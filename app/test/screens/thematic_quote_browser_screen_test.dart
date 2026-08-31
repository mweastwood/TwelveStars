import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThematicQuoteBrowserScreen Tests', () {
    testWidgets('renders theme title and actions in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThematicQuoteBrowserScreen(
            initialThemeId: 'sacraments.eucharist',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ThematicQuoteBrowserScreen), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    });

    test(
      'ThematicHelper taxonomy defines all 35 themes and 7 category groups',
      () {
        expect(ThematicHelper.categoryGroups.length, 7);
        expect(ThematicHelper.allThemes.length, 35);
        expect(
          ThematicHelper.getThemeTitle('sacraments.eucharist'),
          'The Most Holy Eucharist & The Mass',
        );
        expect(
          ThematicHelper.getThemeTitle('sacraments.baptism'),
          'Holy Baptism & Regeneration',
        );
        expect(
          ThematicHelper.getThemeTitle('sacraments.confirmation'),
          'Confirmation & Holy Chrism',
        );
      },
    );
  });
}
