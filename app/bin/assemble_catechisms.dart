// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

String cleanText(String text) {
  return text.replaceAll('\r\n', '\n').replaceAll(RegExp(r'[\r\f]'), '').trim();
}

String stripGutenbergHeaderFooter(String text) {
  final startMatch = RegExp(
    r'\*\*\*\s*START OF (THE|THIS) PROJECT GUTENBERG EBOOK.*?\*\*\*',
    caseSensitive: false,
  ).firstMatch(text);
  if (startMatch != null) {
    text = text.substring(startMatch.end);
  }

  final endMatch = RegExp(
    r'\*\*\*\s*END OF (THE|THIS) PROJECT GUTENBERG EBOOK',
    caseSensitive: false,
  ).firstMatch(text);
  if (endMatch != null) {
    text = text.substring(0, endMatch.start);
  }

  return text.trim();
}

void parseBaltimoreFile(
  String filepath,
  String bookId,
  String title,
  String subtitle,
  Directory outputDir,
) {
  final file = File(filepath);
  if (!file.existsSync()) {
    print('Error: $filepath not found!');
    return;
  }

  final raw = file.readAsStringSync();
  final cleaned = stripGutenbergHeaderFooter(raw);
  final lines = cleaned.split('\n');

  final List<Map<String, dynamic>> sections = [];
  Map<String, dynamic>? currentSection;

  final qPattern = RegExp(r'^\s*Q\.\s*(\d+)\.?\s*(.*)', caseSensitive: false);
  final aPattern = RegExp(r'^\s*A\.\s*(.*)', caseSensitive: false);

  int? currentQNum;
  String currentQText = '';
  String currentAText = '';
  bool isAnswering = false;

  void finalizeQa() {
    if (currentQNum != null && currentSection != null) {
      (currentSection['content'] as List<dynamic>).add({
        'type': 'qa',
        'questionNumber': currentQNum,
        'question': currentQText.trim(),
        'answer': currentAText.trim(),
      });
    }
    currentQNum = null;
    currentQText = '';
    currentAText = '';
    isAnswering = false;
  }

  for (final line in lines) {
    final stripped = line.trim();
    if (stripped.isEmpty) continue;

    final matchLesson = RegExp(
      r'^\s*(LESSON\s+[A-Z0-9\-\s]+|PRONUNCIATION OF NAMES|PRAYERS)\.?\s*$',
      caseSensitive: false,
    ).firstMatch(stripped);
    if (matchLesson != null &&
        stripped.length < 40 &&
        !stripped.startsWith('Q.') &&
        !stripped.startsWith('A.')) {
      finalizeQa();
      final secId = 'sec_${sections.length + 1}';
      currentSection = {
        'id': secId,
        'title': stripped,
        'subtitle': '',
        'content': <Map<String, dynamic>>[],
      };
      sections.add(currentSection);
      continue;
    }

    if (currentSection != null &&
        (currentSection['content'] as List).isEmpty &&
        (currentSection['subtitle'] as String).isEmpty &&
        !stripped.startsWith('Q.') &&
        !stripped.startsWith('A.')) {
      if (stripped == stripped.toUpperCase() || stripped.startsWith('ON ')) {
        currentSection['subtitle'] = stripped;
        continue;
      }
    }

    final matchQ = qPattern.firstMatch(stripped);
    if (matchQ != null) {
      finalizeQa();
      currentQNum = int.parse(matchQ.group(1)!);
      currentQText = matchQ.group(2)!;
      isAnswering = false;
      if (currentSection == null) {
        currentSection = {
          'id': 'sec_1',
          'title': 'Introduction & Prayers',
          'subtitle': '',
          'content': <Map<String, dynamic>>[],
        };
        sections.add(currentSection);
      }
      continue;
    }

    final matchA = aPattern.firstMatch(stripped);
    if (matchA != null && currentQNum != null) {
      currentAText = matchA.group(1)!;
      isAnswering = true;
      continue;
    }

    if (isAnswering) {
      currentAText += ' $stripped';
    } else if (currentQNum != null) {
      currentQText += ' $stripped';
    } else {
      if (currentSection != null &&
          (currentSection['content'] as List).isEmpty) {
        (currentSection['content'] as List).add({
          'type': 'text',
          'text': stripped,
        });
      }
    }
  }

  finalizeQa();

  final validSections = sections
      .where(
        (s) =>
            (s['content'] as List).isNotEmpty ||
            (s['subtitle'] as String).isNotEmpty,
      )
      .toList();

  final toc = validSections.map((sec) {
    String tocTitle = sec['title'] as String;
    if ((sec['subtitle'] as String).isNotEmpty) {
      tocTitle += ': ${sec['subtitle']}';
    }
    return {'id': sec['id'], 'title': tocTitle};
  }).toList();

  final data = {
    'bookId': bookId,
    'title': title,
    'subtitle': subtitle,
    'author': 'Third Plenary Council of Baltimore',
    'toc': toc,
    'sections': validSections,
  };

  final outFile = File(p.join(outputDir.path, '$bookId.json'));
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  print(
    'Successfully generated ${outFile.path} (${validSections.length} sections)',
  );
}

void parseTrent(String filepath, Directory outputDir) {
  final file = File(filepath);
  if (!file.existsSync()) {
    print('Error: $filepath not found!');
    return;
  }

  final raw = file.readAsStringSync();
  final cleaned = cleanText(raw);
  final lines = cleaned.split('\n');

  final List<Map<String, dynamic>> sections = [];
  String currentPart = 'PART I';
  Map<String, dynamic>? currentSection;

  final partPattern = RegExp(
    r'^\s*(PART\s+[I|V|X]+)\.?\s*$',
    caseSensitive: false,
  );
  final chapPattern = RegExp(
    r'^\s*(CHAP(?:TER)?\.?\s+[I|V|X\d]+)\.?(.*)',
    caseSensitive: false,
  );

  for (final line in lines) {
    final stripped = line.trim();
    if (stripped.isEmpty) continue;

    final mPart = partPattern.firstMatch(stripped);
    if (mPart != null) {
      currentPart = mPart.group(1)!.toUpperCase();
      continue;
    }

    final mChap = chapPattern.firstMatch(stripped);
    if (mChap != null && stripped.length < 80) {
      final chapNum = mChap.group(1)!.toUpperCase();
      final chapTitle = mChap
          .group(2)!
          .replaceAll(RegExp(r'^[\s\.\—\–\-]+'), '')
          .trim();
      final secId = 'sec_trent_${sections.length + 1}';
      String fullTitle = '$currentPart, $chapNum';
      if (chapTitle.isNotEmpty) {
        fullTitle += ': $chapTitle';
      }

      currentSection = {
        'id': secId,
        'title': fullTitle,
        'part': currentPart,
        'chapter': chapNum,
        'content': <Map<String, dynamic>>[],
      };
      sections.add(currentSection);
      continue;
    }

    if (currentSection != null) {
      if (RegExp(
        r'^\s*PART\s+[I|V|X]+.*?CHAPTER.*?\d+\s*$',
        caseSensitive: false,
      ).hasMatch(stripped)) {
        continue;
      }
      final contentList = currentSection['content'] as List<dynamic>;
      if (contentList.isNotEmpty && contentList.last['type'] == 'text') {
        contentList.last['text'] = '${contentList.last['text']}\n$stripped';
      } else {
        contentList.add({'type': 'text', 'text': stripped});
      }
    }
  }

  final validSections = sections
      .where((s) => (s['content'] as List).isNotEmpty)
      .toList();

  final toc = validSections.map((sec) {
    return {'id': sec['id'], 'title': sec['title']};
  }).toList();

  final data = {
    'bookId': 'council_of_trent',
    'title': 'Catechism of the Council of Trent',
    'subtitle': 'The Roman Catechism (Translated by Rev. J. Donovan, 1829)',
    'author': 'Council of Trent / St. Pius V',
    'toc': toc,
    'sections': validSections,
  };

  final outFile = File(p.join(outputDir.path, 'council_of_trent.json'));
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  print(
    'Successfully generated ${outFile.path} (${validSections.length} sections)',
  );
}

void main() {
  final outputDir = Directory('assets/catechism/json');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final baltimoreDir = p.join('assets', 'catechism', 'baltimore');
  final trentDir = p.join('assets', 'catechism', 'trent');

  parseBaltimoreFile(
    p.join(baltimoreDir, 'baltimore_catechism_no1.txt'),
    'baltimore_1',
    'Baltimore Catechism No. 1',
    'For First Communion Classes',
    outputDir,
  );
  parseBaltimoreFile(
    p.join(baltimoreDir, 'baltimore_catechism_no2.txt'),
    'baltimore_2',
    'Baltimore Catechism No. 2',
    'For Confirmation & Grammar Classes',
    outputDir,
  );
  parseBaltimoreFile(
    p.join(baltimoreDir, 'baltimore_catechism_no3.txt'),
    'baltimore_3',
    'Baltimore Catechism No. 3',
    'For Two Years\' Course for Post-Confirmation Classes',
    outputDir,
  );
  parseBaltimoreFile(
    p.join(baltimoreDir, 'baltimore_catechism_no4_explanation.txt'),
    'baltimore_4',
    'Baltimore Catechism No. 4',
    'An Explanation of the Baltimore Catechism (Fr. Kinkead)',
    outputDir,
  );
  parseTrent(
    p.join(trentDir, 'catechism_of_the_council_of_trent_donovan_1829.txt'),
    outputDir,
  );
}
