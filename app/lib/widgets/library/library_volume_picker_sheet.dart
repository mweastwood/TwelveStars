import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/library_database.dart';

class LibraryVolumePickerSheet extends StatelessWidget {
  final LibraryBookItem bookItem;
  final ValueChanged<BaltimoreVolume> onSelectVolume;
  final ScrollController? scrollController;
  final bool popOnSelect;

  const LibraryVolumePickerSheet({
    super.key,
    required this.bookItem,
    required this.onSelectVolume,
    this.scrollController,
    this.popOnSelect = false,
  });

  static Future<void> show(
    BuildContext context, {
    required LibraryBookItem bookItem,
    required ValueChanged<BaltimoreVolume> onSelectVolume,
  }) async {
    if (bookItem.volumes == null || bookItem.volumes!.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return LibraryVolumePickerSheet(
              bookItem: bookItem,
              scrollController: scrollController,
              popOnSelect: true,
              onSelectVolume: onSelectVolume,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final volumes = bookItem.volumes ?? const <BaltimoreVolume>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10.0, bottom: 6.0),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookItem.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Select from ${volumes.length} volumes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: volumes.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final vol = volumes[idx];
              return ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (idx + 1).toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  vol.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: vol.description.isNotEmpty
                    ? Text(
                        vol.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onTap: () {
                  if (popOnSelect) {
                    Navigator.pop(ctx);
                  }
                  onSelectVolume(vol);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
