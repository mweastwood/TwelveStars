import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:local_agent/local_agent.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/logic/prayers.dart';

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
                    child: Container(
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
                                  : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
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
          spans.add(
            TextSpan(
              text: token.text,
              recognizer: recognizer,
              style: TextStyle(
                backgroundColor: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.8)
                    : null,
                decoration: isSelected ? null : TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
                decorationColor: theme.colorScheme.primary.withValues(
                  alpha: 0.5,
                ),
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(children: spans),
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 16.0,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          ?amenWidget,
        ],
      );
    }

    // Fallback: plain text
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        ?amenWidget,
      ],
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
                  if (_isDualMode &&
                      _selectedPhraseId != null &&
                      _isAiAvailable)
                    const SizedBox(height: 56),
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
              Positioned(
                bottom: 12,
                right: 12,
                child: FloatingActionButton.small(
                  onPressed: _explainSelectedTranslation,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.auto_awesome, size: 16),
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
      builder: (context) => _TranslationExplainerSheet(
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

class _TranslationExplainerSheet extends StatefulWidget {
  final String originalPhrase;
  final String translatedPhrase;
  final String originalContext;
  final String translatedContext;
  final String originalLang;
  final String translatedLang;

  const _TranslationExplainerSheet({
    required this.originalPhrase,
    required this.translatedPhrase,
    required this.originalContext,
    required this.translatedContext,
    required this.originalLang,
    required this.translatedLang,
  });

  @override
  State<_TranslationExplainerSheet> createState() =>
      __TranslationExplainerSheetState();
}

class __TranslationExplainerSheetState
    extends State<_TranslationExplainerSheet> {
  bool _isLoading = true;
  String? _explanation;
  String? _error;
  AiCoreStatus _status = AiCoreStatus.unavailable;

  @override
  void initState() {
    super.initState();
    _checkStatusAndRun();
  }

  Future<void> _checkStatusAndRun() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = LocalAgentHelper.instance;
      final status = await aiService.checkStatus();
      setState(() {
        _status = status;
      });

      if (status == AiCoreStatus.available) {
        await _runExplanation();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error initializing AI service: $e';
      });
    }
  }

  Future<void> _triggerDownload() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = LocalAgentHelper.instance;
      await aiService.triggerDownload();
      // Poll status for a bit
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final status = await aiService.checkStatus();
        setState(() {
          _status = status;
        });
        if (status == AiCoreStatus.available) {
          await _runExplanation();
          return;
        }
      }
      setState(() {
        _isLoading = false;
        _error =
            'Model download taking longer than expected. Please wait or try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error downloading model: $e';
      });
    }
  }

  Future<void> _runExplanation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prompt =
          '''
Original phrase:
${widget.originalPhrase}

Translated phrase:
${widget.translatedPhrase}

Original phrase in context:
${widget.originalContext}

Translated phrase in context:
${widget.translatedContext}

Define each translated word and how the translated phrase comes to carry the meaning of the original phrase.
''';

      final response = await LocalAgentHelper.instance.generateContent(
        prompt: prompt,
      );

      setState(() {
        _explanation = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error generating explanation: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (_isLoading) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _status == AiCoreStatus.downloading
                    ? 'Downloading Gemini Nano model weights (~30MB)...'
                    : 'Running AI analysis locally...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    } else if (_error != null) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to generate explanation',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkStatusAndRun,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_status == AiCoreStatus.unavailable) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.secondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('AI Core Unavailable', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'On-device AI features (Gemini Nano) are not supported on this device. '
              'Please ensure you are on a compatible Pixel device with AICore enabled.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (_status == AiCoreStatus.downloadable) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.download_for_offline_outlined,
              color: theme.colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('Download AI Model', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'The on-device Gemini Nano model needs to be downloaded before it can explain translations.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _triggerDownload,
              icon: const Icon(Icons.download),
              label: const Text('Download now'),
            ),
          ],
        ),
      );
    } else {
      content = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_explanation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                child: Text(
                  _explanation!,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No explanation generated.'),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Translation Explainer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            '${widget.originalLang} ➜ ${widget.translatedLang}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          // Show comparing phrases nicely
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.originalLang}:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  widget.originalPhrase,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.translatedLang}:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Text(
                  widget.translatedPhrase,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
