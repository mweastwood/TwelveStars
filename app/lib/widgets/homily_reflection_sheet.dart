import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/homily_service.dart';

class HomilyReflectionSheet extends StatefulWidget {
  final String celebrationTitle;
  final List<LectionaryReading> readings;
  final List<HomilyReadingData>? preloadedReadingsData;

  const HomilyReflectionSheet({
    super.key,
    required this.celebrationTitle,
    required this.readings,
    this.preloadedReadingsData,
  });

  @override
  State<HomilyReflectionSheet> createState() => _HomilyReflectionSheetState();
}

class _HomilyReflectionSheetState extends State<HomilyReflectionSheet> {
  bool _isLoading = true;
  String? _reflection;
  String? _error;
  bool _isCopied = false;
  Timer? _copyResetTimer;
  AiCoreStatus _status = AiCoreStatus.unavailable;

  @override
  void initState() {
    super.initState();
    _checkStatusAndRun();
  }

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatusAndRun() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = LocalAgentHelper.instance;
      final status = await aiService.checkStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
      });

      if (status == AiCoreStatus.available) {
        await _runReflection();
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error initializing AI service: $e';
      });
    }
  }

  Future<void> _triggerDownload() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = LocalAgentHelper.instance;
      await aiService.triggerDownload();
      var status = await aiService.checkStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
      });
      if (status == AiCoreStatus.available) {
        await _runReflection();
        return;
      }

      // Poll status for up to 30 seconds
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        status = await aiService.checkStatus();
        if (!mounted) return;
        setState(() {
          _status = status;
        });
        if (status == AiCoreStatus.available) {
          await _runReflection();
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            'Model download taking longer than expected. Please wait or try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error downloading model: $e';
      });
    }
  }

  Future<void> _runReflection() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final readingsData =
          widget.preloadedReadingsData ??
          await HomilyService.fetchReadingsData(widget.readings);

      if (readingsData.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'No readings found to generate homily reflection.';
        });
        return;
      }

      final response = await HomilyService.generateReflection(readingsData);

      if (!mounted) return;
      if (response == null || response.trim().isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No reflection generated. Please try again.';
        });
      } else {
        setState(() {
          _reflection = response.trim();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error generating reflection: $e';
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_reflection == null) return;
    await Clipboard.setData(ClipboardData(text: _reflection!));
    if (!mounted) return;
    setState(() {
      _isCopied = true;
    });
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reflection copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {}
    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  String get _citationsSummary {
    if (widget.readings.isEmpty && widget.preloadedReadingsData != null) {
      return widget.preloadedReadingsData!.map((r) => r.citation).join(' • ');
    }
    return widget.readings.map((r) => r.citation).join(' • ');
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
                    : "Reflecting on today's readings locally...",
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
              'Failed to generate homily reflection',
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
              'The on-device Gemini Nano model needs to be downloaded before it can generate homily reflections.',
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
          if (_reflection != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: MarkdownBody(
                data: _reflection!,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  theme,
                ).copyWith(p: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: Icon(_isCopied ? Icons.check : Icons.copy, size: 18),
                  label: Text(_isCopied ? 'Copied' : 'Copy reflection'),
                ),
              ],
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text('No reflection generated.'),
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
                      'Homily Reflection',
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
              if (widget.celebrationTitle.isNotEmpty)
                Text(
                  widget.celebrationTitle,
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
                      if (_citationsSummary.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.celebrationTitle.isNotEmpty
                                    ? widget.celebrationTitle
                                    : 'Readings of the Day',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _citationsSummary,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                      ],
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
