import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';
import 'package:twelve_stars/widgets/confirmation_bracket_view.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

enum DiscernmentStage { quiz, tournament, champion }

/// Interactive Confirmation Saint Discernment screen featuring a dynamic quiz,
/// vector-similarity seeding, and a 16-entrant head-to-head tournament bracket.
class ConfirmationDiscernmentScreen extends StatefulWidget {
  const ConfirmationDiscernmentScreen({super.key});

  @override
  State<ConfirmationDiscernmentScreen> createState() =>
      _ConfirmationDiscernmentScreenState();
}

class _ConfirmationDiscernmentScreenState
    extends State<ConfirmationDiscernmentScreen> {
  List<Saint> _allSaints = [];
  bool _loading = true;
  String? _error;

  DiscernmentStage _stage = DiscernmentStage.quiz;
  List<DiscernmentQuestion> _activeQuestions = [];
  int _currentQuestionIndex = 0;
  final Map<String, int> _selectedAnswers = {};

  TournamentState? _tournament;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final saints = await SaintDatabase.loadSaints();
      final questions = ConfirmationDiscernmentEngine.selectQuestions(count: 7);
      if (mounted) {
        setState(() {
          _allSaints = saints;
          _activeQuestions = questions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _restartDiscernment() {
    setState(() {
      _stage = DiscernmentStage.quiz;
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _activeQuestions = ConfirmationDiscernmentEngine.selectQuestions(
        count: 7,
      );
      _tournament = null;
    });
  }

  void _startTournament() {
    if (_allSaints.isEmpty) return;

    final userVector = ConfirmationDiscernmentEngine.calculateUserVector(
      _selectedAnswers,
      _activeQuestions,
    );

    final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
      allSaints: _allSaints,
      userVector: userVector,
      noiseMagnitude: 0.08,
    );

    final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

    setState(() {
      _tournament = tournament;
      _stage = DiscernmentStage.tournament;
    });
  }

  void _selectWinner(TournamentSeed winner) {
    if (_tournament == null) return;

    setState(() {
      _tournament!.recordWinner(winner);
      if (_tournament!.isComplete) {
        _stage = DiscernmentStage.champion;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmation Discernment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmation Discernment')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    switch (_stage) {
      case DiscernmentStage.quiz:
        return _buildQuizStage(context, theme);
      case DiscernmentStage.tournament:
        return _buildTournamentStage(context, theme);
      case DiscernmentStage.champion:
        return _buildChampionStage(context, theme);
    }
  }

  // ==========================================
  // STAGE 1: DISCERNMENT QUIZ
  // ==========================================
  Widget _buildQuizStage(BuildContext context, ThemeData theme) {
    final currentQ = _activeQuestions[_currentQuestionIndex];
    final selectedOption = _selectedAnswers[currentQ.id];
    final isLastQuestion = _currentQuestionIndex == _activeQuestions.length - 1;
    final canProceed = selectedOption != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation Discernment'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Restart'),
            onPressed: _restartDiscernment,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _activeQuestions.length,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
              minHeight: 6,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUESTION ${_currentQuestionIndex + 1} OF ${_activeQuestions.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (currentQ.primaryAxis != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentQ.primaryAxis!.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Question Card & Options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      currentQ.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (int i = 0; i < currentQ.options.length; i++)
                      _buildOptionTile(
                        context,
                        option: currentQ.options[i],
                        index: i,
                        isSelected: selectedOption == i,
                        onTap: () {
                          setState(() {
                            _selectedAnswers[currentQ.id] = i;
                          });
                        },
                        theme: theme,
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    key: const Key('discernment_next_button'),
                    icon: Icon(
                      isLastQuestion ? Icons.emoji_events : Icons.arrow_forward,
                    ),
                    label: Text(
                      isLastQuestion ? 'Start Tournament' : 'Next Question',
                    ),
                    onPressed: canProceed
                        ? () {
                            if (isLastQuestion) {
                              _startTournament();
                            } else {
                              setState(() {
                                _currentQuestionIndex++;
                              });
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required DiscernmentOption option,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        key: Key('discernment_option_$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (option.icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    option.icon,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STAGE 2: TOURNAMENT ARENA (H2H BRACKET)
  // ==========================================
  Widget _buildTournamentStage(BuildContext context, ThemeData theme) {
    if (_tournament == null) return const SizedBox.shrink();
    final match = _tournament!.currentMatch;
    if (match == null || !match.isReady) return const SizedBox.shrink();

    final matchNum = _tournament!.completedMatchCount + 1;
    final totalMatches = _tournament!.totalMatches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saint Showdown'),
        actions: [
          IconButton(
            key: const Key('view_bracket_button'),
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'View Bracket Tree',
            onPressed: () =>
                ConfirmationBracketView.show(context, _tournament!),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header progress
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MATCH $matchNum OF $totalMatches • ${match.roundName.toUpperCase()}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.account_tree, size: 14),
                    label: const Text('Bracket'),
                    onPressed: () =>
                        ConfirmationBracketView.show(context, _tournament!),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Arena Matchup Cards
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  if (isWide) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildMatchupCard(
                              context,
                              seed: match.entrant1!,
                              onSelect: () => _selectWinner(match.entrant1!),
                              theme: theme,
                              keyPrefix: 'entrant_1',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.amber,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'VS',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildMatchupCard(
                              context,
                              seed: match.entrant2!,
                              onSelect: () => _selectWinner(match.entrant2!),
                              theme: theme,
                              keyPrefix: 'entrant_2',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Mobile layout (Stacked)
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildMatchupCard(
                          context,
                          seed: match.entrant1!,
                          onSelect: () => _selectWinner(match.entrant1!),
                          theme: theme,
                          keyPrefix: 'entrant_1',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.amber,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'VS',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ),
                        _buildMatchupCard(
                          context,
                          seed: match.entrant2!,
                          onSelect: () => _selectWinner(match.entrant2!),
                          theme: theme,
                          keyPrefix: 'entrant_2',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchupCard(
    BuildContext context, {
    required TournamentSeed seed,
    required VoidCallback onSelect,
    required ThemeData theme,
    required String keyPrefix,
  }) {
    final saint = seed.saint;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top badges (Seed + Match %)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SEED #${seed.seed}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${seed.matchPercentage}% Match',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Icon + Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: saint.categoryColor(theme).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: saint.categoryColor(theme).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    saint.categoryIcon,
                    color: saint.categoryColor(theme),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        saint.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (saint.dateRange.isNotEmpty)
                        Text(
                          saint.dateRange,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Profession & Patronage
            Text(
              saint.profession,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (saint.patronage != null && saint.patronage!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Patron of ${saint.patronage}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Summary excerpt
            if (saint.summary != null) ...[
              if (isWideScreen(context))
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      saint.summary!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  saint.summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
            ],
            const SizedBox(height: 12),

            // Actions: Read Full Bio & Choose Saint
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => SaintDetailsSheet.show(context, saint),
                  child: const Text('Read Bio'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: Key('${keyPrefix}_select_button'),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      'Choose ${saint.shortName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: onSelect,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STAGE 3: CHAMPION CROWNING & CONFIRMATION DOSSIER
  // ==========================================
  Widget _buildChampionStage(BuildContext context, ThemeData theme) {
    final champion = _tournament?.champion;
    if (champion == null) return const SizedBox.shrink();
    final saint = champion.saint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation Patron Chosen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Start New Discernment',
            onPressed: _restartDiscernment,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Celebration Trophy Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade100.withValues(alpha: 0.8),
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade600, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 56,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'YOUR CONFIRMATION PATRON SAINT',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      saint.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (saint.dateRange.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        saint.dateRange,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${champion.matchPercentage}% Compatibility Match',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Patron Details Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patronage & Significance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vocation: ${saint.profession}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (saint.feastDay != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Feast Day: ${saint.feastDay}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (saint.patronage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Patron Saint of: ${saint.patronage}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (saint.summary != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Biography Summary',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          saint.summary!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Patron Saint Prayer for Confirmation
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_stories,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Confirmation Intercessory Prayer',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final invocationName = saint.invocationName;
                        return Text(
                          '$invocationName, you lived a life of extraordinary holiness, faith, and love for Jesus Christ. As I prepare for the Sacrament of Confirmation, I choose you as my patron and intercessor before the throne of God. Pray for me that the gifts of the Holy Spirit may be stirred into flame in my life, that I may witness to the Gospel with courage and truth. Amen.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              FilledButton.icon(
                key: const Key('copy_dossier_button'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Confirmation Saint Dossier'),
                onPressed: () {
                  final invocationName = saint.invocationName;
                  final dossier =
                      '''
CONFIRMATION SAINT DOSSIER
===========================
Patron Saint: ${saint.name}
Dates: ${saint.dateRange}
Feast Day: ${saint.feastDay ?? 'N/A'}
Patronage: ${saint.patronage ?? 'N/A'}
Vocation: ${saint.profession}

BIOGRAPHY & SIGNIFICANCE:
${saint.summary ?? ''}

CONFIRMATION PRAYER:
$invocationName, pray for me as I receive the gifts of the Holy Spirit in Confirmation, that I may follow Christ faithfully all the days of my life. Amen.
''';
                  Clipboard.setData(ClipboardData(text: dossier));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Confirmation dossier copied to clipboard!',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.account_tree),
                label: const Text('View Full Tournament Bracket Recap'),
                onPressed: () =>
                    ConfirmationBracketView.show(context, _tournament!),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Discern Again (New Quiz & Tournament)'),
                onPressed: _restartDiscernment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
