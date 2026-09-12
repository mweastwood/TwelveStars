import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebsiteViewerScreen extends StatefulWidget {
  final String title;
  final String url;
  final WebViewController? controller;

  const WebsiteViewerScreen({
    super.key,
    required this.title,
    required this.url,
    this.controller,
  });

  @override
  State<WebsiteViewerScreen> createState() => _WebsiteViewerScreenState();
}

class _WebsiteViewerScreenState extends State<WebsiteViewerScreen> {
  WebViewController? _controller;
  bool _isSupported = false;
  int _loadingProgress = 0;
  bool _hasError = false;
  String? _errorMessage;
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _initController();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller;
      _isSupported = true;
      _updateNavState();
      return;
    }

    if (_checkPlatformSupported()) {
      try {
        final controller = WebViewController();
        controller.setJavaScriptMode(JavaScriptMode.unrestricted);
        controller.setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _currentUrl = url;
                  _hasError = false;
                  _errorMessage = null;
                });
                _updateNavState();
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _currentUrl = url;
                  _loadingProgress = 100;
                });
                _updateNavState();
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (error.errorCode == -999) return;
              if (!(error.isForMainFrame ?? true)) return;
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        );
        controller.loadRequest(Uri.parse(widget.url));
        _controller = controller;
        _isSupported = true;
      } catch (_) {
        _isSupported = false;
        _controller = null;
      }
    } else {
      _isSupported = false;
      _controller = null;
    }
  }

  bool _checkPlatformSupported() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> _updateNavState() async {
    if (_controller == null) return;
    try {
      final canGoBack = await _controller!.canGoBack();
      final canGoForward = await _controller!.canGoForward();
      if (mounted) {
        setState(() {
          _canGoBack = canGoBack;
          _canGoForward = canGoForward;
        });
      }
    } catch (_) {}
  }

  String get _domain {
    try {
      final uri = Uri.parse(_currentUrl.isNotEmpty ? _currentUrl : widget.url);
      final host = uri.host;
      if (host.startsWith('www.')) {
        return host.substring(4);
      }
      return host.isNotEmpty ? host : widget.url;
    } catch (_) {
      return widget.url;
    }
  }

  Future<void> _openInExternalBrowser() async {
    bool launched = false;
    try {
      final activeUrl = _currentUrl.isNotEmpty ? _currentUrl : widget.url;
      final uri = Uri.tryParse(activeUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open external browser'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyUrl() async {
    final activeUrl = _currentUrl.isNotEmpty ? _currentUrl : widget.url;
    await Clipboard.setData(ClipboardData(text: activeUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_controller != null && await _controller!.canGoBack()) {
          await _controller!.goBack();
          _updateNavState();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to library',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _domain,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              tooltip: 'Back',
              onPressed: _canGoBack
                  ? () async {
                      await _controller?.goBack();
                      _updateNavState();
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              tooltip: 'Forward',
              onPressed: _canGoForward
                  ? () async {
                      await _controller?.goForward();
                      _updateNavState();
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _controller != null
                  ? () {
                      setState(() {
                        _hasError = false;
                        _errorMessage = null;
                      });
                      _controller?.reload();
                    }
                  : null,
            ),
            PopupMenuButton<String>(
              tooltip: 'More options',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'open_external') {
                  _openInExternalBrowser();
                } else if (value == 'copy_url') {
                  _copyUrl();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'open_external',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_browser_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Open in External Browser'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_url',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Copy URL'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3.0),
            child: (_isSupported && _loadingProgress < 100)
                ? LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    minHeight: 3.0,
                  )
                : const SizedBox(height: 3.0),
          ),
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!_isSupported || _controller == null) {
      return _buildDesktopFallback(context);
    }
    if (_hasError) {
      return _buildErrorView(context);
    }
    return WebViewWidget(controller: _controller!);
  }

  Widget _buildDesktopFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _domain,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Embedded web browsing is not available on this platform. You can read this work directly in your web browser.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open in External Browser'),
                  onPressed: _openInExternalBrowser,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Link'),
                  onPressed: _copyUrl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 40,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Unable to Load Page',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ??
                      'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = null;
                        });
                        _controller?.reload();
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('Open in External Browser'),
                      onPressed: _openInExternalBrowser,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
