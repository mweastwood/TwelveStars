/// Centralized codec for constructing and parsing reader content and annotation
/// node identifiers across Scripture (Bible/Missal) and Library documents.
class ReaderNodeId {
  const ReaderNodeId._();

  /// Formats a canonical Bible verse node ID (`'<bookNumber>_<chapter>_<verseNumber>'`).
  static String bibleVerse(int bookNumber, int chapter, int verseNumber) =>
      '${bookNumber}_${chapter}_$verseNumber';

  /// Extracts the trailing 1-based verse number from a Bible [nodeId],
  /// returning [fallback] if parsing fails.
  static int parseBibleVerseNumber(String nodeId, {int fallback = 1}) {
    if (nodeId.isEmpty) return fallback;
    final lastPart = nodeId.split('_').last;
    return int.tryParse(lastPart) ?? fallback;
  }

  /// Formats a canonical Library item node ID (`'[<volumeKey>:]<sectionId>_<itemIndex>'`).
  static String libraryItem({
    required String sectionId,
    required int itemIndex,
    String? volumeKey,
  }) {
    final prefix = (volumeKey != null && volumeKey.isNotEmpty)
        ? '$volumeKey:'
        : '';
    return '$prefix${sectionId}_$itemIndex';
  }

  /// Parses a Library bookmark or comment [nodeId] into its constituent
  /// `(volumeKey, itemIndex, questionNumber)` components.
  ///
  /// Supports both canonical underscore-delimited (`sec_1_0`) and legacy
  /// hyphen-delimited (`sec_1-0`) item indices, as well as question suffixes
  /// (`lesson_01_q42`) and volume prefixes (`no2:lesson_03_q15`).
  static (String? volumeKey, int? itemIndex, int? questionNumber) parseLibrary(
    String nodeId,
  ) {
    String? volumeKey;
    String rest = nodeId;
    if (rest.contains(':')) {
      final parts = rest.split(':');
      volumeKey = parts.first;
      rest = parts.sublist(1).join(':');
    }

    int? itemIndex;
    int? questionNumber;

    if (rest.contains('_q')) {
      final qPart = rest.split('_q').last;
      questionNumber = int.tryParse(qPart);
    } else if (rest.contains('_')) {
      final lastPart = rest.split('_').last;
      itemIndex = int.tryParse(lastPart);
    } else if (rest.contains('-')) {
      final lastPart = rest.split('-').last;
      itemIndex = int.tryParse(lastPart);
    }

    return (volumeKey, itemIndex, questionNumber);
  }
}
