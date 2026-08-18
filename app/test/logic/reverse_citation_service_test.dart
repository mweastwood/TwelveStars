import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReverseCitationService Unit Tests', () {
    setUp(() {
      ReverseCitationService.clear();
    });

    test(
      'indexes and retrieves reverse citations for chapters and verses',
      () async {
        await ReverseCitationService.ensureIndexed();

        // Genesis 3:15 is heavily cited in Baltimore Catechism & Trent
        final gen3v15Citations = ReverseCitationService.getVerseCitations(
          1,
          3,
          15,
        );
        expect(gen3v15Citations, isNotEmpty);
        expect(
          gen3v15Citations.any((rc) => rc.citation.bookName == 'Genesis'),
          true,
        );
        expect(
          gen3v15Citations.every((rc) => rc.sourceAssetPath.isNotEmpty),
          true,
        );

        // Verify that chapter citations query works without throwing
        final gen1ChapterCitations = ReverseCitationService.getChapterCitations(
          1,
          1,
        );
        expect(gen1ChapterCitations, isA<List<ReverseCitation>>());
      },
    );

    test(
      'deduplicates concurrent ensureIndexed calls with in-flight guard',
      () async {
        expect(ReverseCitationService.isInFlightIndexing, isFalse);

        final future1 = ReverseCitationService.ensureIndexed();
        expect(ReverseCitationService.isInFlightIndexing, isTrue);

        final future2 = ReverseCitationService.ensureIndexed();
        final future3 = ReverseCitationService.ensureIndexed();

        expect(identical(future1, future2), isTrue);
        expect(identical(future2, future3), isTrue);

        await Future.wait([future1, future2, future3]);

        expect(ReverseCitationService.isInFlightIndexing, isFalse);
        expect(ReverseCitationService.indexedSourcesCount, equals(17));
      },
    );

    test('indexes and retrieves citations spanning verse ranges correctly', () {
      final bookData = ParsedBookData(
        bookId: 'test_range_book',
        title: 'Range Book',
        subtitle: '',
        author: '',
        toc: [],
        sections: [
          BookSection(
            id: 's1',
            title: 'Section 1',
            subtitle: '',
            content: [
              ContentItem(
                type: 'text',
                text: 'See John 3:16-18 and Matthew 5:3 for details.',
              ),
            ],
          ),
        ],
      );

      ReverseCitationService.indexBookData('range_source', bookData);

      // John 3:16, 3:17, 3:18 should all index the citation (John is book 52 in Catholic canon)
      for (int v = 16; v <= 18; v++) {
        final citations = ReverseCitationService.getVerseCitations(52, 3, v);
        expect(
          citations.length,
          equals(1),
          reason: 'John 3:$v should have citation',
        );
        expect(citations.first.sourceBookId, equals('test_range_book'));
        expect(citations.first.citation.bookName, equals('John'));
      }

      // John 3:15 and 3:19 should NOT have this citation
      expect(ReverseCitationService.getVerseCitations(52, 3, 15), isEmpty);
      expect(ReverseCitationService.getVerseCitations(52, 3, 19), isEmpty);

      // Matthew 5:3 should index single verse (Matthew is book 49 in Catholic canon)
      final matt5v3 = ReverseCitationService.getVerseCitations(49, 5, 3);
      expect(matt5v3.length, equals(1));
      expect(matt5v3.first.citation.bookName, equals('Matthew'));
      expect(ReverseCitationService.getVerseCitations(49, 5, 4), isEmpty);
    });

    test('indexes and retrieves whole chapter citations correctly', () {
      final bookData = ParsedBookData(
        bookId: 'chapter_book',
        title: 'Chapter Book',
        subtitle: '',
        author: '',
        toc: [],
        sections: [
          BookSection(
            id: 's1',
            title: 'Section 1',
            subtitle: '',
            content: [
              ContentItem(
                type: 'text',
                text: 'Refer to Psalm 23 for meditation.',
              ),
            ],
          ),
        ],
      );

      ReverseCitationService.indexBookData('chapter_source', bookData);

      // Psalm is book 21 in Catholic canon, chapter 23
      final psalm23Chapter = ReverseCitationService.getChapterCitations(21, 23);
      expect(psalm23Chapter.length, equals(1));
      expect(psalm23Chapter.first.sourceBookId, equals('chapter_book'));

      // Verse citations for Psalm 23 should be empty because it is a whole chapter citation
      expect(ReverseCitationService.getVerseCitations(21, 23, 1), isEmpty);
      // Non-indexed chapter should be empty
      expect(ReverseCitationService.getChapterCitations(21, 24), isEmpty);
    });

    test('returns empty list for non-existent books, chapters, or verses', () {
      expect(ReverseCitationService.getVerseCitations(999, 1, 1), isEmpty);
      expect(ReverseCitationService.getChapterCitations(999, 1), isEmpty);
    });

    test(
      'enforces LRU cache bounds on indexed sources and prunes index tables',
      () {
        ReverseCitationService.clear();
        expect(ReverseCitationService.indexedSourcesCount, equals(0));

        // Index 26 sources (max capacity is 25)
        for (int i = 1; i <= 26; i++) {
          final bookData = ParsedBookData(
            bookId: 'book_$i',
            title: 'Book $i',
            subtitle: '',
            author: '',
            toc: [],
            sections: [
              BookSection(
                id: 's1',
                title: 'Section 1',
                subtitle: '',
                content: [ContentItem(type: 'text', text: 'Citation Gen $i:1')],
              ),
            ],
          );
          ReverseCitationService.indexBookData('source_$i', bookData);
        }

        // Max capacity is 25, so source_1 should have been evicted
        expect(
          ReverseCitationService.indexedSourcesCount,
          equals(ReverseCitationService.maxIndexedSources),
        );

        // source_1 was evicted (Gen 1:1 has 0 citations from these custom sources)
        final gen1Citations = ReverseCitationService.getVerseCitations(1, 1, 1);
        expect(gen1Citations, isEmpty);

        // source_26 is retained (Gen 26:1 has 1 citation)
        final gen26Citations = ReverseCitationService.getVerseCitations(
          1,
          26,
          1,
        );
        expect(gen26Citations.length, equals(1));
        expect(gen26Citations.first.sourceBookId, equals('book_26'));
      },
    );

    test('prune() removes oldest sources and updates index tables', () {
      for (int i = 1; i <= 5; i++) {
        final bookData = ParsedBookData(
          bookId: 'book_$i',
          title: 'Book $i',
          subtitle: '',
          author: '',
          toc: [],
          sections: [
            BookSection(
              id: 's1',
              title: 'Section 1',
              subtitle: '',
              content: [ContentItem(type: 'text', text: 'Citation Gen $i:1')],
            ),
          ],
        );
        ReverseCitationService.indexBookData('source_$i', bookData);
      }

      expect(ReverseCitationService.indexedSourcesCount, equals(5));
      expect(ReverseCitationService.getVerseCitations(1, 1, 1), isNotEmpty);

      // Prune when length <= maxIndexedSources does not change anything
      ReverseCitationService.prune();
      expect(ReverseCitationService.indexedSourcesCount, equals(5));
      expect(ReverseCitationService.getVerseCitations(1, 1, 1), isNotEmpty);
    });

    test('clear() resets all caches, indices, and in-flight state', () async {
      await ReverseCitationService.ensureIndexed();
      expect(ReverseCitationService.indexedSourcesCount, greaterThan(0));
      expect(ReverseCitationService.getVerseCitations(1, 3, 15), isNotEmpty);

      ReverseCitationService.clear();

      expect(ReverseCitationService.indexedSourcesCount, equals(0));
      expect(ReverseCitationService.totalIndexedCitations, equals(0));
      expect(ReverseCitationService.isInFlightIndexing, isFalse);
      expect(ReverseCitationService.getVerseCitations(1, 3, 15), isEmpty);
      expect(ReverseCitationService.getChapterCitations(1, 1), isEmpty);
    });

    test(
      'incremental indexing aggregates citations across multiple sources',
      () {
        final book1 = ParsedBookData(
          bookId: 'book_a',
          title: 'Book A',
          subtitle: '',
          author: '',
          toc: [],
          sections: [
            BookSection(
              id: 's1',
              title: 'Section 1',
              subtitle: '',
              content: [
                ContentItem(type: 'text', text: 'Citation Matt 5:3 and Gen 1'),
              ],
            ),
          ],
        );

        final book2 = ParsedBookData(
          bookId: 'book_b',
          title: 'Book B',
          subtitle: '',
          author: '',
          toc: [],
          sections: [
            BookSection(
              id: 's1',
              title: 'Section 1',
              subtitle: '',
              content: [
                ContentItem(
                  type: 'text',
                  text: 'Citation Matt 5:3-4 and John 1:1',
                ),
              ],
            ),
          ],
        );

        ReverseCitationService.indexBookData('src_a', book1);
        ReverseCitationService.indexBookData('src_b', book2);

        expect(ReverseCitationService.indexedSourcesCount, equals(2));

        // Matt 5:3 should have citations from both Book A and Book B
        final matt5v3 = ReverseCitationService.getVerseCitations(49, 5, 3);
        expect(matt5v3.length, equals(2));
        expect(
          matt5v3.map((c) => c.sourceBookId).toSet(),
          equals({'book_a', 'book_b'}),
        );

        // Matt 5:4 should only have Book B
        final matt5v4 = ReverseCitationService.getVerseCitations(49, 5, 4);
        expect(matt5v4.length, equals(1));
        expect(matt5v4.first.sourceBookId, equals('book_b'));

        // Genesis 1 entire chapter should have Book A
        final gen1 = ReverseCitationService.getChapterCitations(1, 1);
        expect(gen1.length, equals(1));
        expect(gen1.first.sourceBookId, equals('book_a'));

        // John 1:1 should have Book B
        final john1v1 = ReverseCitationService.getVerseCitations(52, 1, 1);
        expect(john1v1.length, equals(1));
        expect(john1v1.first.sourceBookId, equals('book_b'));
      },
    );

    test(
      'overwriting an existing source triggers rebuild and purges old citations',
      () {
        final initialBook = ParsedBookData(
          bookId: 'custom_doc',
          title: 'Custom Doc v1',
          subtitle: '',
          author: '',
          toc: [],
          sections: [
            BookSection(
              id: 's1',
              title: 'Section 1',
              subtitle: '',
              content: [ContentItem(type: 'text', text: 'Citation Matt 28:19')],
            ),
          ],
        );

        ReverseCitationService.indexBookData('custom_key', initialBook);
        expect(
          ReverseCitationService.getVerseCitations(49, 28, 19).length,
          equals(1),
        );
        expect(ReverseCitationService.getVerseCitations(49, 28, 20), isEmpty);

        // Overwrite custom_key with different citations
        final updatedBook = ParsedBookData(
          bookId: 'custom_doc',
          title: 'Custom Doc v2',
          subtitle: '',
          author: '',
          toc: [],
          sections: [
            BookSection(
              id: 's1',
              title: 'Section 1',
              subtitle: '',
              content: [ContentItem(type: 'text', text: 'Citation Matt 28:20')],
            ),
          ],
        );

        ReverseCitationService.indexBookData('custom_key', updatedBook);
        expect(ReverseCitationService.indexedSourcesCount, equals(1));

        // Old citation Matt 28:19 should no longer be present
        expect(ReverseCitationService.getVerseCitations(49, 28, 19), isEmpty);
        // New citation Matt 28:20 should be present
        final matt28v20 = ReverseCitationService.getVerseCitations(49, 28, 20);
        expect(matt28v20.length, equals(1));
        expect(matt28v20.first.sourceBookTitle, equals('Custom Doc v2'));
      },
    );
  });
}
