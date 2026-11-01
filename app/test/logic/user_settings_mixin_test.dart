import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/notification_service.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/screens/home_screen.dart';
import 'package:twelve_stars/screens/settings_screen.dart';
import '../test_helper.dart';

class _FakeNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<void> cancel({required int id, String? tag}) async {}

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required dynamic scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    bool uiLocalNotificationDateInterpretation = true,
  }) async {}
}

class _MixinTestWidget extends StatefulWidget {
  final void Function(UserSettings settings)? onChanged;
  final void Function(UserSettings loaded)? onLoaded;

  const _MixinTestWidget({this.onChanged, this.onLoaded});

  @override
  State<_MixinTestWidget> createState() => _MixinTestWidgetState();
}

class _MixinTestWidgetState extends State<_MixinTestWidget>
    with UserSettingsStateMixin<_MixinTestWidget> {
  String _languageCode = '';

  @override
  void initState() {
    super.initState();
    _languageCode = currentSettings.primaryLanguageCode;
    ensureUserSettingsLoaded().then((loaded) {
      widget.onLoaded?.call(loaded);
    });
  }

  @override
  void onUserSettingsChanged(UserSettings settings) {
    widget.onChanged?.call(settings);
    setState(() {
      _languageCode = settings.primaryLanguageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('lang:$_languageCode', textDirection: TextDirection.ltr);
  }
}

void main() {
  setUp(() {
    NotificationService.mockPlugin = _FakeNotificationsPlugin();
    PrayerDatabase.mockSettings = null;
    PrayerDatabase.mockPrayers = null;
    UserSettingsController.instance.resetForTesting();
  });

  tearDown(() {
    NotificationService.mockPlugin = null;
    BibleDatabaseHelper.db = null;
    PrayerDatabase.mockSettings = null;
    PrayerDatabase.mockPrayers = null;
    UserSettingsController.instance.resetForTesting();
  });

  group('UserSettingsStateMixin lifecycle', () {
    testWidgets(
      'subscribes in initState, receives onUserSettingsChanged updates, and unsubscribes on dispose',
      (tester) async {
        PrayerDatabase.mockSettings = UserSettings(
          primaryLanguageCode: 'spanish',
        );

        final received = <String>[];
        UserSettings? loadedSettings;

        await tester.pumpWidget(
          _MixinTestWidget(
            onChanged: (s) => received.add(s.primaryLanguageCode),
            onLoaded: (s) => loadedSettings = s,
          ),
        );
        await tester.pumpAndSettle();

        expect(loadedSettings?.primaryLanguageCode, equals('spanish'));
        expect(find.text('lang:spanish'), findsOneWidget);
        expect(received, contains('spanish'));

        final countAfterLoad = received.length;

        // Mutate settings while widget is mounted
        await UserSettingsController.instance.mutate((s) {
          s.primaryLanguageCode = 'latin';
        });
        await tester.pump();

        expect(received.length, equals(countAfterLoad + 1));
        expect(received.last, equals('latin'));
        expect(find.text('lang:latin'), findsOneWidget);

        // Unmount widget and verify listener was removed in dispose
        await tester.pumpWidget(const SizedBox.shrink());
        final countAfterDispose = received.length;

        await UserSettingsController.instance.mutate((s) {
          s.primaryLanguageCode = 'french';
        });
        await tester.pump();

        expect(received.length, equals(countAfterDispose));
      },
    );
  });

  group('SettingsScreen _TimedReminderTile & iOS system theme', () {
    testWidgets(
      'renders all three timed reminder tiles and updates time via time picker',
      (tester) async {
        PrayerDatabase.mockSettings = UserSettings(
          rosaryReminderEnabled: true,
          rosaryReminderHour: 20,
          rosaryReminderMinute: 0,
          morningPrayerReminderEnabled: true,
          morningPrayerReminderHour: 7,
          morningPrayerReminderMinute: 30,
          nightPrayerReminderEnabled: true,
          nightPrayerReminderHour: 21,
          nightPrayerReminderMinute: 15,
        );

        await tester.pumpWidget(
          buildTestableWidget(child: const SettingsScreen()),
        );
        await tester.pumpAndSettle();

        final rosaryTimeBtn = find.byKey(
          const Key('settings_rosary_time_button'),
        );
        await tester.scrollUntilVisible(rosaryTimeBtn, 300);
        expect(find.text('8:00 PM'), findsOneWidget);
        expect(
          find.text('Daily reminder at 8:00 PM for the day\'s mystery'),
          findsOneWidget,
        );

        final morningTimeBtn = find.byKey(
          const Key('settings_morning_prayer_time_button'),
        );
        await tester.scrollUntilVisible(morningTimeBtn, 300);
        expect(find.text('7:30 AM'), findsOneWidget);
        expect(find.text('Daily morning offering at 7:30 AM'), findsOneWidget);

        final nightTimeBtn = find.byKey(
          const Key('settings_night_prayer_time_button'),
        );
        await tester.scrollUntilVisible(nightTimeBtn, 300);
        expect(find.text('9:15 PM'), findsOneWidget);
        expect(
          find.text('Night prayer & examination of conscience at 9:15 PM'),
          findsOneWidget,
        );

        // Open Morning Prayer time picker and confirm (OK)
        await tester.tap(morningTimeBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(PrayerDatabase.mockSettings!.morningPrayerReminderHour, 7);
        expect(PrayerDatabase.mockSettings!.morningPrayerReminderMinute, 30);
      },
    );

    testWidgets('includes AppThemeMode.system option on TargetPlatform.iOS', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        PrayerDatabase.mockSettings = UserSettings(appThemeModeCode: 'system');

        await tester.pumpWidget(
          buildTestableWidget(child: const SettingsScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings_theme_dropdown')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('settings_theme_option_system')),
          findsWidgets,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('HomeScreen Drawer Bible Notes navigation closes active search', () {
    late BibleDatabase testDb;

    setUp(() async {
      testDb = BibleDatabase(NativeDatabase.memory());
      BibleDatabaseHelper.db = testDb;
      await testDb.ensurePopulated();
      await testDb.saveFavorite(
        FavoritePassagesCompanion.insert(
          bookNumber: 1,
          bookName: 'Genesis',
          chapter: 1,
          startVerse: 1,
          endVerse: 1,
          textPreview: 'In the beginning God created heaven, and earth.',
        ),
      );
      await testDb.saveComment(
        UserCommentsCompanion.insert(
          documentId: 'GEN',
          sectionIndex: 1,
          nodeId: '1_1_1',
          commentText: 'Note on Genesis 1:1',
          textPreview: const Value('In the beginning...'),
          createdAt: DateTime(2026, 7, 6),
        ),
      );
    });

    tearDown(() async {
      await testDb.close();
      BibleDatabaseHelper.db = null;
    });

    testWidgets(
      'jumping to a Bible favorite or comment from Drawer closes active prayer search',
      (tester) async {
        PrayerDatabase.mockPrayers = [
          Prayer.mock(
            id: 'our_father',
            defaultTitle: 'Our Father',
            translations: {
              PrayerLanguage.english: [
                PrayerTranslation.mock(
                  title: 'Our Father',
                  subtitle: 'Lord\'s Prayer',
                  text: 'Our Father, who art in heaven...',
                ),
              ],
            },
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: HomeScreen(initialDate: DateTime(2026, 7, 6)),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Go to Prayers tab and open search
        await tester.tap(find.text('Prayers').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);

        // 2. Open Drawer via ScaffoldState and navigate to Bible Notes -> select Favorite
        tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('drawer_bible_notes_tile')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('bible_annotation_favorite_1_1_1')),
        );
        await tester.pumpAndSettle();

        // Should now be on Bible tab with prayer search closed
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Twelve Stars'), findsOneWidget);

        // 3. Repeat for selecting a Comment while prayer search is active
        await tester.tap(find.text('Prayers').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);

        tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('drawer_bible_notes_tile')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Note on Genesis 1:1'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
        expect(find.text('Twelve Stars'), findsOneWidget);
      },
    );
  });
}
