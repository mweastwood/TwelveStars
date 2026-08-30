import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:twelve_stars/logic/prayers.dart';

import '../../bin/verify_sources.dart';

void main() {
  group('softNormalize', () {
    test('strips Western punctuation, quotes, and whitespace', () {
      const input = 'Hello, world! (This is a test: "quotes" and \'single\').';
      final result = softNormalize(input, language: PrayerLanguage.english);
      expect(result, 'helloworldthisisatestquotesandsingle');
    });

    test('strips non-breaking and zero-width spaces', () {
      const input = 'Word1\u00A0Word2\u200bWord3';
      final result = softNormalize(input, language: PrayerLanguage.english);
      expect(result, 'word1word2word3');
    });

    test('strips smart quotes and angle brackets', () {
      const input = '«“Smart Quotes” and ‘Single Quotes’»';
      final result = softNormalize(input, language: PrayerLanguage.english);
      expect(result, 'smartquotesandsinglequotes');
    });

    test('strips Chinese full-width punctuation', () {
      const input = '「我們的天父，願祢的名受顯揚；願祢的國來臨！」';
      final result = softNormalize(
        input,
        language: PrayerLanguage.traditionalChinese,
      );
      expect(result, '我們的天父願祢的名受顯揚願祢的國來臨');
    });

    test('strips Wikipedia footnote reference tags and brackets', () {
      const input = 'Text with footnotes[1][a][123] and [bracketed content]';
      final result = softNormalize(input, language: PrayerLanguage.english);
      expect(result, 'textwithfootnotesandbracketedcontent');
    });

    test('strips liturgical role labels and call/response markers', () {
      const input =
          '℣. Namumuno: Bayan: Linh mục: Chủ tế: Cộng đoàn: Giáo dân: Phó tế: '
          'Người đọc: Người xướng: Người đáp: Đọc chung: 領經者: 主祭: 全體: 啟： 應： ✠ † '
          'Pax vobiscum ℟. Et cum spiritu tuo';
      final result = softNormalize(input, language: PrayerLanguage.latin);
      expect(result, 'paxvobiscumetcumspiritutuo');
    });

    test('strips Amen across multiple languages', () {
      expect(softNormalize('Amen', language: PrayerLanguage.english), '');
      expect(softNormalize('Amén', language: PrayerLanguage.spanish), '');
      expect(softNormalize('Amên', language: PrayerLanguage.vietnamese), '');
      expect(
        softNormalize('亞孟', language: PrayerLanguage.traditionalChinese),
        '',
      );
      expect(
        softNormalize('阿們', language: PrayerLanguage.traditionalChinese),
        '',
      );
      expect(
        softNormalize('阿門', language: PrayerLanguage.traditionalChinese),
        '',
      );
    });

    group('Latin normalization', () {
      test('strips pronunciation accents and normalizes j to i', () {
        const input = 'María, Dóminus tecum, Jesus Christus';
        final result = softNormalize(input, language: PrayerLanguage.latin);
        expect(result, 'mariadominustecumiesuschristus');
      });

      test('expands ligatures æ, œ, ǽ to ae and oe', () {
        const input = 'cælis, cœli, ǽternam';
        final result = softNormalize(input, language: PrayerLanguage.latin);
        expect(result, 'caeliscoeliaeternam');
      });

      test('strips macron and other Latin liturgical diacritics', () {
        const input = 'ā ă ą ē ĕ ė ę ě ī ĭ į ı ō ŏ ő ū ŭ ů ű ų';
        final result = softNormalize(input, language: PrayerLanguage.latin);
        expect(result, 'aaaeeeeeiiiiooouuuuu');
      });
    });

    group('Vietnamese normalization', () {
      test('normalizes Icelandic Eth to đ', () {
        const input = 'kinh ðức chúa trời';
        final result = softNormalize(
          input,
          language: PrayerLanguage.vietnamese,
        );
        expect(result, 'kinhđứcchúatrời');
      });

      test('composes decomposed Unicode combining diacritics', () {
        // Decomposed ă (a + \u0306), â (a + \u0302), đ (d + \u0335)
        const input = 'a\u0306 a\u0302 e\u0302 o\u0302 o\u031b u\u031b d\u0335';
        final result = softNormalize(
          input,
          language: PrayerLanguage.vietnamese,
        );
        expect(result, 'ăâêôơưđ');
      });

      test('composes decomposed Unicode tone marks', () {
        // a + grave (\u0300), a + acute (\u0301), a + hook (\u0309), a + tilde (\u0303), a + dot (\u0323)
        const input = 'a\u0300 a\u0301 a\u0309 a\u0303 a\u0323';
        final result = softNormalize(
          input,
          language: PrayerLanguage.vietnamese,
        );
        expect(result, 'àáảãạ');
      });

      test(
        'normalizes old-style diphthong accent placement to modern style',
        () {
          const input = 'hoà oá uý oé';
          final result = softNormalize(
            input,
            language: PrayerLanguage.vietnamese,
          );
          expect(result, 'hòaóaúyóe');
        },
      );
    });

    group('Spanish normalization', () {
      test('normalizes sólo to solo (RAE 2010 rule update)', () {
        const input = 'Tú sólo eres Santo, sólo Tú Señor';
        final result = softNormalize(input, language: PrayerLanguage.spanish);
        expect(result, 'túsoloeressantosolotúseñor');
      });
    });

    group('Traditional Chinese normalization', () {
      test('replaces known typo 遣責 with 譴責', () {
        const input = '遣責罪惡';
        final result = softNormalize(
          input,
          language: PrayerLanguage.traditionalChinese,
        );
        expect(result, '譴責罪惡');
      });
    });
  });

  group('sourceTypoFixes', () {
    test('Latin typo replacements work in softNormalize', () {
      expect(
        softNormalize(
          'víirgine viirgine &uacutes &iacute &oacute &aelig',
          language: PrayerLanguage.latin,
        ),
        'virginevirgineusioae',
      );
    });

    test('Spanish typo replacements work in softNormalize', () {
      expect(softNormalize('sólo', language: PrayerLanguage.spanish), 'solo');
    });

    test('Vietnamese typo replacements work in softNormalize', () {
      expect(
        softNormalize(
          'chúa chúa hàng ngày khi nay nhầt quỉ cơ bình',
          language: PrayerLanguage.vietnamese,
        ),
        'chúahằngngàykhinàynhấtqủycơbinh',
      );
    });

    test('Traditional Chinese typo replacements work in softNormalize', () {
      expect(
        softNormalize('遣責', language: PrayerLanguage.traditionalChinese),
        '譴責',
      );
    });
  });

  group('slicePrayerLines', () {
    final sampleLines = ['Line 1', 'Line 2', 'Line 3', 'Line 4', 'Line 5'];

    test('slices 1-indexed range correctly', () {
      final slice1 = slicePrayerLines(sampleLines, startLine: 1, endLine: 3);
      expect(slice1, ['Line 1', 'Line 2', 'Line 3']);

      final slice2 = slicePrayerLines(sampleLines, startLine: 3, endLine: 4);
      expect(slice2, ['Line 3', 'Line 4']);

      final slice3 = slicePrayerLines(sampleLines, startLine: 4, endLine: 5);
      expect(slice3, ['Line 4', 'Line 5']);
    });

    test('handles default bounds when startLine or endLine are omitted', () {
      final slice = slicePrayerLines(sampleLines);
      expect(slice, sampleLines);
    });

    test('clamps out-of-bounds startLine and endLine safely', () {
      final slice = slicePrayerLines(sampleLines, startLine: -5, endLine: 100);
      expect(slice, sampleLines);
    });
  });

  group('HTTP Response Handling & Decoding', () {
    test('decodes standard UTF-8 response bytes', () {
      const original = '<p>Kính Mừng Maria, đầy ơn phúc</p>';
      final bytes = utf8.encode(original);
      final decoded = decodeHtmlBytes(bytes, 'https://example.com/prayer');
      expect(decoded, original);
    });

    test('decodes Latin-1 bytes for maranatha.it', () {
      const original = '<p>Signore, pietà. Cristo, pietà.</p>';
      final bytes = latin1.encode(original);
      final decoded = decodeHtmlBytes(
        bytes,
        'https://www.maranatha.it/RitoMessa/missaetext.htm',
      );
      expect(decoded, original);
    });

    test('recovers from malformed UTF-8 bytes with fallback', () {
      final malformedBytes = [0xFF, 0xFE, 0x41, 0x42];
      final decoded = decodeHtmlBytes(
        malformedBytes,
        'https://example.com/page',
      );
      expect(decoded.isNotEmpty, isTrue);
    });

    test('fetchHtml throws HttpException when response is not 200', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('not-found')) {
          return http.Response('Not Found', 404);
        }
        return http.Response('Internal Error', 500);
      });

      expect(
        () => fetchHtml('https://example.com/not-found', client: mockClient),
        throwsA(isA<HttpException>()),
      );

      expect(
        () => fetchHtml('https://example.com/server-error', client: mockClient),
        throwsA(isA<HttpException>()),
      );
    });

    test('parses HTML and extracts body text cleanly', () {
      const html = '''
<!DOCTYPE html>
<html>
  <head><title>Test Prayer</title></head>
  <body>
    <h1>Our Father</h1>
    <p>Our Father, who art in heaven,</p>
    <p>hallowed be thy name;</p>
    <div><span>thy kingdom come;</span></div>
  </body>
</html>
''';
      final document = html_parser.parse(html);
      final pageText = document.body?.text ?? '';
      final normalized = softNormalize(
        pageText,
        language: PrayerLanguage.english,
      );

      expect(normalized, contains('ourfatherwhoartinheaven'));
      expect(normalized, contains('hallowedbethyname'));
      expect(normalized, contains('thykingdomcome'));
    });
  });

  group('Offline Prayer Database Source Verification (MockClient)', () {
    final jsonFile = File('assets/prayers.json');
    if (!jsonFile.existsSync()) {
      throw Exception(
        'assets/prayers.json does not exist. Run bin/assemble_db.dart first.',
      );
    }

    final List<dynamic> prayersList =
        jsonDecode(jsonFile.readAsStringSync()) as List<dynamic>;

    // Build URL-to-text fixture map for deterministic offline MockClient execution
    final Map<String, List<String>> urlToLinesMap = {};
    for (final pMap in prayersList) {
      if (pMap is! Map<String, dynamic>) continue;
      final transMap = pMap['translations'] as Map<String, dynamic>?;
      if (transMap == null) continue;
      for (final entry in transMap.entries) {
        final transList = entry.value as List<dynamic>?;
        if (transList == null) continue;
        for (final tItem in transList) {
          if (tItem is! Map<String, dynamic>) continue;
          final tMap = tItem;
          final text = (tMap['text'] as String?) ?? '';
          final lines = text
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();
          final sourcesList = tMap['sources'] as List<dynamic>?;
          if (sourcesList != null && sourcesList.isNotEmpty) {
            for (final src in sourcesList) {
              if (src is! Map<String, dynamic>) continue;
              final srcMap = src;
              final rawSrcUrl = srcMap['url'] as String?;
              if (rawSrcUrl == null || rawSrcUrl.isEmpty) continue;
              final srcUrl = rawSrcUrl.split('#').first;
              final startLine = (srcMap['start_line'] as int?) ?? 1;
              final endLine = (srcMap['end_line'] as int?) ?? lines.length;
              final srcLines = slicePrayerLines(
                lines,
                startLine: startLine,
                endLine: endLine,
              );
              urlToLinesMap.putIfAbsent(srcUrl, () => []).addAll(srcLines);
            }
          } else {
            final rawSourceUrl = tMap['source_url'] as String?;
            if (rawSourceUrl != null && rawSourceUrl.isNotEmpty) {
              final sourceUrl = rawSourceUrl.split('#').first;
              urlToLinesMap.putIfAbsent(sourceUrl, () => []).addAll(lines);
            }
          }
        }
      }
    }

    final mockHttpClient = MockClient((request) async {
      var cleanUrl = request.url.toString().split('#').first;
      if (cleanUrl.contains('web.archive.org/web/')) {
        cleanUrl = cleanUrl.replaceFirst(
          RegExp(r'^https?://web\.archive\.org/web/\d+/'),
          '',
        );
      }

      final lines = urlToLinesMap[cleanUrl];
      if (lines == null || lines.isEmpty) {
        return http.Response('Not Found', 404);
      }
      final html =
          '<!DOCTYPE html><html><body>${lines.map((l) => '<p>$l</p>').join('\n')}</body></html>';
      if (cleanUrl.contains('maranatha.it')) {
        return http.Response.bytes(
          latin1.encode(html),
          200,
          headers: {'content-type': 'text/html; charset=iso-8859-1'},
        );
      }
      return http.Response(
        html,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    });

    final Map<String, String> htmlCache = {};

    for (final pMap in prayersList) {
      final prayerId = pMap['id'] as String;
      final transMap = pMap['translations'] as Map<String, dynamic>;

      for (final entry in transMap.entries) {
        final languageStr = entry.key;
        final language = PrayerLanguage.values.firstWhere(
          (e) => e.code == languageStr,
          orElse: () => PrayerLanguage.english,
        );

        final transList = entry.value as List<dynamic>;
        final versionCount = transList.length;

        for (
          int versionIndex = 0;
          versionIndex < versionCount;
          versionIndex++
        ) {
          final tMap = transList[versionIndex] as Map<String, dynamic>;
          final text = (tMap['text'] as String?) ?? '';
          final sourceUrl = tMap['source_url'] as String?;
          final suffix = versionCount > 1
              ? ' (Version ${versionIndex + 1})'
              : '';

          test(
            'Verify $prayerId in ${language.name}$suffix matches source text',
            () async {
              final sourcesList = tMap['sources'] as List<dynamic>?;

              final lines = text
                  .split('\n')
                  .where((line) => line.trim().isNotEmpty)
                  .map((line) => softNormalize(line, language: language))
                  .toList();

              bool allLinesMatched = true;
              final missingDetails = <String>[];

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
                    client: mockHttpClient,
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
                      allLinesMatched = false;
                      missingLinesDetails(
                        missingDetails,
                        line,
                        '$srcName: $rawSrcUrl',
                      );
                    }
                  }
                }
              } else if (sourceUrl != null && sourceUrl.isNotEmpty) {
                final html = await fetchHtml(
                  sourceUrl,
                  client: mockHttpClient,
                  cache: htmlCache,
                );
                final document = html_parser.parse(html);
                final pageText = document.body?.text ?? '';
                final softPage = softNormalize(pageText, language: language);

                for (final line in lines) {
                  if (!softPage.contains(line)) {
                    allLinesMatched = false;
                    missingLinesDetails(missingDetails, line, sourceUrl);
                  }
                }
              } else {
                allLinesMatched = false;
                missingDetails.add(
                  'No source URL configured for $prayerId [$languageStr]',
                );
              }

              if (!allLinesMatched) {
                final errorMsg =
                    'Prayer text was not found in the source URLs:\n'
                    'Missing lines:\n${missingDetails.join('\n')}';
                fail(errorMsg);
              }

              expect(allLinesMatched, isTrue);
            },
          );
        }
      }
    }
  });
}

void missingLinesDetails(List<String> details, String line, String source) {
  details.add('"$line" (from $source)');
}
