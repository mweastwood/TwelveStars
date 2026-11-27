import 'package:material_ui/material_ui.dart';
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
  String? wikipediaUrl = 'https://en.wikipedia.org/wiki/Thomas_Aquinas',
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
    wikipediaUrl: wikipediaUrl,
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

    testGoldens(
      'renders SaintDetailsSheet scrolled to show Read on Wikipedia button',
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

        final wikiButton = find.byKey(const Key('saint_wikipedia_link_button'));
        expect(wikiButton, findsOneWidget);
        await tester.ensureVisible(wikiButton);
        await tester.pumpAndSettle();

        await screenMatchesGolden(
          tester,
          'saint_details_sheet_wikipedia_link_golden',
        );
      },
    );

    testGoldens(
      'renders SaintDetailsSheet for Mary with all 6 Marian sprites and switches active portrait on tap',
      (tester) async {
        final mary = _makeSaint(
          id: 'mary-mother-of-god',
          name: 'Blessed Virgin Mary (Our Lady)',
          birthDate: 'c. 20 BC',
          deathDate: 'c. 48 AD',
          nationality: 'Judean / Heavenly',
          profession:
              'Mother of God (Theotokos), Spouse of the Holy Spirit & Queen of All Saints',
          feastDay: 'January 1 / August 15 / December 8',
          patronage:
              'All Humanity, The Catholic Church, Mothers, Pro-Life, The Americas (Our Lady of Guadalupe)',
          summary:
              'The Mother of Jesus Christ and Mother of God (Theotokos). Conceived without original sin and assumed body and soul into heavenly glory, she is the Queen of Heaven and Queen of All Saints.',
          isDoctor: false,
          gender: 'female',
          wikipediaUrl: 'https://en.wikipedia.org/wiki/Mary%2C_mother_of_Jesus',
          categories: const [
            SaintCategory.holyFamily,
            SaintCategory.virgin,
            SaintCategory.mystic,
          ],
        );

        await tester.pumpWidgetBuilder(
          Scaffold(body: SaintDetailsSheet(saint: mary)),
          wrapper: materialAppWrapper(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
          ),
          surfaceSize: const Size(450, 900),
        );
        await tester.pumpAndSettle();

        expect(find.text('Marian Titles'), findsOneWidget);
        expect(find.text('Our Lady of Grace'), findsOneWidget);

        // Tap Our Lady of Guadalupe (index 2) to verify header portrait updates
        await tester.tap(find.byKey(const Key('saint_sprite_variant_2')));
        await tester.pumpAndSettle();

        expect(find.text('Our Lady of Guadalupe'), findsOneWidget);

        await screenMatchesGolden(tester, 'saint_details_sheet_mary_golden');
      },
    );
  });
}
