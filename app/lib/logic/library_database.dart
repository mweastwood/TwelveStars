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

  static const List<BaltimoreVolume> polycarpVolumes = [
    BaltimoreVolume(
      volumeKey: 'philippians',
      name: 'Epistle to the Philippians',
      shortName: 'Philippians',
      description:
          'Written c. 110–140 AD. Pastoral exhortation on righteousness, faith, charity, and steadfastness in Christ against early heresies.',
      assetPath: 'assets/catechism/json/polycarp_philippians_lightfoot.json',
    ),
    BaltimoreVolume(
      volumeKey: 'martyrdom',
      name: 'The Martyrdom of Polycarp',
      shortName: 'Martyrdom',
      description:
          'Written c. 155–160 AD by the Church of Smyrna. The earliest surviving authentic account of Christian martyrdom outside the New Testament ("Eighty and six years have I served Him, and He never did me any injury: how then can I blaspheme my King and my Saviour?").',
      assetPath: 'assets/catechism/json/polycarp_martyrdom_lightfoot.json',
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

  static const List<BaltimoreVolume> cyrilVolumes = [
    BaltimoreVolume(
      volumeKey: 'vol1',
      name: 'Vol. I (Procatechesis & Faith)',
      shortName: 'Vol. I',
      description:
          'Preparation for illumination, repentance, remission of sins, baptism, the 10 doctrinal points, and living faith.',
      assetPath: 'assets/catechism/json/cyril_catechetical_lectures_vol1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'vol2',
      name: 'Vol. II (The Father & The Son)',
      shortName: 'Vol. II',
      description:
          'Exposition of the Jerusalem Creed: God the Father Almighty, Maker of heaven and earth, and the eternal divinity of the Son.',
      assetPath: 'assets/catechism/json/cyril_catechetical_lectures_vol2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'vol3',
      name: 'Vol. III (Incarnation, Spirit & Church)',
      shortName: 'Vol. III',
      description:
          'The Virgin Birth, the Passion and Cross, Resurrection, Ascension, Second Coming, Holy Spirit, Catholic Church, and the resurrection of the body.',
      assetPath: 'assets/catechism/json/cyril_catechetical_lectures_vol3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'vol4',
      name: 'Vol. IV (The Mysteries)',
      shortName: 'Vol. IV',
      description:
          'Post-baptismal lectures on the sacred mysteries: the rites of Baptism, Holy Chrism (Confirmation), the Real Presence in the Eucharist, and the Divine Liturgy.',
      assetPath: 'assets/catechism/json/cyril_catechetical_lectures_vol4.json',
    ),
  ];

  static const List<BaltimoreVolume> gregoryVolumes = [
    BaltimoreVolume(
      volumeKey: 'oration1',
      name: 'Oration I (Against the Eunomians)',
      shortName: 'Oration I',
      description:
          'On the qualifications, dispositions, and reverence required for theological contemplation.',
      assetPath:
          'assets/catechism/json/gregory_theological_orations_oration1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'oration2',
      name: 'Oration II (On the Doctrine of God)',
      shortName: 'Oration II',
      description:
          'On the nature, majesty, and incomprehensibility of the divine essence.',
      assetPath:
          'assets/catechism/json/gregory_theological_orations_oration2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'oration3',
      name: 'Oration III (On the Son — I)',
      shortName: 'Oration III',
      description:
          'Refutation of Eunomian objections; defense of the eternal generation and co-equality of the Son.',
      assetPath:
          'assets/catechism/json/gregory_theological_orations_oration3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'oration4',
      name: 'Oration IV (On the Son — II)',
      shortName: 'Oration IV',
      description:
          'Exegesis of biblical titles and scriptural passages concerning Christ\'s divinity and humanity.',
      assetPath:
          'assets/catechism/json/gregory_theological_orations_oration4.json',
    ),
    BaltimoreVolume(
      volumeKey: 'oration5',
      name: 'Oration V (On the Holy Spirit)',
      shortName: 'Oration V',
      description:
          'The definitive defense of the consubstantial divinity, procession, and co-worship of the Holy Spirit.',
      assetPath:
          'assets/catechism/json/gregory_theological_orations_oration5.json',
    ),
  ];

  static const List<BaltimoreVolume> gregoryPastoralRuleVolumes = [
    BaltimoreVolume(
      volumeKey: 'book1',
      name: 'Book I (The Pastoral Office)',
      shortName: 'Book I',
      description:
          'How one ought to arrive at the office of spiritual leadership; motives, qualifications, and the peril of unworthy ambition.',
      assetPath: 'assets/catechism/json/gregory_pastoral_rule_book1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book2',
      name: 'Book II (The Life of the Pastor)',
      shortName: 'Book II',
      description:
          'The personal conduct, interior life, compassion, contemplation, and moral vigilance required of a pastor.',
      assetPath: 'assets/catechism/json/gregory_pastoral_rule_book2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book3',
      name: 'Book III (Discretion in Preaching)',
      shortName: 'Book III',
      description:
          'Discretion and spiritual discernment in exhorting diverse classes and dispositions of people.',
      assetPath: 'assets/catechism/json/gregory_pastoral_rule_book3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book4',
      name: 'Book IV (Humility & Self-Examination)',
      shortName: 'Book IV',
      description:
          'How the pastor, having discharged his duty well, must enter into himself to guard against vain glory and pride.',
      assetPath: 'assets/catechism/json/gregory_pastoral_rule_book4.json',
    ),
  ];

  static const List<BaltimoreVolume> chrysostomOnThePriesthoodVolumes = [
    BaltimoreVolume(
      volumeKey: 'book1',
      name: 'Book I (Youth & the Holy Scheme)',
      shortName: 'Book I',
      description:
          'Early friendship with Basil, proposal for shared ascetical life, rumors of ordination, and Chrysostom avoiding consecration.',
      assetPath:
          'assets/catechism/json/chrysostom_on_the_priesthood_book1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book2',
      name: 'Book II (The Pastoral Office & Shepherding)',
      shortName: 'Book II',
      description:
          'Justification of his action; the immense spiritual responsibility, perils, and discernment demanded of the shepherd of souls.',
      assetPath:
          'assets/catechism/json/chrysostom_on_the_priesthood_book2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book3',
      name: 'Book III (The Sublime Dignity & Eucharistic Mystery)',
      shortName: 'Book III',
      description:
          'The heavenly dignity and terrors of the sacred priesthood, the Holy Sacrifice of the Altar, power of the keys, and perils of unworthy candidates.',
      assetPath:
          'assets/catechism/json/chrysostom_on_the_priesthood_book3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book4',
      name: 'Book IV (The Ministry of the Word & Refuting Heresy)',
      shortName: 'Book IV',
      description:
          'Necessity of sound doctrine and pastoral preaching; wielding Scripture to heal souls and defend against error.',
      assetPath:
          'assets/catechism/json/chrysostom_on_the_priesthood_book4.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book5',
      name: 'Book V (Trials & Temptations of Preaching)',
      shortName: 'Book V',
      description:
          'Temptations facing the preacher: flattery, popular applause, censure, and the discipline of seeking God\'s glory over human praise.',
      assetPath:
          'assets/catechism/json/chrysostom_on_the_priesthood_book5.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book6',
      name: 'Book VI (Purity of Heart & Final Reconciliation)',
      shortName: 'Book VI',
      description:
          'The angelic sanctity demanded of secular priests versus hermits, spiritual vigilance in the world, and prayerful conclusion.',
      assetPath:
          'assets/catechism/json/chrysostom_on_the_priesthood_book6.json',
    ),
  ];

  static const List<BaltimoreVolume> damasceneOrthodoxFaithVolumes = [
    BaltimoreVolume(
      volumeKey: 'book1',
      name: 'Book I (The Godhead & the Trinity)',
      shortName: 'Book I',
      description:
          'Chapters 1–14: On the incomprehensibility of God, divine nature and attributes, Trinity of Persons, generation of the Son, and procession of the Holy Spirit.',
      assetPath: 'assets/catechism/json/damascene_orthodox_faith_book1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book2',
      name: 'Book II (Creation, Angels & Man)',
      shortName: 'Book II',
      description:
          'Chapters 1–30: On creation ex nihilo, angelic hierarchy, devil and demons, visible creation, human nature (soul and body), passions, free will, and divine providence.',
      assetPath: 'assets/catechism/json/damascene_orthodox_faith_book2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book3',
      name: 'Book III (Incarnation & Christology)',
      shortName: 'Book III',
      description:
          'Chapters 1–29: On the Divine Economy, the Incarnation, two natures in Christ, hypostatic union, communication of idioms, two wills and operations, and the Theotokos.',
      assetPath: 'assets/catechism/json/damascene_orthodox_faith_book3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book4',
      name: 'Book IV (Resurrection, Sacraments & Icons)',
      shortName: 'Book IV',
      description:
          'Chapters 1–27: On the Resurrection, faith, Baptism, Holy Eucharist, Holy Cross, worship toward the East, veneration of sacred icons and relics, Scripture, and virginity.',
      assetPath: 'assets/catechism/json/damascene_orthodox_faith_book4.json',
    ),
  ];

  static const List<BaltimoreVolume> ambroseVolumes = [
    BaltimoreVolume(
      volumeKey: 'on_the_mysteries',
      name: 'On the Mysteries (De Mysteriis)',
      shortName: 'On the Mysteries',
      description:
          'Nine mystagogical instructions for the newly baptized explaining the rites of Christian initiation: Baptism, the spiritual seal of Confirmation, and the Eucharistic sacrifice.',
      assetPath: 'assets/catechism/json/ambrose_on_the_mysteries.json',
    ),
    BaltimoreVolume(
      volumeKey: 'on_the_sacraments',
      name: 'On the Sacraments (De Sacramentis)',
      shortName: 'On the Sacraments',
      description:
          'Six post-baptismal sermons expounding the sacramental mysteries: the baptismal font, chrismation, the Eucharistic canon, consecration by Christ\'s words, and the Lord\'s Prayer.',
      assetPath: 'assets/catechism/json/ambrose_on_the_sacraments.json',
    ),
  ];

  static const List<BaltimoreVolume> leoGreatVolumes = [
    BaltimoreVolume(
      volumeKey: 'tome_and_letters',
      name: 'Vol. I (The Tome to Flavian & Christological Letters)',
      shortName: 'Vol. I (Tome & Letters)',
      description:
          'The definitive dogmatic Tome to Flavian defining the two natures in one person of Christ, acclaimed at Chalcedon, with key Christological letters to Emperor Theodosius, Empress Pulcheria, and the Monks of Palestine.',
      assetPath: 'assets/catechism/json/leo_tome_and_letters.json',
    ),
    BaltimoreVolume(
      volumeKey: 'selected_sermons',
      name: 'Vol. II (Selected Festal Sermons & Epistles on Church Order)',
      shortName: 'Vol. II (Sermons & Epistles)',
      description:
          'Celebrated sermons on the Nativity, Epiphany, Lent, Passion, Resurrection, Ascension, and Petrine Primacy, alongside pastoral epistles on Church order and episcopal unity.',
      assetPath: 'assets/catechism/json/leo_selected_sermons.json',
    ),
  ];

  static const List<BaltimoreVolume> cyprianVolumes = [
    BaltimoreVolume(
      volumeKey: 'unity_and_lapsed',
      name: 'Vol. I: On the Unity of the Church & The Lapsed',
      shortName: 'Vol. I (Unity & The Lapsed)',
      description:
          'Treatise I on the unity of the Catholic Church, the Chair of Peter, and schism, together with Treatise III on the reconciliation of the lapsed after persecution.',
      assetPath: 'assets/catechism/json/cyprian_unity_and_lapsed.json',
    ),
    BaltimoreVolume(
      volumeKey: 'prayer_and_treatises',
      name: 'Vol. II: On the Lord\'s Prayer & Christian Life',
      shortName: 'Vol. II (Lord\'s Prayer & Treatises)',
      description:
          'Treatise IV commenting on the Lord\'s Prayer, Treatise VII on mortality during plague, and Treatise VIII on works and almsgiving.',
      assetPath: 'assets/catechism/json/cyprian_prayer_and_treatises.json',
    ),
  ];

  static const List<BaltimoreVolume> aquinasCompendiumVolumes = [
    BaltimoreVolume(
      volumeKey: 'part1',
      name: 'Part I (On Faith)',
      shortName: 'Part I',
      description:
          'Treatise on the theological virtue of Faith: the Trinity, Creation, Providence, the Fall, Incarnation, Sacraments, and the General Judgment (Chapters 1–246).',
      assetPath:
          'assets/catechism/json/aquinas_compendium_of_theology_part1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'part2',
      name: 'Part II (On Hope)',
      shortName: 'Part II',
      description:
          'Treatise on the theological virtue of Hope, prayer, and the seven petitions of the Lord\'s Prayer (Chapters 1–10).',
      assetPath:
          'assets/catechism/json/aquinas_compendium_of_theology_part2.json',
    ),
  ];

  static const List<BaltimoreVolume> aquinasCatecheticalVolumes = [
    BaltimoreVolume(
      volumeKey: 'creed',
      name: 'Part I (The Apostles\' Creed)',
      shortName: 'The Creed',
      description:
          'Exposition of the Twelve Articles of Faith contained in the Apostles\' Creed.',
      assetPath: 'assets/catechism/json/aquinas_catechetical_creed.json',
    ),
    BaltimoreVolume(
      volumeKey: 'sacraments',
      name: 'Part II (The Sacraments)',
      shortName: 'Sacraments',
      description:
          'Treatise on the nature, necessity, minister, and effects of the Seven Sacraments.',
      assetPath: 'assets/catechism/json/aquinas_catechetical_sacraments.json',
    ),
    BaltimoreVolume(
      volumeKey: 'commandments',
      name: 'Part III (The Commandments)',
      shortName: 'Commandments',
      description:
          'Exposition of the Two Precepts of Charity and the Ten Commandments of the Decalogue.',
      assetPath: 'assets/catechism/json/aquinas_catechetical_commandments.json',
    ),
    BaltimoreVolume(
      volumeKey: 'prayer',
      name: 'Part IV (The Lord\'s Prayer)',
      shortName: 'Lord\'s Prayer',
      description:
          'Exposition of the excellence, qualities, and Seven Petitions of the Our Father.',
      assetPath: 'assets/catechism/json/aquinas_catechetical_prayer.json',
    ),
    BaltimoreVolume(
      volumeKey: 'hail_mary',
      name: 'Part V (The Hail Mary)',
      shortName: 'Hail Mary',
      description:
          'Exposition of the Angelic Salutation, its triple dignity, and the fullness of grace.',
      assetPath: 'assets/catechism/json/aquinas_catechetical_hail_mary.json',
    ),
  ];

  static const List<BaltimoreVolume> anselmCurDeusHomoVolumes = [
    BaltimoreVolume(
      volumeKey: 'book1',
      name: 'Book I: The Necessity of Redemption',
      shortName: 'Book I',
      description:
          'Anselm and Boso examine the objections of unbelievers, showing the necessity of satisfaction for sin and why salvation is impossible without a Savior.',
      assetPath: 'assets/catechism/json/anselm_cur_deus_homo_book1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'book2',
      name: 'Book II: The God-Man and Atonement',
      shortName: 'Book II',
      description:
          'Demonstrates why only a person who is both truly God and truly man can offer the infinite satisfaction required to redeem mankind.',
      assetPath: 'assets/catechism/json/anselm_cur_deus_homo_book2.json',
    ),
  ];

  static const List<BaltimoreVolume> devoutLifeVolumes = [
    BaltimoreVolume(
      volumeKey: 'part1',
      name: 'Part I (First Desire for Devotion)',
      shortName: 'Part I',
      description:
          'Defines true devotion, general purification from mortal and venial sin, affections for evil things, and the 10 foundational meditations.',
      assetPath: 'assets/catechism/json/sales_devout_life_part1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'part2',
      name: 'Part II (Prayer & Sacraments)',
      shortName: 'Part II',
      description:
          'Instructions on the presence of God, invocations, meditation techniques, spiritual dryness, morning and evening prayers, Holy Mass, Confession, and frequent reception of Holy Communion.',
      assetPath: 'assets/catechism/json/sales_devout_life_part2.json',
    ),
    BaltimoreVolume(
      volumeKey: 'part3',
      name: 'Part III (Practice of Virtues)',
      shortName: 'Part III',
      description:
          'Practical directives for daily life: choice of virtues, patience, exterior and interior humility, meekness, gentleness, obedience, chastity, holy friendships, mortification, and modesty in attire and speech.',
      assetPath: 'assets/catechism/json/sales_devout_life_part3.json',
    ),
    BaltimoreVolume(
      volumeKey: 'part4',
      name: 'Part IV (Against Ordinary Temptations)',
      shortName: 'Part IV',
      description:
          'Strategies for spiritual combat: despising temptations, handling anxiety and disquietude, overcoming sadness, managing consolations and spiritual dryness, and examination during trials.',
      assetPath: 'assets/catechism/json/sales_devout_life_part4.json',
    ),
    BaltimoreVolume(
      volumeKey: 'part5',
      name: 'Part V (Renewing the Soul in Devotion)',
      shortName: 'Part V',
      description:
          'Annual spiritual renewal and retreat: examination of spiritual progress towards God, self, and neighbor; renewal of good resolutions; final protestations; and perseverance in holiness.',
      assetPath: 'assets/catechism/json/sales_devout_life_part5.json',
    ),
  ];

  static const List<BaltimoreVolume> teresaWayOfPerfectionVolumes = [
    BaltimoreVolume(
      volumeKey: 'part1',
      name: 'Vol. I: The Way of Prayer & Evangelical Counsels',
      shortName: 'Vol. I',
      description:
          'Motives for founding St. Joseph\'s, the three evangelical foundations (detachment, mutual love, humility), mental vs. vocal prayer, and preparation for the spiritual journey (Chapters 1–18).',
      assetPath: 'assets/catechism/json/teresa_way_perfection_part1.json',
    ),
    BaltimoreVolume(
      volumeKey: 'part2',
      name: 'Vol. II: Contemplation & Meditation on the Lord\'s Prayer',
      shortName: 'Vol. II',
      description:
          'The living water, prayer of recollection, prayer of quiet, contemplation, and clause-by-clause commentary on the Our Father (Chapters 19–42).',
      assetPath: 'assets/catechism/json/teresa_way_perfection_part2.json',
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
        id: 'polycarp_writings',
        title: 'Epistle & Martyrdom of St. Polycarp',
        subtitle:
            'Epistle to the Philippians & Martyrdom of Polycarp (Trans. J. B. Lightfoot, 1891)',
        category: 'Apostolic Fathers',
        author:
            'St. Polycarp of Smyrna / Church of Smyrna (Trans. J. B. Lightfoot)',
        description:
            'Writings related to St. Polycarp of Smyrna (c. 69–156 AD), Bishop of Smyrna and disciple of St. John the Apostle. Includes his pastoral Epistle to the Philippians and the Martyrdom of Polycarp, the earliest surviving authentic account of Christian martyrdom outside the New Testament.',
        volumes: polycarpVolumes,
      ),
      const LibraryBookItem(
        id: 'diognetus_lightfoot',
        title: 'The Epistle to Diognetus',
        subtitle: 'Letter to Diognetus (Trans. J. B. Lightfoot, 1891)',
        category: 'Apostolic Fathers',
        author: 'The Apostolic Fathers (Trans. J. B. Lightfoot)',
        description:
            'An early Christian apologetic work (c. 130–200 AD) addressed to Diognetus, defending Christianity against paganism and Judaism, and offering a profound exposition of the Christian life in the world ("what the soul is in the body, that the Christians are in the world") and the Incarnation.',
        defaultAssetPath: 'assets/catechism/json/diognetus_lightfoot.json',
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
        id: 'justin_dialogue_trypho',
        title: 'Dialogue with Trypho',
        subtitle:
            'Dialogus cum Tryphone Judaeo (Trans. Marcus Dods & George Reith, 1885)',
        category: 'Early Apologists',
        author: 'St. Justin Martyr (Trans. Marcus Dods & George Reith)',
        description:
            'Written c. 155–160 AD. The most extensive 2nd-century patristic dialogue exploring Old Testament typology, Messianic prophecies, the divinity of Christ the Logos, the abrogation of the Old Law, and the Church as the new spiritual Israel.',
        defaultAssetPath:
            'assets/catechism/json/justin_dialogue_trypho_dods.json',
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
        id: 'athanasius_life_of_anthony',
        title: 'Life of St. Anthony',
        subtitle: 'Vita Antonii (Trans. Archibald Robertson, 1892)',
        category: 'Church Fathers',
        author: 'St. Athanasius of Alexandria (Trans. Archibald Robertson)',
        description:
            'Written c. 357 AD by the Patriarch of Alexandria shortly after the death of St. Anthony the Great. The foundational spiritual biography that sparked the Christian monastic movement across the East and West and inspired the conversion of St. Augustine.',
        defaultAssetPath:
            'assets/catechism/json/athanasius_life_of_anthony.json',
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
      const LibraryBookItem(
        id: 'cyril_catechetical_lectures',
        title: 'Catechetical Lectures',
        subtitle: 'Catecheses (Trans. Edwin Hamilton Gifford, 1893)',
        category: 'Church Fathers',
        author: 'St. Cyril of Jerusalem (Trans. E. H. Gifford)',
        description:
            'Delivered c. 348–350 AD in the Church of the Holy Sepulchre. St. Cyril\'s 24 lectures form the Church\'s classic manual of baptismal catechesis, expounding the Jerusalem Creed, Christian moral life, and the Mystagogical rites of Baptism, Chrism, and the Holy Eucharist.',
        volumes: cyrilVolumes,
      ),
      const LibraryBookItem(
        id: 'basil_on_the_holy_spirit',
        title: 'On the Holy Spirit',
        subtitle: 'De Spiritu Sancto (Trans. Blomfield Jackson, 1895)',
        category: 'Church Fathers',
        author: 'St. Basil the Great (Trans. Blomfield Jackson)',
        description:
            'Written c. 375 AD to St. Amphilochius of Iconium. The classic patristic treatise defending the consubstantial divinity and co-equal worship of the Holy Spirit with the Father and the Son, expounding the doxology, baptismal formula, and unwritten Apostolic Tradition.',
        defaultAssetPath: 'assets/catechism/json/basil_on_the_holy_spirit.json',
      ),
      const LibraryBookItem(
        id: 'gregory_theological_orations',
        title: 'The Five Theological Orations',
        subtitle: 'Orations 27–31 (Trans. Browne & Swallow, 1894)',
        category: 'Church Fathers',
        author: 'St. Gregory of Nazianzus (Trans. Browne & Swallow)',
        description:
            'Delivered c. 380 AD in Constantinople by "Gregory the Theologian." The definitive patristic exposition and defense of the Holy Trinity, the eternal divinity of the Son, and the consubstantial deity and procession of the Holy Spirit.',
        volumes: gregoryVolumes,
      ),
      const LibraryBookItem(
        id: 'chrysostom_on_the_priesthood',
        title: 'On the Priesthood',
        subtitle: 'De Sacerdotio (Trans. W. R. W. Stephens, 1889)',
        category: 'Church Fathers',
        author: 'St. John Chrysostom (Trans. W. R. W. Stephens)',
        description:
            'Written c. 386–390 AD. The classic patristic masterwork on the sacred dignity, moral gravity, perils, and pastoral duties of the Catholic priesthood, expounding the Eucharistic Sacrifice, spiritual warfare, and the ministry of preaching.',
        volumes: chrysostomOnThePriesthoodVolumes,
      ),
      const LibraryBookItem(
        id: 'ambrose_mysteries_and_sacraments',
        title: 'On the Mysteries & On the Sacraments',
        subtitle:
            'De Mysteriis & De Sacramentis (Trans. Thompson & Srawley, 1919)',
        category: 'Church Fathers',
        author: 'St. Ambrose of Milan (Trans. T. Thompson & J. H. Srawley)',
        description:
            'Delivered c. 387–390 AD by the Bishop of Milan and Doctor of the Church. Foundational mystagogical works of the Western Church expounding Christian initiation: Baptism, Confirmation (the spiritual seal), the Lord\'s Prayer, and the Real Presence and Sacrifice in the Holy Eucharist.',
        volumes: ambroseVolumes,
      ),
      const LibraryBookItem(
        id: 'vincent_commonitory',
        title: 'The Commonitory',
        subtitle:
            'For the Antiquity and Universality of the Catholic Faith (Trans. C. A. Heurtley, 1894)',
        category: 'Church Fathers',
        author: 'St. Vincent of Lérins (Trans. C. A. Heurtley)',
        description:
            'Written c. 434 AD on the island of Lérins. The classic patristic masterwork establishing the Vincentian Canon on Sacred Tradition ("quod ubique, quod semper, quod ab omnibus creditum est") and formulating the orthodox standard for the legitimate organic development of Christian doctrine.',
        defaultAssetPath: 'assets/catechism/json/vincent_commonitory.json',
      ),
      const LibraryBookItem(
        id: 'leo_great_tome_and_sermons',
        title: 'The Tome & Selected Works',
        subtitle:
            'Tome to Flavian, Sermons & Letters (Trans. Charles Feltoe, NPNF II/12)',
        category: 'Church Fathers',
        author: 'Pope St. Leo the Great (Trans. Charles Feltoe)',
        description:
            'Written in the 5th century by the Pope and Doctor of the Church. Features the definitive dogmatic Tome to Flavian acclaimed at Chalcedon alongside celebrated sermons on the Incarnation and Petrine primacy.',
        volumes: leoGreatVolumes,
      ),
      const LibraryBookItem(
        id: 'gregory_pastoral_rule',
        title: 'Pastoral Rule',
        subtitle: 'Liber Regulae Pastoralis (Trans. James Barmby, 1895)',
        category: 'Church Fathers',
        author: 'Pope St. Gregory the Great (Trans. James Barmby)',
        description:
            'Written c. 590 AD by Pope St. Gregory the Great upon his accession to the Papacy. The premier 4-book guide for bishops, priests, and spiritual directors on pastoral care, discretionary preaching to diverse souls, and the preservation of humility.',
        volumes: gregoryPastoralRuleVolumes,
      ),
      const LibraryBookItem(
        id: 'cyprian_unity_of_church',
        title: 'On the Unity of the Church & Treatises',
        subtitle:
            'De Catholicae Ecclesiae Unitate (Trans. Robert Wallis, ANF Vol. 5)',
        category: 'Patristics',
        author: 'St. Cyprian of Carthage (Trans. Robert Ernest Wallis)',
        description:
            'Written in 251 AD by the Bishop and Martyr of Carthage. The foundational early patristic treatise on the unity of the Church and the Chair of Peter, together with his commentary on the Lord\'s Prayer.',
        volumes: cyprianVolumes,
      ),
      const LibraryBookItem(
        id: 'john_damascene_orthodox_faith',
        title: 'An Exact Exposition of the Orthodox Faith',
        subtitle: 'De Fide Orthodoxa (Trans. S. D. F. Salmond, NPNF II/9)',
        category: 'Patristics',
        author: 'St. John Damascene (Trans. S. D. F. Salmond)',
        description:
            'Written in the 8th century by the last of the Eastern Fathers and Doctor of the Church. The monumental systematic summa of Christian dogma covering the Trinity, Creation, Christology, Sacraments, and Holy Icons.',
        volumes: damasceneOrthodoxFaithVolumes,
      ),
      const LibraryBookItem(
        id: 'anselm_proslogion',
        title: 'Proslogion',
        subtitle:
            'Faith Seeking Understanding (Trans. Sidney Norton Deane, 1903)',
        category: 'Doctors of the Church',
        author: 'St. Anselm of Canterbury (Trans. Sidney Norton Deane)',
        description:
            'Written c. 1077–1078 AD. The classic philosophical and devotional masterpiece formulating the ontological argument for the existence of God ("that than which nothing greater can be conceived") and exploring the divine attributes through prayer and reason.',
        defaultAssetPath: 'assets/catechism/json/anselm_proslogion.json',
      ),
      const LibraryBookItem(
        id: 'anselm_cur_deus_homo',
        title: 'Cur Deus Homo',
        subtitle: 'Why God Became Man (Trans. Sidney Norton Deane, 1903)',
        category: 'Doctors of the Church',
        author: 'St. Anselm of Canterbury (Trans. Sidney Norton Deane)',
        description:
            'Written c. 1098 AD. The foundational scholastic treatise in soteriology, structured as a dialogue between Anselm and Boso, developing the satisfaction theory of the Atonement and explaining the necessity of the Incarnation.',
        volumes: anselmCurDeusHomoVolumes,
      ),
      const LibraryBookItem(
        id: 'john_cross_ascent_mount_carmel',
        title: 'Ascent of Mount Carmel',
        subtitle:
            'Subida del Monte Carmelo (Trans. David Lewis, Rev. Benedict Zimmerman, O.C.D.)',
        category: 'Doctors of the Church / Spiritual Classics',
        author: 'St. John of the Cross',
        description:
            'c. 1578–1585. St. John of the Cross\'s classic systematic treatise on active purification of the senses and spiritual faculties (intellect, memory, and will) through the theological virtues of Faith, Hope, and Charity leading to divine union.',
        defaultAssetPath:
            'assets/catechism/json/john_cross_ascent_mount_carmel.json',
      ),
      const LibraryBookItem(
        id: 'john_cross_dark_night_soul',
        title: 'Dark Night of the Soul',
        subtitle:
            'Noche Oscura del Alma (Trans. David Lewis, Rev. Benedict Zimmerman, O.C.D.)',
        category: 'Doctors of the Church / Spiritual Classics',
        author: 'St. John of the Cross',
        description:
            'c. 1584–1586. The companion masterpiece on passive purification of the sensory and spiritual appetites, guiding the soul through dark contemplation and the ten steps of the ladder of divine love into mystical union with God.',
        defaultAssetPath:
            'assets/catechism/json/john_cross_dark_night_soul.json',
      ),
      const LibraryBookItem(
        id: 'aquinas_compendium_of_theology',
        title: 'Compendium of Theology',
        subtitle: 'Compendium Theologiae (Trans. Cyril Vollert, S.J., 1947)',
        category: 'Doctors of the Church',
        author: 'St. Thomas Aquinas (Trans. Cyril Vollert)',
        description:
            'Written c. 1273 by the Angelic Doctor. A concise, systematic handbook of Catholic theology organized around the Theological Virtues (Faith and Hope), presenting the essence of the Summa Theologiae.',
        volumes: aquinasCompendiumVolumes,
      ),
      const LibraryBookItem(
        id: 'aquinas_catechetical_instructions',
        title: 'The Catechetical Instructions',
        subtitle:
            'Expositions on the Creed, Sacraments, Commandments & Prayer (Trans. Joseph B. Collins, 1939)',
        category: 'Doctors of the Church',
        author: 'St. Thomas Aquinas (Trans. Joseph B. Collins)',
        description:
            'Lenten sermon-conferences delivered in 1273 at Naples. Accessible, profound expositions of the Apostles\' Creed, the Seven Sacraments, the Ten Commandments, the Lord\'s Prayer, and the Hail Mary.',
        volumes: aquinasCatecheticalVolumes,
      ),
      const LibraryBookItem(
        id: 'montfort_true_devotion',
        title: 'True Devotion to Mary',
        subtitle:
            'Traité de la vraie dévotion (Trans. Fr. Frederick W. Faber, 1862)',
        category: 'Marian & Spiritual Classics',
        author: 'St. Louis-Marie de Montfort (Trans. Fr. Frederick W. Faber)',
        description:
            'Written 1712 (first published 1843). St. Louis de Montfort\'s crowning Catholic spiritual classic on Total Consecration to Jesus through Mary ("Holy Slavery of Love"), presenting the shortest, easiest, most secure, and most perfect path to total transformation in Christ.',
        defaultAssetPath: 'assets/catechism/json/montfort_true_devotion.json',
      ),
      const LibraryBookItem(
        id: 'benedict_rule',
        title: 'The Rule of St. Benedict',
        subtitle:
            'Regula Sancti Benedicti (Trans. Rev. Boniface Verheyen, O.S.B., 1928)',
        category: 'Monastic & Spiritual Classics',
        author:
            'St. Benedict of Nursia (Trans. Rev. Boniface Verheyen, O.S.B.)',
        description:
            'Written c. 516–530 AD at Monte Cassino. The foundational charter of Western monasticism and European Christian culture, establishing the rhythm of prayer, work, and community life ("Ora et Labora").',
        defaultAssetPath: 'assets/catechism/json/benedict_rule.json',
      ),
      const LibraryBookItem(
        id: 'francis_de_sales_devout_life',
        title: 'Introduction to the Devout Life',
        subtitle:
            'Introduction à la vie dévote (Trans. Allan Ross / Rivingtons)',
        category: 'Spiritual Classics',
        author: 'St. Francis de Sales (Trans. Allan Ross)',
        description:
            'Written in 1609 by the Bishop of Geneva and Doctor of the Church. The universal spiritual classic showing that authentic holiness is attainable and necessary for persons in every state of life.',
        volumes: devoutLifeVolumes,
      ),
      const LibraryBookItem(
        id: 'teresa_interior_castle',
        title: 'The Interior Castle',
        subtitle:
            'El Castillo Interior / Las Moradas (Trans. Benedictines of Stanbrook, 1906)',
        category: 'Spiritual Classics',
        author: 'St. Teresa of Ávila (Trans. Benedictines of Stanbrook)',
        description:
            'Written in 1577 by the Doctor of the Church. St. Teresa\'s definitive masterpiece on the interior journey through the Seven Mansions of the soul, from vocal prayer and purification to spiritual betrothal, transforming union, and the indwelling of the Most Holy Trinity.',
        defaultAssetPath: 'assets/catechism/json/teresa_interior_castle.json',
      ),
      const LibraryBookItem(
        id: 'teresa_way_of_perfection',
        title: 'The Way of Perfection',
        subtitle: 'Camino de Perfección (Trans. Benedictines of Stanbrook)',
        category: 'Spiritual Classics',
        author: 'St. Teresa of Ávila (Trans. Benedictines of Stanbrook)',
        description:
            'Written in 1566 by the Great Reformer of Carmel and Doctor of the Church. A masterwork on the practice of prayer, detachment, and love of neighbor, concluding with an exposition of the Our Father.',
        volumes: teresaWayOfPerfectionVolumes,
      ),
      const LibraryBookItem(
        id: 'kempis_imitation_of_christ',
        title: 'The Imitation of Christ',
        subtitle:
            'De Imitatione Christi (Trans. Richard Challoner / William Benham)',
        category: 'Spiritual Classics',
        author: 'Thomas à Kempis',
        description:
            'Written c. 1418–1427. The most widely read devotional classic in Christian history after Sacred Scripture, providing profound guidance on spiritual interiority, peace in trials, humility, the Royal Road of the Cross, and devout preparation for the Holy Eucharist.',
        defaultAssetPath:
            'assets/catechism/json/kempis_imitation_of_christ.json',
      ),
      const LibraryBookItem(
        id: 'bonaventure_minds_road_to_god',
        title: "The Mind's Road to God",
        subtitle: 'Itinerarium Mentis in Deum (Trans. George Boas, 1953)',
        category: 'Doctors of the Church',
        author: 'St. Bonaventure (Trans. George Boas)',
        description:
            'Written 1259 AD on Mount La Verna. The Seraphic Doctor\'s mystical and philosophical masterpiece charting the soul\'s ascent to God through six progressive stages of contemplation—from the vestiges in the universe and sensory world, through the divine image in the mind\'s natural faculties and renewed by grace, to the contemplation of divine unity (Being) and the Trinity (Goodness), culminating in ecstatic union and mystical rest in God.',
        defaultAssetPath:
            'assets/catechism/json/bonaventure_minds_road_to_god.json',
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
