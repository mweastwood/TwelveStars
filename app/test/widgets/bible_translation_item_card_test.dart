import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';
import 'package:twelve_stars/widgets/bible/bible_approval_badge.dart';
import 'package:twelve_stars/widgets/bible/bible_translation_item_card.dart';

void main() {
  group('BibleApprovalBadge', () {
    testWidgets('renders Imprimatur badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BibleApprovalBadge(status: BibleApprovalStatus.imprimatur),
          ),
        ),
      );

      expect(find.text('✓ Imprimatur'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders No Imprimatur badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BibleApprovalBadge(status: BibleApprovalStatus.noImprimatur),
          ),
        ),
      );

      expect(find.text('✗ No Imprimatur'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders Canonical Source badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BibleApprovalBadge(
              status: BibleApprovalStatus.canonicalSourceText,
            ),
          ),
        ),
      );

      expect(find.text('🏛️ Canonical Source'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });
  });

  group('BibleTranslationItemCard', () {
    testWidgets(
      'renders Primary badge, metadata, origin, usage, and fires onTap',
      (tester) async {
        final drc = BibleTranslationInfo.getByCode('DRC');
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleTranslationItemCard(
                item: drc,
                isPrimary: true,
                isCompare: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('translation_item_DRC')),
          findsOneWidget,
        );
        expect(find.text(drc.name), findsOneWidget);
        expect(find.text('✓ Primary'), findsOneWidget);
        expect(find.text('✓ Secondary'), findsNothing);
        expect(find.text('✓ Imprimatur'), findsOneWidget);
        expect(
          find.text('🏛️ Origin: ${drc.originDescription}'),
          findsOneWidget,
        );
        expect(find.text('✝️ Usage: ${drc.churchUsage}'), findsOneWidget);

        await tester.tap(find.byType(BibleTranslationItemCard));
        expect(tapped, isTrue);
      },
    );

    testWidgets('renders Secondary badge when isCompare is true', (
      tester,
    ) async {
      final vul = BibleTranslationInfo.getByCode('VUL');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleTranslationItemCard(
              item: vul,
              isPrimary: false,
              isCompare: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('translation_item_VUL')),
        findsOneWidget,
      );
      expect(find.text('✓ Secondary'), findsOneWidget);
      expect(find.text('✓ Primary'), findsNothing);
    });

    testWidgets(
      'renders OT Only badge and incompatible book warning for New Testament book',
      (tester) async {
        final lxx = BibleTranslationInfo.getByCode('LXX');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleTranslationItemCard(
                item: lxx,
                isPrimary: false,
                isCompare: false,
                currentBookNumber: 49,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('OT Only'), findsOneWidget);
        expect(
          find.text('Old Testament only. Not available for this book.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'omits incompatible book warning for Old Testament book on OT-only translation',
      (tester) async {
        final lxx = BibleTranslationInfo.getByCode('LXX');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleTranslationItemCard(
                item: lxx,
                isPrimary: false,
                isCompare: false,
                currentBookNumber: 1,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('OT Only'), findsOneWidget);
        expect(
          find.text('Old Testament only. Not available for this book.'),
          findsNothing,
        );
      },
    );
  });
}
