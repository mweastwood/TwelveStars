import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/saint_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryDatabase & Author Saint Mappings', () {
    test('LibraryHelper.getCatalog returns populated catalog items', () {
      final catalog = LibraryHelper.getCatalog();
      expect(catalog, isNotEmpty);
      expect(catalog.length, greaterThanOrEqualTo(25));
    });

    test(
      'all configured authorSaintId values correspond to valid saints in the database',
      () async {
        final catalog = LibraryHelper.getCatalog();
        final allSaints = await SaintDatabase.loadSaints();
        final validSaintIds = allSaints.map((s) => s.id).toSet();

        final booksWithSaintAuthor = catalog
            .where((b) => b.authorSaintId != null)
            .toList();
        expect(booksWithSaintAuthor, isNotEmpty);

        for (final book in booksWithSaintAuthor) {
          expect(
            validSaintIds.contains(book.authorSaintId),
            isTrue,
            reason:
                'Book ${book.id} (${book.title}) has invalid authorSaintId: ${book.authorSaintId}',
          );
        }
      },
    );

    test(
      'verifies specific patristic, scholastic and spiritual author saint mappings',
      () {
        final catalog = LibraryHelper.getCatalog();
        final map = {for (final b in catalog) b.id: b.authorSaintId};

        expect(map['council_of_trent'], equals('pius-v'));
        expect(map['first_clement_lightfoot'], equals('clement-of-rome'));
        expect(map['ignatius_epistles'], equals('ignatius-of-antioch'));
        expect(map['polycarp_writings'], equals('polycarp-of-smyrna'));
        expect(map['justin_martyr_apologies'], equals('justin-martyr'));
        expect(map['justin_dialogue_trypho'], equals('justin-martyr'));
        expect(map['irenaeus_against_heresies'], equals('irenaeus-of-lyons'));
        expect(
          map['athanasius_on_the_incarnation'],
          equals('athanasius-of-alexandria'),
        );
        expect(
          map['athanasius_life_of_anthony'],
          equals('athanasius-of-alexandria'),
        );
        expect(map['augustine_confessions'], equals('augustine-of-hippo'));
        expect(map['augustine_city_of_god'], equals('augustine-of-hippo'));
        expect(
          map['cyril_catechetical_lectures'],
          equals('cyril-of-jerusalem'),
        );
        expect(map['basil_on_the_holy_spirit'], equals('basil-the-great'));
        expect(
          map['gregory_theological_orations'],
          equals('gregory-of-nazianzus'),
        );
        expect(map['chrysostom_on_the_priesthood'], equals('john-chrysostom'));
        expect(map['ambrose_mysteries_and_sacraments'], equals('ambrose'));
        expect(map['vincent_commonitory'], equals('vincent-of-lerins'));
        expect(map['leo_great_tome_and_sermons'], equals('leo-the-great'));
        expect(map['gregory_pastoral_rule'], equals('gregory-the-great'));
        expect(map['cyprian_unity_of_church'], equals('cyprian-of-carthage'));
        expect(map['john_damascene_orthodox_faith'], equals('john-damascene'));
        expect(map['anselm_proslogion'], equals('anselm-of-canterbury'));
        expect(map['anselm_cur_deus_homo'], equals('anselm-of-canterbury'));
        expect(
          map['john_cross_ascent_mount_carmel'],
          equals('john-of-the-cross'),
        );
        expect(map['john_cross_dark_night_soul'], equals('john-of-the-cross'));
        expect(map['aquinas_compendium_of_theology'], equals('thomas-aquinas'));
        expect(
          map['aquinas_catechetical_instructions'],
          equals('thomas-aquinas'),
        );
        expect(
          map['montfort_true_devotion'],
          equals('louis-marie-de-montfort'),
        );
        expect(map['benedict_rule'], equals('benedict-of-nursia'));
        expect(map['francis_de_sales_devout_life'], equals('francis-de-sales'));
        expect(map['francis_de_sales_love_of_god'], equals('francis-de-sales'));
        expect(map['teresa_interior_castle'], equals('teresa-of-avila'));
        expect(map['teresa_way_of_perfection'], equals('teresa-of-avila'));
        expect(map['bonaventure_minds_road_to_god'], equals('bonaventure'));

        // Verify books without specific saint authors remain null
        expect(map['baltimore_catechism'], isNull);
        expect(map['didache_lightfoot'], isNull);
        expect(map['second_clement_lightfoot'], isNull);
        expect(map['diognetus_lightfoot'], isNull);
        expect(map['kempis_imitation_of_christ'], isNull);
      },
    );
  });

  group('Library Search & Background Parsing Tests', () {
    final sampleBook = ParsedBookData(
      bookId: 'test_book',
      title: 'Sample Test Book',
      subtitle: 'A testing guide',
      author: 'Test Author',
      toc: [TocEntry(id: 'sec_1', title: 'Chapter 1')],
      sections: [
        BookSection(
          id: 'sec_1',
          title: 'Chapter 1: The Foundations of Faith',
          subtitle: '',
          content: [
            ContentItem(
              type: 'qa',
              questionNumber: 1,
              question: 'Who made us?',
              answer: 'God made us to know Him, to love Him, and to serve Him.',
            ),
            ContentItem(
              type: 'text',
              text:
                  'Grace is a supernatural gift of God bestowed upon us through the merits of Jesus Christ for our salvation.',
            ),
          ],
        ),
      ],
    );

    test('searchInBook finds QA and text matches with snippets', () {
      final qaResults = LibraryHelper.searchInBook(sampleBook, 'know love');
      expect(qaResults, hasLength(1));
      expect(qaResults.first.bookTitle, equals('Sample Test Book'));
      expect(qaResults.first.sectionId, equals('sec_1'));
      expect(
        qaResults.first.matchedSnippet,
        contains('God made us to know Him'),
      );

      final textResults = LibraryHelper.searchInBook(sampleBook, 'grace gift');
      expect(textResults, hasLength(1));
      expect(
        textResults.first.matchedSnippet,
        contains('Grace is a supernatural gift'),
      );

      final noResults = LibraryHelper.searchInBook(
        sampleBook,
        'nonexistent query',
      );
      expect(noResults, isEmpty);

      final emptyResults = LibraryHelper.searchInBook(sampleBook, '   ');
      expect(emptyResults, isEmpty);
    });

    test('searchInBook caps results at 50', () {
      final manySections = List.generate(
        60,
        (i) => BookSection(
          id: 'sec_$i',
          title: 'Section $i',
          subtitle: '',
          content: [
            ContentItem(
              type: 'text',
              text: 'Repeated common content matching the query number $i.',
            ),
          ],
        ),
      );

      final largeBook = ParsedBookData(
        bookId: 'large_book',
        title: 'Large Book',
        subtitle: '',
        author: 'Author',
        toc: [],
        sections: manySections,
      );

      final results = LibraryHelper.searchInBook(largeBook, 'Repeated common');
      expect(results.length, equals(50));
    });

    test('searchCatalog returns empty on whitespace or empty query', () async {
      expect(await LibraryHelper.searchCatalog(''), isEmpty);
      expect(await LibraryHelper.searchCatalog('   '), isEmpty);
    });

    test('ParsedBookData.fromJson parses all fields and nested structures', () {
      final jsonMap = {
        'bookId': 'council_of_trent',
        'title': 'The Canons and Decrees of the Council of Trent',
        'subtitle': 'Ecumenical Council',
        'author': 'Pope Pius IV',
        'verseSystem': 'vulgate',
        'toc': [
          {'id': 'session_1', 'title': 'Session I'},
        ],
        'sections': [
          {
            'id': 'session_1',
            'title': 'Session I: Opening Decree',
            'subtitle': '',
            'content': [
              {
                'type': 'qa',
                'questionNumber': 1,
                'question': 'What was declared?',
                'answer': 'The opening of the holy ecumenical council.',
              },
            ],
          },
        ],
      };

      final parsed = ParsedBookData.fromJson(jsonMap);
      expect(parsed.bookId, equals('council_of_trent'));
      expect(
        parsed.title,
        equals('The Canons and Decrees of the Council of Trent'),
      );
      expect(parsed.subtitle, equals('Ecumenical Council'));
      expect(parsed.author, equals('Pope Pius IV'));
      expect(parsed.verseSystem, equals('vulgate'));
      expect(parsed.toc.length, equals(1));
      expect(parsed.toc.first.id, equals('session_1'));
      expect(parsed.sections.length, equals(1));
      expect(parsed.sections.first.content.length, equals(1));
      expect(parsed.sections.first.content.first.type, equals('qa'));
      expect(parsed.sections.first.content.first.questionNumber, equals(1));
    });
  });
}
