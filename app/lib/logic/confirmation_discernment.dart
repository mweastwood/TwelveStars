import 'dart:math';
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

/// Full state machine for the 16-entrant single elimination tournament.
class TournamentState {
  final List<TournamentSeed> initialSeeds;
  final List<List<TournamentMatch>> rounds;
  int currentRoundIndex;
  int currentMatchIndex;

  TournamentState({
    required this.initialSeeds,
    required this.rounds,
    this.currentRoundIndex = 0,
    this.currentMatchIndex = 0,
  });

  int get totalMatches => 15; // 8 + 4 + 2 + 1

  int get completedMatchCount {
    int count = 0;
    for (final round in rounds) {
      for (final match in round) {
        if (match.isDecided) count++;
      }
    }
    return count;
  }

  TournamentMatch? get currentMatch {
    if (isComplete) return null;
    if (currentRoundIndex < rounds.length &&
        currentMatchIndex < rounds[currentRoundIndex].length) {
      return rounds[currentRoundIndex][currentMatchIndex];
    }
    return null;
  }

  bool get isComplete {
    return rounds.isNotEmpty &&
        rounds.last.isNotEmpty &&
        rounds.last.first.isDecided;
  }

  TournamentSeed? get champion {
    if (isComplete) {
      return rounds.last.first.winner;
    }
    return null;
  }

  void recordWinner(TournamentSeed winner) {
    if (isComplete) return;
    final match = currentMatch;
    if (match == null) return;

    match.winner = winner;

    // Propagate winner to next round
    final nextRoundIdx = currentRoundIndex + 1;
    if (nextRoundIdx < rounds.length) {
      final nextMatchIdx = currentMatchIndex ~/ 2;
      final nextMatch = rounds[nextRoundIdx][nextMatchIdx];
      if (currentMatchIndex % 2 == 0) {
        rounds[nextRoundIdx][nextMatchIdx] = TournamentMatch(
          round: nextRoundIdx,
          matchIndex: nextMatchIdx,
          entrant1: winner,
          entrant2: nextMatch.entrant2,
          winner: nextMatch.winner,
        );
      } else {
        rounds[nextRoundIdx][nextMatchIdx] = TournamentMatch(
          round: nextRoundIdx,
          matchIndex: nextMatchIdx,
          entrant1: nextMatch.entrant1,
          entrant2: winner,
          winner: nextMatch.winner,
        );
      }
    }

    // Advance to next match
    currentMatchIndex++;
    if (currentMatchIndex >= rounds[currentRoundIndex].length) {
      currentRoundIndex++;
      currentMatchIndex = 0;
    }
  }
}

/// Core logic engine for the 32-question bank, stratified down-selection,
/// vector matching, and bracket generation.
class ConfirmationDiscernmentEngine {
  /// The curated bank of 32 discernment questions spanning all 6 axes and cross-cutting gifts.
  static const List<DiscernmentQuestion> questionBank = [
    // --- AXIS 1: Contemplation vs. Active Mission (5 Questions) ---
    DiscernmentQuestion(
      id: 'q1_prayer_space',
      title: 'Where do you feel God’s presence most vividly?',
      primaryAxis: DiscernmentAxis.contemplativeVsActive,
      options: [
        DiscernmentOption(
          text: 'In quiet Eucharistic adoration or a silent chapel',
          subtitle: 'Interior recollection and deep peace',
          icon: Icons.self_improvement,
          weights: {DiscernmentAxis.contemplativeVsActive: -0.9},
        ),
        DiscernmentOption(
          text: 'Serving the needy, helping out, or in active community',
          subtitle: 'Finding Christ in loving action and encounter',
          icon: Icons.volunteer_activism,
          weights: {DiscernmentAxis.contemplativeVsActive: 0.9},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q2_ideal_retreat',
      title: 'If you had a whole day dedicated to God, you would prefer:',
      primaryAxis: DiscernmentAxis.contemplativeVsActive,
      options: [
        DiscernmentOption(
          text:
              'A quiet day in nature meditating on Scripture and praying the Rosary',
          icon: Icons.nature_people,
          weights: {DiscernmentAxis.contemplativeVsActive: -0.8},
        ),
        DiscernmentOption(
          text:
              'A mission day organizing a service project or soup kitchen outreach',
          icon: Icons.handshake,
          weights: {DiscernmentAxis.contemplativeVsActive: 0.8},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q3_world_transformation',
      title:
          'How do you believe hearts and the world are most powerfully transformed?',
      primaryAxis: DiscernmentAxis.contemplativeVsActive,
      options: [
        DiscernmentOption(
          text:
              'Through hidden, unceasing prayer and sacrifice that move God’s grace',
          icon: Icons.favorite_border,
          weights: {DiscernmentAxis.contemplativeVsActive: -0.9},
        ),
        DiscernmentOption(
          text:
              'Through bold public witness, preaching, and direct charitable deeds',
          icon: Icons.campaign,
          weights: {DiscernmentAxis.contemplativeVsActive: 0.9},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q4_daily_habit',
      title: 'Which spiritual practice appeals to you most as a daily rhythm?',
      primaryAxis: DiscernmentAxis.contemplativeVsActive,
      options: [
        DiscernmentOption(
          text: '20 minutes of meditative silent contemplation (Lectio Divina)',
          icon: Icons.menu_book,
          weights: {DiscernmentAxis.contemplativeVsActive: -0.7},
        ),
        DiscernmentOption(
          text:
              'Deliberately doing 5 concrete acts of charity for friends and strangers',
          icon: Icons.diversity_1,
          weights: {DiscernmentAxis.contemplativeVsActive: 0.7},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q5_church_atmosphere',
      title: 'Which atmosphere in the Church inspires your heart most?',
      primaryAxis: DiscernmentAxis.contemplativeVsActive,
      options: [
        DiscernmentOption(
          text: 'Sacred silence, incense, Gregorian chant, and monastic prayer',
          icon: Icons.church,
          weights: {DiscernmentAxis.contemplativeVsActive: -0.85},
        ),
        DiscernmentOption(
          text:
              'Energetic youth rallies, vibrant mission trips, and community gatherings',
          icon: Icons.groups,
          weights: {DiscernmentAxis.contemplativeVsActive: 0.85},
        ),
      ],
    ),

    // --- AXIS 2: Intellect & Doctrine vs. Heart & Devotion (5 Questions) ---
    DiscernmentQuestion(
      id: 'q6_faith_driver',
      title: 'What draws you deeper into wanting to know God?',
      primaryAxis: DiscernmentAxis.intellectualVsDevotional,
      options: [
        DiscernmentOption(
          text:
              'Learning the deep theology, apologetics, and philosophy behind Catholic truth',
          subtitle: 'Faith seeking understanding',
          icon: Icons.school,
          weights: {DiscernmentAxis.intellectualVsDevotional: -0.9},
        ),
        DiscernmentOption(
          text:
              'Heartfelt personal prayer, Eucharistic devotion, and emotional intimacy with Jesus',
          subtitle: 'A heart burning with love',
          icon: Icons.favorite,
          weights: {DiscernmentAxis.intellectualVsDevotional: 0.9},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q7_reading_choice',
      title: 'Which book would you eagerly choose to read first?',
      primaryAxis: DiscernmentAxis.intellectualVsDevotional,
      options: [
        DiscernmentOption(
          text:
              'A profound theological work on the mysteries of the faith and scripture',
          icon: Icons.library_books,
          weights: {DiscernmentAxis.intellectualVsDevotional: -0.85},
        ),
        DiscernmentOption(
          text:
              'An inspiring spiritual autobiography about living simple love in daily life',
          icon: Icons.auto_stories,
          weights: {DiscernmentAxis.intellectualVsDevotional: 0.85},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q8_explaining_faith',
      title: 'When a friend asks why you are Catholic, your first response is:',
      primaryAxis: DiscernmentAxis.intellectualVsDevotional,
      options: [
        DiscernmentOption(
          text:
              'Walk through historical facts, apostolic succession, and logical evidence',
          icon: Icons.psychology,
          weights: {DiscernmentAxis.intellectualVsDevotional: -0.8},
        ),
        DiscernmentOption(
          text:
              'Share the personal peace, forgiveness, and unconditional love God gives you',
          icon: Icons.sentiment_very_satisfied,
          weights: {DiscernmentAxis.intellectualVsDevotional: 0.8},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q9_challenge_focus',
      title: 'Which challenge feels most important for today’s culture?',
      primaryAxis: DiscernmentAxis.intellectualVsDevotional,
      options: [
        DiscernmentOption(
          text:
              'Defending objective truth and reason against confusion and relativism',
          icon: Icons.gavel,
          weights: {DiscernmentAxis.intellectualVsDevotional: -0.85},
        ),
        DiscernmentOption(
          text:
              'Reaching lonely hearts and teaching people how to truly love and forgive',
          icon: Icons.healing,
          weights: {DiscernmentAxis.intellectualVsDevotional: 0.85},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q10_holy_spirit_gift_mind_heart',
      title: 'Which gift of the Holy Spirit do you long for most right now?',
      primaryAxis: DiscernmentAxis.intellectualVsDevotional,
      options: [
        DiscernmentOption(
          text: 'Wisdom & Understanding — deep insight into divine truth',
          icon: Icons.lightbulb,
          weights: {DiscernmentAxis.intellectualVsDevotional: -0.9},
        ),
        DiscernmentOption(
          text:
              'Piety & Awe of the Lord — a tender, reverent heart full of trust',
          icon: Icons.auto_awesome,
          weights: {DiscernmentAxis.intellectualVsDevotional: 0.9},
        ),
      ],
    ),

    // --- AXIS 3: Courage/Fortitude vs. Gentleness/Mercy (5 Questions) ---
    DiscernmentQuestion(
      id: 'q11_facing_opposition',
      title: 'When people around you mock Christian morals or faith:',
      primaryAxis: DiscernmentAxis.courageVsMercy,
      options: [
        DiscernmentOption(
          text:
              'Stand up boldly, speak the truth without fear, and hold the line',
          icon: Icons.shield,
          weights: {DiscernmentAxis.courageVsMercy: -0.9},
        ),
        DiscernmentOption(
          text:
              'Respond with gentle patience, listen with empathy, and win them with kindness',
          icon: Icons.spa,
          weights: {DiscernmentAxis.courageVsMercy: 0.9},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q12_heroic_story',
      title: 'Which kind of hero inspires you most deeply?',
      primaryAxis: DiscernmentAxis.courageVsMercy,
      options: [
        DiscernmentOption(
          text:
              'A courageous martyr who never flinched even when facing persecution or death',
          icon: Icons.local_fire_department,
          weights: {DiscernmentAxis.courageVsMercy: -0.95},
        ),
        DiscernmentOption(
          text:
              'A compassionate healer who spent years caring for the sick and forgotten',
          icon: Icons.medical_services,
          weights: {DiscernmentAxis.courageVsMercy: 0.95},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q13_coach_style',
      title: 'What spiritual director or coach would help you grow fastest?',
      primaryAxis: DiscernmentAxis.courageVsMercy,
      options: [
        DiscernmentOption(
          text:
              'A demanding leader who challenges you to conquer your comfort zone',
          icon: Icons.fitness_center,
          weights: {DiscernmentAxis.courageVsMercy: -0.8},
        ),
        DiscernmentOption(
          text:
              'A gentle shepherd who patiently heals your weaknesses and encourages you',
          icon: Icons.thumb_up,
          weights: {DiscernmentAxis.courageVsMercy: 0.8},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q14_handling_conflict',
      title: 'When conflict breaks out among your peers, your natural role is:',
      primaryAxis: DiscernmentAxis.courageVsMercy,
      options: [
        DiscernmentOption(
          text: 'Calling out injustice directly and demanding accountability',
          icon: Icons.balance,
          weights: {DiscernmentAxis.courageVsMercy: -0.85},
        ),
        DiscernmentOption(
          text:
              'Being a peacemaker, calming angry voices, and bringing reconciliation',
          icon: Icons.emoji_people,
          weights: {DiscernmentAxis.courageVsMercy: 0.85},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q15_virtue_aspiration',
      title: 'Which Beatitude speaks to your soul most clearly?',
      primaryAxis: DiscernmentAxis.courageVsMercy,
      options: [
        DiscernmentOption(
          text:
              '“Blessed are those who are persecuted for righteousness’ sake”',
          icon: Icons.military_tech,
          weights: {DiscernmentAxis.courageVsMercy: -0.9},
        ),
        DiscernmentOption(
          text: '“Blessed are the merciful, for they shall receive mercy”',
          icon: Icons.favorite_border,
          weights: {DiscernmentAxis.courageVsMercy: 0.9},
        ),
      ],
    ),

    // --- AXIS 4: Ancient & Apostolic vs. Modern & Relatable (5 Questions) ---
    DiscernmentQuestion(
      id: 'q16_era_connection',
      title: 'Which historical setting feels most captivating to you?',
      primaryAxis: DiscernmentAxis.ancientVsModern,
      options: [
        DiscernmentOption(
          text:
              'Biblical times, the Apostles, Roman catacombs, and Early Church Fathers',
          icon: Icons.account_balance,
          weights: {DiscernmentAxis.ancientVsModern: -0.9},
        ),
        DiscernmentOption(
          text:
              'The 19th–21st century: modern schools, smartphones, and contemporary culture',
          icon: Icons.devices,
          weights: {DiscernmentAxis.ancientVsModern: 0.9},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q17_relatability',
      title: 'Do you find it easier to connect with a saint who:',
      primaryAxis: DiscernmentAxis.ancientVsModern,
      options: [
        DiscernmentOption(
          text:
              'Lived in ancient times and established the foundations of the faith',
          icon: Icons.history_edu,
          weights: {DiscernmentAxis.ancientVsModern: -0.85},
        ),
        DiscernmentOption(
          text:
              'Faced modern struggles like digital media, modern school pressure, or world wars',
          icon: Icons.trending_up,
          weights: {DiscernmentAxis.ancientVsModern: 0.85},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q18_patron_age',
      title: 'Which mentor archetype appeals to you more?',
      primaryAxis: DiscernmentAxis.ancientVsModern,
      options: [
        DiscernmentOption(
          text: 'A venerable ancient patriarch or pillar of the Church',
          icon: Icons.person_pin,
          weights: {DiscernmentAxis.ancientVsModern: -0.8},
        ),
        DiscernmentOption(
          text:
              'A young saint or contemporary youth who lived holiness in modern times',
          icon: Icons.face,
          weights: {DiscernmentAxis.ancientVsModern: 0.8},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q19_monuments',
      title:
          'If visiting a sacred pilgrimage site, you would be more excited by:',
      primaryAxis: DiscernmentAxis.ancientVsModern,
      options: [
        DiscernmentOption(
          text:
              'Ancient Roman ruins, holy land caves, and 1,500-year-old stone shrines',
          icon: Icons.castle,
          weights: {DiscernmentAxis.ancientVsModern: -0.85},
        ),
        DiscernmentOption(
          text:
              'Places visited by modern saints, contemporary shrines, and youth pilgrimage centers',
          icon: Icons.flight,
          weights: {DiscernmentAxis.ancientVsModern: 0.85},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q20_witness_context',
      title: 'Which testimony of faith feels most inspiring?',
      primaryAxis: DiscernmentAxis.ancientVsModern,
      options: [
        DiscernmentOption(
          text:
              'Witnessing under the Roman Empire and defending the Nicene Creed',
          icon: Icons.auto_awesome_motion,
          weights: {DiscernmentAxis.ancientVsModern: -0.9},
        ),
        DiscernmentOption(
          text:
              'Living joyful Catholic holiness in our fast-paced, high-tech modern world',
          icon: Icons.computer,
          weights: {DiscernmentAxis.ancientVsModern: 0.9},
        ),
      ],
    ),

    // --- AXIS 5: Simplicity & Poverty vs. Leadership & Governance (5 Questions) ---
    DiscernmentQuestion(
      id: 'q21_lifestyle_calling',
      title: 'What radical Gospel lifestyle calls to your heart?',
      primaryAxis: DiscernmentAxis.simplicityVsLeadership,
      options: [
        DiscernmentOption(
          text:
              'Radical simplicity, detachment from luxury, and humble hidden service',
          icon: Icons.energy_savings_leaf,
          weights: {DiscernmentAxis.simplicityVsLeadership: -0.9},
        ),
        DiscernmentOption(
          text:
              'Using leadership, influence, authority, and talent to build up society and Church',
          icon: Icons.leaderboard,
          weights: {DiscernmentAxis.simplicityVsLeadership: 0.9},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q22_position_in_life',
      title: 'If God offered you a high role of public authority, you would:',
      primaryAxis: DiscernmentAxis.simplicityVsLeadership,
      options: [
        DiscernmentOption(
          text: 'Prefer to stay behind the scenes in quiet, humble obedience',
          icon: Icons.visibility_off,
          weights: {DiscernmentAxis.simplicityVsLeadership: -0.85},
        ),
        DiscernmentOption(
          text:
              'Accept the responsibility gladly to govern, protect, and guide others wisely',
          icon: Icons.stars,
          weights: {DiscernmentAxis.simplicityVsLeadership: 0.85},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q23_vocation_model',
      title: 'Whose life story do you find more compelling?',
      primaryAxis: DiscernmentAxis.simplicityVsLeadership,
      options: [
        DiscernmentOption(
          text:
              'A humble lay person or beggar who found extraordinary holiness in ordinary obscurity',
          icon: Icons.person,
          weights: {DiscernmentAxis.simplicityVsLeadership: -0.85},
        ),
        DiscernmentOption(
          text:
              'A great bishop, pope, king, or queen who transformed nations and institutions',
          icon: Icons.workspace_premium,
          weights: {DiscernmentAxis.simplicityVsLeadership: 0.85},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q24_material_goods',
      title: 'How do you view material wealth and influence?',
      primaryAxis: DiscernmentAxis.simplicityVsLeadership,
      options: [
        DiscernmentOption(
          text: 'Something to let go of to be truly free like St. Francis',
          icon: Icons.eco,
          weights: {DiscernmentAxis.simplicityVsLeadership: -0.8},
        ),
        DiscernmentOption(
          text:
              'A tool to be stewarded effectively to fund schools, churches, and great works',
          icon: Icons.account_balance_wallet,
          weights: {DiscernmentAxis.simplicityVsLeadership: 0.8},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q25_daily_calling',
      title: 'In your friend circle or school group, you are naturally:',
      primaryAxis: DiscernmentAxis.simplicityVsLeadership,
      options: [
        DiscernmentOption(
          text:
              'The quiet supporter who listens, helps, and works behind the scenes',
          icon: Icons.support,
          weights: {DiscernmentAxis.simplicityVsLeadership: -0.8},
        ),
        DiscernmentOption(
          text:
              'The organizer who takes charge, leads projects, and rallies everyone together',
          icon: Icons.groups_2,
          weights: {DiscernmentAxis.simplicityVsLeadership: 0.8},
        ),
      ],
    ),

    // --- AXIS 6: Pioneering & Innovation vs. Tradition & Preservation (5 Questions) ---
    DiscernmentQuestion(
      id: 'q26_geographic_calling',
      title: 'If God called you to an exciting adventure of faith:',
      primaryAxis: DiscernmentAxis.pioneeringVsPreservation,
      options: [
        DiscernmentOption(
          text:
              'Travel across oceans as a pioneer missionary to bring Christ where He isn’t known',
          icon: Icons.explore,
          weights: {DiscernmentAxis.pioneeringVsPreservation: -0.9},
        ),
        DiscernmentOption(
          text:
              'Stay and strengthen your local parish and family, keeping the sacred flame burning',
          icon: Icons.home,
          weights: {DiscernmentAxis.pioneeringVsPreservation: 0.9},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q27_creative_methods',
      title:
          'When sharing the Gospel with the next generation, you prioritize:',
      primaryAxis: DiscernmentAxis.pioneeringVsPreservation,
      options: [
        DiscernmentOption(
          text:
              'Inventing new creative media, digital technology, art, and modern formats',
          icon: Icons.palette,
          weights: {DiscernmentAxis.pioneeringVsPreservation: -0.85},
        ),
        DiscernmentOption(
          text:
              'Preserving timeless sacred traditions, beautiful liturgy, and authentic heritage',
          icon: Icons.hourglass_top,
          weights: {DiscernmentAxis.pioneeringVsPreservation: 0.85},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q28_vocation_legacy',
      title: 'Which legacy sounds most meaningful to you?',
      primaryAxis: DiscernmentAxis.pioneeringVsPreservation,
      options: [
        DiscernmentOption(
          text:
              'Founding something entirely new that breaks fresh ground for Christ',
          icon: Icons.add_circle_outline,
          weights: {DiscernmentAxis.pioneeringVsPreservation: -0.85},
        ),
        DiscernmentOption(
          text:
              'Being a steadfast pillar who guards and passes on the sacred deposit of faith',
          icon: Icons.shield_outlined,
          weights: {DiscernmentAxis.pioneeringVsPreservation: 0.85},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q29_fixing_problems',
      title: 'When an organization or system needs improvement:',
      primaryAxis: DiscernmentAxis.pioneeringVsPreservation,
      options: [
        DiscernmentOption(
          text:
              'Innovate a fresh alternative and start an initiative from scratch',
          icon: Icons.rocket_launch,
          weights: {DiscernmentAxis.pioneeringVsPreservation: -0.8},
        ),
        DiscernmentOption(
          text:
              'Patiently reform, preserve, and restore the original founding principles',
          icon: Icons.build,
          weights: {DiscernmentAxis.pioneeringVsPreservation: 0.8},
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q30_quote_affinity',
      title: 'Which Scripture passage inspires you more?',
      primaryAxis: DiscernmentAxis.pioneeringVsPreservation,
      options: [
        DiscernmentOption(
          text:
              '“Go into all the world and proclaim the gospel to the whole creation” (Mk 16:15)',
          icon: Icons.public,
          weights: {DiscernmentAxis.pioneeringVsPreservation: -0.9},
        ),
        DiscernmentOption(
          text:
              '“Stand firm and hold to the traditions which you were taught” (2 Thess 2:15)',
          icon: Icons.verified,
          weights: {DiscernmentAxis.pioneeringVsPreservation: 0.9},
        ),
      ],
    ),

    // --- CROSS-CUTTING & CONFIRMATION CHARISMS (2 Questions) ---
    DiscernmentQuestion(
      id: 'q31_confirmation_charism',
      title:
          'What spiritual charism do you most want the Holy Spirit to ignite in you at Confirmation?',
      options: [
        DiscernmentOption(
          text:
              'Intellectual clarity and bold truth to teach and defend the faith',
          icon: Icons.school_outlined,
          weights: {
            DiscernmentAxis.intellectualVsDevotional: -0.8,
            DiscernmentAxis.courageVsMercy: -0.5,
          },
        ),
        DiscernmentOption(
          text:
              'Interior peace, mystical prayer, and tender closeness to Jesus and Mary',
          icon: Icons.favorite_border,
          weights: {
            DiscernmentAxis.contemplativeVsActive: -0.8,
            DiscernmentAxis.intellectualVsDevotional: 0.7,
          },
        ),
        DiscernmentOption(
          text:
              'Courageous missionary zeal to lead others and build God’s kingdom',
          icon: Icons.flag,
          weights: {
            DiscernmentAxis.contemplativeVsActive: 0.8,
            DiscernmentAxis.simplicityVsLeadership: 0.6,
            DiscernmentAxis.pioneeringVsPreservation: -0.6,
          },
        ),
        DiscernmentOption(
          text:
              'Boundless mercy and hands-on compassion for those who are suffering',
          icon: Icons.volunteer_activism_outlined,
          weights: {
            DiscernmentAxis.courageVsMercy: 0.8,
            DiscernmentAxis.contemplativeVsActive: 0.6,
            DiscernmentAxis.simplicityVsLeadership: -0.6,
          },
        ),
      ],
    ),
    DiscernmentQuestion(
      id: 'q32_life_aspiration',
      title:
          'What area of life do you most want your Confirmation saint to guide you through?',
      options: [
        DiscernmentOption(
          text: 'Academics, science, critical thinking, and finding truth',
          icon: Icons.science,
          weights: {
            DiscernmentAxis.intellectualVsDevotional: -0.9,
            DiscernmentAxis.pioneeringVsPreservation: 0.4,
          },
        ),
        DiscernmentOption(
          text:
              'Moral courage, standing firm with peers, and living pure integrity',
          icon: Icons.security,
          weights: {
            DiscernmentAxis.courageVsMercy: -0.9,
            DiscernmentAxis.ancientVsModern: 0.4,
          },
        ),
        DiscernmentOption(
          text:
              'Caring for people in healthcare, teaching, counseling, or family life',
          icon: Icons.family_restroom,
          weights: {
            DiscernmentAxis.courageVsMercy: 0.8,
            DiscernmentAxis.contemplativeVsActive: 0.6,
          },
        ),
        DiscernmentOption(
          text:
              'Discovering my future vocation (Marriage, Priesthood, or Consecrated Life)',
          icon: Icons.church_outlined,
          weights: {
            DiscernmentAxis.contemplativeVsActive: -0.5,
            DiscernmentAxis.simplicityVsLeadership: -0.4,
            DiscernmentAxis.pioneeringVsPreservation: 0.6,
          },
        ),
      ],
    ),
  ];

  /// Down-selects a stratified set of questions from the bank (guaranteeing coverage across all 6 axes).
  static List<DiscernmentQuestion> selectQuestions({
    int count = 7,
    Random? random,
  }) {
    final rng = random ?? Random();

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

    // 2. Pick 1 question from each of the 6 primary axes
    for (final axis in DiscernmentAxis.values) {
      final list = axisGroups[axis];
      if (list != null && list.isNotEmpty) {
        final chosen = list[rng.nextInt(list.length)];
        selected.add(chosen);
      }
    }

    // 3. Pick remaining questions from cross-cutting (or extra from bank)
    if (crossCutting.isNotEmpty && selected.length < count) {
      final shuffledCross = List<DiscernmentQuestion>.from(crossCutting)
        ..shuffle(rng);
      for (final q in shuffledCross) {
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
    final rng = random ?? Random();

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

    // Extract top `count`
    final topEntries = scored.take(count).toList();

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
