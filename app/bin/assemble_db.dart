// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

List<Map<String, dynamic>> parseTokens(String input) {
  final List<Map<String, dynamic>> tokens = [];
  final regex = RegExp(r'\{([^\}]*)\|([^\|\}]+)\}');
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

String calculateHash(String input) {
  int hash = 5381;
  for (int i = 0; i < input.length; i++) {
    hash = ((hash << 5) + hash) + input.codeUnitAt(i);
    hash = hash & 0xFFFFFFFF; // Keep it as 32-bit unsigned int
  }
  return hash.toRadixString(16);
}

void main() {
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

    final YamlMap yaml = loadYaml(frontmatterYaml);

    final category = yaml['category'] as String;
    final defaultOrder = yaml['default_order'] as int;
    final defaultTitle = yaml['default_title'] as String;
    final title = yaml['title'] as String;
    final subtitle = yaml['subtitle'] as String?;
    final sourceName = yaml['source_name'] as String;
    final sourceUrl = yaml['source_url'] as String;
    final copyright = yaml.containsKey('copyright')
        ? yaml['copyright'] as String
        : '';
    final historyAuthor = yaml['history_author'] as String? ?? '';
    final historyOrigin = yaml['history_origin'] as String? ?? '';
    final historyDescription = yaml['history_description'] as String? ?? '';
    final hasAmen = yaml['has_amen'] as bool? ?? false;

    List<Map<String, dynamic>>? sources;
    if (yaml.containsKey('sources')) {
      final yamlList = yaml['sources'] as YamlList;
      sources = yamlList.map((item) {
        final map = item as YamlMap;
        return {
          'name': map['name'] as String,
          'url': map['url'] as String,
          'start_line': map['start_line'] as int,
          'end_line': map['end_line'] as int,
        };
      }).toList();
    }

    List<List<Map<String, dynamic>>>? chineseLines;
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
      chineseLines = lines;
    }

    prayersToInsert[prayerId] = {
      'id': prayerId,
      'default_title': defaultTitle,
      'category': category,
      'default_order': defaultOrder,
      'has_amen':
          (prayersToInsert[prayerId]?['has_amen'] as bool? ?? false) || hasAmen,
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
      'copyright': copyright,
      'history_author': historyAuthor,
      'history_origin': historyOrigin,
      'history_description': historyDescription,
      'chinese_lines': chineseLines,
      'tokens': tokens,
      'sources': sources,
    });
  }

  // Reconstruct JSON structure for Database catalog
  final List<Map<String, dynamic>> jsonList = [];
  for (final p in prayersToInsert.values) {
    final Map<String, List<Map<String, dynamic>>> translationsMap = {};
    for (final t in translationsToInsert) {
      if (t['prayer_id'] == p['id']) {
        final lang = t['language'] as String;
        if (!translationsMap.containsKey(lang)) {
          translationsMap[lang] = [];
        }

        translationsMap[lang]!.add({
          'title': t['title'],
          'subtitle': t['subtitle'],
          'text': t['text'],
          'source_name': t['source_name'],
          'source_url': t['source_url'],
          'history_author': t['history_author'],
          'history_origin': t['history_origin'],
          'history_description': t['history_description'],
          'chinese_lines': t['chinese_lines'],
          'tokens': t['tokens'],
          'sources': t['sources'],
        });
      }
    }
    final prayerData = {
      'id': p['id'],
      'default_title': p['default_title'],
      'category': p['category'],
      'default_order': p['default_order'],
      'has_amen': p['has_amen'],
      'translations': translationsMap,
    };
    final canonicalString = jsonEncode(prayerData);
    prayerData['hash'] = calculateHash(canonicalString);
    jsonList.add(prayerData);
  }

  // Sort jsonList by default_order to keep a deterministic order in assets/prayers.json
  jsonList.sort(
    (a, b) => (a['default_order'] as int).compareTo(b['default_order'] as int),
  );

  final targetJsonFile = File('assets/prayers.json');
  targetJsonFile.writeAsStringSync(jsonEncode(jsonList));
  print('Successfully compiled JSON database: assets/prayers.json');
}
