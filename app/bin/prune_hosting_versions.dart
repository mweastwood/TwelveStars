// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

const String _defaultTokenUri = 'https://oauth2.googleapis.com/token';
const String _firebaseHostingApiBase =
    'https://firebasehosting.googleapis.com/v1beta1';
const String _oauthScopes =
    'https://www.googleapis.com/auth/firebase '
    'https://www.googleapis.com/auth/cloud-platform';

/// Signature for signing a UTF-8 message string with an RSA-SHA256 PEM private key.
typedef RsaSha256Signer =
    Future<List<int>> Function(String signingInput, String privateKeyPem);

/// Exception thrown when Firebase Hosting version pruning encounters an error.
class FirebaseHostingPruningException implements Exception {
  final String message;

  const FirebaseHostingPruningException(this.message);

  @override
  String toString() => 'FirebaseHostingPruningException: $message';
}

/// Service account credentials parsed from a Google Cloud / Firebase JSON key.
class ServiceAccountCredentials {
  final String clientEmail;
  final String privateKey;
  final String tokenUri;

  const ServiceAccountCredentials({
    required this.clientEmail,
    required this.privateKey,
    this.tokenUri = _defaultTokenUri,
  });

  factory ServiceAccountCredentials.fromJsonString(String rawJson) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException catch (e) {
      throw FirebaseHostingPruningException(
        'Failed to parse service account JSON: ${e.message}',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FirebaseHostingPruningException(
        'Service account JSON must be a JSON object.',
      );
    }
    return ServiceAccountCredentials.fromJson(decoded);
  }

  factory ServiceAccountCredentials.fromJson(Map<String, dynamic> json) {
    final clientEmail = (json['client_email'] as String?)?.trim() ?? '';
    final privateKey = (json['private_key'] as String?)?.trim() ?? '';
    final tokenUri = (json['token_uri'] as String?)?.trim();

    if (clientEmail.isEmpty) {
      throw const FirebaseHostingPruningException(
        'Service account JSON is missing a non-empty "client_email" field.',
      );
    }
    if (privateKey.isEmpty) {
      throw const FirebaseHostingPruningException(
        'Service account JSON is missing a non-empty "private_key" field.',
      );
    }

    return ServiceAccountCredentials(
      clientEmail: clientEmail,
      privateKey: privateKey,
      tokenUri: (tokenUri != null && tokenUri.isNotEmpty)
          ? tokenUri
          : _defaultTokenUri,
    );
  }
}

/// Represents a single version resource on a Firebase Hosting site.
class HostingVersion {
  final String name;
  final String status;
  final DateTime createTime;

  const HostingVersion({
    required this.name,
    required this.status,
    required this.createTime,
  });

  factory HostingVersion.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim() ?? '';
    final status =
        (json['status'] as String?)?.trim() ?? 'VERSION_STATUS_UNSPECIFIED';
    final createTimeStr = (json['createTime'] as String?)?.trim();
    final createTime = createTimeStr != null
        ? (DateTime.tryParse(createTimeStr)?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return HostingVersion(name: name, status: status, createTime: createTime);
  }
}

/// Summary returned after executing a pruning run.
class PruningResult {
  final int totalVersionsScanned;
  final Set<String> protectedVersionNames;
  final List<String> deletedVersionNames;
  final Map<String, String> failedDeletions;

  const PruningResult({
    required this.totalVersionsScanned,
    required this.protectedVersionNames,
    required this.deletedVersionNames,
    required this.failedDeletions,
  });
}

String _base64UrlNoPad(List<int> bytes) {
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Signs [signingInput] with [privateKeyPem] using the system `openssl` CLI.
///
/// The private key is written to a temporary directory with `0600` permissions
/// and deleted immediately in a `finally` block.
Future<List<int>> signRsaSha256WithOpenSsl(
  String signingInput,
  String privateKeyPem,
) async {
  final tempDir = Directory.systemTemp.createTempSync('firebase_sa_key_');
  try {
    final keyFile = File(p.join(tempDir.path, 'key.pem'));
    keyFile.writeAsStringSync(privateKeyPem, flush: true);
    if (!Platform.isWindows) {
      final chmodResult = await Process.run('chmod', ['600', keyFile.path]);
      if (chmodResult.exitCode != 0) {
        throw FirebaseHostingPruningException(
          'Failed to set permissions on temporary key file: ${chmodResult.stderr}',
        );
      }
    }

    final process = await Process.start('openssl', [
      'dgst',
      '-sha256',
      '-sign',
      keyFile.path,
    ]);
    process.stdin.add(utf8.encode(signingInput));
    await process.stdin.close();

    final stdoutBytesFuture = process.stdout.fold<List<int>>(
      <int>[],
      (previous, element) => previous..addAll(element),
    );
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    final stdoutBytes = await stdoutBytesFuture;
    final stderrText = await stderrFuture;

    if (exitCode != 0) {
      throw FirebaseHostingPruningException(
        'openssl dgst -sha256 -sign failed (exit $exitCode): ${stderrText.trim()}',
      );
    }
    return stdoutBytes;
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

/// Builds a signed OAuth2 JWT assertion for [credentials].
Future<String> createSignedServiceAccountJwt(
  ServiceAccountCredentials credentials, {
  DateTime? issuedAt,
  RsaSha256Signer signer = signRsaSha256WithOpenSsl,
}) async {
  final now = (issuedAt ?? DateTime.now()).toUtc();
  final iatSeconds = now.millisecondsSinceEpoch ~/ 1000;
  final expSeconds = iatSeconds + 3600;

  final headerJson = jsonEncode({'alg': 'RS256', 'typ': 'JWT'});
  final claimsJson = jsonEncode({
    'iss': credentials.clientEmail,
    'scope': _oauthScopes,
    'aud': credentials.tokenUri,
    'iat': iatSeconds,
    'exp': expSeconds,
  });

  final encodedHeader = _base64UrlNoPad(utf8.encode(headerJson));
  final encodedClaims = _base64UrlNoPad(utf8.encode(claimsJson));
  final signingInput = '$encodedHeader.$encodedClaims';

  final signatureBytes = await signer(signingInput, credentials.privateKey);
  final encodedSignature = _base64UrlNoPad(signatureBytes);

  return '$signingInput.$encodedSignature';
}

/// Exchanges a service account JWT for a Google OAuth2 bearer access token.
Future<String> fetchGoogleAccessToken(
  ServiceAccountCredentials credentials, {
  required http.Client httpClient,
  DateTime? issuedAt,
  RsaSha256Signer signer = signRsaSha256WithOpenSsl,
}) async {
  final jwt = await createSignedServiceAccountJwt(
    credentials,
    issuedAt: issuedAt,
    signer: signer,
  );

  final response = await httpClient.post(
    Uri.parse(credentials.tokenUri),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      'assertion': jwt,
    },
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw FirebaseHostingPruningException(
      'OAuth2 token exchange failed with HTTP ${response.statusCode}: '
      '${response.body}',
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw const FirebaseHostingPruningException(
      'OAuth2 token response was not a JSON object.',
    );
  }

  final accessToken = (decoded['access_token'] as String?)?.trim() ?? '';
  if (accessToken.isEmpty) {
    throw const FirebaseHostingPruningException(
      'OAuth2 token response did not contain a valid "access_token".',
    );
  }

  return accessToken;
}

/// Prunes old Firebase Hosting versions on [siteId] while preserving active
/// channel versions and the newest [keepCount] finalized versions.
class FirebaseHostingVersionPruner {
  final http.Client httpClient;
  final String siteId;
  final String accessToken;
  final int keepCount;
  final bool dryRun;
  final Duration staleNonFinalizedAge;
  final DateTime Function() clock;
  final void Function(String message) logger;

  FirebaseHostingVersionPruner({
    required this.httpClient,
    required this.siteId,
    required this.accessToken,
    this.keepCount = 3,
    this.dryRun = false,
    this.staleNonFinalizedAge = const Duration(minutes: 30),
    DateTime Function()? clock,
    void Function(String message)? logger,
  }) : assert(keepCount >= 1, 'keepCount must be at least 1'),
       clock = clock ?? (() => DateTime.now().toUtc()),
       logger = logger ?? print;

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $accessToken',
    'Accept': 'application/json',
  };

  /// Fetches the version names currently serving on any channel (including `live`
  /// and preview channels) plus the latest site release so they are never deleted.
  Future<Set<String>> fetchProtectedVersionNames() async {
    final protected = <String>{};

    // 1. Check all channels on the site.
    String? pageToken;
    do {
      final queryParams = <String, String>{
        'pageSize': '100',
        if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
      };
      final uri = Uri.parse(
        '$_firebaseHostingApiBase/sites/$siteId/channels',
      ).replace(queryParameters: queryParams);

      final response = await httpClient.get(uri, headers: _authHeaders);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FirebaseHostingPruningException(
          'Failed to list channels for site "$siteId" '
          '(HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final channels = (body['channels'] as List<dynamic>?) ?? const [];
      for (final channel in channels.whereType<Map<String, dynamic>>()) {
        final release = channel['release'] as Map<String, dynamic>?;
        final version = release?['version'] as Map<String, dynamic>?;
        final versionName = (version?['name'] as String?)?.trim();
        if (versionName != null && versionName.isNotEmpty) {
          protected.add(versionName);
        }
      }

      pageToken = (body['nextPageToken'] as String?)?.trim();
    } while (pageToken != null && pageToken.isNotEmpty);

    // 2. Also check the latest releases on the site as an extra safeguard.
    final releasesUri = Uri.parse(
      '$_firebaseHostingApiBase/sites/$siteId/releases',
    ).replace(queryParameters: const {'pageSize': '5'});
    final releasesResponse = await httpClient.get(
      releasesUri,
      headers: _authHeaders,
    );
    if (releasesResponse.statusCode >= 200 &&
        releasesResponse.statusCode < 300) {
      final body = jsonDecode(releasesResponse.body) as Map<String, dynamic>;
      final releases = (body['releases'] as List<dynamic>?) ?? const [];
      if (releases.isNotEmpty) {
        final latestRelease = releases.first;
        if (latestRelease is Map<String, dynamic>) {
          final version = latestRelease['version'] as Map<String, dynamic>?;
          final versionName = (version?['name'] as String?)?.trim();
          if (versionName != null && versionName.isNotEmpty) {
            protected.add(versionName);
          }
        }
      }
    }

    return protected;
  }

  /// Fetches all version resources for [siteId] across all pages.
  Future<List<HostingVersion>> fetchAllVersions() async {
    final versions = <HostingVersion>[];
    String? pageToken;

    do {
      final queryParams = <String, String>{
        'pageSize': '100',
        if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
      };
      final uri = Uri.parse(
        '$_firebaseHostingApiBase/sites/$siteId/versions',
      ).replace(queryParameters: queryParams);

      final response = await httpClient.get(uri, headers: _authHeaders);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FirebaseHostingPruningException(
          'Failed to list versions for site "$siteId" '
          '(HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rawVersions = (body['versions'] as List<dynamic>?) ?? const [];
      for (final item in rawVersions.whereType<Map<String, dynamic>>()) {
        final version = HostingVersion.fromJson(item);
        if (version.name.isNotEmpty) {
          versions.add(version);
        }
      }

      pageToken = (body['nextPageToken'] as String?)?.trim();
    } while (pageToken != null && pageToken.isNotEmpty);

    return versions;
  }

  /// Selects which versions should be deleted given [allVersions] and
  /// [protectedVersionNames].
  ///
  /// Rules:
  /// 1. Never delete any version in [protectedVersionNames] or with status `DELETED`.
  /// 2. Sort all `FINALIZED` versions newest-first by `createTime` (tie-breaking by
  ///    `name` descending). Keep the newest [keepCount] finalized versions, and
  ///    mark all older finalized versions (not in [protectedVersionNames]) for deletion.
  /// 3. Mark `ABANDONED` and `EXPIRED` versions (not in [protectedVersionNames]) for
  ///    deletion, as well as `CREATED` versions older than [staleNonFinalizedAge].
  List<HostingVersion> selectVersionsToDelete(
    List<HostingVersion> allVersions,
    Set<String> protectedVersionNames,
  ) {
    final now = clock().toUtc();

    final finalized = allVersions.where((v) => v.status == 'FINALIZED').toList()
      ..sort((a, b) {
        final cmp = b.createTime.compareTo(a.createTime);
        return cmp != 0 ? cmp : b.name.compareTo(a.name);
      });

    final retainedFinalizedNames = finalized
        .take(keepCount)
        .map((v) => v.name)
        .toSet();

    final toDelete = <HostingVersion>[];

    for (final v in finalized) {
      if (protectedVersionNames.contains(v.name)) continue;
      if (retainedFinalizedNames.contains(v.name)) continue;
      toDelete.add(v);
    }

    for (final v in allVersions) {
      if (v.status == 'FINALIZED' || v.status == 'DELETED') continue;
      if (protectedVersionNames.contains(v.name)) continue;

      if (v.status == 'ABANDONED' || v.status == 'EXPIRED') {
        toDelete.add(v);
      } else if (v.status == 'CREATED') {
        final age = now.difference(v.createTime);
        if (age >= staleNonFinalizedAge) {
          toDelete.add(v);
        }
      }
    }

    return toDelete;
  }

  /// Runs the full pruning workflow on [siteId].
  Future<PruningResult> prune() async {
    logger(
      'Checking Firebase Hosting versions for site "$siteId" '
      '(keepCount=$keepCount, dryRun=$dryRun)...',
    );

    final protectedNames = await fetchProtectedVersionNames();
    logger(
      'Protected active channel/release versions (${protectedNames.length}): '
      '${protectedNames.isEmpty ? "none" : protectedNames.join(", ")}',
    );

    final allVersions = await fetchAllVersions();
    final toDelete = selectVersionsToDelete(allVersions, protectedNames);

    logger(
      'Found ${allVersions.length} total versions on "$siteId"; '
      '${toDelete.length} eligible for deletion.',
    );

    final deletedNames = <String>[];
    final failedDeletions = <String, String>{};

    for (final version in toDelete) {
      if (dryRun) {
        logger(
          '[DRY RUN] Would delete ${version.name} '
          '(status=${version.status}, created=${version.createTime.toIso8601String()})',
        );
        deletedNames.add(version.name);
        continue;
      }

      final deleteUri = Uri.parse('$_firebaseHostingApiBase/${version.name}');
      final response = await httpClient.delete(
        deleteUri,
        headers: _authHeaders,
      );

      if (response.statusCode >= 200 && response.statusCode < 300 ||
          response.statusCode == 404) {
        logger(
          'Deleted ${version.name} '
          '(status=${version.status}, created=${version.createTime.toIso8601String()})',
        );
        deletedNames.add(version.name);
      } else {
        final errorDetail =
            'HTTP ${response.statusCode}: ${response.body.trim()}';
        logger('WARNING: Failed to delete ${version.name}: $errorDetail');
        failedDeletions[version.name] = errorDetail;
      }
    }

    logger(
      'Pruning complete for "$siteId": '
      '${deletedNames.length} deleted, ${failedDeletions.length} failed.',
    );

    return PruningResult(
      totalVersionsScanned: allVersions.length,
      protectedVersionNames: protectedNames,
      deletedVersionNames: deletedNames,
      failedDeletions: failedDeletions,
    );
  }
}

/// Parsed command-line options for `prune_hosting_versions.dart`.
class PruneCliOptions {
  final String siteId;
  final int keepCount;
  final String serviceAccountEnvVar;
  final String? serviceAccountFilePath;
  final bool dryRun;

  const PruneCliOptions({
    required this.siteId,
    this.keepCount = 3,
    this.serviceAccountEnvVar = 'FIREBASE_SERVICE_ACCOUNT_JSON',
    this.serviceAccountFilePath,
    this.dryRun = false,
  });

  static PruneCliOptions parse(List<String> args) {
    String? siteId;
    int keepCount = 3;
    String serviceAccountEnvVar = 'FIREBASE_SERVICE_ACCOUNT_JSON';
    String? serviceAccountFilePath;
    bool dryRun = false;

    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--site' && i + 1 < args.length) {
        siteId = args[++i].trim();
      } else if (arg.startsWith('--site=')) {
        siteId = arg.substring('--site='.length).trim();
      } else if (arg == '--keep' && i + 1 < args.length) {
        keepCount = int.parse(args[++i].trim());
      } else if (arg.startsWith('--keep=')) {
        keepCount = int.parse(arg.substring('--keep='.length).trim());
      } else if (arg == '--service-account-env' && i + 1 < args.length) {
        serviceAccountEnvVar = args[++i].trim();
      } else if (arg.startsWith('--service-account-env=')) {
        serviceAccountEnvVar = arg
            .substring('--service-account-env='.length)
            .trim();
      } else if (arg == '--service-account-file' && i + 1 < args.length) {
        serviceAccountFilePath = args[++i].trim();
      } else if (arg.startsWith('--service-account-file=')) {
        serviceAccountFilePath = arg
            .substring('--service-account-file='.length)
            .trim();
      } else if (arg == '--dry-run') {
        dryRun = true;
      } else {
        throw ArgumentError('Unknown or incomplete argument: $arg');
      }
    }

    if (siteId == null || siteId.isEmpty) {
      throw ArgumentError('Missing required argument: --site <siteId>');
    }
    if (keepCount < 1) {
      throw ArgumentError('--keep must be at least 1 (got $keepCount)');
    }

    return PruneCliOptions(
      siteId: siteId,
      keepCount: keepCount,
      serviceAccountEnvVar: serviceAccountEnvVar,
      serviceAccountFilePath: serviceAccountFilePath,
      dryRun: dryRun,
    );
  }
}

Future<void> main(List<String> args) async {
  final PruneCliOptions options;
  try {
    options = PruneCliOptions.parse(args);
  } on Object catch (e) {
    stderr.writeln('Error: $e');
    stderr.writeln(
      'Usage: dart run bin/prune_hosting_versions.dart '
      '--site <siteId> [--keep <count>] '
      '[--service-account-env <ENV_VAR>] '
      '[--service-account-file <path>] [--dry-run]',
    );
    exit(2);
  }

  final String rawServiceAccountJson;
  if (options.serviceAccountFilePath != null &&
      options.serviceAccountFilePath!.isNotEmpty) {
    final file = File(options.serviceAccountFilePath!);
    if (!file.existsSync()) {
      stderr.writeln(
        'Error: Service account file not found: ${options.serviceAccountFilePath}',
      );
      exit(1);
    }
    rawServiceAccountJson = file.readAsStringSync();
  } else {
    rawServiceAccountJson =
        Platform.environment[options.serviceAccountEnvVar]?.trim() ?? '';
    if (rawServiceAccountJson.isEmpty) {
      stderr.writeln(
        'Error: Environment variable ${options.serviceAccountEnvVar} is empty or not set.',
      );
      exit(1);
    }
  }

  final client = http.Client();
  try {
    final credentials = ServiceAccountCredentials.fromJsonString(
      rawServiceAccountJson,
    );
    final accessToken = await fetchGoogleAccessToken(
      credentials,
      httpClient: client,
    );
    final pruner = FirebaseHostingVersionPruner(
      httpClient: client,
      siteId: options.siteId,
      accessToken: accessToken,
      keepCount: options.keepCount,
      dryRun: options.dryRun,
    );
    await pruner.prune();
  } on Object catch (e) {
    stderr.writeln('Error pruning Firebase Hosting versions: $e');
    exit(1);
  } finally {
    client.close();
  }
}
