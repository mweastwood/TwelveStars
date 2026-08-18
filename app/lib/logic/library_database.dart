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

  static const List<BaltimoreVolume> confessionsVolumes = [
    BaltimoreVolume(
      volumeKey: 'book1',
      name: 'Book I (Infancy & Childhood)',
      shortName: 'Book I',
      description:
          'Early childhood, school years, learning to speak, and initial prayers.',
      assetPath: 'assets/catechism/json/augustine_confessions_book1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book2',
      name: 'Book II (The Pear Tree)',
      shortName: 'Book II',
      description:
          'Adolescence, awakening desires, and the infamous theft of the pears.',
      assetPath: 'assets/catechism/json/augustine_confessions_book2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book3',
      name: 'Book III (Carthage & Manichaeism)',
      shortName: 'Book III',
      description:
          'Studies in Carthage, love of theatre, fall into Manichaeism, and Monica\'s tears.',
      assetPath: 'assets/catechism/json/augustine_confessions_book3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book4',
      name: 'Book IV (Teaching Rhetoric & Grief)',
      shortName: 'Book IV',
      description:
          'Teaching rhetoric at Tagaste, grief over the death of a close friend, and treatise on beauty.',
      assetPath: 'assets/catechism/json/augustine_confessions_book4.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book5',
      name: 'Book V (Rome & Milan)',
      shortName: 'Book V',
      description:
          'Disillusionment with Faustus the Manichaean, move to Rome and Milan, meeting St. Ambrose.',
      assetPath: 'assets/catechism/json/augustine_confessions_book5.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book6',
      name: 'Book VI (Moral Struggles & Friends)',
      shortName: 'Book VI',
      description:
          'Friendship with Alypius and Nebridius, worldly ambitions, and search for truth.',
      assetPath: 'assets/catechism/json/augustine_confessions_book6.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book7',
      name: 'Book VII (Neoplatonism & the Word)',
      shortName: 'Book VII',
      description:
          'Overcoming materialism, the origin of evil, Platonist philosophy, and Christ the Mediator.',
      assetPath: 'assets/catechism/json/augustine_confessions_book7.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book8',
      name: 'Book VIII (Conversion in the Garden)',
      shortName: 'Book VIII',
      description:
          'The struggle of two wills, reading St. Paul, and the voice saying "Tolle, lege" (Take and read).',
      assetPath: 'assets/catechism/json/augustine_confessions_book8.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book9',
      name: 'Book IX (Baptism & Death of Monica)',
      shortName: 'Book IX',
      description:
          'Baptism at Milan by St. Ambrose, mystical vision at Ostia, and the holy death of St. Monica.',
      assetPath: 'assets/catechism/json/augustine_confessions_book9.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book10',
      name: 'Book X (Memory & Self-Examination)',
      shortName: 'Book X',
      description:
          'Profound exploration of memory, the senses, temptations, and Christ the true Mediator.',
      assetPath: 'assets/catechism/json/augustine_confessions_book10.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book11',
      name: 'Book XI (Time & Eternity)',
      shortName: 'Book XI',
      description:
          'The creation narrative in Genesis 1:1, the nature of time, eternity, and psychological perception of time.',
      assetPath: 'assets/catechism/json/augustine_confessions_book11.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book12',
      name: 'Book XII (Heaven, Earth & Scripture)',
      shortName: 'Book XII',
      description:
          'Exposition of Genesis 1:1–2, formless matter, spiritual creation, and biblical hermeneutics.',
      assetPath: 'assets/catechism/json/augustine_confessions_book12.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book13',
      name: 'Book XIII (The Allegory of Creation)',
      shortName: 'Book XIII',
      description:
          'Spiritual and allegorical interpretation of the Six Days of Creation and God\'s Sabbath rest.',
      assetPath: 'assets/catechism/json/augustine_confessions_book13.json',
    ),
  ];

  static const List<BaltimoreVolume> cityOfGodVolumes = [
    BaltimoreVolume(
      volumeKey: 'book1',
      name: 'Book I (The Sack of Rome)',
      shortName: 'Book I',
      description:
          'Refutation of pagans who blamed Christianity for the sack of Rome; defense of Christian sanctuary.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book2',
      name: 'Book II (Moral Evils of Rome)',
      shortName: 'Book II',
      description:
          'Proof that pagan gods failed to protect Rome from moral degeneration and corruption.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book3',
      name: 'Book III (Physical Calamities of Rome)',
      shortName: 'Book III',
      description:
          'Survey of disasters, wars, plagues, and civil strife suffered by Rome under pagan rule.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book4',
      name: 'Book IV (Imperial Greatness & True God)',
      shortName: 'Book IV',
      description:
          'Kingdoms without justice are great robberies; earthly empire is granted by the one true God.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book4.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book5',
      name: 'Book V (Fate, Providence & Free Will)',
      shortName: 'Book V',
      description:
          'Refutation of astrological fate; harmony of divine foreknowledge, providence, and human free will.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book5.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book6',
      name: 'Book VI (Varro & Civil Theology)',
      shortName: 'Book VI',
      description:
          'Refutation of civil theology; Varro\'s classification of gods; pagan gods cannot give eternal life.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book6.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book7',
      name: 'Book VII (Natural Theology & Pagan Gods)',
      shortName: 'Book VII',
      description:
          'Refutation of physical interpretations of pagan deities; worship belongs to the Creator alone.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book7.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book8',
      name: 'Book VIII (Platonism & Demonology)',
      shortName: 'Book VIII',
      description:
          'Examination of Platonist philosophy; refutation of Apuleius and demonic mediation; Christ alone is Mediator.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book8.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book9',
      name: 'Book IX (Demons vs. Christ the Mediator)',
      shortName: 'Book IX',
      description:
          'Demons are spirits of wickedness incapable of mediating; Christ the God-man is our sole Mediator.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book9.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book10',
      name: 'Book X (Sacrifice, Angels & Porphyry)',
      shortName: 'Book X',
      description:
          'The nature of true worship (latria) and sacrifice; holy angels refuse worship; refutation of Porphyry.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book10.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book11',
      name: 'Book XI (Creation & the Angelic Cities)',
      shortName: 'Book XI',
      description:
          'The beginning of the City of God; creation of time, light, and separation of holy and fallen angels.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book11.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book12',
      name: 'Book XII (Angelic Wills & Creation of Man)',
      shortName: 'Book XII',
      description:
          'Good and evil wills of angels; creation of mankind from one man; refutation of cyclical time.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book12.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book13',
      name: 'Book XIII (The Fall & Human Mortality)',
      shortName: 'Book XIII',
      description:
          'The fall of Adam, original sin, bodily and spiritual death, and restoration through Christ.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book13.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book14',
      name: 'Book XIV (The Two Loves & Two Cities)',
      shortName: 'Book XIV',
      description:
          'Living according to the flesh vs. spirit; the two loves that founded the two cities (love of self vs. love of God).',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book14.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book15',
      name: 'Book XV (Two Cities in Genesis: Cain & Abel)',
      shortName: 'Book XV',
      description:
          'The earthly city represented by Cain and heavenly city by Abel; Noah\'s Ark as a figure of the Church.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book15.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book16',
      name: 'Book XVI (From Noah to the Kings)',
      shortName: 'Book XVI',
      description:
          'Progress of the City of God from Abraham to David; Babel, circumcision, and Old Testament prophecies.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book16.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book17',
      name: 'Book XVII (The Prophets & King David)',
      shortName: 'Book XVII',
      description:
          'The history of the City of God under the monarchy and prophets; the Davidic Covenant and Messianic Psalms.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book17.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book18',
      name: 'Book XVIII (Parallel Histories of Two Cities)',
      shortName: 'Book XVIII',
      description:
          'Synchronous history of earthly empires (Assyria, Greece, Rome) and the City of God up to Christ.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book18.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book19',
      name: 'Book XIX (Peace & the Supreme Good)',
      shortName: 'Book XIX',
      description:
          'The supreme good (summum bonum); definitions of justice, commonwealth, and true peace (tranquillitas ordinis).',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book19.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book20',
      name: 'Book XX (The Last Judgment)',
      shortName: 'Book XX',
      description:
          'Prophecies of the Final Judgment in the Old and New Testaments; bodily resurrection and Christ as Judge.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book20.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book21',
      name: 'Book XXI (Punishment of the Earthly City)',
      shortName: 'Book XXI',
      description:
          'The reality and justice of eternal punishment, hellfire, and refutation of universal salvation.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book21.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book22',
      name: 'Book XXII (Eternal Bliss of City of God)',
      shortName: 'Book XXII',
      description:
          'The resurrection of the flesh, miracles worked by Christ and the martyrs, beatific vision, and the eternal Sabbath.',
      assetPath: 'assets/catechism/json/augustine_city_of_god_book22.json',
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
      const LibraryBookItem(
        id: 'augustine_confessions',
        title: 'The Confessions',
        subtitle: 'Confessiones (Trans. Edward Bouverie Pusey, 1838)',
        category: 'Church Fathers',
        author: 'St. Augustine of Hippo (Trans. E. B. Pusey)',
        description:
            'Written c. 397–400 AD. The world\'s first spiritual autobiography tracing Augustine\'s journey from sinful youth and Manichaeism to his conversion at Milan ("Tolle, lege"), the life and death of St. Monica, and profound reflections on memory, time, and creation.',
        volumes: confessionsVolumes,
      ),
      const LibraryBookItem(
        id: 'augustine_city_of_god',
        title: 'The City of God',
        subtitle: 'De Civitate Dei contra Paganos (Trans. Marcus Dods, 1871)',
        category: 'Church Fathers',
        author: 'St. Augustine of Hippo (Trans. Marcus Dods)',
        description:
            'Written c. 413–426 AD following the sack of Rome. Augustine\'s magnum opus in 22 books contrasting the City of God (founded on the love of God) with the City of Man (founded on the love of self), expounding providence, Christian history, true peace, and eternal beatitude.',
        volumes: cityOfGodVolumes,
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
