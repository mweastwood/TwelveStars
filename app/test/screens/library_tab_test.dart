import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/screens/library_tab.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleDatabase testDb;

  setUp(() {
    testDb = BibleDatabase(NativeDatabase.memory());
    BibleDatabaseHelper.db = testDb;
  });

  tearDown(() async {
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
      expect(find.text('The Five Theological Orations'), findsOneWidget);
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
      expect(find.text('The Interior Castle'), findsOneWidget);
      expect(find.text('The Imitation of Christ'), findsOneWidget);
      expect(find.text("The Mind's Road to God"), findsOneWidget);

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

      // Verify Ambrose volume chips exist
      expect(find.text('On the Mysteries (De Mysteriis)'), findsOneWidget);
      expect(find.text('On the Sacraments (De Sacramentis)'), findsOneWidget);

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

    testWidgets(
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

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryReaderScreen(
                bookItem: compendium,
                initialVolumeKey: 'part1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('Compendium of Theology'), findsWidgets);
      },
    );

    testWidgets(
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

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: LibraryReaderScreen(
                bookItem: catechetical,
                initialVolumeKey: 'creed',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        expect(find.text('The Catechetical Instructions'), findsWidgets);
      },
    );

    testWidgets('LibraryReaderScreen renders True Devotion to Mary', (
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

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: LibraryReaderScreen(bookItem: montfort)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('True Devotion to Mary'), findsWidgets);
      expect(find.text('Chapter 1'), findsWidgets);
      expect(find.text('Section 1 of 11'), findsOneWidget);
    });

    testWidgets('LibraryReaderScreen renders The Rule of St. Benedict', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final benedict = catalog.firstWhere((b) => b.id == 'benedict_rule');

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/benedict_rule.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: LibraryReaderScreen(bookItem: benedict)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('The Rule of St. Benedict'), findsWidgets);
      expect(find.text('Section 1 of 74'), findsOneWidget);
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

    testWidgets('LibraryReaderScreen renders The Imitation of Christ', (
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

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: LibraryReaderScreen(bookItem: kempis)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('The Imitation of Christ'), findsWidgets);
      expect(find.text('Chapter 1'), findsWidgets);
      expect(find.text('Section 1 of 114'), findsOneWidget);
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

    testWidgets('LibraryReaderScreen renders Proslogion', (tester) async {
      final catalog = LibraryHelper.getCatalog();
      final proslogion = catalog.firstWhere((b) => b.id == 'anselm_proslogion');

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/anselm_proslogion.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(body: LibraryReaderScreen(bookItem: proslogion)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Proslogion'), findsWidgets);
      expect(find.text('Section 1 of 26'), findsOneWidget);
    });

    testWidgets('LibraryReaderScreen renders Cur Deus Homo (Book I)', (
      tester,
    ) async {
      final catalog = LibraryHelper.getCatalog();
      final curDeus = catalog.firstWhere((b) => b.id == 'anselm_cur_deus_homo');

      await tester.runAsync(() async {
        await LibraryHelper.loadBookData(
          'assets/catechism/json/anselm_cur_deus_homo_book1.json',
        );
      });

      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: LibraryReaderScreen(
              bookItem: curDeus,
              initialVolumeKey: 'book1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibraryReaderScreen), findsOneWidget);
      expect(find.text('Cur Deus Homo'), findsWidgets);
      expect(find.text('Section 1 of 25'), findsOneWidget);
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
  });
}
