import 'package:flutter/material.dart';
import 'discernment_models.dart';

/// The curated bank of 32 discernment questions spanning all 6 axes and cross-cutting gifts.
const List<DiscernmentQuestion> questionBank = [
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
        text: '“Blessed are those who are persecuted for righteousness’ sake”',
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
    title: 'When sharing the Gospel with the next generation, you prioritize:',
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
