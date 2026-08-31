import 'dart:math';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/screens/library_tab.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
    ThematicHelper.mockRandom = Random(42);
  });

  tearDown(() async {
    ThematicHelper.mockRandom = null;
    await testDb.close();
  });

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

    testGoldens('LibraryTab renders continue reading hero card correctly', (
      tester,
    ) async {
      await testDb.saveBookReadingPosition(
        bookId: 'didache_lightfoot',
        sectionIndex: 2,
        sectionId: 'ch3',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/didache_lightfoot.json',
        );
      });

      await tester.pumpWidgetBuilder(
        const Scaffold(body: LibraryTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'library_tab_continue_reading_hero_golden',
      );
    });

    testGoldens('LibraryTab renders category filter state correctly', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const Scaffold(body: LibraryTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Apostolic Fathers'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'library_tab_category_filter_golden');
    });

    testGoldens('LibraryTab renders volume picker modal sheet correctly', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const Scaffold(body: LibraryTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      final browseBtn = find.widgetWithText(TextButton, 'Browse All ▾').first;
      await tester.tap(browseBtn);
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'library_tab_volume_picker_modal_golden',
      );
    });

    testGoldens('LibraryTab renders global search results correctly', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/didache_lightfoot.json',
        );
        await LibraryHelper.loadBookData(
          'assets/catechism/json/first_clement_lightfoot.json',
        );
      });

      await tester.pumpWidgetBuilder(
        const Scaffold(body: LibraryTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.runAsync(() async {
        await tester.enterText(searchField, 'Baptism');
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'library_tab_search_results_golden');
    });

    testGoldens('LibraryTab renders quotes and themes tab correctly', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await ThematicHelper.loadAllPassages();
      });

      await tester.pumpWidgetBuilder(
        const Scaffold(body: LibraryTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quotes & Themes'));
      await tester.pump();
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'library_tab_quotes_and_themes_tab_golden',
      );
    });

    testGoldens('LibraryTab renders favorites tab correctly', (tester) async {
      await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: 'didache_lightfoot',
          sectionIndex: 0,
          nodeId: 'ch1_0',
          textPreview:
              'The Didache, Chapter 1\nThere are two ways, one of life and one of death...',
          createdAt: DateTime.now(),
        ),
      );
      await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: 'first_clement_lightfoot',
          sectionIndex: 0,
          nodeId: 'ch1_0',
          textPreview:
              'First Clement, Chapter 1\nThe Church of God which sojourneth at Rome...',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidgetBuilder(
        const Scaffold(body: LibraryTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'library_tab_favorites_tab_golden');
    });

    testGoldens('LibraryTab renders comments tab correctly', (tester) async {
      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'didache_lightfoot',
          sectionIndex: 0,
          nodeId: 'ch1_0',
          commentText: 'Insight on the two ways in early Christian teaching',
          textPreview: const Value(
            'There are two ways, one of life and one of death',
          ),
          createdAt: DateTime.now(),
        ),
      );
      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'baltimore_catechism',
          sectionIndex: 0,
          nodeId: 'no1:lesson_01_1',
          commentText: 'Explanation of the end of man',
          textPreview: const Value('Who made the world? God made the world.'),
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidgetBuilder(
        const Scaffold(body: LibraryTab()),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comments'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'library_tab_comments_tab_golden');
    });

    testGoldens(
      'LibraryTab renders saint details sheet when author is tapped',
      (tester) async {
        await tester.runAsync(() async {
          await SaintDatabase.loadSaints();
        });

        await tester.pumpWidgetBuilder(
          const Scaffold(body: LibraryTab()),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        final authorFinder = find.text(
          'By Pope St. Clement of Rome (Trans. J. B. Lightfoot)',
        );
        await tester.scrollUntilVisible(
          authorFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(authorFinder);
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'library_tab_saint_details_sheet_golden',
        );
      },
    );

    testWidgets('renders catalog header and book cards', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      expect(find.text('CATECHISMS & DOCTRINE'), findsOneWidget);
      expect(find.text('Baltimore Catechism'), findsOneWidget);
      expect(find.text('Catechism of the Council of Trent'), findsOneWidget);
      expect(find.text('The Didache'), findsOneWidget);
      expect(find.text('First Epistle of Clement'), findsOneWidget);
      expect(find.text('Second Epistle of Clement'), findsOneWidget);
      expect(find.text('Epistles of St. Ignatius'), findsOneWidget);
      expect(find.text('Epistle & Martyrdom of St. Polycarp'), findsOneWidget);
      expect(find.text('The Epistle to Diognetus'), findsOneWidget);
      expect(find.text('Apologies of St. Justin Martyr'), findsOneWidget);
      expect(find.text('Dialogue with Trypho'), findsOneWidget);
      expect(find.text('Against Heresies'), findsOneWidget);
      expect(find.text('On the Incarnation of the Word'), findsOneWidget);
      expect(find.text('The Confessions'), findsOneWidget);
      expect(find.text('The City of God'), findsOneWidget);
      expect(find.text('Catechetical Lectures'), findsOneWidget);
      expect(find.text('On the Holy Spirit'), findsOneWidget);
      expect(find.text('The Five Theological Orations'), findsOneWidget);
      expect(find.text('On the Priesthood'), findsOneWidget);
      expect(find.text('Proslogion'), findsOneWidget);
      expect(find.text('Cur Deus Homo'), findsOneWidget);
      expect(find.text('Ascent of Mount Carmel'), findsOneWidget);
      expect(find.text('Dark Night of the Soul'), findsOneWidget);
      expect(find.text('On the Mysteries & On the Sacraments'), findsOneWidget);
      expect(find.text('Compendium of Theology'), findsOneWidget);
      expect(find.text('The Catechetical Instructions'), findsOneWidget);
      expect(find.text('True Devotion to Mary'), findsOneWidget);
      expect(find.text('The Rule of St. Benedict'), findsOneWidget);
      expect(find.text('Introduction to the Devout Life'), findsOneWidget);
      expect(find.text('Treatise on the Love of God'), findsOneWidget);
      expect(find.text('The Interior Castle'), findsOneWidget);
      expect(find.text('The Imitation of Christ'), findsOneWidget);
      expect(find.text("The Mind's Road to God"), findsOneWidget);
      expect(find.text('The Tome & Selected Works'), findsOneWidget);
      expect(find.text('Pastoral Rule'), findsOneWidget);
      expect(
        find.text('On the Unity of the Church & Treatises'),
        findsOneWidget,
      );
      expect(
        find.text('An Exact Exposition of the Orthodox Faith'),
        findsOneWidget,
      );

      // Verify Baltimore Catechism volume chips exist
      expect(find.text('No. 1 (First Communion)'), findsOneWidget);
      expect(find.text('No. 2 (Confirmation & Grammar)'), findsOneWidget);
      expect(find.text('No. 3 (Post-Confirmation Course)'), findsOneWidget);
      expect(find.text('No. 4 (Explanation by Fr. Kinkead)'), findsOneWidget);

      // Verify Ignatius volume chips exist
      expect(find.text('Epistle to the Ephesians'), findsOneWidget);
      expect(find.text('Epistle to the Romans'), findsOneWidget);
      expect(find.text('Epistle to the Smyrnaeans'), findsOneWidget);

      // Verify Polycarp volume chips exist
      expect(find.text('Epistle to the Philippians'), findsOneWidget);
      expect(find.text('The Martyrdom of Polycarp'), findsOneWidget);

      // Verify Justin Martyr volume chips exist
      expect(find.text('First Apology'), findsOneWidget);
      expect(find.text('Second Apology'), findsOneWidget);

      // Verify Irenaeus volume chips exist
      expect(find.text('Book I (Gnostic Sects)'), findsOneWidget);
      expect(find.text('Book III (Faith & Tradition)'), findsOneWidget);

      // Verify Augustine volume chips exist
      expect(find.text('Book I (Infancy & Childhood)'), findsOneWidget);
      expect(find.text('Book VIII (Conversion in the Garden)'), findsOneWidget);
      expect(find.text('Book I (The Sack of Rome)'), findsOneWidget);
      expect(find.text('Book XIX (Peace & the Supreme Good)'), findsOneWidget);

      // Verify Cyril volume chips exist
      expect(find.text('Vol. I (Procatechesis & Faith)'), findsOneWidget);
      expect(find.text('Vol. IV (The Mysteries)'), findsOneWidget);

      // Verify Gregory volume chips exist
      expect(find.text('Oration I (Against the Eunomians)'), findsOneWidget);
      expect(find.text('Oration V (On the Holy Spirit)'), findsOneWidget);

      // Verify Chrysostom volume chips exist
      expect(find.text('Book I (Youth & the Holy Scheme)'), findsOneWidget);
      expect(
        find.text('Book VI (Purity of Heart & Final Reconciliation)'),
        findsOneWidget,
      );

      // Verify Ambrose volume chips exist
      expect(find.text('On the Mysteries (De Mysteriis)'), findsOneWidget);
      expect(find.text('On the Sacraments (De Sacramentis)'), findsOneWidget);

      // Verify St. Leo the Great volume chips exist
      expect(
        find.text('Vol. I (The Tome to Flavian & Christological Letters)'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Vol. II (Selected Festal Sermons & Epistles on Church Order)',
        ),
        findsOneWidget,
      );

      // Verify Gregory the Great Pastoral Rule volume chips exist
      expect(find.text('Book I (The Pastoral Office)'), findsOneWidget);
      expect(
        find.text('Book IV (Humility & Self-Examination)'),
        findsOneWidget,
      );

      // Verify Aquinas volume chips exist
      expect(find.text('Part I (On Faith)'), findsOneWidget);
      expect(find.text('Part II (On Hope)'), findsOneWidget);
      expect(find.text('Part I (The Apostles\' Creed)'), findsOneWidget);
      expect(find.text('Part II (The Sacraments)'), findsOneWidget);
      expect(find.text('Part III (The Commandments)'), findsOneWidget);
      expect(find.text('Part IV (The Lord\'s Prayer)'), findsOneWidget);
      expect(find.text('Part V (The Hail Mary)'), findsOneWidget);

      // Verify Anselm volume chips exist
      expect(find.text('Book I: The Necessity of Redemption'), findsOneWidget);
      expect(find.text('Book II: The God-Man and Atonement'), findsOneWidget);

      // Verify St. Francis de Sales volume chips exist
      expect(find.text('Part I (First Desire for Devotion)'), findsOneWidget);
      expect(
        find.text('Part V (Renewing the Soul in Devotion)'),
        findsOneWidget,
      );

      // Verify Cyprian volume chips exist
      expect(
        find.text('Vol. I: On the Unity of the Church & The Lapsed'),
        findsOneWidget,
      );
      expect(
        find.text('Vol. II: On the Lord\'s Prayer & Christian Life'),
        findsOneWidget,
      );

      // Verify St. John Damascene volume chips exist
      expect(find.text('Book I (The Godhead & the Trinity)'), findsOneWidget);
      expect(
        find.text('Book IV (Resurrection, Sacraments & Icons)'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Gregory volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/gregory_theological_orations_oration5.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final oration5Chip = find.text('Oration V (On the Holy Spirit)');
      await tester.scrollUntilVisible(
        oration5Chip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(oration5Chip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('The Five Theological Orations'), findsWidgets);
    });

    testWidgets(
      'tapping Aquinas Compendium volume chip opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/aquinas_compendium_of_theology_part1.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final part1Chip = find.text('Part I (On Faith)');
        await tester.scrollUntilVisible(
          part1Chip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(part1Chip);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Compendium of Theology'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Aquinas Catechetical volume chip opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/aquinas_catechetical_creed.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final creedChip = find.text('Part I (The Apostles\' Creed)');
        await tester.scrollUntilVisible(
          creedChip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(creedChip);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Catechetical Instructions'), findsWidgets);
      },
    );

    testWidgets(
      'tapping St. Francis de Sales volume chip opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/sales_devout_life_part1.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final part1Chip = find.text('Part I (First Desire for Devotion)');
        await tester.scrollUntilVisible(
          part1Chip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(part1Chip);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Introduction to the Devout Life'), findsWidgets);
      },
    );

    testWidgets('tapping Cyril volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/cyril_catechetical_lectures_vol4.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final vol4Chip = find.text('Vol. IV (The Mysteries)');
      await tester.scrollUntilVisible(
        vol4Chip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(vol4Chip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Catechetical Lectures'), findsWidgets);
    });

    testWidgets('tapping Confessions volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/augustine_confessions_book8.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final book8Chip = find.text('Book VIII (Conversion in the Garden)');
      await tester.scrollUntilVisible(
        book8Chip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(book8Chip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('The Confessions'), findsWidgets);
    });

    testWidgets('tapping City of God volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/augustine_city_of_god_book19.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final book19Chip = find.text('Book XIX (Peace & the Supreme Good)');
      await tester.scrollUntilVisible(
        book19Chip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(book19Chip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('The City of God'), findsWidgets);
    });

    testWidgets('tapping Irenaeus volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/irenaeus_against_heresies_book3.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final book3Chip = find.text('Book III (Faith & Tradition)');
      await tester.scrollUntilVisible(
        book3Chip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(book3Chip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Against Heresies'), findsWidgets);
    });

    testWidgets('tapping Justin Martyr volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/justin_first_apology_dods.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final apologyChip = find.text('First Apology');
      await tester.scrollUntilVisible(
        apologyChip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(apologyChip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Apologies of St. Justin Martyr'), findsWidgets);
    });

    testWidgets('tapping volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/baltimore_1.json',
        );
      });

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

    testWidgets('tapping Ignatius volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/ignatius_romans_lightfoot.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final romansChip = find.text('Epistle to the Romans');
      await tester.scrollUntilVisible(
        romansChip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(romansChip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Epistles of St. Ignatius'), findsWidgets);
    });

    testWidgets('tapping Polycarp volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/polycarp_philippians_lightfoot.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final philChip = find.text('Epistle to the Philippians');
      await tester.scrollUntilVisible(
        philChip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(philChip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Epistle & Martyrdom of St. Polycarp'), findsWidgets);
    });

    testWidgets(
      'tapping Polycarp Martyrdom volume chip opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/polycarp_martyrdom_lightfoot.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final martChip = find.text('The Martyrdom of Polycarp');
        await tester.scrollUntilVisible(
          martChip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(martChip);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Epistle & Martyrdom of St. Polycarp'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on The Epistle to Diognetus opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/diognetus_lightfoot.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final diognetusCard = find.ancestor(
          of: find.text('The Epistle to Diognetus'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: diognetusCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Epistle to Diognetus'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on First Clement opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/first_clement_lightfoot.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final clementCard = find.ancestor(
          of: find.text('First Epistle of Clement'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: clementCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('First Epistle of Clement'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on True Devotion to Mary opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/montfort_true_devotion.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final montfortCard = find.ancestor(
          of: find.text('True Devotion to Mary'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: montfortCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('True Devotion to Mary'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on The Imitation of Christ opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/kempis_imitation_of_christ.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final kempisCard = find.ancestor(
          of: find.text('The Imitation of Christ'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: kempisCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Imitation of Christ'), findsWidgets);
      },
    );

    testWidgets('tapping Read Book on Didache opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/didache_lightfoot.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final didacheCard = find.ancestor(
        of: find.text('The Didache'),
        matching: find.byType(Card),
      );
      final readBtn = find.descendant(
        of: didacheCard,
        matching: find.widgetWithText(FilledButton, 'Read Book'),
      );

      await tester.scrollUntilVisible(
        readBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(readBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('The Didache'), findsWidgets);
    });

    testWidgets(
      'tapping Ambrose On the Mysteries volume chip opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/ambrose_on_the_mysteries.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final mysteriesChip = find.text('On the Mysteries (De Mysteriis)');
        await tester.scrollUntilVisible(
          mysteriesChip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(mysteriesChip);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('On the Mysteries'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on Basil on the Holy Spirit opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/basil_on_the_holy_spirit.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final basilCard = find.ancestor(
          of: find.text('On the Holy Spirit'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: basilCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('On the Holy Spirit'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on The Commonitory opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/vincent_commonitory.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final vincentCard = find.ancestor(
          of: find.text('The Commonitory'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: vincentCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Commonitory'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on Life of St. Anthony opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/athanasius_life_of_anthony.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final anthonyCard = find.ancestor(
          of: find.text('Life of St. Anthony'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: anthonyCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Life of St. Anthony'), findsWidgets);
      },
    );

    testWidgets(
      'tapping The Way of Perfection volume chip opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/teresa_way_perfection_part1.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final part1Chip = find.text(
          'Vol. I: The Way of Prayer & Evangelical Counsels',
        );
        await tester.scrollUntilVisible(
          part1Chip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(part1Chip);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Way of Perfection'), findsWidgets);
      },
    );

    testWidgets('tapping Cur Deus Homo volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/anselm_cur_deus_homo_book1.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final book1Chip = find.text('Book I: The Necessity of Redemption');
      await tester.scrollUntilVisible(
        book1Chip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(book1Chip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Cur Deus Homo'), findsWidgets);
    });

    testWidgets('tapping Read Book on Proslogion opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/anselm_proslogion.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final proslogionCard = find.ancestor(
        of: find.text('Proslogion'),
        matching: find.byType(Card),
      );
      final readBtn = find.descendant(
        of: proslogionCard,
        matching: find.widgetWithText(FilledButton, 'Read Book'),
      );

      await tester.scrollUntilVisible(
        readBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(readBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Proslogion'), findsWidgets);
    });

    testWidgets(
      'tapping Read Book on The Rule of St. Benedict opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/benedict_rule.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final benedictCard = find.ancestor(
          of: find.text('The Rule of St. Benedict'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: benedictCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Rule of St. Benedict'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on The Mind\'s Road to God opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/bonaventure_minds_road_to_god.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final bonaventureCard = find.ancestor(
          of: find.text("The Mind's Road to God"),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: bonaventureCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text("The Mind's Road to God"), findsWidgets);
      },
    );

    testWidgets('Favorites tab displays saved bookmarks and can delete them', (
      tester,
    ) async {
      await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: 'didache',
          sectionIndex: 0,
          nodeId: 'ch1_0',
          textPreview: 'The Didache, Chapter 1, Q. 1\nThere are two ways...',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      // Tap Favorites tab
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('The Didache, Chapter 1, Q. 1'), findsOneWidget);
      expect(find.text('There are two ways...'), findsOneWidget);

      // Delete the favorite
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(
        find.text('No favorite passages saved in Library yet.'),
        findsOneWidget,
      );
    });

    testWidgets('Comments tab displays saved comments and can delete them', (
      tester,
    ) async {
      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'baltimore_catechism',
          sectionIndex: 0,
          nodeId: 'no1:lesson_01_1',
          commentText: 'Important lesson on God.',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      // Tap Comments tab
      await tester.tap(find.text('Comments'));
      await tester.pumpAndSettle();

      expect(find.text('Important lesson on God.'), findsOneWidget);

      // Delete the comment
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('No comments on library books yet.'), findsOneWidget);
    });

    testWidgets('category filter chips filter books correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      // Initially All is selected and all categories are present
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Catechisms'), findsOneWidget);
      expect(
        find.widgetWithText(FilterChip, 'Apostolic Fathers'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilterChip, 'Church Fathers'), findsOneWidget);
      expect(
        find.widgetWithText(FilterChip, 'Early Apologists'),
        findsOneWidget,
      );

      expect(find.text('Baltimore Catechism'), findsOneWidget);
      expect(find.text('The Didache'), findsOneWidget);

      // Select 'Apostolic Fathers'
      await tester.tap(find.widgetWithText(FilterChip, 'Apostolic Fathers'));
      await tester.pumpAndSettle();

      expect(find.text('Baltimore Catechism'), findsNothing);
      expect(find.text('The Didache'), findsOneWidget);
      expect(find.text('First Epistle of Clement'), findsOneWidget);
      expect(find.text('Epistles of St. Ignatius'), findsOneWidget);

      // Select 'Catechisms'
      await tester.tap(find.widgetWithText(FilterChip, 'Catechisms'));
      await tester.pumpAndSettle();

      expect(find.text('Baltimore Catechism'), findsOneWidget);
      expect(find.text('Catechism of the Council of Trent'), findsOneWidget);
      expect(find.text('The Didache'), findsNothing);

      // Select 'All'
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('Baltimore Catechism'), findsOneWidget);
      expect(find.text('The Didache'), findsOneWidget);
    });

    testWidgets('renders continue reading hero card and resumes reading', (
      tester,
    ) async {
      await testDb.saveBookReadingPosition(
        bookId: 'didache_lightfoot',
        sectionIndex: 2,
        sectionId: 'ch3',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/didache_lightfoot.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE READING'), findsOneWidget);
      expect(find.text('The Didache'), findsWidgets);
      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('The Didache'), findsWidgets);
    });

    testWidgets('renders era badges and volume counts on book cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      expect(find.text('1885 AD'), findsWidgets);
      expect(find.text('c. 96 AD'), findsWidgets);
      expect(find.text('1566 AD'), findsWidgets);
      expect(find.text('4 Volumes'), findsWidgets);
      expect(find.text('22 Volumes'), findsWidgets);
    });

    testWidgets('tapping Browse All opens volume picker modal sheet', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/baltimore_2.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final browseBtn = find.widgetWithText(TextButton, 'Browse All ▾').first;
      await tester.tap(browseBtn);
      await tester.pumpAndSettle();

      // Modal sheet should display all volumes
      expect(find.text('Select from 4 volumes'), findsOneWidget);
      expect(find.text('No. 2 (Confirmation & Grammar)'), findsWidgets);

      // Tap volume 2 in modal
      await tester.tap(find.text('No. 2 (Confirmation & Grammar)').last);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Baltimore Catechism'), findsWidgets);
    });

    testWidgets('global search groups results by book with match counts', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/didache_lightfoot.json',
        );
        await LibraryHelper.loadBookData(
          'assets/catechism/json/first_clement_lightfoot.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.runAsync(() async {
        await tester.enterText(searchField, 'Baptism');
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SEARCH RESULTS'), findsOneWidget);
      expect(find.textContaining('match'), findsWidgets);
    });

    testWidgets('favorites tab filters bookmarks by book', (tester) async {
      await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: 'didache_lightfoot',
          sectionIndex: 0,
          nodeId: 'ch1_0',
          textPreview: 'The Didache, Chapter 1\nThere are two ways...',
          createdAt: DateTime.now(),
        ),
      );
      await testDb.saveLibraryBookmark(
        LibraryBookmarksCompanion.insert(
          documentId: 'first_clement_lightfoot',
          sectionIndex: 0,
          nodeId: 'ch1_0',
          textPreview: 'First Clement, Chapter 1\nThe Church of God...',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('The Didache, Chapter 1'), findsOneWidget);
      expect(find.text('First Clement, Chapter 1'), findsOneWidget);

      // Filter to Didache
      await tester.tap(find.widgetWithText(FilterChip, 'The Didache (1)'));
      await tester.pumpAndSettle();

      expect(find.text('The Didache, Chapter 1'), findsOneWidget);
      expect(find.text('First Clement, Chapter 1'), findsNothing);

      // Return to All
      await tester.tap(find.widgetWithText(FilterChip, 'All (2)'));
      await tester.pumpAndSettle();

      expect(find.text('The Didache, Chapter 1'), findsOneWidget);
      expect(find.text('First Clement, Chapter 1'), findsOneWidget);
    });

    testWidgets('comments tab filters comments by book', (tester) async {
      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'didache_lightfoot',
          sectionIndex: 0,
          nodeId: 'ch1_0',
          commentText: 'Note on Didache',
          createdAt: DateTime.now(),
        ),
      );
      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'baltimore_catechism',
          sectionIndex: 0,
          nodeId: 'no1:lesson_01_1',
          commentText: 'Note on Baltimore',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comments'));
      await tester.pumpAndSettle();

      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Note on Didache'), findsOneWidget);
      expect(find.text('Note on Baltimore'), findsOneWidget);

      // Filter to Didache
      await tester.tap(find.widgetWithText(FilterChip, 'The Didache (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Note on Didache'), findsOneWidget);
      expect(find.text('Note on Baltimore'), findsNothing);
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

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/baltimore_1.json',
        );
      });

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

    testWidgets(
      'long-press enters selection mode, saves favorite and adds comment',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final didache = catalog.firstWhere((b) => b.id == 'didache_lightfoot');

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/didache_lightfoot.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(body: LibraryReaderScreen(bookItem: didache)),
          ),
        );
        await tester.pumpAndSettle();

        // Long press first content item
        final firstItem = find.textContaining('There are two ways').first;
        await tester.longPress(firstItem);
        await tester.pumpAndSettle();

        // Selection action bar should appear
        expect(find.byType(ReaderSelectionActionBar), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.comment_outlined), findsOneWidget);

        // Tap Save Favorite
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Check database for bookmark
        final bookmarks = await testDb.getLibraryBookmarks(
          documentId: 'didache_lightfoot',
        );
        expect(bookmarks.length, 1);

        // Selection cleared after save
        expect(find.byType(ReaderSelectionActionBar), findsNothing);

        // Long press again to add comment
        await tester.longPress(firstItem);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.comment_outlined));
        await tester.pumpAndSettle();

        // Add Comment dialog appears
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);

        await tester.enterText(
          find.byType(TextField).last,
          'My note on the two ways',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final comments = await testDb.getComments(
          documentId: 'didache_lightfoot',
        );
        expect(comments.length, 1);
        expect(comments.first.commentText, 'My note on the two ways');

        // Verify comment badge is displayed
        expect(find.byIcon(Icons.comment_rounded), findsWidgets);
      },
    );

    testWidgets(
      'displays comment badge on series books with volume-prefixed nodeId',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final baltimore = catalog.firstWhere(
          (b) => b.id == 'baltimore_catechism',
        );

        await testDb.saveComment(
          UserCommentsCompanion.insert(
            documentId: 'baltimore_catechism',
            sectionIndex: 0,
            nodeId: 'no1:sec_1_0',
            commentText: 'Note on First Communion Q1',
            createdAt: DateTime.now(),
          ),
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_1.json',
          );
        });

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

        // Verify comment badge is visible on the Baltimore Catechism item
        expect(find.byIcon(Icons.comment_rounded), findsWidgets);
        expect(find.text('1'), findsWidgets);
      },
    );

    testGoldens('LibraryReaderScreen renders Baltimore No. 2', (tester) async {
      final catalog = LibraryHelper.getCatalog();
      final baltimore = catalog.firstWhere(
        (b) => b.id == 'baltimore_catechism',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/baltimore_2.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(
          body: LibraryReaderScreen(
            bookItem: baltimore,
            initialVolumeKey: 'no2',
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'catechism_baltimore_2_reader_golden');
    });

    testGoldens(
      'LibraryReaderScreen renders Baltimore No. 3 with Cross-References',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final baltimore = catalog.firstWhere(
          (b) => b.id == 'baltimore_catechism',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_3.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: baltimore,
              initialVolumeKey: 'no3',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'catechism_baltimore_3_reader_golden',
        );
      },
    );

    testGoldens(
      'LibraryReaderScreen renders Baltimore No. 4 with Explanations',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final baltimore = catalog.firstWhere(
          (b) => b.id == 'baltimore_catechism',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/baltimore_4.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: baltimore,
              initialVolumeKey: 'no4',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'catechism_baltimore_4_reader_golden',
        );
      },
    );

    testGoldens(
      'LibraryReaderScreen renders Catechism of the Council of Trent',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final trent = catalog.firstWhere((b) => b.id == 'council_of_trent');

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/council_of_trent.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(body: LibraryReaderScreen(bookItem: trent)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'catechism_trent_reader_golden');
      },
    );

    testGoldens('LibraryReaderScreen renders The Didache', (tester) async {
      final catalog = LibraryHelper.getCatalog();
      final didache = catalog.firstWhere((b) => b.id == 'didache_lightfoot');

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/didache_lightfoot.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: didache)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'didache_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders First Epistle of Clement', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final firstClement = catalog.firstWhere(
        (b) => b.id == 'first_clement_lightfoot',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/first_clement_lightfoot.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: firstClement)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'first_clement_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders Second Epistle of Clement', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final secondClement = catalog.firstWhere(
        (b) => b.id == 'second_clement_lightfoot',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/second_clement_lightfoot.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: secondClement)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'second_clement_reader_golden');
    });

    testGoldens(
      'LibraryReaderScreen renders Epistles of St. Ignatius (Romans)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final ignatius = catalog.firstWhere((b) => b.id == 'ignatius_epistles');

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/ignatius_romans_lightfoot.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: ignatius,
              initialVolumeKey: 'romans',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'ignatius_romans_reader_golden');
      },
    );

    testGoldens(
      'LibraryReaderScreen renders Epistles of St. Ignatius (Ephesians)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final ignatius = catalog.firstWhere((b) => b.id == 'ignatius_epistles');

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/ignatius_ephesians_lightfoot.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: ignatius,
              initialVolumeKey: 'ephesians',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'ignatius_ephesians_reader_golden');
      },
    );

    testGoldens('LibraryReaderScreen renders First Apology of Justin Martyr', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final justin = catalog.firstWhere(
        (b) => b.id == 'justin_martyr_apologies',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/justin_first_apology_dods.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(
          body: LibraryReaderScreen(
            bookItem: justin,
            initialVolumeKey: 'first_apology',
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'justin_first_apology_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders Second Apology of Justin Martyr', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final justin = catalog.firstWhere(
        (b) => b.id == 'justin_martyr_apologies',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/justin_second_apology_dods.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(
          body: LibraryReaderScreen(
            bookItem: justin,
            initialVolumeKey: 'second_apology',
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'justin_second_apology_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders Against Heresies (Book III)', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final irenaeus = catalog.firstWhere(
        (b) => b.id == 'irenaeus_against_heresies',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/irenaeus_against_heresies_book3.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(
          body: LibraryReaderScreen(
            bookItem: irenaeus,
            initialVolumeKey: 'book3',
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'irenaeus_book3_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders On the Incarnation of the Word', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final athanasius = catalog.firstWhere(
        (b) => b.id == 'athanasius_on_the_incarnation',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/athanasius_on_the_incarnation.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: athanasius)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'athanasius_incarnation_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders The Confessions (Book VIII)', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final confessions = catalog.firstWhere(
        (b) => b.id == 'augustine_confessions',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/augustine_confessions_book8.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(
          body: LibraryReaderScreen(
            bookItem: confessions,
            initialVolumeKey: 'book8',
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'augustine_confessions_book8_golden');
    });

    testGoldens('LibraryReaderScreen renders The City of God (Book XIX)', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final cityOfGod = catalog.firstWhere(
        (b) => b.id == 'augustine_city_of_god',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/augustine_city_of_god_book19.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(
          body: LibraryReaderScreen(
            bookItem: cityOfGod,
            initialVolumeKey: 'book19',
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'augustine_city_of_god_book19_golden');
    });

    testGoldens(
      'LibraryReaderScreen renders Cyril Catechetical Lectures (Vol. IV)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final cyril = catalog.firstWhere(
          (b) => b.id == 'cyril_catechetical_lectures',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/cyril_catechetical_lectures_vol4.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: cyril,
              initialVolumeKey: 'vol4',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'cyril_lectures_vol4_golden');
      },
    );

    testGoldens(
      'LibraryReaderScreen renders St. Gregory The Five Theological Orations',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final gregory = catalog.firstWhere(
          (b) => b.id == 'gregory_theological_orations',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/gregory_theological_orations_oration1.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: gregory,
              initialVolumeKey: 'oration1',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'gregory_theological_orations_oration1_golden',
        );
      },
    );

    testGoldens('LibraryReaderScreen renders St. Ambrose On the Mysteries', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final ambrose = catalog.firstWhere(
        (b) => b.id == 'ambrose_mysteries_and_sacraments',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/ambrose_on_the_mysteries.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(
          body: LibraryReaderScreen(
            bookItem: ambrose,
            initialVolumeKey: 'on_the_mysteries',
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'ambrose_mysteries_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders St. Basil On the Holy Spirit', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final basil = catalog.firstWhere(
        (b) => b.id == 'basil_on_the_holy_spirit',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/basil_on_the_holy_spirit.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: basil)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'basil_holy_spirit_reader_golden');
    });

    testGoldens(
      'LibraryReaderScreen renders St. Vincent of Lérins The Commonitory',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final vincent = catalog.firstWhere(
          (b) => b.id == 'vincent_commonitory',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/vincent_commonitory.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(body: LibraryReaderScreen(bookItem: vincent)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'vincent_commonitory_reader_golden');
      },
    );

    testGoldens(
      'LibraryReaderScreen renders St. Athanasius Life of St. Anthony',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final anthony = catalog.firstWhere(
          (b) => b.id == 'athanasius_life_of_anthony',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/athanasius_life_of_anthony.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(body: LibraryReaderScreen(bookItem: anthony)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'athanasius_life_of_anthony_reader_golden',
        );
      },
    );

    testGoldens(
      'LibraryReaderScreen renders St. John Chrysostom On the Priesthood (Book I)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final chrysostom = catalog.firstWhere(
          (b) => b.id == 'chrysostom_on_the_priesthood',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/chrysostom_on_the_priesthood_book1.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: chrysostom,
              initialVolumeKey: 'book1',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'chrysostom_priesthood_reader_golden',
        );
      },
    );

    testWidgets(
      'LibraryReaderScreen renders Chrysostom On the Priesthood (Book III)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final chrysostom = catalog.firstWhere(
          (b) => b.id == 'chrysostom_on_the_priesthood',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/chrysostom_on_the_priesthood_book3.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryReaderScreen(
                bookItem: chrysostom,
                initialVolumeKey: 'book3',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('On the Priesthood'), findsWidgets);
        expect(find.text('Section 1 of 17'), findsOneWidget);
      },
    );

    testWidgets(
      'LibraryReaderScreen renders Chrysostom On the Priesthood (Book VI)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final chrysostom = catalog.firstWhere(
          (b) => b.id == 'chrysostom_on_the_priesthood',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/chrysostom_on_the_priesthood_book6.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryReaderScreen(
                bookItem: chrysostom,
                initialVolumeKey: 'book6',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('On the Priesthood'), findsWidgets);
        expect(find.text('Section 1 of 13'), findsOneWidget);
      },
    );

    testWidgets('tapping Chrysostom volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/chrysostom_on_the_priesthood_book1.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final chip = find.text('Book I (Youth & the Holy Scheme)');
      await tester.scrollUntilVisible(
        chip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('On the Priesthood'), findsWidgets);
      expect(find.text('Section 1 of 8'), findsOneWidget);
    });

    testGoldens(
      'LibraryReaderScreen renders Aquinas Compendium of Theology (Part I)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final compendium = catalog.firstWhere(
          (b) => b.id == 'aquinas_compendium_of_theology',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/aquinas_compendium_of_theology_part1.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: compendium,
              initialVolumeKey: 'part1',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'aquinas_compendium_part1_reader_golden',
        );
      },
    );

    testGoldens(
      'LibraryReaderScreen renders Aquinas Catechetical Instructions (The Apostles\' Creed)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final catechetical = catalog.firstWhere(
          (b) => b.id == 'aquinas_catechetical_instructions',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/aquinas_catechetical_creed.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: catechetical,
              initialVolumeKey: 'creed',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'aquinas_catechetical_creed_reader_golden',
        );
      },
    );

    testGoldens('LibraryReaderScreen renders True Devotion to Mary', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final montfort = catalog.firstWhere(
        (b) => b.id == 'montfort_true_devotion',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/montfort_true_devotion.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: montfort)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'montfort_true_devotion_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders The Rule of St. Benedict', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final benedict = catalog.firstWhere((b) => b.id == 'benedict_rule');

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/benedict_rule.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: benedict)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'benedict_rule_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders St. Teresa The Interior Castle', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final teresa = catalog.firstWhere(
        (b) => b.id == 'teresa_interior_castle',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/teresa_interior_castle.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: teresa)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'teresa_interior_castle_golden');
    });

    testGoldens('LibraryReaderScreen renders The Imitation of Christ', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final kempis = catalog.firstWhere(
        (b) => b.id == 'kempis_imitation_of_christ',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/kempis_imitation_of_christ.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: kempis)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'kempis_imitation_reader_golden');
    });

    testGoldens(
      'LibraryReaderScreen renders St. Bonaventure The Mind\'s Road to God correctly',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final bonaventure = catalog.firstWhere(
          (b) => b.id == 'bonaventure_minds_road_to_god',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/bonaventure_minds_road_to_god.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(body: LibraryReaderScreen(bookItem: bonaventure)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'bonaventure_minds_road_to_god_golden',
        );
      },
    );

    testWidgets('renders interactive Scripture citation chip', (tester) async {
      final catalog = LibraryHelper.getCatalog();
      final baltimore = catalog.firstWhere(
        (b) => b.id == 'baltimore_catechism',
      );

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/baltimore_4.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryReaderScreen(
              bookItem: baltimore,
              initialVolumeKey: 'no4',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
    });

    testWidgets(
      'LibraryReaderScreen restores saved reading position and updates on navigation',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final confessions = catalog.firstWhere(
          (b) => b.id == 'augustine_confessions',
        );

        await testDb.saveBookReadingPosition(
          bookId: 'augustine_confessions',
          volumeKey: 'book8',
          sectionIndex: 2,
          sectionId: 'sec_augustine_confessions_b8_3',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/augustine_confessions_book8.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(body: LibraryReaderScreen(bookItem: confessions)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        // Verify Section 3 of 12 (index 2) is displayed
        expect(find.text('Section 3 of 12'), findsOneWidget);

        // Tap Next Section
        final nextBtn = find.byTooltip('Next Section');
        expect(nextBtn, findsOneWidget);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();

        final updatedPos = await testDb.getBookReadingPosition(
          'augustine_confessions',
        );
        expect(updatedPos, isNotNull);
        expect(updatedPos!.sectionIndex, equals(3));
      },
    );

    testWidgets(
      'LibraryTab resumes from saved reading position when opening book',
      (tester) async {
        await testDb.saveBookReadingPosition(
          bookId: 'didache_lightfoot',
          sectionIndex: 1,
          sectionId: 'sec_didache_lightfoot_2',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/didache_lightfoot.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        // Scroll and find "Read Book" for Didache
        final didacheCard = find.ancestor(
          of: find.text('The Didache'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: didacheCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );
        await tester.ensureVisible(readBtn);
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Section 2 of 16'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Read Book on Dialogue with Trypho opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/justin_dialogue_trypho_dods.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final tryphoCard = find.ancestor(
          of: find.text('Dialogue with Trypho'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: tryphoCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Dialogue with Trypho'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on Ascent of Mount Carmel opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/john_cross_ascent_mount_carmel.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final ascentCard = find.ancestor(
          of: find.text('Ascent of Mount Carmel'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: ascentCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Ascent of Mount Carmel'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Read Book on Dark Night of the Soul opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/john_cross_dark_night_soul.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final darkNightCard = find.ancestor(
          of: find.text('Dark Night of the Soul'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: darkNightCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Dark Night of the Soul'), findsWidgets);
      },
    );

    testGoldens(
      'LibraryReaderScreen renders St. Justin Martyr Dialogue with Trypho',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final trypho = catalog.firstWhere(
          (b) => b.id == 'justin_dialogue_trypho',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/justin_dialogue_trypho_dods.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(body: LibraryReaderScreen(bookItem: trypho)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'justin_dialogue_trypho_reader_golden',
        );
      },
    );

    testGoldens(
      'LibraryReaderScreen renders St. John of the Cross Ascent of Mount Carmel',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final ascent = catalog.firstWhere(
          (b) => b.id == 'john_cross_ascent_mount_carmel',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/john_cross_ascent_mount_carmel.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(body: LibraryReaderScreen(bookItem: ascent)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'john_cross_ascent_mount_carmel_reader_golden',
        );
      },
    );

    testGoldens(
      'LibraryReaderScreen renders St. John of the Cross Dark Night of the Soul',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final darkNight = catalog.firstWhere(
          (b) => b.id == 'john_cross_dark_night_soul',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/john_cross_dark_night_soul.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(body: LibraryReaderScreen(bookItem: darkNight)),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'john_cross_dark_night_soul_reader_golden',
        );
      },
    );

    testGoldens('LibraryReaderScreen renders Proslogion', (tester) async {
      final catalog = LibraryHelper.getCatalog();
      final proslogion = catalog.firstWhere((b) => b.id == 'anselm_proslogion');

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/anselm_proslogion.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(body: LibraryReaderScreen(bookItem: proslogion)),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'anselm_proslogion_reader_golden');
    });

    testGoldens('LibraryReaderScreen renders Cur Deus Homo (Book I)', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final curDeus = catalog.firstWhere((b) => b.id == 'anselm_cur_deus_homo');

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/anselm_cur_deus_homo_book1.json',
        );
      });

      await tester.pumpWidgetBuilder(
        Scaffold(
          body: LibraryReaderScreen(
            bookItem: curDeus,
            initialVolumeKey: 'book1',
          ),
        ),
        wrapper: materialAppWrapper(),
        surfaceSize: const Size(480, 800),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'anselm_cur_deus_homo_book1_reader_golden',
      );
    });

    testWidgets('LibraryReaderScreen renders Cur Deus Homo (Book II)', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final curDeus = catalog.firstWhere((b) => b.id == 'anselm_cur_deus_homo');

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/anselm_cur_deus_homo_book2.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryReaderScreen(
              bookItem: curDeus,
              initialVolumeKey: 'book2',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Cur Deus Homo'), findsWidgets);
      expect(find.text('Section 1 of 22'), findsOneWidget);
    });

    testWidgets(
      'tapping Read Book on The Interior Castle opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/teresa_interior_castle.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final teresaCard = find.ancestor(
          of: find.text('The Interior Castle'),
          matching: find.byType(Card),
        );
        final readBtn = find.descendant(
          of: teresaCard,
          matching: find.widgetWithText(FilledButton, 'Read Book'),
        );

        await tester.scrollUntilVisible(
          readBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Interior Castle'), findsWidgets);
      },
    );

    testWidgets(
      'LibraryReaderScreen renders St. Vincent of Lérins The Commonitory',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final vincent = catalog.firstWhere(
          (b) => b.id == 'vincent_commonitory',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/vincent_commonitory.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(body: LibraryReaderScreen(bookItem: vincent)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Commonitory'), findsWidgets);
        expect(find.text('Section 1 of 33'), findsOneWidget);
      },
    );

    testWidgets(
      'LibraryReaderScreen renders St. Athanasius Life of St. Anthony',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final anthony = catalog.firstWhere(
          (b) => b.id == 'athanasius_life_of_anthony',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/athanasius_life_of_anthony.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(body: LibraryReaderScreen(bookItem: anthony)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Life of St. Anthony'), findsWidgets);
        expect(find.text('Section 1 of 94'), findsOneWidget);
      },
    );

    testGoldens(
      'LibraryReaderScreen renders Pope St. Leo the Great Tome and Sermons Vol. 1',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final leo = catalog.firstWhere(
          (b) => b.id == 'leo_great_tome_and_sermons',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/leo_tome_and_letters.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: leo,
              initialVolumeKey: 'tome_and_letters',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'leo_great_tome_and_letters_reader_golden',
        );
      },
    );

    testWidgets(
      'LibraryReaderScreen renders Pope St. Leo the Great Tome and Sermons Vol. 2',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final leo = catalog.firstWhere(
          (b) => b.id == 'leo_great_tome_and_sermons',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/leo_selected_sermons.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryReaderScreen(
                bookItem: leo,
                initialVolumeKey: 'selected_sermons',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Tome & Selected Works'), findsWidgets);
        expect(find.text('Section 1 of 12'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping St. Leo the Great volume chip opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/leo_tome_and_letters.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final chip = find.text(
          'Vol. I (The Tome to Flavian & Christological Letters)',
        );
        await tester.scrollUntilVisible(
          chip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(chip);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Tome & Selected Works'), findsWidgets);
      },
    );

    testGoldens(
      'LibraryReaderScreen renders St. Teresa The Way of Perfection (Vol. I)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final teresa = catalog.firstWhere(
          (b) => b.id == 'teresa_way_of_perfection',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/teresa_way_perfection_part1.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: teresa,
              initialVolumeKey: 'part1',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'teresa_way_perfection_part1_reader_golden',
        );
      },
    );

    testWidgets(
      'LibraryReaderScreen renders St. Teresa The Way of Perfection (Vol. II)',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final teresa = catalog.firstWhere(
          (b) => b.id == 'teresa_way_of_perfection',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/teresa_way_perfection_part2.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryReaderScreen(
                bookItem: teresa,
                initialVolumeKey: 'part2',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Way of Perfection'), findsWidgets);
        expect(find.text('Section 1 of 24'), findsOneWidget);
      },
    );

    testGoldens(
      'LibraryReaderScreen renders St. Cyprian of Carthage On the Unity of the Church & Treatises',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final cyprian = catalog.firstWhere(
          (b) => b.id == 'cyprian_unity_of_church',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/cyprian_unity_and_lapsed.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: cyprian,
              initialVolumeKey: 'unity_and_lapsed',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'cyprian_unity_and_lapsed_reader_golden',
        );
      },
    );

    testWidgets('tapping Damascene volume chip opens LibraryReaderScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/damascene_orthodox_faith_book1.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(child: const Scaffold(body: LibraryTab())),
      );
      await tester.pumpAndSettle();

      final book1Chip = find.text('Book I (The Godhead & the Trinity)');
      await tester.scrollUntilVisible(
        book1Chip,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(book1Chip);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(
        find.text('An Exact Exposition of the Orthodox Faith'),
        findsWidgets,
      );
    });

    testGoldens(
      'LibraryReaderScreen renders St. John Damascene An Exact Exposition of the Orthodox Faith',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final damascene = catalog.firstWhere(
          (b) => b.id == 'john_damascene_orthodox_faith',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/damascene_orthodox_faith_book1.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: damascene,
              initialVolumeKey: 'book1',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'damascene_orthodox_faith_book1_reader_golden',
        );
      },
    );

    testWidgets(
      'tapping Gregory Pastoral Rule volume chip opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/gregory_pastoral_rule_book1.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final book1Chip = find.text('Book I (The Pastoral Office)');
        await tester.scrollUntilVisible(
          book1Chip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(book1Chip);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Pastoral Rule'), findsWidgets);
      },
    );

    testGoldens(
      'LibraryReaderScreen renders Pope St. Gregory the Great Pastoral Rule',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final gregory = catalog.firstWhere(
          (b) => b.id == 'gregory_pastoral_rule',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/gregory_pastoral_rule_book1.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: gregory,
              initialVolumeKey: 'book1',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'gregory_pastoral_rule_book1_reader_golden',
        );
      },
    );

    testWidgets(
      'tapping St. Francis de Sales Treatise on the Love of God volume chip opens LibraryReaderScreen',
      (tester) async {
        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/sales_love_of_god_vol1.json',
          );
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final vol1Chip = find.text(
          'Vol. I (Origin and Motives of Divine Love)',
        );
        await tester.scrollUntilVisible(
          vol1Chip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(vol1Chip);
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Treatise on the Love of God'), findsWidgets);
      },
    );

    testGoldens(
      'LibraryReaderScreen renders St. Francis de Sales Treatise on the Love of God',
      (tester) async {
        final catalog = LibraryHelper.getCatalog();
        final loveOfGod = catalog.firstWhere(
          (b) => b.id == 'francis_de_sales_love_of_god',
        );

        await tester.runAsync(() async {
          await LibraryHelper.loadBookData(
            'assets/catechism/json/sales_love_of_god_vol1.json',
          );
        });

        await tester.pumpWidgetBuilder(
          Scaffold(
            body: LibraryReaderScreen(
              bookItem: loveOfGod,
              initialVolumeKey: 'vol1',
            ),
          ),
          wrapper: materialAppWrapper(),
          surfaceSize: const Size(480, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'sales_love_of_god_vol1_reader_golden',
        );
      },
    );

    testWidgets(
      'tapping author of book with authorSaintId opens SaintDetailsSheet',
      (tester) async {
        await tester.runAsync(() async {
          await SaintDatabase.loadSaints();
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final authorFinder = find.text(
          'By Pope St. Clement of Rome (Trans. J. B. Lightfoot)',
        );
        await tester.scrollUntilVisible(
          authorFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(authorFinder);
        await tester.pumpAndSettle();

        expect(find.byType(SaintDetailsSheet), findsOneWidget);
        expect(find.text('St. Clement of Rome'), findsWidgets);
      },
    );

    testWidgets(
      'tapping Doctor of Church author opens SaintDetailsSheet with Doctor badge',
      (tester) async {
        await tester.runAsync(() async {
          await SaintDatabase.loadSaints();
        });

        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: LibraryTab())),
        );
        await tester.pumpAndSettle();

        final authorFinder = find.text(
          'By St. Thomas Aquinas (Trans. Cyril Vollert)',
        );
        await tester.scrollUntilVisible(
          authorFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(authorFinder);
        await tester.pumpAndSettle();

        expect(find.byType(SaintDetailsSheet), findsOneWidget);
        expect(find.text('St. Thomas Aquinas'), findsWidgets);
        expect(find.text('Doctor'), findsOneWidget);
      },
    );
  });
}
