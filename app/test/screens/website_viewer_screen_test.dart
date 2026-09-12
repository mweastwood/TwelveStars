import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/screens/website_viewer_screen.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../test_helper.dart';

class FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  bool canLaunchValue = true;
  bool launchValue = false;
  String? lastLaunchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => canLaunchValue;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return launchValue;
  }
}

class FakeWebViewPlatform extends WebViewPlatform {
  FakePlatformWebViewController? lastCreatedController;
  FakePlatformNavigationDelegate? lastCreatedNavigationDelegate;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = FakePlatformWebViewController(params);
    lastCreatedController = controller;
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    final delegate = FakePlatformNavigationDelegate(params);
    lastCreatedNavigationDelegate = delegate;
    return delegate;
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return FakePlatformWebViewWidget(params);
  }
}

class FakePlatformWebViewController extends PlatformWebViewController {
  FakePlatformWebViewController(super.params) : super.implementation();

  bool canGoBackValue = false;
  bool canGoForwardValue = false;
  int goBackCalls = 0;
  int goForwardCalls = 0;
  int reloadCalls = 0;
  Uri? loadedUri;
  PlatformNavigationDelegate? navigationDelegate;

  @override
  Future<bool> canGoBack() async => canGoBackValue;

  @override
  Future<bool> canGoForward() async => canGoForwardValue;

  @override
  Future<void> goBack() async {
    goBackCalls++;
  }

  @override
  Future<void> goForward() async {
    goForwardCalls++;
  }

  @override
  Future<void> reload() async {
    reloadCalls++;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadedUri = params.uri;
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    navigationDelegate = handler;
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
}

class FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  FakePlatformNavigationDelegate(super.params) : super.implementation();

  ProgressCallback? onProgress;
  PageEventCallback? onPageStarted;
  PageEventCallback? onPageFinished;
  WebResourceErrorCallback? onWebResourceError;
  NavigationRequestCallback? onNavigationRequest;

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    this.onProgress = onProgress;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    this.onPageStarted = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    this.onPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {
    this.onWebResourceError = onWebResourceError;
  }

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    this.onNavigationRequest = onNavigationRequest;
  }
}

class FakePlatformWebViewWidget extends PlatformWebViewWidget {
  FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('mock_web_view'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String> clipboardLog = [];
  late FakeWebViewPlatform fakePlatform;
  late FakeUrlLauncherPlatform fakeUrlLauncher;
  final originalPlatform = WebViewPlatform.instance;
  final originalUrlLauncher = UrlLauncherPlatform.instance;

  setUp(() {
    clipboardLog.clear();
    fakePlatform = FakeWebViewPlatform();
    WebViewPlatform.instance = fakePlatform;

    fakeUrlLauncher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeUrlLauncher;

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
    if (originalPlatform != null) {
      WebViewPlatform.instance = originalPlatform;
    }
    UrlLauncherPlatform.instance = originalUrlLauncher;
  });

  const testTitle = 'Catechism of the Catholic Church';
  const testUrl =
      'https://www.usccb.org/beliefs-and-teachings/what-we-believe/catechism/catechism-of-the-catholic-church';

  group('WebsiteViewerScreen', () {
    testWidgets(
      'renders app bar title, domain subtitle, leading exit, and navigation action icons',
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
          expect(find.byTooltip('Back to library'), findsOneWidget);
          expect(find.byTooltip('Back'), findsOneWidget);
          expect(find.byTooltip('Forward'), findsOneWidget);
          expect(find.byTooltip('Refresh'), findsOneWidget);
          expect(find.byTooltip('More options'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('leading back button directly pops the screen', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WebsiteViewerScreen(
                          title: testTitle,
                          url: testUrl,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Viewer'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Viewer'));
        await tester.pumpAndSettle();
        expect(find.byType(WebsiteViewerScreen), findsOneWidget);

        await tester.tap(find.byTooltip('Back to library'));
        await tester.pumpAndSettle();
        expect(find.byType(WebsiteViewerScreen), findsNothing);
        expect(find.text('Open Viewer'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

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
      'shows snackbar when external browser launch fails from fallback card',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await tester.pumpWidget(
            buildTestableWidget(
              child: const WebsiteViewerScreen(title: testTitle, url: testUrl),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.widgetWithText(FilledButton, 'Open in External Browser'),
          );
          await tester.pumpAndSettle();

          expect(find.text('Could not open external browser'), findsOneWidget);
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

    testWidgets(
      'exercises injected controller parameter and navigation actions',
      (tester) async {
        final mockParams = PlatformWebViewControllerCreationParams();
        final mockPlatformController = FakePlatformWebViewController(
          mockParams,
        );
        mockPlatformController.canGoBackValue = true;
        mockPlatformController.canGoForwardValue = false;
        final controller = WebViewController.fromPlatform(
          mockPlatformController,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: WebsiteViewerScreen(
              title: testTitle,
              url: testUrl,
              controller: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mock_web_view')), findsOneWidget);

        final backFinder = find.widgetWithIcon(
          IconButton,
          Icons.arrow_back_ios_new_rounded,
        );
        final backButton = tester.widget<IconButton>(backFinder);
        expect(backButton.onPressed, isNotNull);

        final forwardFinder = find.widgetWithIcon(
          IconButton,
          Icons.arrow_forward_ios_rounded,
        );
        final forwardButton = tester.widget<IconButton>(forwardFinder);
        expect(forwardButton.onPressed, isNull);

        await tester.tap(backFinder);
        await tester.pumpAndSettle();
        expect(mockPlatformController.goBackCalls, 1);
      },
    );

    testWidgets(
      'handles progress, subresource errors, main frame errors, and retry on supported platform',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          await tester.pumpWidget(
            buildTestableWidget(
              child: const WebsiteViewerScreen(title: testTitle, url: testUrl),
            ),
          );
          await tester.pump();

          final delegate = fakePlatform.lastCreatedNavigationDelegate;
          final controller = fakePlatform.lastCreatedController;
          expect(delegate, isNotNull);
          expect(controller, isNotNull);

          // Test progress indicator
          delegate!.onProgress!(45);
          await tester.pump();
          final progressFinder = find.byType(LinearProgressIndicator);
          expect(progressFinder, findsOneWidget);
          final indicator = tester.widget<LinearProgressIndicator>(
            progressFinder,
          );
          expect(indicator.value, closeTo(0.45, 0.001));

          // Subresource error should NOT trigger error view
          const subresourceError = WebResourceError(
            errorCode: 404,
            description: 'Favicon missing',
            isForMainFrame: false,
          );
          delegate.onWebResourceError!(subresourceError);
          await tester.pump();
          expect(find.text('Unable to Load Page'), findsNothing);

          // Cancelled request (-999) should NOT trigger error view
          const cancelledError = WebResourceError(
            errorCode: -999,
            description: 'Request cancelled',
            isForMainFrame: true,
          );
          delegate.onWebResourceError!(cancelledError);
          await tester.pump();
          expect(find.text('Unable to Load Page'), findsNothing);

          // Main frame error DOES trigger error view
          const mainFrameError = WebResourceError(
            errorCode: 500,
            description: 'Internal server error occurred',
            isForMainFrame: true,
          );
          delegate.onWebResourceError!(mainFrameError);
          await tester.pump();
          expect(find.text('Unable to Load Page'), findsOneWidget);
          expect(find.text('Internal server error occurred'), findsOneWidget);

          // Tapping Retry invokes reload() and clears error view
          await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
          await tester.pump();
          expect(controller!.reloadCalls, 1);
          expect(find.text('Unable to Load Page'), findsNothing);
          expect(find.byKey(const Key('mock_web_view')), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
