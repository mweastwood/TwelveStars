class UsfmParseParams {
  final String usfmContent;
  final String translationCode;
  final int bookNumber;
  final String bookName;

  const UsfmParseParams({
    required this.usfmContent,
    required this.translationCode,
    required this.bookNumber,
    required this.bookName,
  });
}

// Simple USFM Parser
class UsfmParser {
  static final RegExp _footnoteRegex = RegExp(r'\\f\s+.*?\\f\*');
  static final RegExp _crossRefRegex = RegExp(r'\\x\s+.*?\\x\*');
  static final RegExp _qsRegex = RegExp(r'\\qs\s*.*?\s*\\qs\*');
  static final RegExp _tagRegex = RegExp(r'\\[a-zA-Z0-9]+(?:\*|\s)?');
  static final RegExp _attributeRegex = RegExp(
    r'\|[a-zA-Z0-9_]+="[^"]*"(?:\s+[a-zA-Z0-9_]+="[^"]*")*',
  );
  static final RegExp _multiSpaceRegex = RegExp(r'\s+');
  static final RegExp _chapterRegex = RegExp(r'^\\c\s+(\d+)');
  static final RegExp _verseRegex = RegExp(r'\\v\s+(\d+)\s*');
  static final RegExp _ignoredLineTagRegex = RegExp(
    r'^\\(?:id|h|toc\d*|mt\d*|cl|ca|qa|s\d*|sd\d*|cd|rem|ip)\b',
  );

  static List<Map<String, dynamic>> parseInBackground(UsfmParseParams params) {
    return parse(
      params.usfmContent,
      params.translationCode,
      params.bookNumber,
      params.bookName,
    );
  }

  static List<Map<String, dynamic>> parse(
    String usfmContent,
    String translationCode,
    int bookNumber,
    String bookName,
  ) {
    final List<Map<String, dynamic>> verses = [];
    final lines = usfmContent.split('\n');

    int currentChapter = 0;
    int currentVerseNumber = 0;
    String currentVerseText = '';

    void saveCurrentVerse() {
      if (currentChapter > 0 && currentVerseNumber > 0) {
        var text = currentVerseText;
        // Strip inline footnotes and formatting
        text = text.replaceAll(_footnoteRegex, '');
        text = text.replaceAll(_crossRefRegex, '');
        text = text.replaceAll(_qsRegex, '');
        text = text.replaceAll(_tagRegex, '');
        text = text.replaceAll(_attributeRegex, '');
        text = text.trim();
        // Remove multiple consecutive spaces
        text = text.replaceAll(_multiSpaceRegex, ' ');

        verses.add({
          'bookNumber': bookNumber,
          'bookName': bookName,
          'chapter': currentChapter,
          'verseNumber': currentVerseNumber,
          'verseText': text,
          'translationCode': translationCode,
        });
      }
    }

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final chapterMatch = _chapterRegex.firstMatch(line);
      if (chapterMatch != null) {
        saveCurrentVerse();
        currentChapter = int.parse(chapterMatch.group(1)!);
        currentVerseNumber = 0;
        currentVerseText = '';
        continue;
      }

      final verseMatches = _verseRegex.allMatches(line).toList();
      if (verseMatches.isNotEmpty) {
        for (int i = 0; i < verseMatches.length; i++) {
          final m = verseMatches[i];
          final textEnd = (i + 1 < verseMatches.length)
              ? verseMatches[i + 1].start
              : line.length;
          final chunk = line.substring(m.end, textEnd);

          if (i == 0) {
            final prefix = line.substring(0, m.start).trim();
            if (prefix.isNotEmpty &&
                currentChapter > 0 &&
                currentVerseNumber > 0) {
              currentVerseText += ' $prefix';
            }
          }

          saveCurrentVerse();
          currentVerseNumber = int.parse(m.group(1)!);
          currentVerseText = chunk;
        }
        continue;
      }

      if (currentChapter > 0 && currentVerseNumber > 0) {
        if (_ignoredLineTagRegex.hasMatch(line)) {
          continue;
        }
        currentVerseText += ' $line';
      }
    }

    saveCurrentVerse();
    return verses;
  }
}
