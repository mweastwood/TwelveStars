import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_book_card.dart';
import 'package:twelve_stars/widgets/library/library_search_results_view.dart';
import 'package:twelve_stars/widgets/library/library_volume_picker_sheet.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const singleBook = LibraryBookItem(
    id: 'single_book_1',
    title: 'Single Volume Work',
    subtitle: 'Treatise on Prayer',
    category: 'Spiritual Classics',
    author: 'St. Example',
    era: '16th Century',
    description: 'A classic treatise on mental prayer.',
    defaultAssetPath: 'assets/books/single_book_1.json',
  );

  const seriesBook = LibraryBookItem(
    id: 'series_book_1',
    title: 'Multi-Volume Catechism',
    subtitle: 'Complete Series',
    category: 'Catechisms',
    author: 'Council Fathers',
    description: 'A multi-volume catechetical series.',
    volumes: [
      BaltimoreVolume(
        volumeKey: 'vol1',
        name: 'Volume I: The Creed',
        shortName: 'Vol. I',
        description: 'Exposition of the Apostles Creed',
        assetPath: 'assets/books/series_vol1.json',
      ),
      BaltimoreVolume(
        volumeKey: 'vol2',
        name: 'Volume II: The Sacraments',
        shortName: 'Vol. II',
        description: 'Exposition of the Seven Sacraments',
        assetPath: 'assets/books/series_vol2.json',
      ),
    ],
  );

  const webBook = LibraryBookItem(
    id: 'web_book_1',
    title: 'Online Catechism Resource',
    subtitle: 'Official Vatican Text',
    category: 'Catechisms',
    author: 'Holy See',
    description: 'An external online doctrinal resource.',
    webUrl: 'https://example.com/catechism',
  );

  group('LibraryBookCard', () {
    testWidgets('renders single-volume book and invokes onOpenReader on tap', (
      tester,
    ) async {
      LibraryBookItem? openedBook;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: LibraryBookCard(
                bookItem: singleBook,
                onOpenReader: (book, {volumeKey, assetPath}) {
                  openedBook = book;
                },
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('book_card_single_book_1')),
        findsOneWidget,
      );
      expect(find.text('Single Volume Work'), findsOneWidget);
      expect(find.text('Treatise on Prayer'), findsOneWidget);
      expect(find.text('By St. Example'), findsOneWidget);
      expect(find.text('16th Century'), findsOneWidget);
      expect(find.text('Spiritual Classics'), findsOneWidget);
      expect(find.text('A classic treatise on mental prayer.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Read Book'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Read Book'));
      await tester.pumpAndSettle();

      expect(openedBook, equals(singleBook));
    });

    testWidgets(
      'renders multi-volume badge and volume chips and invokes callbacks',
      (tester) async {
        LibraryBookItem? openedBook;
        String? openedVolumeKey;
        String? openedAssetPath;
        bool browseTapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: SingleChildScrollView(
                child: LibraryBookCard(
                  bookItem: seriesBook,
                  onOpenReader: (book, {volumeKey, assetPath}) {
                    openedBook = book;
                    openedVolumeKey = volumeKey;
                    openedAssetPath = assetPath;
                  },
                  onBrowseVolumes: () {
                    browseTapped = true;
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('2 Volumes'), findsOneWidget);
        expect(find.text('Select Volume (2):'), findsOneWidget);
        expect(
          find.widgetWithText(ActionChip, 'Volume I: The Creed'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ActionChip, 'Volume II: The Sacraments'),
          findsOneWidget,
        );

        await tester.tap(
          find.widgetWithText(ActionChip, 'Volume II: The Sacraments'),
        );
        await tester.pumpAndSettle();

        expect(openedBook, equals(seriesBook));
        expect(openedVolumeKey, 'vol2');
        expect(openedAssetPath, 'assets/books/series_vol2.json');

        await tester.tap(find.widgetWithText(TextButton, 'Browse All ▾'));
        await tester.pumpAndSettle();
        expect(browseTapped, isTrue);
      },
    );

    testWidgets('renders web link badge and Read Online button', (
      tester,
    ) async {
      LibraryBookItem? openedBook;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: LibraryBookCard(
                bookItem: webBook,
                onOpenReader: (book, {volumeKey, assetPath}) {
                  openedBook = book;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Online Work'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Read Online'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Read Book'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Read Online'));
      await tester.pumpAndSettle();

      expect(openedBook, equals(webBook));
    });

    test('LibraryCategoryIcons.forCategory returns expected icons', () {
      expect(
        LibraryCategoryIcons.forCategory('Apostolic Fathers'),
        Icons.history_edu_rounded,
      );
      expect(
        LibraryCategoryIcons.forCategory('Doctors of the Church'),
        Icons.school_rounded,
      );
      expect(
        LibraryCategoryIcons.forCategory('Unknown Category'),
        Icons.menu_book_rounded,
      );
    });
  });

  group('LibraryVolumePickerSheet', () {
    testWidgets('displays volumes and selects a volume', (tester) async {
      BaltimoreVolume? selectedVolume;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryVolumePickerSheet(
              bookItem: seriesBook,
              onSelectVolume: (vol) {
                selectedVolume = vol;
              },
            ),
          ),
        ),
      );

      expect(find.text('Multi-Volume Catechism'), findsOneWidget);
      expect(find.text('Select from 2 volumes'), findsOneWidget);
      expect(find.text('Volume I: The Creed'), findsOneWidget);
      expect(find.text('Exposition of the Apostles Creed'), findsOneWidget);
      expect(find.text('Volume II: The Sacraments'), findsOneWidget);
      expect(find.text('Exposition of the Seven Sacraments'), findsOneWidget);

      await tester.tap(find.text('Volume II: The Sacraments'));
      await tester.pumpAndSettle();

      expect(selectedVolume, isNotNull);
      expect(selectedVolume!.volumeKey, 'vol2');
      expect(selectedVolume!.assetPath, 'assets/books/series_vol2.json');
    });

    testWidgets('static show opens modal sheet and selects volume', (
      tester,
    ) async {
      BaltimoreVolume? selectedVolume;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LibraryVolumePickerSheet.show(
                  context,
                  bookItem: seriesBook,
                  onSelectVolume: (vol) {
                    selectedVolume = vol;
                  },
                ),
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Select from 2 volumes'), findsOneWidget);

      await tester.tap(find.text('Volume I: The Creed'));
      await tester.pumpAndSettle();

      expect(selectedVolume, isNotNull);
      expect(selectedVolume!.volumeKey, 'vol1');
    });
  });

  group('LibrarySearchResultsView', () {
    testWidgets('renders loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibrarySearchResultsView(
              searchQuery: 'grace',
              isLoading: true,
              results: const [],
              catalog: const [singleBook, seriesBook],
              onOpenReader:
                  (
                    book, {
                    volumeKey,
                    assetPath,
                    sectionId,
                    questionNumber,
                    itemIndex,
                  }) {},
            ),
          ),
        ),
      );

      expect(find.text('SEARCH RESULTS'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state when results are empty', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibrarySearchResultsView(
              searchQuery: 'nonexistent',
              isLoading: false,
              results: const [],
              catalog: const [singleBook, seriesBook],
              onOpenReader:
                  (
                    book, {
                    volumeKey,
                    assetPath,
                    sectionId,
                    questionNumber,
                    itemIndex,
                  }) {},
            ),
          ),
        ),
      );

      expect(find.text('SEARCH RESULTS'), findsOneWidget);
      expect(
        find.text('No search results found for "nonexistent".'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders grouped book results and triggers onOpenReader on tap',
      (tester) async {
        final results = [
          BookSearchResult(
            bookId: 'single_book_1',
            bookTitle: 'Single Volume Work',
            sectionId: 'sec_1',
            sectionTitle: 'Chapter 1: On Prayer',
            matchedSnippet:
                'Prayer is the raising of the mind and heart to God.',
            itemIndex: 3,
          ),
          BookSearchResult(
            bookId: 'series_book_1',
            volumeKey: 'vol2',
            assetPath: 'assets/books/series_vol2.json',
            bookTitle: 'Multi-Volume Catechism',
            sectionId: 'sec_sacraments',
            sectionTitle: 'Lesson 12: Baptism',
            matchedSnippet: 'Q. 120 What is Baptism?',
            itemIndex: 0,
            questionNumber: 120,
          ),
          BookSearchResult(
            bookId: 'series_book_1',
            volumeKey: 'vol2',
            assetPath: 'assets/books/series_vol2.json',
            bookTitle: 'Multi-Volume Catechism',
            sectionId: 'sec_eucharist',
            sectionTitle: 'Lesson 15: The Eucharist',
            matchedSnippet: 'Q. 150 What is the Holy Eucharist?',
            itemIndex: 4,
            questionNumber: 150,
          ),
        ];

        LibraryBookItem? tappedBook;
        String? tappedVolumeKey;
        String? tappedAssetPath;
        String? tappedSectionId;
        int? tappedItemIndex;
        int? tappedQuestionNumber;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: SingleChildScrollView(
                child: LibrarySearchResultsView(
                  searchQuery: 'sacrament',
                  isLoading: false,
                  results: results,
                  catalog: const [singleBook, seriesBook],
                  onOpenReader:
                      (
                        book, {
                        volumeKey,
                        assetPath,
                        sectionId,
                        questionNumber,
                        itemIndex,
                      }) {
                        tappedBook = book;
                        tappedVolumeKey = volumeKey;
                        tappedAssetPath = assetPath;
                        tappedSectionId = sectionId;
                        tappedItemIndex = itemIndex;
                        tappedQuestionNumber = questionNumber;
                      },
                ),
              ),
            ),
          ),
        );

        expect(find.text('Single Volume Work'), findsOneWidget);
        expect(find.text('1 match'), findsOneWidget);
        expect(find.text('Multi-Volume Catechism'), findsOneWidget);
        expect(find.text('2 matches'), findsOneWidget);
        expect(find.text('Chapter 1: On Prayer'), findsOneWidget);
        expect(find.text('Lesson 12: Baptism'), findsOneWidget);
        expect(find.text('Lesson 15: The Eucharist'), findsOneWidget);

        await tester.tap(find.text('Lesson 12: Baptism'));
        await tester.pumpAndSettle();

        expect(tappedBook, equals(seriesBook));
        expect(tappedVolumeKey, 'vol2');
        expect(tappedAssetPath, 'assets/books/series_vol2.json');
        expect(tappedSectionId, 'sec_sacraments');
        expect(tappedItemIndex, 0);
        expect(tappedQuestionNumber, 120);
      },
    );
  });
}
