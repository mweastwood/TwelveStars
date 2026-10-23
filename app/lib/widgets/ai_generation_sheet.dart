import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';

/// Exception thrown by [AiGenerationSheet.onGenerate] when a user-facing error
/// message should be displayed directly without a technical prefix.
class AiGenerationUserMessageException implements Exception {
  final String message;

  const AiGenerationUserMessageException(this.message);

  @override
  String toString() => message;
}

/// Shared bottom-sheet scaffold and lifecycle controller for on-device Gemini
/// Nano AI features (status check, model download polling, error retry, and
/// Markdown result rendering).
class AiGenerationSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? contextCard;
  final String loadingMessage;
  final String errorTitle;
  final String downloadDescription;
  final String emptyResultMessage;
  final String generationErrorPrefix;
  final Future<String?> Function() onGenerate;
  final double resultBottomPadding;
  final Widget Function(BuildContext context, String resultText)?
  resultFooterBuilder;

  const AiGenerationSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.contextCard,
    required this.loadingMessage,
    required this.errorTitle,
    required this.downloadDescription,
    required this.emptyResultMessage,
    required this.generationErrorPrefix,
    required this.onGenerate,
    this.resultBottomPadding = 20.0,
    this.resultFooterBuilder,
  });

  @override
  State<AiGenerationSheet> createState() => _AiGenerationSheetState();
}

class _AiGenerationSheetState extends State<AiGenerationSheet> {
  bool _isLoading = true;
  String? _resultText;
  String? _error;
  AiCoreStatus _status = AiCoreStatus.unavailable;

  @override
  void initState() {
    super.initState();
    _checkStatusAndRun();
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
        await _runGeneration();
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
        await _runGeneration();
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
          await _runGeneration();
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

  Future<void> _runGeneration() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.onGenerate();
      if (!mounted) return;
      setState(() {
        _resultText = response;
        _isLoading = false;
      });
    } on AiGenerationUserMessageException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '${widget.generationErrorPrefix}: $e';
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
                    : widget.loadingMessage,
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
              widget.errorTitle,
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
            Text(widget.downloadDescription, textAlign: TextAlign.center),
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
          if (_resultText != null) ...[
            Padding(
              padding: EdgeInsets.only(
                top: 8.0,
                bottom: widget.resultBottomPadding,
              ),
              child: MarkdownBody(
                data: _resultText!,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  theme,
                ).copyWith(p: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
              ),
            ),
            if (widget.resultFooterBuilder != null)
              widget.resultFooterBuilder!(context, _resultText!),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(widget.emptyResultMessage),
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
                      widget.title,
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
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                Text(
                  widget.subtitle!,
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
                      if (widget.contextCard != null) ...[
                        widget.contextCard!,
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
