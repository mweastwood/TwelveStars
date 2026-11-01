import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

import '../../bin/prune_hosting_versions.dart';

void main() {
  group('ServiceAccountCredentials', () {
    test('parses valid service account JSON and defaults tokenUri', () {
      final raw = jsonEncode({
        'client_email':
            'firebase-adminsdk@twelve-stars-dev.iam.gserviceaccount.com',
        'private_key':
            '-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n',
      });

      final creds = ServiceAccountCredentials.fromJsonString(raw);
      expect(
        creds.clientEmail,
        'firebase-adminsdk@twelve-stars-dev.iam.gserviceaccount.com',
      );
      expect(creds.privateKey, contains('BEGIN PRIVATE KEY'));
      expect(creds.tokenUri, 'https://oauth2.googleapis.com/token');
    });

    test(
      'throws FirebaseHostingPruningException on invalid JSON or missing fields',
      () {
        expect(
          () => ServiceAccountCredentials.fromJsonString('not-json'),
          throwsA(isA<FirebaseHostingPruningException>()),
        );
        expect(
          () => ServiceAccountCredentials.fromJsonString(
            jsonEncode({'client_email': ''}),
          ),
          throwsA(isA<FirebaseHostingPruningException>()),
        );
        expect(
          () => ServiceAccountCredentials.fromJsonString(
            jsonEncode({
              'client_email': 'test@example.com',
              'private_key': '   ',
            }),
          ),
          throwsA(isA<FirebaseHostingPruningException>()),
        );
      },
    );
  });

  group('JWT signing and OAuth2 token exchange', () {
    test(
      'signRsaSha256WithOpenSsl signs data verifiable with public key',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'openssl_jwt_test_',
        );
        try {
          final privKeyPath = p.join(tempDir.path, 'private.pem');
          final pubKeyPath = p.join(tempDir.path, 'public.pem');

          final genResult = await Process.run('openssl', [
            'genrsa',
            '-out',
            privKeyPath,
            '2048',
          ]);
          expect(genResult.exitCode, 0, reason: '${genResult.stderr}');

          final pubResult = await Process.run('openssl', [
            'rsa',
            '-in',
            privKeyPath,
            '-pubout',
            '-out',
            pubKeyPath,
          ]);
          expect(pubResult.exitCode, 0, reason: '${pubResult.stderr}');

          final privateKeyPem = File(privKeyPath).readAsStringSync();
          final credentials = ServiceAccountCredentials(
            clientEmail: 'deployer@twelve-stars-dev.iam.gserviceaccount.com',
            privateKey: privateKeyPem,
          );

          final issuedAt = DateTime.utc(2026, 11, 1, 12, 0, 0);
          final jwt = await createSignedServiceAccountJwt(
            credentials,
            issuedAt: issuedAt,
          );

          final parts = jwt.split('.');
          expect(parts, hasLength(3));

          final signingInput = '${parts[0]}.${parts[1]}';
          final sigBytes = base64Url.decode(base64Url.normalize(parts[2]));

          final sigFile = File(p.join(tempDir.path, 'sig.bin'))
            ..writeAsBytesSync(sigBytes);
          final dataFile = File(p.join(tempDir.path, 'data.txt'))
            ..writeAsStringSync(signingInput);

          final verifyResult = await Process.run('openssl', [
            'dgst',
            '-sha256',
            '-verify',
            pubKeyPath,
            '-signature',
            sigFile.path,
            dataFile.path,
          ]);
          expect(verifyResult.exitCode, 0, reason: '${verifyResult.stderr}');
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      },
    );

    test(
      'fetchGoogleAccessToken exchanges signed JWT for access_token',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), 'https://oauth2.googleapis.com/token');
          expect(
            request.bodyFields['grant_type'],
            'urn:ietf:params:oauth:grant-type:jwt-bearer',
          );
          expect(request.bodyFields['assertion']?.split('.'), hasLength(3));

          return http.Response(
            jsonEncode({
              'access_token': 'mock-oauth-token-123',
              'expires_in': 3600,
            }),
            200,
          );
        });

        final creds = const ServiceAccountCredentials(
          clientEmail: 'sa@twelve-stars-dev.iam.gserviceaccount.com',
          privateKey: 'FAKE_KEY',
        );

        final token = await fetchGoogleAccessToken(
          creds,
          httpClient: mockClient,
          signer: (input, key) async => utf8.encode('mock-sig'),
        );
        expect(token, 'mock-oauth-token-123');
      },
    );
  });

  group('FirebaseHostingVersionPruner', () {
    final fixedNow = DateTime.utc(2026, 11, 1, 18, 0, 0);

    test(
      'selectVersionsToDelete keeps newest N finalized, protects live versions even when old, and prunes stale non-finalized versions',
      () {
        final pruner = FirebaseHostingVersionPruner(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
          siteId: 'twelve-stars-dev',
          accessToken: 'token',
          keepCount: 2,
          clock: () => fixedNow,
        );

        final versions = [
          // Newest finalized (#1) -> keep
          HostingVersion(
            name: 'sites/twelve-stars-dev/versions/v5_newest',
            status: 'FINALIZED',
            createTime: fixedNow.subtract(const Duration(minutes: 5)),
          ),
          // Second newest finalized (#2) -> keep
          HostingVersion(
            name: 'sites/twelve-stars-dev/versions/v4_second',
            status: 'FINALIZED',
            createTime: fixedNow.subtract(const Duration(hours: 1)),
          ),
          // Third newest finalized (#3) -> delete
          HostingVersion(
            name: 'sites/twelve-stars-dev/versions/v3_old_finalized',
            status: 'FINALIZED',
            createTime: fixedNow.subtract(const Duration(hours: 2)),
          ),
          // Fourth newest finalized (#4), but currently serving on a preview channel -> protected!
          HostingVersion(
            name: 'sites/twelve-stars-dev/versions/v2_live_on_preview',
            status: 'FINALIZED',
            createTime: fixedNow.subtract(const Duration(days: 3)),
          ),
          // Fifth newest finalized (#5) -> delete
          HostingVersion(
            name: 'sites/twelve-stars-dev/versions/v1_ancient',
            status: 'FINALIZED',
            createTime: fixedNow.subtract(const Duration(days: 10)),
          ),
          // Abandoned version -> delete
          HostingVersion(
            name: 'sites/twelve-stars-dev/versions/v_abandoned',
            status: 'ABANDONED',
            createTime: fixedNow.subtract(const Duration(minutes: 10)),
          ),
          // Fresh CREATED version (2 minutes old, e.g. concurrent deploy) -> keep!
          HostingVersion(
            name: 'sites/twelve-stars-dev/versions/v_created_fresh',
            status: 'CREATED',
            createTime: fixedNow.subtract(const Duration(minutes: 2)),
          ),
          // Stale CREATED version (45 minutes old, failed deploy) -> delete!
          HostingVersion(
            name: 'sites/twelve-stars-dev/versions/v_created_stale',
            status: 'CREATED',
            createTime: fixedNow.subtract(const Duration(minutes: 45)),
          ),
          // Already DELETED version -> ignore
          HostingVersion(
            name: 'sites/twelve-stars-dev/versions/v_already_deleted',
            status: 'DELETED',
            createTime: fixedNow.subtract(const Duration(days: 20)),
          ),
        ];

        final protectedNames = {
          'sites/twelve-stars-dev/versions/v2_live_on_preview',
        };

        final toDelete = pruner.selectVersionsToDelete(
          versions,
          protectedNames,
        );
        expect(
          toDelete.map((v) => v.name).toList(),
          equals([
            'sites/twelve-stars-dev/versions/v3_old_finalized',
            'sites/twelve-stars-dev/versions/v1_ancient',
            'sites/twelve-stars-dev/versions/v_abandoned',
            'sites/twelve-stars-dev/versions/v_created_stale',
          ]),
        );
      },
    );

    test(
      'prune paginates channels and versions and deletes eligible versions',
      () async {
        final deletedCalls = <String>[];
        final logs = <String>[];

        final mockClient = MockClient((request) async {
          final path = request.url.path;
          final query = request.url.queryParameters;

          if (request.method == 'GET' &&
              path == '/v1beta1/sites/twelve-stars-dev/channels') {
            return http.Response(
              jsonEncode({
                'channels': [
                  {
                    'name': 'sites/twelve-stars-dev/channels/live',
                    'release': {
                      'version': {
                        'name':
                            'sites/twelve-stars-dev/versions/v_live_current',
                      },
                    },
                  },
                ],
              }),
              200,
            );
          }

          if (request.method == 'GET' &&
              path == '/v1beta1/sites/twelve-stars-dev/releases') {
            return http.Response(
              jsonEncode({
                'releases': [
                  {
                    'version': {
                      'name': 'sites/twelve-stars-dev/versions/v_live_current',
                    },
                  },
                ],
              }),
              200,
            );
          }

          if (request.method == 'GET' &&
              path == '/v1beta1/sites/twelve-stars-dev/versions') {
            if (query['pageToken'] == null) {
              return http.Response(
                jsonEncode({
                  'versions': [
                    {
                      'name': 'sites/twelve-stars-dev/versions/v_live_current',
                      'status': 'FINALIZED',
                      'createTime': '2026-11-01T17:00:00Z',
                    },
                    {
                      'name': 'sites/twelve-stars-dev/versions/v_previous_keep',
                      'status': 'FINALIZED',
                      'createTime': '2026-11-01T16:00:00Z',
                    },
                  ],
                  'nextPageToken': 'page_2',
                }),
                200,
              );
            } else if (query['pageToken'] == 'page_2') {
              return http.Response(
                jsonEncode({
                  'versions': [
                    {
                      'name': 'sites/twelve-stars-dev/versions/v_old_1',
                      'status': 'FINALIZED',
                      'createTime': '2026-11-01T14:00:00Z',
                    },
                    {
                      'name': 'sites/twelve-stars-dev/versions/v_old_2',
                      'status': 'FINALIZED',
                      'createTime': '2026-11-01T12:00:00Z',
                    },
                  ],
                }),
                200,
              );
            }
          }

          if (request.method == 'DELETE') {
            deletedCalls.add(path);
            return http.Response('{}', 200);
          }

          return http.Response(
            'Unexpected request: ${request.method} $path',
            500,
          );
        });

        final pruner = FirebaseHostingVersionPruner(
          httpClient: mockClient,
          siteId: 'twelve-stars-dev',
          accessToken: 'token',
          keepCount: 2,
          clock: () => fixedNow,
          logger: logs.add,
        );

        final result = await pruner.prune();
        expect(result.totalVersionsScanned, 4);
        expect(
          result.protectedVersionNames,
          equals({'sites/twelve-stars-dev/versions/v_live_current'}),
        );
        expect(
          result.deletedVersionNames,
          equals([
            'sites/twelve-stars-dev/versions/v_old_1',
            'sites/twelve-stars-dev/versions/v_old_2',
          ]),
        );
        expect(result.failedDeletions, isEmpty);
        expect(
          deletedCalls,
          equals([
            '/v1beta1/sites/twelve-stars-dev/versions/v_old_1',
            '/v1beta1/sites/twelve-stars-dev/versions/v_old_2',
          ]),
        );
      },
    );
  });

  group('PruneCliOptions', () {
    test('parses CLI flags accurately', () {
      final options = PruneCliOptions.parse([
        '--site',
        'twelve-stars-dev',
        '--keep=2',
        '--service-account-env',
        'CUSTOM_SA_ENV',
        '--dry-run',
      ]);

      expect(options.siteId, 'twelve-stars-dev');
      expect(options.keepCount, 2);
      expect(options.serviceAccountEnvVar, 'CUSTOM_SA_ENV');
      expect(options.dryRun, isTrue);
    });

    test('throws ArgumentError when --site is missing or --keep < 1', () {
      expect(() => PruneCliOptions.parse(['--keep', '2']), throwsArgumentError);
      expect(
        () => PruneCliOptions.parse([
          '--site',
          'twelve-stars-dev',
          '--keep',
          '0',
        ]),
        throwsArgumentError,
      );
    });
  });
}
