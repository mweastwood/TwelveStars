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
      String cleanQ = currentQText.replaceAll(RegExp(r'\s+'), ' ').trim();
      int? crossRefQNum;
      final refMatch = RegExp(r'\{(\d+)\}').firstMatch(cleanQ);
      if (refMatch != null) {
        crossRefQNum = int.parse(refMatch.group(1)!);
        cleanQ = cleanQ.replaceAll(RegExp(r'\{(\d+)\}\s*'), '').trim();
      }

      final Map<String, dynamic> entry = {
        'type': 'qa',
        'questionNumber': currentQNum,
        'question': cleanQ,
        'answer': currentAText.replaceAll(RegExp(r'\s+'), ' ').trim(),
      };
      if (crossRefQNum != null) {
        entry['crossRefQNum'] = crossRefQNum;
      }
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

  int bodyStartIdx = 0;
  int bodyEndIdx = lines.length;
  if (bookId == 'baltimore_3') {
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim() == 'Catechism of Christian Doctrine') {
        bodyStartIdx = i;
        break;
      }
    }
  } else if (bookId == 'baltimore_4') {
    bodyStartIdx = 1270;
    bodyEndIdx = 11778;
  }

  final bodyLines = lines.sublist(bodyStartIdx, bodyEndIdx);
  bool isParagraphBreak = false;

  for (final line in bodyLines) {
    final stripped = line.trim();
    if (stripped.isEmpty) {
      if (isAnswering) {
        isAnswering = false;
        isExplaining = true;
      }
      if (isExplaining &&
          currentExplanation.isNotEmpty &&
          currentExplanation.last.isNotEmpty) {
        currentExplanation.add('');
      }
      isParagraphBreak = true;
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
      isParagraphBreak = false;
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
        isParagraphBreak = false;
        continue;
      }
    }

    final matchQ = qPattern.firstMatch(stripped);
    if (matchQ != null) {
      finalizeQa();
      isParagraphBreak = false;
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
      isParagraphBreak = false;
      continue;
    }

    if (currentQNum != null && !isAnswering && !isExplaining) {
      final qTrim = currentQText.trimRight();
      if (qTrim.endsWith('?') || qTrim.endsWith(':')) {
        currentAText = stripped;
        isAnswering = true;
        isParagraphBreak = false;
        continue;
      }
    }

    if (isAnswering) {
      currentAText += ' $stripped';
      isParagraphBreak = false;
    } else if (isExplaining) {
      if (currentExplanation.isNotEmpty) {
        if (currentExplanation.last.isEmpty) {
          currentExplanation[currentExplanation.length - 1] = stripped;
        } else {
          currentExplanation[currentExplanation.length - 1] += ' $stripped';
        }
      } else {
        currentExplanation.add(stripped);
      }
      isParagraphBreak = false;
    } else if (currentQNum != null) {
      currentQText += ' $stripped';
      isParagraphBreak = false;
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
          isParagraphBreak = false;
        } else {
          final contentList = sec['content'] as List<dynamic>;
          if (contentList.isNotEmpty &&
              contentList.last['type'] == 'text' &&
              !isParagraphBreak) {
            contentList.last['text'] = '${contentList.last['text']} $stripped';
          } else {
            contentList.add({'type': 'text', 'text': stripped});
          }
          isParagraphBreak = false;
        }
      }
    }
  }

  finalizeQa();

  final validSections = sections
      .where((s) => (s['content'] as List).isNotEmpty)
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

void assembleTrentFromSource(String sourcePath, Directory outputDir) {
  final file = File(sourcePath);
  if (!file.existsSync()) {
    print('Error: $sourcePath not found!');
    return;
  }

  final rawData = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  final List<Map<String, dynamic>> sections = [];
  final List<Map<String, String>> toc = [];

  int secCounter = 1;

  for (final part in rawData) {
    final partNum = part['partNumber'] ?? 1;
    final partTitle = part['title'] as String? ?? 'Part $partNum';

    // 1. Part Introduction
    final intro = part['introduction'] as Map<String, dynamic>?;
    if (intro != null && intro['sections'] != null) {
      final secId = 'sec_trent_$secCounter';
      secCounter++;

      final secTitle = 'Part $partNum: $partTitle';
      const secSub = 'Introduction';
      final List<Map<String, dynamic>> content = [];

      for (final isec in intro['sections'] as List<dynamic>) {
        final stitle = isec['title'] as String?;
        if (stitle != null && stitle.isNotEmpty) {
          content.add({'type': 'heading', 'text': stitle});
        }
        for (final p in isec['paragraphs'] as List<dynamic>) {
          final ptext = (p['text'] as String? ?? '').trim();
          if (ptext.isNotEmpty) {
            content.add({'type': 'text', 'text': ptext});
          }
        }
      }

      if (content.isNotEmpty) {
        sections.add({
          'id': secId,
          'title': secTitle,
          'subtitle': secSub,
          'content': content,
        });
        toc.add({'id': secId, 'title': '$secTitle - $secSub'});
      }
    }

    // 2. Part Articles
    final articles = part['articles'] as List<dynamic>? ?? [];
    for (final art in articles) {
      final artNum = art['articleNumber'];
      final artTitle = art['title'] as String? ?? '';
      final artHeading = art['heading'] as String? ?? '';

      final secId = 'sec_trent_$secCounter';
      secCounter++;

      final fullTitle = artNum != null && '$artNum'.isNotEmpty
          ? 'Part $partNum, Article $artNum'
          : 'Part $partNum';
      final subtitle = artTitle.isNotEmpty
          ? artTitle
          : (artHeading.length > 60 ? artHeading.substring(0, 60) : artHeading);

      final List<Map<String, dynamic>> content = [];
      if (artHeading.isNotEmpty && artHeading != artTitle) {
        content.add({'type': 'heading', 'text': artHeading});
      }

      for (final isec in art['sections'] as List<dynamic>? ?? []) {
        final stitle = isec['title'] as String?;
        if (stitle != null && stitle.isNotEmpty) {
          content.add({'type': 'heading', 'text': stitle});
        }
        for (final p in isec['paragraphs'] as List<dynamic>? ?? []) {
          final ptext = (p['text'] as String? ?? '').trim();
          if (ptext.isNotEmpty) {
            content.add({'type': 'text', 'text': ptext});
          }
        }
      }

      if (content.isNotEmpty) {
        sections.add({
          'id': secId,
          'title': fullTitle,
          'subtitle': subtitle,
          'content': content,
        });
        final tocText = subtitle.isNotEmpty
            ? '$fullTitle: $subtitle'
            : fullTitle;
        toc.add({'id': secId, 'title': tocText});
      }
    }
  }

  final finalJson = {
    'bookId': 'council_of_trent',
    'title': 'Catechism of the Council of Trent',
    'subtitle':
        'The Roman Catechism (Translated by Rev. J. A. McHugh & C. J. Callan, 1923)',
    'author': 'Council of Trent / St. Pius V',
    'toc': toc,
    'sections': sections,
  };

  final outFile = File(p.join(outputDir.path, 'council_of_trent.json'));
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(finalJson),
  );
  print(
    'Successfully generated ${outFile.path} (${sections.length} sections, ${toc.length} TOC entries)',
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

  assembleTrentFromSource(
    p.join(trentDir, 'trent_romanus_source.json'),
    outputDir,
  );
}
