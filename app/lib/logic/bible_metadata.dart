class BibleBook {
  final int bookNumber;
  final String bookName;
  final String abbrev;
  final int chaptersCount;
  final String category;
  final String testament;

  const BibleBook({
    required this.bookNumber,
    required this.bookName,
    required this.abbrev,
    required this.chaptersCount,
    required this.category,
    required this.testament,
  });
}

const List<BibleBook> catholicBooks = [
  // Old Testament - Pentateuch
  BibleBook(
    bookNumber: 1,
    bookName: 'Genesis',
    abbrev: 'GEN',
    chaptersCount: 50,
    category: 'Pentateuch',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 2,
    bookName: 'Exodus',
    abbrev: 'EXO',
    chaptersCount: 40,
    category: 'Pentateuch',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 3,
    bookName: 'Leviticus',
    abbrev: 'LEV',
    chaptersCount: 27,
    category: 'Pentateuch',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 4,
    bookName: 'Numbers',
    abbrev: 'NUM',
    chaptersCount: 36,
    category: 'Pentateuch',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 5,
    bookName: 'Deuteronomy',
    abbrev: 'DEU',
    chaptersCount: 34,
    category: 'Pentateuch',
    testament: 'Old Testament',
  ),

  // Old Testament - Historical
  BibleBook(
    bookNumber: 6,
    bookName: 'Joshua',
    abbrev: 'JOS',
    chaptersCount: 24,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 7,
    bookName: 'Judges',
    abbrev: 'JDG',
    chaptersCount: 21,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 8,
    bookName: 'Ruth',
    abbrev: 'RUT',
    chaptersCount: 4,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 9,
    bookName: '1 Samuel',
    abbrev: '1SA',
    chaptersCount: 31,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 10,
    bookName: '2 Samuel',
    abbrev: '2SA',
    chaptersCount: 24,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 11,
    bookName: '1 Kings',
    abbrev: '1KI',
    chaptersCount: 22,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 12,
    bookName: '2 Kings',
    abbrev: '2KI',
    chaptersCount: 25,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 13,
    bookName: '1 Chronicles',
    abbrev: '1CH',
    chaptersCount: 29,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 14,
    bookName: '2 Chronicles',
    abbrev: '2CH',
    chaptersCount: 36,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 15,
    bookName: 'Ezra',
    abbrev: 'EZR',
    chaptersCount: 10,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 16,
    bookName: 'Nehemiah',
    abbrev: 'NEH',
    chaptersCount: 13,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 17,
    bookName: 'Tobit',
    abbrev: 'TOB',
    chaptersCount: 14,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 18,
    bookName: 'Judith',
    abbrev: 'JDT',
    chaptersCount: 16,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 19,
    bookName: 'Esther',
    abbrev: 'EST',
    chaptersCount: 16,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 45,
    bookName: '1 Maccabees',
    abbrev: '1MA',
    chaptersCount: 16,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 46,
    bookName: '2 Maccabees',
    abbrev: '2MA',
    chaptersCount: 15,
    category: 'Historical Books',
    testament: 'Old Testament',
  ),

  // Old Testament - Wisdom
  BibleBook(
    bookNumber: 20,
    bookName: 'Job',
    abbrev: 'JOB',
    chaptersCount: 42,
    category: 'Wisdom Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 21,
    bookName: 'Psalms',
    abbrev: 'PSA',
    chaptersCount: 150,
    category: 'Wisdom Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 22,
    bookName: 'Proverbs',
    abbrev: 'PRO',
    chaptersCount: 31,
    category: 'Wisdom Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 23,
    bookName: 'Ecclesiastes',
    abbrev: 'ECC',
    chaptersCount: 12,
    category: 'Wisdom Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 24,
    bookName: 'Canticle of Canticles',
    abbrev: 'SNG',
    chaptersCount: 8,
    category: 'Wisdom Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 25,
    bookName: 'Wisdom',
    abbrev: 'WIS',
    chaptersCount: 19,
    category: 'Wisdom Books',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 26,
    bookName: 'Sirach',
    abbrev: 'SIR',
    chaptersCount: 51,
    category: 'Wisdom Books',
    testament: 'Old Testament',
  ),

  // Old Testament - Prophets
  BibleBook(
    bookNumber: 27,
    bookName: 'Isaiah',
    abbrev: 'ISA',
    chaptersCount: 66,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 28,
    bookName: 'Jeremiah',
    abbrev: 'JER',
    chaptersCount: 52,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 29,
    bookName: 'Lamentations',
    abbrev: 'LAM',
    chaptersCount: 5,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 30,
    bookName: 'Baruch',
    abbrev: 'BAR',
    chaptersCount: 6,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 31,
    bookName: 'Ezekiel',
    abbrev: 'EZK',
    chaptersCount: 48,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 32,
    bookName: 'Daniel',
    abbrev: 'DAN',
    chaptersCount: 14,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 33,
    bookName: 'Hosea',
    abbrev: 'HOS',
    chaptersCount: 14,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 34,
    bookName: 'Joel',
    abbrev: 'JOL',
    chaptersCount: 3,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 35,
    bookName: 'Amos',
    abbrev: 'AMO',
    chaptersCount: 9,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 36,
    bookName: 'Obadiah',
    abbrev: 'OBA',
    chaptersCount: 1,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 37,
    bookName: 'Jonah',
    abbrev: 'JON',
    chaptersCount: 4,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 38,
    bookName: 'Micah',
    abbrev: 'MIC',
    chaptersCount: 7,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 39,
    bookName: 'Nahum',
    abbrev: 'NAM',
    chaptersCount: 3,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 40,
    bookName: 'Habakkuk',
    abbrev: 'HAB',
    chaptersCount: 3,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 41,
    bookName: 'Zephaniah',
    abbrev: 'ZEP',
    chaptersCount: 3,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 42,
    bookName: 'Haggai',
    abbrev: 'HAG',
    chaptersCount: 2,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 43,
    bookName: 'Zechariah',
    abbrev: 'ZEC',
    chaptersCount: 14,
    category: 'Prophets',
    testament: 'Old Testament',
  ),
  BibleBook(
    bookNumber: 44,
    bookName: 'Malachi',
    abbrev: 'MAL',
    chaptersCount: 4,
    category: 'Prophets',
    testament: 'Old Testament',
  ),

  // New Testament - Gospels & Acts
  BibleBook(
    bookNumber: 49,
    bookName: 'Matthew',
    abbrev: 'MAT',
    chaptersCount: 28,
    category: 'Gospels & Acts',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 50,
    bookName: 'Mark',
    abbrev: 'MRK',
    chaptersCount: 16,
    category: 'Gospels & Acts',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 51,
    bookName: 'Luke',
    abbrev: 'LUK',
    chaptersCount: 24,
    category: 'Gospels & Acts',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 52,
    bookName: 'John',
    abbrev: 'JHN',
    chaptersCount: 21,
    category: 'Gospels & Acts',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 53,
    bookName: 'Acts',
    abbrev: 'ACT',
    chaptersCount: 28,
    category: 'Gospels & Acts',
    testament: 'New Testament',
  ),

  // New Testament - Epistles
  BibleBook(
    bookNumber: 54,
    bookName: 'Romans',
    abbrev: 'ROM',
    chaptersCount: 16,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 55,
    bookName: '1 Corinthians',
    abbrev: '1CO',
    chaptersCount: 16,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 56,
    bookName: '2 Corinthians',
    abbrev: '2CO',
    chaptersCount: 13,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 57,
    bookName: 'Galatians',
    abbrev: 'GAL',
    chaptersCount: 6,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 58,
    bookName: 'Ephesians',
    abbrev: 'EPH',
    chaptersCount: 6,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 59,
    bookName: 'Philippians',
    abbrev: 'PHP',
    chaptersCount: 4,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 60,
    bookName: 'Colossians',
    abbrev: 'COL',
    chaptersCount: 4,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 61,
    bookName: '1 Thessalonians',
    abbrev: '1TH',
    chaptersCount: 5,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 62,
    bookName: '2 Thessalonians',
    abbrev: '2TH',
    chaptersCount: 3,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 64,
    bookName: '1 Timothy',
    abbrev: '1TI',
    chaptersCount: 6,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 65,
    bookName: '2 Timothy',
    abbrev: '2TI',
    chaptersCount: 4,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 66,
    bookName: 'Titus',
    abbrev: 'TIT',
    chaptersCount: 3,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 67,
    bookName: 'Philemon',
    abbrev: 'PHM',
    chaptersCount: 1,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 68,
    bookName: 'Hebrews',
    abbrev: 'HEB',
    chaptersCount: 13,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 69,
    bookName: 'James',
    abbrev: 'JAM',
    chaptersCount: 5,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 70,
    bookName: '1 Peter',
    abbrev: '1PE',
    chaptersCount: 5,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 71,
    bookName: '2 Peter',
    abbrev: '2PE',
    chaptersCount: 3,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 72,
    bookName: '1 John',
    abbrev: '1JN',
    chaptersCount: 5,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 73,
    bookName: '2 John',
    abbrev: '2JN',
    chaptersCount: 1,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 74,
    bookName: '3 John',
    abbrev: '3JN',
    chaptersCount: 1,
    category: 'Epistles',
    testament: 'New Testament',
  ),
  BibleBook(
    bookNumber: 75,
    bookName: 'Jude',
    abbrev: 'JUD',
    chaptersCount: 1,
    category: 'Epistles',
    testament: 'New Testament',
  ),

  // New Testament - Prophecy
  BibleBook(
    bookNumber: 76,
    bookName: 'Revelation',
    abbrev: 'REV',
    chaptersCount: 22,
    category: 'Prophecy',
    testament: 'New Testament',
  ),
];

/// Map of uppercase Catholic Bible book abbreviations to [BibleBook] for O(1) constant lookup.
final Map<String, BibleBook> catholicBooksByAbbrev = Map.unmodifiable({
  for (final book in catholicBooks) book.abbrev.toUpperCase(): book,
});

/// Set of uppercase Catholic Bible book abbreviations for O(1) constant lookup.
final Set<String> catholicBookAbbrevs = Set.unmodifiable(
  catholicBooksByAbbrev.keys,
);

/// Map of Catholic Bible book number to [BibleBook] for O(1) constant lookup.
final Map<int, BibleBook> catholicBooksByNumber = Map.unmodifiable({
  for (final book in catholicBooks) book.bookNumber: book,
});

/// Canonical map of lowercase Scripture book names, Douay-Rheims titles,
/// and standard abbreviations to Catholic [BibleBook.bookNumber].
final Map<String, int> catholicBookAliases = Map.unmodifiable(() {
  final map = <String, int>{};
  for (final book in catholicBooks) {
    map[book.bookName.toLowerCase()] = book.bookNumber;
    map[book.abbrev.toLowerCase()] = book.bookNumber;
  }

  void alias(String a, int num) => map[a.toLowerCase()] = num;

  alias('gen', 1);
  alias('genesis', 1);
  alias('ex', 2);
  alias('exod', 2);
  alias('exodus', 2);
  alias('lev', 3);
  alias('leviticus', 3);
  alias('num', 4);
  alias('numbers', 4);
  alias('deut', 5);
  alias('deuteronomy', 5);
  alias('jos', 6);
  alias('josh', 6);
  alias('joshua', 6);
  alias('jdg', 7);
  alias('judg', 7);
  alias('judges', 7);
  alias('rut', 8);
  alias('ruth', 8);
  alias('1sa', 9);
  alias('1 sam', 9);
  alias('1sam', 9);
  alias('1 samuel', 9);
  alias('2sa', 10);
  alias('2 sam', 10);
  alias('2sam', 10);
  alias('2 samuel', 10);
  alias('1ki', 11);
  alias('1 ki', 11);
  alias('3 kings', 11);
  alias('3ki', 11);
  alias('1kings', 11);
  alias('1 kings', 11);
  alias('2ki', 12);
  alias('2 ki', 12);
  alias('4 kings', 12);
  alias('4ki', 12);
  alias('2kings', 12);
  alias('2 kings', 12);
  alias('1ch', 13);
  alias('1 chron', 13);
  alias('1 par', 13);
  alias('1 paralip', 13);
  alias('1 paralipomenon', 13);
  alias('2ch', 14);
  alias('2 chron', 14);
  alias('2 par', 14);
  alias('2 paralip', 14);
  alias('2 paralipomenon', 14);
  alias('ezr', 15);
  alias('esd', 15);
  alias('esdras', 15);
  alias('neh', 16);
  alias('nehemiah', 16);
  alias('tob', 17);
  alias('tobias', 17);
  alias('tobit', 17);
  alias('jdt', 18);
  alias('judith', 18);
  alias('est', 19);
  alias('esth', 19);
  alias('esther', 19);
  alias('job', 20);
  alias('psa', 21);
  alias('ps', 21);
  alias('pss', 21);
  alias('psalm', 21);
  alias('psalms', 21);
  alias('pro', 22);
  alias('prov', 22);
  alias('proverbs', 22);
  alias('ecc', 23);
  alias('eccl', 23);
  alias('eccles', 23);
  alias('ecclesiastes', 23);
  alias('sng', 24);
  alias('cant', 24);
  alias('song', 24);
  alias('canticle', 24);
  alias('canticles', 24);
  alias('song of songs', 24);
  alias('song of solomon', 24);
  alias('canticle of canticles', 24);
  alias('wis', 25);
  alias('wisd', 25);
  alias('wisdom', 25);
  alias('sir', 26);
  alias('ecclus', 26);
  alias('sirach', 26);
  alias('ecclesiasticus', 26);
  alias('isa', 27);
  alias('isaias', 27);
  alias('isaiah', 27);
  alias('jer', 28);
  alias('jeremias', 28);
  alias('jeremiah', 28);
  alias('lam', 29);
  alias('lamentations', 29);
  alias('bar', 30);
  alias('baruch', 30);
  alias('eze', 31);
  alias('ezek', 31);
  alias('ezekiel', 31);
  alias('dan', 32);
  alias('daniel', 32);
  alias('hos', 33);
  alias('osee', 33);
  alias('hosea', 33);
  alias('joe', 34);
  alias('joel', 34);
  alias('amo', 35);
  alias('amos', 35);
  alias('oba', 36);
  alias('obad', 36);
  alias('abdias', 36);
  alias('obadiah', 36);
  alias('jon', 37);
  alias('jonas', 37);
  alias('jonah', 37);
  alias('mic', 38);
  alias('micheas', 38);
  alias('micah', 38);
  alias('nah', 39);
  alias('nahum', 39);
  alias('hab', 40);
  alias('habacuc', 40);
  alias('habakkuk', 40);
  alias('zep', 41);
  alias('zeph', 41);
  alias('sophonias', 41);
  alias('zephaniah', 41);
  alias('hag', 42);
  alias('aggeus', 42);
  alias('haggai', 42);
  alias('zech', 43);
  alias('zacharias', 43);
  alias('zechariah', 43);
  alias('mal', 44);
  alias('malachias', 44);
  alias('malachi', 44);
  alias('1ma', 45);
  alias('1 mach', 45);
  alias('1mach', 45);
  alias('1 mac', 45);
  alias('1mac', 45);
  alias('1 macc', 45);
  alias('1macc', 45);
  alias('1 maccabees', 45);
  alias('2ma', 46);
  alias('2 mach', 46);
  alias('2mach', 46);
  alias('2 mac', 46);
  alias('2mac', 46);
  alias('2 macc', 46);
  alias('2macc', 46);
  alias('2 maccabees', 46);

  alias('mt', 49);
  alias('mat', 49);
  alias('matt', 49);
  alias('matthew', 49);
  alias('mk', 50);
  alias('mar', 50);
  alias('mark', 50);
  alias('lk', 51);
  alias('luk', 51);
  alias('luke', 51);
  alias('jn', 52);
  alias('joh', 52);
  alias('john', 52);
  alias('act', 53);
  alias('acts', 53);
  alias('rom', 54);
  alias('romans', 54);
  alias('1co', 55);
  alias('1 cor', 55);
  alias('1cor', 55);
  alias('1 corinthians', 55);
  alias('2co', 56);
  alias('2 cor', 56);
  alias('2cor', 56);
  alias('2 corinthians', 56);
  alias('gal', 57);
  alias('galatians', 57);
  alias('eph', 58);
  alias('ephesians', 58);
  alias('php', 59);
  alias('phil', 59);
  alias('philippians', 59);
  alias('col', 60);
  alias('colossians', 60);
  alias('1th', 61);
  alias('1 thes', 61);
  alias('1 thess', 61);
  alias('1thess', 61);
  alias('1 thessalonians', 61);
  alias('2th', 62);
  alias('2 thes', 62);
  alias('2 thess', 62);
  alias('2thess', 62);
  alias('2 thessalonians', 62);
  alias('1ti', 64);
  alias('1 tim', 64);
  alias('1tim', 64);
  alias('1 timothy', 64);
  alias('2ti', 65);
  alias('2 tim', 65);
  alias('2tim', 65);
  alias('2 timothy', 65);
  alias('tit', 66);
  alias('titus', 66);
  alias('phm', 67);
  alias('philem', 67);
  alias('philemon', 67);
  alias('heb', 68);
  alias('hebrews', 68);
  alias('jam', 69);
  alias('jas', 69);
  alias('james', 69);
  alias('1pe', 70);
  alias('1 pet', 70);
  alias('1pet', 70);
  alias('1 peter', 70);
  alias('2pe', 71);
  alias('2 pet', 71);
  alias('2pet', 71);
  alias('2 peter', 71);
  alias('1jn', 72);
  alias('1 jn', 72);
  alias('1 john', 72);
  alias('2jn', 73);
  alias('2 jn', 73);
  alias('2 john', 73);
  alias('3jn', 74);
  alias('3 jn', 74);
  alias('3 john', 74);
  alias('jud', 75);
  alias('jude', 75);
  alias('rev', 76);
  alias('apoc', 76);
  alias('apocalypse', 76);
  alias('revelation', 76);

  return map;
}());

/// Lowercase Scripture book abbreviation tokens (including trailing tokens of
/// numbered books such as `cor`, `sam`, `ki`, `thess`) used to avoid false
/// sentence breaks on abbreviated citations like `1 Cor. 13:4` or `Matt. 5:3`.
const Set<String> catholicBookAbbreviationTokens = {
  'gen',
  'ex',
  'exod',
  'lev',
  'num',
  'deut',
  'jos',
  'josh',
  'jdg',
  'judg',
  'rut',
  'sam',
  'ki',
  'chron',
  'par',
  'paralip',
  'ezr',
  'esd',
  'neh',
  'tob',
  'jdt',
  'est',
  'esth',
  'ps',
  'pss',
  'psa',
  'prov',
  'pro',
  'ecc',
  'eccl',
  'eccles',
  'cant',
  'sng',
  'wis',
  'wisd',
  'sir',
  'ecclus',
  'isa',
  'jer',
  'lam',
  'bar',
  'eze',
  'ezek',
  'dan',
  'hos',
  'joe',
  'joel',
  'amo',
  'amos',
  'oba',
  'obad',
  'jon',
  'mic',
  'nah',
  'hab',
  'zep',
  'zeph',
  'hag',
  'zech',
  'mal',
  'mach',
  'macc',
  'mt',
  'matt',
  'mat',
  'mk',
  'mar',
  'lk',
  'luk',
  'jn',
  'joh',
  'act',
  'acts',
  'rom',
  'cor',
  'gal',
  'eph',
  'php',
  'phil',
  'col',
  'thes',
  'thess',
  'tim',
  'tit',
  'phm',
  'philem',
  'heb',
  'jas',
  'jam',
  'pet',
  'jud',
  'rev',
  'apoc',
};
