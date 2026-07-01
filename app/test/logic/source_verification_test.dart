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

    // A robust soft normalization to handle HTML tag spacing, punctuation, accents, and casing.
    String softNormalize(String text, {required bool isLatin}) {
      // Strip Wikipedia footnote reference tags like [a] or [1]
      String res = text
          .replaceAll(RegExp(r'\[\w\]'), '')
          .replaceAll(RegExp(r'\[\d+\]'), '');
      // Strip bracket symbols themselves but preserve their inner content (e.g. for [Như đã có...])
      res = res.replaceAll('[', '').replaceAll(']', '');

      res = res.toLowerCase();

      if (isLatin) {
        // Latin is normalized (accent/diacritic stripping and ligature expansion) because:
        // 1. Liturgical Latin source texts (like the Vatican Compendium) use variable pronunciation/chanting
        //    accents (e.g. 'Dóminus', 'María') that do not alter grammatical meaning, unlike modern languages
        //    (e.g., Spanish, French, Vietnamese) where accents change word meaning.
        // 2. Different sources use ligatures (æ/œ) interchangeably with standard letter pairings (ae/oe).
        // Stripping accents/ligatures only for Latin prevents false mismatches due to style and typography
        // while preserving strict accent checks for modern languages.
        res = res
            .replaceAll('æ', 'ae')
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

      // Strip all punctuation and whitespace to do a character-sequence only match.
      // This includes Western and Chinese full-width punctuation.
      res = res.replaceAll(
        RegExp(r"[.,;:!?\-\(\)«»‘’“”\s\u00A0\u200b，。、；：！？「」『』/]+"),
        '',
      );

      // Strip closing Amen or equivalent from the end/body of the text
      res = res
          .replaceAll('amen', '')
          .replaceAll('amon', '')
          .replaceAll('亞孟', '')
          .replaceAll('阿們', '');

      return res;
    }

    // Open compiled JSON database
    final jsonFile = File('assets/prayers.json');
    if (!jsonFile.existsSync()) {
      throw Exception(
        'assets/prayers.json does not exist. Run bin/assemble_db.dart first.',
      );
    }
    final jsonList = jsonDecode(jsonFile.readAsStringSync()) as List<dynamic>;

    for (final prayerItem in jsonList) {
      final pMap = prayerItem as Map<String, dynamic>;
      final prayerId = pMap['id'] as String;
      final category = pMap['category'] as String? ?? 'starter';

      if (category != 'starter') continue;

      final transMap = pMap['translations'] as Map<String, dynamic>;

      for (final entry in transMap.entries) {
        final languageStr = entry.key;
        final language = PrayerLanguage.values.firstWhere(
          (e) => e.toString().split('.').last == languageStr,
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
          final text = tMap['text'] as String;
          final sourceUrl = tMap['source_url'] as String;
          final suffix = versionCount > 1
              ? ' (Version ${versionIndex + 1})'
              : '';

          // Skip specific versions that don't have stable/standard scrapeable online sources
          final skipKey = '$prayerId/${languageStr}_v${versionIndex + 1}';
          final shouldSkip =
              [
                // GitHub Issue #69: fatima_prayer/tagalog
                'fatima_prayer/tagalog_v1',
                // GitHub Issue #70: anima_christi/vietnamese
                'anima_christi/vietnamese_v1',
                // GitHub Issue #71: final_prayer_rosary/vietnamese
                'final_prayer_rosary/vietnamese_v1',
                // GitHub Issue #72: act_of_contrition/tagalog
                'act_of_contrition/tagalog_v1',
              ].contains(skipKey) ||
              // GitHub Issue #73: now_i_lay_me (all languages)
              prayerId == 'now_i_lay_me';

          if (shouldSkip) {
            test(
              'Verify $prayerId in ${language.name}$suffix matches source text (SKIPPED)',
              () {
                // ignore: avoid_print
                print('Skipping source verification for $skipKey');
              },
            );
            continue;
          }

          test(
            'Verify $prayerId in ${language.name}$suffix matches source text',
            () async {
              final html = await fetchHtml(sourceUrl);
              final document = html_parser.parse(html);
              final pageText = document.body?.text ?? '';

              final isLatin = language == PrayerLanguage.latin;
              final softPage = softNormalize(pageText, isLatin: isLatin);

              // Split the prayer into lines by newline to verify each line exists on the page.
              final lines = text
                  .split('\n')
                  .map((line) => softNormalize(line, isLatin: isLatin))
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
                    'Prayer text was not found in the source URL: $sourceUrl\n\n'
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
