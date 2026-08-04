import 'package:flutter/material.dart';

class ReaderTextOptionsSheet extends StatefulWidget {
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;

  const ReaderTextOptionsSheet({
    super.key,
    required this.fontSize,
    required this.onFontSizeChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required double fontSize,
    required ValueChanged<double> onFontSizeChanged,
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
            min: 12.0,
            max: 32.0,
            divisions: 20,
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
