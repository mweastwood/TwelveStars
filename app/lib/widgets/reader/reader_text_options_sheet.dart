import 'package:flutter/material.dart';

class ReaderTextOptionsSheet extends StatefulWidget {
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final double minFontSize;
  final double maxFontSize;
  final int? divisions;

  const ReaderTextOptionsSheet({
    super.key,
    required this.fontSize,
    required this.onFontSizeChanged,
    this.minFontSize = 12.0,
    this.maxFontSize = 32.0,
    this.divisions = 20,
  });

  static Future<void> show(
    BuildContext context, {
    required double fontSize,
    required ValueChanged<double> onFontSizeChanged,
    double minFontSize = 12.0,
    double maxFontSize = 32.0,
    int? divisions = 20,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ReaderTextOptionsSheet(
          fontSize: fontSize,
          onFontSizeChanged: onFontSizeChanged,
          minFontSize: minFontSize,
          maxFontSize: maxFontSize,
          divisions: divisions,
        );
      },
    );
  }

  @override
  State<ReaderTextOptionsSheet> createState() => _ReaderTextOptionsSheetState();
}

class _ReaderTextOptionsSheetState extends State<ReaderTextOptionsSheet> {
  late double _currentFontSize;

  @override
  void initState() {
    super.initState();
    _currentFontSize = widget.fontSize;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reading Options',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.format_size, size: 16),
              const SizedBox(width: 8),
              Text(
                'Font Size: ${_currentFontSize.round()} pt',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          Slider(
            value: _currentFontSize,
            min: widget.minFontSize,
            max: widget.maxFontSize,
            divisions: widget.divisions,
            label: '${_currentFontSize.round()}',
            onChanged: (val) {
              setState(() {
                _currentFontSize = val;
              });
              widget.onFontSizeChanged(val);
            },
          ),
        ],
      ),
    );
  }
}
