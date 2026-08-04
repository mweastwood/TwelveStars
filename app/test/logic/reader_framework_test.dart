import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
import 'package:twelve_stars/logic/reader/bible_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unified Reader Framework Phase 1', () {
    group('Reader Models', () {
      test('ReaderContentNode creation and properties', () {
        const verseNode = ReaderContentNode(
          id: 'v1',
          nodeType: ReaderNodeType.verse,
          primaryText: 'In the beginning',
          questionNumber: '1',
        );
        expect(verseNode.id, 'v1');
        expect(verseNode.nodeType, ReaderNodeType.verse);
        expect(verseNode.primaryText, 'In the beginning');
        expect(verseNode.questionNumber, '1');

        const qaNode = ReaderContentNode(
          id: 'qa1',
          nodeType: ReaderNodeType.qa,
          questionNumber: '1',
          question: 'Who made the world?',
          answer: 'God made the world.',
          explanation: 'Explanation text',
        );
        expect(qaNode.nodeType, ReaderNodeType.qa);
        expect(qaNode.question, 'Who made the world?');
      });

      test('ReaderSection and ReaderDocument metadata', () {
        const doc = ReaderDocument(
          documentId: 'doc1',
          title: 'Test Doc',
          sectionsCount: 1,
          tocEntries: [ReaderTocEntry(index: 0, title: 'Chapter 1')],
        );
        expect(doc.title, 'Test Doc');
        expect(doc.sectionsCount, 1);
        expect(doc.tocEntries.first.title, 'Chapter 1');
      });

      test('ReaderBookmark properties', () {
        final timestamp = DateTime.now();
        final bookmark = ReaderBookmark(
          id: 'b1',
          documentId: 'doc1',
          sectionIndex: 0,
          nodeId: 'v1',
          textPreview: 'In the beginning',
          timestamp: timestamp,
        );
        expect(bookmark.textPreview, 'In the beginning');
        expect(bookmark.timestamp, timestamp);
      });

      test('ReaderComment properties', () {
        final timestamp = DateTime.now();
        final comment = ReaderComment(
          id: 'c1',
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          text: 'Deep theological note',
          textPreview: 'In the beginning God created',
          timestamp: timestamp,
        );
        expect(comment.id, 'c1');
        expect(comment.documentId, 'GEN');
        expect(comment.sectionIndex, 1);
        expect(comment.nodeId, '1_1_1');
        expect(comment.text, 'Deep theological note');
        expect(comment.textPreview, 'In the beginning God created');
        expect(comment.timestamp, timestamp);
      });
    });

    group('BibleReaderAdapter', () {
      late BibleDatabase db;
      late BibleReaderAdapter adapter;

      setUp(() async {
        db = BibleDatabase(NativeDatabase.memory());

        // Populate test data
        await db
            .into(db.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText:
                    'In the beginning God created the heavens and the earth.',
                translationCode: 'CPDV',
              ),
            );
        await db
            .into(db.bibleVerses)
            .insert(
              BibleVersesCompanion.insert(
                bookNumber: 1,
                bookName: 'Genesis',
                chapter: 1,
                verseNumber: 1,
                verseText: 'In principio creavit Deus caelum et terram.',
                translationCode: 'VUL',
              ),
            );

        const testBook = BibleBook(
          bookNumber: 1,
          bookName: 'Genesis',
          abbrev: 'GEN',
          chaptersCount: 50,
          category: 'Pentateuch',
          testament: 'Old Testament',
        );

        adapter = BibleReaderAdapter(bibleBook: testBook, dbHelper: db);
      });

      tearDown(() async {
        await db.close();
      });

      test('loadDocument returns correct metadata and TOC', () async {
        final doc = await adapter.loadDocument();
        expect(doc.documentId, 'GEN');
        expect(doc.title, 'Genesis');
        expect(doc.subtitle, 'Old Testament');
        expect(doc.sectionsCount, 50);
        expect(doc.tocEntries.length, 50);
        expect(doc.tocEntries.first.title, 'Chapter 1');
      });

      test('loadSection returns correctly mapped verses', () async {
        final section = await adapter.loadSection(1);
        expect(section.sectionIndex, 1);
        expect(section.title, 'Genesis 1');
        expect(section.nodes.length, 1);

        final node = section.nodes.first;
        expect(node.nodeType, ReaderNodeType.verse);
        expect(
          node.primaryText,
          'In the beginning God created the heavens and the earth.',
        );
        expect(node.questionNumber, '1');
        expect(node.id, '1_1_1');
      });

      test('loadSection with compare translation', () async {
        final section = await adapter.loadSection(1, compareVariant: 'VUL');
        final node = section.nodes.first;
        expect(
          node.primaryText,
          'In the beginning God created the heavens and the earth.',
        );
        expect(
          node.secondaryText,
          'In principio creavit Deus caelum et terram.',
        );
      });

      test('saveComment, loadComments, deleteComment', () async {
        final comment = ReaderComment(
          id: '1',
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          text: 'Reflections on Genesis 1:1',
          textPreview: 'In the beginning...',
          timestamp: DateTime.now(),
        );

        await adapter.saveComment(comment);

        final loaded = await adapter.loadComments(nodeId: '1_1_1');
        expect(loaded.length, 1);
        expect(loaded.first.text, 'Reflections on Genesis 1:1');
        expect(loaded.first.nodeId, '1_1_1');

        await adapter.deleteComment(loaded.first.id);
        final emptyList = await adapter.loadComments(nodeId: '1_1_1');
        expect(emptyList.isEmpty, true);
      });
    });

    group('LibraryReaderAdapter', () {
      late LibraryReaderAdapter adapter;
      const testAssetPath = 'test_assets/book.json';

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (ByteData? message) async {
              final String key = utf8.decode(message!.buffer.asUint8List());
              if (key == testAssetPath) {
                const jsonString = '''{
              "bookId": "test_book",
              "title": "Test Book",
              "subtitle": "A Test",
              "author": "Author",
              "toc": [{"id": "s1", "title": "Section 1"}],
              "sections": [{
                "id": "s1",
                "title": "Section 1",
                "subtitle": "",
                "content": [
                  {"type": "heading", "text": "A Heading"},
                  {"type": "paragraph", "text": "A paragraph of text."},
                  {
                    "type": "qa",
                    "questionNumber": 1,
                    "question": "Q?",
                    "answer": "A.",
                    "explanation": "Exp",
                    "crossRefQNum": 2
                  }
                ]
              }]
            }''';
                return ByteData.view(
                  Uint8List.fromList(utf8.encode(jsonString)).buffer,
                );
              }
              return null;
            });

        const item = LibraryBookItem(
          id: 'test_book',
          title: 'Test Book',
          subtitle: 'A Test',
          category: 'Cat',
          author: 'Author',
          description: 'Desc',
        );

        adapter = LibraryReaderAdapter(
          bookItem: item,
          assetPath: testAssetPath,
        );
      });

      test('loadDocument metadata', () async {
        final doc = await adapter.loadDocument();
        expect(doc.documentId, 'test_book');
        expect(doc.title, 'Test Book');
        expect(doc.sectionsCount, 1);
        expect(doc.tocEntries.first.title, 'Section 1');
      });

      test('loadSection nodes', () async {
        final section = await adapter.loadSection(0);
        expect(section.title, 'Section 1');
        expect(section.nodes.length, 3);

        expect(section.nodes[0].nodeType, ReaderNodeType.heading);
        expect(section.nodes[0].primaryText, 'A Heading');

        expect(section.nodes[1].nodeType, ReaderNodeType.paragraph);

        expect(section.nodes[2].nodeType, ReaderNodeType.qa);
        expect(section.nodes[2].question, 'Q?');
        expect(section.nodes[2].answer, 'A.');
        expect(section.nodes[2].explanation, 'Exp');
        expect(section.nodes[2].crossRefId, '2');
      });

      test(
        'saveComment, loadComments, deleteComment in LibraryReaderAdapter',
        () async {
          final comment = ReaderComment(
            id: 'c_lib_1',
            documentId: 'test_book',
            sectionIndex: 0,
            nodeId: 's1-1',
            text: 'Comment on paragraph',
            timestamp: DateTime.now(),
          );

          await adapter.saveComment(comment);
          final comments = await adapter.loadComments(nodeId: 's1-1');
          expect(comments.length, 1);
          expect(comments.first.text, 'Comment on paragraph');

          await adapter.deleteComment('c_lib_1');
          final afterDelete = await adapter.loadComments(nodeId: 's1-1');
          expect(afterDelete.isEmpty, true);
        },
      );
    });
  });
}
