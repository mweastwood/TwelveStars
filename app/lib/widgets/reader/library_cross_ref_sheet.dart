import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';

Future<void> showBaltimoreCrossRefSheet({
  required BuildContext context,
  required int questionNumber,
  required LibraryBookItem bookItem,
  required void Function(BaltimoreVolume volume, int sectionIndex)
  onSwitchVolume,
}) async {
  final theme = Theme.of(context);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (sheetCtx, scrollController) {
          return FutureBuilder<List<ParsedBookData?>>(
            future: Future.wait([
              LibraryHelper.loadBookData(
                'assets/catechism/json/baltimore_2.json',
              ),
              LibraryHelper.loadBookData(
                'assets/catechism/json/baltimore_4.json',
              ),
            ]),
            builder: (bCtx, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final vol2 = snapshot.data![0];
              final vol4 = snapshot.data![1];

              ContentItem? q2Item;
              int? q2SecIdx;
              if (vol2 != null) {
                for (int s = 0; s < vol2.sections.length; s++) {
                  for (final item in vol2.sections[s].content) {
                    if (item.type == 'qa' &&
                        item.questionNumber == questionNumber) {
                      q2Item = item;
                      q2SecIdx = s;
                      break;
                    }
                  }
                  if (q2Item != null) break;
                }
              }

              ContentItem? q4Item;
              int? q4SecIdx;
              if (vol4 != null) {
                for (int s = 0; s < vol4.sections.length; s++) {
                  for (final item in vol4.sections[s].content) {
                    if (item.type == 'qa' &&
                        item.questionNumber == questionNumber) {
                      q4Item = item;
                      q4SecIdx = s;
                      break;
                    }
                  }
                  if (q4Item != null) break;
                }
              }

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cross-Reference: Master Question #$questionNumber',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (q2Item != null) ...[
                      Text(
                        'Baltimore Catechism No. 2 (Confirmation Edition)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q. ${q2Item.questionNumber}. ${q2Item.question}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('A. ${q2Item.answer}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (q4Item != null) ...[
                      Text(
                        'Baltimore Catechism No. 4 (Fr. Kinkead\'s Explanation)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPLANATION',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              q4Item.explanation ?? q4Item.answer ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (bookItem.isSeries && bookItem.volumes != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (q2SecIdx != null &&
                              bookItem.volumes!.any(
                                (v) =>
                                    v.volumeKey == 'no2' ||
                                    v.volumeKey == 'baltimore_2',
                              ))
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.bookmark_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Open Vol 2'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                onSwitchVolume(
                                  bookItem.volumes!.firstWhere(
                                    (v) =>
                                        v.volumeKey == 'no2' ||
                                        v.volumeKey == 'baltimore_2',
                                  ),
                                  q2SecIdx!,
                                );
                              },
                            ),
                          if (q4SecIdx != null &&
                              bookItem.volumes!.any(
                                (v) =>
                                    v.volumeKey == 'no4' ||
                                    v.volumeKey == 'baltimore_4',
                              ))
                            FilledButton.icon(
                              icon: const Icon(
                                Icons.menu_book_rounded,
                                size: 18,
                              ),
                              label: const Text('Open Vol 4'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                onSwitchVolume(
                                  bookItem.volumes!.firstWhere(
                                    (v) =>
                                        v.volumeKey == 'no4' ||
                                        v.volumeKey == 'baltimore_4',
                                  ),
                                  q4SecIdx!,
                                );
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
