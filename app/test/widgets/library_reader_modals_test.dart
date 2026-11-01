import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';
import 'package:twelve_stars/widgets/library/library_reader_modals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryReaderAdapter.formatSectionSelection', () {
    final qaSection = BookSection(
      id: 'sec_1',
      title: 'Lesson 1: On the End of Man',
      subtitle: 'Questions 1-3',
      content: [
        ContentItem(
          type: 'qa',
          questionNumber: 1,
          question: 'Who made the world?',
          answer: 'God made the world.',
        ),
        ContentItem(
          type: 'qa',
          questionNumber: 2,
          question: 'Who is God?',
          answer: 'God is the Creator of heaven and earth.',
        ),
        ContentItem(
          type: 'qa',
          questionNumber: 3,
          question: 'What is man?',
          answer: 'Man is a creature composed of body and soul.',
        ),
      ],
    );

    final paragraphSection = BookSection(
      id: 'ch_1',
      title: 'Chapter 1: The Two Ways',
      subtitle: '',
      content: [
        ContentItem(
          type: 'paragraph',
          text: 'There are two ways, one of life and one of death.',
        ),
        ContentItem(
          type: 'paragraph',
          text: 'First of all, thou shalt love the God who made thee.',
        ),
      ],
    );

    test('formats single QA item without volume title', () {
      final result = LibraryReaderAdapter.formatSectionSelection(
        section: qaSection,
        startIndex: 0,
        endIndex: 0,
      );

      expect(result.citation, equals('Lesson 1: On the End of Man, Q. 1'));
      expect(
        result.textPreview,
        equals('Q. Who made the world?\nA. God made the world.'),
      );
    });

    test('formats single QA item with volume title', () {
      final result = LibraryReaderAdapter.formatSectionSelection(
        section: qaSection,
        startIndex: 1,
        endIndex: 1,
        volumeTitle: 'Baltimore Catechism (No. 1)',
      );

      expect(
        result.citation,
        equals(
          'Baltimore Catechism (No. 1), Lesson 1: On the End of Man, Q. 2',
        ),
      );
      expect(
        result.textPreview,
        equals('Q. Who is God?\nA. God is the Creator of heaven and earth.'),
      );
    });

    test('formats multi-QA range without volume title', () {
      final result = LibraryReaderAdapter.formatSectionSelection(
        section: qaSection,
        startIndex: 0,
        endIndex: 2,
      );

      expect(result.citation, equals('Lesson 1: On the End of Man, QQ. 1-3'));
      expect(
        result.textPreview,
        equals(
          'Q. Who made the world?\nA. God made the world.\n\n'
          'Q. Who is God?\nA. God is the Creator of heaven and earth.\n\n'
          'Q. What is man?\nA. Man is a creature composed of body and soul.',
        ),
      );
    });

    test('formats multi-QA range with volume title and reversed indices', () {
      final result = LibraryReaderAdapter.formatSectionSelection(
        section: qaSection,
        startIndex: 2,
        endIndex: 0,
        volumeTitle: 'No. 2',
      );

      expect(
        result.citation,
        equals('No. 2, Lesson 1: On the End of Man, QQ. 1-3'),
      );
      expect(
        result.textPreview,
        contains('Q. Who made the world?\nA. God made the world.'),
      );
      expect(
        result.textPreview,
        contains(
          'Q. What is man?\nA. Man is a creature composed of body and soul.',
        ),
      );
    });

    test('formats paragraph items with and without volume title', () {
      final withoutVol = LibraryReaderAdapter.formatSectionSelection(
        section: paragraphSection,
        startIndex: 0,
        endIndex: 1,
      );
      expect(withoutVol.citation, equals('Chapter 1: The Two Ways'));
      expect(
        withoutVol.textPreview,
        equals(
          'There are two ways, one of life and one of death.\n\n'
          'First of all, thou shalt love the God who made thee.',
        ),
      );

      final withVol = LibraryReaderAdapter.formatSectionSelection(
        section: paragraphSection,
        startIndex: 0,
        endIndex: 1,
        volumeTitle: 'The Didache',
      );
      expect(withVol.citation, equals('The Didache, Chapter 1: The Two Ways'));
      expect(
        withVol.textPreview,
        equals(
          'There are two ways, one of life and one of death.\n\n'
          'First of all, thou shalt love the God who made thee.',
        ),
      );
    });

    test('handles empty section content gracefully', () {
      final emptySection = BookSection(
        id: 'empty',
        title: 'Empty Section',
        subtitle: '',
        content: const [],
      );

      final res = LibraryReaderAdapter.formatSectionSelection(
        section: emptySection,
        startIndex: 0,
        endIndex: 3,
        volumeTitle: 'Volume I',
      );
      expect(res.citation, equals('Volume I, Empty Section'));
      expect(res.textPreview, isEmpty);
    });
  });

  group('LibraryReaderModals Widget Tests', () {
    final testVolumes = [
      const BaltimoreVolume(
        volumeKey: 'baltimore_1',
        name: 'Baltimore Catechism No. 1',
        shortName: 'No. 1',
        description: 'First Communion Edition',
        assetPath: 'assets/catechism/json/baltimore_1.json',
      ),
      const BaltimoreVolume(
        volumeKey: 'baltimore_2',
        name: 'Baltimore Catechism No. 2',
        shortName: 'No. 2',
        description: 'Confirmation Edition',
        assetPath: 'assets/catechism/json/baltimore_2.json',
      ),
      const BaltimoreVolume(
        volumeKey: 'baltimore_4',
        name: 'Baltimore Catechism No. 4',
        shortName: 'No. 4',
        description: 'Fr. Kinkead Explanation',
        assetPath: 'assets/catechism/json/baltimore_4.json',
      ),
    ];

    late LibraryBookItem testBookItem;
    late ParsedBookData sampleBook;

    setUp(() {
      LibraryHelper.clearCache();
      testBookItem = LibraryBookItem(
        id: 'baltimore_catechism',
        title: 'Baltimore Catechism',
        subtitle: 'Official Catechism for Plenary Councils',
        category: 'Catechisms',
        author: 'Third Plenary Council of Baltimore',
        description: 'A classic summary of Catholic doctrine.',
        defaultAssetPath: 'assets/catechism/json/baltimore_1.json',
        volumes: testVolumes,
      );

      sampleBook = ParsedBookData(
        bookId: 'baltimore_catechism',
        title: 'Baltimore Catechism',
        subtitle: 'No. 1',
        author: 'Third Plenary Council of Baltimore',
        toc: const [],
        sections: [
          BookSection(
            id: 'sec_1',
            title: 'Lesson First: On the End of Man',
            subtitle: 'Questions 1-5',
            content: [
              ContentItem(
                type: 'qa',
                questionNumber: 1,
                question: 'Who made the world?',
                answer: 'God made the world.',
              ),
            ],
          ),
          BookSection(
            id: 'sec_2',
            title: 'Lesson Second: On God and His Perfections',
            subtitle: 'Questions 6-15',
            content: [
              ContentItem(
                type: 'qa',
                questionNumber: 6,
                question: 'Who is God?',
                answer: 'God is the Creator of heaven and earth.',
              ),
            ],
          ),
        ],
      );
    });

    tearDown(() {
      LibraryHelper.clearCache();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    testWidgets(
      'showLibraryReaderVolumePickerSheet displays volumes and invokes callback on selection',
      (tester) async {
        BaltimoreVolume? selectedVolume;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showLibraryReaderVolumePickerSheet(
                    context: context,
                    bookItem: testBookItem,
                    currentVolumeKey: 'baltimore_1',
                    onVolumeSelected: (vol) => selectedVolume = vol,
                  ),
                  child: const Text('Open Volume Picker'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Volume Picker'));
        await tester.pumpAndSettle();

        expect(find.text('Baltimore Catechism'), findsOneWidget);
        expect(find.text('Select from 3 volumes'), findsOneWidget);
        expect(find.text('Baltimore Catechism No. 1'), findsOneWidget);
        expect(find.text('Baltimore Catechism No. 2'), findsOneWidget);
        expect(find.text('Confirmation Edition'), findsOneWidget);

        await tester.tap(find.text('Baltimore Catechism No. 2'));
        await tester.pumpAndSettle();

        expect(selectedVolume, isNotNull);
        expect(selectedVolume!.volumeKey, equals('baltimore_2'));
      },
    );

    testWidgets(
      'showLibraryReaderTocSheet displays sections and invokes onSectionSelected',
      (tester) async {
        int? selectedSectionIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showLibraryReaderTocSheet(
                    context: context,
                    book: sampleBook,
                    currentSectionIndex: 0,
                    onSectionSelected: (idx) => selectedSectionIndex = idx,
                  ),
                  child: const Text('Open TOC'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open TOC'));
        await tester.pumpAndSettle();

        expect(find.text('Table of Contents'), findsOneWidget);
        expect(find.text('Lesson First: On the End of Man'), findsOneWidget);
        expect(
          find.text('Lesson Second: On God and His Perfections'),
          findsOneWidget,
        );

        await tester.tap(
          find.text('Lesson Second: On God and His Perfections'),
        );
        await tester.pumpAndSettle();

        expect(selectedSectionIndex, equals(1));
      },
    );

    testWidgets(
      'showLibraryReaderSearchDialog searches book content and returns tapped result',
      (tester) async {
        BookSearchResult? selectedResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showLibraryReaderSearchDialog(
                    context: context,
                    book: sampleBook,
                    onResultSelected: (res) => selectedResult = res,
                  ),
                  child: const Text('Open Search Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Search Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Search in Baltimore Catechism'), findsOneWidget);
        expect(
          find.text('Type a search term to find in this book.'),
          findsOneWidget,
        );

        await tester.enterText(find.byType(TextField), 'Creator');
        await tester.pumpAndSettle();

        expect(
          find.text('Lesson Second: On God and His Perfections'),
          findsOneWidget,
        );

        await tester.tap(
          find.text('Lesson Second: On God and His Perfections'),
        );
        await tester.pumpAndSettle();

        expect(selectedResult, isNotNull);
        expect(selectedResult!.sectionId, equals('sec_2'));
        expect(selectedResult!.questionNumber, equals(6));
      },
    );

    testWidgets(
      'showLibraryReaderCrossRefModal displays cross-reference content and switches volume',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
              final String key = utf8.decode(message!.buffer.asUint8List());
              final dummyData = {
                'bookId': key,
                'title': 'Book for $key',
                'subtitle': '',
                'author': '',
                'toc': [],
                'sections': [
                  {
                    'id': 'sec_1',
                    'title': 'Lesson 1',
                    'subtitle': '',
                    'content': [
                      {
                        'type': 'qa',
                        'questionNumber': 1,
                        'question': 'Who made the world?',
                        'answer': 'God made the world.',
                        'explanation': 'God created all things out of nothing.',
                      },
                    ],
                  },
                ],
              };
              final jsonStr = jsonEncode(dummyData);
              return ByteData.view(
                Uint8List.fromList(utf8.encode(jsonStr)).buffer,
              );
            });

        BaltimoreVolume? switchedVolume;
        int? switchedSectionIndex;
        int? switchedQuestionNumber;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showLibraryReaderCrossRefModal(
                    context: context,
                    questionNumber: 1,
                    bookItem: testBookItem,
                    onSwitchVolume: (vol, secIdx, [qNum]) {
                      switchedVolume = vol;
                      switchedSectionIndex = secIdx;
                      switchedQuestionNumber = qNum;
                    },
                  ),
                  child: const Text('Open Cross Ref Modal'),
                ),
              ),
            ),
          ),
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_2.json',
          );
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_4.json',
          );
        });

        await tester.tap(find.text('Open Cross Ref Modal'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text('Cross-Reference: Master Question #1'),
          findsOneWidget,
        );
        expect(
          find.text('Baltimore Catechism No. 2 (Confirmation Edition)'),
          findsOneWidget,
        );
        expect(
          find.text("Baltimore Catechism No. 4 (Fr. Kinkead's Explanation)"),
          findsOneWidget,
        );

        await tester.tap(find.text('Open Vol 2'));
        await tester.pumpAndSettle();

        expect(switchedVolume?.volumeKey, equals('baltimore_2'));
        expect(switchedSectionIndex, equals(0));
        expect(switchedQuestionNumber, equals(1));
      },
    );
  });
}
