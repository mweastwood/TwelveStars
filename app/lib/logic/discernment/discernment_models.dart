import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/saint_models.dart';

/// The 6 core spiritual dimensions used for confirmation discernment vectors.
enum DiscernmentAxis {
  contemplativeVsActive,
  intellectualVsDevotional,
  courageVsMercy,
  ancientVsModern,
  simplicityVsLeadership,
  pioneeringVsPreservation;

  String get label {
    switch (this) {
      case DiscernmentAxis.contemplativeVsActive:
        return 'Contemplation vs. Active Mission';
      case DiscernmentAxis.intellectualVsDevotional:
        return 'Intellect & Doctrine vs. Heart & Devotion';
      case DiscernmentAxis.courageVsMercy:
        return 'Courage & Fortitude vs. Gentleness & Mercy';
      case DiscernmentAxis.ancientVsModern:
        return 'Ancient & Apostolic vs. Modern & Relatable';
      case DiscernmentAxis.simplicityVsLeadership:
        return 'Simplicity & Poverty vs. Leadership & Governance';
      case DiscernmentAxis.pioneeringVsPreservation:
        return 'Pioneering & Innovation vs. Tradition & Preservation';
    }
  }
}

/// An option for a discernment question with associated dimension weights.
class DiscernmentOption {
  final String text;
  final String? subtitle;
  final IconData? icon;
  final Map<DiscernmentAxis, double> weights;

  const DiscernmentOption({
    required this.text,
    this.subtitle,
    this.icon,
    required this.weights,
  });
}

/// A question in the discernment question bank.
class DiscernmentQuestion {
  final String id;
  final String title;
  final String? contextDescription;
  final DiscernmentAxis? primaryAxis;
  final List<DiscernmentOption> options;

  const DiscernmentQuestion({
    required this.id,
    required this.title,
    this.contextDescription,
    this.primaryAxis,
    required this.options,
  });
}

/// A seeded saint entrant in the 16-candidate tournament.
class TournamentSeed {
  final int seed; // 1 to 16
  final Saint saint;
  final double matchScore; // 0.0 to 1.0 (e.g. 0.95 = 95% compatibility)
  final String primaryHighlight;

  const TournamentSeed({
    required this.seed,
    required this.saint,
    required this.matchScore,
    required this.primaryHighlight,
  });

  int get matchPercentage => (matchScore * 100).round().clamp(1, 99);
}

/// A single head-to-head matchup in the bracket.
class TournamentMatch {
  final int
  round; // 0: Round of 16 (8 matches), 1: Quarterfinals (4), 2: Semifinals (2), 3: Finals (1)
  final int matchIndex;
  final TournamentSeed? entrant1;
  final TournamentSeed? entrant2;
  TournamentSeed? winner;

  TournamentMatch({
    required this.round,
    required this.matchIndex,
    this.entrant1,
    this.entrant2,
    this.winner,
  });

  bool get isReady => entrant1 != null && entrant2 != null;
  bool get isDecided => winner != null;

  String get roundName {
    switch (round) {
      case 0:
        return 'Round of 16';
      case 1:
        return 'Quarterfinals';
      case 2:
        return 'Semifinals';
      case 3:
        return 'Championship Match';
      default:
        return 'Round ${round + 1}';
    }
  }
}
