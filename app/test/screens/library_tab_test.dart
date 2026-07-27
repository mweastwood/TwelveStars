import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/screens/library_tab.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryTab Golden & Widget Tests', () {
    testGoldens('LibraryTab renders catalog correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Library Tab Landing Catalog',
          const SizedBox(height: 600, child: Scaffold(body: LibraryTab())),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );

      await screenMatchesGolden(tester, 'library_tab_catalog_golden');
    });

    testWidgets('renders catalog header and book cards', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      expect(find.text('CATECHISMS & DOCTRINE'), findsOneWidget);
      expect(find.text('Baltimore Catechism'), findsOneWidget);
      expect(find.text('Catechism of the Council of Trent'), findsOneWidget);

      // Verify Baltimore Catechism volume chips exist
      expect(find.text('No. 1 (First Communion)'), findsOneWidget);
      expect(find.text('No. 2 (Confirmation & Grammar)'), findsOneWidget);
      expect(find.text('No. 3 (Post-Confirmation Course)'), findsOneWidget);
      expect(find.text('No. 4 (Explanation by Fr. Kinkead)'), findsOneWidget);
    });

    testWidgets('tapping volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final vol1Chip = find.text('No. 1 (First Communion)');
      await tester.tap(vol1Chip);
      await tester.pumpAndSettle();

      // Reader screen should be visible
      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Baltimore Catechism'), findsWidgets);
    });
  });

  group('LibraryReaderScreen Widget Tests', () {
    testWidgets('loads and renders book section and volume switching', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final baltimore = catalog.firstWhere(
        (b) => b.id == 'baltimore_catechism',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryReaderScreen(
              bookItem: baltimore,
              initialVolumeKey: 'no1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify reader toolbar and content loaded
      expect(find.text('Baltimore Catechism'), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Open Table of Contents sheet
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      expect(find.text('Table of Contents'), findsOneWidget);
    });
  });
}
