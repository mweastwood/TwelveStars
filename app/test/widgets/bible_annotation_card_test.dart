import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/screens/bible_notes_screen.dart';
import 'package:twelve_stars/widgets/bible_annotation_card.dart';

import '../test_helper.dart';

void main() {
  final favoriteItem = BibleAnnotationItem(
    bookNumber: 1,
    bookName: 'Genesis',
    chapter: 1,
    startVerse: 1,
    endVerse: 3,
    textPreview: 'In the beginning God created heaven, and earth.',
    type: BibleAnnotationType.favorite,
    favorite: FavoritePassage(
      id: 1,
      bookNumber: 1,
      bookName: 'Genesis',
      chapter: 1,
      startVerse: 1,
      endVerse: 3,
      textPreview: 'In the beginning God created heaven, and earth.',
      createdAt: DateTime(2026, 1, 1),
    ),
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  final commentItem = BibleAnnotationItem(
    bookNumber: 21,
    bookName: 'Psalms',
    chapter: 23,
    startVerse: 1,
    endVerse: 1,
    textPreview: 'The Lord is my shepherd; I shall not want.',
    type: BibleAnnotationType.comment,
    comment: UserComment(
      id: 101,
      documentId: 'psa',
      sectionIndex: 23,
      nodeId: 'psa_23_1',
      commentText: 'The Lord is my shepherd: powerful psalm of divine trust.',
      textPreview: 'The Lord is my shepherd; I shall not want.',
      createdAt: DateTime(2026, 1, 10),
    ),
    createdAt: DateTime(2026, 1, 10),
  );

  group('BibleAnnotationCard Widget Tests', () {
    testWidgets('renders favorite annotation card with badge, scripture preview, and key', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleAnnotationCard(item: favoriteItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bible_annotation_favorite_1_1_1')), findsOneWidget);
      expect(find.text('Genesis 1:1-3'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('"In the beginning God created heaven, and earth."'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      // No edit button for favorite
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.text('Personal Reflection'), findsNothing);
    });

    testWidgets('renders note annotation card with badge, scripture preview, and personal reflection', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleAnnotationCard(item: commentItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bible_annotation_comment_21_23_1')), findsOneWidget);
      expect(find.text('Psalms 23:1'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.byIcon(Icons.comment_rounded), findsOneWidget);
      expect(find.text('"The Lord is my shepherd; I shall not want."'), findsOneWidget);
      expect(find.text('Personal Reflection'), findsOneWidget);
      expect(find.text('The Lord is my shepherd: powerful psalm of divine trust.'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('invokes onOpen when card body is tapped', (tester) async {
      bool opened = false;
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleAnnotationCard(
              item: favoriteItem,
              onOpen: () => opened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bible_annotation_favorite_1_1_1')));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });

    testWidgets('invokes onOpen when Open button is pressed', (tester) async {
      bool opened = false;
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleAnnotationCard(
              item: favoriteItem,
              onOpen: () => opened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Open'));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });

    testWidgets('invokes onCopy when Copy button is pressed', (tester) async {
      bool copied = false;
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleAnnotationCard(
              item: favoriteItem,
              onCopy: () => copied = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Copy'));
      await tester.pumpAndSettle();

      expect(copied, isTrue);
    });

    testWidgets('invokes onEdit when Edit note button is pressed on comment', (tester) async {
      bool edited = false;
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleAnnotationCard(
              item: commentItem,
              onEdit: () => edited = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit note'));
      await tester.pumpAndSettle();

      expect(edited, isTrue);
    });

    testWidgets('invokes onDelete when Delete button is pressed', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            body: BibleAnnotationCard(
              item: favoriteItem,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
