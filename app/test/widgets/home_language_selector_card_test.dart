import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/home_language_selector_card.dart';

import '../test_helper.dart';

void main() {
  group('HomeLanguageSelectorCard Widget', () {
    testWidgets(
      'renders dual language mode with correct labels, flags, and names',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: HomeLanguageSelectorCard(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
                onPrimaryChanged: (_) {},
                onSecondaryChanged: (_) {},
                onSwap: () {},
                onClearSecondary: () {},
              ),
            ),
          ),
        );

        // Verify card existence
        expect(
          find.byKey(const ValueKey('home_language_selector_card')),
          findsOneWidget,
        );

        // Verify header labels
        expect(find.text('Primary Language'), findsOneWidget);
        expect(find.text('Secondary Language'), findsOneWidget);

        // Verify primary language flag and name
        expect(find.text('🇺🇸'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);

        // Verify comparison language flag and name
        expect(find.text('🇻🇦'), findsOneWidget);
        expect(find.text('Latina'), findsOneWidget);

        // Verify swap button is enabled and has tooltip
        expect(find.byTooltip('Swap Languages'), findsOneWidget);
        final swapButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(swapButton.onPressed, isNotNull);

        // Verify clear secondary button is visible
        final visibility = tester.widget<Visibility>(
          find.ancestor(
            of: find.byKey(const ValueKey('clear_secondary_language')),
            matching: find.byType(Visibility),
          ),
        );
        expect(visibility.visible, isTrue);
      },
    );

    testWidgets(
      'renders null secondary language with "None", disabled swap, and hidden clear',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: HomeLanguageSelectorCard(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: null,
                onPrimaryChanged: (_) {},
                onSecondaryChanged: (_) {},
                onSwap: () {},
                onClearSecondary: () {},
              ),
            ),
          ),
        );

        // Verify primary language
        expect(find.text('Primary Language'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);

        // Verify secondary language shows 'None' with '🚫'
        expect(find.text('Secondary Language'), findsOneWidget);
        expect(find.text('🚫'), findsOneWidget);
        expect(find.text('None'), findsOneWidget);

        // Verify swap button is disabled (onPressed is null)
        expect(find.byTooltip('Swap Languages'), findsOneWidget);
        final swapButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(swapButton.onPressed, isNull);

        // Verify clear secondary button is hidden
        final visibility = tester.widget<Visibility>(
          find.ancestor(
            of: find.byKey(const ValueKey('clear_secondary_language')),
            matching: find.byType(Visibility),
          ),
        );
        expect(visibility.visible, isFalse);
      },
    );

    testWidgets(
      'invokes onPrimaryChanged when selecting a new primary language',
      (tester) async {
        PrayerLanguage? selectedLanguage;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: HomeLanguageSelectorCard(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
                onPrimaryChanged: (val) => selectedLanguage = val,
                onSecondaryChanged: (_) {},
                onSwap: () {},
                onClearSecondary: () {},
              ),
            ),
          ),
        );

        // Open primary dropdown
        final primaryDropdown = find.byType(DropdownButton<PrayerLanguage>);
        await tester.tap(primaryDropdown);
        await tester.pumpAndSettle();

        // Tap Spanish option
        final spanishOption = find.text('Español').last;
        await tester.tap(spanishOption);
        await tester.pumpAndSettle();

        expect(selectedLanguage, equals(PrayerLanguage.spanish));
      },
    );

    testWidgets(
      'invokes onSecondaryChanged when selecting a comparison language or None',
      (tester) async {
        PrayerLanguage? selectedLanguage;
        bool callbackFired = false;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: HomeLanguageSelectorCard(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
                onPrimaryChanged: (_) {},
                onSecondaryChanged: (val) {
                  selectedLanguage = val;
                  callbackFired = true;
                },
                onSwap: () {},
                onClearSecondary: () {},
              ),
            ),
          ),
        );

        // Open secondary dropdown
        final secondaryDropdown = find.byType(DropdownButton<PrayerLanguage?>);
        await tester.tap(secondaryDropdown);
        await tester.pumpAndSettle();

        // Select 'None' option
        final noneOption = find.text('None').last;
        await tester.tap(noneOption);
        await tester.pumpAndSettle();

        expect(callbackFired, isTrue);
        expect(selectedLanguage, isNull);

        // Test selecting another valid language
        callbackFired = false;
        await tester.tap(secondaryDropdown);
        await tester.pumpAndSettle();

        final italianOption = find.text('Italiano').last;
        await tester.tap(italianOption);
        await tester.pumpAndSettle();

        expect(callbackFired, isTrue);
        expect(selectedLanguage, equals(PrayerLanguage.italian));
      },
    );

    testWidgets(
      'invokes onSwap when swap button is tapped and compareLanguage is set',
      (tester) async {
        var swapCallCount = 0;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: HomeLanguageSelectorCard(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
                onPrimaryChanged: (_) {},
                onSecondaryChanged: (_) {},
                onSwap: () => swapCallCount++,
                onClearSecondary: () {},
              ),
            ),
          ),
        );

        // Tap swap button
        await tester.tap(find.widgetWithIcon(IconButton, Icons.swap_horiz));
        await tester.pumpAndSettle();

        expect(swapCallCount, equals(1));
      },
    );

    testWidgets(
      'does not invoke onSwap when compareLanguage is null (disabled)',
      (tester) async {
        var swapCallCount = 0;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: HomeLanguageSelectorCard(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: null,
                onPrimaryChanged: (_) {},
                onSecondaryChanged: (_) {},
                onSwap: () => swapCallCount++,
                onClearSecondary: () {},
              ),
            ),
          ),
        );

        // Attempt to tap swap button
        await tester.tap(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(swapCallCount, equals(0));
      },
    );

    testWidgets(
      'invokes onClearSecondary when clear secondary button is tapped',
      (tester) async {
        var clearCallCount = 0;

        await tester.pumpWidget(
          buildTestableWidget(
            child: Scaffold(
              body: HomeLanguageSelectorCard(
                primaryLanguage: PrayerLanguage.english,
                compareLanguage: PrayerLanguage.latin,
                onPrimaryChanged: (_) {},
                onSecondaryChanged: (_) {},
                onSwap: () {},
                onClearSecondary: () => clearCallCount++,
              ),
            ),
          ),
        );

        // Tap clear secondary button
        await tester.tap(
          find.byKey(const ValueKey('clear_secondary_language')),
        );
        await tester.pumpAndSettle();

        expect(clearCallCount, equals(1));
      },
    );
  });
}
