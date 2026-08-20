import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('St. Polycarp Library Database & Asset Tests', () {
    test('LibraryDatabase.catalog contains St. Polycarp writings', () {
      final catalog = LibraryHelper.getCatalog();
      final polycarp = catalog.firstWhere(
        (b) => b.id == 'polycarp_writings',
        orElse: () => throw Exception('polycarp_writings not found in catalog'),
      );

      expect(polycarp.title, 'Epistle & Martyrdom of St. Polycarp');
      expect(polycarp.category, 'Apostolic Fathers');
      expect(
        polycarp.author,
        'St. Polycarp of Smyrna / Church of Smyrna (Trans. J. B. Lightfoot)',
      );
      expect(polycarp.volumes, isNotNull);
      expect(polycarp.volumes!.length, 2);

      final philVol = polycarp.volumes!.firstWhere(
        (v) => v.volumeKey == 'philippians',
      );
      expect(philVol.name, 'Epistle to the Philippians');
      expect(philVol.shortName, 'Philippians');
      expect(
        philVol.assetPath,
        'assets/catechism/json/polycarp_philippians_lightfoot.json',
      );

      final martVol = polycarp.volumes!.firstWhere(
        (v) => v.volumeKey == 'martyrdom',
      );
      expect(martVol.name, 'The Martyrdom of Polycarp');
      expect(martVol.shortName, 'Martyrdom');
      expect(
        martVol.assetPath,
        'assets/catechism/json/polycarp_martyrdom_lightfoot.json',
      );
    });

    test(
      'polycarp_philippians_lightfoot.json has valid structure and 14 chapters',
      () {
        final file = File(
          'assets/catechism/json/polycarp_philippians_lightfoot.json',
        );
        expect(file.existsSync(), isTrue);

        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(json['bookId'], 'polycarp_philippians_lightfoot');
        expect(json['title'], 'Epistle of Polycarp to the Philippians');
        expect(json['verseSystem'], 'vulgate');

        final toc = json['toc'] as List<dynamic>;
        final sections = json['sections'] as List<dynamic>;

        expect(toc.length, 14);
        expect(sections.length, 14);

        // Verify chapter 1
        final sec1 = sections.first as Map<String, dynamic>;
        expect(sec1['id'], 'sec_polycarp_philippians_1');
        expect(sec1['title'], 'Chapter 1');
        expect(sec1['subtitle'], isNotEmpty);
        final content1 = sec1['content'] as List<dynamic>;
        expect(content1.isNotEmpty, isTrue);

        // Verify chapter 14
        final sec14 = sections.last as Map<String, dynamic>;
        expect(sec14['id'], 'sec_polycarp_philippians_14');
        expect(sec14['title'], 'Chapter 14');
        final content14 = sec14['content'] as List<dynamic>;
        expect(content14.isNotEmpty, isTrue);
      },
    );

    test(
      'polycarp_martyrdom_lightfoot.json has valid structure and 22 chapters',
      () {
        final file = File(
          'assets/catechism/json/polycarp_martyrdom_lightfoot.json',
        );
        expect(file.existsSync(), isTrue);

        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(json['bookId'], 'polycarp_martyrdom_lightfoot');
        expect(json['title'], 'The Martyrdom of Polycarp');
        expect(json['verseSystem'], 'vulgate');

        final toc = json['toc'] as List<dynamic>;
        final sections = json['sections'] as List<dynamic>;

        expect(toc.length, 22);
        expect(sections.length, 22);

        // Verify chapter 1
        final sec1 = sections.first as Map<String, dynamic>;
        expect(sec1['id'], 'sec_polycarp_martyrdom_1');
        expect(sec1['title'], 'Chapter 1');
        expect(sec1['subtitle'], isNotEmpty);
        final content1 = sec1['content'] as List<dynamic>;
        expect(content1.isNotEmpty, isTrue);

        // Verify chapter 22
        final sec22 = sections.last as Map<String, dynamic>;
        expect(sec22['id'], 'sec_polycarp_martyrdom_22');
        expect(sec22['title'], 'Chapter 22');
        final content22 = sec22['content'] as List<dynamic>;
        expect(content22.isNotEmpty, isTrue);
      },
    );

    test('LibraryReaderAdapter loads and adapts Polycarp documents', () async {
      final catalog = LibraryHelper.getCatalog();
      final polycarp = catalog.firstWhere((b) => b.id == 'polycarp_writings');

      final philAdapter = LibraryReaderAdapter(
        bookItem: polycarp,
        assetPath: 'assets/catechism/json/polycarp_philippians_lightfoot.json',
      );

      final philDoc = await philAdapter.loadDocument();
      expect(philDoc.documentId, 'polycarp_writings');
      expect(philDoc.title, 'Epistle & Martyrdom of St. Polycarp');
      expect(philDoc.sectionsCount, 14);
      expect(philDoc.tocEntries.length, 14);

      final martAdapter = LibraryReaderAdapter(
        bookItem: polycarp,
        assetPath: 'assets/catechism/json/polycarp_martyrdom_lightfoot.json',
      );

      final martDoc = await martAdapter.loadDocument();
      expect(martDoc.documentId, 'polycarp_writings');
      expect(martDoc.title, 'Epistle & Martyrdom of St. Polycarp');
      expect(martDoc.sectionsCount, 22);
      expect(martDoc.tocEntries.length, 22);
    });
  });
}
