import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';

void main() {
  group('BibleTranslationInfo & BibleApprovalStatus Unit Tests', () {
    group('Model Instantiation', () {
      test('instantiates BibleTranslationInfo with valid properties', () {
        const info = BibleTranslationInfo(
          code: 'CUSTOM',
          name: 'Custom Translation Name',
          shortName: 'Custom Short',
          languages: ['Latin', 'English'],
          primaryLanguageCode: 'la',
          publicationDate: '2026',
          publicDomainStatus: 'Public Domain',
          approvalStatus: BibleApprovalStatus.imprimatur,
          originDescription: 'A test translation origin description.',
          churchUsage: 'Used for liturgical testing purposes.',
        );

        expect(info.code, equals('CUSTOM'));
        expect(info.name, equals('Custom Translation Name'));
        expect(info.shortName, equals('Custom Short'));
        expect(info.languages, equals(['Latin', 'English']));
        expect(info.primaryLanguageCode, equals('la'));
        expect(info.publicationDate, equals('2026'));
        expect(info.publicDomainStatus, equals('Public Domain'));
        expect(info.approvalStatus, equals(BibleApprovalStatus.imprimatur));
        expect(
          info.originDescription,
          equals('A test translation origin description.'),
        );
        expect(
          info.churchUsage,
          equals('Used for liturgical testing purposes.'),
        );
      });
    });

    group('Approval Status Labels', () {
      test('returns "Imprimatur" for BibleApprovalStatus.imprimatur', () {
        const info = BibleTranslationInfo(
          code: 'TEST',
          name: 'Test',
          shortName: 'Test',
          languages: ['English'],
          primaryLanguageCode: 'en',
          publicationDate: '2026',
          publicDomainStatus: 'Public Domain',
          approvalStatus: BibleApprovalStatus.imprimatur,
          originDescription: 'Description',
          churchUsage: 'Usage',
        );

        expect(info.approvalStatusLabel, equals('Imprimatur'));
      });

      test('returns "No Imprimatur" for BibleApprovalStatus.noImprimatur', () {
        const info = BibleTranslationInfo(
          code: 'TEST',
          name: 'Test',
          shortName: 'Test',
          languages: ['English'],
          primaryLanguageCode: 'en',
          publicationDate: '2026',
          publicDomainStatus: 'Public Domain',
          approvalStatus: BibleApprovalStatus.noImprimatur,
          originDescription: 'Description',
          churchUsage: 'Usage',
        );

        expect(info.approvalStatusLabel, equals('No Imprimatur'));
      });

      test(
        'returns "Canonical Source Text" for BibleApprovalStatus.canonicalSourceText',
        () {
          const info = BibleTranslationInfo(
            code: 'TEST',
            name: 'Test',
            shortName: 'Test',
            languages: ['Greek'],
            primaryLanguageCode: 'el',
            publicationDate: 'Ancient',
            publicDomainStatus: 'Public Domain',
            approvalStatus: BibleApprovalStatus.canonicalSourceText,
            originDescription: 'Description',
            churchUsage: 'Usage',
          );

          expect(info.approvalStatusLabel, equals('Canonical Source Text'));
        },
      );

      test(
        'covers every BibleApprovalStatus enum value with non-empty label',
        () {
          expect(BibleApprovalStatus.values, hasLength(3));

          for (final status in BibleApprovalStatus.values) {
            final info = BibleTranslationInfo(
              code: 'TEST',
              name: 'Test',
              shortName: 'Test',
              languages: ['English'],
              primaryLanguageCode: 'en',
              publicationDate: '2026',
              publicDomainStatus: 'Public Domain',
              approvalStatus: status,
              originDescription: 'Description',
              churchUsage: 'Usage',
            );

            expect(info.approvalStatusLabel, isNotEmpty);
          }
        },
      );
    });

    group('Translation Lookup (getByCode)', () {
      test('matches exact uppercase codes correctly', () {
        final drc = BibleTranslationInfo.getByCode('DRC');
        expect(drc.code, equals('DRC'));
        expect(drc.shortName, equals('Douay-Rheims'));

        final vul = BibleTranslationInfo.getByCode('VUL');
        expect(vul.code, equals('VUL'));
        expect(vul.shortName, equals('Clementine Vulgate'));

        final jun = BibleTranslationInfo.getByCode('JUN');
        expect(jun.code, equals('JUN'));
        expect(jun.shortName, equals('Torres Amat'));

        final tam = BibleTranslationInfo.getByCode('TAM');
        expect(tam.code, equals('TAM'));
        expect(tam.shortName, equals('Scío de San Miguel'));

        final cpdv = BibleTranslationInfo.getByCode('CPDV');
        expect(cpdv.code, equals('CPDV'));
        expect(cpdv.shortName, equals('CPDV'));

        final lxx = BibleTranslationInfo.getByCode('LXX');
        expect(lxx.code, equals('LXX'));
        expect(lxx.shortName, equals('Septuagint'));

        final orig = BibleTranslationInfo.getByCode('ORIG');
        expect(orig.code, equals('ORIG'));
        expect(orig.shortName, equals('Original Languages'));
      });

      test('is case-insensitive for lookup codes', () {
        expect(BibleTranslationInfo.getByCode('drc').code, equals('DRC'));
        expect(BibleTranslationInfo.getByCode('vul').code, equals('VUL'));
        expect(BibleTranslationInfo.getByCode('jun').code, equals('JUN'));
        expect(BibleTranslationInfo.getByCode('tam').code, equals('TAM'));
        expect(BibleTranslationInfo.getByCode('cpdv').code, equals('CPDV'));
        expect(BibleTranslationInfo.getByCode('lxx').code, equals('LXX'));
        expect(BibleTranslationInfo.getByCode('orig').code, equals('ORIG'));

        expect(BibleTranslationInfo.getByCode('CpdV').code, equals('CPDV'));
        expect(BibleTranslationInfo.getByCode('VuL').code, equals('VUL'));
        expect(BibleTranslationInfo.getByCode('Drc').code, equals('DRC'));
      });

      test(
        'falls back to default (first translation, DRC) for unknown code',
        () {
          final unknown = BibleTranslationInfo.getByCode('UNKNOWN');
          expect(
            unknown.code,
            equals(BibleTranslationInfo.allTranslations.first.code),
          );
          expect(unknown.code, equals('DRC'));

          final empty = BibleTranslationInfo.getByCode('');
          expect(empty.code, equals('DRC'));

          final nonExistent = BibleTranslationInfo.getByCode('xyz_123');
          expect(nonExistent.code, equals('DRC'));
        },
      );
    });

    group('Catalog Invariants & Completeness (allTranslations)', () {
      test('contains exactly 7 supported Catholic translations', () {
        expect(BibleTranslationInfo.allTranslations.length, equals(7));
      });

      test('first translation is Douay-Rheims (DRC) as default', () {
        final first = BibleTranslationInfo.allTranslations.first;
        expect(first.code, equals('DRC'));
        expect(first.shortName, equals('Douay-Rheims'));
      });

      test('all translation codes are unique and uppercase', () {
        final codes = BibleTranslationInfo.allTranslations
            .map((t) => t.code)
            .toList();
        expect(codes.toSet().length, equals(codes.length));

        for (final code in codes) {
          expect(code, equals(code.toUpperCase()));
          expect(code, isNotEmpty);
        }
      });

      test('all translations contain non-empty metadata fields', () {
        for (final t in BibleTranslationInfo.allTranslations) {
          expect(t.code, isNotEmpty);
          expect(t.name, isNotEmpty);
          expect(t.shortName, isNotEmpty);
          expect(t.publicationDate, isNotEmpty);
          expect(t.publicDomainStatus, isNotEmpty);
          expect(t.originDescription, isNotEmpty);
          expect(t.churchUsage, isNotEmpty);
        }
      });

      test(
        'all translations define non-empty languages and valid primary language code',
        () {
          const validLanguageCodes = {'en', 'la', 'es', 'el', 'he'};

          for (final t in BibleTranslationInfo.allTranslations) {
            expect(t.languages, isNotEmpty);
            for (final lang in t.languages) {
              expect(lang, isNotEmpty);
            }
            expect(validLanguageCodes.contains(t.primaryLanguageCode), isTrue);
          }
        },
      );

      test('all translations have a valid approval status and label', () {
        for (final t in BibleTranslationInfo.allTranslations) {
          expect(BibleApprovalStatus.values.contains(t.approvalStatus), isTrue);
          expect(t.approvalStatusLabel, isNotEmpty);
        }
      });

      test(
        'verifies specific approval status classifications for catalog editions',
        () {
          final drc = BibleTranslationInfo.getByCode('DRC');
          final vul = BibleTranslationInfo.getByCode('VUL');
          final jun = BibleTranslationInfo.getByCode('JUN');
          final tam = BibleTranslationInfo.getByCode('TAM');
          final cpdv = BibleTranslationInfo.getByCode('CPDV');
          final lxx = BibleTranslationInfo.getByCode('LXX');
          final orig = BibleTranslationInfo.getByCode('ORIG');

          expect(drc.approvalStatus, equals(BibleApprovalStatus.imprimatur));
          expect(vul.approvalStatus, equals(BibleApprovalStatus.imprimatur));
          expect(jun.approvalStatus, equals(BibleApprovalStatus.imprimatur));
          expect(tam.approvalStatus, equals(BibleApprovalStatus.imprimatur));
          expect(cpdv.approvalStatus, equals(BibleApprovalStatus.noImprimatur));
          expect(
            lxx.approvalStatus,
            equals(BibleApprovalStatus.canonicalSourceText),
          );
          expect(
            orig.approvalStatus,
            equals(BibleApprovalStatus.canonicalSourceText),
          );
        },
      );
    });
  });
}
