// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:twelve_stars/logic/lectionary_resolver.dart';
import 'package:twelve_stars/logic/liturgical_calendar_core.dart';
import 'package:twelve_stars/logic/rosary_helper.dart';

const List<String> _rosaryPrayerIds = [
  'sign_of_the_cross',
  'apostles_creed',
  'our_father',
  'hail_mary',
  'glory_be',
  'fatima_prayer',
  'hail_holy_queen',
  'final_prayer_rosary',
];

const List<String> _wearPrayerLanguages = ['english', 'latin'];

const Map<int, String> _gospelUsfmFiles = {
  49: '49-MAT-ENG[B]CPDV2025[pd].usfm',
  50: '50-MRK-ENG[B]CPDV2025[pd].usfm',
  51: '51-LUK-ENG[B]CPDV2025[pd].usfm',
  52: '52-JHN-ENG[B]CPDV2025[pd].usfm',
};

const Map<int, String> _gospelShortBookNames = {
  49: 'Mt',
  50: 'Mk',
  51: 'Lk',
  52: 'Jn',
};

String _formatIsoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _mysteryKey(RosaryMysteryType type) {
  switch (type) {
    case RosaryMysteryType.joyful:
      return 'joyful';
    case RosaryMysteryType.sorrowful:
      return 'sorrowful';
    case RosaryMysteryType.glorious:
      return 'glorious';
    case RosaryMysteryType.luminous:
      return 'luminous';
  }
}

File _resolveAssetFile(List<String> relativeParts) {
  final cwdFile = File(p.joinAll(relativeParts));
  if (cwdFile.existsSync()) {
    return cwdFile;
  }
  if (Platform.script.scheme == 'file') {
    final scriptDir = p.dirname(Platform.script.toFilePath());
    final scriptRelative = File(
      p.normalize(p.joinAll([scriptDir, '..', ...relativeParts])),
    );
    if (scriptRelative.existsSync()) {
      return scriptRelative;
    }
  }
  return cwdFile;
}

Directory _resolveAssetDir(List<String> relativeParts) {
  final cwdDir = Directory(p.joinAll(relativeParts));
  if (cwdDir.existsSync()) {
    return cwdDir;
  }
  if (Platform.script.scheme == 'file') {
    final scriptDir = p.dirname(Platform.script.toFilePath());
    final scriptRelative = Directory(
      p.normalize(p.joinAll([scriptDir, '..', ...relativeParts])),
    );
    if (scriptRelative.existsSync()) {
      return scriptRelative;
    }
  }
  return cwdDir;
}

File _resolveDefaultPrayersJsonFile() =>
    _resolveAssetFile(['assets', 'prayers.json']);

String _cleanUsfmVerseText(String raw) {
  var text = raw;
  // Strip USFM footnotes (\f ... \f*) and cross-references (\x ... \x*).
  text = text.replaceAll(RegExp(r'\\f\b.*?\\f\*'), '');
  text = text.replaceAll(RegExp(r'\\x\b.*?\\x\*'), '');
  // Strip remaining inline USFM markers.
  text = text.replaceAll(RegExp(r'\\\+?[a-zA-Z]+\d*\*?'), '');
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

Map<int, Map<int, String>> _parseUsfmBook(File file) {
  final chapters = <int, Map<int, String>>{};
  int? currentChapter;
  final chapterRegex = RegExp(r'^\\c\s+(\d+)');
  final verseRegex = RegExp(r'^\\v\s+(\d+)(?:-\d+)?\s+(.*)$');

  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final cMatch = chapterRegex.firstMatch(line);
    if (cMatch != null) {
      currentChapter = int.parse(cMatch.group(1)!);
      chapters.putIfAbsent(currentChapter, () => <int, String>{});
      continue;
    }
    final vMatch = verseRegex.firstMatch(line);
    if (vMatch != null && currentChapter != null) {
      final verseNum = int.parse(vMatch.group(1)!);
      final cleaned = _cleanUsfmVerseText(vMatch.group(2)!);
      if (cleaned.isNotEmpty) {
        chapters[currentChapter]![verseNum] = cleaned;
      }
    }
  }
  return chapters;
}

String _formatShortGospelCitation(int bookNumber, String citation) {
  final shortBook = _gospelShortBookNames[bookNumber];
  var primary = citation.trim();
  final orIndex = primary.toLowerCase().indexOf(' or ');
  if (orIndex != -1) {
    primary = primary.substring(0, orIndex).trim();
  }
  if (shortBook == null) return primary;
  final spaceIdx = primary.indexOf(' ');
  if (spaceIdx == -1) return primary;
  final rest = primary.substring(spaceIdx + 1).trim();
  // Keep it compact for Wear OS SHORT_TEXT complications (strip trailing a/b letters).
  final compactRest = rest.replaceAllMapped(
    RegExp(r'([0-9])[a-zA-Z]+'),
    (m) => m.group(1)!,
  );
  return '$shortBook $compactRest';
}

Map<String, dynamic> buildLiturgicalCalendarPayload({
  required int startYear,
  required int endYear,
}) {
  if (endYear < startYear) {
    throw ArgumentError('endYear ($endYear) must be >= startYear ($startYear)');
  }

  final days = <String, Map<String, dynamic>>{};
  var current = DateTime(startYear, 1, 1);
  final endExclusive = DateTime(endYear + 1, 1, 1);

  while (current.isBefore(endExclusive)) {
    final day = LiturgicalCalendar.computeDay(current);
    final mystery = RosaryHelper.getMysteryForDay(current);
    days[_formatIsoDate(current)] = {
      'season': day.season.name,
      'seasonName': day.seasonName,
      'color': day.color.name,
      'colorName': day.colorName,
      if (day.name != null) 'name': day.name,
      'weekName': day.weekName,
      'sundayCycle': day.sundayCycle,
      'weekdayCycle': day.weekdayCycle,
      'lectionaryKey': day.lectionaryKey,
      'rosaryMystery': _mysteryKey(mystery),
    };
    current = DateTime(current.year, current.month, current.day + 1);
  }

  return {
    'schemaVersion': 1,
    'startYear': startYear,
    'endYear': endYear,
    'days': days,
  };
}

Map<String, dynamic> buildRosaryPayload({File? prayersJsonFile}) {
  final mysteries = <String, Map<String, dynamic>>{};
  for (final type in RosaryMysteryType.values) {
    final items = RosaryHelper.mysteries[type] ?? const <RosaryMystery>[];
    mysteries[_mysteryKey(type)] = {
      'title': type.name,
      'days': type.days,
      'decades': [
        for (final m in items)
          {'number': m.number, 'title': m.title, 'description': m.description},
      ],
    };
  }

  final sourceFile = prayersJsonFile ?? _resolveDefaultPrayersJsonFile();
  if (!sourceFile.existsSync()) {
    throw FileSystemException('Prayers JSON file not found', sourceFile.path);
  }

  final decoded = jsonDecode(sourceFile.readAsStringSync());
  if (decoded is! List) {
    throw FormatException(
      'Expected a JSON list in ${sourceFile.path}, '
      'got ${decoded.runtimeType}',
    );
  }

  final byId = <String, Map<String, dynamic>>{};
  for (final item in decoded) {
    if (item is Map<String, dynamic>) {
      final id = item['id'] as String?;
      if (id != null && _rosaryPrayerIds.contains(id)) {
        byId[id] = item;
      }
    }
  }

  final missingIds = _rosaryPrayerIds
      .where((id) => !byId.containsKey(id))
      .toList();
  if (missingIds.isNotEmpty) {
    throw StateError(
      'Missing required Rosary prayer IDs from ${sourceFile.path}: '
      '${missingIds.join(', ')}',
    );
  }

  final prayers = <String, Map<String, dynamic>>{};
  for (final id in _rosaryPrayerIds) {
    final item = byId[id]!;
    final rawTranslations = item['translations'];
    final localized = <String, Map<String, String>>{};
    if (rawTranslations is Map) {
      for (final lang in _wearPrayerLanguages) {
        final versions = rawTranslations[lang];
        if (versions is List && versions.isNotEmpty) {
          final first = versions.first;
          if (first is Map) {
            localized[lang] = {
              'title': (first['title'] as String?) ?? '',
              'text': (first['text'] as String?) ?? '',
            };
          }
        }
      }
    }
    prayers[id] = {
      'id': id,
      'defaultTitle': (item['default_title'] as String?) ?? id,
      'hasAmen': (item['has_amen'] as bool?) ?? false,
      'translations': localized,
    };
  }

  return {'schemaVersion': 1, 'mysteries': mysteries, 'prayers': prayers};
}

Map<String, dynamic> buildGospelPayload({
  File? lectionaryJsonFile,
  Directory? usfmDir,
}) {
  final lectionaryFile =
      lectionaryJsonFile ??
      _resolveAssetFile(['assets', 'bible', 'lectionary.json']);
  if (!lectionaryFile.existsSync()) {
    throw FileSystemException(
      'Lectionary JSON file not found',
      lectionaryFile.path,
    );
  }

  final cpdvUsfmDir =
      usfmDir ?? _resolveAssetDir(['assets', 'bible', 'cpdv', 'usfm']);
  if (!cpdvUsfmDir.existsSync()) {
    throw FileSystemException(
      'CPDV USFM directory not found',
      cpdvUsfmDir.path,
    );
  }

  final gospelBooks = <int, Map<int, Map<int, String>>>{};
  for (final entry in _gospelUsfmFiles.entries) {
    final file = File(p.join(cpdvUsfmDir.path, entry.value));
    if (!file.existsSync()) {
      throw FileSystemException('Gospel USFM file not found', file.path);
    }
    gospelBooks[entry.key] = _parseUsfmBook(file);
  }

  final decoded = jsonDecode(lectionaryFile.readAsStringSync());
  if (decoded is! List) {
    throw FormatException(
      'Expected a JSON list in ${lectionaryFile.path}, '
      'got ${decoded.runtimeType}',
    );
  }

  final readings = <String, Map<String, dynamic>>{};
  for (final item in decoded) {
    if (item is! Map<String, dynamic>) continue;
    final readingType = (item['reading_type'] as String?)?.toLowerCase();
    if (readingType != 'gospel') continue;
    final key = item['reading_key'] as String?;
    if (key == null || key.isEmpty || readings.containsKey(key)) continue;

    final bookNumber = item['book_number'] as int?;
    final bookName = (item['book_name'] as String?) ?? '';
    final chapter = item['chapter'] as int?;
    final verseRange = (item['verse_range'] as String?) ?? '';
    final citation = (item['citation'] as String?) ?? '';
    if (bookNumber == null || chapter == null) continue;

    final bookChapters = gospelBooks[bookNumber];
    if (bookChapters == null) continue;

    final ranges = resolveReadingRanges(
      bookNumber: bookNumber,
      defaultChapter: chapter,
      defaultVerseRange: verseRange,
      citation: citation,
    );

    final verses = <Map<String, dynamic>>[];
    for (final range in ranges) {
      final chapterVerses = bookChapters[range.chapter];
      if (chapterVerses == null) continue;
      final verseNumbers = range.verses != null && range.verses!.isNotEmpty
          ? range.verses!
          : (chapterVerses.keys.toList()..sort());
      for (final vNum in verseNumbers) {
        if (range.startVerseLimit != null && vNum < range.startVerseLimit!) {
          continue;
        }
        if (range.endVerseLimit != null && vNum > range.endVerseLimit!) {
          continue;
        }
        final text = chapterVerses[vNum];
        if (text != null && text.isNotEmpty) {
          verses.add({'chapter': range.chapter, 'number': vNum, 'text': text});
        }
      }
    }

    if (verses.isNotEmpty) {
      readings[key] = {
        'citation': citation,
        'shortCitation': _formatShortGospelCitation(bookNumber, citation),
        'bookName': bookName,
        'verses': verses,
      };
    }
  }

  return {'schemaVersion': 1, 'readings': readings};
}

void main(List<String> args) {
  final nowYear = DateTime.now().year;
  var startYear = nowYear - 1;
  var endYear = nowYear + 10;
  var outDir = 'build/wear_data';

  for (final arg in args) {
    if (arg.startsWith('--start-year=')) {
      final raw = arg.substring('--start-year='.length);
      final parsed = int.tryParse(raw);
      if (parsed == null) {
        stderr.writeln('Invalid --start-year value: "$raw"');
        exit(1);
      }
      startYear = parsed;
    } else if (arg.startsWith('--end-year=')) {
      final raw = arg.substring('--end-year='.length);
      final parsed = int.tryParse(raw);
      if (parsed == null) {
        stderr.writeln('Invalid --end-year value: "$raw"');
        exit(1);
      }
      endYear = parsed;
    } else if (arg.startsWith('--out-dir=')) {
      final raw = arg.substring('--out-dir='.length).trim();
      if (raw.isEmpty) {
        stderr.writeln('Invalid --out-dir value: must not be empty');
        exit(1);
      }
      outDir = raw;
    } else if (arg == '--help' || arg == '-h') {
      print(
        'Usage: dart run bin/assemble_wear_data.dart '
        '[--start-year=YYYY] [--end-year=YYYY] [--out-dir=DIR]',
      );
      return;
    } else {
      stderr.writeln('Unknown argument: $arg');
      exit(1);
    }
  }

  try {
    final outputDirectory = Directory(outDir);
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync(recursive: true);
    }

    final calendarPayload = buildLiturgicalCalendarPayload(
      startYear: startYear,
      endYear: endYear,
    );
    final calendarFile = File(p.join(outDir, 'liturgical_calendar.json'));
    calendarFile.writeAsStringSync(jsonEncode(calendarPayload));

    final rosaryPayload = buildRosaryPayload();
    final rosaryFile = File(p.join(outDir, 'rosary_data.json'));
    rosaryFile.writeAsStringSync(jsonEncode(rosaryPayload));

    final gospelPayload = buildGospelPayload();
    final gospelFile = File(p.join(outDir, 'gospel_data.json'));
    gospelFile.writeAsStringSync(jsonEncode(gospelPayload));

    final dayCount = (calendarPayload['days'] as Map).length;
    final gospelCount = (gospelPayload['readings'] as Map).length;
    print(
      'Generated Wear OS data ($dayCount days, $gospelCount gospels, '
      '$startYear-$endYear) in $outDir',
    );
  } on ArgumentError catch (e) {
    stderr.writeln('Error: ${e.message ?? e}');
    exit(1);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(1);
  } on FileSystemException catch (e) {
    final pathInfo = e.path != null ? ' (${e.path})' : '';
    stderr.writeln('Error: ${e.message}$pathInfo');
    exit(1);
  } on StateError catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(1);
  }
}
