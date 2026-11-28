import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/bible_numbering_mapper.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';
import 'package:twelve_stars/logic/lectionary_resolver.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/psalm_response_service.dart';
import 'package:twelve_stars/logic/reader/bible_reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_node_id.dart';
import 'package:twelve_stars/logic/reader/reader_selection_controller.dart';
import 'package:twelve_stars/logic/reverse_citation_service.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/widgets/bible_verse_row.dart';
import 'package:twelve_stars/widgets/reader/bible_verse_modals.dart';
import 'package:twelve_stars/widgets/reader/mass_psalm_widgets.dart';
import 'package:twelve_stars/widgets/reader/mass_reading_dialogue_box.dart';
import 'package:twelve_stars/widgets/reader/reader_selection_action_bar.dart';

/// Encapsulates an active verse selection within a [MassReadingCard],
/// allowing parent widgets like [MissalTab] to render a floating action bar.
///
/// Action callbacks are bound to closures within the active [MassReadingCard]
/// state instance. Value equality is based on [readingIdentifier], [citation],
/// and [selectedCount].
class MassReadingSelection {
  final String readingIdentifier;
  final String citation;
  final int selectedCount;
  final VoidCallback onSaveFavorite;
  final VoidCallback onCopy;
  final VoidCallback? onAddComment;
  final VoidCallback onClearSelection;

  const MassReadingSelection({
    required this.readingIdentifier,
    required this.citation,
    required this.selectedCount,
    required this.onSaveFavorite,
    required this.onCopy,
    this.onAddComment,
    required this.onClearSelection,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MassReadingSelection &&
          runtimeType == other.runtimeType &&
          readingIdentifier == other.readingIdentifier &&
          citation == other.citation &&
          selectedCount == other.selectedCount;

  @override
  int get hashCode => Object.hash(readingIdentifier, citation, selectedCount);
}

/// Renders an individual reading for the Catholic Mass lectionary.
///
/// Automatically indexes reverse Bible citations across patristic, Marian,
/// and theological library sources via [ReverseCitationService], displaying citation badges on verse rows
/// and opening reverse citations modals on tap.
class MassReadingCard extends StatefulWidget {
  final LectionaryReading reading;
  final double fontSize;
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage? compareLanguage;
  final bool isSelected;
  final ValueChanged<MassReadingSelection?>? onSelectionChanged;

  const MassReadingCard({
    super.key,
    required this.reading,
    this.fontSize = 16.0,
    this.primaryLanguage = PrayerLanguage.english,
    this.compareLanguage,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  State<MassReadingCard> createState() => _MassReadingCardState();
}

class _MassReadingCardState extends State<MassReadingCard> {
  bool _isExpanded = true;
  bool _isLoading = false;
  List<BibleVerse>? _verses;
  List<List<BibleVerse>>? _psalmStanzas;
  PsalmResponseSpec? _psalmResponseSpec;
  List<BibleVerse>? _psalmResponseVerses;
  Map<String, List<UserComment>> _commentsByNodeId = {};
  Map<String, List<FavoritePassage>> _favoritesByVerseKey = {};
  String? _errorMessage;

  bool get _isPsalm => widget.reading.readingType.toLowerCase() == 'psalm';

  String? _loadedTranslation;
  String? _loadingTranslation;
  int _loadGeneration = 0;
  BibleNumberingSystem _numberingSystem = BibleNumberingSystem.vulgate;
  final ReaderSelectionController _selectionController =
      ReaderSelectionController();

  @override
  void initState() {
    super.initState();
    UserSettingsController.instance.addListener(_onSettingsChanged);
    _loadVerses();
  }

  @override
  void dispose() {
    UserSettingsController.instance.removeListener(_onSettingsChanged);
    _selectionController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final settings = UserSettingsController.instance.value;
    final requestedTranslation = settings.primaryBibleTranslation;
    final transInfo = BibleTranslationInfo.getByCode(requestedTranslation);
    final translation = transInfo.supportsBook(widget.reading.bookNumber)
        ? requestedTranslation
        : 'CPDV';
    final activeTranslation = _loadingTranslation ?? _loadedTranslation;
    if (activeTranslation != null && activeTranslation != translation) {
      final hadSelection = _selectionController.hasSelection;
      _selectionController.clear();
      if (hadSelection) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_selectionController.hasSelection) {
            _notifySelectionChanged();
          }
        });
      }
      _loadVerses();
    } else if (_numberingSystem != settings.bibleNumberingSystem) {
      setState(() {
        _numberingSystem = settings.bibleNumberingSystem;
      });
      if (_selectionController.hasSelection) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectionController.hasSelection) {
            _notifySelectionChanged();
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(MassReadingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reading != widget.reading) {
      final hadSelection = _selectionController.hasSelection;
      _selectionController.clear();
      if (hadSelection && !(oldWidget.isSelected && !widget.isSelected)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_selectionController.hasSelection) {
            _notifySelectionChanged();
          }
        });
      }
      _loadVerses(force: true);
    } else if (oldWidget.primaryLanguage != widget.primaryLanguage ||
        oldWidget.compareLanguage != widget.compareLanguage) {
      setState(() {});
    }

    if (widget.onSelectionChanged != null &&
        oldWidget.isSelected &&
        !widget.isSelected) {
      setState(() {
        _selectionController.clear();
      });
    }
  }

  String get _readingTitle {
    switch (widget.reading.readingType) {
      case 'first':
        return 'First Reading';
      case 'second':
        return 'Second Reading';
      case 'psalm':
        return 'Responsorial Psalm';
      case 'gospel':
        return 'Gospel';
      default:
        return 'Reading';
    }
  }

  IconData get _readingIcon {
    switch (widget.reading.readingType) {
      case 'first':
      case 'second':
        return Icons.menu_book;
      case 'psalm':
        return Icons.music_note;
      case 'gospel':
        return Icons.auto_stories;
      default:
        return Icons.book;
    }
  }

  Set<int> _resolveTargetChapters() {
    final ranges = resolveReadingRanges(
      bookNumber: widget.reading.bookNumber,
      defaultChapter: widget.reading.chapter,
      defaultVerseRange: widget.reading.verseRange,
      citation: widget.reading.citation,
    );
    final chapters = ranges.map((r) => r.chapter).toSet();
    return chapters.isNotEmpty ? chapters : {widget.reading.chapter};
  }

  Future<void> _loadFavorites() async {
    try {
      final byVerseKey =
          await BibleReaderAdapter.fetchFavoritesByNodeIdForChapters(
            widget.reading.bookNumber,
            _resolveTargetChapters(),
          );
      if (mounted) {
        setState(() {
          _favoritesByVerseKey = byVerseKey;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    try {
      final bookMeta =
          catholicBooksByNumber[widget.reading.bookNumber] ??
          (throw Exception('Book ${widget.reading.bookName} not found'));
      final byNodeId =
          await BibleReaderAdapter.fetchCommentsByNodeIdForChapters(
            bookMeta.abbrev,
            _resolveTargetChapters(),
          );
      if (mounted) {
        setState(() {
          _commentsByNodeId = byNodeId;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadVerses({bool force = false}) async {
    final loadGen = ++_loadGeneration;
    final settings = UserSettingsController.instance.isInitialized
        ? UserSettingsController.instance.value
        : await UserSettingsController.instance.load();
    if (!mounted || loadGen != _loadGeneration) return;

    final requestedTranslation = settings.primaryBibleTranslation;
    final transInfo = BibleTranslationInfo.getByCode(requestedTranslation);
    final translation = transInfo.supportsBook(widget.reading.bookNumber)
        ? requestedTranslation
        : 'CPDV';

    if (_verses != null &&
        _loadedTranslation == translation &&
        _loadingTranslation == null &&
        !force) {
      return;
    }

    _loadingTranslation = translation;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      ReverseCitationService.ensureIndexed().then((_) {
        if (mounted) setState(() {});
      });

      final db = BibleDatabaseHelper.db;
      final bookMeta =
          catholicBooksByNumber[widget.reading.bookNumber] ??
          (throw Exception('Book ${widget.reading.bookName} not found'));
      await db.ensureBookPopulated(
        bookMeta.bookNumber,
        bookMeta.bookName,
        bookMeta.abbrev,
        translation: translation,
      );
      if (!mounted || loadGen != _loadGeneration) return;

      await _loadFavorites();
      if (!mounted || loadGen != _loadGeneration) return;

      await _loadComments();
      if (!mounted || loadGen != _loadGeneration) return;

      List<BibleVerse> verses;
      List<List<BibleVerse>>? psalmStanzas;
      PsalmResponseSpec? psalmResponseSpec;
      List<BibleVerse>? psalmResponseVerses;

      if (_isPsalm) {
        final stanzaRanges = resolvePsalmStanzas(
          bookNumber: widget.reading.bookNumber,
          defaultChapter: widget.reading.chapter,
          defaultVerseRange: widget.reading.verseRange,
          citation: widget.reading.citation,
        );
        final flatRanges = [for (final s in stanzaRanges) ...s];
        final fetched = await db.getVersesForRanges(
          translationCode: translation,
          bookNumber: widget.reading.bookNumber,
          ranges: flatRanges,
        );
        if (!mounted || loadGen != _loadGeneration) return;

        final byChapVerse = <(int, int), BibleVerse>{
          for (final v in fetched) (v.chapter, v.verseNumber): v,
        };
        final hydratedStanzas = <List<BibleVerse>>[];
        for (final stanza in stanzaRanges) {
          final stanzaVerses = <BibleVerse>[];
          final seenInStanza = <(int, int)>{};
          void addVerse(BibleVerse v) {
            if (seenInStanza.add((v.chapter, v.verseNumber))) {
              stanzaVerses.add(v);
            }
          }

          for (final range in stanza) {
            if (range.verses != null) {
              for (final vNum in range.verses!) {
                final match = byChapVerse[(range.chapter, vNum)];
                if (match != null) {
                  addVerse(match);
                }
              }
              if (range.startVerseLimit != null ||
                  range.endVerseLimit != null) {
                for (final v in fetched) {
                  if (v.chapter != range.chapter) continue;
                  final matchesStart =
                      range.startVerseLimit != null &&
                      v.verseNumber >= range.startVerseLimit!;
                  final matchesEnd =
                      range.endVerseLimit != null &&
                      v.verseNumber <= range.endVerseLimit!;
                  if (matchesStart || matchesEnd) {
                    addVerse(v);
                  }
                }
              }
            } else {
              for (final v in fetched) {
                if (v.chapter != range.chapter) continue;
                if (range.startVerseLimit != null &&
                    v.verseNumber < range.startVerseLimit!) {
                  continue;
                }
                if (range.endVerseLimit != null &&
                    v.verseNumber > range.endVerseLimit!) {
                  continue;
                }
                addVerse(v);
              }
            }
          }
          if (stanzaVerses.isNotEmpty) {
            hydratedStanzas.add(stanzaVerses);
          }
        }
        psalmStanzas = hydratedStanzas;
        verses = [for (final s in hydratedStanzas) ...s];

        if (PsalmResponseService.isLoaded) {
          final resolved = await _fetchPsalmResponse(
            db: db,
            loadGen: loadGen,
            requestedTranslation: requestedTranslation,
            transInfo: transInfo,
            psalmTranslation: translation,
          );
          if (!mounted || loadGen != _loadGeneration) return;
          psalmResponseSpec = resolved.spec;
          psalmResponseVerses = resolved.verses;
        } else {
          PsalmResponseService.ensureLoaded().then((_) async {
            if (!mounted || loadGen != _loadGeneration) return;
            if (!PsalmResponseService.isLoaded) return;
            try {
              final resolved = await _fetchPsalmResponse(
                db: db,
                loadGen: loadGen,
                requestedTranslation: requestedTranslation,
                transInfo: transInfo,
                psalmTranslation: translation,
              );
              if (!mounted || loadGen != _loadGeneration) return;
              if (resolved.spec != null) {
                setState(() {
                  _psalmResponseSpec = resolved.spec;
                  _psalmResponseVerses = resolved.verses;
                });
              }
            } catch (_) {}
          });
        }
      } else {
        final ranges = resolveReadingRanges(
          bookNumber: widget.reading.bookNumber,
          defaultChapter: widget.reading.chapter,
          defaultVerseRange: widget.reading.verseRange,
          citation: widget.reading.citation,
        );

        verses = await db.getVersesForRanges(
          translationCode: translation,
          bookNumber: widget.reading.bookNumber,
          ranges: ranges,
        );
      }

      if (mounted && loadGen == _loadGeneration) {
        final currentNumbering = UserSettingsController.instance.isInitialized
            ? UserSettingsController.instance.value.bibleNumberingSystem
            : settings.bibleNumberingSystem;
        setState(() {
          _verses = verses;
          _psalmStanzas = psalmStanzas;
          _psalmResponseSpec = psalmResponseSpec;
          _psalmResponseVerses = psalmResponseVerses;
          _loadedTranslation = translation;
          _loadingTranslation = null;
          _numberingSystem = currentNumbering;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && loadGen == _loadGeneration) {
        setState(() {
          _loadingTranslation = null;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<({PsalmResponseSpec? spec, List<BibleVerse>? verses})>
  _fetchPsalmResponse({
    required BibleDatabase db,
    required int loadGen,
    required String requestedTranslation,
    required BibleTranslationInfo transInfo,
    required String psalmTranslation,
  }) async {
    final spec = PsalmResponseService.getForReadingKey(
      widget.reading.readingKey,
    );
    if (spec == null || spec.isAlleluia || !spec.hasRefrain) {
      return (spec: spec, verses: null);
    }

    final responseBookNum = spec.targetBookNumber(widget.reading.bookNumber);
    final responseRanges = spec.resolveVulgateRanges(
      defaultBookNumber: widget.reading.bookNumber,
      defaultChapter: widget.reading.chapter,
    );
    if (responseRanges.isEmpty) {
      return (spec: spec, verses: null);
    }

    final responseTranslation = transInfo.supportsBook(responseBookNum)
        ? requestedTranslation
        : 'CPDV';
    if (responseBookNum != widget.reading.bookNumber ||
        responseTranslation != psalmTranslation) {
      final responseBookMeta = catholicBooksByNumber[responseBookNum];
      if (responseBookMeta != null) {
        await db.ensureBookPopulated(
          responseBookMeta.bookNumber,
          responseBookMeta.bookName,
          responseBookMeta.abbrev,
          translation: responseTranslation,
        );
        if (!mounted || loadGen != _loadGeneration) {
          return (spec: null, verses: null);
        }
      }
    }

    final fetchedResponse = await db.getVersesForRanges(
      translationCode: responseTranslation,
      bookNumber: responseBookNum,
      ranges: responseRanges,
    );
    if (!mounted || loadGen != _loadGeneration) {
      return (spec: null, verses: null);
    }

    final respMap = <(int, int), BibleVerse>{
      for (final v in fetchedResponse) (v.chapter, v.verseNumber): v,
    };
    final orderedResponse = <BibleVerse>[];
    for (final range in responseRanges) {
      if (range.verses != null) {
        for (final vNum in range.verses!) {
          final match = respMap[(range.chapter, vNum)];
          if (match != null) {
            orderedResponse.add(match);
          }
        }
      }
    }
    return (spec: spec, verses: orderedResponse);
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _clearSelection();
      }
    });
    if (_isExpanded) {
      _loadVerses();
    }
  }

  String get _readingIdentifier =>
      '${widget.reading.readingKey}_${widget.reading.readingType}_${widget.reading.id}';

  bool _isVerseSelected(int index) => _selectionController.isSelected(index);

  void _onVerseLongPress(int index) {
    setState(() {
      _selectionController.onLongPress(index);
      _notifySelectionChanged();
    });
  }

  void _onVerseTap(int index) {
    if (_selectionController.hasSelection) {
      setState(() {
        _selectionController.onTap(index);
        _notifySelectionChanged();
      });
    }
  }

  void _clearSelection({bool notify = true}) {
    setState(() {
      _selectionController.clear();
      if (notify) {
        _notifySelectionChanged();
      }
    });
  }

  void _notifySelectionChanged() {
    // Invariant: Must be called inside or after updating _selectionController
    // so _createSelectionData reflects current state.
    widget.onSelectionChanged?.call(_createSelectionData());
  }

  String _formatSelectionCitation(
    BibleVerse firstV,
    BibleVerse lastV, {
    required bool isSingleVerse,
  }) {
    return BibleReaderAdapter.formatPassageCitation(
      bookNumber: firstV.bookNumber,
      bookName: firstV.bookName,
      startChapter: firstV.chapter,
      startVerse: firstV.verseNumber,
      endChapter: isSingleVerse ? firstV.chapter : lastV.chapter,
      endVerse: isSingleVerse ? firstV.verseNumber : lastV.verseNumber,
      numberingSystem: _numberingSystem,
      crossChapterSeparator: ' - ',
    );
  }

  String _formatVerseCitation(BibleVerse verse) =>
      _formatSelectionCitation(verse, verse, isSingleVerse: true);

  List<List<BibleVerse>> _splitContiguousRuns(List<BibleVerse> sortedVerses) {
    final runs = <List<BibleVerse>>[];
    for (final v in sortedVerses) {
      if (runs.isNotEmpty) {
        final prev = runs.last.last;
        if (prev.bookNumber == v.bookNumber &&
            prev.chapter == v.chapter &&
            v.verseNumber == prev.verseNumber + 1) {
          runs.last.add(v);
          continue;
        }
      }
      runs.add([v]);
    }
    return runs;
  }

  String _formatContiguousRunsCitation(List<List<BibleVerse>> runs) {
    if (runs.length == 1) {
      final run = runs.first;
      return _formatSelectionCitation(
        run.first,
        run.last,
        isSingleVerse: run.length == 1,
      );
    }
    final firstRun = runs.first;
    final allSameBookAndChapter = runs.every(
      (r) =>
          r.first.bookNumber == firstRun.first.bookNumber &&
          r.first.chapter == firstRun.first.chapter,
    );
    if (allSameBookAndChapter &&
        _numberingSystem != BibleNumberingSystem.dual) {
      final head = _formatSelectionCitation(
        firstRun.first,
        firstRun.last,
        isSingleVerse: firstRun.length == 1,
      );
      final tailParts = <String>[];
      for (int i = 1; i < runs.length; i++) {
        final run = runs[i];
        final startDisp = BibleVerseResolver.formatVerseDisplay(
          bookNumber: run.first.bookNumber,
          chapter: run.first.chapter,
          verseNumber: run.first.verseNumber,
          numberingSystem: _numberingSystem,
        ).displayVerseNumber;
        if (run.length == 1) {
          tailParts.add('$startDisp');
        } else {
          final endDisp = BibleVerseResolver.formatVerseDisplay(
            bookNumber: run.last.bookNumber,
            chapter: run.last.chapter,
            verseNumber: run.last.verseNumber,
            numberingSystem: _numberingSystem,
          ).displayVerseNumber;
          tailParts.add('$startDisp-$endDisp');
        }
      }
      return '$head, ${tailParts.join(', ')}';
    }
    return runs
        .map(
          (r) => _formatSelectionCitation(
            r.first,
            r.last,
            isSingleVerse: r.length == 1,
          ),
        )
        .join('; ');
  }

  String? _formatResponseCitation(List<BibleVerse>? verses) {
    if (verses == null || verses.isEmpty) return null;
    final sorted = List<BibleVerse>.from(verses)
      ..sort((a, b) {
        final chapCmp = a.chapter.compareTo(b.chapter);
        return chapCmp != 0 ? chapCmp : a.verseNumber.compareTo(b.verseNumber);
      });
    final runs = _splitContiguousRuns(sorted);
    if (runs.length == 1) {
      final run = runs.first;
      return BibleReaderAdapter.formatPassageCitation(
        bookNumber: run.first.bookNumber,
        bookName: run.first.bookName,
        startChapter: run.first.chapter,
        startVerse: run.first.verseNumber,
        endChapter: run.last.chapter,
        endVerse: run.last.verseNumber,
        numberingSystem: _numberingSystem,
        crossChapterSeparator: ' - ',
      );
    }
    return _formatContiguousRunsCitation(runs);
  }

  MassReadingSelection? _createSelectionData() {
    if (!_selectionController.hasSelection ||
        _verses == null ||
        _verses!.isEmpty) {
      return null;
    }

    final start = _selectionController.start!;
    final end = _selectionController.end!;
    if (start >= _verses!.length || end >= _verses!.length) {
      return null;
    }
    final rawSelectedVerses = _verses!.sublist(start, end + 1);
    final seenKeys = <(int, int, int)>{};
    final uniqueVerses = <BibleVerse>[];
    for (final v in rawSelectedVerses) {
      if (seenKeys.add((v.bookNumber, v.chapter, v.verseNumber))) {
        uniqueVerses.add(v);
      }
    }

    // Sort into canonical (chapter, verseNumber) order so non-monotonic psalm
    // stanzas (e.g. Ps 136:1 and 23-24, 10-12) never yield inverted ranges.
    final sortedVerses = List<BibleVerse>.from(uniqueVerses)
      ..sort((a, b) {
        final chapCmp = a.chapter.compareTo(b.chapter);
        return chapCmp != 0 ? chapCmp : a.verseNumber.compareTo(b.verseNumber);
      });
    bool wasReordered = false;
    for (int i = 0; i < uniqueVerses.length; i++) {
      if (uniqueVerses[i].chapter != sortedVerses[i].chapter ||
          uniqueVerses[i].verseNumber != sortedVerses[i].verseNumber) {
        wasReordered = true;
        break;
      }
    }

    final runs = _splitContiguousRuns(sortedVerses);
    final selectedVerses = wasReordered ? sortedVerses : uniqueVerses;
    final count = selectedVerses.length;
    final firstV = selectedVerses.first;
    final lastV = selectedVerses.last;

    final hasSameChapterDisjointRuns =
        runs.length > 1 &&
        runs.every((r) => r.first.chapter == runs.first.first.chapter);
    final citation = (wasReordered || (_isPsalm && hasSameChapterDisjointRuns))
        ? _formatContiguousRunsCitation(runs)
        : _formatSelectionCitation(firstV, lastV, isSingleVerse: count == 1);

    final textPreview = selectedVerses.map((v) => v.verseText).join(' ');

    return MassReadingSelection(
      readingIdentifier: _readingIdentifier,
      citation: citation,
      selectedCount: count,
      onSaveFavorite: () async {
        for (final run in runs) {
          final runFirst = run.first;
          final runLast = run.last;
          final runPreview = runs.length == 1
              ? textPreview
              : run.map((v) => v.verseText).join(' ');
          final favorite = FavoritePassagesCompanion.insert(
            bookNumber: runFirst.bookNumber,
            bookName: runFirst.bookName,
            chapter: runFirst.chapter,
            startVerse: runFirst.verseNumber,
            endVerse: runLast.verseNumber,
            textPreview: runPreview,
          );
          await BibleDatabaseHelper.db.saveFavorite(favorite);
        }

        await _loadFavorites();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved $citation to Favorites'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _clearSelection();
        }
      },
      onAddComment: () {
        final bookMeta =
            catholicBooksByNumber[widget.reading.bookNumber] ??
            (throw Exception('Book ${widget.reading.bookName} not found'));
        showAddCommentDialog(
          context: context,
          citation: citation,
          textPreview: textPreview,
          documentId: bookMeta.abbrev,
          sectionIndex: firstV.chapter,
          nodeId: ReaderNodeId.bibleVerse(
            firstV.bookNumber,
            firstV.chapter,
            firstV.verseNumber,
          ),
          onCommentSaved: () async {
            _clearSelection();
            await _loadComments();
          },
        );
      },
      onCopy: () async {
        final clipboardContent = BibleReaderAdapter.formatVersesForClipboard(
          citation: citation,
          verses: selectedVerses,
          numberingSystem: _numberingSystem,
          fallbackBookNumber: widget.reading.bookNumber,
        );
        await Clipboard.setData(ClipboardData(text: clipboardContent));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied $citation to clipboard'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _clearSelection();
        }
      },
      onClearSelection: () => _clearSelection(),
    );
  }

  Widget _buildSelectionActionBar(ThemeData theme) {
    // Inline fallback path: Used when MassReadingCard is rendered standalone
    // without an external onSelectionChanged coordinator (e.g. outside MissalTab).
    // In this mode, the ReaderSelectionActionBar is rendered inline at the bottom
    // of the card rather than floated by the parent viewport.
    final selection = _createSelectionData();
    if (selection == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: ReaderSelectionActionBar(
        title: selection.citation,
        selectedCount: selection.selectedCount,
        itemLabel: 'verse',
        onSaveFavorite: selection.onSaveFavorite,
        onCopy: selection.onCopy,
        onAddComment: selection.onAddComment,
        onClearSelection: selection.onClearSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      _readingIcon,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _readingTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.reading.citation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            // Expanded content
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Loading scripture...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Text(
                  'Error loading scripture: $_errorMessage',
                  style: TextStyle(color: theme.colorScheme.error),
                )
              else if (_verses == null || _verses!.isEmpty)
                const Text('No verses found for this reading range.')
              else ...[
                if (widget.reading.readingType.toLowerCase() == 'gospel')
                  MassReadingIntroDialogue(
                    reading: widget.reading,
                    primaryLanguage: widget.primaryLanguage,
                    compareLanguage: widget.compareLanguage,
                    fontSize: widget.fontSize,
                  ),
                if (_isPsalm &&
                    _psalmStanzas != null &&
                    _psalmStanzas!.isNotEmpty)
                  ..._buildPsalmContent()
                else
                  ..._verses!.asMap().entries.map(
                    (entry) => _buildVerseRow(entry.value, entry.key),
                  ),
                if (!_isPsalm)
                  MassReadingConcludingDialogue(
                    reading: widget.reading,
                    primaryLanguage: widget.primaryLanguage,
                    compareLanguage: widget.compareLanguage,
                    fontSize: widget.fontSize,
                  ),
                if (widget.onSelectionChanged == null &&
                    _selectionController.hasSelection)
                  _buildSelectionActionBar(theme),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPsalmContent() {
    final stanzas = _psalmStanzas!;
    final spec = _psalmResponseSpec;
    final responseVerses = _psalmResponseVerses;
    final hasAlleluia = spec?.isAlleluia == true;
    final hasVerseResponse =
        spec != null &&
        !hasAlleluia &&
        responseVerses != null &&
        responseVerses.isNotEmpty;
    final effectiveIsAlleluia =
        hasAlleluia || (!hasVerseResponse && spec?.allowAlleluia == true);
    final hasResponse = effectiveIsAlleluia || hasVerseResponse;
    final responseText = hasVerseResponse
        ? responseVerses.map((v) => v.verseText).join(' ')
        : '';
    final responseCitation = hasVerseResponse
        ? _formatResponseCitation(responseVerses)
        : null;

    final widgets = <Widget>[];
    if (hasResponse) {
      widgets.add(
        MassPsalmResponseBanner(
          responseText: responseText,
          responseCitation: responseCitation,
          isAlleluia: effectiveIsAlleluia,
          showEasterAlleluiaOption:
              !effectiveIsAlleluia && spec?.allowAlleluia == true,
          primaryLanguage: widget.primaryLanguage,
          compareLanguage: widget.compareLanguage,
          fontSize: widget.fontSize,
        ),
      );
    }

    int flatIndex = 0;
    for (int stanzaIdx = 0; stanzaIdx < stanzas.length; stanzaIdx++) {
      final stanza = stanzas[stanzaIdx];
      final isLastStanza = stanzaIdx == stanzas.length - 1;
      for (final verse in stanza) {
        widgets.add(_buildVerseRow(verse, flatIndex));
        flatIndex++;
      }
      if (hasResponse) {
        widgets.add(
          MassPsalmRefrainCue(
            responseText: responseText,
            isAlleluia: effectiveIsAlleluia,
            primaryLanguage: widget.primaryLanguage,
            fontSize: widget.fontSize,
            isLast: isLastStanza,
          ),
        );
      } else if (!isLastStanza) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  Widget _buildVerseRow(BibleVerse verse, int index) {
    final isSelected = _isVerseSelected(index);

    final verseCitations = ReverseCitationService.getVerseCitations(
      verse.bookNumber,
      verse.chapter,
      verse.verseNumber,
    );

    final nodeId = ReaderNodeId.bibleVerse(
      verse.bookNumber,
      verse.chapter,
      verse.verseNumber,
    );
    final verseComments = _commentsByNodeId[nodeId] ?? const [];

    final matchingFavorites = _favoritesByVerseKey[nodeId] ?? const [];
    final isFavorite = matchingFavorites.isNotEmpty;

    final verseDisplay = BibleVerseResolver.formatVerseDisplay(
      bookNumber: verse.bookNumber,
      chapter: verse.chapter,
      verseNumber: verse.verseNumber,
      numberingSystem: _numberingSystem,
    );
    final verseRef = _formatVerseCitation(verse);

    return BibleVerseRow(
      verseNumber: verseDisplay.displayVerseNumber,
      alternateVerseNumber: verseDisplay.alternateVerseNumber,
      verseText: verse.verseText,
      padding: const EdgeInsets.only(
        left: 0.0,
        right: 8.0,
        top: 6.0,
        bottom: 6.0,
      ),
      isSelected: isSelected,
      fontSize: widget.fontSize,
      citationsCount: verseCitations.length,
      commentsCount: verseComments.length,
      isFavorite: isFavorite,
      onTap: () => _onVerseTap(index),
      onLongPress: () => _onVerseLongPress(index),
      onTapCitations: () => showReverseCitationsModal(
        context: context,
        title: verseRef,
        citations: verseCitations,
      ),
      onTapComments: () {
        final bookMeta =
            catholicBooksByNumber[widget.reading.bookNumber] ??
            (throw Exception('Book ${widget.reading.bookName} not found'));
        showVerseCommentsModal(
          context: context,
          title: verseRef,
          nodeId: nodeId,
          textPreview: verse.verseText,
          comments: verseComments,
          onCommentsChanged: _loadComments,
          onAddComment: () => showAddCommentDialog(
            context: context,
            citation: verseRef,
            textPreview: verse.verseText,
            documentId: bookMeta.abbrev,
            sectionIndex: verse.chapter,
            nodeId: nodeId,
            onCommentSaved: _loadComments,
          ),
        );
      },
      onTapFavorite: () => showVerseFavoritesModal(
        context: context,
        title: verseRef,
        favorites: matchingFavorites,
        onFavoritesChanged: _loadFavorites,
      ),
    );
  }
}
