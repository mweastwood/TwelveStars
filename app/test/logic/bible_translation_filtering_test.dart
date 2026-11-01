import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';

void main() {
  group('BibleTranslationInfo Filtering & Dual-Target Resolution Tests', () {
    group('Filter Tags & matchesFilterTag', () {
      test('exposes canonical filterTags and dialogFilterTags lists', () {
        expect(
          BibleTranslationInfo.filterTags,
          equals([
            'All',
            'English',
            'Catholic Approved',
            'Sacred Languages',
            'Spanish',
            'Chinese',
            'Arabic',
          ]),
        );
        expect(
          BibleTranslationInfo.dialogFilterTags,
          equals(['Imprimatur', 'English', 'Latin', 'Spanish', 'Ancient']),
        );
      });

      test('filterTranslations with "All" returns all 7 translations', () {
        final results = BibleTranslationInfo.filterTranslations(
          selectedTag: 'All',
        );
        expect(results, hasLength(BibleTranslationInfo.allTranslations.length));
      });

      test('filterTranslations with "English" returns DRC and CPDV', () {
        final results = BibleTranslationInfo.filterTranslations(
          selectedTag: 'English',
        );
        expect(results.map((t) => t.code).toList(), equals(['DRC', 'CPDV']));
      });

      test(
        'filterTranslations with "Catholic Approved" or "Imprimatur" returns approved editions',
        () {
          final approved = BibleTranslationInfo.filterTranslations(
            selectedTag: 'Catholic Approved',
          );
          final imprimatur = BibleTranslationInfo.filterTranslations(
            selectedTag: 'Imprimatur',
          );

          expect(
            approved.map((t) => t.code).toList(),
            equals(['DRC', 'VUL', 'JUN', 'TAM']),
          );
          expect(
            imprimatur.map((t) => t.code).toList(),
            equals(['DRC', 'VUL', 'JUN', 'TAM']),
          );
        },
      );

      test(
        'filterTranslations with "Sacred Languages" returns VUL, LXX, and ORIG',
        () {
          final results = BibleTranslationInfo.filterTranslations(
            selectedTag: 'Sacred Languages',
          );
          expect(
            results.map((t) => t.code).toList(),
            equals(['VUL', 'LXX', 'ORIG']),
          );
        },
      );

      test(
        'filterTranslations with "Ancient" returns canonical source texts LXX and ORIG',
        () {
          final results = BibleTranslationInfo.filterTranslations(
            selectedTag: 'Ancient',
          );
          expect(results.map((t) => t.code).toList(), equals(['LXX', 'ORIG']));
        },
      );

      test('filterTranslations with "Latin" returns VUL', () {
        final results = BibleTranslationInfo.filterTranslations(
          selectedTag: 'Latin',
        );
        expect(results.map((t) => t.code).toList(), equals(['VUL']));
      });

      test('filterTranslations with "Spanish" returns JUN and TAM', () {
        final results = BibleTranslationInfo.filterTranslations(
          selectedTag: 'Spanish',
        );
        expect(results.map((t) => t.code).toList(), equals(['JUN', 'TAM']));
      });

      test(
        'filterTranslations with "Chinese" and "Arabic" handles custom/empty matches cleanly',
        () {
          expect(
            BibleTranslationInfo.filterTranslations(selectedTag: 'Chinese'),
            isEmpty,
          );
          expect(
            BibleTranslationInfo.filterTranslations(selectedTag: 'Arabic'),
            isEmpty,
          );

          const customChinese = BibleTranslationInfo(
            code: 'SIGAO',
            name: 'Studium Biblicum Franciscanum (Sigao Bible)',
            shortName: 'Sigao',
            languages: ['Chinese'],
            primaryLanguageCode: 'zh',
            publicationDate: '1968',
            publicDomainStatus: 'Church Edition',
            approvalStatus: BibleApprovalStatus.imprimatur,
            originDescription:
                'Translated by Gabriele Allegra and Franciscan friars.',
            churchUsage: 'Standard Chinese Catholic Bible.',
          );
          const customArabic = BibleTranslationInfo(
            code: 'JESUIT',
            name: 'Jesuit Arabic Bible',
            shortName: 'Jesuit Arabic',
            languages: ['Arabic'],
            primaryLanguageCode: 'ar',
            publicationDate: '1880',
            publicDomainStatus: 'Public Domain',
            approvalStatus: BibleApprovalStatus.imprimatur,
            originDescription: 'Beirut Jesuit Arabic translation.',
            churchUsage: 'Middle Eastern Catholic liturgy and study.',
          );

          final customSource = [
            ...BibleTranslationInfo.allTranslations,
            customChinese,
            customArabic,
          ];

          final zhResults = BibleTranslationInfo.filterTranslations(
            selectedTag: 'Chinese',
            source: customSource,
          );
          expect(zhResults.map((t) => t.code).toList(), equals(['SIGAO']));

          final arResults = BibleTranslationInfo.filterTranslations(
            selectedTag: 'Arabic',
            source: customSource,
          );
          expect(arResults.map((t) => t.code).toList(), equals(['JESUIT']));
        },
      );

      test('supports multi-select filter combinations via selectedFilters', () {
        final results = BibleTranslationInfo.filterTranslations(
          selectedFilters: {'Spanish', 'Imprimatur'},
        );
        expect(results.map((t) => t.code).toList(), equals(['JUN', 'TAM']));

        final englishImprimatur = BibleTranslationInfo.filterTranslations(
          selectedFilters: {'English', 'Imprimatur'},
        );
        expect(englishImprimatur.map((t) => t.code).toList(), equals(['DRC']));
      });
    });

    group(
      'Search Query Matching (matchesSearchQuery & filterTranslations)',
      () {
        test('matches by translation code (case-insensitive)', () {
          final results = BibleTranslationInfo.filterTranslations(
            query: 'cpdv',
          );
          expect(results.map((t) => t.code), contains('CPDV'));
        });

        test('matches by full name and shortName', () {
          final byName = BibleTranslationInfo.filterTranslations(
            query: 'Sixto-Clementine',
          );
          expect(byName.map((t) => t.code).toList(), equals(['VUL']));

          final byShortName = BibleTranslationInfo.filterTranslations(
            query: 'Torres Amat',
          );
          expect(byShortName.map((t) => t.code).toList(), equals(['JUN']));
        });

        test(
          'matches by originDescription / notes and churchUsage / tradition',
          () {
            final byOrigin = BibleTranslationInfo.filterTranslations(
              query: 'Challoner',
            );
            expect(byOrigin.map((t) => t.code).toList(), equals(['DRC']));

            final byTradition = BibleTranslationInfo.filterTranslations(
              query: 'Divino Afflante Spiritu',
            );
            expect(byTradition.map((t) => t.code).toList(), equals(['ORIG']));
          },
        );

        test('matches by language name', () {
          final aramaic = BibleTranslationInfo.filterTranslations(
            query: 'Aramaic',
          );
          expect(aramaic.map((t) => t.code).toList(), equals(['ORIG']));

          final greek = BibleTranslationInfo.filterTranslations(query: 'Greek');
          expect(greek.map((t) => t.code).toList(), equals(['LXX', 'ORIG']));
        });

        test('combines search query and tag filter', () {
          final results = BibleTranslationInfo.filterTranslations(
            query: 'Vulgate',
            selectedTag: 'English',
          );
          expect(results.map((t) => t.code).toList(), equals(['DRC', 'CPDV']));
        });
      },
    );

    group('Dual-Translation Selection & Swap Resolution', () {
      test(
        'resolvePrimarySelection updates primary and preserves non-colliding secondary',
        () {
          final result = BibleTranslationInfo.resolvePrimarySelection(
            currentPrimary: 'CPDV',
            currentSecondary: 'VUL',
            newPrimary: 'DRC',
          );
          expect(result.primary, equals('DRC'));
          expect(result.secondary, equals('VUL'));
          expect(result.primaryChanged, isTrue);
        },
      );

      test(
        'resolvePrimarySelection clears secondary when newPrimary collides with currentSecondary',
        () {
          final result = BibleTranslationInfo.resolvePrimarySelection(
            currentPrimary: 'CPDV',
            currentSecondary: 'DRC',
            newPrimary: 'DRC',
          );
          expect(result.primary, equals('DRC'));
          expect(result.secondary, isNull);
          expect(result.primaryChanged, isTrue);
        },
      );

      test(
        'resolveSecondarySelection sets secondary without changing primary when no collision',
        () {
          final result = BibleTranslationInfo.resolveSecondarySelection(
            currentPrimary: 'DRC',
            currentSecondary: null,
            newSecondary: 'VUL',
          );
          expect(result.primary, equals('DRC'));
          expect(result.secondary, equals('VUL'));
          expect(result.primaryChanged, isFalse);
        },
      );

      test(
        'resolveSecondarySelection swaps primary to previous secondary when newSecondary collides with currentPrimary',
        () {
          final result = BibleTranslationInfo.resolveSecondarySelection(
            currentPrimary: 'DRC',
            currentSecondary: 'VUL',
            newSecondary: 'DRC',
          );
          expect(result.primary, equals('VUL'));
          expect(result.secondary, equals('DRC'));
          expect(result.primaryChanged, isTrue);
        },
      );

      test(
        'resolveSecondarySelection falls back to first alternative translation when colliding and no previous secondary exists',
        () {
          final result = BibleTranslationInfo.resolveSecondarySelection(
            currentPrimary: 'DRC',
            currentSecondary: null,
            newSecondary: 'DRC',
          );
          expect(result.primary, equals('VUL'));
          expect(result.secondary, equals('DRC'));
          expect(result.primaryChanged, isTrue);
        },
      );

      test(
        'resolveSecondarySelection clears secondary when newSecondary is null or "none"',
        () {
          final clearedNull = BibleTranslationInfo.resolveSecondarySelection(
            currentPrimary: 'DRC',
            currentSecondary: 'VUL',
            newSecondary: null,
          );
          expect(clearedNull.primary, equals('DRC'));
          expect(clearedNull.secondary, isNull);
          expect(clearedNull.primaryChanged, isFalse);

          final clearedNone = BibleTranslationInfo.resolveSecondarySelection(
            currentPrimary: 'DRC',
            currentSecondary: 'VUL',
            newSecondary: 'none',
          );
          expect(clearedNone.primary, equals('DRC'));
          expect(clearedNone.secondary, isNull);
          expect(clearedNone.primaryChanged, isFalse);
        },
      );

      test(
        'swapSelections exchanges primary and secondary when secondary is set',
        () {
          final swapped = BibleTranslationInfo.swapSelections(
            currentPrimary: 'CPDV',
            currentSecondary: 'DRC',
          );
          expect(swapped.primary, equals('DRC'));
          expect(swapped.secondary, equals('CPDV'));
          expect(swapped.primaryChanged, isTrue);
        },
      );

      test('swapSelections is a no-op when secondary is null or "none"', () {
        final noOp = BibleTranslationInfo.swapSelections(
          currentPrimary: 'CPDV',
          currentSecondary: null,
        );
        expect(noOp.primary, equals('CPDV'));
        expect(noOp.secondary, isNull);
        expect(noOp.primaryChanged, isFalse);
      });
    });
  });
}
