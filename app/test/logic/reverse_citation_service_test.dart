import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReverseCitationService Unit Tests', () {
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

        // Verify that chapter citations query works without throwing
        final gen1ChapterCitations = ReverseCitationService.getChapterCitations(
          1,
          1,
        );
        expect(gen1ChapterCitations, isA<List<ReverseCitation>>());
      },
    );
  });
}
