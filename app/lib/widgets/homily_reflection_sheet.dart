import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/homily_service.dart';
import 'package:twelve_stars/widgets/ai_generation_sheet.dart';

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
  bool _isCopied = false;
  Timer? _copyResetTimer;

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    super.dispose();
  }

  Future<String?> _generateReflection() async {
    final readingsData =
        widget.preloadedReadingsData ??
        await HomilyService.fetchReadingsData(widget.readings);

    if (readingsData.isEmpty) {
      throw const AiGenerationUserMessageException(
        'No readings found to generate homily reflection.',
      );
    }

    final response = await HomilyService.generateReflection(readingsData);
    if (response == null || response.trim().isEmpty) {
      throw const AiGenerationUserMessageException(
        'No reflection generated. Please try again.',
      );
    }
    return response.trim();
  }

  Future<void> _copyToClipboard(String reflection) async {
    await Clipboard.setData(ClipboardData(text: reflection));
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
    final summary = _citationsSummary;

    return AiGenerationSheet(
      title: 'Homily Reflection',
      subtitle: widget.celebrationTitle.isNotEmpty
          ? widget.celebrationTitle
          : null,
      loadingMessage: "Reflecting on today's readings locally...",
      errorTitle: 'Failed to generate homily reflection',
      downloadDescription:
          'The on-device Gemini Nano model needs to be downloaded before it can generate homily reflections.',
      emptyResultMessage: 'No reflection generated.',
      generationErrorPrefix: 'Error generating reflection',
      onGenerate: _generateReflection,
      resultBottomPadding: 16.0,
      contextCard: summary.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
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
                    summary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : null,
      resultFooterBuilder: (context, reflection) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => _copyToClipboard(reflection),
            icon: Icon(_isCopied ? Icons.check : Icons.copy, size: 18),
            label: Text(_isCopied ? 'Copied' : 'Copy reflection'),
          ),
        ],
      ),
    );
  }
}
