import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';

Future<void> showLibraryScriptureModal({
  required BuildContext context,
  required BibleCitation citation,
}) async {
  final theme = Theme.of(context);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (sheetCtx, scrollController) {
          return FutureBuilder<List<BibleVerse>>(
            future: () async {
              await BibleDatabaseHelper.db.ensureBookPopulated(
                citation.bookNumber,
                citation.bookName,
                citation.abbrev,
              );
              return await BibleDatabaseHelper.db.getChapterVerses(
                'CPDV',
                citation.bookNumber,
                citation.chapter,
              );
            }(),
            builder: (bCtx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final verses = snapshot.data ?? [];
              final bool hasTargetVerse = citation.verse != null;
              final targetVerseNum = citation.verse ?? 1;
              final endVerseNum = citation.endVerse ?? targetVerseNum;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients &&
                    hasTargetVerse &&
                    targetVerseNum > 1) {
                  final targetIndex = verses.indexWhere(
                    (v) => v.verseNumber == targetVerseNum,
                  );
                  if (targetIndex > 0) {
                    final targetOffset = (targetIndex * 85.0).clamp(
                      0.0,
                      scrollController.position.maxScrollExtent,
                    );
                    scrollController.jumpTo(targetOffset);
                  }
                }
              });

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
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
                    Text(
                      '${citation.bookName} ${citation.chapter}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catholic Public Domain Version (CPDV)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: verses.length,
                        itemBuilder: (lCtx, index) {
                          final verse = verses[index];
                          final isTarget =
                              hasTargetVerse &&
                              verse.verseNumber >= targetVerseNum &&
                              verse.verseNumber <= endVerseNum;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 2.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              color: isTarget
                                  ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.4)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                              border: isTarget
                                  ? Border(
                                      left: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 3.5,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${verse.verseNumber}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    verse.verseText,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.5,
                                      fontWeight: isTarget
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
