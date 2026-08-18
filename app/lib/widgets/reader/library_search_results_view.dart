import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';

class LibrarySearchResultsView extends StatelessWidget {
  final String searchQuery;
  final List<BookSearchResult> searchResults;
  final ValueChanged<BookSearchResult> onResultTap;

  const LibrarySearchResultsView({
    super.key,
    required this.searchQuery,
    required this.searchResults,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (searchQuery.trim().isEmpty) {
      return Center(
        child: Text(
          'Type a search term to find in this book.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Text(
          'No matches found for "$searchQuery".',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: searchResults.length,
      itemBuilder: (context, idx) {
        final res = searchResults[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: ListTile(
            title: Text(
              res.sectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                res.matchedSnippet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            onTap: () => onResultTap(res),
          ),
        );
      },
    );
  }
}
