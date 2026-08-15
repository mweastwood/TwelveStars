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

    test('enforces LRU cache bounds on indexed sources', () {
      ReverseCitationService.clear();
      expect(ReverseCitationService.indexedSourcesCount, equals(0));

      // Index 6 sources (max capacity is 5)
      for (int i = 1; i <= 6; i++) {
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

      // Max capacity is 5, so source_1 should have been evicted
      expect(ReverseCitationService.indexedSourcesCount, equals(5));

      // source_1 was evicted (Gen 1:1 has 0 citations from these custom sources)
      final gen1Citations = ReverseCitationService.getVerseCitations(1, 1, 1);
      expect(gen1Citations, isEmpty);

      // source_6 is retained (Gen 6:1 has 1 citation)
      final gen6Citations = ReverseCitationService.getVerseCitations(1, 6, 1);
      expect(gen6Citations.length, equals(1));
      expect(gen6Citations.first.sourceBookId, equals('book_6'));
    });
  });
}
