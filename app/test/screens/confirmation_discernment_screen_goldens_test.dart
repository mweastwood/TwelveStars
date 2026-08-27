import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/screens/confirmation_discernment_screen.dart';
import '../test_helper.dart';

/// Returns 16 deterministic mock saints suitable for driving the full
/// discernment quiz + tournament flow without touching the asset bundle.
List<Saint> _buildMockSaints() {
  return [
    const Saint(
      id: 'thomas-aquinas',
      name: 'St. Thomas Aquinas',
      birthDate: '1225',
      deathDate: '1274',
      nationality: 'Italian',
      profession: 'Philosopher, Theologian',
      feastDay: 'January 28',
      patronage: 'Students, Universities',
      summary:
          'An Italian Dominican friar and the foremost scholastic theologian, called the Angelic Doctor.',
      isDoctor: true,
      gender: 'male',
      categories: [SaintCategory.doctor, SaintCategory.priest],
    ),
    const Saint(
      id: 'therese-of-lisieux',
      name: 'St. Thérèse of Lisieux',
      birthDate: '1873',
      deathDate: '1897',
      nationality: 'French',
      profession: 'Carmelite Nun',
      feastDay: 'October 1',
      patronage: 'Missions, Florists',
      summary:
          'Known as the Little Flower, she taught the "Little Way" of spiritual childhood.',
      isDoctor: true,
      gender: 'female',
      categories: [SaintCategory.doctor, SaintCategory.nun],
    ),
    const Saint(
      id: 'francis-of-assisi',
      name: 'St. Francis of Assisi',
      birthDate: '1181',
      deathDate: '1226',
      nationality: 'Italian',
      profession: 'Friar, Founder',
      feastDay: 'October 4',
      patronage: 'Animals, Environment',
      summary: 'Founder of the Franciscan Order and lover of creation.',
      isDoctor: false,
      gender: 'male',
      categories: [SaintCategory.brother],
    ),
    const Saint(
      id: 'joan-of-arc',
      name: 'St. Joan of Arc',
      birthDate: '1412',
      deathDate: '1431',
      nationality: 'French',
      profession: 'Military Leader, Martyr',
      feastDay: 'May 30',
      patronage: 'France, Soldiers',
      summary:
          'A peasant girl who led French armies by divine visions and was martyred at 19.',
      isDoctor: false,
      gender: 'female',
      categories: [SaintCategory.martyr],
    ),
    const Saint(
      id: 'augustine-of-hippo',
      name: 'St. Augustine of Hippo',
      birthDate: '354',
      deathDate: '430',
      nationality: 'Numidian',
      profession: 'Bishop, Doctor',
      feastDay: 'August 28',
      patronage: 'Brewers, Theologians',
      summary:
          'One of the greatest Doctors of the Church, author of Confessions and City of God.',
      isDoctor: true,
      gender: 'male',
      categories: [SaintCategory.doctor, SaintCategory.bishop],
    ),
    const Saint(
      id: 'dominic-guzman',
      name: 'St. Dominic',
      birthDate: '1170',
      deathDate: '1221',
      nationality: 'Spanish',
      profession: 'Friar, Founder',
      feastDay: 'August 8',
      patronage: 'Astronomers, Dominican Republic',
      summary: 'Founder of the Order of Preachers (Dominicans).',
      isDoctor: false,
      gender: 'male',
      categories: [SaintCategory.priest],
    ),
    const Saint(
      id: 'ignatius-of-loyola',
      name: 'St. Ignatius of Loyola',
      birthDate: '1491',
      deathDate: '1556',
      nationality: 'Spanish',
      profession: 'Priest, Founder',
      feastDay: 'July 31',
      patronage: 'Jesuits, Spiritual Exercises',
      summary: 'Founder of the Society of Jesus (Jesuits).',
      isDoctor: false,
      gender: 'male',
      categories: [SaintCategory.priest],
    ),
    const Saint(
      id: 'catherine-of-siena',
      name: 'St. Catherine of Siena',
      birthDate: '1347',
      deathDate: '1380',
      nationality: 'Italian',
      profession: 'Mystic, Doctor',
      feastDay: 'April 29',
      patronage: 'Italy, Nurses',
      summary: 'A Dominican tertiary and Doctor of the Church.',
      isDoctor: true,
      gender: 'female',
      categories: [SaintCategory.doctor, SaintCategory.mystic],
    ),
    const Saint(
      id: 'maximilian-kolbe',
      name: 'St. Maximilian Kolbe',
      birthDate: '1894',
      deathDate: '1941',
      nationality: 'Polish',
      profession: 'Franciscan Friar, Martyr',
      feastDay: 'August 14',
      patronage: 'Drug Addicts, Families',
      summary:
          'A Franciscan friar who gave his life in Auschwitz to save another prisoner.',
      isDoctor: false,
      gender: 'male',
      categories: [SaintCategory.martyr, SaintCategory.priest],
    ),
    const Saint(
      id: 'teresa-of-avila',
      name: 'St. Teresa of Ávila',
      birthDate: '1515',
      deathDate: '1582',
      nationality: 'Spanish',
      profession: 'Carmelite Nun, Doctor',
      feastDay: 'October 15',
      patronage: 'Headache Sufferers, Spain',
      summary:
          'First woman named Doctor of the Church, reformer of the Carmelite Order.',
      isDoctor: true,
      gender: 'female',
      categories: [
        SaintCategory.doctor,
        SaintCategory.mystic,
        SaintCategory.nun,
      ],
    ),
    const Saint(
      id: 'john-bosco',
      name: 'St. John Bosco',
      birthDate: '1815',
      deathDate: '1888',
      nationality: 'Italian',
      profession: 'Priest, Educator',
      feastDay: 'January 31',
      patronage: 'Youth, Apprentices',
      summary: 'Founder of the Salesians, devoted his life to youth education.',
      isDoctor: false,
      gender: 'male',
      categories: [SaintCategory.priest],
    ),
    const Saint(
      id: 'padre-pio',
      name: 'St. Padre Pio',
      birthDate: '1887',
      deathDate: '1968',
      nationality: 'Italian',
      profession: 'Capuchin Friar',
      feastDay: 'September 23',
      patronage: 'Stress, Civil Defense',
      summary: 'A Capuchin friar who bore the stigmata for 50 years.',
      isDoctor: false,
      gender: 'male',
      categories: [SaintCategory.priest, SaintCategory.mystic],
    ),
    const Saint(
      id: 'kateri-tekakwitha',
      name: 'St. Kateri Tekakwitha',
      birthDate: '1656',
      deathDate: '1680',
      nationality: 'Mohawk-Algonquin',
      profession: 'Lay Virgin',
      feastDay: 'July 14',
      patronage: 'Ecology, Indigenous People',
      summary:
          'The first Native American to be canonized, known as the Lily of the Mohawks.',
      isDoctor: false,
      gender: 'female',
      categories: [SaintCategory.virgin, SaintCategory.laity],
    ),
    const Saint(
      id: 'luigi-gonzaga',
      name: 'St. Aloysius Gonzaga',
      birthDate: '1568',
      deathDate: '1591',
      nationality: 'Italian',
      profession: 'Jesuit Scholastic',
      feastDay: 'June 21',
      patronage: 'Youth, AIDS Patients',
      summary:
          'Patron of youth and students who died at 23 while caring for plague victims.',
      isDoctor: false,
      gender: 'male',
      categories: [SaintCategory.laity, SaintCategory.martyr],
    ),
    const Saint(
      id: 'cecilia',
      name: 'St. Cecilia',
      birthDate: 'Unknown',
      deathDate: 'c. 230',
      nationality: 'Roman',
      profession: 'Virgin Martyr',
      feastDay: 'November 22',
      patronage: 'Musicians, Singers',
      summary: 'Early Christian martyr and patron saint of musicians.',
      isDoctor: false,
      gender: 'female',
      categories: [SaintCategory.martyr, SaintCategory.virgin],
    ),
    const Saint(
      id: 'peter-apostle',
      name: 'St. Peter the Apostle',
      birthDate: 'c. 1 BC',
      deathDate: 'c. 68 AD',
      nationality: 'Galilean',
      profession: 'Fisherman, Apostle, Pope',
      feastDay: 'June 29',
      patronage: 'Popes, Fishermen',
      summary: 'Chief of the Apostles and first Bishop of Rome.',
      isDoctor: false,
      gender: 'male',
      categories: [SaintCategory.apostle, SaintCategory.pope],
    ),
  ];
}

void main() {
  group('ConfirmationDiscernmentScreen Golden Tests', () {
    setUp(() {
      SaintDatabase.mockSaints = _buildMockSaints();
      ConfirmationDiscernmentEngine.mockQuestions = null;
      ConfirmationDiscernmentEngine.mockRandom = null;
    });

    tearDown(() {
      SaintDatabase.mockSaints = null;
      ConfirmationDiscernmentEngine.mockQuestions = null;
      ConfirmationDiscernmentEngine.mockRandom = null;
    });

    testGoldens(
      'renders Quiz Stage — Question 1 (light theme, no answer selected)',
      (tester) async {
        final mockQuestions = [
          ConfirmationDiscernmentEngine.questionBank.firstWhere(
            (q) => q.id == 'q25_daily_calling',
          ),
          ...ConfirmationDiscernmentEngine.questionBank
              .where((q) => q.id != 'q25_daily_calling')
              .take(6),
        ];

        await tester.pumpWidgetBuilder(
          ConfirmationDiscernmentScreen(initialQuestions: mockQuestions),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(400, 800),
        );
        // Allow the async initialization to complete
        await tester.pump();
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'confirmation_discernment_quiz_q1_golden',
        );
      },
    );

    testGoldens(
      'renders Quiz Stage — Question 1 with option 0 selected (dark theme)',
      (tester) async {
        final mockQuestions = [
          ConfirmationDiscernmentEngine.questionBank.firstWhere(
            (q) => q.id == 'q26_geographic_calling',
          ),
          ...ConfirmationDiscernmentEngine.questionBank
              .where((q) => q.id != 'q26_geographic_calling')
              .take(6),
        ];

        await tester.pumpWidgetBuilder(
          ConfirmationDiscernmentScreen(initialQuestions: mockQuestions),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(400, 800),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // Select the first option
        await tester.tap(find.byKey(const Key('discernment_option_0')));
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'confirmation_discernment_quiz_selected_dark_golden',
        );
      },
    );

    testGoldens('renders Tournament Stage — Match 1 of 15 (light theme)', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const ConfirmationDiscernmentScreen(),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
        ),
        surfaceSize: const Size(480, 860),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Answer all 7 questions (always option 0) to enter tournament
      for (int q = 0; q < 7; q++) {
        await tester.tap(find.byKey(const Key('discernment_option_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('discernment_next_button')));
        await tester.pumpAndSettle();
      }

      // Now in tournament stage — capture Match 1 of 15
      expect(find.text('Saint Showdown'), findsOneWidget);

      await screenMatchesGolden(
        tester,
        'confirmation_discernment_tournament_match1_golden',
      );
    });

    testGoldens('renders Tournament Stage — Match 1 of 15 (dark theme)', (
      tester,
    ) async {
      await tester.pumpWidgetBuilder(
        const ConfirmationDiscernmentScreen(),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
        ),
        surfaceSize: const Size(480, 860),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      for (int q = 0; q < 7; q++) {
        await tester.tap(find.byKey(const Key('discernment_option_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('discernment_next_button')));
        await tester.pumpAndSettle();
      }

      expect(find.text('Saint Showdown'), findsOneWidget);

      await screenMatchesGolden(
        tester,
        'confirmation_discernment_tournament_match1_dark_golden',
      );
    });

    testGoldens(
      'renders Champion Stage after completing all 15 matches (light theme)',
      (tester) async {
        await tester.pumpWidgetBuilder(
          const ConfirmationDiscernmentScreen(),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(480, 960),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // Answer 7 quiz questions
        for (int q = 0; q < 7; q++) {
          await tester.tap(find.byKey(const Key('discernment_option_0')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('discernment_next_button')));
          await tester.pumpAndSettle();
        }

        // Play all 15 matches, always choosing entrant 1
        for (int m = 0; m < 15; m++) {
          await tester.tap(find.byKey(const Key('entrant_1_select_button')));
          await tester.pumpAndSettle();
        }

        // Now in champion stage
        expect(find.text('Confirmation Patron Chosen'), findsOneWidget);

        await screenMatchesGolden(
          tester,
          'confirmation_discernment_champion_golden',
        );
      },
    );

    testGoldens(
      'renders Champion Stage after completing all 15 matches (dark theme)',
      (tester) async {
        await tester.pumpWidgetBuilder(
          const ConfirmationDiscernmentScreen(),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(480, 960),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        for (int q = 0; q < 7; q++) {
          await tester.tap(find.byKey(const Key('discernment_option_0')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('discernment_next_button')));
          await tester.pumpAndSettle();
        }

        for (int m = 0; m < 15; m++) {
          await tester.tap(find.byKey(const Key('entrant_1_select_button')));
          await tester.pumpAndSettle();
        }

        expect(find.text('Confirmation Patron Chosen'), findsOneWidget);

        await screenMatchesGolden(
          tester,
          'confirmation_discernment_champion_dark_golden',
        );
      },
    );
  });
}
