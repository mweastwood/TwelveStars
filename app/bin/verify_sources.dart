// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:twelve_stars/logic/prayers.dart';

// List of domains that have Cloudflare/bot protection and should be fetched from the Wayback Machine directly.
const Set<String> waybackOnlyDomains = {'usccb.org', 'www.usccb.org'};

// Map of known typographical errors on external source pages to their correct spellings, categorized by language.
const Map<PrayerLanguage, Map<String, String>> sourceTypoFixes = {
  PrayerLanguage.latin: {
    'víirgine': 'virgine',
    'viirgine': 'virgine',
    '&uacutes': 'us',
    '&iacute': 'i',
    '&oacute': 'o',
    '&aelig': 'ae',
  },
  PrayerLanguage.spanish: {
    // In 2010, the Real Academia Española (RAE) updated the spelling rules and officially
    // eliminated the accent mark on "sólo" (meaning "only" or "just"). Today, the correct spelling is
    // simply "solo" without an accent. Our database uses the modern spelling "solo", but older web sources
    // still use "sólo". We normalize "sólo" to "solo" to prevent accent mismatch failures.
    'sólo': 'solo',
  },
  PrayerLanguage.vietnamese: {
    // VEYM website has a typo "Đức Chúa Chúa Thánh Thần" in the Apostles' Creed.
    'chúa chúa': 'chúa',
    // VEYM website has a typo "lương thực hàng ngày" instead of "hằng ngày" in the Our Father.
    'hàng ngày': 'hằng ngày',
    // VEYM website has a typo "khi nay" instead of "khi này" in the Hail Mary.
    'khi nay': 'khi này',
    // VEYM website has a typo "nhầt" instead of "nhất" in the Fatima Prayer.
    'nhầt': 'nhất',
    // VietCatholic uses the spelling "quỉ", while we use "quỷ". We normalize to "quỷ" to prevent mismatch.
    'quỉ': 'quỷ',
    // VietCatholic has a typo "cơ bình" instead of "cơ binh" in the St. Michael prayer.
    'cơ bình': 'cơ binh',
  },
  PrayerLanguage.traditionalChinese: {
    // Diocesan Family Commission has a typo "遣責" instead of "譴責".
    '遣責': '譴責',
  },
};

/// Decodes HTTP response bytes handling special legacy encodings (like Latin-1 for maranatha.it).
String decodeHtmlBytes(List<int> bodyBytes, String url) {
  final cleanUrl = url.split('#').first;
  if (cleanUrl.contains('maranatha.it')) {
    return latin1.decode(bodyBytes);
  }
  try {
    return utf8.decode(bodyBytes);
  } catch (_) {
    try {
      return utf8.decode(bodyBytes, allowMalformed: true);
    } catch (_) {
      return latin1.decode(bodyBytes);
    }
  }
}

/// Slices lines based on 1-indexed [startLine] and [endLine] bounds.
List<String> slicePrayerLines(
  List<String> lines, {
  int? startLine,
  int? endLine,
}) {
  final start = (startLine ?? 1) - 1;
  final end = endLine ?? lines.length;
  final int startIdx = start.clamp(0, lines.length);
  final int endIdx = end.clamp(startIdx, lines.length);
  return lines.sublist(startIdx, endIdx);
}

/// A robust soft normalization to handle HTML tag spacing, punctuation, accents, and casing.
String softNormalize(String text, {required PrayerLanguage language}) {
  // Strip Wikipedia footnote reference tags like [a] or [1] or [12]
  String res = text
      .replaceAll(RegExp(r'\[\w\]'), '')
      .replaceAll(RegExp(r'\[\d+\]'), '');
  // Strip bracket symbols themselves but preserve their inner content (e.g. for [Như đã có...])
  res = res.replaceAll('[', '').replaceAll(']', '');

  res = res.toLowerCase();

  // Strip call/response symbols, role labels, and prompt headers that are
  // present in web sources but omitted in the application's local text database.
  // This is done before stripping whitespace and punctuation so that multi-word
  // labels (like "người xướng" and "đọc chung") can be matched accurately.
  res = res
      .replaceAll(RegExp(r'(^|\s)[℣℟vVrR]\.?(\s|$)'), ' ')
      .replaceAll(RegExp(r'(^|\s)[vVrR]/(\s|$)'), ' ')
      .replaceAll('namumuno', '')
      .replaceAll('bayan', '')
      .replaceAll('người đọc', '')
      .replaceAll('người xướng', '')
      .replaceAll('người đáp', '')
      .replaceAll('đọc chung', '')
      .replaceAll('xướng', '')
      .replaceAll('đáp', '')
      .replaceAll('linh mục', '')
      .replaceAll('chủ tế', '')
      .replaceAll('cộng đoàn', '')
      .replaceAll('giáo dân', '')
      .replaceAll('phó tế', '')
      .replaceAll('領經者', '')
      .replaceAll('主祭', '')
      .replaceAll('全體', '')
      .replaceAll('啟：', '')
      .replaceAll('應：', '')
      .replaceAll('啟', '')
      .replaceAll('應', '');

  // Apply language-specific external source typo fixes
  final fixesForLanguage = sourceTypoFixes[language];
  if (fixesForLanguage != null) {
    for (final entry in fixesForLanguage.entries) {
      res = res.replaceAll(entry.key, entry.value);
    }
  }

  if (language == PrayerLanguage.latin) {
    res = res
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('æ', 'ae')
        .replaceAll('œ', 'oe')
        .replaceAll('ǽ', 'ae');
  }

  if (language == PrayerLanguage.vietnamese) {
    // Normalize Icelandic Eth (used on older sites like conggiao.org) to Vietnamese D-with-stroke
    res = res.replaceAll('ð', 'đ');

    // Compose decomposed Unicode combining diacritics into precomposed NFC characters
    const baseMap = {
      'a\u0306': 'ă',
      'a\u0302': 'â',
      'e\u0302': 'ê',
      'o\u0302': 'ô',
      'o\u031b': 'ơ',
      'u\u031b': 'ư',
      'd\u0335': 'đ',
    };
    for (final entry in baseMap.entries) {
      res = res.replaceAll(entry.key, entry.value);
    }

    const toneMap = {
      'a\u0300': 'à',
      'a\u0301': 'á',
      'a\u0309': 'ả',
      'a\u0303': 'ã',
      'a\u0323': 'ạ',
      'ă\u0300': 'ằ',
      'ă\u0301': 'ắ',
      'ă\u0309': 'ẳ',
      'ă\u0303': 'ẵ',
      'ă\u0323': 'ặ',
      'â\u0300': 'ầ',
      'â\u0301': 'ấ',
      'â\u0309': 'ẩ',
      'â\u0303': 'ẫ',
      'â\u0323': 'ậ',
      'e\u0300': 'è',
      'e\u0301': 'é',
      'e\u0309': 'ẻ',
      'e\u0303': 'ẽ',
      'e\u0323': 'ẹ',
      'ê\u0300': 'ề',
      'ê\u0301': 'ế',
      'ê\u0309': 'ể',
      'ê\u0303': 'ễ',
      'ê\u0323': 'ệ',
      'i\u0300': 'ì',
      'i\u0301': 'í',
      'i\u0309': 'ỉ',
      'i\u0303': 'ĩ',
      'i\u0323': 'ị',
      'o\u0300': 'ò',
      'o\u0301': 'ó',
      'o\u0309': 'ỏ',
      'o\u0303': 'õ',
      'o\u0323': 'ọ',
      'ô\u0300': 'ồ',
      'ô\u0301': 'ố',
      'ô\u0309': 'ổ',
      'ô\u0303': 'ỗ',
      'ô\u0323': 'ộ',
      'ơ\u0300': 'ờ',
      'ơ\u0301': 'ớ',
      'ơ\u0309': 'ở',
      'ơ\u0303': 'ỡ',
      'ơ\u0323': 'ợ',
      'u\u0300': 'ù',
      'u\u0301': 'ú',
      'u\u0309': 'ủ',
      'u\u0303': 'ũ',
      'u\u0323': 'ụ',
      'ư\u0300': 'ừ',
      'ư\u0301': 'ứ',
      'ư\u0309': 'ử',
      'ư\u0303': 'ữ',
      'ư\u0323': 'ự',
      'y\u0300': 'ỳ',
      'y\u0301': 'ý',
      'y\u0309': 'ỷ',
      'y\u0303': 'ỹ',
      'y\u0323': 'ỵ',
    };
    for (final entry in toneMap.entries) {
      res = res.replaceAll(entry.key, entry.value);
    }

    // Normalize old-style diphthong accent placement to modern-style
    const diphthongMap = {
      'oá': 'óa',
      'oà': 'òa',
      'oả': 'ỏa',
      'oã': 'õa',
      'oạ': 'ọa',
      'uý': 'úy',
      'uỳ': 'ùy',
      'uỷ': 'ủy',
      'uỹ': 'ũy',
      'uỵ': 'ụy',
      'oé': 'óe',
      'oè': 'òe',
      'oẻ': 'ỏe',
      'oẽ': 'õe',
      'oẹ': 'ọe',
    };
    for (final entry in diphthongMap.entries) {
      res = res.replaceAll(entry.key, entry.value);
    }
  }

  final isLatin = language == PrayerLanguage.latin;
  if (isLatin) {
    res = res
        .replaceAll('j', 'i')
        .replaceAll('æ', 'ae')
        .replaceAll('ǽ', 'ae')
        .replaceAll('œ', 'oe')
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('å', 'a')
        .replaceAll('ā', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ą', 'a')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ē', 'e')
        .replaceAll('ĕ', 'e')
        .replaceAll('ė', 'e')
        .replaceAll('ę', 'e')
        .replaceAll('ě', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ī', 'i')
        .replaceAll('ĭ', 'i')
        .replaceAll('į', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ø', 'o')
        .replaceAll('ō', 'o')
        .replaceAll('ŏ', 'o')
        .replaceAll('ő', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ū', 'u')
        .replaceAll('ŭ', 'u')
        .replaceAll('ů', 'u')
        .replaceAll('ű', 'u')
        .replaceAll('ų', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ć', 'c')
        .replaceAll('ĉ', 'c')
        .replaceAll('ċ', 'c')
        .replaceAll('č', 'c')
        .replaceAll('ď', 'd')
        .replaceAll('đ', 'd')
        .replaceAll('ĝ', 'g')
        .replaceAll('ğ', 'g')
        .replaceAll('ġ', 'g')
        .replaceAll('ģ', 'g')
        .replaceAll('ĥ', 'h')
        .replaceAll('ħ', 'h')
        .replaceAll('ĵ', 'j')
        .replaceAll('ķ', 'k')
        .replaceAll('ĺ', 'l')
        .replaceAll('ļ', 'l')
        .replaceAll('ľ', 'l')
        .replaceAll('ł', 'l')
        .replaceAll('ń', 'n')
        .replaceAll('ņ', 'n')
        .replaceAll('ň', 'n')
        .replaceAll('ŉ', 'n')
        .replaceAll('ŕ', 'r')
        .replaceAll('ŗ', 'r')
        .replaceAll('ř', 'r')
        .replaceAll('ś', 's')
        .replaceAll('ŝ', 's')
        .replaceAll('ş', 's')
        .replaceAll('š', 's')
        .replaceAll('ţ', 't')
        .replaceAll('ť', 't')
        .replaceAll('ŧ', 't')
        .replaceAll('ŵ', 'w')
        .replaceAll('ŷ', 'y')
        .replaceAll('ÿ', 'y')
        .replaceAll('ź', 'z')
        .replaceAll('ż', 'z')
        .replaceAll('ž', 'z');
  }

  res = res
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"');

  // Strip all straight quotes first
  res = res.replaceAll('"', '').replaceAll("'", '');

  // Strip all punctuation, markdown italics asterisks, and whitespace to do a character-sequence only match.
  // This includes Western and Chinese full-width punctuation.
  res = res.replaceAll(
    RegExp(r"[*.,;:!?\-\(\)«»‘’“”\s\u00A0\u200b，。、；：！？「」『』/]+"),
    '',
  );

  res = res
      .replaceAll('amen', '')
      .replaceAll('amén', '')
      .replaceAll('amên', '')
      .replaceAll('亞孟', '')
      .replaceAll('阿們', '')
      .replaceAll('阿門', '')
      .replaceAll('priest', '')
      .replaceAll('people', '')
      .replaceAll('deacon', '')
      .replaceAll('reader', '')
      .replaceAll('sacerdos', '')
      .replaceAll('populus', '')
      .replaceAll('diaconus', '')
      .replaceAll('lector', '')
      .replaceAll('sacerdote', '')
      .replaceAll('asamblea', '')
      .replaceAll('pueblo', '')
      .replaceAll('diácono', '')
      .replaceAll('linhmục', '')
      .replaceAll('chủtế', '')
      .replaceAll('cộngđoàn', '')
      .replaceAll('giáodân', '')
      .replaceAll('phótế', '')
      .replaceAll('ngườiđọc', '')
      .replaceAll('prêtre', '')
      .replaceAll('lecteur', '')
      .replaceAll('popolo', '')
      .replaceAll('lettore', '')
      .replaceAll('pari', '')
      .replaceAll('namumuno', '')
      .replaceAll('bayan', '')
      .replaceAll('領經者', '')
      .replaceAll('主祭', '')
      .replaceAll('全體', '')
      .replaceAll('✠', '')
      .replaceAll('†', '')
      .replaceAll('&#10016;', '')
      .replaceAll('&#8224;', '');

  return res;
}

/// Fetches HTML from [url], using Wayback Machine fallback on blocking / failure.
Future<String> fetchHtml(
  String url, {
  http.Client? client,
  Map<String, String>? cache,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final activeClient = client ?? http.Client();
  final cleanUrl = url.split('#').first;
  if (cache != null && cache.containsKey(cleanUrl)) {
    return cache[cleanUrl]!;
  }

  final uri = Uri.parse(cleanUrl);
  final isWaybackOnly = waybackOnlyDomains.contains(uri.host);

  http.Response response;
  if (isWaybackOnly) {
    final waybackUrl = 'https://web.archive.org/web/20260101/$cleanUrl';
    try {
      response = await activeClient
          .get(Uri.parse(waybackUrl), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(timeout);
    } catch (e) {
      throw HttpException(
        'Failed to fetch from Wayback Machine ($waybackUrl): $e',
      );
    }
  } else {
    try {
      response = await activeClient
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          )
          .timeout(timeout);

      final pageText = response.body.toLowerCase();
      final isBlocked =
          response.statusCode == 403 ||
          response.statusCode == 503 ||
          pageText.contains('cloudflare') ||
          pageText.contains('security check') ||
          (pageText.contains('captcha') &&
              !pageText.contains('wgconfirmedit')) ||
          pageText.contains('sucuri') ||
          pageText.contains('access denied') ||
          pageText.contains('challenge-platform') ||
          pageText.contains('ray id') ||
          pageText.contains('please enable cookies');

      if (isBlocked) {
        final waybackUrl = 'https://web.archive.org/web/20260101/$cleanUrl';
        try {
          final waybackResponse = await activeClient
              .get(
                Uri.parse(waybackUrl),
                headers: {'User-Agent': 'Mozilla/5.0'},
              )
              .timeout(timeout);
          if (waybackResponse.statusCode == 200) {
            response = waybackResponse;
          } else {
            throw HttpException(
              'Blocked on live site and Wayback Machine returned HTTP ${waybackResponse.statusCode}',
            );
          }
        } catch (e) {
          throw HttpException(
            'Blocked on live site and Wayback Machine fetch failed: $e',
          );
        }
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      final waybackUrl = 'https://web.archive.org/web/20260101/$cleanUrl';
      try {
        response = await activeClient
            .get(Uri.parse(waybackUrl), headers: {'User-Agent': 'Mozilla/5.0'})
            .timeout(timeout);
      } catch (we) {
        throw HttpException(
          'Live fetch failed ($e) and Wayback Machine fetch failed ($we)',
        );
      }
    }
  }

  if (response.statusCode != 200) {
    throw HttpException(
      'Failed to fetch $cleanUrl: HTTP ${response.statusCode}',
    );
  }

  final html = decodeHtmlBytes(response.bodyBytes, cleanUrl);
  if (cache != null) {
    cache[cleanUrl] = html;
  }
  return html;
}

void printUsage() {
  print('''
Usage: dart bin/verify_sources.dart [options]

Options:
  --language=<lang>    Filter verification by language (e.g., english, latin, spanish, etc.)
  --prayer=<id>        Filter verification by prayer ID (e.g., our_father, hail_mary)
  -h, --help           Show this help message
''');
}

Future<void> main(List<String> args) async {
  String? filterLanguage;
  String? filterPrayer;

  for (final arg in args) {
    if (arg == '-h' || arg == '--help') {
      printUsage();
      return;
    } else if (arg.startsWith('--language=')) {
      filterLanguage = arg.substring('--language='.length).trim();
    } else if (arg.startsWith('--prayer=')) {
      filterPrayer = arg.substring('--prayer='.length).trim();
    } else {
      print('Unknown option: $arg');
      printUsage();
      exit(1);
    }
  }

  final jsonFile = File('assets/prayers.json');
  if (!jsonFile.existsSync()) {
    print(
      'Error: assets/prayers.json does not exist. Run bin/assemble_db.dart first.',
    );
    exit(1);
  }

  final List<dynamic> prayersList =
      jsonDecode(jsonFile.readAsStringSync()) as List<dynamic>;

  final Map<String, String> htmlCache = {};
  final httpClient = http.Client();

  int totalChecks = 0;
  int passedChecks = 0;
  int failedChecks = 0;
  final Map<String, List<String>> failedDetailsByLang = {};

  print('Starting live prayer source verification...');
  if (filterLanguage != null) print('Filtering by language: $filterLanguage');
  if (filterPrayer != null) print('Filtering by prayer ID: $filterPrayer');
  print('--------------------------------------------------');

  try {
    for (final pMap in prayersList) {
      if (pMap is! Map<String, dynamic>) continue;
      final prayerId = pMap['id'] as String;
      if (filterPrayer != null && prayerId != filterPrayer) continue;

      final transMap = pMap['translations'] as Map<String, dynamic>? ?? {};

      for (final entry in transMap.entries) {
        final languageStr = entry.key;
        if (filterLanguage != null &&
            languageStr.toLowerCase() != filterLanguage.toLowerCase()) {
          continue;
        }

        final language = PrayerLanguage.values.firstWhere(
          (e) => e.code == languageStr,
          orElse: () => PrayerLanguage.english,
        );

        final transList = entry.value as List<dynamic>? ?? [];
        final versionCount = transList.length;

        for (
          int versionIndex = 0;
          versionIndex < versionCount;
          versionIndex++
        ) {
          totalChecks++;
          final tMap = transList[versionIndex] as Map<String, dynamic>;
          final text = (tMap['text'] as String?) ?? '';
          final sourceUrl = tMap['source_url'] as String?;
          final sourcesList = tMap['sources'] as List<dynamic>?;
          final suffix = versionCount > 1 ? ' (v${versionIndex + 1})' : '';
          final itemLabel = '$prayerId [$languageStr$suffix]';

          final lines = text
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) => softNormalize(line, language: language))
              .toList();

          bool checkPassed = true;
          final missingDetails = <String>[];

          try {
            if (sourcesList != null && sourcesList.isNotEmpty) {
              for (final src in sourcesList) {
                if (src is! Map<String, dynamic>) continue;
                final srcName = (src['name'] as String?) ?? 'Source';
                final rawSrcUrl = src['url'] as String?;
                if (rawSrcUrl == null || rawSrcUrl.isEmpty) continue;
                final startLine = src['start_line'] as int?;
                final endLine = src['end_line'] as int?;

                final html = await fetchHtml(
                  rawSrcUrl,
                  client: httpClient,
                  cache: htmlCache,
                );
                final document = html_parser.parse(html);
                final pageText = document.body?.text ?? '';
                final softPage = softNormalize(pageText, language: language);

                final srcLines = slicePrayerLines(
                  lines,
                  startLine: startLine,
                  endLine: endLine,
                );

                for (final line in srcLines) {
                  if (!softPage.contains(line)) {
                    checkPassed = false;
                    missingDetails.add('"$line" (from $srcName: $rawSrcUrl)');
                  }
                }
              }
            } else if (sourceUrl != null && sourceUrl.isNotEmpty) {
              final html = await fetchHtml(
                sourceUrl,
                client: httpClient,
                cache: htmlCache,
              );
              final document = html_parser.parse(html);
              final pageText = document.body?.text ?? '';
              final softPage = softNormalize(pageText, language: language);

              for (final line in lines) {
                if (!softPage.contains(line)) {
                  checkPassed = false;
                  missingDetails.add('"$line" (from $sourceUrl)');
                }
              }
            } else {
              checkPassed = false;
              missingDetails.add('No source URL configured.');
            }
          } catch (e) {
            checkPassed = false;
            missingDetails.add('Network or parsing error: $e');
          }

          if (checkPassed) {
            passedChecks++;
            print('  [PASS] $itemLabel');
          } else {
            failedChecks++;
            print('  [FAIL] $itemLabel');
            for (final detail in missingDetails) {
              print('         - $detail');
            }
            failedDetailsByLang
                .putIfAbsent(languageStr, () => [])
                .add('$itemLabel: ${missingDetails.join('; ')}');
          }
        }
      }
    }
  } finally {
    httpClient.close();
  }

  print('==================================================');
  print('Source Verification Summary:');
  print('==================================================');
  print('Total Checks: $totalChecks');
  print('Passed:       $passedChecks');
  print('Failed:       $failedChecks');
  print('==================================================');

  if (failedChecks > 0) {
    print('Failures by language:');
    for (final entry in failedDetailsByLang.entries) {
      print('  ${entry.key}:');
      for (final item in entry.value) {
        print('    • $item');
      }
    }
    exit(1);
  } else {
    print('All prayer sources verified successfully!');
    exit(0);
  }
}
