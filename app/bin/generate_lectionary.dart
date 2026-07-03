// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';

const Map<String, String> abbrevToBookName = {
  'Gn': 'Genesis',
  'Gen': 'Genesis',
  'Ex': 'Exodus',
  'Exo': 'Exodus',
  'Lv': 'Leviticus',
  'Lev': 'Leviticus',
  'Nm': 'Numbers',
  'Num': 'Numbers',
  'Dt': 'Deuteronomy',
  'Deut': 'Deuteronomy',
  'Jos': 'Joshua',
  'Josh': 'Joshua',
  'Jgs': 'Judges',
  'Judg': 'Judges',
  'Ru': 'Ruth',
  'Rut': 'Ruth',
  '1 Sm': '1 Samuel',
  '1 Sam': '1 Samuel',
  '2 Sm': '2 Samuel',
  '2 Sam': '2 Samuel',
  '1 Kgs': '1 Kings',
  '1 King': '1 Kings',
  '2 Kgs': '2 Kings',
  '2 King': '2 Kings',
  '1 Chr': '1 Chronicles',
  '1 Chron': '1 Chronicles',
  '2 Chr': '2 Chronicles',
  '2 Chron': '2 Chronicles',
  'Ezr': 'Ezra',
  'Neh': 'Nehemiah',
  'Tb': 'Tobit',
  'Tob': 'Tobit',
  'Jdt': 'Judith',
  'Jud': 'Judith',
  'Est': 'Esther',
  'Esth': 'Esther',
  '1 Mc': '1 Maccabees',
  '1 Macc': '1 Maccabees',
  '2 Mc': '2 Maccabees',
  '2 Macc': '2 Maccabees',
  'Jb': 'Job',
  'Ps': 'Psalms',
  'Pss': 'Psalms',
  'Psalm': 'Psalms',
  'Prv': 'Proverbs',
  'Prov': 'Proverbs',
  'Eccl': 'Ecclesiastes',
  'Ecc': 'Ecclesiastes',
  'Sg': 'Canticle of Canticles',
  'Song': 'Canticle of Canticles',
  'Cant': 'Canticle of Canticles',
  'Wis': 'Wisdom',
  'Sir': 'Sirach',
  'Ecclus': 'Sirach',
  'Is': 'Isaiah',
  'Isa': 'Isaiah',
  'Jer': 'Jeremiah',
  'Lam': 'Lamentations',
  'Bar': 'Baruch',
  'Ez': 'Ezekiel',
  'Ezek': 'Ezekiel',
  'Dn': 'Daniel',
  'Dan': 'Daniel',
  'Hos': 'Hosea',
  'Jl': 'Joel',
  'Am': 'Amos',
  'Ob': 'Obadiah',
  'Obad': 'Obadiah',
  'Jon': 'Jonah',
  'Mi': 'Micah',
  'Mic': 'Micah',
  'Na': 'Nahum',
  'Nah': 'Nahum',
  'Hb': 'Habakkuk',
  'Hab': 'Habakkuk',
  'Zep': 'Zephaniah',
  'Zeph': 'Zephaniah',
  'Hg': 'Haggai',
  'Hag': 'Haggai',
  'Zec': 'Zechariah',
  'Zech': 'Zechariah',
  'Mal': 'Malachi',
  'Mt': 'Matthew',
  'Matt': 'Matthew',
  'Mk': 'Mark',
  'Lk': 'Luke',
  'Jn': 'John',
  'Acts': 'Acts',
  'Rom': 'Romans',
  '1 Cor': '1 Corinthians',
  '2 Cor': '2 Corinthians',
  'Gal': 'Galatians',
  'Eph': 'Ephesians',
  'Phil': 'Philippians',
  'Col': 'Colossians',
  '1 Thes': '1 Thessalonians',
  '1 Thess': '1 Thessalonians',
  '2 Thes': '2 Thessalonians',
  '2 Thess': '2 Thessalonians',
  '1 Tm': '1 Timothy',
  '1 Tim': '1 Timothy',
  '2 Tm': '2 Timothy',
  '2 Tim': '2 Timothy',
  'Ti': 'Titus',
  'Tit': 'Titus',
  'Phlm': 'Philemon',
  'Philem': 'Philemon',
  'Heb': 'Hebrews',
  'Jas': 'James',
  'Jam': 'James',
  '1 Pt': '1 Peter',
  '1 Pet': '1 Peter',
  '2 Pt': '2 Peter',
  '2 Pet': '2 Peter',
  '1 Jn': '1 John',
  '1 John': '1 John',
  '2 Jn': '2 John',
  '2 John': '2 John',
  '3 Jn': '3 John',
  '3 John': '3 John',
  'Jude': 'Jude',
  'Rv': 'Revelation',
  'Rev': 'Revelation',
  'Apoc': 'Revelation',
  'Song of Songs': 'Canticle of Canticles',
  'Sgs': 'Canticle of Canticles',
  'M': 'Mark',
  'Phiippians': 'Philippians',
};

final Map<String, String> upperAbbrevToBookName = abbrevToBookName.map(
  (k, v) => MapEntry(k.toUpperCase(), v),
);

class ParsedRef {
  final String bookName;
  final int chapter;
  final String verseRange;

  ParsedRef({
    required this.bookName,
    required this.chapter,
    required this.verseRange,
  });
}

ParsedRef? parseCitation(String citation) {
  var clean = citation.trim().replaceAll('–', '-').replaceAll('—', '-');
  // Add space if missing between letters and digits (e.g. Psalm103 -> Psalm 103)
  clean = clean.replaceAll(RegExp(r'([a-zA-Z]+)(\d+)'), r'$1 $2');

  // Match optional numbered book (e.g. "1 Cor") or standard book, then space, then chapter/verse digits.
  final match = RegExp(
    r'^((?:\d+\s+)?[a-zA-Z\.\s]+)\s+(\d+.*)$',
  ).firstMatch(clean);
  if (match == null) return null;

  final abbrev = match.group(1)!.trim();
  final refPart = match.group(2)!.trim();

  // Strip any trailing punctuation from the book name or abbrev
  final cleanAbbrev = abbrev.replaceAll(RegExp(r'[;,\.\s]+$'), '').trim();

  // Look up canonical book name using uppercase match, or fallback to the cleaned abbreviation
  final keyAbbrev = cleanAbbrev.toUpperCase();
  var canonicalBook = upperAbbrevToBookName[keyAbbrev] ?? cleanAbbrev;
  if (canonicalBook.toLowerCase() == 'sirarch') {
    canonicalBook = 'Sirach';
  }

  int chapter = 1;
  String verseRange = '';

  if (refPart.contains(':')) {
    final parts = refPart.split(':');
    chapter = int.tryParse(parts[0]) ?? 1;
    verseRange = parts[1];
  } else {
    final isSingleChapter = const [
      'PHLM',
      'JUDE',
      'OB',
      '2 JN',
      '3 JN',
      'PHILEMON',
      'OBADIAH',
      '2 JOHN',
      '3 JOHN',
    ].contains(keyAbbrev);

    if (isSingleChapter) {
      chapter = 1;
      verseRange = refPart;
    } else {
      chapter = int.tryParse(refPart) ?? 1;
      verseRange = 'all';
    }
  }

  return ParsedRef(
    bookName: canonicalBook,
    chapter: chapter,
    verseRange: verseRange,
  );
}

void main() async {
  final sourceFile = File(
    '/tmp/catholic-daily-readings/data/lectionary/readings.json',
  );
  if (!await sourceFile.exists()) {
    print('Error: Source file readings.json not found at ${sourceFile.path}');
    exit(1);
  }

  print('Loading readings catalog...');
  final content = await sourceFile.readAsString();
  final Map<String, dynamic> rawCatalog = jsonDecode(content);
  print('Loaded ${rawCatalog.length} calendar dates from source.');

  final Map<String, Map<String, dynamic>> processedEntries = {};

  final startDate = DateTime(2023, 1, 1);
  final endDate = DateTime(2028, 12, 31);

  print('Processing dates from 2023 to 2028...');
  var currentDate = startDate;
  var processedDaysCount = 0;

  while (!currentDate.isAfter(endDate)) {
    final dateStr =
        '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

    if (rawCatalog.containsKey(dateStr)) {
      final List<dynamic> massConfigs = rawCatalog[dateStr];
      if (massConfigs.isNotEmpty) {
        final Map<String, dynamic> massConfig = massConfigs.first;
        final Map<String, dynamic>? readingsSection = massConfig['readings'];

        if (readingsSection != null) {
          final computedDay = LiturgicalCalendar.computeDay(currentDate);
          final key = computedDay.lectionaryKey;

          void processReadingType(String usccbKey, String typeCode) {
            final List<dynamic>? list = readingsSection[usccbKey];
            if (list != null && list.isNotEmpty) {
              final Map<String, dynamic> item = list.first;
              final String? citation = item['citation'];
              if (citation != null && citation.trim().isNotEmpty) {
                final parsed = parseCitation(citation);
                if (parsed != null) {
                  final BibleBook matchedBook = catholicBooks.firstWhere(
                    (b) =>
                        b.bookName.toLowerCase() ==
                        parsed.bookName.toLowerCase(),
                    orElse: () => catholicBooks.firstWhere(
                      (b) =>
                          b.abbrev.toLowerCase() ==
                          parsed.bookName.toLowerCase(),
                      orElse: () => const BibleBook(
                        bookNumber: 0,
                        bookName: '',
                        abbrev: '',
                        chaptersCount: 0,
                        category: '',
                        testament: '',
                      ),
                    ),
                  );

                  if (matchedBook.bookNumber != 0) {
                    final compositeKey = '${key}_$typeCode';
                    processedEntries[compositeKey] = {
                      'reading_key': key,
                      'reading_type': typeCode,
                      'book_number': matchedBook.bookNumber,
                      'book_name': matchedBook.bookName,
                      'chapter': parsed.chapter,
                      'verse_range': parsed.verseRange,
                      'citation': citation,
                    };
                  }
                }
              }
            }
          }

          processReadingType('first_reading', 'first');
          processReadingType('second_reading', 'second');
          processReadingType('responsorial_psalm', 'psalm');
          processReadingType('gospel', 'gospel');

          processedDaysCount++;
        }
      }
    }

    currentDate = currentDate.add(const Duration(days: 1));
  }

  print(
    'Matched and generated $processedDaysCount liturgical days from calendar mapping.',
  );
  print(
    'Unique lectionary reading records generated: ${processedEntries.length}',
  );

  final outputList = processedEntries.values.toList();
  // Sort for clean ordering
  outputList.sort((a, b) {
    final keyComp = (a['reading_key'] as String).compareTo(
      b['reading_key'] as String,
    );
    if (keyComp != 0) return keyComp;
    return (a['reading_type'] as String).compareTo(b['reading_type'] as String);
  });

  final outputFile = File('assets/bible/lectionary.json');
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(outputList),
  );
  print(
    'Successfully saved final database to ${outputFile.path} (${outputList.length} records)',
  );
}
