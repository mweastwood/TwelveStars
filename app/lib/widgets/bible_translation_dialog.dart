import 'package:flutter/material.dart';

enum BibleTranslationDialogMode { primary, compare }

class BibleTranslationDialog extends StatefulWidget {
  final BibleTranslationDialogMode mode;
  final String currentPrimary;
  final String currentCompare;

  const BibleTranslationDialog({
    super.key,
    required this.mode,
    required this.currentPrimary,
    required this.currentCompare,
  });

  @override
  State<BibleTranslationDialog> createState() => _BibleTranslationDialogState();
}

class _BibleTranslationDialogState extends State<BibleTranslationDialog> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.mode == BibleTranslationDialogMode.primary
        ? widget.currentPrimary
        : widget.currentCompare;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrimaryMode = widget.mode == BibleTranslationDialogMode.primary;

    return AlertDialog(
      title: Text(
        isPrimaryMode ? 'Primary Translation' : 'Comparison Translation',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPrimaryMode) ...[
                _buildTranslationOption(
                  title: 'Catholic Public Domain Version (CPDV)',
                  origin: 'Ronald L. Conte Jr. (2009)',
                  description:
                      'A contemporary, literal translation of the Clementine Latin Vulgate.',
                  usage:
                      'Clear modern reading, literal Vulgate comparison, and study.',
                  value: 'CPDV',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Douay-Rheims Bible (DRC)',
                  origin: 'Challoner Revision (1749–1752)',
                  description:
                      'A classic, traditional translation of the Latin Vulgate, highly faithful to the Latin text.',
                  usage:
                      'Majestic traditional language, personal devotions, and historical study.',
                  value: 'DRC',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Biblia de Jünemann (JUN)',
                  origin: 'Guillermo Jünemann (1928)',
                  description:
                      'La primera versión de la Biblia completa traducida en América Latina, con el AT traducido de la Septuaginta.',
                  usage:
                      'Estudio bíblico hispano, comparación con la Septuaginta y devoción.',
                  value: 'JUN',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Torres Amat (TAM)',
                  origin: 'Félix Torres Amat (1836)',
                  description:
                      'Una de las traducciones católicas al español más tradicionales e influyentes, basada en la Vulgata.',
                  usage:
                      'Lenguaje tradicional, devoción personal y comparación histórica.',
                  value: 'TAM',
                  theme: theme,
                ),
              ] else ...[
                _buildTranslationOption(
                  title: 'None (Single View)',
                  origin: '',
                  description:
                      'Displays only the primary translation in a single column layout.',
                  usage: '',
                  value: 'none',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Catholic Public Domain Version (CPDV)',
                  origin: 'Ronald L. Conte Jr. (2009)',
                  description:
                      'A contemporary, literal translation of the Clementine Latin Vulgate.',
                  usage:
                      'Clear modern reading, literal Vulgate comparison, and study.',
                  value: 'CPDV',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Douay-Rheims Bible (DRC)',
                  origin: 'Challoner Revision (1749–1752)',
                  description:
                      'A classic, traditional translation of the Latin Vulgate, highly faithful to the Latin text.',
                  usage:
                      'Majestic traditional language, personal devotions, and historical study.',
                  value: 'DRC',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Biblia de Jünemann (JUN)',
                  origin: 'Guillermo Jünemann (1928)',
                  description:
                      'La primera versión de la Biblia completa traducida en América Latina, con el AT traducido de la Septuaginta.',
                  usage:
                      'Estudio bíblico hispano, comparación con la Septuaginta y devoción.',
                  value: 'JUN',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildTranslationOption(
                  title: 'Torres Amat (TAM)',
                  origin: 'Félix Torres Amat (1836)',
                  description:
                      'Una de las traducciones católicas al español más tradicionales e influyentes, basada en la Vulgata.',
                  usage:
                      'Lenguaje tradicional, devoción personal y comparación histórica.',
                  value: 'TAM',
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedValue);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildTranslationOption({
    required String title,
    required String origin,
    required String description,
    required String usage,
    required String value,
    required ThemeData theme,
  }) {
    final isSelected = _selectedValue == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedValue = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (origin.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Origin: $origin',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (usage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Best for: $usage',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
