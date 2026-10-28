import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';

Future<void> showLibraryScriptureModal({
  required BuildContext context,
  required BibleCitation citation,
}) async {
  final theme = Theme.of(context);
  final settings = UserSettingsController.instance.value;

  final preferredTrans = BibleTranslationInfo.getByCode(
    settings.primaryBibleTranslation,
  );
  final activeTransInfo = preferredTrans.supportsBook(citation.bookNumber)
      ? preferredTrans
      : BibleTranslationInfo.getByCode('CPDV');
  final translationCode = activeTransInfo.code;

  final isModern = citation.verseSystem == 'modern';
  final BibleNumberingSystem effectiveNumberingSystem;
  if (settings.bibleNumberingSystem != BibleNumberingSystem.vulgate) {
    effectiveNumberingSystem = settings.bibleNumberingSystem;
  } else if (isModern) {
    effectiveNumberingSystem = BibleNumberingSystem.dual;
  } else {
    effectiveNumberingSystem = BibleNumberingSystem.vulgate;
  }

  late final ({int chapter, int verse}) resolvedStart;
  late final ({int chapter, int verse}) resolvedEnd;
  late final bool hasTargetVerse;

  if (isModern && citation.verse == null && citation.bookNumber == 21) {
    switch (citation.chapter) {
      case 9:
        resolvedStart = (chapter: 9, verse: 1);
        resolvedEnd = (chapter: 9, verse: 21);
        hasTargetVerse = true;
      case 10:
        resolvedStart = (chapter: 9, verse: 22);
        resolvedEnd = (chapter: 9, verse: 39);
        hasTargetVerse = true;
      case 114:
        resolvedStart = (chapter: 113, verse: 1);
        resolvedEnd = (chapter: 113, verse: 8);
        hasTargetVerse = true;
      case 115:
        resolvedStart = (chapter: 113, verse: 9);
        resolvedEnd = (chapter: 113, verse: 26);
        hasTargetVerse = true;
      case 116:
        resolvedStart = (chapter: 114, verse: 1);
        resolvedEnd = (chapter: 115, verse: 999);
        hasTargetVerse = false;
      case 147:
        resolvedStart = (chapter: 146, verse: 1);
        resolvedEnd = (chapter: 147, verse: 999);
        hasTargetVerse = false;
      default:
        final vCh = BibleVerseResolver.masoreticToVulgatePsalm(
          citation.chapter,
        );
        resolvedStart = (chapter: vCh, verse: 1);
        resolvedEnd = (chapter: vCh, verse: 999);
        hasTargetVerse = false;
    }
  } else {
    resolvedStart = isModern
        ? BibleVerseResolver.masoreticToVulgateVerse(
            bookNumber: citation.bookNumber,
            chapter: citation.chapter,
            verse: citation.verse ?? 1,
          )
        : (chapter: citation.chapter, verse: citation.verse ?? 1);

    resolvedEnd = (isModern && (citation.endVerse ?? citation.verse) != null)
        ? BibleVerseResolver.masoreticToVulgateVerses(
            bookNumber: citation.bookNumber,
            chapter: citation.chapter,
            verse: (citation.endVerse ?? citation.verse)!,
          ).last
        : (
            chapter: resolvedStart.chapter,
            verse: citation.endVerse ?? resolvedStart.verse,
          );
    hasTargetVerse = citation.verse != null;
  }

  final startVulgateChapter = resolvedStart.chapter;
  final endVulgateChapter = resolvedEnd.chapter >= resolvedStart.chapter
      ? resolvedEnd.chapter
      : resolvedStart.chapter;

  final versesFuture = () async {
    await BibleDatabaseHelper.db.ensureBookPopulated(
      citation.bookNumber,
      citation.bookName,
      citation.abbrev,
      translation: translationCode,
    );
    final loaded = <BibleVerse>[];
    for (int ch = startVulgateChapter; ch <= endVulgateChapter; ch++) {
      final chVerses = await BibleDatabaseHelper.db.getChapterVerses(
        translationCode,
        citation.bookNumber,
        ch,
      );
      loaded.addAll(chVerses);
    }
    return loaded;
  }();
  bool hasScrolledToInitialTarget = false;
  final firstTargetKey = GlobalKey();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (sheetCtx, scrollController) {
          return FutureBuilder<List<BibleVerse>>(
            future: versesFuture,
            builder: (bCtx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final verses = snapshot.data ?? [];

              bool isVerseInTargetRange(BibleVerse v) {
                if (!hasTargetVerse) return false;
                if (resolvedEnd.chapter < resolvedStart.chapter ||
                    (resolvedEnd.chapter == resolvedStart.chapter &&
                        resolvedEnd.verse < resolvedStart.verse)) {
                  return false;
                }
                final afterOrAtStart =
                    v.chapter > resolvedStart.chapter ||
                    (v.chapter == resolvedStart.chapter &&
                        v.verseNumber >= resolvedStart.verse);
                final beforeOrAtEnd =
                    v.chapter < resolvedEnd.chapter ||
                    (v.chapter == resolvedEnd.chapter &&
                        v.verseNumber <= resolvedEnd.verse);
                return afterOrAtStart && beforeOrAtEnd;
              }

              final firstTargetIndex = hasTargetVerse
                  ? verses.indexWhere(isVerseInTargetRange)
                  : -1;

              if (!hasScrolledToInitialTarget && firstTargetIndex > 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!hasScrolledToInitialTarget &&
                      scrollController.hasClients) {
                    hasScrolledToInitialTarget = true;
                    final roughOffset = (firstTargetIndex * 56.0).clamp(
                      0.0,
                      scrollController.position.maxScrollExtent,
                    );
                    scrollController.jumpTo(roughOffset);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final targetCtx = firstTargetKey.currentContext;
                      if (targetCtx != null) {
                        Scrollable.ensureVisible(targetCtx, alignment: 0.15);
                      }
                    });
                  }
                });
              }

              final String headerTitle;
              if (startVulgateChapter != endVulgateChapter) {
                if (effectiveNumberingSystem == BibleNumberingSystem.modern &&
                    isModern) {
                  headerTitle = '${citation.bookName} ${citation.chapter}';
                } else if (isModern) {
                  headerTitle =
                      '${citation.bookName} $startVulgateChapter–$endVulgateChapter (Modern ${citation.chapter})';
                } else {
                  headerTitle =
                      '${citation.bookName} $startVulgateChapter–$endVulgateChapter';
                }
              } else if (effectiveNumberingSystem ==
                  BibleNumberingSystem.modern) {
                headerTitle = isModern
                    ? '${citation.bookName} ${citation.chapter}'
                    : BibleVerseResolver.formatChapterTitle(
                        bookNumber: citation.bookNumber,
                        bookName: citation.bookName,
                        chapter: startVulgateChapter,
                        numberingSystem: BibleNumberingSystem.modern,
                      );
              } else if (effectiveNumberingSystem ==
                  BibleNumberingSystem.dual) {
                headerTitle =
                    (isModern && startVulgateChapter != citation.chapter)
                    ? '${citation.bookName} $startVulgateChapter (Modern ${citation.chapter})'
                    : BibleVerseResolver.formatChapterTitle(
                        bookNumber: citation.bookNumber,
                        bookName: citation.bookName,
                        chapter: startVulgateChapter,
                        numberingSystem: BibleNumberingSystem.dual,
                      );
              } else {
                headerTitle = '${citation.bookName} $startVulgateChapter';
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      headerTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeTransInfo.name.contains('(${activeTransInfo.code})')
                          ? activeTransInfo.name
                          : '${activeTransInfo.name} (${activeTransInfo.code})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: verses.length,
                        itemBuilder: (lCtx, index) {
                          final verse = verses[index];
                          final isTarget = isVerseInTargetRange(verse);

                          final verseDisplay =
                              BibleVerseResolver.formatVerseDisplay(
                                bookNumber: citation.bookNumber,
                                chapter: verse.chapter,
                                verseNumber: verse.verseNumber,
                                numberingSystem: effectiveNumberingSystem,
                              );
                          final hasAlt =
                              verseDisplay.alternateVerseNumber != null;
                          final multiChapterPrefix =
                              startVulgateChapter != endVulgateChapter &&
                                  effectiveNumberingSystem !=
                                      BibleNumberingSystem.modern
                              ? '${verse.chapter}:'
                              : '';
                          final verseNumText = hasAlt
                              ? '$multiChapterPrefix${verseDisplay.displayVerseNumber} (${verseDisplay.alternateVerseNumber})'
                              : '$multiChapterPrefix${verseDisplay.displayVerseNumber}';

                          return AnimatedContainer(
                            key: index == firstTargetIndex
                                ? firstTargetKey
                                : null,
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 2.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              color: isTarget
                                  ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.4)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                              border: isTarget
                                  ? Border(
                                      left: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 3.5,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                SizedBox(
                                  width: hasAlt
                                      ? (verseNumText.length > 7 ? 68 : 52)
                                      : (verseNumText.length > 2 ? 38 : 28),
                                  child: Text(
                                    verseNumText,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      height: 1.5,
                                      fontSize: hasAlt ? 11.0 : null,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    verse.verseText,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.5,
                                      fontWeight: isTarget
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
