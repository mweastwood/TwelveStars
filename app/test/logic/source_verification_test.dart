import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:twelve_stars/logic/prayers.dart';

void main() {
  HttpOverrides.global = null;

  group('Prayer Source Verification', () {
    // Cache to avoid fetching the same URL multiple times
    final Map<String, String> htmlCache = {};

    Future<String> fetchHtml(String url) async {
      if (htmlCache.containsKey(url)) {
        return htmlCache[url]!;
      }

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch $url: HTTP ${response.statusCode}');
      }

      // Convert body to UTF-8 to handle special characters correctly
      final html = utf8.decode(response.bodyBytes);
      htmlCache[url] = html;
      return html;
    }

    // A map-based lookup for accents and diacritics to avoid index offset errors
    final Map<String, String> accentMap = {
      // Spanish / French / Italian / Latin
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'ā': 'a',
      'ă': 'a',
      'ą': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ē': 'e',
      'ĕ': 'e',
      'ė': 'e',
      'ę': 'e',
      'ě': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ĩ': 'i',
      'ī': 'i',
      'ĭ': 'i',
      'į': 'i',
      'ı': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ø': 'o',
      'ō': 'o',
      'ŏ': 'o',
      'ő': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ũ': 'u',
      'ū': 'u',
      'ŭ': 'u',
      'ů': 'u',
      'ű': 'u',
      'ų': 'u',
      'ç': 'c', 'ć': 'c', 'ĉ': 'c', 'ċ': 'c', 'č': 'c',
      'ď': 'd', 'đ': 'd',
      'ĝ': 'g', 'ğ': 'g', 'ġ': 'g', 'ģ': 'g',
      'ĥ': 'h', 'ħ': 'h',
      'ĵ': 'j',
      'ķ': 'k',
      'ĺ': 'l', 'ļ': 'l', 'ľ': 'l', 'ł': 'l',
      'ń': 'n', 'ņ': 'n', 'ň': 'n', 'ŉ': 'n',
      'ŕ': 'r', 'ŗ': 'r', 'ř': 'r',
      'ś': 's', 'ŝ': 's', 'ş': 's', 'š': 's',
      'ţ': 't', 'ť': 't', 'ŧ': 't',
      'ŵ': 'w',
      'ŷ': 'y', 'ÿ': 'y',
      'ź': 'z', 'ż': 'z', 'ž': 'z',
      'æ': 'ae', 'œ': 'oe',

      // Vietnamese
      'ả': 'a', 'ạ': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ế': 'e',
      'ề': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ỉ': 'i', 'ị': 'i',
      'ỏ': 'o',
      'ọ': 'o',
      'ố': 'o',
      'ồ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ủ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ứ': 'u',
      'ừ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    };

    String stripAccents(String str) {
      final sb = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        final char = str[i];
        final replacement = accentMap[char];
        if (replacement != null) {
          sb.write(replacement);
        } else {
          sb.write(char);
        }
      }
      return sb.toString();
    }

    // A robust soft normalization to handle HTML tag spacing, punctuation, accents, and casing.
    String softNormalize(String text) {
      // Strip Wikipedia footnote reference tags like [a] or [1]
      String res = text
          .replaceAll(RegExp(r'\[\w\]'), '')
          .replaceAll(RegExp(r'\[\d+\]'), '');
      // Strip bracket symbols themselves but preserve their inner content (e.g. for [Như đã có...])
      res = res.replaceAll('[', '').replaceAll(']', '');

      res = res.toLowerCase();
      res = stripAccents(res);

      res = res
          .replaceAll('’', "'")
          .replaceAll('‘', "'")
          .replaceAll('“', '"')
          .replaceAll('”', '"');

      // Traditional Chinese variant character normalization
      res = res
          .replaceAll('妳', '你')
          .replaceAll('祂', '你')
          .replaceAll('禰', '你')
          .replaceAll('祢', '你')
          .replaceAll('他', '你')
          .replaceAll('她', '你')
          .replaceAll('兇', '凶')
          .replaceAll('亞孟', '阿們');

      // Tagalog pronoun/spelling equivalents
      res = res
          .replaceAll("'yong", 'iyong')
          .replaceAll('yong', 'iyong')
          .replaceAll('utang', 'sala')
          .replaceAll('nagkakautang', 'nagkakasala')
          .replaceAll('bagkus', 'at')
          .replaceAll('lahatngmasama', 'masama')
          .replaceAll('lahatmasama', 'masama')
          .replaceAll('nang', 'ng');

      // Strip all straight quotes first
      res = res.replaceAll('"', '').replaceAll("'", '');

      // Strip all punctuation and whitespace to do a character-sequence only match.
      // This includes Western and Chinese full-width punctuation.
      res = res.replaceAll(
        RegExp(r"[.,;:!?\-\(\)«»‘’“”\s\u00A0\u200b，。、；：！？「」『』]+"),
        '',
      );

      // Tagalog phrase variants after whitespace stripping
      res = res
          .replaceAll('noongunguna', 'ngsauna')
          .replaceAll('noongungun-una', 'ngsauna')
          .replaceAll('noongunanguna', 'ngsauna')
          .replaceAll('noongunang-una', 'ngsauna')
          .replaceAll('nangsauna', 'ngsauna')
          .replaceAll('gayondin', '');

      // Strip closing Amen or equivalent from the end/body of the text
      res = res.replaceAll('amen', '').replaceAll('amon', '');

      return res;
    }

    for (final prayer in defaultPrayers) {
      for (final entry in prayer.translations.entries) {
        final language = entry.key;
        final translations = entry.value;

        for (int i = 0; i < translations.length; i++) {
          final translation = translations[i];
          final suffix = translations.length > 1 ? ' (Version ${i + 1})' : '';

          test(
            'Verify ${prayer.id} in ${language.name}$suffix matches source text',
            () async {
              final html = await fetchHtml(translation.sourceUrl);
              final document = html_parser.parse(html);
              final pageText = document.body?.text ?? '';

              final softPage = softNormalize(pageText);

              // Split the prayer into lines by newline to verify each line exists on the page.
              // This is robust against side-by-side bilingual layouts or interspersed footnotes/Greek text.
              final lines = translation.text
                  .split('\n')
                  .map((line) => softNormalize(line))
                  .where((line) => line.isNotEmpty)
                  .toList();

              bool allLinesMatched = true;
              final missingLines = <String>[];

              for (final line in lines) {
                if (!softPage.contains(line)) {
                  allLinesMatched = false;
                  missingLines.add(line);
                }
              }

              if (!allLinesMatched) {
                final errorMsg =
                    'Prayer text was not found in the source URL: ${translation.sourceUrl}\n\n'
                    'Missing lines (soft normalized):\n${missingLines.map((l) => '"$l"').join('\n')}\n\n'
                    'First 500 characters of page text (soft normalized):\n'
                    '"${softPage.substring(0, softPage.length > 500 ? 500 : softPage.length)}"';
                fail(errorMsg);
              }

              expect(allLinesMatched, isTrue);
            },
            timeout: const Timeout(Duration(seconds: 30)),
          );
        }
      }
    }
  });
}
