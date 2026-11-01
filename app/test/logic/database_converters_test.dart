import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/database_converters.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/thematic_models.dart';
import 'package:twelve_stars/widgets/common/dual_target_selector_row.dart';
import 'package:twelve_stars/widgets/library/library_annotations_list_shell.dart';
import '../test_helper.dart';

void main() {
  group('JsonModelListConverter & Concrete Converters', () {
    test(
      'LocalizedTranslationsConverter round-trips and handles malformed inputs',
      () {
        const converter = LocalizedTranslationsConverter();

        expect(converter.fromSql(''), isEmpty);
        expect(converter.fromSql('not json'), isEmpty);
        expect(converter.fromSql('{"not": "a list"}'), isEmpty);
        expect(
          converter.fromSql('[123, "skip", {"languageCode": "latin"}]'),
          hasLength(1),
        );

        final items = [
          LocalizedTranslations(
            languageCode: 'english',
            list: [
              PrayerTranslation(title: 'Our Father', text: 'Our Father...'),
            ],
          ),
        ];
        final sql = converter.toSql(items);
        final decoded = converter.fromSql(sql);

        expect(decoded, hasLength(1));
        expect(decoded.first.languageCode, 'english');
        expect(decoded.first.list?.first.title, 'Our Father');
      },
    );

    test(
      'PreferredVersionsConverter round-trips and skips non-map elements',
      () {
        const converter = PreferredVersionsConverter();

        expect(converter.fromSql(''), isEmpty);
        expect(converter.fromSql('invalid'), isEmpty);
        expect(
          converter.fromSql(
            '[null, {"key": "ave_maria:latin", "versionIndex": 2}]',
          ),
          hasLength(1),
        );

        final prefs = [
          PrayerVersionPreference('pater_noster:english', 1),
          PrayerVersionPreference('ave_maria:latin', 0),
        ];
        final sql = converter.toSql(prefs);
        final roundTrip = converter.fromSql(sql);

        expect(roundTrip, hasLength(2));
        expect(roundTrip[0].key, 'pater_noster:english');
        expect(roundTrip[0].versionIndex, 1);
        expect(roundTrip[1].key, 'ave_maria:latin');
        expect(roundTrip[1].versionIndex, 0);
      },
    );

    test('BibleRibbonsConverter round-trips and handles invalid JSON', () {
      const converter = BibleRibbonsConverter();

      expect(converter.fromSql(''), isEmpty);
      expect(converter.fromSql('corrupt'), isEmpty);

      const ribbons = [
        BibleRibbonBookmark(ribbonIndex: 0, bookNumber: 1, chapter: 1),
        BibleRibbonBookmark(ribbonIndex: 2, bookNumber: 43, chapter: 3),
      ];
      final sql = converter.toSql(ribbons);
      final roundTrip = converter.fromSql(sql);

      expect(roundTrip, equals(ribbons));
    });

    test(
      'Generic JsonModelListConverter supports direct function callbacks',
      () {
        final converter = JsonModelListConverter<ThematicPassage>(
          fromJson: ThematicPassage.fromJson,
          toJson: (item) => item.toJson(),
        );

        final passage = ThematicPassage(
          bookId: 'didache_lightfoot',
          bookTitle: 'The Didache',
          author: 'Anonymous',
          sectionId: 'ch1',
          sectionTitle: 'Chapter 1',
          itemIndex: 2,
          questionNumber: 5,
          primaryTheme: 'sacraments.eucharist',
          secondaryThemes: const ['prayer.vocal_mental_meditation'],
          keyExcerpt: 'Two Ways',
          oneSentenceSummary: 'Teaching of the Lord.',
          fullText: 'There are two ways, one of life and one of death.',
        );

        final sql = converter.toSql([passage]);
        final decoded = converter.fromSql(sql);

        expect(decoded, hasLength(1));
        expect(decoded.first.bookId, 'didache_lightfoot');
        expect(decoded.first.questionNumber, 5);
        expect(decoded.first.primaryTheme, 'sacraments.eucharist');
        expect(decoded.first.secondaryThemes, [
          'prayer.vocal_mental_meditation',
        ]);
      },
    );
  });

  group('ThematicPassage & ThematicTaxonomyData (Pure Dart Models)', () {
    test('ThematicPassage serializes and deserializes via toJson/fromJson', () {
      final passage = ThematicPassage(
        bookId: 'clement_1',
        bookTitle: 'First Clement',
        author: 'St. Clement',
        sectionId: 'sec1',
        sectionTitle: 'Section 1',
        itemIndex: 3,
        questionNumber: 7,
        primaryTheme: 'ecclesiology.church_unity_papacy',
        secondaryThemes: const ['virtues.humility_meekness'],
        keyExcerpt: 'Let us be humble',
        oneSentenceSummary: 'Humility preserves unity.',
        fullText: 'Full text of the passage.',
        authorSaintId: 'clement-of-rome',
      );

      final json = passage.toJson();
      final restored = ThematicPassage.fromJson(
        json,
        authorSaintId: 'clement-of-rome',
      );

      expect(restored.bookId, passage.bookId);
      expect(restored.questionNumber, 7);
      expect(restored.primaryTheme, passage.primaryTheme);
      expect(restored.secondaryThemes, passage.secondaryThemes);
      expect(restored.authorSaintId, 'clement-of-rome');
    });

    test('ThematicTaxonomyData normalizes and validates themes', () {
      expect(ThematicTaxonomyData.categoryGroups, hasLength(7));
      expect(ThematicTaxonomyData.allThemes, hasLength(35));
      expect(ThematicTaxonomyData.isValidTheme('sacraments.eucharist'), isTrue);
      expect(ThematicTaxonomyData.isValidTheme('invalid.theme'), isFalse);
      expect(
        ThematicTaxonomyData.normalizeTheme(' `SACRAMENTS.EUCHARIST` '),
        'sacraments.eucharist',
      );
      expect(ThematicTaxonomyData.normalizeTheme('unknown'), isNull);
    });
  });

  group('DualTargetSelectorRow Widget', () {
    testWidgets('renders primary, secondary, and swap button states', (
      tester,
    ) async {
      int swaps = 0;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: DualTargetSelectorRow(
              canSwap: true,
              onSwap: () => swaps++,
              swapTooltip: 'Custom Swap Tooltip',
              primaryChild: const Text('Primary Slot'),
              secondaryChild: const Text('Secondary Slot'),
            ),
          ),
        ),
      );

      expect(find.text('Primary Slot'), findsOneWidget);
      expect(find.text('Secondary Slot'), findsOneWidget);
      expect(find.byTooltip('Custom Swap Tooltip'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.swap_horiz));
      await tester.pump();
      expect(swaps, 1);
    });
  });

  group('LibraryAnnotationsListShell Widget', () {
    testWidgets(
      'resets selected book filter to all when filtered book items are removed',
      (tester) async {
        final itemsInitial = [
          (id: '1', docId: 'didache_lightfoot', label: 'Didache Note'),
          (
            id: '2',
            docId: 'first_clement_lightfoot',
            label: 'First Clement Note',
          ),
        ];

        Widget buildShell(
          List<({String id, String docId, String label})> items,
        ) {
          return buildTestableWidget(
            child: Scaffold(
              body:
                  LibraryAnnotationsListShell<
                    ({String id, String docId, String label})
                  >(
                    items: items,
                    isLoading: false,
                    emptyIcon: Icons.bookmark_outline,
                    emptyTitle: 'Empty Title',
                    emptySubtitle: 'Empty Subtitle',
                    documentIdOf: (item) => item.docId,
                    itemBuilder: (context, item, catalog) =>
                        ListTile(title: Text(item.label)),
                  ),
            ),
          );
        }

        await tester.pumpWidget(buildShell(itemsInitial));
        await tester.pumpAndSettle();

        // Filter to Didache
        await tester.tap(find.text('The Didache (1)'));
        await tester.pumpAndSettle();
        expect(find.text('Didache Note'), findsOneWidget);
        expect(find.text('First Clement Note'), findsNothing);

        // Rebuild with Didache item removed -> filter should reset to 'all'
        await tester.pumpWidget(buildShell([itemsInitial[1]]));
        await tester.pumpAndSettle();

        expect(find.text('First Clement Note'), findsOneWidget);
      },
    );
  });
}
