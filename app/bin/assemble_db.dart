// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yaml/yaml.dart';

List<Map<String, dynamic>> parseTokens(String input) {
  final List<Map<String, dynamic>> tokens = [];
  final regex = RegExp(r'\{([^\}]+)\|([^\|\}]+)\}');
  int lastMatchEnd = 0;

  for (final match in regex.allMatches(input)) {
    if (match.start > lastMatchEnd) {
      tokens.add({
        'text': input.substring(lastMatchEnd, match.start),
        'id': null,
      });
    }
    tokens.add({'text': match.group(1)!, 'id': match.group(2)!});
    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < input.length) {
    tokens.add({'text': input.substring(lastMatchEnd), 'id': null});
  }
  return tokens;
}

void main() {
  // Override sqlite3 FFI loading on Linux to fall back to libsqlite3.so.0 if libsqlite3.so is not available.
  open.overrideFor(OperatingSystem.linux, () {
    try {
      return DynamicLibrary.open('libsqlite3.so.0');
    } catch (_) {
      return DynamicLibrary.open('libsqlite3.so');
    }
  });

  // Load pinyin dictionary
  final pinyinMap = <String, String>{};
  final pinyinDictFile = File('assets/pinyin_dict.txt');
  if (pinyinDictFile.existsSync()) {
    for (final line in pinyinDictFile.readAsLinesSync()) {
      final parts = line.split(':');
      if (parts.length == 2) {
        pinyinMap[parts[0].trim()] = parts[1].trim();
      }
    }
  } else {
    print('Warning: assets/pinyin_dict.txt not found.');
  }

  final targetDbFile = File('assets/prayers.db');
  if (targetDbFile.existsSync()) {
    targetDbFile.deleteSync();
  }

  final db = sqlite3.open(targetDbFile.path);

  // Create tables
  db.execute('''
    CREATE TABLE prayers (
      id TEXT PRIMARY KEY,
      default_title TEXT NOT NULL,
      category TEXT NOT NULL,
      default_order INTEGER NOT NULL
    );
  ''');

  db.execute('''
    CREATE TABLE translations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      prayer_id TEXT NOT NULL,
      language TEXT NOT NULL,
      version_index INTEGER NOT NULL,
      title TEXT NOT NULL,
      subtitle TEXT,
      text TEXT NOT NULL,
      source_name TEXT,
      source_url TEXT,
      chinese_lines TEXT, -- JSON string representation
      tokens TEXT, -- JSON string representation of parsed tokens
      FOREIGN KEY(prayer_id) REFERENCES prayers(id)
    );
  ''');

  db.execute('''
    CREATE VIRTUAL TABLE translation_search USING fts5(
      translation_id UNINDEXED,
      title,
      subtitle,
      text,
      tokenize="unicode61"
    );
  ''');

  // Find all .md files under assets/prayers/
  final dir = Directory('assets/prayers');
  if (!dir.existsSync()) {
    print('Error: assets/prayers directory not found!');
    exit(1);
  }

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  final prayersToInsert = <String, Map<String, dynamic>>{};
  final translationsToInsert = <Map<String, dynamic>>{};

  for (final file in files) {
    final filename = p.basename(file.path);
    final prayerId = p.basename(p.dirname(file.path));

    final filenameParts = filename.split('_v');
    final language = filenameParts.first;
    final versionIndex =
        int.parse(filenameParts.last.replaceAll('.md', '')) - 1;

    final content = file.readAsStringSync();

    // Normalization to handle varying line-ending formats (\r\n) cleanly
    final normalizedContent = content.replaceAll('\r\n', '\n');
    final parts = normalizedContent.split('---\n');
    if (parts.length < 3) {
      print('Warning: Invalid markdown structure in ${file.path}');
      continue;
    }

    final frontmatterYaml = parts[1];
    final bodyTextRaw = parts.sublist(2).join('---\n').trim();

    final tokens = parseTokens(bodyTextRaw);
    final bodyText = tokens.map((t) => t['text'] as String).join('');
    final tokensJson = jsonEncode(tokens);

    final YamlMap yaml = loadYaml(frontmatterYaml);

    final category = yaml['category'] as String;
    final defaultOrder = yaml['default_order'] as int;
    final defaultTitle = yaml['default_title'] as String;
    final title = yaml['title'] as String;
    final subtitle = yaml['subtitle'] as String?;
    final sourceName = yaml['source_name'] as String;
    final sourceUrl = yaml['source_url'] as String;

    String? chineseLinesJson;
    if (language == 'traditionalChinese') {
      final List<List<Map<String, dynamic>>> lines = [];
      final List<String?> charPhraseIds = [];
      for (final token in tokens) {
        final tokenText = token['text'] as String;
        final tokenId = token['id'] as String?;
        for (int i = 0; i < tokenText.runes.length; i++) {
          charPhraseIds.add(tokenId);
        }
      }

      int globalCharIndex = 0;
      for (final line in bodyText.split('\n')) {
        if (line.trim().isEmpty) continue;
        final List<Map<String, dynamic>> currentLine = [];
        for (final char in line.runes.map((r) => String.fromCharCode(r))) {
          final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(char);
          if (isChinese && !pinyinMap.containsKey(char)) {
            print(
              'Error: Missing pinyin mapping for Chinese character "$char" in assets/pinyin_dict.txt',
            );
            exit(1);
          }
          final pinyin = pinyinMap[char] ?? '';

          String? phraseId;
          if (globalCharIndex < charPhraseIds.length) {
            phraseId = charPhraseIds[globalCharIndex];
          }
          globalCharIndex++;

          currentLine.add({
            'char': char,
            'pinyin': pinyin,
            'phraseId': phraseId,
          });
        }
        globalCharIndex++; // account for newline character
        lines.add(currentLine);
      }
      chineseLinesJson = jsonEncode(lines);
    }

    prayersToInsert[prayerId] = {
      'id': prayerId,
      'default_title': defaultTitle,
      'category': category,
      'default_order': defaultOrder,
    };

    translationsToInsert.add({
      'prayer_id': prayerId,
      'language': language,
      'version_index': versionIndex,
      'title': title,
      'subtitle': subtitle,
      'text': bodyText,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'chinese_lines': chineseLinesJson,
      'tokens': tokensJson,
    });
  }

  // Insert prayers
  final insertPrayer = db.prepare('''
    INSERT OR REPLACE INTO prayers (id, default_title, category, default_order)
    VALUES (?, ?, ?, ?);
  ''');
  for (final p in prayersToInsert.values) {
    insertPrayer.execute([
      p['id'],
      p['default_title'],
      p['category'],
      p['default_order'],
    ]);
  }
  insertPrayer.dispose();

  // Insert translations
  final insertTranslation = db.prepare('''
    INSERT INTO translations (prayer_id, language, version_index, title, subtitle, text, source_name, source_url, chinese_lines, tokens)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
  ''');

  final insertSearch = db.prepare('''
    INSERT INTO translation_search (translation_id, title, subtitle, text)
    VALUES (?, ?, ?, ?);
  ''');

  for (final t in translationsToInsert) {
    insertTranslation.execute([
      t['prayer_id'],
      t['language'],
      t['version_index'],
      t['title'],
      t['subtitle'],
      t['text'],
      t['source_name'],
      t['source_url'],
      t['chinese_lines'],
      t['tokens'],
    ]);
    final translationId = db.lastInsertRowId;

    insertSearch.execute([translationId, t['title'], t['subtitle'], t['text']]);
  }

  insertTranslation.dispose();
  insertSearch.dispose();

  db.dispose();
  print('Successfully compiled SQLite database: assets/prayers.db');
}
