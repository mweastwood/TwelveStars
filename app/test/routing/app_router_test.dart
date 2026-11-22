import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/routing/app_router.dart';
import 'package:twelve_stars/screens/confirmation_discernment_screen.dart';
import 'package:twelve_stars/screens/home_screen.dart';
import 'package:twelve_stars/screens/rosary_screen.dart';
import 'package:twelve_stars/screens/saints_screen.dart';
import 'package:twelve_stars/screens/settings_screen.dart';

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
