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
    int foundStart = -1;
    int foundEnd = -1;
    for (int i = 0; i < lines.length; i++) {
      final stripped = lines[i].trim();
      if (foundStart == -1) {
        if (stripped.toUpperCase() == 'CATECHISM') {
          for (int j = i + 1; j < i + 10 && j < lines.length; j++) {
            if (lines[j].contains('Questions marked') ||
                lines[j].trim() == 'Lesson 1' ||
                lines[j].trim() == 'LESSON 1') {
              foundStart = i;
              break;
            }
          }
        }
      } else {
        if (stripped.toUpperCase().startsWith(
              'QUESTIONS ON THE EXPLANATIONS',
            ) ||
            stripped.toUpperCase().startsWith('NOTE--WHEREVER')) {
          foundEnd = i;
          break;
        }
      }
    }

    if (foundStart != -1) {
      bodyStartIdx = foundStart;
    } else {
      print(
        'Warning: Start marker for baltimore_4 not found. Defaulting to 0.',
      );
    }

    if (foundEnd != -1) {
      bodyEndIdx = foundEnd;
    } else {
      print(
        'Warning: End marker for baltimore_4 not found. Defaulting to end of file.',
      );
    }
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

void parseChapteredBookFile({
  required String filepath,
  required String bookId,
  required String secIdPrefix,
  required String title,
  required String subtitle,
  required String author,
  required Directory outputDir,
}) {
  final file = File(filepath);
  if (!file.existsSync()) {
    print('Error: $filepath not found!');
    return;
  }

  final raw = file.readAsStringSync();
  final lines = cleanText(raw).split('\n');

  final List<Map<String, dynamic>> sections = [];
  final List<Map<String, String>> toc = [];

  Map<String, dynamic>? currentSection;
  String currentChapterTitle = '';
  String currentChapterSubtitle = '';

  for (final line in lines) {
    final stripped = line.trim();
    if (stripped.isEmpty) continue;

    if (stripped.startsWith('The Didache:') ||
        stripped.startsWith('The First Epistle') ||
        stripped.startsWith('First Epistle') ||
        stripped.startsWith('The Second Epistle') ||
        stripped.startsWith('Second Epistle') ||
        stripped.startsWith('The Epistle to Diognetus') ||
        stripped.startsWith('Epistle of Ignatius') ||
        stripped.startsWith('The First Apology') ||
        stripped.startsWith('The Second Apology') ||
        stripped.startsWith('First Apology') ||
        stripped.startsWith('Second Apology') ||
        stripped.startsWith('Dialogue with Trypho') ||
        stripped.startsWith('Against Heresies:') ||
        stripped.startsWith('On the Incarnation') ||
        stripped.startsWith('The Confessions of St. Augustine:') ||
        stripped.startsWith('The City of God:') ||
        stripped.startsWith('Catechetical Lectures:') ||
        stripped.startsWith('The Five Theological Orations') ||
        stripped.startsWith('Theological Orations') ||
        stripped.startsWith('Oration ') ||
        stripped.startsWith('Ascent of Mount Carmel') ||
        stripped.startsWith('Subida del Monte Carmelo') ||
        stripped.startsWith('Dark Night of the Soul') ||
        stripped.startsWith('Noche Oscura del Alma') ||
        stripped.startsWith('By St. John of the Cross') ||
        stripped.startsWith('On the Mysteries') ||
        stripped.startsWith('On the Sacraments') ||
        stripped.startsWith('De Mysteriis') ||
        stripped.startsWith('De Sacramentis') ||
        stripped.startsWith('On the Holy Spirit') ||
        stripped.startsWith('De Spiritu Sancto') ||
        stripped.startsWith('True Devotion to Mary:') ||
        stripped.startsWith('Proslogion') ||
        stripped.startsWith('Cur Deus Homo') ||
        stripped.startsWith('The Rule of St. Benedict') ||
        stripped.startsWith('Regula Sancti Benedicti') ||
        stripped.startsWith('Introduction to the Devout Life:') ||
        stripped.startsWith('The Interior Castle') ||
        stripped.startsWith('El Castillo Interior') ||
        stripped.startsWith('By St. Teresa') ||
        stripped.startsWith('The Imitation of Christ') ||
        stripped.startsWith('De Imitatione Christi') ||
        stripped.startsWith("The Mind's Road to God") ||
        stripped.startsWith('Itinerarium Mentis in Deum') ||
        stripped.startsWith('Compendium of Theology:') ||
        stripped.startsWith('The Catechetical Instructions:') ||
        stripped.startsWith('Translated by')) {
      continue;
    }

    final chapterMatch = RegExp(
      r'^Chapter\s+(\d+)$',
      caseSensitive: false,
    ).firstMatch(stripped);
    if (chapterMatch != null) {
      final chapNum = int.parse(chapterMatch.group(1)!);
      final secId = 'sec_${secIdPrefix}_$chapNum';
      currentChapterTitle = 'Chapter $chapNum';
      currentChapterSubtitle = '';
      currentSection = {
        'id': secId,
        'title': currentChapterTitle,
        'subtitle': '',
        'content': <Map<String, dynamic>>[],
      };
      sections.add(currentSection);
      continue;
    }

    if (currentSection != null &&
        (currentSection['subtitle'] as String).isEmpty &&
        !RegExp(r'^\d+:\d+').hasMatch(stripped)) {
      currentChapterSubtitle = stripped;
      currentSection['subtitle'] = currentChapterSubtitle;
      final tocTitle = currentChapterSubtitle.isNotEmpty
          ? '${currentSection['title']}: $currentChapterSubtitle'
          : currentSection['title'] as String;
      toc.add({'id': currentSection['id'] as String, 'title': tocTitle});
      continue;
    }

    if (currentSection != null) {
      final verseMatch = RegExp(r'^\d+:(\d+)\s*(.*)$').firstMatch(stripped);
      if (verseMatch != null) {
        final vNum = verseMatch.group(1)!;
        final text = verseMatch.group(2)!.trim();
        (currentSection['content'] as List<dynamic>).add({
          'type': 'text',
          'text': '$vNum. $text',
        });
      } else {
        (currentSection['content'] as List<dynamic>).add({
          'type': 'text',
          'text': stripped,
        });
      }
    }
  }

  final finalJson = {
    'bookId': bookId,
    'title': title,
    'subtitle': subtitle,
    'author': author,
    'verseSystem': 'vulgate',
    'toc': toc,
    'sections': sections,
  };

  final outFile = File(p.join(outputDir.path, '$bookId.json'));
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(finalJson),
  );
  print(
    'Successfully generated ${outFile.path} (${sections.length} chapters, ${toc.length} TOC entries)',
  );
}

void parseDidacheFile(String filepath, Directory outputDir) {
  parseChapteredBookFile(
    filepath: filepath,
    bookId: 'didache_lightfoot',
    secIdPrefix: 'didache',
    title: 'The Didache',
    subtitle:
        'The Teaching of the Twelve Apostles (Trans. J. B. Lightfoot, 1891)',
    author: 'The Apostolic Fathers (Trans. J. B. Lightfoot)',
    outputDir: outputDir,
  );
}

void main() {
  final outputDir = Directory('assets/catechism/json');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final baltimoreDir = p.join('assets', 'catechism', 'baltimore');
  final trentDir = p.join('assets', 'catechism', 'trent');
  final didacheDir = p.join('assets', 'catechism', 'didache');
  final polycarpDir = p.join('assets', 'catechism', 'polycarp');
  final diognetusDir = p.join('assets', 'catechism', 'diognetus');
  final clementDir = p.join('assets', 'catechism', 'clement');
  final ignatiusDir = p.join('assets', 'catechism', 'ignatius');
  final justinDir = p.join('assets', 'catechism', 'justin');

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

  parseDidacheFile(p.join(didacheDir, 'didache_lightfoot.txt'), outputDir);

  parseChapteredBookFile(
    filepath: p.join(clementDir, 'first_clement_lightfoot.txt'),
    bookId: 'first_clement_lightfoot',
    secIdPrefix: 'first_clement',
    title: 'First Epistle of Clement',
    subtitle:
        'Letter of the Church of Rome to the Corinthians (Trans. J. B. Lightfoot, 1891)',
    author: 'Pope St. Clement of Rome (Trans. J. B. Lightfoot)',
    outputDir: outputDir,
  );

  parseChapteredBookFile(
    filepath: p.join(clementDir, 'second_clement_lightfoot.txt'),
    bookId: 'second_clement_lightfoot',
    secIdPrefix: 'second_clement',
    title: 'Second Epistle of Clement',
    subtitle: 'An Ancient Christian Homily (Trans. J. B. Lightfoot, 1891)',
    author: 'The Apostolic Fathers (Trans. J. B. Lightfoot)',
    outputDir: outputDir,
  );

  final ignatiusLetters = [
    (
      'ephesians',
      'Epistle of Ignatius to the Ephesians',
      'To the Ephesians (Trans. J. B. Lightfoot, 1891)',
    ),
    (
      'magnesians',
      'Epistle of Ignatius to the Magnesians',
      'To the Magnesians (Trans. J. B. Lightfoot, 1891)',
    ),
    (
      'trallians',
      'Epistle of Ignatius to the Trallians',
      'To the Trallians (Trans. J. B. Lightfoot, 1891)',
    ),
    (
      'romans',
      'Epistle of Ignatius to the Romans',
      'To the Romans (Trans. J. B. Lightfoot, 1891)',
    ),
    (
      'philadelphians',
      'Epistle of Ignatius to the Philadelphians',
      'To the Philadelphians (Trans. J. B. Lightfoot, 1891)',
    ),
    (
      'smyrnaeans',
      'Epistle of Ignatius to the Smyrnaeans',
      'To the Smyrnaeans (Trans. J. B. Lightfoot, 1891)',
    ),
    (
      'polycarp',
      'Epistle of Ignatius to Polycarp',
      'To Polycarp (Trans. J. B. Lightfoot, 1891)',
    ),
  ];

  for (final (slug, title, subtitle) in ignatiusLetters) {
    parseChapteredBookFile(
      filepath: p.join(ignatiusDir, 'ignatius_${slug}_lightfoot.txt'),
      bookId: 'ignatius_${slug}_lightfoot',
      secIdPrefix: 'ignatius_$slug',
      title: title,
      subtitle: subtitle,
      author: 'St. Ignatius of Antioch (Trans. J. B. Lightfoot)',
      outputDir: outputDir,
    );
  }

  parseChapteredBookFile(
    filepath: p.join(polycarpDir, 'polycarp_philippians_lightfoot.txt'),
    bookId: 'polycarp_philippians_lightfoot',
    secIdPrefix: 'polycarp_philippians',
    title: 'Epistle of Polycarp to the Philippians',
    subtitle: 'To the Church of God at Philippi (Trans. J. B. Lightfoot, 1891)',
    author: 'St. Polycarp of Smyrna (Trans. J. B. Lightfoot)',
    outputDir: outputDir,
  );

  parseChapteredBookFile(
    filepath: p.join(polycarpDir, 'polycarp_martyrdom_lightfoot.txt'),
    bookId: 'polycarp_martyrdom_lightfoot',
    secIdPrefix: 'polycarp_martyrdom',
    title: 'The Martyrdom of Polycarp',
    subtitle:
        'Encyclical Epistle of the Church at Smyrna (Trans. J. B. Lightfoot, 1891)',
    author: 'The Church of Smyrna (Trans. J. B. Lightfoot)',
    outputDir: outputDir,
  );

  parseChapteredBookFile(
    filepath: p.join(diognetusDir, 'diognetus_lightfoot.txt'),
    bookId: 'diognetus_lightfoot',
    secIdPrefix: 'diognetus',
    title: 'The Epistle to Diognetus',
    subtitle: 'Letter to Diognetus (Trans. J. B. Lightfoot, 1891)',
    author: 'The Apostolic Fathers (Trans. J. B. Lightfoot)',
    outputDir: outputDir,
  );

  parseChapteredBookFile(
    filepath: p.join(justinDir, 'justin_first_apology_dods.txt'),
    bookId: 'justin_first_apology_dods',
    secIdPrefix: 'justin_first_apology',
    title: 'The First Apology of St. Justin Martyr',
    subtitle: 'Addressed to Emperor Antoninus Pius (Trans. Marcus Dods, 1885)',
    author: 'St. Justin Martyr (Trans. Marcus Dods)',
    outputDir: outputDir,
  );

  parseChapteredBookFile(
    filepath: p.join(justinDir, 'justin_second_apology_dods.txt'),
    bookId: 'justin_second_apology_dods',
    secIdPrefix: 'justin_second_apology',
    title: 'The Second Apology of St. Justin Martyr',
    subtitle: 'Addressed to the Roman Senate (Trans. Marcus Dods, 1885)',
    author: 'St. Justin Martyr (Trans. Marcus Dods)',
    outputDir: outputDir,
  );

  parseChapteredBookFile(
    filepath: p.join(justinDir, 'justin_dialogue_trypho_dods.txt'),
    bookId: 'justin_dialogue_trypho_dods',
    secIdPrefix: 'justin_dialogue_trypho',
    title: 'Dialogue with Trypho',
    subtitle:
        'Dialogus cum Tryphone Judaeo (Trans. Marcus Dods & George Reith, 1885)',
    author: 'St. Justin Martyr (Trans. Marcus Dods & George Reith)',
    outputDir: outputDir,
  );

  final irenaeusDir = p.join('assets', 'catechism', 'irenaeus');
  final athanasiusDir = p.join('assets', 'catechism', 'athanasius');

  final irenaeusBooks = [
    (
      'book1',
      'Against Heresies: Book I',
      'Gnostic Sects and Heresies (Trans. Roberts & Rambaut, 1885)',
    ),
    (
      'book2',
      'Against Heresies: Book II',
      'Refutation of Gnosticism (Trans. Roberts & Rambaut, 1885)',
    ),
    (
      'book3',
      'Against Heresies: Book III',
      'The Rule of Faith and Apostolic Succession (Trans. Roberts & Rambaut, 1885)',
    ),
    (
      'book4',
      'Against Heresies: Book IV',
      'Unity of Old and New Testaments (Trans. Roberts & Rambaut, 1885)',
    ),
    (
      'book5',
      'Against Heresies: Book V',
      'The Incarnation and Resurrection of the Flesh (Trans. Roberts & Rambaut, 1885)',
    ),
  ];

  for (final (slug, title, subtitle) in irenaeusBooks) {
    parseChapteredBookFile(
      filepath: p.join(irenaeusDir, 'irenaeus_against_heresies_$slug.txt'),
      bookId: 'irenaeus_against_heresies_$slug',
      secIdPrefix: 'irenaeus_$slug',
      title: title,
      subtitle: subtitle,
      author: 'St. Irenaeus of Lyons (Trans. Roberts & Rambaut)',
      outputDir: outputDir,
    );
  }

  parseChapteredBookFile(
    filepath: p.join(athanasiusDir, 'athanasius_on_the_incarnation.txt'),
    bookId: 'athanasius_on_the_incarnation',
    secIdPrefix: 'athanasius_incarnation',
    title: 'On the Incarnation of the Word',
    subtitle: 'De Incarnatione Verbi Dei (Trans. Archibald Robertson, 1892)',
    author: 'St. Athanasius of Alexandria (Trans. Archibald Robertson)',
    outputDir: outputDir,
  );

  final augustineDir = p.join('assets', 'catechism', 'augustine');

  final confessionsSubtitles = [
    'Infancy and Childhood (Trans. E. B. Pusey, 1838)',
    'Youth and the Pear Tree (Trans. E. B. Pusey, 1838)',
    'Carthage and Manichaeism (Trans. E. B. Pusey, 1838)',
    'Teaching Rhetoric and Grief (Trans. E. B. Pusey, 1838)',
    'Rome and Milan (Trans. E. B. Pusey, 1838)',
    'Moral Struggles and Friends (Trans. E. B. Pusey, 1838)',
    'Neoplatonism and the Word (Trans. E. B. Pusey, 1838)',
    'Conversion in the Garden (Trans. E. B. Pusey, 1838)',
    'Baptism and Death of Monica (Trans. E. B. Pusey, 1838)',
    'Memory and Self-Examination (Trans. E. B. Pusey, 1838)',
    'Time and Eternity (Trans. E. B. Pusey, 1838)',
    'Heaven, Earth, and Scripture (Trans. E. B. Pusey, 1838)',
    'The Allegory of Creation (Trans. E. B. Pusey, 1838)',
  ];

  for (int b = 1; b <= 13; b++) {
    parseChapteredBookFile(
      filepath: p.join(augustineDir, 'augustine_confessions_book$b.txt'),
      bookId: 'augustine_confessions_book$b',
      secIdPrefix: 'augustine_confessions_b$b',
      title: 'The Confessions: Book $b',
      subtitle: confessionsSubtitles[b - 1],
      author: 'St. Augustine of Hippo (Trans. E. B. Pusey)',
      outputDir: outputDir,
    );
  }

  final cityOfGodSubtitles = [
    'The Sack of Rome (Trans. Marcus Dods, 1871)',
    'Moral Evils of Rome (Trans. Marcus Dods, 1871)',
    'Physical Calamities of Rome (Trans. Marcus Dods, 1871)',
    'Imperial Greatness and True God (Trans. Marcus Dods, 1871)',
    'Fate, Providence, and Free Will (Trans. Marcus Dods, 1871)',
    'Varro and Civil Theology (Trans. Marcus Dods, 1871)',
    'Natural Theology and Pagan Gods (Trans. Marcus Dods, 1871)',
    'Platonism and Demonology (Trans. Marcus Dods, 1871)',
    'Demons vs. Christ the Mediator (Trans. Marcus Dods, 1871)',
    'Sacrifice, Angels, and Porphyry (Trans. Marcus Dods, 1871)',
    'Creation and the Two Angelic Cities (Trans. Marcus Dods, 1871)',
    'The Nature of Angels and Creation of Man (Trans. Marcus Dods, 1871)',
    'The Fall and Human Mortality (Trans. Marcus Dods, 1871)',
    'The Two Loves and Two Cities (Trans. Marcus Dods, 1871)',
    'The Two Cities in Genesis: Cain and Abel (Trans. Marcus Dods, 1871)',
    'From Noah to the Kings of Israel (Trans. Marcus Dods, 1871)',
    'The Prophets and King David (Trans. Marcus Dods, 1871)',
    'Parallel Histories of the Two Cities (Trans. Marcus Dods, 1871)',
    'Peace and the Supreme Good (Trans. Marcus Dods, 1871)',
    'The Last Judgment (Trans. Marcus Dods, 1871)',
    'The Punishment of the Earthly City (Trans. Marcus Dods, 1871)',
    'The Eternal Bliss of the City of God (Trans. Marcus Dods, 1871)',
  ];

  for (int b = 1; b <= 22; b++) {
    parseChapteredBookFile(
      filepath: p.join(augustineDir, 'augustine_city_of_god_book$b.txt'),
      bookId: 'augustine_city_of_god_book$b',
      secIdPrefix: 'augustine_city_of_god_b$b',
      title: 'The City of God: Book $b',
      subtitle: cityOfGodSubtitles[b - 1],
      author: 'St. Augustine of Hippo (Trans. Marcus Dods)',
      outputDir: outputDir,
    );
  }

  final cyrilDir = p.join('assets', 'catechism', 'cyril');

  final cyrilVolumes = [
    (
      'vol1',
      'Catechetical Lectures: Vol. I',
      'Procatechesis & General Catechesis (Trans. E. H. Gifford, 1893)',
    ),
    (
      'vol2',
      'Catechetical Lectures: Vol. II',
      'The Creed: God the Father & The Son (Trans. E. H. Gifford, 1893)',
    ),
    (
      'vol3',
      'Catechetical Lectures: Vol. III',
      'The Creed: Incarnation, Spirit & Church (Trans. E. H. Gifford, 1893)',
    ),
    (
      'vol4',
      'Catechetical Lectures: Vol. IV',
      'The Mystagogical Lectures (Trans. E. H. Gifford, 1893)',
    ),
  ];

  for (final (slug, title, subtitle) in cyrilVolumes) {
    parseChapteredBookFile(
      filepath: p.join(cyrilDir, 'cyril_catechetical_lectures_$slug.txt'),
      bookId: 'cyril_catechetical_lectures_$slug',
      secIdPrefix: 'cyril_lectures_$slug',
      title: title,
      subtitle: subtitle,
      author: 'St. Cyril of Jerusalem (Trans. E. H. Gifford)',
      outputDir: outputDir,
    );
  }

  final gregoryDir = p.join('assets', 'catechism', 'gregory');

  final gregoryOrations = [
    (
      'oration1',
      'The Five Theological Orations: Oration I',
      'Oration 27: Against the Eunomians (Trans. Browne & Swallow, 1894)',
    ),
    (
      'oration2',
      'The Five Theological Orations: Oration II',
      'Oration 28: On the Doctrine of God (Trans. Browne & Swallow, 1894)',
    ),
    (
      'oration3',
      'The Five Theological Orations: Oration III',
      'Oration 29: On the Son — I (Trans. Browne & Swallow, 1894)',
    ),
    (
      'oration4',
      'The Five Theological Orations: Oration IV',
      'Oration 30: On the Son — II (Trans. Browne & Swallow, 1894)',
    ),
    (
      'oration5',
      'The Five Theological Orations: Oration V',
      'Oration 31: On the Holy Spirit (Trans. Browne & Swallow, 1894)',
    ),
  ];

  for (final (slug, title, subtitle) in gregoryOrations) {
    parseChapteredBookFile(
      filepath: p.join(gregoryDir, 'gregory_theological_orations_$slug.txt'),
      bookId: 'gregory_theological_orations_$slug',
      secIdPrefix: 'gregory_theological_orations_$slug',
      title: title,
      subtitle: subtitle,
      author: 'St. Gregory of Nazianzus (Trans. Browne & Swallow)',
      outputDir: outputDir,
    );
  }

  final johnCrossDir = p.join('assets', 'catechism', 'john_of_the_cross');

  // 1. Ascent of Mount Carmel
  parseChapteredBookFile(
    filepath: p.join(johnCrossDir, 'john_cross_ascent_mount_carmel.txt'),
    bookId: 'john_cross_ascent_mount_carmel',
    secIdPrefix: 'john_cross_ascent_mount_carmel',
    title: 'Ascent of Mount Carmel',
    subtitle:
        'Subida del Monte Carmelo (Trans. David Lewis, Rev. Benedict Zimmerman, O.C.D.)',
    author: 'St. John of the Cross',
    outputDir: outputDir,
  );

  // 2. Dark Night of the Soul
  parseChapteredBookFile(
    filepath: p.join(johnCrossDir, 'john_cross_dark_night_soul.txt'),
    bookId: 'john_cross_dark_night_soul',
    secIdPrefix: 'john_cross_dark_night_soul',
    title: 'Dark Night of the Soul',
    subtitle:
        'Noche Oscura del Alma (Trans. David Lewis, Rev. Benedict Zimmerman, O.C.D.)',
    author: 'St. John of the Cross',
    outputDir: outputDir,
  );

  final ambroseDir = p.join('assets', 'catechism', 'ambrose');
  parseChapteredBookFile(
    filepath: p.join(ambroseDir, 'ambrose_on_the_mysteries.txt'),
    bookId: 'ambrose_on_the_mysteries',
    secIdPrefix: 'ambrose_mysteries',
    title: 'On the Mysteries',
    subtitle: 'De Mysteriis (Trans. Thompson & Srawley, 1919)',
    author: 'St. Ambrose of Milan (Trans. T. Thompson & J. H. Srawley)',
    outputDir: outputDir,
  );

  parseChapteredBookFile(
    filepath: p.join(ambroseDir, 'ambrose_on_the_sacraments.txt'),
    bookId: 'ambrose_on_the_sacraments',
    secIdPrefix: 'ambrose_sacraments',
    title: 'On the Sacraments',
    subtitle: 'De Sacramentis (Trans. Thompson & Srawley, 1919)',
    author: 'St. Ambrose of Milan (Trans. T. Thompson & J. H. Srawley)',
    outputDir: outputDir,
  );

  final aquinasDir = p.join('assets', 'catechism', 'aquinas');

  final compendiumVolumes = [
    (
      'part1',
      'Compendium of Theology: Part I',
      'On Faith (Trans. Cyril Vollert, S.J., 1947)',
    ),
    (
      'part2',
      'Compendium of Theology: Part II',
      'On Hope (Trans. Cyril Vollert, S.J., 1947)',
    ),
  ];

  for (final (slug, title, subtitle) in compendiumVolumes) {
    parseChapteredBookFile(
      filepath: p.join(aquinasDir, 'aquinas_compendium_of_theology_$slug.txt'),
      bookId: 'aquinas_compendium_of_theology_$slug',
      secIdPrefix: 'aquinas_compendium_$slug',
      title: title,
      subtitle: subtitle,
      author: 'St. Thomas Aquinas (Trans. Cyril Vollert)',
      outputDir: outputDir,
    );
  }

  final catecheticalVolumes = [
    (
      'creed',
      'The Catechetical Instructions: Part I',
      'The Apostles\' Creed (Trans. Joseph B. Collins, 1939)',
    ),
    (
      'sacraments',
      'The Catechetical Instructions: Part II',
      'The Sacraments of the Church (Trans. Joseph B. Collins, 1939)',
    ),
    (
      'commandments',
      'The Catechetical Instructions: Part III',
      'The Ten Commandments (Trans. Joseph B. Collins, 1939)',
    ),
    (
      'prayer',
      'The Catechetical Instructions: Part IV',
      'The Lord\'s Prayer (Trans. Joseph B. Collins, 1939)',
    ),
    (
      'hail_mary',
      'The Catechetical Instructions: Part V',
      'The Hail Mary (Trans. Joseph B. Collins, 1939)',
    ),
  ];

  for (final (slug, title, subtitle) in catecheticalVolumes) {
    parseChapteredBookFile(
      filepath: p.join(aquinasDir, 'aquinas_catechetical_$slug.txt'),
      bookId: 'aquinas_catechetical_$slug',
      secIdPrefix: 'aquinas_catechetical_$slug',
      title: title,
      subtitle: subtitle,
      author: 'St. Thomas Aquinas (Trans. Joseph B. Collins)',
      outputDir: outputDir,
    );
  }

  final montfortDir = p.join('assets', 'catechism', 'montfort');
  parseChapteredBookFile(
    filepath: p.join(montfortDir, 'montfort_true_devotion.txt'),
    bookId: 'montfort_true_devotion',
    secIdPrefix: 'montfort_true_devotion',
    title: 'True Devotion to Mary',
    subtitle:
        'Traité de la vraie dévotion (Trans. Fr. Frederick W. Faber, 1862)',
    author: 'St. Louis-Marie de Montfort (Trans. Fr. Frederick W. Faber)',
    outputDir: outputDir,
  );

  final anselmDir = p.join('assets', 'catechism', 'anselm');

  parseChapteredBookFile(
    filepath: p.join(anselmDir, 'anselm_proslogion.txt'),
    bookId: 'anselm_proslogion',
    secIdPrefix: 'anselm_proslogion',
    title: 'Proslogion',
    subtitle: 'Faith Seeking Understanding (Trans. Sidney Norton Deane, 1903)',
    author: 'St. Anselm of Canterbury (Trans. Sidney Norton Deane)',
    outputDir: outputDir,
  );

  parseChapteredBookFile(
    filepath: p.join(anselmDir, 'anselm_cur_deus_homo_book1.txt'),
    bookId: 'anselm_cur_deus_homo_book1',
    secIdPrefix: 'anselm_cur_deus_b1',
    title: 'Cur Deus Homo: Book I',
    subtitle: 'The Necessity of Redemption (Trans. Sidney Norton Deane, 1903)',
    author: 'St. Anselm of Canterbury (Trans. Sidney Norton Deane)',
    outputDir: outputDir,
  );

  parseChapteredBookFile(
    filepath: p.join(anselmDir, 'anselm_cur_deus_homo_book2.txt'),
    bookId: 'anselm_cur_deus_homo_book2',
    secIdPrefix: 'anselm_cur_deus_b2',
    title: 'Cur Deus Homo: Book II',
    subtitle: 'The God-Man and Atonement (Trans. Sidney Norton Deane, 1903)',
    author: 'St. Anselm of Canterbury (Trans. Sidney Norton Deane)',
    outputDir: outputDir,
  );

  final benedictDir = p.join('assets', 'catechism', 'benedict');
  parseChapteredBookFile(
    filepath: p.join(benedictDir, 'benedict_rule.txt'),
    bookId: 'benedict_rule',
    secIdPrefix: 'benedict_rule',
    title: 'The Rule of St. Benedict',
    subtitle:
        'Regula Sancti Benedicti (Trans. Rev. Boniface Verheyen, O.S.B., 1928)',
    author: 'St. Benedict of Nursia (Trans. Rev. Boniface Verheyen, O.S.B.)',
    outputDir: outputDir,
  );

  final salesDir = p.join('assets', 'catechism', 'francis_de_sales');

  final salesParts = [
    (
      'part1',
      'p1',
      'Introduction to the Devout Life: Part I',
      'Counsels & Exercises for the Soul\'s First Desire (Trans. Allan Ross / Rivingtons)',
    ),
    (
      'part2',
      'p2',
      'Introduction to the Devout Life: Part II',
      'Counsels for Elevating the Soul in Prayer & Sacraments (Trans. Allan Ross / Rivingtons)',
    ),
    (
      'part3',
      'p3',
      'Introduction to the Devout Life: Part III',
      'Counsels Concerning the Practice of Virtues (Trans. Allan Ross / Rivingtons)',
    ),
    (
      'part4',
      'p4',
      'Introduction to the Devout Life: Part IV',
      'Necessary Counsels Against Ordinary Temptations (Trans. Allan Ross / Rivingtons)',
    ),
    (
      'part5',
      'p5',
      'Introduction to the Devout Life: Part V',
      'Exercises & Counsels for Renewing the Soul in Devotion (Trans. Allan Ross / Rivingtons)',
    ),
  ];

  for (final (partSlug, secPrefix, title, subtitle) in salesParts) {
    parseChapteredBookFile(
      filepath: p.join(salesDir, 'sales_devout_life_$partSlug.txt'),
      bookId: 'sales_devout_life_$partSlug',
      secIdPrefix: 'sales_devout_life_$secPrefix',
      title: title,
      subtitle: subtitle,
      author: 'St. Francis de Sales (Trans. Allan Ross)',
      outputDir: outputDir,
    );
  }

  final teresaDir = p.join('assets', 'catechism', 'teresa');
  parseChapteredBookFile(
    filepath: p.join(teresaDir, 'teresa_interior_castle.txt'),
    bookId: 'teresa_interior_castle',
    secIdPrefix: 'teresa_interior_castle',
    title: 'The Interior Castle',
    subtitle:
        'El Castillo Interior / Las Moradas (Trans. Benedictines of Stanbrook, 1906)',
    author: 'St. Teresa of Ávila (Trans. Benedictines of Stanbrook)',
    outputDir: outputDir,
  );

  final kempisDir = p.join('assets', 'catechism', 'kempis');
  parseChapteredBookFile(
    filepath: p.join(kempisDir, 'kempis_imitation_of_christ.txt'),
    bookId: 'kempis_imitation_of_christ',
    secIdPrefix: 'kempis_imitation',
    title: 'The Imitation of Christ',
    subtitle:
        'De Imitatione Christi (Trans. Richard Challoner / William Benham)',
    author: 'Thomas à Kempis',
    outputDir: outputDir,
  );

  final bonaventureDir = p.join('assets', 'catechism', 'bonaventure');

  parseChapteredBookFile(
    filepath: p.join(bonaventureDir, 'bonaventure_minds_road_to_god.txt'),
    bookId: 'bonaventure_minds_road_to_god',
    secIdPrefix: 'bonaventure_minds_road',
    title: "The Mind's Road to God",
    subtitle: 'Itinerarium Mentis in Deum (Trans. George Boas, 1953)',
    author: 'St. Bonaventure (Trans. George Boas)',
    outputDir: outputDir,
  );

  final basilDir = p.join('assets', 'catechism', 'basil');
  parseChapteredBookFile(
    filepath: p.join(basilDir, 'basil_on_the_holy_spirit.txt'),
    bookId: 'basil_on_the_holy_spirit',
    secIdPrefix: 'basil_holy_spirit',
    title: 'On the Holy Spirit',
    subtitle: 'De Spiritu Sancto (Trans. Blomfield Jackson, 1895)',
    author: 'St. Basil the Great (Trans. Blomfield Jackson)',
    outputDir: outputDir,
  );
}
