import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/screens/website_viewer_screen.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String> clipboardLog = [];

  setUp(() {
    clipboardLog.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>?;
            final text = args?['text'] as String?;
            if (text != null) clipboardLog.add(text);
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return {'text': clipboardLog.isNotEmpty ? clipboardLog.last : ''};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  const testTitle = 'Catechism of the Catholic Church';
  const testUrl =
      'https://www.usccb.org/beliefs-and-teachings/what-we-believe/catechism/catechism-of-the-catholic-church';

  group('WebsiteViewerScreen', () {
    testWidgets(
      'renders app bar title, domain subtitle, and navigation action icons',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await tester.pumpWidget(
            buildTestableWidget(
              child: const WebsiteViewerScreen(title: testTitle, url: testUrl),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text(testTitle),
            findsNWidgets(2),
          ); // AppBar + Fallback card
          expect(
            find.text('usccb.org'),
            findsNWidgets(2),
          ); // AppBar + Fallback card
          expect(find.byTooltip('Back'), findsOneWidget);
          expect(find.byTooltip('Forward'), findsOneWidget);
          expect(find.byTooltip('Refresh'), findsOneWidget);
          expect(find.byTooltip('More options'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('renders desktop fallback card on non-webview platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const WebsiteViewerScreen(title: testTitle, url: testUrl),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Embedded web browsing is not available on this platform. You can read this work directly in your web browser.',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FilledButton, 'Open in External Browser'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Copy Link'),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'copies url to clipboard from fallback card button and shows snackbar',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await tester.pumpWidget(
            buildTestableWidget(
              child: const WebsiteViewerScreen(title: testTitle, url: testUrl),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(OutlinedButton, 'Copy Link'));
          await tester.pumpAndSettle();

          expect(clipboardLog, contains(testUrl));
          expect(find.text('URL copied to clipboard'), findsOneWidget);
          final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
          expect(clipboardData?.text, testUrl);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'more options popup menu displays Open in External Browser and Copy URL',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await tester.pumpWidget(
            buildTestableWidget(
              child: const WebsiteViewerScreen(title: testTitle, url: testUrl),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip('More options'));
          await tester.pumpAndSettle();

          expect(
            find.text('Open in External Browser'),
            findsNWidgets(2),
          ); // 1 on card, 1 in menu
          expect(find.text('Copy URL'), findsOneWidget);

          await tester.tap(find.text('Copy URL'));
          await tester.pumpAndSettle();

          expect(clipboardLog, contains(testUrl));
          expect(find.text('URL copied to clipboard'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'gracefully falls back when platform does not have webview support',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await tester.pumpWidget(
            buildTestableWidget(
              child: const WebsiteViewerScreen(title: testTitle, url: testUrl),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text(
              'Embedded web browsing is not available on this platform. You can read this work directly in your web browser.',
            ),
            findsOneWidget,
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
