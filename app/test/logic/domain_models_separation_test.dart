import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';
import 'package:twelve_stars/logic/catalog/library_annotation_resolver.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/user_settings_model.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_dialog.dart';

void main() {
  group('BibleTranslationInfo.resolveForBook & usfmAssetPathForBook', () {
    test(
      'resolveForBook returns preferred translation when book is supported',
      () {
        expect(
          BibleTranslationInfo.resolveForBook('LXX', 1).code,
          equals('LXX'),
        );
        expect(
          BibleTranslationInfo.resolveForBook('DRC', 49).code,
          equals('DRC'),
        );
      },
    );

    test(
      'resolveForBook falls back when preferred translation does not support book or is unknown',
      () {
        expect(
          BibleTranslationInfo.resolveForBook('LXX', 49).code,
          equals('CPDV'),
        );
        expect(
          BibleTranslationInfo.resolveForBook(
            'LXX',
            49,
            fallbackCode: 'VUL',
          ).code,
          equals('VUL'),
        );
        expect(
          BibleTranslationInfo.resolveForBook('UNKNOWN', 1).code,
          equals('CPDV'),
        );
      },
    );

    test(
      'usfmAssetPathForBook returns expected asset paths and null for unsupported books',
      () {
        expect(
          BibleTranslationInfo.getByCode('DRC').usfmAssetPathForBook(1, 'GEN'),
          equals('assets/bible/drc/usfm/01-GEN-ENG[B]DRC1899[pd].usfm'),
        );
        expect(
          BibleTranslationInfo.getByCode('JUN').usfmAssetPathForBook(1, 'GEN'),
          equals('assets/bible/jun/usfm/01-GEN-SPA[B]JUN1928[pd].usfm'),
        );
        expect(
          BibleTranslationInfo.getByCode('TAM').usfmAssetPathForBook(1, 'GEN'),
          equals('assets/bible/tam/usfm/01-GEN-SPA[B]TAM1836[pd].usfm'),
        );
        expect(
          BibleTranslationInfo.getByCode('VUL').usfmAssetPathForBook(1, 'GEN'),
          equals('assets/bible/vul/usfm/01-GEN-LAT[B]VUL1592[pd].usfm'),
        );
        expect(
          BibleTranslationInfo.getByCode('LXX').usfmAssetPathForBook(1, 'GEN'),
          equals('assets/bible/lxx/usfm/01-GEN-GRC[B]LXX[pd].usfm'),
        );
        expect(
          BibleTranslationInfo.getByCode(
            'ORIG',
          ).usfmAssetPathForBook(49, 'MAT'),
          equals('assets/bible/orig/usfm/49-MAT-ORIG[pd].usfm'),
        );
        expect(
          BibleTranslationInfo.getByCode(
            'CPDV',
          ).usfmAssetPathForBook(49, 'MAT'),
          equals('assets/bible/cpdv/usfm/49-MAT-ENG[B]CPDV2025[pd].usfm'),
        );
        expect(
          BibleTranslationInfo.getByCode('LXX').usfmAssetPathForBook(49, 'MAT'),
          isNull,
        );
      },
    );
  });

  group('BibleTranslationSelectorDialog normalization and swap behavior', () {
    testWidgets(
      'treats currentCompareCode "none" as null and swaps primary to previous compare when selecting primary as secondary',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        String primary = 'VUL';
        String? compare = 'none';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleTranslationSelectorDialog(
                currentPrimaryCode: primary,
                currentCompareCode: compare,
                initialTarget: BibleTranslationTarget.compare,
                onPrimarySelected: (val) => primary = val,
                onCompareSelected: (val) => compare = val,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 'none' should render as 'None' with swap button disabled and no clear button
        expect(find.text('None'), findsOneWidget);
        expect(find.byTooltip('Clear Secondary'), findsNothing);
        final swapButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(swapButton.onPressed, isNull);

        // Select JUN as secondary first
        await tester.tap(find.text('Biblia Torres Amat'));
        await tester.pumpAndSettle();
        expect(primary, equals('VUL'));
        expect(compare, equals('JUN'));

        // Now select VUL (current primary) while in Secondary mode:
        // Primary should swap to previous secondary (JUN) rather than DRC!
        await tester.tap(find.text('Sixto-Clementine Vulgate (Biblia Sacra)'));
        await tester.pumpAndSettle();
        expect(primary, equals('JUN'));
        expect(compare, equals('VUL'));
      },
    );
  });

  group('UserSettings direct import from user_settings_model.dart', () {
    test(
      'supports theme, numbering system, language resolution, and copyWith',
      () {
        final settings = UserSettings(
          primaryLanguageCode: 'latin',
          compareLanguageCode: 'none',
          appThemeModeCode: 'liturgical',
          bibleNumberingSystemCode: 'modern',
          bibleRibbons: const [
            BibleRibbonBookmark(ribbonIndex: 0, bookNumber: 49, chapter: 5),
          ],
        );

        expect(settings.appThemeMode, equals(AppThemeMode.liturgical));
        expect(
          settings.bibleNumberingSystem,
          equals(BibleNumberingSystem.modern),
        );
        expect(settings.primaryLanguage.code, equals('latin'));
        expect(settings.compareLanguage, isNull);
        expect(settings.bibleRibbons, hasLength(1));

        final updated = settings.copyWith(primaryBibleTranslation: 'DRC');
        expect(updated.primaryBibleTranslation, equals('DRC'));
        expect(updated.appThemeMode, equals(AppThemeMode.liturgical));
      },
    );
  });

  group('resolveLibraryAnnotation series volume resolution', () {
    final seriesCatalog = <LibraryBookItem>[
      const LibraryBookItem(
        id: 'summa_theologiae',
        title: 'Summa Theologiae',
        subtitle: 'Complete Theological Treatise',
        author: 'St. Thomas Aquinas',
        description: 'Summa',
        category: 'Theology',
        volumes: [
          BaltimoreVolume(
            volumeKey: 'summa_i',
            name: 'First Part (Prima Pars)',
            shortName: 'Part I',
            description: 'First Part',
            assetPath: 'assets/library/summa/prima_pars.json',
          ),
          BaltimoreVolume(
            volumeKey: 'summa_ii_ii',
            name: 'Second Part of the Second Part',
            shortName: 'Part II-II',
            description: 'Secunda Secundae',
            assetPath: 'assets/library/summa/secunda_secundae.json',
          ),
        ],
      ),
    ];

    test('resolves explicit volumeKey on a series book', () {
      final resolved = resolveLibraryAnnotation(
        documentId: 'summa_theologiae',
        nodeId: 'summa_ii_ii:q1-a1_2',
        catalog: seriesCatalog,
      );

      expect(resolved.book?.id, equals('summa_theologiae'));
      expect(resolved.volumeKey, equals('summa_ii_ii'));
      expect(
        resolved.assetPath,
        equals('assets/library/summa/secunda_secundae.json'),
      );
      expect(resolved.sectionId, equals('q1-a1'));
      expect(resolved.itemIndex, equals(2));
    });

    test('does not coerce missing volumeKey to Volume 1 on a series book', () {
      final resolved = resolveLibraryAnnotation(
        documentId: 'summa_theologiae',
        nodeId: 'q1-a1_2',
        catalog: seriesCatalog,
      );

      expect(resolved.book?.id, equals('summa_theologiae'));
      expect(resolved.volumeKey, isNull);
      expect(resolved.assetPath, isNull);
      expect(resolved.sectionId, equals('q1-a1'));
      expect(resolved.itemIndex, equals(2));
    });
  });
}
