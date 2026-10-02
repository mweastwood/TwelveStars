import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfirmationDiscernmentEngine Tests', () {
    setUp(() {
      ConfirmationDiscernmentEngine.mockQuestions = null;
      ConfirmationDiscernmentEngine.mockRandom = null;
    });

    tearDown(() {
      ConfirmationDiscernmentEngine.mockQuestions = null;
      ConfirmationDiscernmentEngine.mockRandom = null;
    });

    group('Stratified Question Selection (selectQuestions)', () {
      test(
        'Axis Stratification & Coverage with default count (14 questions)',
        () {
          final selected = ConfirmationDiscernmentEngine.selectQuestions(
            random: Random(42),
          );

          expect(selected.length, 14);
          expect(
            selected.toSet().length,
            14,
            reason: 'All selected questions must be unique',
          );

          final axisCounts = <DiscernmentAxis, int>{};
          int crossCuttingCount = 0;

          for (final q in selected) {
            if (q.primaryAxis != null) {
              axisCounts[q.primaryAxis!] =
                  (axisCounts[q.primaryAxis!] ?? 0) + 1;
            } else {
              crossCuttingCount++;
            }
          }

          // All 6 core dimensions must have exactly 2 questions
          for (final axis in DiscernmentAxis.values) {
            expect(
              axisCounts[axis],
              2,
              reason:
                  'Axis $axis must have exactly 2 questions for default count 14',
            );
          }

          // Exactly 2 cross-cutting questions (primaryAxis == null)
          expect(
            crossCuttingCount,
            2,
            reason:
                'Must include 2 cross-cutting questions to reach total of 14',
          );
        },
      );

      test(
        'Boundary count < 6 (count: 3) returns exactly 3 questions without exceeding limit',
        () {
          final selected = ConfirmationDiscernmentEngine.selectQuestions(
            count: 3,
            random: Random(123),
          );

          expect(selected.length, 3);
          expect(selected.toSet().length, 3);
        },
      );

      test(
        'Boundary count < 6 (count: 1 and count: 5) respects count limit',
        () {
          final selected1 = ConfirmationDiscernmentEngine.selectQuestions(
            count: 1,
            random: Random(1),
          );
          expect(selected1.length, 1);

          final selected5 = ConfirmationDiscernmentEngine.selectQuestions(
            count: 5,
            random: Random(5),
          );
          expect(selected5.length, 5);
          expect(selected5.toSet().length, 5);
        },
      );

      test(
        'Count = 20 selects 20 unique questions with balanced distribution across axes',
        () {
          final selected = ConfirmationDiscernmentEngine.selectQuestions(
            count: 20,
            random: Random(77),
          );

          expect(selected.length, 20);
          expect(
            selected.toSet().length,
            20,
            reason: 'Must contain 20 unique questions',
          );

          final axisCounts = <DiscernmentAxis, int>{};
          int crossCuttingCount = 0;
          for (final q in selected) {
            if (q.primaryAxis != null) {
              axisCounts[q.primaryAxis!] =
                  (axisCounts[q.primaryAxis!] ?? 0) + 1;
            } else {
              crossCuttingCount++;
            }
          }

          // Each axis should receive 3 questions (20 ~/ 6 = 3), total 18
          for (final axis in DiscernmentAxis.values) {
            expect(
              axisCounts[axis],
              3,
              reason: 'Axis $axis must have 3 questions when count=20',
            );
          }
          // Remaining 2 questions should be cross-cutting
          expect(crossCuttingCount, 2);
        },
      );

      test(
        'Count >= 32 selects all 32 questions from questionBank without duplicates',
        () {
          final selected32 = ConfirmationDiscernmentEngine.selectQuestions(
            count: 32,
            random: Random(99),
          );
          expect(selected32.length, 32);
          expect(selected32.toSet().length, 32);
          expect(
            selected32.map((q) => q.id).toSet(),
            equals(
              ConfirmationDiscernmentEngine.questionBank
                  .map((q) => q.id)
                  .toSet(),
            ),
          );

          // Even if requesting more than 32 (e.g. 40), it cannot exceed available bank of 32
          final selected40 = ConfirmationDiscernmentEngine.selectQuestions(
            count: 40,
            random: Random(101),
          );
          expect(selected40.length, 32);
          expect(selected40.toSet().length, 32);
        },
      );

      test('Determinism using injected Random(seed) parameter', () {
        final runA = ConfirmationDiscernmentEngine.selectQuestions(
          count: 14,
          random: Random(42),
        );
        final runB = ConfirmationDiscernmentEngine.selectQuestions(
          count: 14,
          random: Random(42),
        );

        expect(
          runA.map((q) => q.id).toList(),
          equals(runB.map((q) => q.id).toList()),
        );
      });

      test('Determinism using ConfirmationDiscernmentEngine.mockRandom', () {
        ConfirmationDiscernmentEngine.mockRandom = Random(888);
        final runA = ConfirmationDiscernmentEngine.selectQuestions(count: 14);

        ConfirmationDiscernmentEngine.mockRandom = Random(888);
        final runB = ConfirmationDiscernmentEngine.selectQuestions(count: 14);

        expect(
          runA.map((q) => q.id).toList(),
          equals(runB.map((q) => q.id).toList()),
        );
      });

      test('Injected random parameter takes precedence over mockRandom', () {
        ConfirmationDiscernmentEngine.mockRandom = Random(111);
        final runWithParam = ConfirmationDiscernmentEngine.selectQuestions(
          count: 14,
          random: Random(222),
        );

        final runDirectParam = ConfirmationDiscernmentEngine.selectQuestions(
          count: 14,
          random: Random(222),
        );

        expect(
          runWithParam.map((q) => q.id).toList(),
          equals(runDirectParam.map((q) => q.id).toList()),
        );
      });

      test(
        'Override behavior when ConfirmationDiscernmentEngine.mockQuestions is populated',
        () {
          const dummyMock = [
            DiscernmentQuestion(
              id: 'mock_1',
              title: 'Mock Question 1',
              options: [
                DiscernmentOption(
                  text: 'Opt 1',
                  weights: {DiscernmentAxis.contemplativeVsActive: 0.5},
                ),
              ],
            ),
            DiscernmentQuestion(
              id: 'mock_2',
              title: 'Mock Question 2',
              options: [
                DiscernmentOption(
                  text: 'Opt 2',
                  weights: {DiscernmentAxis.intellectualVsDevotional: -0.5},
                ),
              ],
            ),
          ];

          ConfirmationDiscernmentEngine.mockQuestions = dummyMock;

          // Regardless of requested count, mockQuestions is returned
          final result = ConfirmationDiscernmentEngine.selectQuestions(
            count: 14,
          );
          expect(result.length, 2);
          expect(result.map((q) => q.id).toList(), ['mock_1', 'mock_2']);

          // Clean up and verify restoration
          ConfirmationDiscernmentEngine.mockQuestions = null;
          final restored = ConfirmationDiscernmentEngine.selectQuestions(
            count: 14,
          );
          expect(restored.length, 14);
          expect(restored.any((q) => q.id == 'mock_1'), isFalse);
        },
      );
    });

    group('Spiritual Profile Vector Calculation (calculateUserVector)', () {
      test('Dimension & Ordering matches canonical 6-axis layout', () {
        // Construct 6 custom questions, each exclusively modifying one axis
        final questions = [
          const DiscernmentQuestion(
            id: 'q_axis_0',
            title: 'Contemplative vs Active',
            options: [
              DiscernmentOption(
                text: 'Active',
                weights: {DiscernmentAxis.contemplativeVsActive: 0.8},
              ),
            ],
          ),
          const DiscernmentQuestion(
            id: 'q_axis_1',
            title: 'Intellectual vs Devotional',
            options: [
              DiscernmentOption(
                text: 'Devotional',
                weights: {DiscernmentAxis.intellectualVsDevotional: 0.6},
              ),
            ],
          ),
          const DiscernmentQuestion(
            id: 'q_axis_2',
            title: 'Courage vs Mercy',
            options: [
              DiscernmentOption(
                text: 'Mercy',
                weights: {DiscernmentAxis.courageVsMercy: 0.4},
              ),
            ],
          ),
          const DiscernmentQuestion(
            id: 'q_axis_3',
            title: 'Ancient vs Modern',
            options: [
              DiscernmentOption(
                text: 'Ancient',
                weights: {DiscernmentAxis.ancientVsModern: -0.7},
              ),
            ],
          ),
          const DiscernmentQuestion(
            id: 'q_axis_4',
            title: 'Simplicity vs Leadership',
            options: [
              DiscernmentOption(
                text: 'Simplicity',
                weights: {DiscernmentAxis.simplicityVsLeadership: -0.5},
              ),
            ],
          ),
          const DiscernmentQuestion(
            id: 'q_axis_5',
            title: 'Pioneering vs Preservation',
            options: [
              DiscernmentOption(
                text: 'Preservation',
                weights: {DiscernmentAxis.pioneeringVsPreservation: 0.9},
              ),
            ],
          ),
        ];

        final answers = {
          'q_axis_0': 0,
          'q_axis_1': 0,
          'q_axis_2': 0,
          'q_axis_3': 0,
          'q_axis_4': 0,
          'q_axis_5': 0,
        };

        final vector = ConfirmationDiscernmentEngine.calculateUserVector(
          answers,
          questions,
        );

        expect(vector.length, 6);
        expect(vector[0], closeTo(0.8, 1e-5)); // contemplativeVsActive
        expect(vector[1], closeTo(0.6, 1e-5)); // intellectualVsDevotional
        expect(vector[2], closeTo(0.4, 1e-5)); // courageVsMercy
        expect(vector[3], closeTo(-0.7, 1e-5)); // ancientVsModern
        expect(vector[4], closeTo(-0.5, 1e-5)); // simplicityVsLeadership
        expect(vector[5], closeTo(0.9, 1e-5)); // pioneeringVsPreservation
      });

      test(
        'Extreme positive answers (+1.0 on all axes) verify vector reaches +1.0',
        () {
          final allPositiveWeights = {
            for (final axis in DiscernmentAxis.values) axis: 1.0,
          };
          final question = DiscernmentQuestion(
            id: 'q_extreme_pos',
            title: 'Extreme Positive Question',
            options: [
              DiscernmentOption(text: 'Max All', weights: allPositiveWeights),
            ],
          );

          final vector = ConfirmationDiscernmentEngine.calculateUserVector(
            {'q_extreme_pos': 0},
            [question],
          );

          expect(vector.length, 6);
          for (final val in vector) {
            expect(val, closeTo(1.0, 1e-5));
          }
        },
      );

      test(
        'Extreme negative answers (-1.0 on all axes) verify vector reaches -1.0',
        () {
          final allNegativeWeights = {
            for (final axis in DiscernmentAxis.values) axis: -1.0,
          };
          final question = DiscernmentQuestion(
            id: 'q_extreme_neg',
            title: 'Extreme Negative Question',
            options: [
              DiscernmentOption(text: 'Min All', weights: allNegativeWeights),
            ],
          );

          final vector = ConfirmationDiscernmentEngine.calculateUserVector(
            {'q_extreme_neg': 0},
            [question],
          );

          expect(vector.length, 6);
          for (final val in vector) {
            expect(val, closeTo(-1.0, 1e-5));
          }
        },
      );

      test('Weight clamping beyond +/-1.0 clamps correctly to [-1.0, 1.0]', () {
        const questionOver = DiscernmentQuestion(
          id: 'q_over',
          title: 'Over 1.0',
          options: [
            DiscernmentOption(
              text: 'Too positive',
              weights: {DiscernmentAxis.contemplativeVsActive: 2.5},
            ),
          ],
        );
        const questionUnder = DiscernmentQuestion(
          id: 'q_under',
          title: 'Under -1.0',
          options: [
            DiscernmentOption(
              text: 'Too negative',
              weights: {DiscernmentAxis.intellectualVsDevotional: -3.0},
            ),
          ],
        );

        final vector = ConfirmationDiscernmentEngine.calculateUserVector(
          {'q_over': 0, 'q_under': 0},
          [questionOver, questionUnder],
        );

        expect(vector[0], 1.0);
        expect(vector[1], -1.0);
      });

      test(
        'Canceling/balanced answers (+1.0 and -1.0 on same axis) evaluates average to 0.0',
        () {
          final questions = [
            const DiscernmentQuestion(
              id: 'q1',
              title: 'Active Favor',
              options: [
                DiscernmentOption(
                  text: 'Active',
                  weights: {DiscernmentAxis.contemplativeVsActive: 1.0},
                ),
              ],
            ),
            const DiscernmentQuestion(
              id: 'q2',
              title: 'Contemplative Favor',
              options: [
                DiscernmentOption(
                  text: 'Contemplative',
                  weights: {DiscernmentAxis.contemplativeVsActive: -1.0},
                ),
              ],
            ),
          ];

          final vector = ConfirmationDiscernmentEngine.calculateUserVector({
            'q1': 0,
            'q2': 0,
          }, questions);

          // contemplativeVsActive averaged: (1.0 + -1.0) / 2 = 0.0
          expect(vector[0], closeTo(0.0, 1e-5));
        },
      );

      test(
        'Weight aggregation computes arithmetic mean across multiple questions on same axis',
        () {
          final questions = [
            const DiscernmentQuestion(
              id: 'q1',
              title: 'Part 1',
              options: [
                DiscernmentOption(
                  text: 'Opt',
                  weights: {DiscernmentAxis.courageVsMercy: 0.4},
                ),
              ],
            ),
            const DiscernmentQuestion(
              id: 'q2',
              title: 'Part 2',
              options: [
                DiscernmentOption(
                  text: 'Opt',
                  weights: {DiscernmentAxis.courageVsMercy: 0.8},
                ),
              ],
            ),
          ];

          final vector = ConfirmationDiscernmentEngine.calculateUserVector({
            'q1': 0,
            'q2': 0,
          }, questions);

          // (0.4 + 0.8) / 2 = 0.6
          expect(vector[2], closeTo(0.6, 1e-5));
        },
      );

      test('Unselected / untouched axes default to neutral 0.0', () {
        const question = DiscernmentQuestion(
          id: 'q_single',
          title: 'Single Axis',
          options: [
            DiscernmentOption(
              text: 'Only simplicity modified',
              weights: {DiscernmentAxis.simplicityVsLeadership: 0.75},
            ),
          ],
        );

        final vector = ConfirmationDiscernmentEngine.calculateUserVector(
          {'q_single': 0},
          [question],
        );

        expect(vector[0], 0.0);
        expect(vector[1], 0.0);
        expect(vector[2], 0.0);
        expect(vector[3], 0.0);
        expect(vector[4], closeTo(0.75, 1e-5)); // simplicityVsLeadership
        expect(vector[5], 0.0);
      });

      test('Empty response map returns all 0.0', () {
        final questions = ConfirmationDiscernmentEngine.questionBank
            .take(5)
            .toList();
        final vector = ConfirmationDiscernmentEngine.calculateUserVector(
          {},
          questions,
        );

        expect(vector, equals([0.0, 0.0, 0.0, 0.0, 0.0, 0.0]));
      });

      test('Empty activeQuestions list returns all 0.0', () {
        final vector = ConfirmationDiscernmentEngine.calculateUserVector({
          'any_id': 0,
        }, []);

        expect(vector, equals([0.0, 0.0, 0.0, 0.0, 0.0, 0.0]));
      });

      test(
        'Invalid option indices (negative or out-of-bounds) are safely ignored',
        () {
          const question = DiscernmentQuestion(
            id: 'q1',
            title: 'Valid question',
            options: [
              DiscernmentOption(
                text: 'Only option',
                weights: {DiscernmentAxis.ancientVsModern: 0.5},
              ),
            ],
          );

          // Test negative index
          final vectorNeg = ConfirmationDiscernmentEngine.calculateUserVector(
            {'q1': -1},
            [question],
          );
          expect(vectorNeg, equals([0.0, 0.0, 0.0, 0.0, 0.0, 0.0]));

          // Test out of bounds index
          final vectorOob = ConfirmationDiscernmentEngine.calculateUserVector(
            {'q1': 99},
            [question],
          );
          expect(vectorOob, equals([0.0, 0.0, 0.0, 0.0, 0.0, 0.0]));
        },
      );

      test(
        'Missing question IDs in answers are safely ignored as unselected',
        () {
          const questionA = DiscernmentQuestion(
            id: 'q_answered',
            title: 'Answered',
            options: [
              DiscernmentOption(
                text: 'A',
                weights: {DiscernmentAxis.contemplativeVsActive: 0.4},
              ),
            ],
          );
          const questionB = DiscernmentQuestion(
            id: 'q_unanswered',
            title: 'Unanswered',
            options: [
              DiscernmentOption(
                text: 'B',
                weights: {DiscernmentAxis.intellectualVsDevotional: 0.9},
              ),
            ],
          );

          final vector = ConfirmationDiscernmentEngine.calculateUserVector(
            {'q_answered': 0},
            [questionA, questionB],
          );

          expect(vector[0], closeTo(0.4, 1e-5));
          expect(vector[1], 0.0, reason: 'Unanswered question must remain 0.0');
        },
      );
    });

    group('Tournament Seed Generation (generateTournamentSeeds)', () {
      Saint createTestSaint({
        required String id,
        required String name,
        SaintEmbedding? embedding,
        bool isDoctor = false,
        List<SaintCategory> categories = const [],
        String? patronage,
        String profession = 'Holy Saint',
      }) {
        return Saint(
          id: id,
          name: name,
          nationality: 'Universal',
          profession: profession,
          isDoctor: isDoctor,
          categories: categories,
          patronage: patronage,
          embedding: embedding,
        );
      }

      test(
        'Matches user vectors and strictly sorts candidates in descending order of similarity',
        () {
          // User vector strictly along axis 0
          final userVector = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0];

          final saintPerfect = createTestSaint(
            id: 'perfect',
            name: 'St. Perfect',
            embedding: const SaintEmbedding(contemplativeVsActive: 1.0),
          );
          final saintPartial = createTestSaint(
            id: 'partial',
            name: 'St. Partial',
            embedding: const SaintEmbedding(
              contemplativeVsActive: 0.5,
              intellectualVsDevotional: 0.5,
            ),
          );
          final saintOrthogonal = createTestSaint(
            id: 'orthogonal',
            name: 'St. Orthogonal',
            embedding: const SaintEmbedding(intellectualVsDevotional: 1.0),
          );
          final saintOpposite = createTestSaint(
            id: 'opposite',
            name: 'St. Opposite',
            embedding: const SaintEmbedding(contemplativeVsActive: -1.0),
          );

          final saints = [
            saintOpposite,
            saintOrthogonal,
            saintPerfect,
            saintPartial,
          ];

          final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
            allSaints: saints,
            userVector: userVector,
            noiseMagnitude: 0.0,
            count: 4,
          );

          expect(seeds.length, 4);
          expect(
            seeds[0].saint.id,
            'perfect',
            reason: 'Highest similarity score',
          );
          expect(seeds[1].saint.id, 'partial');
          expect(seeds[2].saint.id, 'orthogonal');
          expect(
            seeds[3].saint.id,
            'opposite',
            reason: 'Lowest similarity score',
          );

          // Seeds are assigned 1 to count
          for (int i = 0; i < seeds.length; i++) {
            expect(seeds[i].seed, i + 1);
          }

          // Check strictly descending matchScore
          for (int i = 0; i < seeds.length - 1; i++) {
            expect(
              seeds[i].matchScore,
              greaterThanOrEqualTo(seeds[i + 1].matchScore),
            );
          }
        },
      );

      test('Candidate cycling when allSaints.length < count', () {
        final saints = [
          createTestSaint(
            id: 's1',
            name: 'Saint 1',
            embedding: const SaintEmbedding(contemplativeVsActive: 1.0),
          ),
          createTestSaint(
            id: 's2',
            name: 'Saint 2',
            embedding: const SaintEmbedding(contemplativeVsActive: 0.5),
          ),
          createTestSaint(
            id: 's3',
            name: 'Saint 3',
            embedding: const SaintEmbedding(contemplativeVsActive: 0.0),
          ),
        ];

        final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
          allSaints: saints,
          userVector: [1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          noiseMagnitude: 0.0,
          count: 8,
        );

        expect(seeds.length, 8);
        expect(seeds.map((s) => s.saint.id).toList(), [
          's1',
          's2',
          's3',
          's1',
          's2',
          's3',
          's1',
          's2',
        ]);
        for (int i = 0; i < seeds.length; i++) {
          expect(seeds[i].seed, i + 1);
        }
      });

      test('Empty saint catalog returns empty list', () {
        final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
          allSaints: [],
          userVector: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          count: 16,
        );

        expect(seeds, isEmpty);
      });

      test('Variable seed counts (count: 8 vs count: 16)', () {
        final saints = List.generate(
          20,
          (i) => createTestSaint(
            id: 'saint_$i',
            name: 'Saint $i',
            embedding: SaintEmbedding(contemplativeVsActive: (i - 10) / 10.0),
          ),
        );

        final seeds8 = ConfirmationDiscernmentEngine.generateTournamentSeeds(
          allSaints: saints,
          userVector: [1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          count: 8,
        );
        expect(seeds8.length, 8);
        expect(seeds8.last.seed, 8);

        final seeds16 = ConfirmationDiscernmentEngine.generateTournamentSeeds(
          allSaints: saints,
          userVector: [1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          count: 16,
        );
        expect(seeds16.length, 16);
        expect(seeds16.last.seed, 16);
      });

      test('Display score normalization to [0.50, 0.99] range', () {
        // Raw similarity ranges from -1.0 to 1.0:
        // formula: ((rawScore + 1.0) / 2.0 * 0.5 + 0.49).clamp(0.50, 0.99)
        // raw = 1.0 -> (2/2 * 0.5 + 0.49) = 0.99
        // raw = -1.0 -> (0/2 * 0.5 + 0.49) = 0.49 clamped to 0.50
        // raw = 0.0 -> (1/2 * 0.5 + 0.49) = 0.74
        final saintMax = createTestSaint(
          id: 'max',
          name: 'Max Match',
          embedding: const SaintEmbedding(contemplativeVsActive: 1.0),
        );
        final saintMin = createTestSaint(
          id: 'min',
          name: 'Min Match',
          embedding: const SaintEmbedding(contemplativeVsActive: -1.0),
        );
        final saintZero = createTestSaint(
          id: 'zero',
          name: 'Zero Match',
          embedding: const SaintEmbedding(intellectualVsDevotional: 1.0),
        );

        final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
          allSaints: [saintMax, saintMin, saintZero],
          userVector: [1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          noiseMagnitude: 0.0,
          count: 3,
        );

        final seedMax = seeds.firstWhere((s) => s.saint.id == 'max');
        expect(seedMax.matchScore, closeTo(0.99, 1e-4));
        expect(seedMax.matchPercentage, 99);

        final seedMin = seeds.firstWhere((s) => s.saint.id == 'min');
        expect(seedMin.matchScore, closeTo(0.50, 1e-4));
        expect(seedMin.matchPercentage, 50);

        final seedZero = seeds.firstWhere((s) => s.saint.id == 'zero');
        expect(seedZero.matchScore, closeTo(0.74, 1e-4));
        expect(seedZero.matchPercentage, 74);
      });

      test('Primary highlight determination respects exact precedence rules', () {
        // Rule 1: isDoctor: true
        final doctorSaint = createTestSaint(
          id: 'h1',
          name: 'Doctor Saint',
          isDoctor: true,
          categories: [SaintCategory.martyr, SaintCategory.mystic],
          patronage: 'Theologians',
          profession: 'Doctor & Martyr',
        );

        // Rule 2: Martyr category
        final martyrSaint = createTestSaint(
          id: 'h2',
          name: 'Martyr Saint',
          isDoctor: false,
          categories: [SaintCategory.martyr, SaintCategory.healerMissionary],
          patronage: 'Soldiers',
          profession: 'Soldier',
        );

        // Rule 3: Healer/Missionary category
        final missionarySaint = createTestSaint(
          id: 'h3',
          name: 'Missionary Saint',
          isDoctor: false,
          categories: [SaintCategory.healerMissionary, SaintCategory.mystic],
          patronage: 'Doctors',
          profession: 'Physician',
        );

        // Rule 4: Mystic category
        final mysticSaint = createTestSaint(
          id: 'h4',
          name: 'Mystic Saint',
          isDoctor: false,
          categories: [SaintCategory.mystic, SaintCategory.apostle],
          patronage: 'Contemplatives',
          profession: 'Cloistered Nun',
        );

        // Rule 5: Apostle category
        final apostleSaint = createTestSaint(
          id: 'h5',
          name: 'Apostle Saint',
          isDoctor: false,
          categories: [SaintCategory.apostle],
          patronage: 'Fishermen',
          profession: 'Fisherman',
        );

        // Rule 6: Patronage specified (no matching special categories)
        final patronSaint = createTestSaint(
          id: 'h6',
          name: 'Patron Saint',
          isDoctor: false,
          categories: [SaintCategory.laity],
          patronage: 'Carpenters and Workers',
          profession: 'Carpenter',
        );

        // Rule 7: Default fallback to profession (patronage is null or empty)
        final fallbackSaint = createTestSaint(
          id: 'h7',
          name: 'Fallback Saint',
          isDoctor: false,
          categories: [SaintCategory.laity],
          patronage: null,
          profession: 'Humble Weaver',
        );

        final fallbackEmptyPatronage = createTestSaint(
          id: 'h7_empty',
          name: 'Fallback Empty Patronage',
          isDoctor: false,
          categories: [SaintCategory.laity],
          patronage: '',
          profession: 'Hermit Monk',
        );

        final all = [
          doctorSaint,
          martyrSaint,
          missionarySaint,
          mysticSaint,
          apostleSaint,
          patronSaint,
          fallbackSaint,
          fallbackEmptyPatronage,
        ];

        final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
          allSaints: all,
          userVector: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          count: all.length,
        );

        final seedMap = {for (final s in seeds) s.saint.id: s.primaryHighlight};

        expect(
          seedMap['h1'],
          'Doctor of the Church • Deep Theological Wisdom',
          reason:
              'Rule 1: Doctor takes precedence over all other categories and patronage',
        );
        expect(
          seedMap['h2'],
          'Courageous Martyr • Unwavering Fortitude',
          reason: 'Rule 2: Martyr category',
        );
        expect(
          seedMap['h3'],
          'Healer & Missionary • Radiant Christian Charity',
          reason: 'Rule 3: Healer & Missionary category',
        );
        expect(
          seedMap['h4'],
          'Mystic & Contemplative • Intimate Union with God',
          reason: 'Rule 4: Mystic category',
        );
        expect(
          seedMap['h5'],
          'Apostle of Christ • Foundational Pillar of Faith',
          reason: 'Rule 5: Apostle category',
        );
        expect(
          seedMap['h6'],
          'Patron of Carpenters and Workers',
          reason: 'Rule 6: Patronage string',
        );
        expect(
          seedMap['h7'],
          'Humble Weaver',
          reason: 'Rule 7: Fallback to profession when patronage is null',
        );
        expect(
          seedMap['h7_empty'],
          'Hermit Monk',
          reason:
              'Rule 7: Fallback to profession when patronage is empty string',
        );
      });
    });

    group('Tournament Bracket Creation (createTournament)', () {
      Saint makeDummySaint(int seedNum) {
        return Saint(
          id: 'saint_$seedNum',
          name: 'Saint $seedNum',
          nationality: 'Roman',
          profession: 'Saint',
        );
      }

      List<TournamentSeed> generateMockSeeds(int count) {
        return List.generate(
          count,
          (i) => TournamentSeed(
            seed: i + 1,
            saint: makeDummySaint(i + 1),
            matchScore: 0.85,
            primaryHighlight: 'Highlight ${i + 1}',
          ),
        );
      }

      test('Throws ArgumentError when passed fewer than 16 seeds', () {
        expect(
          () => ConfirmationDiscernmentEngine.createTournament([]),
          throwsA(isA<ArgumentError>()),
        );

        final seeds15 = generateMockSeeds(15);
        expect(
          () => ConfirmationDiscernmentEngine.createTournament(seeds15),
          throwsA(isA<ArgumentError>()),
        );
      });

      test(
        'Initializes 4 tournament rounds with canonical NCAA / Grand Slam 16-seed pairings',
        () {
          final seeds16 = generateMockSeeds(16);
          final tournament = ConfirmationDiscernmentEngine.createTournament(
            seeds16,
          );

          expect(tournament.initialSeeds.length, 16);
          expect(tournament.rounds.length, 4);
          expect(tournament.totalMatches, 15);
          expect(tournament.completedMatchCount, 0);
          expect(tournament.isComplete, isFalse);
          expect(tournament.champion, isNull);

          // Verify round counts: Round 0 = 8 matches, Round 1 = 4, Round 2 = 2, Round 3 = 1
          expect(tournament.rounds[0].length, 8);
          expect(tournament.rounds[1].length, 4);
          expect(tournament.rounds[2].length, 2);
          expect(tournament.rounds[3].length, 1);

          // Verify round names
          expect(tournament.rounds[0][0].roundName, 'Round of 16');
          expect(tournament.rounds[1][0].roundName, 'Quarterfinals');
          expect(tournament.rounds[2][0].roundName, 'Semifinals');
          expect(tournament.rounds[3][0].roundName, 'Championship Match');

          // Verify Round 0 canonical pairings:
          // Match 0: [1, 16]
          // Match 1: [8, 9]
          // Match 2: [4, 13]
          // Match 3: [5, 12]
          // Match 4: [2, 15]
          // Match 5: [7, 10]
          // Match 6: [3, 14]
          // Match 7: [6, 11]
          final expectedPairings = [
            [1, 16],
            [8, 9],
            [4, 13],
            [5, 12],
            [2, 15],
            [7, 10],
            [3, 14],
            [6, 11],
          ];

          for (int i = 0; i < 8; i++) {
            final match = tournament.rounds[0][i];
            expect(match.round, 0);
            expect(match.matchIndex, i);
            expect(match.isReady, isTrue);
            expect(match.isDecided, isFalse);
            expect(match.entrant1!.seed, expectedPairings[i][0]);
            expect(match.entrant2!.seed, expectedPairings[i][1]);
          }

          // Verify subsequent rounds initially have null entrants
          for (int r = 1; r < 4; r++) {
            for (final match in tournament.rounds[r]) {
              expect(match.entrant1, isNull);
              expect(match.entrant2, isNull);
              expect(match.winner, isNull);
              expect(match.isReady, isFalse);
            }
          }
        },
      );
    });
  });
}
