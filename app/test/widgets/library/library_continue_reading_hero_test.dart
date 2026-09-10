import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_continue_reading_hero.dart';
import '../../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog = LibraryHelper.getCatalog();
  final singleBook = catalog.firstWhere((b) => !b.isSeries);
  final seriesBook = catalog.firstWhere(
    (b) => b.isSeries && b.volumes != null && b.volumes!.isNotEmpty,
  );
  final seriesVol = seriesBook.volumes!.first;

  testWidgets('renders SizedBox.shrink when book not found in catalog', (
    tester,
  ) async {
    final pos = BookReadingPosition(
      bookId: 'non_existent_book',
      sectionIndex: 0,
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryContinueReadingHero(
            readingPosition: pos,
            catalog: catalog,
            onResume: (_, {volumeKey, assetPath, sectionIndex, sectionId}) {},
          ),
        ),
      ),
    );

    expect(find.text('CONTINUE READING'), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('renders single book resume card and triggers onResume', (
    tester,
  ) async {
    final pos = BookReadingPosition(
      bookId: singleBook.id,
      sectionIndex: 3,
      sectionId: 'sec_4',
      updatedAt: DateTime.now(),
    );

    LibraryBookItem? resumedBook;
    String? resumedVolKey;
    String? resumedAssetPath;
    int? resumedSectionIndex;
    String? resumedSectionId;

    await tester.pumpWidget(
      buildTestableWidget(
        child: Scaffold(
          body: LibraryContinueReadingHero(
            readingPosition: pos,
            catalog: catalog,
            onResume: (book, {volumeKey, assetPath, sectionIndex, sectionId}) {
              resumedBook = book;
              resumedVolKey = volumeKey;
              resumedAssetPath = assetPath;
              resumedSectionIndex = sectionIndex;
              resumedSectionId = sectionId;
            },
          ),
        ),
      ),
    );

    expect(find.text('CONTINUE READING'), findsOneWidget);
    expect(find.text(singleBook.title), findsOneWidget);
    expect(find.text('Section 4'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();

    expect(resumedBook?.id, singleBook.id);
    expect(resumedVolKey, isNull);
    expect(resumedAssetPath, isNull);
    expect(resumedSectionIndex, 3);
    expect(resumedSectionId, 'sec_4');
  });

  testWidgets(
    'renders series volume resume card and passes volume data to onResume',
    (tester) async {
      final pos = BookReadingPosition(
        bookId: seriesBook.id,
        volumeKey: seriesVol.volumeKey,
        sectionIndex: 1,
        sectionId: 'chap_2',
        updatedAt: DateTime.now(),
      );

      LibraryBookItem? resumedBook;
      String? resumedVolKey;
      String? resumedAssetPath;
      int? resumedSectionIndex;
      String? resumedSectionId;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryContinueReadingHero(
              readingPosition: pos,
              catalog: catalog,
              onResume:
                  (book, {volumeKey, assetPath, sectionIndex, sectionId}) {
                    resumedBook = book;
                    resumedVolKey = volumeKey;
                    resumedAssetPath = assetPath;
                    resumedSectionIndex = sectionIndex;
                    resumedSectionId = sectionId;
                  },
            ),
          ),
        ),
      );

      expect(find.text('CONTINUE READING'), findsOneWidget);
      expect(find.text(seriesBook.title), findsOneWidget);
      expect(find.text(seriesVol.name), findsOneWidget);
      expect(find.text('Section 2'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pump();

      expect(resumedBook?.id, seriesBook.id);
      expect(resumedVolKey, seriesVol.volumeKey);
      expect(resumedAssetPath, seriesVol.assetPath);
      expect(resumedSectionIndex, 1);
      expect(resumedSectionId, 'chap_2');
    },
  );
}
