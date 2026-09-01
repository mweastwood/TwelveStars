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
        expect(gen3v15Citations.any((rc) => rc.sourceAuthor.isNotEmpty), true);

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
        expect(
          ReverseCitationService.indexedSourcesCount,
          equals(ReverseCitationService.catalogPaths.length),
        );
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
        expect(citations.length, equals(1));
        expect(citations.first.sourceBookId, equals('test_range_book'));
      }

      // Matthew 5:3 (Matthew is book 49)
      final mattCitations = ReverseCitationService.getVerseCitations(49, 5, 3);
      expect(mattCitations.length, equals(1));
      expect(mattCitations.first.sourceBookId, equals('test_range_book'));
    });

    test('populates sourceAuthor on ReverseCitation during indexing', () {
      final bookData = ParsedBookData(
        bookId: 'test_author_book',
        title: 'Author Book',
        subtitle: 'A Work of Theology',
        author: 'St. Augustine of Hippo',
        toc: [],
        sections: [
          BookSection(
            id: 's1',
            title: 'Section 1',
            subtitle: '',
            content: [
              ContentItem(type: 'text', text: 'As written in John 3:16.'),
            ],
          ),
        ],
      );

      ReverseCitationService.indexBookData('author_source', bookData);

      final citations = ReverseCitationService.getVerseCitations(52, 3, 16);
      expect(citations, isNotEmpty);
      expect(citations.first.sourceAuthor, equals('St. Augustine of Hippo'));
      expect(citations.first.sourceBookTitle, equals('Author Book'));
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

        // Index maxIndexedSources + 1 sources
        final count = ReverseCitationService.maxIndexedSources + 1;
        for (int i = 1; i <= count; i++) {
          final ch = ((i - 1) % 150) + 1;
          final v = ((i - 1) ~/ 150) + 1;
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
                content: [
                  ContentItem(type: 'text', text: 'Citation Ps $ch:$v'),
                ],
              ),
            ],
          );
          ReverseCitationService.indexBookData('source_$i', bookData);
        }

        // Cache count should be capped at maxIndexedSources
        expect(
          ReverseCitationService.indexedSourcesCount,
          equals(ReverseCitationService.maxIndexedSources),
        );

        // Oldest source (source_1) was evicted (Psalm is book 21 in Catholic canon)
        final ps1Citations = ReverseCitationService.getVerseCitations(21, 1, 1);
        expect(ps1Citations, isEmpty);

        // Newest source (source_count) remains present
        final newestCh = ((count - 1) % 150) + 1;
        final newestV = ((count - 1) ~/ 150) + 1;
        final psNewestCitations = ReverseCitationService.getVerseCitations(
          21,
          newestCh,
          newestV,
        );
        expect(psNewestCitations.length, equals(1));
      },
    );

    test('prune() removes oldest sources and updates index tables', () {
      ReverseCitationService.clear();

      final count = ReverseCitationService.maxIndexedSources + 5;
      for (int i = 1; i <= count; i++) {
        final ch = ((i - 1) % 150) + 1;
        final v = ((i - 1) ~/ 150) + 1;
        final bookData = ParsedBookData(
          bookId: 'prune_book_$i',
          title: 'Prune Book $i',
          subtitle: '',
          author: '',
          toc: [],
          sections: [
            BookSection(
              id: 's1',
              title: 'Section 1',
              subtitle: '',
              content: [ContentItem(type: 'text', text: 'Citation Ps $ch:$v')],
            ),
          ],
        );
        ReverseCitationService.indexBookData('prune_source_$i', bookData);
      }

      ReverseCitationService.prune();
      expect(
        ReverseCitationService.indexedSourcesCount,
        equals(ReverseCitationService.maxIndexedSources),
      );
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

    test(
      'indexes St. John Chrysostom On the Priesthood across all 6 books',
      () async {
        await ReverseCitationService.ensureIndexed();

        final chrysostomPaths = [
          'assets/catechism/json/chrysostom_on_the_priesthood_book1.json',
          'assets/catechism/json/chrysostom_on_the_priesthood_book2.json',
          'assets/catechism/json/chrysostom_on_the_priesthood_book3.json',
          'assets/catechism/json/chrysostom_on_the_priesthood_book4.json',
          'assets/catechism/json/chrysostom_on_the_priesthood_book5.json',
          'assets/catechism/json/chrysostom_on_the_priesthood_book6.json',
        ];

        for (final path in chrysostomPaths) {
          expect(
            ReverseCitationService.catalogPaths.contains(path),
            isTrue,
            reason: '$path should be registered in catalogPaths',
          );
        }
      },
    );

    test('indexes St. Vincent of Lérins The Commonitory', () async {
      await ReverseCitationService.ensureIndexed();

      const vincentPath = 'assets/catechism/json/vincent_commonitory.json';
      expect(
        ReverseCitationService.catalogPaths.contains(vincentPath),
        isTrue,
        reason: '$vincentPath should be registered in catalogPaths',
      );
    });

    test('indexes St. Athanasius Life of St. Anthony', () async {
      await ReverseCitationService.ensureIndexed();

      const anthonyPath =
          'assets/catechism/json/athanasius_life_of_anthony.json';
      expect(
        ReverseCitationService.catalogPaths.contains(anthonyPath),
        isTrue,
        reason: '$anthonyPath should be registered in catalogPaths',
      );
    });

    test(
      'indexes Pope St. Leo the Great Tome and Sermons across both volumes',
      () async {
        await ReverseCitationService.ensureIndexed();

        final leoPaths = [
          'assets/catechism/json/leo_tome_and_letters.json',
          'assets/catechism/json/leo_selected_sermons.json',
        ];

        for (final path in leoPaths) {
          expect(
            ReverseCitationService.catalogPaths.contains(path),
            isTrue,
            reason: '$path should be registered in catalogPaths',
          );
        }
      },
    );

    test(
      'indexes St. Teresa of Ávila The Way of Perfection across both volumes',
      () async {
        await ReverseCitationService.ensureIndexed();

        const teresaPart1 =
            'assets/catechism/json/teresa_way_perfection_part1.json';
        const teresaPart2 =
            'assets/catechism/json/teresa_way_perfection_part2.json';
        expect(
          ReverseCitationService.catalogPaths.contains(teresaPart1),
          isTrue,
          reason: '$teresaPart1 should be registered in catalogPaths',
        );
        expect(
          ReverseCitationService.catalogPaths.contains(teresaPart2),
          isTrue,
          reason: '$teresaPart2 should be registered in catalogPaths',
        );
      },
    );

    test(
      'indexes St. Cyprian of Carthage On the Unity of the Church & Treatises',
      () async {
        await ReverseCitationService.ensureIndexed();

        final cyprianPaths = [
          'assets/catechism/json/cyprian_unity_and_lapsed.json',
          'assets/catechism/json/cyprian_prayer_and_treatises.json',
        ];

        for (final path in cyprianPaths) {
          expect(
            ReverseCitationService.catalogPaths.contains(path),
            isTrue,
            reason: '$path should be registered in catalogPaths',
          );
        }
      },
    );

    test(
      'indexes St. John Damascene An Exact Exposition of the Orthodox Faith across all 4 books',
      () async {
        await ReverseCitationService.ensureIndexed();

        final damascenePaths = [
          'assets/catechism/json/damascene_orthodox_faith_book1.json',
          'assets/catechism/json/damascene_orthodox_faith_book2.json',
          'assets/catechism/json/damascene_orthodox_faith_book3.json',
          'assets/catechism/json/damascene_orthodox_faith_book4.json',
        ];

        for (final path in damascenePaths) {
          expect(
            ReverseCitationService.catalogPaths.contains(path),
            isTrue,
            reason: '$path should be registered in catalogPaths',
          );
        }
      },
    );

    test(
      'indexes St. Francis de Sales Treatise on the Love of God across all 4 volumes',
      () async {
        await ReverseCitationService.ensureIndexed();

        final salesLoveOfGodPaths = [
          'assets/catechism/json/sales_love_of_god_vol1.json',
          'assets/catechism/json/sales_love_of_god_vol2.json',
          'assets/catechism/json/sales_love_of_god_vol3.json',
          'assets/catechism/json/sales_love_of_god_vol4.json',
        ];

        for (final path in salesLoveOfGodPaths) {
          expect(
            ReverseCitationService.catalogPaths.contains(path),
            isTrue,
            reason: '$path should be registered in catalogPaths',
          );
        }
      },
    );

    test(
      'catalogPaths matches LibraryDatabase.getAllCatalogPaths() and includes all volumes',
      () {
        final dbPaths = LibraryDatabase.getAllCatalogPaths();
        expect(ReverseCitationService.catalogPaths, equals(dbPaths));
        expect(ReverseCitationService.catalogPaths.isNotEmpty, isTrue);
      },
    );

    test(
      'indexes St. Gregory of Nazianzus Five Theological Orations across all 5 volumes',
      () async {
        await ReverseCitationService.ensureIndexed();

        final gregoryPaths = [
          'assets/catechism/json/gregory_theological_orations_oration1.json',
          'assets/catechism/json/gregory_theological_orations_oration2.json',
          'assets/catechism/json/gregory_theological_orations_oration3.json',
          'assets/catechism/json/gregory_theological_orations_oration4.json',
          'assets/catechism/json/gregory_theological_orations_oration5.json',
        ];

        for (final path in gregoryPaths) {
          expect(
            ReverseCitationService.catalogPaths.contains(path),
            isTrue,
            reason: '$path should be registered in catalogPaths',
          );
        }
      },
    );

    group(
      'LibraryBookItem.allAssetPaths & LibraryDatabase.getAllCatalogPaths',
      () {
        test(
          'returns defaultAssetPath as single element list for non-series item',
          () {
            const item = LibraryBookItem(
              id: 'test_single',
              title: 'Test Single',
              subtitle: '',
              category: 'Catechisms',
              author: 'Author',
              description: 'Desc',
              defaultAssetPath: 'assets/catechism/json/test_single.json',
            );
            expect(
              item.allAssetPaths,
              equals(['assets/catechism/json/test_single.json']),
            );
          },
        );

        test('returns volume assetPaths for series item', () {
          const item = LibraryBookItem(
            id: 'test_series',
            title: 'Test Series',
            subtitle: '',
            category: 'Catechisms',
            author: 'Author',
            description: 'Desc',
            volumes: [
              BaltimoreVolume(
                volumeKey: 'v1',
                name: 'Vol 1',
                shortName: 'V1',
                description: 'D1',
                assetPath: 'assets/catechism/json/v1.json',
              ),
              BaltimoreVolume(
                volumeKey: 'v2',
                name: 'Vol 2',
                shortName: 'V2',
                description: 'D2',
                assetPath: 'assets/catechism/json/v2.json',
              ),
            ],
          );
          expect(
            item.allAssetPaths,
            equals([
              'assets/catechism/json/v1.json',
              'assets/catechism/json/v2.json',
            ]),
          );
        });

        test(
          'returns empty list when neither defaultAssetPath nor volumes is provided',
          () {
            const item = LibraryBookItem(
              id: 'test_empty',
              title: 'Test Empty',
              subtitle: '',
              category: 'Catechisms',
              author: 'Author',
              description: 'Desc',
            );
            expect(item.allAssetPaths, isEmpty);
          },
        );
      },
    );

    group('extractSentences & Contextual Windowing', () {
      test('extracts sentences while respecting abbreviations', () {
        const text =
            'St. Peter spoke to Fr. John and Dr. Smith. '
            'See e.g. no. 4, ch. 2, v. 5. '
            'We read in Rom 8:28 that all things work for good! '
            'Is this clear? Yes, J. B. Lightfoot agrees...';

        final sentences = ReverseCitationService.extractSentences(text);
        expect(sentences.length, equals(5));
        expect(
          sentences[0],
          equals('St. Peter spoke to Fr. John and Dr. Smith.'),
        );
        expect(sentences[1], equals('See e.g. no. 4, ch. 2, v. 5.'));
        expect(
          sentences[2],
          equals('We read in Rom 8:28 that all things work for good!'),
        );
        expect(sentences[3], equals('Is this clear?'));
        expect(sentences[4], equals('Yes, J. B. Lightfoot agrees...'));
      });

      test(
        'extracts 3 to 5 sentence window with ellipsis prefix when truncated',
        () {
          final bookData = ParsedBookData(
            bookId: 'window_test_book',
            title: 'Window Test Book',
            subtitle: '',
            author: '',
            toc: [],
            sections: [
              BookSection(
                id: 'sec_window',
                title: 'Window Section',
                subtitle: '',
                content: [
                  ContentItem(
                    type: 'text',
                    text:
                        'Sentence one. '
                        'Sentence two. '
                        'Sentence three. '
                        'Sentence four. '
                        'Sentence five. '
                        'Sentence six citing John 3:16. '
                        'Sentence seven. '
                        'Sentence eight.',
                  ),
                ],
              ),
            ],
          );

          ReverseCitationService.indexBookData('window_src', bookData);
          final citations = ReverseCitationService.getVerseCitations(52, 3, 16);

          expect(citations.length, equals(1));
          final citation = citations.first;
          expect(citation.itemIndex, equals(0));
          // Window should contain 5 sentences (2 through 6) with '... ' prefix
          expect(citation.snippet.startsWith('... '), isTrue);
          expect(citation.snippet.contains('Sentence two.'), isTrue);
          expect(citation.snippet.contains('Sentence three.'), isTrue);
          expect(citation.snippet.contains('Sentence four.'), isTrue);
          expect(citation.snippet.contains('Sentence five.'), isTrue);
          expect(
            citation.snippet.contains('Sentence six citing John 3:16.'),
            isTrue,
          );
          expect(citation.snippet.contains('Sentence one.'), isFalse);
          expect(citation.snippet.contains('Sentence seven.'), isFalse);
        },
      );

      test(
        'formats Q&A contextual snippet accurately with question and answer',
        () {
          final bookData = ParsedBookData(
            bookId: 'baltimore_test',
            title: 'Baltimore Catechism',
            subtitle: '',
            author: '',
            toc: [],
            sections: [
              BookSection(
                id: 'sec_qa',
                title: 'On Creation',
                subtitle: '',
                content: [
                  ContentItem(
                    type: 'qa',
                    questionNumber: 15,
                    question: 'Who made the world?',
                    answer:
                        'God made the world. '
                        'He made heaven and earth from nothing (Gen 1:1).',
                  ),
                ],
              ),
            ],
          );

          ReverseCitationService.indexBookData('baltimore_src', bookData);
          final citations = ReverseCitationService.getVerseCitations(1, 1, 1);

          expect(citations.length, equals(1));
          final citation = citations.first;
          expect(citation.questionNumber, equals(15));
          expect(citation.itemIndex, equals(0));
          expect(
            citation.snippet.startsWith('Q. Who made the world?\nA. '),
            isTrue,
          );
          expect(
            citation.snippet.contains(
              'God made the world. He made heaven and earth from nothing (Gen 1:1).',
            ),
            isTrue,
          );
        },
      );

      test('preserves itemIndex across multiple content items in section', () {
        final bookData = ParsedBookData(
          bookId: 'multi_item_book',
          title: 'Multi Item Book',
          subtitle: '',
          author: '',
          toc: [],
          sections: [
            BookSection(
              id: 'sec_multi',
              title: 'Multi Section',
              subtitle: '',
              content: [
                ContentItem(type: 'heading', text: 'Chapter 1: The Beginning'),
                ContentItem(
                  type: 'text',
                  text: 'Here is introductory text without citations.',
                ),
                ContentItem(
                  type: 'text',
                  text: 'Here we cite Matthew 5:3 in the third item.',
                ),
                ContentItem(
                  type: 'qa',
                  questionNumber: 42,
                  question: 'What about Luke?',
                  answer: 'See Luke 1:26 for the Annunciation.',
                ),
              ],
            ),
          ],
        );

        ReverseCitationService.indexBookData('multi_src', bookData);

        // Matthew 5:3 is in content[2]
        final mattCitations = ReverseCitationService.getVerseCitations(
          49,
          5,
          3,
        );
        expect(mattCitations.length, equals(1));
        expect(mattCitations.first.itemIndex, equals(2));
        expect(mattCitations.first.questionNumber, isNull);

        // Luke 1:26 is in content[3]
        final lukeCitations = ReverseCitationService.getVerseCitations(
          51,
          1,
          26,
        );
        expect(lukeCitations.length, equals(1));
        expect(lukeCitations.first.itemIndex, equals(3));
        expect(lukeCitations.first.questionNumber, equals(42));
      });
    });

    group('parseBookCitationsInBackground Worker Tests', () {
      test(
        'parses raw JSON string payload and extracts citations accurately',
        () {
          const rawJson = '''
{
  "bookId": "isolate_worker_test",
  "title": "Worker Test Book",
  "subtitle": "Subtitle",
  "author": "St. Jerome",
  "verseSystem": "vulgate",
  "toc": [],
  "sections": [
    {
      "id": "sec_worker_1",
      "title": "Worker Section 1",
      "subtitle": "",
      "content": [
        {
          "type": "heading",
          "text": "Heading text"
        },
        {
          "type": "text",
          "text": "Saint Paul teaches that love is patient (1 Cor 13:4-7). We also read Psalm 23."
        },
        {
          "type": "qa",
          "questionNumber": 7,
          "question": "What does Christ say in John 14:6?",
          "answer": "I am the way, and the truth, and the life (John 14:6).",
          "explanation": "Compare Matthew 7:14 for the narrow gate."
        }
      ]
    }
  ]
}
''';

          final params = CitationParseParams(
            sourceKey: 'test/path/worker_test.json',
            rawJson: rawJson,
          );

          final citations = parseBookCitationsInBackground(params);
          expect(citations.length, equals(5));

          // 1 Cor 13:4-7
          final corCitation = citations.firstWhere(
            (c) => c.citation.bookName == '1 Corinthians',
          );
          expect(corCitation.sourceBookId, equals('isolate_worker_test'));
          expect(corCitation.sourceBookTitle, equals('Worker Test Book'));
          expect(corCitation.sourceAuthor, equals('St. Jerome'));
          expect(
            corCitation.sourceAssetPath,
            equals('test/path/worker_test.json'),
          );
          expect(corCitation.citation.chapter, equals(13));
          expect(corCitation.citation.verse, equals(4));
          expect(corCitation.citation.endVerse, equals(7));
          expect(corCitation.itemIndex, equals(1));

          // Psalm 23 entire chapter
          final psalmCitation = citations.firstWhere(
            (c) => c.citation.bookName == 'Psalms',
          );
          expect(psalmCitation.citation.chapter, equals(23));
          expect(psalmCitation.citation.isEntireChapter, isTrue);

          // Q&A Question John 14:6
          final qaQuestionCitation = citations.firstWhere(
            (c) =>
                c.citation.bookName == 'John' &&
                c.snippet.startsWith('Q. What does Christ say in John 14:6?'),
          );
          expect(qaQuestionCitation.questionNumber, equals(7));
          expect(qaQuestionCitation.itemIndex, equals(2));

          // Q&A Answer John 14:6
          final qaAnswerCitation = citations.firstWhere(
            (c) =>
                c.citation.bookName == 'John' &&
                c.snippet.contains(
                  'A. I am the way, and the truth, and the life',
                ),
          );
          expect(qaAnswerCitation.questionNumber, equals(7));
          expect(qaAnswerCitation.itemIndex, equals(2));

          // Q&A Explanation Matt 7:14
          final mattCitation = citations.firstWhere(
            (c) => c.citation.bookName == 'Matthew',
          );
          expect(mattCitation.citation.chapter, equals(7));
          expect(mattCitation.citation.verse, equals(14));
          expect(mattCitation.questionNumber, equals(7));
        },
      );
    });
  });
}
