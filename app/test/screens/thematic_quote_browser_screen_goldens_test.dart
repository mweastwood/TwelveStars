import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';
import '../test_helper.dart';

List<ThematicPassage> _buildMockThematicPassages() {
  return [
    ThematicPassage(
      bookId: 'aquinas_catechetical_sacraments',
      bookTitle: 'The Catechetical Instructions: Part II',
      author: 'St. Thomas Aquinas (Trans. Joseph B. Collins)',
      authorSaintId: 'thomas-aquinas',
      sectionId: 'sec_aquinas_catechetical_sacraments_1',
      sectionTitle: 'Chapter 1: The Sacraments of the Church',
      itemIndex: 0,
      primaryTheme: 'sacraments.eucharist',
      secondaryThemes: const [
        'theology.holy_spirit_grace',
        'theology.christ_incarnation',
      ],
      keyExcerpt:
          'A sacrament is a visible sign of invisible grace, instituted by Jesus Christ for our sanctification.',
      oneSentenceSummary:
          'St. Thomas defines a sacrament as an efficacious outward sign instituted by Christ to confer invisible sanctifying grace.',
      fullText:
          '1. A sacrament is a visible sign of invisible grace, instituted by Jesus Christ for our sanctification.',
    ),
    ThematicPassage(
      bookId: 'didache_lightfoot',
      bookTitle: 'The Didache',
      author: 'Apostolic Fathers (Trans. J. B. Lightfoot)',
      sectionId: 'ch7',
      sectionTitle: 'Chapter 7: Concerning Baptism',
      itemIndex: 0,
      primaryTheme: 'sacraments.baptism',
      secondaryThemes: const ['virtues.purity_modesty'],
      keyExcerpt:
          'And concerning baptism, baptize this way: having first said all these things, baptize into the name of the Father, and of the Son, and of the Holy Spirit, in living water.',
      oneSentenceSummary:
          'The Didache prescribes the Trinitarian formula in living water as the ancient Apostolic baptismal rite.',
      fullText:
          'And concerning baptism, baptize this way: having first said all these things, baptize into the name of the Father, and of the Son, and of the Holy Spirit, in living water.',
    ),
    ThematicPassage(
      bookId: 'augustine_confessions_book8',
      bookTitle: 'The Confessions',
      author: 'St. Augustine of Hippo (Trans. E. B. Pusey)',
      authorSaintId: 'augustine-of-hippo',
      sectionId: 'ch12',
      sectionTitle: 'Chapter 12: Conversion in the Garden',
      itemIndex: 0,
      primaryTheme: 'prayer.conformity_divine_will',
      secondaryThemes: const ['virtues.faith_hope_charity'],
      keyExcerpt:
          'Take up and read; take up and read. I grasped, opened, and in silence read that section on which my eyes first fell.',
      oneSentenceSummary:
          'St. Augustine hears the divine child voice prompting him to open the Scriptures and experience complete moral conversion.',
      fullText:
          'Take up and read; take up and read. I grasped, opened, and in silence read that section on which my eyes first fell.',
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    ThematicHelper.mockPassages = _buildMockThematicPassages();
    ThematicHelper.mockRandom = Random(42);
  });

  tearDown(() async {
    ThematicHelper.mockPassages = null;
    ThematicHelper.mockRandom = null;
    await testDb.close();
  });

  group('ThematicQuoteBrowserScreen Golden Tests', () {
    testGoldens('renders standalone mode with quote card (light theme)', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const ThematicQuoteBrowserScreen(
          initialThemeId: 'sacraments.eucharist',
          embedded: false,
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
        ),
        surfaceSize: const Size(480, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'thematic_quote_browser_standalone_light_golden',
      );
    });

    testGoldens('renders standalone mode with quote card (dark theme)', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const ThematicQuoteBrowserScreen(
          initialThemeId: 'sacraments.eucharist',
          embedded: false,
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
        ),
        surfaceSize: const Size(480, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'thematic_quote_browser_standalone_dark_golden',
      );
    });

    testGoldens('renders embedded mode without outer AppBar (light theme)', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const Scaffold(
          body: ThematicQuoteBrowserScreen(
            initialThemeId: 'sacraments.eucharist',
            embedded: true,
          ),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
        ),
        surfaceSize: const Size(480, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'thematic_quote_browser_embedded_light_golden',
      );
    });

    testGoldens(
      'renders theme selector bottom sheet when theme title is tapped',
      (tester) async {
        await tester.pumpWidgetBuilder(
          const ThematicQuoteBrowserScreen(
            initialThemeId: 'sacraments.eucharist',
            embedded: false,
          ),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(480, 800),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.text('The Most Holy Eucharist & The Mass'));
        await tester.pump();
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'thematic_quote_browser_theme_picker_sheet_golden',
        );
      },
    );

    testGoldens('renders favorited/bookmarked state on quote card', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const ThematicQuoteBrowserScreen(
          initialThemeId: 'sacraments.eucharist',
          embedded: false,
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
        ),
        surfaceSize: const Size(480, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final favoriteBtn = find.byIcon(Icons.favorite_border_rounded).first;
      await tester.tap(favoriteBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'thematic_quote_browser_favorited_card_golden',
      );
    });

    testGoldens(
      'renders empty state when selected theme has no indexed quotes',
      (tester) async {
        await tester.pumpWidgetBuilder(
          const ThematicQuoteBrowserScreen(
            initialThemeId: 'theology.unindexed_sample_theme',
            embedded: false,
          ),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(480, 800),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'thematic_quote_browser_empty_state_golden',
        );
      },
    );
  });
}
