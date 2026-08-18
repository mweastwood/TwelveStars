import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  final String description;
  final String? defaultAssetPath;
  final List<BaltimoreVolume>? volumes;
  final String verseSystem;

  const LibraryBookItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.author,
    required this.description,
    this.defaultAssetPath,
    this.volumes,
    this.verseSystem = 'vulgate',
  });

  bool get isSeries => volumes != null && volumes!.isNotEmpty;
}

class BookSearchResult {
  final String bookTitle;
  final String sectionId;
  final String sectionTitle;
  final String matchedSnippet;

  BookSearchResult({
    required this.bookTitle,
    required this.sectionId,
    required this.sectionTitle,
    required this.matchedSnippet,
  });
}

class LibraryHelper {
  static const int maxCacheSize = 5;
  static final Map<String, ParsedBookData> _cache = {};

  @visibleForTesting
  static int get cacheSize => _cache.length;

  @visibleForTesting
  static void clearCache() => _cache.clear();

  static const List<BaltimoreVolume> baltimoreVolumes = [
    BaltimoreVolume(
      volumeKey: 'no1',
      name: 'No. 1 (First Communion)',
      shortName: 'No. 1',
      description: 'Abridged version for First Communion classes (33 Lessons).',
      assetPath: 'assets/catechism/json/baltimore_1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'no2',
      name: 'No. 2 (Confirmation & Grammar)',
      shortName: 'No. 2',
      description:
          'Standard edition for Confirmation and grammar grades (37 Lessons).',
      assetPath: 'assets/catechism/json/baltimore_2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'no3',
      name: 'No. 3 (Post-Confirmation Course)',
      shortName: 'No. 3',
      description:
          'Comprehensive 2-year post-confirmation study course (37 Lessons, 1400+ Q&As).',
      assetPath: 'assets/catechism/json/baltimore_3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'no4',
      name: 'No. 4 (Explanation by Fr. Kinkead)',
      shortName: 'No. 4',
      description:
          'Complete explanation with commentary and pastoral guidance by Rev. Thomas L. Kinkead.',
      assetPath: 'assets/catechism/json/baltimore_4.json',
    ),
  ];

  static const List<BaltimoreVolume> ignatiusVolumes = [
    BaltimoreVolume(
      volumeKey: 'ephesians',
      name: 'Epistle to the Ephesians',
      shortName: 'Ephesians',
      description:
          'On church harmony, unity with the bishop, and the mystery of the Incarnation.',
      assetPath: 'assets/catechism/json/ignatius_ephesians_lightfoot.json',
    ),
    BaltimoreVolume(
      volumeKey: 'magnesians',
      name: 'Epistle to the Magnesians',
      shortName: 'Magnesians',
      description:
          'On the authority of the bishop, the Lord\'s Day, and avoiding Judaizing fables.',
      assetPath: 'assets/catechism/json/ignatius_magnesians_lightfoot.json',
    ),
    BaltimoreVolume(
      volumeKey: 'trallians',
      name: 'Epistle to the Trallians',
      shortName: 'Trallians',
      description:
          'On reverence for the threefold ministry and refuting Docetism with Christ\'s true Passion.',
      assetPath: 'assets/catechism/json/ignatius_trallians_lightfoot.json',
    ),
    BaltimoreVolume(
      volumeKey: 'romans',
      name: 'Epistle to the Romans',
      shortName: 'Romans',
      description:
          'Famous letter on martyrdom: "I am God\'s wheat, to be ground by the teeth of wild beasts."',
      assetPath: 'assets/catechism/json/ignatius_romans_lightfoot.json',
    ),
    BaltimoreVolume(
      volumeKey: 'philadelphians',
      name: 'Epistle to the Philadelphians',
      shortName: 'Philadelphians',
      description:
          'On one altar, one Eucharist, unity around the bishop, and the peace of the Church.',
      assetPath: 'assets/catechism/json/ignatius_philadelphians_lightfoot.json',
    ),
    BaltimoreVolume(
      volumeKey: 'smyrnaeans',
      name: 'Epistle to the Smyrnaeans',
      shortName: 'Smyrnaeans',
      description:
          'Earliest surviving use of "Catholic Church"; defense of Christ\'s true flesh and the Eucharist.',
      assetPath: 'assets/catechism/json/ignatius_smyrnaeans_lightfoot.json',
    ),
    BaltimoreVolume(
      volumeKey: 'polycarp',
      name: 'Epistle to Polycarp',
      shortName: 'Polycarp',
      description:
          'Personal pastoral letter of counsel and encouragement to St. Polycarp, Bishop of Smyrna.',
      assetPath: 'assets/catechism/json/ignatius_polycarp_lightfoot.json',
    ),
  ];

  static const List<BaltimoreVolume> justinVolumes = [
    BaltimoreVolume(
      volumeKey: 'first_apology',
      name: 'First Apology',
      shortName: 'First Apology',
      description:
          'Addressed to Antoninus Pius; refutes charges of atheism and describes early Christian Baptism and the Sunday Eucharist.',
      assetPath: 'assets/catechism/json/justin_first_apology_dods.json',
    ),
    BaltimoreVolume(
      volumeKey: 'second_apology',
      name: 'Second Apology',
      shortName: 'Second Apology',
      description:
          'Addressed to the Roman Senate; defends Christian fortitude under unjust executions and expounds the Logos in creation.',
      assetPath: 'assets/catechism/json/justin_second_apology_dods.json',
    ),
  ];

  static const List<BaltimoreVolume> irenaeusVolumes = [
    BaltimoreVolume(
      volumeKey: 'book1',
      name: 'Book I (Gnostic Sects)',
      shortName: 'Book I',
      description:
          'Exposition of Gnostic heresies (Valentinus, Simon Magus, Ptolemy) and their mythological systems.',
      assetPath: 'assets/catechism/json/irenaeus_against_heresies_book1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book2',
      name: 'Book II (Refutation)',
      shortName: 'Book II',
      description:
          'Philosophical and logical refutation of Gnostic dualism and the Demiurge; defense of God\'s unity.',
      assetPath: 'assets/catechism/json/irenaeus_against_heresies_book2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book3',
      name: 'Book III (Faith & Tradition)',
      shortName: 'Book III',
      description:
          'The Rule of Faith, Apostolic Succession, the preeminence of the Roman Church, and the fourfold Gospel.',
      assetPath: 'assets/catechism/json/irenaeus_against_heresies_book3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book4',
      name: 'Book IV (Scripture & Law)',
      shortName: 'Book IV',
      description:
          'Unity of the Old and New Testaments; proof from Christ and the Prophets that the Father of Jesus is the Creator.',
      assetPath: 'assets/catechism/json/irenaeus_against_heresies_book4.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book5',
      name: 'Book V (Resurrection)',
      shortName: 'Book V',
      description:
          'The Incarnation, the resurrection of the flesh, recapitulation, and the final consummation in the Kingdom of God.',
      assetPath: 'assets/catechism/json/irenaeus_against_heresies_book5.json',
    ),
  ];

  static List<LibraryBookItem> getCatalog() {
    return [
      const LibraryBookItem(
        id: 'baltimore_catechism',
        title: 'Baltimore Catechism',
        subtitle: 'Third Plenary Council of Baltimore (1885)',
        category: 'Catechisms',
        author: 'Third Plenary Council of Baltimore / Rev. Thomas L. Kinkead',
        description:
            'The official national Catholic catechism of the United States from 1885 to the late 20th century. Features 4 progressive editions for all age levels.',
        volumes: baltimoreVolumes,
      ),
      const LibraryBookItem(
        id: 'council_of_trent',
        title: 'Catechism of the Council of Trent',
        subtitle: 'The Roman Catechism (St. Pius V, 1566)',
        category: 'Catechisms',
        author:
            'Council of Trent / Commission of St. Pius V (Trans. Rev. J. Donovan)',
        description:
            'Promulgated by Pope St. Pius V in 1566. The authoritative Roman Catechism expounding Catholic doctrine, sacraments, commandments, and prayer.',
        defaultAssetPath: 'assets/catechism/json/council_of_trent.json',
      ),
      const LibraryBookItem(
        id: 'didache_lightfoot',
        title: 'The Didache',
        subtitle:
            'The Teaching of the Twelve Apostles (Trans. J. B. Lightfoot, 1891)',
        category: 'Apostolic Fathers',
        author: 'The Apostolic Fathers (Trans. J. B. Lightfoot)',
        description:
            'The earliest surviving non-canonical Christian treatise (c. 1st century), presenting the doctrine of the Two Ways, early liturgical rites for Baptism and the Eucharist, and instructions on church order.',
        defaultAssetPath: 'assets/catechism/json/didache_lightfoot.json',
      ),
      const LibraryBookItem(
        id: 'first_clement_lightfoot',
        title: 'First Epistle of Clement',
        subtitle:
            'Letter of the Church of Rome to the Corinthians (Trans. J. B. Lightfoot, 1891)',
        category: 'Apostolic Fathers',
        author: 'Pope St. Clement of Rome (Trans. J. B. Lightfoot)',
        description:
            'Written c. 96 AD from the Church of Rome to Corinth to restore order following a rebellion against the presbyters. An invaluable early witness to apostolic succession, Christian charity, and liturgical order.',
        defaultAssetPath: 'assets/catechism/json/first_clement_lightfoot.json',
      ),
      const LibraryBookItem(
        id: 'second_clement_lightfoot',
        title: 'Second Epistle of Clement',
        subtitle: 'An Ancient Christian Homily (Trans. J. B. Lightfoot, 1891)',
        category: 'Apostolic Fathers',
        author: 'The Apostolic Fathers (Trans. J. B. Lightfoot)',
        description:
            'The earliest surviving complete Christian sermon/homily outside the New Testament (c. 100–140 AD), exhorting believers to purity of life, repentance, and steadfast hope in the resurrection.',
        defaultAssetPath: 'assets/catechism/json/second_clement_lightfoot.json',
      ),
      const LibraryBookItem(
        id: 'ignatius_epistles',
        title: 'Epistles of St. Ignatius',
        subtitle: 'The Seven Authentic Letters (Trans. J. B. Lightfoot, 1891)',
        category: 'Apostolic Fathers',
        author: 'St. Ignatius of Antioch (Trans. J. B. Lightfoot)',
        description:
            'Written c. 107–110 AD on his way to martyrdom in Rome. The seven authentic letters provide an irreplaceable early witness to the hierarchy of the Church, the Holy Eucharist, the Catholic Church, and Christian martyrdom.',
        volumes: ignatiusVolumes,
      ),
      const LibraryBookItem(
        id: 'justin_martyr_apologies',
        title: 'Apologies of St. Justin Martyr',
        subtitle: 'The First and Second Apologies (Trans. Marcus Dods, 1885)',
        category: 'Early Apologists',
        author: 'St. Justin Martyr (Trans. Marcus Dods)',
        description:
            'Written c. 150–155 AD to Emperor Antoninus Pius and the Roman Senate. Famous early defenses of Christian doctrine and morality, featuring the earliest detailed accounts of the Sunday Eucharistic Liturgy and Baptism.',
        volumes: justinVolumes,
      ),
      const LibraryBookItem(
        id: 'irenaeus_against_heresies',
        title: 'Against Heresies',
        subtitle: 'Adversus Haereses (Trans. Roberts & Rambaut, 1885)',
        category: 'Church Fathers',
        author: 'St. Irenaeus of Lyons (Trans. Roberts & Rambaut)',
        description:
            'Written c. 180 AD by the Bishop of Lyons. The monumental 5-book refutation of Gnosticism establishing Apostolic Succession, the authority of the Roman Church, the fourfold Gospel canon, and the resurrection of the body.',
        volumes: irenaeusVolumes,
      ),
      const LibraryBookItem(
        id: 'athanasius_on_the_incarnation',
        title: 'On the Incarnation of the Word',
        subtitle:
            'De Incarnatione Verbi Dei (Trans. Archibald Robertson, 1892)',
        category: 'Church Fathers',
        author: 'St. Athanasius of Alexandria (Trans. Archibald Robertson)',
        description:
            'Written c. 318–335 AD by the Patriarch of Alexandria. The classic treatise on why God became man, the redemption of humanity through Christ\'s death and resurrection, and the spiritual renewal of the world.',
        defaultAssetPath:
            'assets/catechism/json/athanasius_on_the_incarnation.json',
      ),
    ];
  }

  static Future<ParsedBookData> loadBookData(String assetPath) async {
    if (_cache.containsKey(assetPath)) {
      final cached = _cache.remove(assetPath)!;
      _cache[assetPath] = cached;
      return cached;
    }
    final rawString = await rootBundle.loadString(assetPath);
    final map = json.decode(rawString) as Map<String, dynamic>;
    final parsed = ParsedBookData.fromJson(map);
    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[assetPath] = parsed;
    return parsed;
  }

  static List<BookSearchResult> searchInBook(
    ParsedBookData book,
    String query,
  ) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];
    final words = cleanQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    final results = <BookSearchResult>[];

    for (final sec in book.sections) {
      for (final item in sec.content) {
        String fullText = '';
        if (item.type == 'qa') {
          fullText =
              'Q. ${item.questionNumber} ${item.question ?? ""} A. ${item.answer ?? ""}';
        } else {
          fullText = item.text ?? '';
        }

        final lowerText = fullText.toLowerCase();
        final matches = words.every((w) => lowerText.contains(w));
        if (matches) {
          int matchIdx = lowerText.indexOf(words.first);
          int start = (matchIdx - 30).clamp(0, fullText.length);
          int end = (matchIdx + 120).clamp(0, fullText.length);
          String snippet = fullText.substring(start, end).replaceAll('\n', ' ');
          if (start > 0) snippet = '...$snippet';
          if (end < fullText.length) snippet = '$snippet...';

          results.add(
            BookSearchResult(
              bookTitle: book.title,
              sectionId: sec.id,
              sectionTitle: sec.title,
              matchedSnippet: snippet,
            ),
          );
          if (results.length >= 50) break;
        }
      }
      if (results.length >= 50) break;
    }

    return results;
  }
}
