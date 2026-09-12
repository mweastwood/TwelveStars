import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/reader/library_models.dart';

void main() {
  group('LibraryBookItem web properties', () {
    test('default webUrl is null and isWeb is false', () {
      const book = LibraryBookItem(
        id: 'test_book',
        title: 'Test Book',
        subtitle: 'Subtitle',
        category: 'Catechisms',
        author: 'Author',
        description: 'Description',
        defaultAssetPath: 'assets/test.json',
      );

      expect(book.webUrl, isNull);
      expect(book.isWeb, isFalse);
      expect(book.allAssetPaths, ['assets/test.json']);
    });

    test('custom webUrl sets isWeb to true and allAssetPaths is empty', () {
      const book = LibraryBookItem(
        id: 'ccc_usccb',
        title: 'Catechism of the Catholic Church',
        subtitle: 'Promulgated by Pope St. John Paul II',
        category: 'Catechisms',
        author: 'USCCB',
        description: 'USCCB Catechism',
        webUrl:
            'https://www.usccb.org/beliefs-and-teachings/what-we-believe/catechism/catechism-of-the-catholic-church',
      );

      expect(
        book.webUrl,
        'https://www.usccb.org/beliefs-and-teachings/what-we-believe/catechism/catechism-of-the-catholic-church',
      );
      expect(book.isWeb, isTrue);
      expect(book.allAssetPaths, isEmpty);
    });

    test('empty webUrl returns isWeb as false', () {
      const book = LibraryBookItem(
        id: 'empty_web',
        title: 'Empty Web Book',
        subtitle: 'Subtitle',
        category: 'Catechisms',
        author: 'Author',
        description: 'Description',
        webUrl: '',
      );

      expect(book.isWeb, isFalse);
      expect(book.allAssetPaths, isEmpty);
    });
  });
}
