// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

String cleanText(String text) {
  return text.replaceAll('\r\n', '\n').replaceAll(RegExp(r'[\r\f]'), '');
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

  final endMatch2 = RegExp(
    r'End of (the )?Project Gutenberg',
    caseSensitive: false,
  ).firstMatch(text);
  if (endMatch2 != null) {
    text = text.substring(0, endMatch2.start);
  }

  return text.trim();
}

const Map<String, String> ordinalMap = {
  'FIRST': '1',
  'SECOND': '2',
  'THIRD': '3',
  'FOURTH': '4',
  'FIFTH': '5',
  'SIXTH': '6',
  'SEVENTH': '7',
  'EIGHTH': '8',
  'NINTH': '9',
  'TENTH': '10',
  'ELEVENTH': '11',
  'TWELFTH': '12',
  'THIRTEENTH': '13',
  'FOURTEENTH': '14',
  'FIFTEENTH': '15',
  'SIXTEENTH': '16',
  'SEVENTEENTH': '17',
  'EIGHTEENTH': '18',
  'NINTEENTH': '19',
  'NINETEENTH': '19',
  'TWENTIETH': '20',
  'TWENTY-FIRST': '21',
  'TWENTY-SECOND': '22',
  'TWENTY-THIRD': '23',
  'TWENTY-FOURTH': '24',
  'TWENTY-FIFTH': '25',
  'TWENTY-SIXTH': '26',
  'TWENTY-SEVENTH': '27',
  'TWENTY-EIGHTH': '28',
  'TWENTY-NINTH': '29',
  'THIRTIETH': '30',
  'THIRTY-FIRST': '31',
  'THIRTY-SECOND': '32',
  'THIRTY-THIRD': '33',
  'THIRTY-FOURTH': '34',
  'THIRTY-FIFTH': '35',
  'THIRTY-SIXTH': '36',
  'THIRTY-SEVENTH': '37',
};

String formatTitleCase(String text) {
  final words = text.split(' ');
  final result = <String>[];
  for (final w in words) {
    if (w.isEmpty) continue;
    if (w == w.toUpperCase() || w == w.toLowerCase()) {
      result.add(
        '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
      );
    } else {
      result.add(w);
    }
  }
  return result.join(' ');
}

String formatLessonTitle(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[\s\.]+$'), '').trim();
  final upper = cleaned.toUpperCase();
  if (upper.startsWith('LESSON ')) {
    final ordPart = upper.replaceFirst('LESSON ', '').trim();
    final num = ordinalMap[ordPart] ?? ordPart;
    return 'Lesson $num';
  }
  return formatTitleCase(cleaned);
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
  final cleaned = stripGutenbergHeaderFooter(cleanText(raw));
  final lines = cleaned.split('\n');

  final List<Map<String, dynamic>> sections = [];
  Map<String, dynamic>? currentSection;

  // Flexible regex for Baltimore Q&A:
  // Matches "1 Q.", "1. Q.", "*4 Q.", "Q. 126.", "{1} Q. 130."
  final qPattern = RegExp(
    r'^\s*[\*\s]*(?:\{\d+\}\s*)?(?:(\d+)\.?\s*Q\.|Q\.\s*(\d+)\.?)\s*(.*)',
    caseSensitive: false,
  );
  final aPattern = RegExp(r'^\s*A\.\s*(.*)', caseSensitive: false);
  final lessonPattern = RegExp(
    r'^\s*(LESSON\s+[A-Z0-9\-\s]+|PRONUNCIATION OF NAMES|PRAYERS)\.?\s*$',
    caseSensitive: false,
  );
  final dotsPattern = RegExp(r'(\.\s*){4,}');

  int? currentQNum;
  String currentQText = '';
  String currentAText = '';
  final List<String> currentExplanation = [];
  bool isAnswering = false;
  bool isExplaining = false;

  void finalizeQa() {
    final sec = currentSection;
    if (currentQNum != null && sec != null) {
      final Map<String, dynamic> entry = {
        'type': 'qa',
        'questionNumber': currentQNum,
        'question': currentQText.replaceAll(RegExp(r'\s+'), ' ').trim(),
        'answer': currentAText.replaceAll(RegExp(r'\s+'), ' ').trim(),
      };
      if (currentExplanation.isNotEmpty) {
        final expText = currentExplanation
            .map((p) => p.replaceAll(RegExp(r'\s+'), ' ').trim())
            .where((p) => p.isNotEmpty)
            .join('\n\n');
        if (expText.isNotEmpty) {
          entry['explanation'] = expText;
        }
      }
      (sec['content'] as List<dynamic>).add(entry);
    }
    currentQNum = null;
    currentQText = '';
    currentAText = '';
    currentExplanation.clear();
    isAnswering = false;
    isExplaining = false;
  }

  for (final line in lines) {
    final stripped = line.trim();
    if (stripped.isEmpty) {
      if (isAnswering) {
        isAnswering = false;
        isExplaining = true;
      }
      continue;
    }

    if (dotsPattern.hasMatch(stripped)) {
      continue;
    }

    final matchLesson = lessonPattern.firstMatch(stripped);
    if (matchLesson != null &&
        stripped.length < 50 &&
        !qPattern.hasMatch(stripped) &&
        !aPattern.hasMatch(stripped)) {
      finalizeQa();
      final secId = 'sec_${sections.length + 1}';
      final formattedTitle = formatLessonTitle(stripped);
      currentSection = {
        'id': secId,
        'title': formattedTitle,
        'subtitle': '',
        'content': <Map<String, dynamic>>[],
      };
      sections.add(currentSection);
      continue;
    }

    final sec = currentSection;
    if (sec != null &&
        (sec['content'] as List).isEmpty &&
        (sec['subtitle'] as String).isEmpty &&
        !qPattern.hasMatch(stripped) &&
        !aPattern.hasMatch(stripped)) {
      if (stripped == stripped.toUpperCase() ||
          stripped.startsWith('ON ') ||
          stripped.startsWith('FROM ')) {
        sec['subtitle'] = formatTitleCase(stripped);
        continue;
      }
    }

    final matchQ = qPattern.firstMatch(stripped);
    if (matchQ != null) {
      finalizeQa();
      final qNumStr = matchQ.group(1) ?? matchQ.group(2);
      currentQNum = qNumStr != null ? int.parse(qNumStr) : 0;
      currentQText = matchQ.group(3) ?? '';
      isAnswering = false;
      isExplaining = false;
      if (currentSection == null) {
        currentSection = {
          'id': 'sec_1',
          'title': 'Prayers & Intro',
          'subtitle': '',
          'content': <Map<String, dynamic>>[],
        };
        sections.add(currentSection);
      }
      continue;
    }

    final matchA = aPattern.firstMatch(stripped);
    if (matchA != null && currentQNum != null) {
      currentAText = matchA.group(1) ?? '';
      isAnswering = true;
      isExplaining = false;
      continue;
    }

    if (currentQNum != null && !isAnswering && !isExplaining) {
      final qTrim = currentQText.trimRight();
      if (qTrim.endsWith('?') || qTrim.endsWith(':')) {
        currentAText = stripped;
        isAnswering = true;
        continue;
      }
    }

    if (isAnswering) {
      currentAText += ' $stripped';
    } else if (isExplaining) {
      if (currentExplanation.isNotEmpty) {
        currentExplanation[currentExplanation.length - 1] += ' $stripped';
      } else {
        currentExplanation.add(stripped);
      }
    } else if (currentQNum != null) {
      currentQText += ' $stripped';
    } else {
      if (sec != null) {
        if (stripped == stripped.toUpperCase() &&
            stripped.length < 70 &&
            !stripped.startsWith('Q.') &&
            !stripped.startsWith('A.')) {
          (sec['content'] as List<dynamic>).add({
            'type': 'heading',
            'text': formatTitleCase(stripped),
          });
        } else {
          final contentList = sec['content'] as List<dynamic>;
          if (contentList.isNotEmpty && contentList.last['type'] == 'text') {
            contentList.last['text'] = '${contentList.last['text']} $stripped';
          } else {
            contentList.add({'type': 'text', 'text': stripped});
          }
        }
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

  final toc = validSections.map((secItem) {
    String tocTitle = secItem['title'] as String;
    if ((secItem['subtitle'] as String).isNotEmpty) {
      tocTitle += ': ${secItem['subtitle']}';
    }
    return {'id': secItem['id'], 'title': tocTitle};
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

  var cleaned = cleanText(file.readAsStringSync());

  // Fix hyphenated words across line breaks (e.g. "accord- \n ing" -> "according")
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'(\b[a-zA-Z]+)-\s*\n\s*([a-zA-Z]+\b)'),
    (m) => '${m.group(1)}${m.group(2)}',
  );

  final lines = cleaned.split('\n');

  // Find start of main body (skip Gutenberg headers, Toc, and Prefaces)
  int mainBodyStartIdx = 0;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].toUpperCase().contains('DECREE OF THE COUNCIL OF TRENT')) {
      mainBodyStartIdx = i;
      break;
    }
  }

  final bodyLines = lines.sublist(mainBodyStartIdx);

  final List<Map<String, dynamic>> sections = [];
  String currentPart = 'Part 1';
  Map<String, dynamic>? currentSection;

  final partPattern = RegExp(
    r'^\s*(PART\s+[I|V|X\d]+)\.?\s*$',
    caseSensitive: false,
  );
  final chapPattern = RegExp(
    r'^\s*(CHAPTER\s+[I|V|X\d]+)\.?\s*$',
    caseSensitive: false,
  );
  final questionHeaderPattern = RegExp(
    r'^\s*(Que?stion\s+[I|V|X\d]+\.?\s*[\—\–\-]?\s*.*)',
    caseSensitive: false,
  );
  final runningHeaderPattern = RegExp(
    r'^\s*(\d+\s+)?(PART\s+[I|V|X]+|CATECHISM|THE TRANSLATOR|PREFACE).*?(\d+)?\s*$',
    caseSensitive: false,
  );
  final pageNumPattern = RegExp(r'^\s*\d+\s*$');
  final dotsPattern = RegExp(r'(\.\s*){4,}');

  for (final line in bodyLines) {
    final stripped = line.trim();
    if (stripped.isEmpty) continue;

    if (dotsPattern.hasMatch(stripped)) continue;

    if (pageNumPattern.hasMatch(stripped)) continue;
    if (runningHeaderPattern.hasMatch(stripped) &&
        stripped.length < 70 &&
        !questionHeaderPattern.hasMatch(stripped)) {
      continue;
    }

    final mPart = partPattern.firstMatch(stripped);
    if (mPart != null) {
      currentPart = formatTitleCase(mPart.group(1)!);
      continue;
    }

    final mChap = chapPattern.firstMatch(stripped);
    if (mChap != null) {
      final chapNum = formatTitleCase(mChap.group(1)!);
      final secId = 'sec_trent_${sections.length + 1}';

      currentSection = {
        'id': secId,
        'title': '$currentPart, $chapNum',
        'part': currentPart,
        'chapter': chapNum,
        'content': <Map<String, dynamic>>[],
      };
      sections.add(currentSection);
      continue;
    }

    final sec = currentSection;
    if (sec != null) {
      final mQHead = questionHeaderPattern.firstMatch(stripped);
      if (mQHead != null) {
        var qText = mQHead.group(1)!;
        qText = qText.replaceAll(
          RegExp(r'Quxstion', caseSensitive: false),
          'Question',
        );
        qText = qText.replaceAll(
          RegExp(r'Symiol', caseSensitive: false),
          'Symbol',
        );
        (sec['content'] as List<dynamic>).add({
          'type': 'heading',
          'text': formatTitleCase(qText.replaceAll(RegExp(r'\s+'), ' ').trim()),
        });
        continue;
      }

      final contentList = sec['content'] as List<dynamic>;
      if (contentList.isNotEmpty && contentList.last['type'] == 'text') {
        contentList.last['text'] = '${contentList.last['text']} $stripped';
      } else {
        contentList.add({'type': 'text', 'text': stripped});
      }
    }
  }

  for (final sec in sections) {
    for (final item in sec['content'] as List<dynamic>) {
      item['text'] = (item['text'] as String)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
  }

  final validSections = sections
      .where((s) => (s['content'] as List).isNotEmpty)
      .toList();

  final toc = validSections.map((secItem) {
    String title = secItem['title'] as String;
    final content = secItem['content'] as List<dynamic>;
    if (content.isNotEmpty && content.first['type'] == 'heading') {
      title += ': ${content.first['text']}';
    }
    return {'id': secItem['id'], 'title': title};
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
