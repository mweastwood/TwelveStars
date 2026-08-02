import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/bible_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 Reader Framework Models & Adapters Tests', () {
    late BibleDatabase memoryDb;

    setUp(() {
      memoryDb = BibleDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('ReaderContentNode models all required node types', () {
      const verseNode = ReaderContentNode(
        id: '1_1_1',
        nodeType: ReaderNodeType.verse,
        primaryText: 'In the beginning God created heaven, and earth.',
        secondaryText: 'In principio creavit Deus caelum et terram.',
      );
      expect(verseNode.nodeType, equals(ReaderNodeType.verse));
      expect(verseNode.primaryText, contains('In the beginning'));
      expect(verseNode.secondaryText, contains('In principio'));

      const qaNode = ReaderContentNode(
        id: '0_1',
        nodeType: ReaderNodeType.qa,
        questionNumber: '1',
        question: 'Who made the world?',
        answer: 'God made the world.',
        explanation: 'God is the creator of heaven and earth.',
        crossRefId: '2',
      );
      expect(qaNode.nodeType, equals(ReaderNodeType.qa));
      expect(qaNode.questionNumber, equals('1'));
      expect(qaNode.question, equals('Who made the world?'));
      expect(qaNode.explanation, contains('creator of heaven'));
    });

    test('ReaderDocument and ReaderTocEntry represent hierarchical TOC', () {
      const doc = ReaderDocument(
        documentId: 'test_doc',
        title: 'Baltimore Catechism',
        subtitle: 'No. 3',
        author: 'Third Plenary Council of Baltimore',
        sectionsCount: 37,
        tocEntries: [
          ReaderTocEntry(index: 0, title: 'Lesson 1: On the End of Man'),
          ReaderTocEntry(
            index: 1,
            title: 'Lesson 2: On God and His Perfections',
          ),
        ],
      );

      expect(doc.sectionsCount, equals(37));
      expect(doc.tocEntries.length, equals(2));
      expect(doc.tocEntries.first.title, contains('Lesson 1'));
    });

    test(
      'BibleReaderAdapter correctly converts Bible Book to Reader Document and Section',
      () async {
        const book = BibleBook(
          bookNumber: 1,
          bookName: 'Genesis',
          abbrev: 'GEN',
          chaptersCount: 50,
          category: 'Pentateuch',
          testament: 'Old Testament',
        );

        final adapter = BibleReaderAdapter(book: book, db: memoryDb);
        final doc = await adapter.loadDocument();

        expect(doc.documentId, equals('bible_1'));
        expect(doc.title, equals('Genesis'));
        expect(doc.sectionsCount, equals(50));
        expect(doc.tocEntries.length, equals(50));

        final section = await adapter.loadSection(1, primaryVariant: 'CPDV');
        expect(section.sectionIndex, equals(1));
        expect(section.title, equals('Genesis 1'));
        expect(section.nodes.isNotEmpty, isTrue);
        expect(section.nodes.first.nodeType, equals(ReaderNodeType.verse));
      },
    );

    test(
      'LibraryReaderAdapter loads document and section nodes cleanly',
      () async {
        final bookItem = LibraryHelper.getCatalog().first;

        final adapter = LibraryReaderAdapter(
          bookItem: bookItem,
          assetPath: bookItem.volumes!.first.assetPath,
        );

        final doc = await adapter.loadDocument();
        expect(doc.title, equals('Baltimore Catechism'));
        expect(doc.sectionsCount, greaterThan(0));

        final section = await adapter.loadSection(0);
        expect(section.title, isNotEmpty);
        expect(section.nodes, isNotEmpty);
      },
    );

    test('ReaderBookmark model handles save and load operations', () async {
      final bookItem = LibraryHelper.getCatalog().first;
      final assetPath = bookItem.volumes!.first.assetPath;
      final adapter = LibraryReaderAdapter(
        bookItem: bookItem,
        assetPath: assetPath,
      );

      final bookmark = ReaderBookmark(
        id: 'bm_1',
        documentId: assetPath,
        sectionIndex: 0,
        nodeId: '0_1',
        textPreview: 'God made the world.',
        timestamp: DateTime.now(),
      );

      await adapter.saveBookmark(bookmark);
      final bookmarks = await adapter.loadBookmarks();

      expect(bookmarks.length, equals(1));
      expect(bookmarks.first.textPreview, equals('God made the world.'));
    });
  });
}
