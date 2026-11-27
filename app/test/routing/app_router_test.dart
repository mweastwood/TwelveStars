import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/routing/app_router.dart';
import 'package:twelve_stars/screens/bible_notes_screen.dart';
import 'package:twelve_stars/screens/bible_tab.dart';
import 'package:twelve_stars/screens/confirmation_discernment_screen.dart';
import 'package:twelve_stars/screens/home_screen.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/screens/missal_tab.dart';
import 'package:twelve_stars/screens/rosary_screen.dart';
import 'package:twelve_stars/screens/saints_screen.dart';
import 'package:twelve_stars/screens/settings_screen.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';
import 'package:twelve_stars/screens/website_viewer_screen.dart';

void main() {
  setUp(() {
    PrayerDatabase.mockPrayers = [
      Prayer(
        prayerId: 'our_father',
        category: 'Basic',
        defaultTitle: 'Our Father',
      ),
    ];
    PrayerDatabase.mockSettings = UserSettings();
    UserSettingsController.instance.resetForTesting();
  });

  tearDown(() {
    PrayerDatabase.mockPrayers = null;
    PrayerDatabase.mockSettings = null;
    UserSettingsController.instance.resetForTesting();
  });

  group('AppRoutes helpers', () {
    test('tabPath and tabIndexForPath map all 4 tabs', () {
      expect(AppRoutes.tabPath(0), '/missal');
      expect(AppRoutes.tabPath(1), '/prayers');
      expect(AppRoutes.tabPath(2), '/bible');
      expect(AppRoutes.tabPath(3), '/library');

      expect(AppRoutes.tabIndexForPath('/missal'), 0);
      expect(AppRoutes.tabIndexForPath('/prayers'), 1);
      expect(AppRoutes.tabIndexForPath('/bible'), 2);
      expect(AppRoutes.tabIndexForPath('/bible/john/3'), 2);
      expect(AppRoutes.tabIndexForPath('/library'), 3);
    });

    test('missalPath formats date query and parseDateQuery parses it', () {
      expect(AppRoutes.missalPath(), '/missal');
      expect(
        AppRoutes.missalPath(date: DateTime(2026, 11, 21)),
        '/missal?date=2026-11-21',
      );
      expect(AppRoutes.parseDateQuery('2026-11-21'), DateTime(2026, 11, 21));
      expect(AppRoutes.parseDateQuery('invalid'), isNull);
      expect(AppRoutes.parseDateQuery('2026-02-31'), isNull);
      expect(AppRoutes.parseDateQuery('2026-99-99'), isNull);
      expect(AppRoutes.parseDateQuery('2025-02-29'), isNull);
      expect(AppRoutes.parseDateQuery('2024-02-29'), DateTime(2024, 2, 29));
    });

    test('biblePath and findBibleBook resolve books by slug, USFM, or num', () {
      final john = AppRoutes.findBibleBook('john');
      expect(john, isNotNull);
      expect(john!.abbrev, 'JHN');
      expect(AppRoutes.findBibleBook('jhn')?.bookNumber, john.bookNumber);
      expect(
        AppRoutes.findBibleBook(john.bookNumber.toString())?.bookNumber,
        john.bookNumber,
      );
      expect(
        AppRoutes.biblePath(
          bookSlug: AppRoutes.bookSlug(john),
          chapter: 3,
          verse: 16,
        ),
        '/bible/john/3?v=16',
      );
      expect(
        AppRoutes.findBibleBook('1-corinthians')?.bookNumber,
        catholicBooks
            .firstWhere((b) => b.bookName == '1 Corinthians')
            .bookNumber,
      );
    });

    test('libraryBookPath encodes volume and query parameters', () {
      expect(
        AppRoutes.libraryBookPath(
          'baltimore_catechism',
          volumeKey: 'vol1',
          sectionId: 'lesson_1',
          questionNumber: 4,
          itemIndex: 2,
        ),
        '/library/book/baltimore_catechism/vol1?section=lesson_1&q=4&item=2',
      );
      expect(
        AppRoutes.libraryThemePath('sacraments.eucharist'),
        '/library/themes/sacraments.eucharist',
      );
    });
  });

  group('createAppRouter navigation', () {
    testWidgets('root / redirects to /missal and renders HomeScreen', (
      tester,
    ) async {
      final router = createAppRouter(initialLocation: AppRoutes.root);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.missal);
    });

    testWidgets('tapping navigation tabs updates the browser URL path', (
      tester,
    ) async {
      final router = createAppRouter(initialLocation: AppRoutes.missal);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Prayers'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.prayers);

      await tester.tap(find.text('Library'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.library);
    });

    testWidgets(
      '/missal?date=2026-11-21 passes initialDate and updates mounted MissalTab',
      (tester) async {
        final router = createAppRouter(
          initialLocation: '/missal?date=2026-11-21',
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(MissalTab), findsOneWidget);
        expect(find.textContaining('November 21, 2026'), findsOneWidget);

        router.go('/missal?date=2026-12-25');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.textContaining('December 25, 2026'), findsOneWidget);
      },
    );

    testWidgets('/bible/:book/:chapter?v=... opens BibleTab at target verse', (
      tester,
    ) async {
      final router = createAppRouter(initialLocation: '/bible/john/3?v=16');
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(BibleTab), findsOneWidget);
      final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(home.selectedTab, 2);
      expect(home.initialBibleTarget?.book.abbrev, 'JHN');
      expect(home.initialBibleTarget?.chapter, 3);
      expect(home.initialBibleTarget?.verse, 16);
    });

    testWidgets('/bible/notes renders BibleNotesScreen', (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.bibleNotes);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(BibleNotesScreen), findsOneWidget);
    });

    testWidgets(
      '/library/book/:bookId and /:volumeKey open LibraryReaderScreen, unknown redirects to /library, web book redirects to /library/web',
      (tester) async {
        final router = createAppRouter(
          initialLocation: '/library/book/baltimore_catechism/no1',
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(LibraryReaderScreen), findsOneWidget);
        final reader = tester.widget<LibraryReaderScreen>(
          find.byType(LibraryReaderScreen),
        );
        expect(reader.bookItem.id, 'baltimore_catechism');
        expect(reader.initialVolumeKey, 'no1');

        router.go('/library/book/nonexistent_book');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.library,
        );
        expect(find.byType(HomeScreen), findsOneWidget);

        router.go('/library/book/ccc_usccb');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.libraryWeb,
        );
        expect(find.byType(WebsiteViewerScreen), findsOneWidget);
      },
    );

    testWidgets('/library/themes/:themeId opens ThematicQuoteBrowserScreen', (
      tester,
    ) async {
      final router = createAppRouter(
        initialLocation: '/library/themes/sacraments.eucharist',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ThematicQuoteBrowserScreen), findsOneWidget);
    });

    testWidgets(
      '/library/web renders WebsiteViewerScreen with valid url and redirects to /library when missing',
      (tester) async {
        final router = createAppRouter(
          initialLocation: AppRoutes.libraryWebPath(
            'https://example.com',
            title: 'Example',
          ),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(WebsiteViewerScreen), findsOneWidget);

        router.go(AppRoutes.libraryWeb);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.library,
        );
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets('push and router.pop() transitions restore previous route', (
      tester,
    ) async {
      final router = createAppRouter(initialLocation: AppRoutes.missal);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomeScreen), findsOneWidget);

      router.push(AppRoutes.settings);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(router.canPop(), isTrue);
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        AppRoutes.settings,
      );

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(router.canPop(), isFalse);
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        AppRoutes.missal,
      );
    });

    testWidgets('deep links open standalone feature routes', (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.settings);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SettingsScreen), findsOneWidget);

      router.go(AppRoutes.saints);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SaintsScreen), findsOneWidget);

      router.go(AppRoutes.discernment);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(ConfirmationDiscernmentScreen), findsOneWidget);

      router.go(AppRoutes.rosary);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(RosaryScreen), findsOneWidget);
    });

    testWidgets(
      'imperative push updates browser URL for pushed routes and pop restores it',
      (tester) async {
        final router = createAppRouter(initialLocation: AppRoutes.missal);
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        router.push(AppRoutes.saints);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(SaintsScreen), findsOneWidget);
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.saints,
        );

        router.push(AppRoutes.discernment);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(ConfirmationDiscernmentScreen), findsOneWidget);
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.discernment,
        );

        router.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.saints,
        );
      },
    );

    testWidgets('unknown route falls back to HomeScreen', (tester) async {
      final router = createAppRouter(initialLocation: '/does-not-exist');
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
