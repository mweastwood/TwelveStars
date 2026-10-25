class TocEntry {
  final String id;
  final String title;

  TocEntry({required this.id, required this.title});

  factory TocEntry.fromJson(Map<String, dynamic> json) {
    return TocEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }
}

class ContentItem {
  final String type; // 'qa', 'text', or 'heading'
  final int? questionNumber;
  final int? crossRefQNum;
  final String? question;
  final String? answer;
  final String? explanation;
  final String? text;

  ContentItem({
    required this.type,
    this.questionNumber,
    this.crossRefQNum,
    this.question,
    this.answer,
    this.explanation,
    this.text,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      type: json['type'] as String? ?? 'text',
      questionNumber: json['questionNumber'] as int?,
      crossRefQNum: json['crossRefQNum'] as int?,
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      explanation: json['explanation'] as String?,
      text: json['text'] as String?,
    );
  }
}

class BookSection {
  final String id;
  final String title;
  final String subtitle;
  final List<ContentItem> content;

  BookSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  factory BookSection.fromJson(Map<String, dynamic> json) {
    final rawList = json['content'] as List<dynamic>? ?? [];
    return BookSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      content: rawList
          .map((c) => ContentItem.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParsedBookData {
  final String bookId;
  final String title;
  final String subtitle;
  final String author;
  final String verseSystem;
  final List<TocEntry> toc;
  final List<BookSection> sections;

  ParsedBookData({
    required this.bookId,
    required this.title,
    required this.subtitle,
    required this.author,
    this.verseSystem = 'vulgate',
    required this.toc,
    required this.sections,
  });

  factory ParsedBookData.fromJson(Map<String, dynamic> json) {
    final rawToc = json['toc'] as List<dynamic>? ?? [];
    final rawSec = json['sections'] as List<dynamic>? ?? [];
    return ParsedBookData(
      bookId: json['bookId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      author: json['author'] as String? ?? '',
      verseSystem: json['verseSystem'] as String? ?? 'vulgate',
      toc: rawToc
          .map((t) => TocEntry.fromJson(t as Map<String, dynamic>))
          .toList(),
      sections: rawSec
          .map((s) => BookSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BaltimoreVolume {
  final String volumeKey;
  final String name;
  final String shortName;
  final String description;
  final String assetPath;

  const BaltimoreVolume({
    required this.volumeKey,
    required this.name,
    required this.shortName,
    required this.description,
    required this.assetPath,
  });
}

class LibraryBookItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String author;
  final String? authorSaintId;
  final String description;
  final String? era;
  final String? defaultAssetPath;
  final List<BaltimoreVolume>? volumes;
  final String verseSystem;
  final String? webUrl;

  const LibraryBookItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.author,
    this.authorSaintId,
    required this.description,
    this.era,
    this.defaultAssetPath,
    this.volumes,
    this.verseSystem = 'vulgate',
    this.webUrl,
  });

  bool get isWeb => webUrl != null && webUrl!.isNotEmpty;

  bool get isSeries => volumes != null && volumes!.isNotEmpty;

  List<String> get allAssetPaths {
    if (isSeries && volumes != null) {
      return volumes!.map((v) => v.assetPath).toList();
    } else if (defaultAssetPath != null) {
      return [defaultAssetPath!];
    }
    return const [];
  }

  static String assetStem(String path) {
    final slash = path.lastIndexOf('/');
    final fileName = slash >= 0 ? path.substring(slash + 1) : path;
    return fileName.endsWith('.json')
        ? fileName.substring(0, fileName.length - 5)
        : fileName;
  }

  static bool matchesAssetExact(String candidatePath, String query) {
    if (candidatePath == query ||
        candidatePath.endsWith('/$query') ||
        candidatePath.endsWith('/$query.json')) {
      return true;
    }
    return assetStem(candidatePath) == assetStem(query);
  }

  static bool matchesAssetBoundarySubstring(
    String candidatePath,
    String query,
  ) {
    int start = 0;
    while (true) {
      final idx = candidatePath.indexOf(query, start);
      if (idx < 0) return false;
      final afterIdx = idx + query.length;
      final followedByDigit =
          afterIdx < candidatePath.length &&
          candidatePath.codeUnitAt(afterIdx) >= 0x30 &&
          candidatePath.codeUnitAt(afterIdx) <= 0x39;
      if (!followedByDigit) {
        return true;
      }
      start = idx + 1;
    }
  }

  /// Resolves a [BaltimoreVolume] for a series book by [volumeKey] or [assetPath].
  ///
  /// When [fallbackToFirst] is `true`, returns `volumes!.first` if no specific
  /// volume matches.
  BaltimoreVolume? resolveVolume({
    String? volumeKey,
    String? assetPath,
    bool fallbackToFirst = true,
  }) {
    if (!isSeries || volumes == null || volumes!.isEmpty) {
      return null;
    }
    if (volumeKey != null && volumeKey.isNotEmpty) {
      for (final v in volumes!) {
        if (v.volumeKey == volumeKey) return v;
      }
    }
    if (assetPath != null && assetPath.isNotEmpty) {
      for (final v in volumes!) {
        if (matchesAssetExact(v.assetPath, assetPath)) {
          return v;
        }
      }
      for (final v in volumes!) {
        if (matchesAssetBoundarySubstring(v.assetPath, assetPath)) {
          return v;
        }
      }
    }
    return fallbackToFirst ? volumes!.first : null;
  }
}

/// Represents a resolved [LibraryBookItem] and optional [BaltimoreVolume]
/// target within the library catalog.
class ResolvedLibraryTarget {
  final LibraryBookItem book;
  final BaltimoreVolume? volume;
  final String? volumeKey;
  final String? assetPath;

  const ResolvedLibraryTarget({
    required this.book,
    this.volume,
    this.volumeKey,
    this.assetPath,
  });
}

class BookSearchResult {
  final String bookTitle;
  final String sectionId;
  final String sectionTitle;
  final String matchedSnippet;
  final String? bookId;
  final String? volumeKey;
  final String? assetPath;

  BookSearchResult({
    required this.bookTitle,
    required this.sectionId,
    required this.sectionTitle,
    required this.matchedSnippet,
    this.bookId,
    this.volumeKey,
    this.assetPath,
  });
}
