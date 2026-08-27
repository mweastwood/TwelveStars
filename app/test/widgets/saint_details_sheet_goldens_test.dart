import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart' hide materialAppWrapper;
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';
import '../test_helper.dart';

Saint _makeSaint({
  String id = 'thomas-aquinas',
  String name = 'St. Thomas Aquinas',
  String birthDate = '1225',
  String deathDate = '1274',
  String nationality = 'Italian',
  String profession = 'Philosopher, Theologian',
  String? feastDay = 'January 28',
  String? patronage = 'Students, Universities',
  String? summary,
  bool isDoctor = true,
  String? gender = 'male',
  List<SaintCategory> categories = const [
    SaintCategory.doctor,
    SaintCategory.priest,
  ],
}) {
  return Saint(
    id: id,
    name: name,
    birthDate: birthDate,
    deathDate: deathDate,
    nationality: nationality,
    profession: profession,
    feastDay: feastDay,
    patronage: patronage,
    summary:
        summary ??
        'Thomas Aquinas was an Italian Dominican friar and priest, an influential philosopher, theologian, and jurist in the tradition of scholasticism, within which he is also known as the "Doctor Angelicus" (the Angelic Doctor) and "Doctor Communis" (the Common Doctor). He is considered the foremost Western thinker, combining the theological principles of faith with the philosophical principles of reason.',
    isDoctor: isDoctor,
    gender: gender,
    categories: categories,
  );
}

void main() {
  group('SaintDetailsSheet Golden Tests', () {
    testGoldens(
      'renders SaintDetailsSheet for Doctor of the Church (light theme)',
      (tester) async {
        final saint = _makeSaint();

        await tester.pumpWidgetBuilder(
          Scaffold(body: SaintDetailsSheet(saint: saint)),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(450, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'saint_details_sheet_doctor_light_golden',
        );
      },
    );

    testGoldens(
      'renders SaintDetailsSheet for Doctor of the Church (dark theme)',
      (tester) async {
        final saint = _makeSaint();

        await tester.pumpWidgetBuilder(
          Scaffold(body: SaintDetailsSheet(saint: saint)),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(450, 800),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'saint_details_sheet_doctor_dark_golden',
        );
      },
    );

    testGoldens(
      'renders SaintDetailsSheet for a martyr saint without patronage',
      (tester) async {
        final saint = _makeSaint(
          id: 'agnes-of-rome',
          name: 'St. Agnes of Rome',
          birthDate: 'c. 291',
          deathDate: 'c. 304',
          nationality: 'Roman',
          profession: 'Virgin Martyr',
          feastDay: 'January 21',
          patronage: null,
          summary:
              'Agnes of Rome was a member of the Roman nobility and an early Christian martyr who was executed for her faith at the age of twelve or thirteen. She is the patron saint of chastity, girls, engaged couples, and rape survivors.',
          isDoctor: false,
          gender: 'female',
          categories: const [SaintCategory.martyr, SaintCategory.virgin],
        );

        await tester.pumpWidgetBuilder(
          Scaffold(body: SaintDetailsSheet(saint: saint)),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(450, 700),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'saint_details_sheet_martyr_golden');
      },
    );

    testGoldens(
      'renders SaintDetailsSheet for an Old Testament prophet (no St. prefix, no isDoctor badge)',
      (tester) async {
        final saint = _makeSaint(
          id: 'elijah-the-prophet',
          name: 'Elijah the Prophet',
          birthDate: 'c. 900 BC',
          deathDate: 'Unknown (taken up to heaven)',
          nationality: 'Israelite',
          profession: 'Prophet',
          feastDay: 'July 20',
          patronage: 'Carmelite Order, Bosnia',
          summary:
              'Elijah was a prophet and miracle worker who lived in the northern kingdom of Israel during the reign of King Ahab. His confrontation with the prophets of Baal on Mount Carmel is among the most dramatic scenes in the Old Testament.',
          isDoctor: false,
          gender: 'male',
          categories: const [SaintCategory.prophet],
        );

        await tester.pumpWidgetBuilder(
          Scaffold(body: SaintDetailsSheet(saint: saint)),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(450, 700),
        );
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'saint_details_sheet_ot_prophet_golden',
        );
      },
    );
  });
}
