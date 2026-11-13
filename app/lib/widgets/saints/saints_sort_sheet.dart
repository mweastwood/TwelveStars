import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/saints/saint_ui_extensions.dart';

/// Modal bottom sheet allowing users to select a [SaintSortOption].
class SaintsSortSheet extends StatelessWidget {
  final SaintSortOption selectedOption;
  final ValueChanged<SaintSortOption> onOptionSelected;

  const SaintsSortSheet({
    super.key,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  /// Displays [SaintsSortSheet] as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required SaintSortOption selectedOption,
    required ValueChanged<SaintSortOption> onOptionSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SaintsSortSheet(
        selectedOption: selectedOption,
        onOptionSelected: onOptionSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Icon(Icons.sort, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Sort Saints',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ...SaintSortOption.values.map((option) {
              final isSelected = selectedOption == option;
              return ListTile(
                key: Key('sort_option_${option.name}'),
                leading: Icon(
                  option.icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  option.label,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  onOptionSelected(option);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
