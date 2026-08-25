import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';

void main() {
  group('BibleMetadata & BibleBook Unit Tests', () {
    group('BibleBook Schema', () {
      test('instantiates BibleBook with valid properties', () {
        const book = BibleBook(
          bookNumber: 1,
          bookName: 'Genesis',
          abbrev: 'GEN',
          chaptersCount: 50,
          category: 'Pentateuch',
          testament: 'Old Testament',
        );

        expect(book.bookNumber, 1);
        expect(book.bookName, 'Genesis');
        expect(book.abbrev, 'GEN');
        expect(book.chaptersCount, 50);
        expect(book.category, 'Pentateuch');
        expect(book.testament, 'Old Testament');
      });
    });

    group('Canon Size and Testament Breakdown', () {
      test('contains exactly 73 canonical Catholic books', () {
        expect(catholicBooks.length, 73);
      });

      test('contains exactly 46 Old Testament books', () {
        final otBooks = catholicBooks
            .where((b) => b.testament == 'Old Testament')
            .toList();
        expect(otBooks.length, 46);
      });

      test('contains exactly 27 New Testament books', () {
        final ntBooks = catholicBooks
            .where((b) => b.testament == 'New Testament')
            .toList();
        expect(ntBooks.length, 27);
      });
    });

    group('Uniqueness and Identifier Integrity', () {
      test('all book numbers are unique and positive', () {
        final bookNumbers = catholicBooks.map((b) => b.bookNumber).toList();
        expect(bookNumbers.toSet().length, 73);
        for (final number in bookNumbers) {
          expect(number, greaterThan(0));
        }
      });

      test('all abbreviations are unique, 3 uppercase characters', () {
        final abbrevs = catholicBooks.map((b) => b.abbrev).toList();
        expect(abbrevs.toSet().length, 73);

        final abbrevPattern = RegExp(r'^[0-9A-Z]{3}$');
        for (final abbrev in abbrevs) {
          expect(abbrev.length, 3);
          expect(abbrev, equals(abbrev.toUpperCase()));
          expect(
            abbrevPattern.hasMatch(abbrev),
            isTrue,
            reason:
                'Abbreviation "$abbrev" must match 3 uppercase alphanumeric chars',
          );
        }
      });

      test('all book names are unique and non-empty', () {
        final bookNames = catholicBooks.map((b) => b.bookName).toList();
        expect(bookNames.toSet().length, 73);
        for (final name in bookNames) {
          expect(name.trim(), isNotEmpty);
          expect(name, equals(name.trim()));
        }
      });
    });

    group('Data Validity and Category Mapping', () {
      test('all books have positive chapter counts', () {
        for (final book in catholicBooks) {
          expect(
            book.chaptersCount,
            greaterThan(0),
            reason: '${book.bookName} must have > 0 chapters',
          );
        }
      });

      test('categories match recognized sets and correct testaments', () {
        const otCategories = {
          'Pentateuch',
          'Historical Books',
          'Wisdom Books',
          'Prophets',
        };
        const ntCategories = {'Gospels & Acts', 'Epistles', 'Prophecy'};
        final allCategories = {...otCategories, ...ntCategories};

        for (final book in catholicBooks) {
          expect(
            allCategories.contains(book.category),
            isTrue,
            reason:
                '${book.bookName} has unrecognized category "${book.category}"',
          );

          if (book.testament == 'Old Testament') {
            expect(
              otCategories.contains(book.category),
              isTrue,
              reason:
                  'OT book ${book.bookName} has invalid category "${book.category}"',
            );
          } else if (book.testament == 'New Testament') {
            expect(
              ntCategories.contains(book.category),
              isTrue,
              reason:
                  'NT book ${book.bookName} has invalid category "${book.category}"',
            );
          } else {
            fail('Unknown testament: ${book.testament}');
          }
        }
      });

      test('category book counts match Catholic canon breakdown', () {
        final pentateuch = catholicBooks.where(
          (b) => b.category == 'Pentateuch',
        );
        final historical = catholicBooks.where(
          (b) => b.category == 'Historical Books',
        );
        final wisdom = catholicBooks.where((b) => b.category == 'Wisdom Books');
        final prophets = catholicBooks.where((b) => b.category == 'Prophets');
        final gospelsActs = catholicBooks.where(
          (b) => b.category == 'Gospels & Acts',
        );
        final epistles = catholicBooks.where((b) => b.category == 'Epistles');
        final prophecy = catholicBooks.where((b) => b.category == 'Prophecy');

        expect(pentateuch.length, 5);
        expect(historical.length, 16);
        expect(wisdom.length, 7);
        expect(prophets.length, 18);
        expect(gospelsActs.length, 5);
        expect(epistles.length, 21);
        expect(prophecy.length, 1);
      });
    });

    group('Key Canonical & Deuterocanonical Books Verification', () {
      test('verifies key anchor books', () {
        final genesis = catholicBooks.firstWhere(
          (b) => b.bookName == 'Genesis',
        );
        expect(genesis.bookNumber, 1);
        expect(genesis.abbrev, 'GEN');
        expect(genesis.chaptersCount, 50);
        expect(genesis.category, 'Pentateuch');
        expect(genesis.testament, 'Old Testament');

        final psalms = catholicBooks.firstWhere((b) => b.bookName == 'Psalms');
        expect(psalms.bookNumber, 21);
        expect(psalms.abbrev, 'PSA');
        expect(psalms.chaptersCount, 150);
        expect(psalms.category, 'Wisdom Books');
        expect(psalms.testament, 'Old Testament');

        final matthew = catholicBooks.firstWhere(
          (b) => b.bookName == 'Matthew',
        );
        expect(matthew.bookNumber, 49);
        expect(matthew.abbrev, 'MAT');
        expect(matthew.chaptersCount, 28);
        expect(matthew.category, 'Gospels & Acts');
        expect(matthew.testament, 'New Testament');

        final revelation = catholicBooks.firstWhere(
          (b) => b.bookName == 'Revelation',
        );
        expect(revelation.bookNumber, 76);
        expect(revelation.abbrev, 'REV');
        expect(revelation.chaptersCount, 22);
        expect(revelation.category, 'Prophecy');
        expect(revelation.testament, 'New Testament');
      });

      test('verifies all 7 deuterocanonical books and additions exist', () {
        final deuterocanonicalNames = [
          'Tobit',
          'Judith',
          '1 Maccabees',
          '2 Maccabees',
          'Wisdom',
          'Sirach',
          'Baruch',
        ];

        for (final name in deuterocanonicalNames) {
          final match = catholicBooks.where((b) => b.bookName == name);
          expect(
            match.isNotEmpty,
            isTrue,
            reason:
                'Deuterocanonical book $name must be present in catholicBooks',
          );
          final book = match.first;
          expect(book.testament, 'Old Testament');
          expect(book.chaptersCount, greaterThan(0));
        }

        final tobit = catholicBooks.firstWhere((b) => b.bookName == 'Tobit');
        expect(tobit.abbrev, 'TOB');
        expect(tobit.chaptersCount, 14);
        expect(tobit.category, 'Historical Books');

        final judith = catholicBooks.firstWhere((b) => b.bookName == 'Judith');
        expect(judith.abbrev, 'JDT');
        expect(judith.chaptersCount, 16);
        expect(judith.category, 'Historical Books');

        final maccabees1 = catholicBooks.firstWhere(
          (b) => b.bookName == '1 Maccabees',
        );
        expect(maccabees1.abbrev, '1MA');
        expect(maccabees1.chaptersCount, 16);
        expect(maccabees1.category, 'Historical Books');

        final maccabees2 = catholicBooks.firstWhere(
          (b) => b.bookName == '2 Maccabees',
        );
        expect(maccabees2.abbrev, '2MA');
        expect(maccabees2.chaptersCount, 15);
        expect(maccabees2.category, 'Historical Books');

        final wisdom = catholicBooks.firstWhere((b) => b.bookName == 'Wisdom');
        expect(wisdom.abbrev, 'WIS');
        expect(wisdom.chaptersCount, 19);
        expect(wisdom.category, 'Wisdom Books');

        final sirach = catholicBooks.firstWhere((b) => b.bookName == 'Sirach');
        expect(sirach.abbrev, 'SIR');
        expect(sirach.chaptersCount, 51);
        expect(sirach.category, 'Wisdom Books');

        final baruch = catholicBooks.firstWhere((b) => b.bookName == 'Baruch');
        expect(baruch.abbrev, 'BAR');
        expect(baruch.chaptersCount, 6);
        expect(baruch.category, 'Prophets');
      });
    });
  });
}
