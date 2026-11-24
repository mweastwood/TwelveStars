// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
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

File _resolveDefaultPrayersJsonFile() {
  final cwdFile = File('assets/prayers.json');
  if (cwdFile.existsSync()) {
    return cwdFile;
  }
  if (Platform.script.scheme == 'file') {
    final scriptDir = p.dirname(Platform.script.toFilePath());
    final scriptRelative = File(
      p.normalize(p.join(scriptDir, '..', 'assets', 'prayers.json')),
    );
    if (scriptRelative.existsSync()) {
      return scriptRelative;
    }
  }
  return cwdFile;
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

    final dayCount = (calendarPayload['days'] as Map).length;
    print(
      'Generated Wear OS data ($dayCount days, $startYear-$endYear) in $outDir',
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
