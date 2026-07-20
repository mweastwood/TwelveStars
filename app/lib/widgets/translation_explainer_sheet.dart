import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';

class TranslationExplainerSheet extends StatefulWidget {
  final String originalPhrase;
  final String translatedPhrase;
  final String originalContext;
  final String translatedContext;
  final String originalLang;
  final String translatedLang;

  const TranslationExplainerSheet({
    super.key,
    required this.originalPhrase,
    required this.translatedPhrase,
    required this.originalContext,
    required this.translatedContext,
    required this.originalLang,
    required this.translatedLang,
  });

  @override
  State<TranslationExplainerSheet> createState() =>
      _TranslationExplainerSheetState();
}

class _TranslationExplainerSheetState extends State<TranslationExplainerSheet> {
  bool _isLoading = true;
  String? _explanation;
  String? _error;
  AiCoreStatus _status = AiCoreStatus.unavailable;

  @override
  void initState() {
    super.initState();
    _checkStatusAndRun();
  }

  Future<void> _checkStatusAndRun() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = LocalAgentHelper.instance;
      final status = await aiService.checkStatus();
      setState(() {
        _status = status;
      });

      if (status == AiCoreStatus.available) {
        await _runExplanation();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error initializing AI service: $e';
      });
    }
  }

  Future<void> _triggerDownload() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = LocalAgentHelper.instance;
      await aiService.triggerDownload();
      // Poll status for a bit
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final status = await aiService.checkStatus();
        setState(() {
          _status = status;
        });
        if (status == AiCoreStatus.available) {
          await _runExplanation();
          return;
        }
      }
      setState(() {
        _isLoading = false;
        _error =
            'Model download taking longer than expected. Please wait or try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error downloading model: $e';
      });
    }
  }

  Future<void> _runExplanation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prompt =
          '''
Original phrase:
${widget.originalPhrase}

Translated phrase:
${widget.translatedPhrase}

Original phrase in context:
${widget.originalContext}

Translated phrase in context:
${widget.translatedContext}

Define each translated word in the selected phrase and explain how the translated phrase carries the meaning of the original phrase. Focus your explanation only on the selected phrase in context, not the rest of the prayer.
''';

      final response = await LocalAgentHelper.instance
          .generateContentWithContinuation(
            prompt: prompt,
            maxOutputTokens: 256,
            autoContinueLimit: 3,
          );

      setState(() {
        _explanation = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error generating explanation: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (_isLoading) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _status == AiCoreStatus.downloading
                    ? 'Downloading Gemini Nano model weights (~30MB)...'
                    : 'Running AI analysis locally...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    } else if (_error != null) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to generate explanation',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkStatusAndRun,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_status == AiCoreStatus.unavailable) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.secondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('AI Core Unavailable', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'On-device AI features (Gemini Nano) are not supported on this device. '
              'Please ensure you are on a compatible Pixel device with AICore enabled.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (_status == AiCoreStatus.downloadable) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.download_for_offline_outlined,
              color: theme.colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('Download AI Model', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'The on-device Gemini Nano model needs to be downloaded before it can explain translations.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _triggerDownload,
              icon: const Icon(Icons.download),
              label: const Text('Download now'),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_explanation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
              child: MarkdownBody(
                data: _explanation!,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  theme,
                ).copyWith(p: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text('No explanation generated.'),
            ),
        ],
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Translation Explainer',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                '${widget.originalLang} ➜ ${widget.translatedLang}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.originalLang}:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              widget.originalPhrase,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.translatedLang}:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            Text(
                              widget.translatedPhrase,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      content,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
