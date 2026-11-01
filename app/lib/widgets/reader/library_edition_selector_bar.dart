import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';

class LibraryEditionSelectorBar extends StatelessWidget {
  final List<BaltimoreVolume> volumes;
  final String? selectedVolumeKey;
  final ValueChanged<BaltimoreVolume> onVolumeSelected;
  final String label;

  const LibraryEditionSelectorBar({
    super.key,
    required this.volumes,
    required this.selectedVolumeKey,
    required this.onVolumeSelected,
    this.label = 'Edition: ',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: volumes.map((vol) {
                  final isSel = vol.volumeKey == selectedVolumeKey;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      key: ValueKey('edition_chip_${vol.volumeKey}'),
                      label: Text(vol.shortName),
                      selected: isSel,
                      onSelected: (selected) {
                        if (selected) onVolumeSelected(vol);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
