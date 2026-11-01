import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/widgets/library/library_book_card.dart';

class LibrarySearchResultsView extends StatelessWidget {
  final String searchQuery;
  final bool isLoading;
  final List<BookSearchResult> results;
  final List<LibraryBookItem>? catalog;
  final void Function(
    LibraryBookItem book, {
    String? volumeKey,
    String? assetPath,
    String? sectionId,
    int? questionNumber,
    int? itemIndex,
  })
  onOpenReader;

  const LibrarySearchResultsView({
    super.key,
    required this.searchQuery,
    required this.isLoading,
    required this.results,
    this.catalog,
    required this.onOpenReader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providedCatalog = catalog;
    final effectiveCatalog =
        (providedCatalog != null && providedCatalog.isNotEmpty)
        ? providedCatalog
        : LibraryHelper.getCatalog();

    final Map<String, List<BookSearchResult>> groups = {};
    for (final res in results) {
      groups.putIfAbsent(res.bookTitle, () => []).add(res);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SEARCH RESULTS',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (results.isEmpty)
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No search results found for "$searchQuery".',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...groups.entries.map((entry) {
            final bookTitle = entry.key;
            final groupResults = entry.value;
            final firstResult = groupResults.first;
            final resolvedGroupTarget = LibraryCatalog.resolveTarget(
              bookId: firstResult.bookId,
              volumeKey: firstResult.volumeKey,
              assetPath: firstResult.assetPath,
              catalog: effectiveCatalog,
            );
            final matchingBook =
                resolvedGroupTarget?.book ??
                effectiveCatalog.firstWhere(
                  (b) => b.title == bookTitle,
                  orElse: () => effectiveCatalog.first,
                );
            final categoryIcon = LibraryCategoryIcons.forCategory(
              matchingBook.category,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          categoryIcon,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bookTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${groupResults.length} ${groupResults.length == 1 ? 'match' : 'matches'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...groupResults.map((res) {
                      final resolvedResultTarget = LibraryCatalog.resolveTarget(
                        bookId: res.bookId,
                        volumeKey: res.volumeKey,
                        assetPath: res.assetPath,
                        catalog: effectiveCatalog,
                      );
                      final targetBook =
                          resolvedResultTarget?.book ?? matchingBook;
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onOpenReader(
                          targetBook,
                          volumeKey:
                              res.volumeKey ?? resolvedResultTarget?.volumeKey,
                          assetPath:
                              res.assetPath ?? resolvedResultTarget?.assetPath,
                          sectionId: res.sectionId,
                          itemIndex: res.itemIndex,
                          questionNumber: res.questionNumber,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 4.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                res.sectionTitle,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                res.matchedSnippet,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
