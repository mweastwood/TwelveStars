// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:twelve_stars/logic/reader/library_models.dart';
import 'package:twelve_stars/logic/thematic_models.dart';

/// Formal taxonomy for categorizing TwelveStars library passages.
class ThematicTaxonomy {
  static Map<String, Map<String, String>> get categories =>
      ThematicTaxonomyData.categories;

  static Map<String, String> get allThemes => ThematicTaxonomyData.allThemes;

  static bool isValidTheme(String themeId) =>
      ThematicTaxonomyData.isValidTheme(themeId);

  static String? normalizeTheme(String? themeId) =>
      ThematicTaxonomyData.normalizeTheme(themeId);
}

/// Categorized passage result from a subagent.
typedef CategorizedPassage = ThematicPassage;

/// Helper to extract clean JSON array substring from LLM response.
String extractJsonArray(String raw) {
  final match = RegExp(r'\[[\s\S]*\]').firstMatch(raw);
  if (match != null) {
    return match.group(0)!;
  }
  return raw.trim();
}

/// Represents a raw section batch with un-chunked items for LLM semantic chunking.
class RawSectionBatch {
  final String bookId;
  final String bookTitle;
  final String author;
  final String sectionId;
  final String sectionTitle;
  final String? sectionSubtitle;
  final List<Map<String, dynamic>> items;

  RawSectionBatch({
    required this.bookId,
    required this.bookTitle,
    required this.author,
    required this.sectionId,
    required this.sectionTitle,
    this.sectionSubtitle,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'bookTitle': bookTitle,
    'author': author,
    'sectionId': sectionId,
    'sectionTitle': sectionTitle,
    if (sectionSubtitle != null && sectionSubtitle!.isNotEmpty)
      'sectionSubtitle': sectionSubtitle,
    'items': items,
  };
}

/// Helper to load book JSON and extract raw section batches for LLM semantic chunking.
List<RawSectionBatch> extractSectionBatchesFromBook(
  File bookFile, {
  int maxItemsPerBatch = 20,
}) {
  final content =
      jsonDecode(bookFile.readAsStringSync()) as Map<String, dynamic>;
  final parsedBook = ParsedBookData.fromJson(content);
  final bookId = parsedBook.bookId.isNotEmpty
      ? parsedBook.bookId
      : p.basenameWithoutExtension(bookFile.path);
  final bookTitle = parsedBook.title.isNotEmpty ? parsedBook.title : bookId;
  final author = parsedBook.author;

  final List<RawSectionBatch> batches = [];

  for (final sec in parsedBook.sections) {
    final secId = sec.id;
    final secTitle = sec.title;
    final secSubtitle = sec.subtitle.isNotEmpty ? sec.subtitle : null;
    final rawItems = sec.content;

    final List<Map<String, dynamic>> cleanItems = [];
    for (int i = 0; i < rawItems.length; i++) {
      final item = rawItems[i];
      if (item.type == 'heading') continue;

      if (item.type == 'qa') {
        final qNum = item.questionNumber;
        final q = item.question ?? '';
        final a = item.answer ?? '';
        final exp = item.explanation;
        String text = 'Q. $qNum $q\nA. $a';
        if (exp != null && exp.trim().isNotEmpty) {
          text += '\nExplanation: ${exp.trim()}';
        }
        cleanItems.add({
          'itemIndex': i,
          'questionNumber': ?qNum,
          'type': 'qa',
          'text': text,
        });
      } else {
        final text = (item.text ?? '').trim();
        if (text.isEmpty) continue;
        cleanItems.add({'itemIndex': i, 'type': 'text', 'text': text});
      }
    }

    if (cleanItems.isEmpty) continue;

    if (cleanItems.length <= maxItemsPerBatch) {
      batches.add(
        RawSectionBatch(
          bookId: bookId,
          bookTitle: bookTitle,
          author: author,
          sectionId: secId,
          sectionTitle: secTitle,
          sectionSubtitle: secSubtitle,
          items: cleanItems,
        ),
      );
    } else {
      for (int i = 0; i < cleanItems.length; i += maxItemsPerBatch) {
        final end = (i + maxItemsPerBatch < cleanItems.length)
            ? i + maxItemsPerBatch
            : cleanItems.length;
        batches.add(
          RawSectionBatch(
            bookId: bookId,
            bookTitle: bookTitle,
            author: author,
            sectionId: secId,
            sectionTitle: secTitle,
            sectionSubtitle: secSubtitle,
            items: cleanItems.sublist(i, end),
          ),
        );
      }
    }
  }

  return batches;
}

/// Generates a standardized prompt for LLM-driven semantic chunking and categorization.
String buildSubagentPrompt({
  required RawSectionBatch sectionBatch,
  required int batchNumber,
  required int totalBatches,
}) {
  final taxonomyBuffer = StringBuffer();
  for (final entry in ThematicTaxonomy.categories.entries) {
    taxonomyBuffer.writeln('### ${entry.key}:');
    for (final theme in entry.value.entries) {
      taxonomyBuffer.writeln('- `${theme.key}`: ${theme.value}');
    }
    taxonomyBuffer.writeln();
  }

  final itemsJson = jsonEncode(sectionBatch.items);

  return '''
You are a patristic scholar and Catholic theologian categorizing text passages for the TwelveStars library.

### TASK:
Perform LLM semantic chunking and thematic categorization on the following section items from "${sectionBatch.bookTitle}" by ${sectionBatch.author} (${sectionBatch.sectionTitle}${sectionBatch.sectionSubtitle != null && sectionBatch.sectionSubtitle!.isNotEmpty ? ': ${sectionBatch.sectionSubtitle}' : ''}) (Batch $batchNumber of $totalBatches).

### TAXONOMY REFERENCE (You MUST use only these exact theme IDs):
$taxonomyBuffer

### GUIDELINES:
1. LLM SEMANTIC CHUNKING:
   - Group short consecutive items (e.g. short verse lines, prayers, introductory clauses) and split long paragraphs so that every output quote passage is between 1 and 5 sentences.
   - Every passage MUST express a complete, self-contained thought. NEVER output an isolated fragment or trailing clause ending in a colon (e.g. "5. Then as regards the broken bread:" MUST be grouped with the thanksgiving prayer that follows it).
   - Set `itemIndex` to the starting `itemIndex` where the quote begins in the reader.
   - Set `fullText` to the complete verbatim text of the chunked passage.
2. THEMATIC CATEGORIZATION:
   - Assign exactly one `primaryTheme` (the most dominant theme of the passage from the taxonomy reference).
   - Assign 0 to 2 `secondaryThemes` if the passage clearly speaks to additional themes.
   - For each of the Seven Sacraments, use the specific sacrament theme ID (e.g. `sacraments.baptism`, `sacraments.confirmation`, `sacraments.eucharist`, `sacraments.penance`, `sacraments.anointing_of_sick`, `sacraments.holy_orders`, `sacraments.matrimony`). Do NOT merge Confirmation into Baptism.
3. EXCERPT & SUMMARY:
   - Extract `keyExcerpt`: 1 to 5 powerful, memorable sentences from the passage that express a complete, self-contained thought or theme.
   - Provide `oneSentenceSummary`: A crisp 1-sentence doctrinal summary explaining what insight or doctrine this passage teaches.

### INPUT ITEMS:
```json
$itemsJson
```

### REQUIRED OUTPUT FORMAT:
Respond with ONLY valid JSON (a list of categorized passage objects) conforming to this schema:
```json
[
  {
    "bookId": "${sectionBatch.bookId}",
    "bookTitle": "${sectionBatch.bookTitle}",
    "author": "${sectionBatch.author}",
    "sectionId": "${sectionBatch.sectionId}",
    "sectionTitle": "${sectionBatch.sectionTitle}",
    "itemIndex": 0,
    "questionNumber": null,
    "primaryTheme": "theology.christ_incarnation",
    "secondaryThemes": ["sacraments.eucharist"],
    "keyExcerpt": "quoted key sentence",
    "oneSentenceSummary": "Summary explanation here.",
    "fullText": "exact full text of the chunked passage"
  }
]
```
''';
}

/// Invokes `agy` CLI to categorize a batch and saves the validated output.
Future<bool> runAgyOnBatch({
  required String prompt,
  required File outputFile,
  String? model,
  int retryCount = 2,
}) async {
  for (int attempt = 1; attempt <= retryCount; attempt++) {
    try {
      final args = ['-p', prompt];
      if (model != null && model.isNotEmpty) {
        args.addAll(['--model', model]);
      }

      final result = await Process.run('agy', args);
      if (result.exitCode != 0) {
        print(
          '    ⚠️ Attempt $attempt failed with code ${result.exitCode}: ${result.stderr}',
        );
        continue;
      }

      final rawOutput = result.stdout.toString();
      final jsonStr = extractJsonArray(rawOutput);
      final rawList = jsonDecode(jsonStr) as List<dynamic>;

      // Normalize & validate taxonomy
      int errors = 0;
      for (final item in rawList) {
        final m = item as Map<String, dynamic>;
        final rawPrimary = m['primaryTheme'] as String?;
        final normPrimary = ThematicTaxonomy.normalizeTheme(rawPrimary);
        if (normPrimary == null) {
          errors++;
        } else {
          m['primaryTheme'] = normPrimary;
        }

        final secondaries = (m['secondaryThemes'] as List<dynamic>?) ?? [];
        final normSecondaries = <String>[];
        for (final sec in secondaries) {
          final normSec = ThematicTaxonomy.normalizeTheme(sec.toString());
          if (normSec != null &&
              normSec != normPrimary &&
              !normSecondaries.contains(normSec)) {
            normSecondaries.add(normSec);
          }
        }
        m['secondaryThemes'] = normSecondaries;
      }

      if (errors > 0) {
        print(
          '    ⚠️ Attempt $attempt had $errors taxonomy errors. Retrying...',
        );
        continue;
      }

      outputFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(rawList),
      );
      return true;
    } catch (e) {
      print('    ⚠️ Attempt $attempt error: $e');
    }
  }
  return false;
}

void printHelp() {
  print('''
TwelveStars Thematic Categorization Tool 🌟

Usage:
  dart run bin/categorize_library.dart <command> [options]

Commands:
  --dispatch --book=<book_id>    End-to-end automated categorization using `agy` CLI agents!
                                 Extracts passages, executes `agy` subagents in parallel, validates,
                                 and automatically saves structured JSON files.
                                 Options: [--concurrency=3] [--batch-size=12] [--model=gemini-3.7-flash-medium]
                                          [--no-merge] [--force]
  --list-taxonomy                List all valid thematic categories and theme IDs.
  --prepare --book=<book_id>     Extract passage units and generate subagent prompt text files.
                                 Options: [--batch-size=12]
  --validate --input=<path>      Validate subagent JSON response file against taxonomy & schema.
  --merge                        Merge all validated batch files from assets/catechism/thematic_batches/
                                 into the unified index assets/catechism/thematic_index.json.
  --collate [--theme=<id>]       View collated passages grouped by theme or inspect a specific theme.
  --status                       Report overall categorization progress across all library books.
  --help                         Show this help message.

Examples:
  dart run bin/categorize_library.dart --dispatch --book=didache_lightfoot
  dart run bin/categorize_library.dart --dispatch --book=all --concurrency=4
  dart run bin/categorize_library.dart --collate --theme=sacraments.eucharist
''');
}

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    printHelp();
    return;
  }

  final booksDir = Directory('assets/catechism/json');
  final batchesDir = Directory('assets/catechism/thematic_batches');
  final unifiedIndexFile = File('assets/catechism/thematic_index.json');

  if (args.contains('--list-taxonomy')) {
    print('\n📜 TWELVESTARS THEMATIC TAXONOMY:');
    print('====================================');
    for (final group in ThematicTaxonomy.categories.entries) {
      print('\n[${group.key}]');
      for (final theme in group.value.entries) {
        print('  • ${theme.key.padRight(38)} -> ${theme.value}');
      }
    }
    print('\nTotal themes defined: ${ThematicTaxonomy.allThemes.length}');
    return;
  }

  if (args.contains('--dispatch') || args.contains('--auto-run')) {
    final bookArg = args.firstWhere(
      (a) => a.startsWith('--book='),
      orElse: () => '',
    );
    if (bookArg.isEmpty) {
      print('Error: Please specify --book=<book_id> or --book=all');
      return;
    }
    final targetBookId = bookArg.replaceFirst('--book=', '').trim();

    int batchSize = 12;
    final batchArg = args.firstWhere(
      (a) => a.startsWith('--batch-size='),
      orElse: () => '',
    );
    if (batchArg.isNotEmpty) {
      batchSize =
          int.tryParse(batchArg.replaceFirst('--batch-size=', '')) ?? 12;
    }

    int concurrency = 3;
    final concArg = args.firstWhere(
      (a) => a.startsWith('--concurrency='),
      orElse: () => '',
    );
    if (concArg.isNotEmpty) {
      concurrency =
          int.tryParse(concArg.replaceFirst('--concurrency=', '')) ?? 3;
    }

    final modelArg = args.firstWhere(
      (a) => a.startsWith('--model='),
      orElse: () => '',
    );
    final targetModel = modelArg.isNotEmpty
        ? modelArg.replaceFirst('--model=', '').trim()
        : null;
    final force = args.contains('--force');
    final autoMerge = !args.contains('--no-merge');

    if (!batchesDir.existsSync()) {
      batchesDir.createSync(recursive: true);
    }

    final bookFiles = targetBookId == 'all'
        ? booksDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList()
        : [File(p.join(booksDir.path, '$targetBookId.json'))];

    print(
      '🚀 Dispatching agy AI subagents to categorize ${bookFiles.length} book(s)...',
    );
    print('   • Concurrency limit : $concurrency');
    print('   • Batch size        : $batchSize passages/batch');
    if (targetModel != null) print('   • Model             : $targetModel');

    int totalCompletedBatches = 0;
    int totalFailedBatches = 0;

    for (final bFile in bookFiles) {
      if (!bFile.existsSync()) {
        print('Error: Book file not found: ${bFile.path}');
        continue;
      }

      final sectionBatches = extractSectionBatchesFromBook(
        bFile,
        maxItemsPerBatch: batchSize,
      );
      if (sectionBatches.isEmpty) continue;

      final totalBatches = sectionBatches.length;
      final bookId = p.basenameWithoutExtension(bFile.path);
      print(
        '\n📖 Processing "$bookId" across $totalBatches section batch(es):',
      );

      final queue = <int>[for (int i = 0; i < totalBatches; i++) i];
      final activeFutures = <Future<void>>[];

      Future<void> processBatch(int b) async {
        final batchNum = b + 1;
        final outFile = File(
          p.join(batchesDir.path, '${bookId}_batch_$batchNum.json'),
        );

        if (!force && outFile.existsSync()) {
          print(
            '   [Batch $batchNum/$totalBatches] ⏭️ Already categorized. Skipping.',
          );
          totalCompletedBatches++;
          return;
        }

        final batch = sectionBatches[b];

        final prompt = buildSubagentPrompt(
          sectionBatch: batch,
          batchNumber: batchNum,
          totalBatches: totalBatches,
        );

        print(
          '   [Batch $batchNum/$totalBatches] 🤖 Dispatching agy agent (${batch.items.length} items from ${batch.sectionTitle})...',
        );
        final stopwatch = Stopwatch()..start();
        final success = await runAgyOnBatch(
          prompt: prompt,
          outputFile: outFile,
          model: targetModel,
        );
        stopwatch.stop();

        if (success) {
          print(
            '   [Batch $batchNum/$totalBatches] ✅ Categorized & saved (${stopwatch.elapsed.inSeconds}s)',
          );
          totalCompletedBatches++;
        } else {
          print('   [Batch $batchNum/$totalBatches] ❌ Failed after retries.');
          totalFailedBatches++;
        }
      }

      // Run with concurrency worker pool
      while (queue.isNotEmpty || activeFutures.isNotEmpty) {
        while (queue.isNotEmpty && activeFutures.length < concurrency) {
          final nextB = queue.removeAt(0);
          final f = processBatch(nextB);
          activeFutures.add(f);
          f.whenComplete(() => activeFutures.remove(f));
        }
        if (activeFutures.isNotEmpty) {
          await Future.any(activeFutures);
        }
      }
    }

    print(
      '\n🏁 All dispatch runs completed! ($totalCompletedBatches successful, $totalFailedBatches failed)',
    );

    if (autoMerge && totalCompletedBatches > 0) {
      print('\n🔄 Auto-merging results into ${unifiedIndexFile.path}...');
      _mergeAllBatches(batchesDir, unifiedIndexFile);
    }
    return;
  }

  if (args.contains('--prepare')) {
    final bookArg = args.firstWhere(
      (a) => a.startsWith('--book='),
      orElse: () => '',
    );
    if (bookArg.isEmpty) {
      print('Error: Please specify --book=<book_id> or --book=all');
      return;
    }
    final targetBookId = bookArg.replaceFirst('--book=', '').trim();

    int batchSize = 12;
    final batchArg = args.firstWhere(
      (a) => a.startsWith('--batch-size='),
      orElse: () => '',
    );
    if (batchArg.isNotEmpty) {
      batchSize =
          int.tryParse(batchArg.replaceFirst('--batch-size=', '')) ?? 12;
    }

    if (!batchesDir.existsSync()) {
      batchesDir.createSync(recursive: true);
    }

    final bookFiles = targetBookId == 'all'
        ? booksDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList()
        : [File(p.join(booksDir.path, '$targetBookId.json'))];

    for (final bFile in bookFiles) {
      if (!bFile.existsSync()) {
        print('Error: Book file not found: ${bFile.path}');
        continue;
      }

      final sectionBatches = extractSectionBatchesFromBook(
        bFile,
        maxItemsPerBatch: batchSize,
      );
      if (sectionBatches.isEmpty) {
        print('Warning: No section batches found in ${bFile.path}');
        continue;
      }

      final totalBatches = sectionBatches.length;
      final bookId = p.basenameWithoutExtension(bFile.path);
      print('📖 Preparing "$bookId": $totalBatches section batch(es).');

      for (int b = 0; b < totalBatches; b++) {
        final batch = sectionBatches[b];

        final prompt = buildSubagentPrompt(
          sectionBatch: batch,
          batchNumber: b + 1,
          totalBatches: totalBatches,
        );

        final promptFile = File(
          p.join(batchesDir.path, '${bookId}_prompt_batch_${b + 1}.txt'),
        );
        promptFile.writeAsStringSync(prompt);

        final payloadFile = File(
          p.join(batchesDir.path, '${bookId}_units_batch_${b + 1}.json'),
        );
        payloadFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(batch.toJson()),
        );
      }
      print('   ✓ Saved prompts and unit payloads in ${batchesDir.path}');
    }
    return;
  }

  if (args.contains('--validate')) {
    final inputArg = args.firstWhere(
      (a) => a.startsWith('--input='),
      orElse: () => '',
    );
    if (inputArg.isEmpty) {
      print('Error: Please specify --input=<file_path>');
      return;
    }
    final targetPath = inputArg.replaceFirst('--input=', '').trim();
    final file = File(targetPath);
    if (!file.existsSync()) {
      print('Error: File not found: $targetPath');
      return;
    }

    try {
      final raw = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      int errors = 0;
      for (int i = 0; i < raw.length; i++) {
        final item = raw[i] as Map<String, dynamic>;
        final primary = item['primaryTheme'] as String?;
        if (primary == null || !ThematicTaxonomy.isValidTheme(primary)) {
          print('❌ Error at index $i: Invalid primaryTheme "$primary"');
          errors++;
        }
        final secondaries = (item['secondaryThemes'] as List<dynamic>?) ?? [];
        for (final sec in secondaries) {
          if (!ThematicTaxonomy.isValidTheme(sec.toString())) {
            print('❌ Error at index $i: Invalid secondaryTheme "$sec"');
            errors++;
          }
        }
      }
      if (errors == 0) {
        print(
          '✅ Validation SUCCESSFUL: ${raw.length} passages strictly match schema and taxonomy in $targetPath',
        );
      } else {
        print('❌ Validation FAILED with $errors taxonomy error(s).');
      }
    } catch (e) {
      print('❌ Validation Error: Invalid JSON structure: $e');
    }
    return;
  }

  if (args.contains('--merge')) {
    _mergeAllBatches(batchesDir, unifiedIndexFile);
    return;
  }

  if (args.contains('--collate')) {
    if (!unifiedIndexFile.existsSync()) {
      print(
        'Error: Unified index file ${unifiedIndexFile.path} does not exist. Run --merge or --dispatch first.',
      );
      return;
    }

    final themeArg = args.firstWhere(
      (a) => a.startsWith('--theme='),
      orElse: () => '',
    );
    final targetTheme = themeArg.isNotEmpty
        ? themeArg.replaceFirst('--theme=', '').trim()
        : null;

    final data =
        jsonDecode(unifiedIndexFile.readAsStringSync()) as Map<String, dynamic>;
    final passagesRaw = data['passages'] as List<dynamic>? ?? [];
    final passages = passagesRaw
        .map((p) => CategorizedPassage.fromJson(p as Map<String, dynamic>))
        .toList();

    final Map<String, List<CategorizedPassage>> grouped = {};
    for (final p in passages) {
      grouped.putIfAbsent(p.primaryTheme, () => []).add(p);
      for (final sec in p.secondaryThemes) {
        grouped.putIfAbsent(sec, () => []).add(p);
      }
    }

    if (targetTheme != null) {
      final list = grouped[targetTheme] ?? [];
      final desc = ThematicTaxonomy.allThemes[targetTheme] ?? targetTheme;
      print('\n📖 THEME: $targetTheme ($desc)');
      print('Total passages: ${list.length}\n${'=' * 60}');
      for (final item in list) {
        print(
          '• [${item.bookTitle}] ${item.sectionTitle} (Item ${item.itemIndex})',
        );
        print('  Author: ${item.author}');
        print('  Summary: ${item.oneSentenceSummary}');
        print('  Excerpt: "${item.keyExcerpt}"\n');
      }
    } else {
      print('\n📊 COLLATED PASSAGE COUNTS BY THEME:');
      print('====================================');
      for (final group in ThematicTaxonomy.categories.entries) {
        print('\n[${group.key}]');
        for (final theme in group.value.entries) {
          final count = grouped[theme.key]?.length ?? 0;
          print('  • ${theme.key.padRight(36)} : $count passage(s)');
        }
      }
    }
    return;
  }

  if (args.contains('--status')) {
    final bookFiles = booksDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    print(
      '\n📚 LIBRARY THEMATIC STATUS (${bookFiles.length} books in catalog):',
    );
    print('===============================================================');

    int totalBatches = 0;
    for (final bFile in bookFiles) {
      final batches = extractSectionBatchesFromBook(bFile);
      totalBatches += batches.length;
      final bookId = p.basenameWithoutExtension(bFile.path);
      print(
        '  • ${bookId.padRight(36)}: ${batches.length.toString().padLeft(4)} section batch(es)',
      );
    }
    print('---------------------------------------------------------------');
    print('Total Section Batches across Library: $totalBatches');
    return;
  }

  printHelp();
}

void _mergeAllBatches(Directory batchesDir, File unifiedIndexFile) {
  if (!batchesDir.existsSync()) {
    print('Error: Batches directory ${batchesDir.path} does not exist.');
    return;
  }

  final resultFiles = batchesDir
      .listSync()
      .whereType<File>()
      .where(
        (f) => f.path.endsWith('.json') && !f.path.contains('_units_batch_'),
      )
      .toList();

  if (resultFiles.isEmpty) {
    print('No completed categorization JSON files found in ${batchesDir.path}');
    return;
  }

  final allPassages = <CategorizedPassage>[];
  for (final rFile in resultFiles) {
    try {
      final list = jsonDecode(rFile.readAsStringSync()) as List<dynamic>;
      for (final item in list) {
        allPassages.add(
          CategorizedPassage.fromJson(item as Map<String, dynamic>),
        );
      }
    } catch (e) {
      print('Warning: Failed to parse ${rFile.path}: $e');
    }
  }

  // Sort by bookId, sectionId, itemIndex
  allPassages.sort((a, b) {
    final c1 = a.bookId.compareTo(b.bookId);
    if (c1 != 0) return c1;
    final c2 = a.sectionId.compareTo(b.sectionId);
    if (c2 != 0) return c2;
    return a.itemIndex.compareTo(b.itemIndex);
  });

  final outputData = {
    'generatedAt': DateTime.now().toIso8601String(),
    'totalPassages': allPassages.length,
    'passages': allPassages.map((p) => p.toJson()).toList(),
  };

  unifiedIndexFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(outputData),
  );
  print(
    '🎉 Successfully merged ${allPassages.length} passages into ${unifiedIndexFile.path}',
  );
}
