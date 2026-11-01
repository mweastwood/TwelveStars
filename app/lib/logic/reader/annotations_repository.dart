import 'package:drift/drift.dart' show Value;
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart'
    show catholicBooksByNumber;

/// Domain repository for reading and mutating Bible and Library annotations
/// (comments, favorite passages, and library bookmarks) without exposing Drift
/// Companion classes or `Value` wrappers to UI layers.
class AnnotationsRepository {
  const AnnotationsRepository._();

  /// Inserts a new user comment and returns its auto-incremented row ID.
  static Future<int> addComment({
    required String documentId,
    required int sectionIndex,
    required String nodeId,
    required String commentText,
    String? textPreview,
    String? targetSubtext,
    String? translationId,
  }) {
    final resolvedPreview = textPreview ?? targetSubtext;
    return BibleDatabaseHelper.db.saveComment(
      UserCommentsCompanion.insert(
        documentId: documentId,
        sectionIndex: sectionIndex,
        nodeId: nodeId,
        commentText: commentText,
        textPreview: resolvedPreview != null
            ? Value(resolvedPreview)
            : const Value.absent(),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Updates the text of an existing user comment with [commentId].
  static Future<void> updateComment(int commentId, String newText) async {
    await BibleDatabaseHelper.db.updateComment(commentId, newText);
  }

  /// Deletes the user comment with [commentId].
  static Future<void> deleteComment(int commentId) async {
    await BibleDatabaseHelper.db.deleteComment(commentId);
  }

  /// Inserts a new favorite Bible passage and returns its auto-incremented ID.
  static Future<int> saveFavoritePassage({
    required int bookNumber,
    required int chapter,
    required int startVerse,
    required int endVerse,
    required String textPreview,
    String translationId = 'CPDV',
    String? bookName,
  }) {
    final resolvedBookName =
        bookName ??
        catholicBooksByNumber[bookNumber]?.bookName ??
        'Book $bookNumber';
    return BibleDatabaseHelper.db.saveFavorite(
      FavoritePassagesCompanion.insert(
        bookNumber: bookNumber,
        bookName: resolvedBookName,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        textPreview: textPreview,
      ),
    );
  }

  /// Deletes the favorite Bible passage with [favoriteId].
  static Future<void> deleteFavoritePassage(int favoriteId) async {
    await BibleDatabaseHelper.db.deleteFavorite(favoriteId);
  }

  /// Deletes the library bookmark with [bookmarkId].
  static Future<void> deleteLibraryBookmark(int bookmarkId) async {
    await BibleDatabaseHelper.db.deleteLibraryBookmark(bookmarkId);
  }
}
