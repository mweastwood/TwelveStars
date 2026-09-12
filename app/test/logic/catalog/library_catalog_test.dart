import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/catalog/library_catalog.dart';
import 'package:twelve_stars/logic/saint_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryCatalog online works', () {
    test('ccc_usccb is present in catalog with valid properties', () {
      final catalog = LibraryCatalog.getCatalog();
      final ccc = catalog.firstWhere(
        (b) => b.id == 'ccc_usccb',
        orElse: () => throw StateError('ccc_usccb not found in catalog'),
      );

      expect(ccc.title, 'Catechism of the Catholic Church');
      expect(ccc.category, 'Catechisms');
      expect(ccc.isWeb, isTrue);
      expect(
        ccc.webUrl,
        'https://www.usccb.org/beliefs-and-teachings/what-we-believe/catechism/catechism-of-the-catholic-church',
      );
      expect(ccc.authorSaintId, 'john-paul-ii');
      expect(ccc.era, '1992 AD');
      expect(ccc.defaultAssetPath, isNull);
      expect(ccc.volumes, isNull);
      expect(ccc.allAssetPaths, isEmpty);
    });

    test('authorSaintId john-paul-ii exists in SaintDatabase', () async {
      final saint = await SaintDatabase.getSaintById('john-paul-ii');
      expect(saint, isNotNull);
      expect(saint?.name, contains('John Paul II'));
    });

    test('getAllCatalogPaths does not contain corrupt or web paths', () {
      final allPaths = LibraryCatalog.getAllCatalogPaths();
      expect(allPaths, isNotEmpty);
      for (final path in allPaths) {
        expect(path.startsWith('http'), isFalse);
        expect(path.startsWith('assets/'), isTrue);
      }
      expect(allPaths.any((p) => p.contains('ccc_usccb')), isFalse);
    });
  });
}
