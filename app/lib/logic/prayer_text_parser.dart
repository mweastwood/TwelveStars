import 'package:twelve_stars/logic/prayers.dart';

/// Pure utility for linguistic and structural parsing of prayer texts,
/// including liturgical dialogue prefixes, phrase slicing, and line-offset indexing.
class PrayerTextParser {
  const PrayerTextParser._();

  /// Matches inline markdown italics (`*text*`).
  static final RegExp italicsRegex = RegExp(r'\*([^*]+)\*');

  /// Matches liturgical congregational response line prefixes across supported languages.
  static final RegExp responsePrefixRegex = RegExp(
    r'^\s*(?:(?:People|Response|All|Populus|Omnes|Asamblea|Pueblo|Todos|Cộng\s+đoàn|Người\s+đáp|Tất\s+cả|Peuple|Tous|Fidèles|Popolo|Tutti|Bayan|Lahat|信友|全體|答|應|眾|會眾|同答)\s*[:：]|℟\.?|R\.|R:)',
    caseSensitive: false,
    multiLine: true,
  );

  /// Matches liturgical celebrant/leader line prefixes across supported languages.
  static final RegExp celebrantPrefixRegex = RegExp(
    r'^\s*(?:(?:Priest|Celebrant|Reader|Lector|Lecteur|Lettore|Sacerdos|Diaconus|Sacerdote|Diácono|Linh\s+mục|Phó\s+tế|Người\s+xướng|Người\s+đọc|Namumuno|領經者|主祭|司鐸|執事|讀經者|主禮|啟)\s*[:：]|℣\.?|V\.|V:)',
    caseSensitive: false,
    multiLine: true,
  );

  /// Returns `true` if [line] begins with a congregational response prefix.
  static bool isResponseLine(String line) {
    return responsePrefixRegex.hasMatch(line);
  }

  /// Returns `true` if [line] begins with a celebrant or leader prefix.
  static bool isCelebrantLine(String line) {
    return celebrantPrefixRegex.hasMatch(line);
  }

  /// Returns `true` if [text] contains any congregational response lines.
  static bool hasResponses(String text) {
    return responsePrefixRegex.hasMatch(text);
  }

  /// Computes the starting character offset of each line in [lines] within
  /// a newline-joined text (`\n` = 1 character).
  static List<int> computeLineStartOffsets(List<String> lines) {
    final lineStartIndices = <int>[];
    int currentStart = 0;
    for (final line in lines) {
      lineStartIndices.add(currentStart);
      currentStart += line.length + 1; // +1 for '\n'
    }
    return lineStartIndices;
  }

  /// Resolves the 0-based line index for [charOffset] given precomputed
  /// [lineStartOffsets] from [computeLineStartOffsets].
  static int getLineIndexAt(List<int> lineStartOffsets, int charOffset) {
    if (charOffset <= 0 || lineStartOffsets.isEmpty) return 0;
    int idx = 0;
    for (int i = 0; i < lineStartOffsets.length; i++) {
      if (lineStartOffsets[i] <= charOffset) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  /// Extracts phrase text from a [PrayerTranslation], token/character list, or
  /// plain text string.
  ///
  /// - When [source] is a [PrayerTranslation] and [phraseSelector] is a phrase
  ///   ID (`String`), concatenates matching tokens (stripping markdown `*`) or
  ///   Chinese characters.
  /// - When [source] is a `String` and [phraseSelector] is a 0-based phrase/line
  ///   index (`int?`), slices the corresponding phrase segment.
  static String extractPhraseText(Object source, [Object? phraseSelector]) {
    if (source is PrayerTranslation) {
      final phraseId = phraseSelector?.toString();
      if (phraseId == null || phraseId.isEmpty) return '';
      if (source.tokens != null && source.tokens!.isNotEmpty) {
        return source.tokens!
            .where((t) => t.id == phraseId)
            .map((t) => t.text.replaceAll('*', ''))
            .join('')
            .trim();
      }
      if (source.chineseLines != null && source.chineseLines!.isNotEmpty) {
        final buffer = StringBuffer();
        for (final line in source.chineseLines!) {
          for (final charItem in line.chars ?? const <ChineseChar>[]) {
            if (charItem.phraseId == phraseId) {
              buffer.write(charItem.char);
            }
          }
        }
        return buffer.toString().trim();
      }
      return '';
    }

    if (source is List<PrayerToken>) {
      final phraseId = phraseSelector?.toString();
      if (phraseId == null || phraseId.isEmpty) return '';
      return source
          .where((t) => t.id == phraseId)
          .map((t) => t.text.replaceAll('*', ''))
          .join('')
          .trim();
    }

    if (source is List<ChineseLine>) {
      final phraseId = phraseSelector?.toString();
      if (phraseId == null || phraseId.isEmpty) return '';
      final buffer = StringBuffer();
      for (final line in source) {
        for (final charItem in line.chars ?? const <ChineseChar>[]) {
          if (charItem.phraseId == phraseId) {
            buffer.write(charItem.char);
          }
        }
      }
      return buffer.toString().trim();
    }

    if (source is String) {
      if (phraseSelector == null || source.isEmpty) return '';
      if (phraseSelector is int) {
        if (phraseSelector < 0) return '';
        final segments = source.contains('\n')
            ? source.split('\n')
            : source.split(';');
        if (phraseSelector >= segments.length) return '';
        return segments[phraseSelector].replaceAll('*', '').trim();
      }
    }

    return '';
  }
}
