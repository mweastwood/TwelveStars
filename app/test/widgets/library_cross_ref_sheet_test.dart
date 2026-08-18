import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/reader/library_cross_ref_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LibraryHelper.clearCache();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final String key = utf8.decode(message!.buffer.asUint8List());
          final dummyData = {
            'bookId': key,
            'title': 'Book for $key',
            'subtitle': '',
            'author': '',
            'toc': [],
            'sections': [
              {
                'id': 'sec_1',
                'title': 'Lesson 1',
                'subtitle': '',
                'content': [
                  {
                    'type': 'qa',
                    'questionNumber': 1,
                    'question': 'Who made the world?',
                    'answer': 'God made the world.',
                    'explanation': 'God created all things out of nothing.',
                  },
                ],
              },
            ],
          };
          final jsonStr = jsonEncode(dummyData);
          return ByteData.view(Uint8List.fromList(utf8.encode(jsonStr)).buffer);
        });
  });

  tearDown(() {
    LibraryHelper.clearCache();
  });

  group('LibraryCrossRefSheet Tests', () {
    testWidgets('renders Baltimore Catechism cross-reference sheet', (
      WidgetTester tester,
    ) async {
      final testBookItem = LibraryBookItem(
        id: 'baltimore_catechism',
        title: 'Baltimore Catechism',
        subtitle: 'Official Catechism for Plenary Councils',
        category: 'Catechisms',
        author: 'Third Plenary Council of Baltimore',
        description: 'A classic summary of Catholic doctrine.',
        defaultAssetPath: 'assets/catechism/json/baltimore_1.json',
        volumes: [
          const BaltimoreVolume(
            volumeKey: 'baltimore_2',
            name: 'Baltimore Catechism No. 2',
            shortName: 'No. 2',
            description: 'Confirmation edition',
            assetPath: 'assets/catechism/json/baltimore_2.json',
          ),
          const BaltimoreVolume(
            volumeKey: 'baltimore_4',
            name: 'Baltimore Catechism No. 4',
            shortName: 'No. 4',
            description: 'Fr. Kinkead explanation',
            assetPath: 'assets/catechism/json/baltimore_4.json',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () => showBaltimoreCrossRefSheet(
                      context: context,
                      questionNumber: 1,
                      bookItem: testBookItem,
                      onSwitchVolume: (_, _) {},
                    ),
                    child: const Text('Open Cross Ref'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Cross Ref'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Cross-Reference: Master Question #1'), findsOneWidget);
      expect(
        find.text('Baltimore Catechism No. 2 (Confirmation Edition)'),
        findsOneWidget,
      );
      expect(
        find.text('Baltimore Catechism No. 4 (Fr. Kinkead\'s Explanation)'),
        findsOneWidget,
      );
    });
  });
}
