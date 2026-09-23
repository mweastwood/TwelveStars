import 'dart:math';
import 'package:twelve_stars/logic/saint_models.dart';
import 'discernment_models.dart';
import 'discernment_question_bank.dart' as qb;
import 'tournament_state_machine.dart';

/// Core logic engine for the 32-question bank, stratified down-selection,
/// vector matching, and bracket generation.
class ConfirmationDiscernmentEngine {
  /// Optional mock questions list for deterministic testing.
  static List<DiscernmentQuestion>? mockQuestions;

  /// Optional mock Random generator for deterministic testing.
  static Random? mockRandom;

  /// The curated bank of 32 discernment questions spanning all 6 axes and cross-cutting gifts.
  static const List<DiscernmentQuestion> questionBank = qb.questionBank;

  /// Down-selects a stratified set of questions from the bank (guaranteeing coverage across all 6 axes).
  static List<DiscernmentQuestion> selectQuestions({
    int count = 14,
    Random? random,
  }) {
    if (mockQuestions != null) {
      return List<DiscernmentQuestion>.from(mockQuestions!);
    }
    final rng = random ?? mockRandom ?? Random();

    // 1. Group questions by primary axis
    final Map<DiscernmentAxis, List<DiscernmentQuestion>> axisGroups = {};
    final List<DiscernmentQuestion> crossCutting = [];

    for (final q in questionBank) {
      if (q.primaryAxis != null) {
        axisGroups.putIfAbsent(q.primaryAxis!, () => []).add(q);
      } else {
        crossCutting.add(q);
      }
    }

    final List<DiscernmentQuestion> selected = [];

    // 2. Determine questions per axis (e.g. 2 per axis when count >= 12)
    final int perAxis = (count >= 12) ? (count ~/ 6).clamp(1, 5) : 1;

    for (final axis in DiscernmentAxis.values) {
      if (selected.length >= count) break;
      final list = axisGroups[axis];
      if (list != null && list.isNotEmpty) {
        final shuffledAxis = List<DiscernmentQuestion>.from(list)..shuffle(rng);
        for (final q in shuffledAxis) {
          if (selected.where((item) => item.primaryAxis == axis).length >=
              perAxis) {
            break;
          }
          if (selected.length >= count) break;
          selected.add(q);
        }
      }
    }

    // 3. Pick remaining questions from cross-cutting
    if (crossCutting.isNotEmpty && selected.length < count) {
      final shuffledCross = List<DiscernmentQuestion>.from(crossCutting)
        ..shuffle(rng);
      for (final q in shuffledCross) {
        if (selected.length >= count) break;
        selected.add(q);
      }
    }

    // 4. Backfill from remaining unselected questions in bank if count is not yet reached
    if (selected.length < count) {
      final unselected =
          questionBank.where((q) => !selected.contains(q)).toList()
            ..shuffle(rng);
      for (final q in unselected) {
        if (selected.length >= count) break;
        selected.add(q);
      }
    }

    // Shuffle question order so the quiz flow feels natural and varied
    selected.shuffle(rng);
    return selected;
  }

  /// Calculates the user's normalized 6D preference vector from question answers.
  static List<double> calculateUserVector(
    Map<String, int> selectedOptionIndices,
    List<DiscernmentQuestion> activeQuestions,
  ) {
    final Map<DiscernmentAxis, double> sumWeights = {
      for (final axis in DiscernmentAxis.values) axis: 0.0,
    };
    final Map<DiscernmentAxis, int> countWeights = {
      for (final axis in DiscernmentAxis.values) axis: 0,
    };

    for (final q in activeQuestions) {
      final optionIdx = selectedOptionIndices[q.id];
      if (optionIdx != null && optionIdx >= 0 && optionIdx < q.options.length) {
        final option = q.options[optionIdx];
        for (final entry in option.weights.entries) {
          sumWeights[entry.key] = (sumWeights[entry.key] ?? 0.0) + entry.value;
          countWeights[entry.key] = (countWeights[entry.key] ?? 0) + 1;
        }
      }
    }

    // Average the weights per axis and clamp to [-1.0, 1.0]
    return [
      _clampAverage(
        sumWeights[DiscernmentAxis.contemplativeVsActive],
        countWeights[DiscernmentAxis.contemplativeVsActive],
      ),
      _clampAverage(
        sumWeights[DiscernmentAxis.intellectualVsDevotional],
        countWeights[DiscernmentAxis.intellectualVsDevotional],
      ),
      _clampAverage(
        sumWeights[DiscernmentAxis.courageVsMercy],
        countWeights[DiscernmentAxis.courageVsMercy],
      ),
      _clampAverage(
        sumWeights[DiscernmentAxis.ancientVsModern],
        countWeights[DiscernmentAxis.ancientVsModern],
      ),
      _clampAverage(
        sumWeights[DiscernmentAxis.simplicityVsLeadership],
        countWeights[DiscernmentAxis.simplicityVsLeadership],
      ),
      _clampAverage(
        sumWeights[DiscernmentAxis.pioneeringVsPreservation],
        countWeights[DiscernmentAxis.pioneeringVsPreservation],
      ),
    ];
  }

  static double _clampAverage(double? sum, int? count) {
    if (sum == null || count == null || count == 0) return 0.0;
    return (sum / count).clamp(-1.0, 1.0);
  }

  /// Calculates similarity against all saints, adds reachability noise, and seeds the Top 16 candidates.
  static List<TournamentSeed> generateTournamentSeeds({
    required List<Saint> allSaints,
    required List<double> userVector,
    double noiseMagnitude = 0.08,
    Random? random,
    int count = 16,
  }) {
    final rng = random ?? mockRandom ?? Random();

    if (allSaints.isEmpty) {
      return [];
    }

    // Calculate score for each saint
    final List<MapEntry<Saint, double>> scored = [];
    for (final saint in allSaints) {
      final embedding = saint.embedding ?? const SaintEmbedding();
      final score = embedding.similarityWith(
        userVector,
        noiseMagnitude: noiseMagnitude,
        random: rng,
      );
      scored.add(MapEntry(saint, score));
    }

    // Sort descending by match score
    scored.sort((a, b) => b.value.compareTo(a.value));

    // Extract top `count`, cycling candidates if candidate count is below `count`
    final List<MapEntry<Saint, double>> topEntries = [];
    while (topEntries.length < count) {
      for (final entry in scored) {
        if (topEntries.length >= count) break;
        topEntries.add(entry);
      }
    }

    // Map into tournament seeds
    final List<TournamentSeed> seeds = [];
    for (int i = 0; i < topEntries.length; i++) {
      final saint = topEntries[i].key;
      final rawScore = topEntries[i].value;
      // Normalize score into [0.5, 0.99] for user presentation
      final displayScore = ((rawScore + 1.0) / 2.0 * 0.5 + 0.49).clamp(
        0.50,
        0.99,
      );

      seeds.add(
        TournamentSeed(
          seed: i + 1,
          saint: saint,
          matchScore: displayScore,
          primaryHighlight: _determineHighlight(saint, userVector),
        ),
      );
    }

    return seeds;
  }

  static String _determineHighlight(Saint saint, List<double> userVector) {
    if (saint.isDoctor) {
      return 'Doctor of the Church • Deep Theological Wisdom';
    }
    if (saint.categories.contains(SaintCategory.martyr)) {
      return 'Courageous Martyr • Unwavering Fortitude';
    }
    if (saint.categories.contains(SaintCategory.healerMissionary)) {
      return 'Healer & Missionary • Radiant Christian Charity';
    }
    if (saint.categories.contains(SaintCategory.mystic)) {
      return 'Mystic & Contemplative • Intimate Union with God';
    }
    if (saint.categories.contains(SaintCategory.apostle)) {
      return 'Apostle of Christ • Foundational Pillar of Faith';
    }
    if (saint.patronage != null && saint.patronage!.isNotEmpty) {
      return 'Patron of ${saint.patronage}';
    }
    return saint.profession;
  }

  /// Builds a canonical 16-entrant single-elimination tournament bracket.
  static TournamentState createTournament(List<TournamentSeed> seeds) {
    if (seeds.length < 16) {
      throw ArgumentError('At least 16 seeds are required for tournament');
    }

    // Canonical NCAA / Grand Slam 16-seed pairings:
    // Match 1: 1 vs 16
    // Match 2: 8 vs 9
    // Match 3: 4 vs 13
    // Match 4: 5 vs 12
    // Match 5: 2 vs 15
    // Match 6: 7 vs 10
    // Match 7: 3 vs 14
    // Match 8: 6 vs 11
    final canonicalPairings = [
      [1, 16],
      [8, 9],
      [4, 13],
      [5, 12],
      [2, 15],
      [7, 10],
      [3, 14],
      [6, 11],
    ];

    final Map<int, TournamentSeed> seedMap = {for (final s in seeds) s.seed: s};

    // Round 0 (Round of 16): 8 matches
    final List<TournamentMatch> round0 = [];
    for (int i = 0; i < canonicalPairings.length; i++) {
      final pair = canonicalPairings[i];
      round0.add(
        TournamentMatch(
          round: 0,
          matchIndex: i,
          entrant1: seedMap[pair[0]],
          entrant2: seedMap[pair[1]],
        ),
      );
    }

    // Round 1 (Quarterfinals): 4 matches (entrants filled as round 0 completes)
    final List<TournamentMatch> round1 = List.generate(
      4,
      (i) => TournamentMatch(round: 1, matchIndex: i),
    );

    // Round 2 (Semifinals): 2 matches
    final List<TournamentMatch> round2 = List.generate(
      2,
      (i) => TournamentMatch(round: 2, matchIndex: i),
    );

    // Round 3 (Championship): 1 match
    final List<TournamentMatch> round3 = [
      TournamentMatch(round: 3, matchIndex: 0),
    ];

    return TournamentState(
      initialSeeds: seeds,
      rounds: [round0, round1, round2, round3],
    );
  }
}
