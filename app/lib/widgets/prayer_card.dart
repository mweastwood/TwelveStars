import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/prayer_text_parser.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/prayers/prayer_card_components.dart';
import 'package:twelve_stars/widgets/prayers/prayer_history_sheet.dart';
import 'package:twelve_stars/widgets/prayers/prayer_pinyin_view.dart';
import 'package:twelve_stars/widgets/prayers/prayer_rich_text_span_builder.dart';
import 'package:twelve_stars/widgets/translation_explainer_sheet.dart';

class PrayerCard extends StatefulWidget {
  final Prayer prayer;
  final PrayerLanguage selectedLanguage;
  final PrayerLanguage? compareLanguage;
  final int initialVersionIndex;
  final ValueChanged<int> onVersionChanged;
  final double fontSize;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.selectedLanguage,
    this.compareLanguage,
    required this.initialVersionIndex,
    required this.onVersionChanged,
    this.fontSize = 16.0,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  int _currentVersionIndex = 0;
  String? _selectedPhraseId;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _targetKey = GlobalKey();
  double _followerDx = 12.0;
  bool _isAiAvailable = false;
  final Map<String, TapGestureRecognizer> _recognizers = {};
  final Set<String> _activeRecognizerKeys = {};

  void _scheduleUpdateFollowerOffset() {
    if (!_isDualMode || _selectedPhraseId == null) {
      _followerDx = 12.0;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isDualMode || _selectedPhraseId == null) return;
      final stackBox =
          _stackKey.currentContext?.findRenderObject() as RenderBox?;
      final targetBox =
          _targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (stackBox == null ||
          targetBox == null ||
          !stackBox.hasSize ||
          !targetBox.hasSize) {
        return;
      }
      final targetRight = targetBox
          .localToGlobal(Offset(targetBox.size.width, 0), ancestor: stackBox)
          .dx;
      final clampedDx = math.min(
        12.0,
        stackBox.size.width - 4.0 - 28.0 - targetRight,
      );
      if ((clampedDx - _followerDx).abs() > 0.5) {
        setState(() {
          _followerDx = clampedDx;
        });
      }
    });
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  void _pruneUnusedRecognizers() {
    _recognizers.removeWhere((key, recognizer) {
      if (!_activeRecognizerKeys.contains(key)) {
        recognizer.dispose();
        return true;
      }
      return false;
    });
  }

  bool get _isDualMode =>
      widget.compareLanguage != null &&
      widget.prayer.translations.containsKey(widget.compareLanguage) &&
      widget.prayer.translations[widget.compareLanguage]!.isNotEmpty;

  void _checkAiAvailability() async {
    if (!_isDualMode || _selectedPhraseId == null) {
      return;
    }
    try {
      final status = await LocalAgentHelper.instance.checkStatus();
      if (mounted) {
        final available = status == AiCoreStatus.available;
        if (_isAiAvailable != available) {
          setState(() {
            _isAiAvailable = available;
          });
        }
      }
    } catch (_) {
      if (mounted && _isAiAvailable) {
        setState(() {
          _isAiAvailable = false;
        });
      }
    }
  }

  PrayerTranslation? get _activeTranslationWithHistory {
    // 1. Try selected translation
    final selectedTranslations =
        widget.prayer.translations[widget.selectedLanguage];
    if (selectedTranslations != null &&
        _currentVersionIndex < selectedTranslations.length) {
      final selectedTrans = selectedTranslations[_currentVersionIndex];
      if (selectedTrans.historyDescription.isNotEmpty) return selectedTrans;
    }

    // 2. Try compare translation
    if (_isDualMode && widget.compareLanguage != null) {
      final compareTranslations =
          widget.prayer.translations[widget.compareLanguage!];
      if (compareTranslations != null && compareTranslations.isNotEmpty) {
        final compareTrans = compareTranslations[0];
        if (compareTrans.historyDescription.isNotEmpty) return compareTrans;
      }
    }

    // 3. Fall back to English translation
    final englishTranslations =
        widget.prayer.translations[PrayerLanguage.english];
    if (englishTranslations != null && englishTranslations.isNotEmpty) {
      final englishTrans = englishTranslations[0];
      if (englishTrans.historyDescription.isNotEmpty) return englishTrans;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _currentVersionIndex = widget.initialVersionIndex;
    _checkAiAvailability();
  }

  @override
  void didUpdateWidget(covariant PrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialVersionIndex != widget.initialVersionIndex) {
      _currentVersionIndex = widget.initialVersionIndex;
    } else if (oldWidget.selectedLanguage != widget.selectedLanguage ||
        oldWidget.prayer.prayerId != widget.prayer.prayerId) {
      _currentVersionIndex = widget.initialVersionIndex;
    }
    if (oldWidget.prayer != widget.prayer ||
        oldWidget.prayer.prayerId != widget.prayer.prayerId ||
        oldWidget.selectedLanguage != widget.selectedLanguage ||
        oldWidget.compareLanguage != widget.compareLanguage) {
      _selectedPhraseId = null;
      _followerDx = 12.0;
    }
    _checkAiAvailability();
    _scheduleUpdateFollowerOffset();
  }

  void _onPhraseSelected(String? phraseId) {
    setState(() {
      _selectedPhraseId = phraseId;
      _followerDx = 12.0;
      if (phraseId != null) {
        _checkAiAvailability();
        _scheduleUpdateFollowerOffset();
      }
    });
  }

  Widget _wrapWithFooter(
    Widget body,
    Widget? amenWidget,
    String copyright,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        ?amenWidget,
        if (copyright.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
            child: Text(
              copyright,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildPrayerText(
    PrayerTranslation trans,
    PrayerLanguage lang,
    ThemeData theme, {
    bool isTargetColumn = false,
  }) {
    final Widget? amenWidget = widget.prayer.hasAmen
        ? Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lang.amenText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          )
        : null;

    Widget bodyWidget;

    // Chinese Character rendering with Pinyin grid
    if (trans.chineseLines != null) {
      bodyWidget = PrayerPinyinView(
        chineseLines: trans.chineseLines!,
        selectedPhraseId: _selectedPhraseId,
        isDualMode: _isDualMode,
        isTargetColumn: isTargetColumn,
        fontSize: widget.fontSize,
        layerLink: _layerLink,
        targetKey: isTargetColumn ? _targetKey : null,
        onPhraseSelected: _onPhraseSelected,
      );
    } else {
      final spanBuilder = PrayerRichTextSpanBuilder(
        theme: theme,
        fontSize: widget.fontSize,
        isDualMode: _isDualMode,
        selectedPhraseId: _selectedPhraseId,
        layerLink: _layerLink,
        targetKey: isTargetColumn ? _targetKey : null,
        recognizers: _recognizers,
        activeRecognizerKeys: _activeRecognizerKeys,
        onPhraseSelected: _onPhraseSelected,
      );

      if (trans.tokens != null && trans.tokens!.isNotEmpty) {
        final spans = spanBuilder.buildTokenizedSpans(
          trans.tokens!,
          isTargetColumn: isTargetColumn,
        );
        bodyWidget = Text.rich(
          TextSpan(children: spans),
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            fontSize: widget.fontSize,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        );
      } else {
        final spans = spanBuilder.buildPlainTextSpans(trans.text);
        bodyWidget = Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.center,
        );
      }
    }

    return _wrapWithFooter(bodyWidget, amenWidget, trans.copyright, theme);
  }

  @override
  Widget build(BuildContext context) {
    _activeRecognizerKeys.clear();

    final hasPrimaryTranslation =
        widget.prayer.translations.containsKey(widget.selectedLanguage) &&
        widget.prayer.translations[widget.selectedLanguage]!.isNotEmpty;

    if (!hasPrimaryTranslation) {
      _pruneUnusedRecognizers();
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final resolvedLanguage = widget.selectedLanguage;

    final translations = widget.prayer.translations[resolvedLanguage]!;
    final versionIndex = _currentVersionIndex < translations.length
        ? _currentVersionIndex
        : 0;
    final translation = translations[versionIndex];

    // Dual mode compare language resolution
    final hasCompareTranslation =
        widget.compareLanguage != null &&
        widget.prayer.translations.containsKey(widget.compareLanguage) &&
        widget.prayer.translations[widget.compareLanguage]!.isNotEmpty;

    final resolvedCompareLanguage = hasCompareTranslation
        ? widget.compareLanguage!
        : resolvedLanguage;
    final compareTranslations =
        widget.prayer.translations[resolvedCompareLanguage]!;
    final compareTranslation =
        compareTranslations[0]; // compare default first version

    final historyTrans = _activeTranslationWithHistory;

    final card = GestureDetector(
      onHorizontalDragEnd: (translations.length > 1 && !_isDualMode)
          ? (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < 0) {
                // Swiped left -> next version
                final newIndex =
                    (_currentVersionIndex + 1) % translations.length;
                setState(() {
                  _currentVersionIndex = newIndex;
                });
                widget.onVersionChanged(newIndex);
              } else if (details.primaryVelocity! > 0) {
                // Swiped right -> previous version
                final newIndex =
                    (_currentVersionIndex - 1 + translations.length) %
                    translations.length;
                setState(() {
                  _currentVersionIndex = newIndex;
                });
                widget.onVersionChanged(newIndex);
              }
            }
          : null,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.none,
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Row: Titles/Subtitles spanning full width
                  PrayerVersionHeader(
                    primaryTitle: translation.title,
                    primarySubtitle: translation.subtitle,
                    isDualMode: _isDualMode,
                    compareTitle: compareTranslation.title,
                    compareSubtitle: compareTranslation.subtitle,
                  ),
                  const SizedBox(height: 12),

                  // Divider
                  Divider(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // 2. Content Row: Prayer 1 | Prayer 2 (conditional)
                  if (_isDualMode)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildPrayerText(
                              translation,
                              resolvedLanguage,
                              theme,
                              isTargetColumn: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPrayerText(
                              compareTranslation,
                              resolvedCompareLanguage,
                              theme,
                              isTargetColumn: true,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildPrayerText(
                      translation,
                      resolvedLanguage,
                      theme,
                      isTargetColumn: true,
                    ),
                  // Footer Divider & Sections (only rendered if history or version dots exist)
                  if (historyTrans != null ||
                      (translations.length > 1 && !_isDualMode)) ...[
                    const SizedBox(height: 20),
                    Divider(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                      height: 1,
                    ),
                  ],

                  // 3. Historical Context Row
                  if (historyTrans != null) ...[
                    const SizedBox(height: 12),
                    PrayerHistoryPanel(
                      origin: historyTrans.historyOrigin,
                      description: historyTrans.historyDescription,
                    ),
                  ],

                  // 4. Version indicator dots
                  if (translations.length > 1 && !_isDualMode) ...[
                    const SizedBox(height: 16),
                    PrayerVersionDots(
                      versionCount: translations.length,
                      currentIndex: versionIndex,
                    ),
                  ],
                ],
              ),
            ),
            if (_isDualMode && _selectedPhraseId != null && _isAiAvailable)
              PrayerFloatingExplainButton(
                layerLink: _layerLink,
                followerDx: _followerDx,
                onPressed: _explainSelectedTranslation,
              ),
          ],
        ),
      ),
    );

    _pruneUnusedRecognizers();
    return card;
  }

  void _explainSelectedTranslation() {
    final phraseId = _selectedPhraseId;
    if (phraseId == null) return;

    final resolvedLanguage = widget.selectedLanguage;
    final hasCompareTranslation =
        widget.compareLanguage != null &&
        widget.prayer.translations.containsKey(widget.compareLanguage!) &&
        widget.prayer.translations[widget.compareLanguage!]!.isNotEmpty;
    final resolvedCompareLanguage = hasCompareTranslation
        ? widget.compareLanguage!
        : resolvedLanguage;

    final translations = widget.prayer.translations[resolvedLanguage]!;
    final versionIndex = _currentVersionIndex < translations.length
        ? _currentVersionIndex
        : 0;
    final translation = translations[versionIndex];

    final compareTranslations =
        widget.prayer.translations[resolvedCompareLanguage]!;
    final compareTranslation = compareTranslations[0];

    final originalPhrase = PrayerTextParser.extractPhraseText(
      compareTranslation,
      phraseId,
    );
    final translatedPhrase = PrayerTextParser.extractPhraseText(
      translation,
      phraseId,
    );

    final originalContext = compareTranslation.text;
    final translatedContext = translation.text;

    final originalLangName = resolvedCompareLanguage.name;
    final translatedLangName = resolvedLanguage.name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TranslationExplainerSheet(
        originalPhrase: originalPhrase,
        translatedPhrase: translatedPhrase,
        originalContext: originalContext,
        translatedContext: translatedContext,
        originalLang: originalLangName,
        translatedLang: translatedLangName,
      ),
    );
  }
}
