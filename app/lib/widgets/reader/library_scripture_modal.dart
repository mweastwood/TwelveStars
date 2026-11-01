import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_citation_parser.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';

Future<void> showLibraryScriptureModal({
  required BuildContext context,
  required BibleCitation citation,
}) async {
  final theme = Theme.of(context);
  final settings = UserSettingsController.instance.value;

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

  final preferredCode = settings.primaryBibleTranslation;
  final preferredInfo = BibleTranslationInfo.allTranslations
      .where((t) => t.code.toUpperCase() == preferredCode.toUpperCase())
      .firstOrNull;
  final effectiveInfo =
      (preferredInfo != null && preferredInfo.supportsBook(citation.bookNumber))
      ? preferredInfo
      : BibleTranslationInfo.getByCode('CPDV');
  final translationCode = effectiveInfo.code;
  final translationSubtitle = effectiveInfo.code == 'CPDV'
      ? 'Catholic Public Domain Version (CPDV)'
      : '${effectiveInfo.name} (${effectiveInfo.code})';

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
  final GlobalKey targetVerseKey = GlobalKey();

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

              if (!hasScrolledToInitialTarget &&
                  hasTargetVerse &&
                  firstTargetIndex > 0) {
                hasScrolledToInitialTarget = true;
                void scrollToTarget([int attempt = 0]) {
                  final targetCtx = targetVerseKey.currentContext;
                  if (targetCtx != null) {
                    Scrollable.ensureVisible(targetCtx, alignment: 0.1);
                    return;
                  }
                  if (attempt < 5 &&
                      scrollController.hasClients &&
                      verses.isNotEmpty) {
                    final position = scrollController.position;
                    final estimatedTotalHeight =
                        position.maxScrollExtent + position.viewportDimension;
                    final targetOffset =
                        ((firstTargetIndex / verses.length) *
                                estimatedTotalHeight)
                            .clamp(0.0, position.maxScrollExtent);
                    scrollController.jumpTo(targetOffset);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => scrollToTarget(attempt + 1),
                    );
                  }
                }

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => scrollToTarget(),
                );
              }

              final loadedChapters = verses.map((v) => v.chapter).toSet();
              final spansMultipleChapters = loadedChapters.length > 1;

              final String headerTitle;
              if (spansMultipleChapters) {
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
                      translationSubtitle,
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

                          return Container(
                            key: index == firstTargetIndex
                                ? targetVerseKey
                                : null,
                            child: BibleVerseRow(
                              verseNumber: verseDisplay.displayVerseNumber,
                              alternateVerseNumber:
                                  verseDisplay.alternateVerseNumber,
                              verseText: verse.verseText,
                              isSelected: isTarget,
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
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
