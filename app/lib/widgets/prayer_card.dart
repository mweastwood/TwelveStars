import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/translation_explainer_sheet.dart';

class PrayerCard extends StatefulWidget {
  final Prayer prayer;
  final PrayerLanguage selectedLanguage;
  final PrayerLanguage compareLanguage;
  final int initialVersionIndex;
  final ValueChanged<int> onVersionChanged;
  final Function(String) onLaunchSource;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.selectedLanguage,
    required this.compareLanguage,
    required this.initialVersionIndex,
    required this.onVersionChanged,
    required this.onLaunchSource,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  int _currentVersionIndex = 0;
  bool _isDualMode = false;
  String? _selectedPhraseId;
  final LayerLink _layerLink = LayerLink();
  bool _isAiAvailable = false;

  void _checkAiAvailability() async {
    try {
      final status = await LocalAgentHelper.instance.checkStatus();
      if (mounted) {
        setState(() {
          _isAiAvailable = status == AiCoreStatus.available;
        });
      }
    } catch (_) {
      if (mounted) {
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
    if (_isDualMode) {
      final compareTranslations =
          widget.prayer.translations[widget.compareLanguage];
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
    final hasCompare =
        widget.prayer.translations.containsKey(widget.compareLanguage) &&
        widget.prayer.translations[widget.compareLanguage]!.isNotEmpty;
    if (!hasCompare) {
      _isDualMode = false;
    }
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
    final hasCompare =
        widget.prayer.translations.containsKey(widget.compareLanguage) &&
        widget.prayer.translations[widget.compareLanguage]!.isNotEmpty;
    if (!hasCompare) {
      _isDualMode = false;
    }
    _checkAiAvailability();
  }

  Widget _buildPrayerText(
    PrayerTranslation trans,
    PrayerLanguage lang,
    ThemeData theme,
  ) {
    bool renderedTarget = false;
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

    // Chinese Character rendering with Pinyin grid
    if (trans.chineseLines != null) {
      return Column(
        children: [
          ...trans.chineseLines!.map((line) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                runSpacing: 4,
                children: (line.chars ?? []).map((charItem) {
                  final isPunct = charItem.pinyin.isEmpty;
                  final isSelected =
                      charItem.phraseId != null &&
                      charItem.phraseId == _selectedPhraseId;
                  final isCompareLang = lang == widget.compareLanguage;

                  final shouldBeTarget =
                      isSelected && isCompareLang && !renderedTarget;
                  if (shouldBeTarget) {
                    renderedTarget = true;
                  }

                  Widget charWidget = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 1.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.8,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          charItem.char,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPunct ? '' : charItem.pinyin,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.7)
                                : theme.colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldBeTarget) {
                    charWidget = CompositedTransformTarget(
                      link: _layerLink,
                      child: charWidget,
                    );
                  }

                  return GestureDetector(
                    onTap: charItem.phraseId != null
                        ? () {
                            setState(() {
                              if (_selectedPhraseId == charItem.phraseId) {
                                _selectedPhraseId = null;
                              } else {
                                _selectedPhraseId = charItem.phraseId;
                                if (!_isDualMode) {
                                  _isDualMode = true;
                                }
                                _checkAiAvailability();
                              }
                            });
                          }
                        : null,
                    child: charWidget,
                  );
                }).toList(),
              ),
            );
          }),
          ?amenWidget,
        ],
      );
    }

    // Text rendering with phrase alignments
    if (trans.tokens != null && trans.tokens!.isNotEmpty) {
      final List<InlineSpan> spans = [];
      for (final token in trans.tokens!) {
        if (token.id != null) {
          final isSelected = token.id == _selectedPhraseId;
          final isCompareLang = lang == widget.compareLanguage;

          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              setState(() {
                if (_selectedPhraseId == token.id) {
                  _selectedPhraseId = null;
                } else {
                  _selectedPhraseId = token.id;
                  if (!_isDualMode) {
                    _isDualMode = true;
                  }
                  _checkAiAvailability();
                }
              });
            };

          if (isSelected) {
            final shouldBeTarget = isCompareLang && !renderedTarget;
            if (shouldBeTarget) {
              renderedTarget = true;
            }

            Widget tokenWidget = Container(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
              child: Text(
                token.text,
                textScaler: TextScaler.noScaling,
                style: (theme.textTheme.bodyLarge ?? const TextStyle())
                    .copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 16.0,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
              ),
            );

            if (shouldBeTarget) {
              tokenWidget = CompositedTransformTarget(
                link: _layerLink,
                child: tokenWidget,
              );
            }

            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  onTap: recognizer.onTap,
                  child: tokenWidget,
                ),
              ),
            );
          } else {
            spans.add(
              TextSpan(
                text: token.text,
                recognizer: recognizer,
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dashed,
                  decorationColor: theme.colorScheme.primary.withValues(
                    alpha: 0.5,
                  ),
                  color: theme.colorScheme.onSurface,
                ),
              ),
            );
          }
        } else {
          spans.add(
            TextSpan(
              text: token.text,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
              ),
            ),
          );
        }
      }
      final children = <Widget>[
        Text.rich(
          TextSpan(children: spans),
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            fontSize: 16.0,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ];
      if (amenWidget != null) {
        children.add(amenWidget);
      }
      if (trans.copyright.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
            child: Text(
              trans.copyright,
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
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    // Fallback: plain text
    final children = <Widget>[
      Text(
        trans.text,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
          fontSize: 16.0,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      ),
    ];
    if (amenWidget != null) {
      children.add(amenWidget);
    }
    if (trans.copyright.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
          child: Text(
            trans.copyright,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPrimaryTranslation =
        widget.prayer.translations.containsKey(widget.selectedLanguage) &&
        widget.prayer.translations[widget.selectedLanguage]!.isNotEmpty;

    if (!hasPrimaryTranslation) {
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
        widget.prayer.translations.containsKey(widget.compareLanguage) &&
        widget.prayer.translations[widget.compareLanguage]!.isNotEmpty;

    final resolvedCompareLanguage = hasCompareTranslation
        ? widget.compareLanguage
        : resolvedLanguage;
    final compareTranslations =
        widget.prayer.translations[resolvedCompareLanguage]!;
    final compareTranslation =
        compareTranslations[0]; // compare default first version

    final historyTrans = _activeTranslationWithHistory;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (translations.length <= 1) return;
        if (_isDualMode) {
          return; // disable swiping version in dual compare mode to avoid visual clutter
        }

        if (details.primaryVelocity! < 0) {
          // Swiped left -> next version
          final newIndex = (_currentVersionIndex + 1) % translations.length;
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
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Row: Titles/Subtitles spanning full width
                  _isDualMode
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column Title/Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    translation.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (translation.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      translation.subtitle,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 32,
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 12),
                            // Right Column Title/Subtitle with padding to avoid overlaying split button
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 36),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      compareTranslation.title,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                    if (compareTranslation
                                        .subtitle
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        compareTranslation.subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translation.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (translation.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  translation.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildPrayerText(translation, resolvedLanguage, theme),
                  const SizedBox(height: 20),

                  // Divider for Footer
                  Divider(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                    height: 1,
                  ),
                  const SizedBox(height: 12),

                  // 3. Source Row: Source Buttons
                  if (_isDualMode)
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: _buildSourceButton(translation, theme),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 1,
                        ), // spacer matching vertical divider
                        const SizedBox(width: 12),
                        Expanded(
                          child: Center(
                            child: _buildSourceButton(
                              compareTranslation,
                              theme,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: _buildSourceButton(translation, theme)),
                      ],
                    ),
                  ],

                  // 4. Historical Context Row: Rendered below Source
                  if (historyTrans != null) ...[
                    const SizedBox(height: 12),
                    _buildHistoryPanel(
                      historyTrans.historyOrigin,
                      historyTrans.historyDescription,
                      theme,
                    ),
                  ],

                  // 5. Version indicator dots
                  if (translations.length > 1 && !_isDualMode) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(translations.length, (index) {
                        final isSelected = index == versionIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant.withValues(
                                    alpha: 0.8,
                                  ),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
            if (hasCompareTranslation)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: RotatedBox(
                    quarterTurns: 1,
                    child: Icon(
                      _isDualMode
                          ? Icons.splitscreen
                          : Icons.splitscreen_outlined,
                      color: _isDualMode
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Compare Translations',
                  onPressed: () {
                    setState(() {
                      _isDualMode = !_isDualMode;
                      _selectedPhraseId = null;
                    });
                  },
                ),
              ),
            if (_isDualMode && _selectedPhraseId != null && _isAiAvailable)
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.bottomLeft,
                offset: const Offset(4, -4),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: FloatingActionButton.small(
                    onPressed: _explainSelectedTranslation,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.auto_awesome, size: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton(PrayerTranslation translation, ThemeData theme) {
    if (translation.sourceUrl.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () => widget.onLaunchSource(translation.sourceUrl),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Source: ${translation.sourceName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary.withValues(
                    alpha: 0.5,
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 12,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel(
    String origin,
    String description,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.history_edu, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'HISTORICAL CONTEXT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Origin: $origin',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  String _getPhraseText(PrayerTranslation trans, String phraseId) {
    if (trans.tokens == null) return '';
    return trans.tokens!
        .where((t) => t.id == phraseId)
        .map((t) => t.text)
        .join('')
        .trim();
  }

  void _explainSelectedTranslation() {
    final phraseId = _selectedPhraseId;
    if (phraseId == null) return;

    final resolvedLanguage = widget.selectedLanguage;
    final hasCompareTranslation =
        widget.prayer.translations.containsKey(widget.compareLanguage) &&
        widget.prayer.translations[widget.compareLanguage]!.isNotEmpty;
    final resolvedCompareLanguage = hasCompareTranslation
        ? widget.compareLanguage
        : resolvedLanguage;

    final translations = widget.prayer.translations[resolvedLanguage]!;
    final versionIndex = _currentVersionIndex < translations.length
        ? _currentVersionIndex
        : 0;
    final translation = translations[versionIndex];

    final compareTranslations =
        widget.prayer.translations[resolvedCompareLanguage]!;
    final compareTranslation = compareTranslations[0];

    final originalPhrase = _getPhraseText(compareTranslation, phraseId);
    final translatedPhrase = _getPhraseText(translation, phraseId);

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
