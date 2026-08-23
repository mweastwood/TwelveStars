import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/saint_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Saint Model Tests', () {
    test('fromJson and toJson deserialize and serialize correctly', () {
      final json = {
        'id': 'thomas-aquinas',
        'name': 'St. Thomas Aquinas',
        'birthDate': '1225',
        'deathDate': '1274',
        'nationality': 'Italian',
        'profession': 'Dominican Friar & Theologian',
        'isDoctor': true,
        'isBlessed': false,
        'feastDay': 'January 28',
        'patronage': 'Academics, Students, Theologians',
        'summary': 'Author of the Summa Theologiae.',
        'gender': 'male',
      };

      final saint = Saint.fromJson(json);
      expect(saint.id, 'thomas-aquinas');
      expect(saint.name, 'St. Thomas Aquinas');
      expect(saint.birthDate, '1225');
      expect(saint.deathDate, '1274');
      expect(saint.nationality, 'Italian');
      expect(saint.profession, 'Dominican Friar & Theologian');
      expect(saint.isDoctor, true);
      expect(saint.isBlessed, false);
      expect(saint.feastDay, 'January 28');
      expect(saint.patronage, 'Academics, Students, Theologians');
      expect(saint.summary, 'Author of the Summa Theologiae.');
      expect(saint.gender, 'male');
      expect(saint.isMale, isTrue);
      expect(saint.isFemale, isFalse);
      expect(saint.dateRange, '1225 – 1274');

      final serialized = saint.toJson();
      expect(serialized['id'], 'thomas-aquinas');
      expect(serialized['isDoctor'], true);
      expect(serialized['isBlessed'], null);
      expect(serialized['patronage'], 'Academics, Students, Theologians');
      expect(serialized['gender'], 'male');

      const blessedSaint = Saint(
        id: 'laura-vicuna',
        name: 'Blessed Laura Vicuña',
        nationality: 'Chilean / Argentine',
        profession: 'Salesian Pupil & Virgin',
        isBlessed: true,
        gender: 'female',
      );
      expect(blessedSaint.toJson()['isBlessed'], true);
      expect(blessedSaint.gender, 'female');
      expect(blessedSaint.isFemale, isTrue);
      expect(blessedSaint.isMale, isFalse);
      expect(blessedSaint.toJson()['gender'], 'female');
    });

    test('dateRange formats different combinations of dates', () {
      const s1 = Saint(
        id: 's1',
        name: 'Saint 1',
        birthDate: '1200',
        deathDate: '1280',
        nationality: 'German',
        profession: 'Scholar',
      );
      expect(s1.dateRange, '1200 – 1280');

      const s2 = Saint(
        id: 's2',
        name: 'Saint 2',
        birthDate: 'c. 100',
        nationality: 'Roman',
        profession: 'Martyr',
      );
      expect(s2.dateRange, 'b. c. 100');

      const s3 = Saint(
        id: 's3',
        name: 'Saint 3',
        deathDate: '304',
        nationality: 'Roman',
        profession: 'Virgin & Martyr',
      );
      expect(s3.dateRange, 'd. 304');

      const s4 = Saint(
        id: 's4',
        name: 'Saint 4',
        nationality: 'Unknown',
        profession: 'Hermit',
      );
      expect(s4.dateRange, '');
    });
  });

  group('SaintDatabase Unit Tests', () {
    setUp(() {
      SaintDatabase.mockSaints = null;
      SaintDatabase.resetCache();
    });

    test('loadSaints loads bundled assets/saints.json properly', () async {
      final saints = await SaintDatabase.loadSaints();
      expect(saints, isNotEmpty);

      // Verify all 37 Doctors of the Church are present and flagged
      final doctors = saints.where((s) => s.isDoctor).toList();
      expect(doctors.length, 37);

      // Check specific prominent Doctors
      final aquinas = saints.firstWhere((s) => s.id == 'thomas-aquinas');
      expect(aquinas.name, 'St. Thomas Aquinas');
      expect(aquinas.isDoctor, true);

      final therese = saints.firstWhere((s) => s.id == 'therese-of-lisieux');
      expect(therese.name, 'St. Thérèse of Lisieux');
      expect(therese.isDoctor, true);

      final augustine = saints.firstWhere((s) => s.id == 'augustine-of-hippo');
      expect(augustine.name, 'St. Augustine of Hippo');
      expect(augustine.isDoctor, true);

      final irenaeus = saints.firstWhere((s) => s.id == 'irenaeus-of-lyons');
      expect(irenaeus.name, 'St. Irenaeus of Lyons');
      expect(irenaeus.isDoctor, true);
    });

    test('loadSaints uses cache on subsequent calls', () async {
      final saints1 = await SaintDatabase.loadSaints();
      final saints2 = await SaintDatabase.loadSaints();
      expect(identical(saints1, saints2), isTrue);
    });

    test('loadSaints returns mockSaints when set', () async {
      final mock = [
        const Saint(
          id: 'test-saint',
          name: 'Test Saint',
          nationality: 'Testing',
          profession: 'Tester',
          isDoctor: true,
        ),
      ];
      SaintDatabase.mockSaints = mock;
      final saints = await SaintDatabase.loadSaints();
      expect(saints, mock);
    });

    test(
      'loadSaintsFromJson handles empty or invalid JSON string gracefully',
      () {
        expect(SaintDatabase.loadSaintsFromJson(''), isEmpty);
        expect(SaintDatabase.loadSaintsFromJson('invalid json'), isEmpty);
        expect(SaintDatabase.loadSaintsFromJson('{"not": "a list"}'), isEmpty);
      },
    );

    test(
      'searchSaints filters by name, nationality, profession, and patronage',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // Search by name
        final antonyResults = SaintDatabase.searchSaints(
          saints,
          query: 'Padua',
        );
        expect(antonyResults.any((s) => s.id == 'anthony-of-padua'), isTrue);

        // Search by nationality
        final frenchResults = SaintDatabase.searchSaints(
          saints,
          query: 'French',
        );
        expect(
          frenchResults.every(
            (s) =>
                s.nationality.toLowerCase().contains('french') ||
                (s.summary?.toLowerCase().contains('french') ?? false),
          ),
          isTrue,
        );

        // Search by profession
        final popeResults = SaintDatabase.searchSaints(saints, query: 'Pope');
        expect(
          popeResults.any(
            (s) => s.id == 'gregory-the-great' || s.id == 'leo-the-great',
          ),
          isTrue,
        );

        // Search by patronage
        final lostThings = SaintDatabase.searchSaints(
          saints,
          query: 'Lost Things',
        );
        expect(lostThings.any((s) => s.id == 'anthony-of-padua'), isTrue);

        // Multi-word search
        final multiSearch = SaintDatabase.searchSaints(
          saints,
          query: 'Italian Theologian',
        );
        expect(multiSearch.any((s) => s.id == 'thomas-aquinas'), isTrue);
      },
    );

    test(
      'searchSaints finds St. Carlo Acutis and Vietnamese Martyrs',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // Check St. Carlo Acutis presence and queries (both Carlo and Carlos)
        final carlo = saints.firstWhere((s) => s.id == 'carlo-acutis');
        expect(carlo.name, 'St. Carlo Acutis');
        expect(carlo.birthDate, '1991');
        expect(carlo.deathDate, '2006');
        expect(carlo.isDoctor, false);
        expect(carlo.feastDay, 'October 12');

        final carloResults = SaintDatabase.searchSaints(saints, query: 'Carlo');
        expect(carloResults.any((s) => s.id == 'carlo-acutis'), isTrue);

        final carlosResults = SaintDatabase.searchSaints(
          saints,
          query: 'Carlos',
        );
        expect(carlosResults.any((s) => s.id == 'carlo-acutis'), isTrue);

        final programmerResults = SaintDatabase.searchSaints(
          saints,
          query: 'Programmer',
        );
        expect(programmerResults.any((s) => s.id == 'carlo-acutis'), isTrue);

        // Check Vietnamese Martyrs presence and queries
        final vietnamese = saints.firstWhere(
          (s) => s.id == 'vietnamese-martyrs',
        );
        expect(
          vietnamese.name,
          'The Vietnamese Martyrs (St. Andrew Dũng-Lạc & Companions)',
        );
        expect(vietnamese.isDoctor, false);
        expect(vietnamese.feastDay, 'November 24');

        final vietResults = SaintDatabase.searchSaints(
          saints,
          query: 'Vietnamese',
        );
        expect(vietResults.any((s) => s.id == 'vietnamese-martyrs'), isTrue);

        final martyrsResults = SaintDatabase.searchSaints(
          saints,
          query: 'Martyrs',
        );
        expect(martyrsResults.any((s) => s.id == 'vietnamese-martyrs'), isTrue);

        final dungLacResults = SaintDatabase.searchSaints(
          saints,
          query: 'Dũng-Lạc',
        );
        expect(dungLacResults.any((s) => s.id == 'vietnamese-martyrs'), isTrue);
      },
    );

    test(
      'searchSaints finds named angels (Archangels Michael, Gabriel, Raphael)',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // 1. St. Michael the Archangel
        final michael = saints.firstWhere(
          (s) => s.id == 'michael-the-archangel',
        );
        expect(michael.name, 'St. Michael the Archangel');
        expect(michael.isDoctor, false);
        expect(michael.feastDay, 'September 29');
        expect(michael.nationality, 'Angelic / Heavenly');
        expect(
          michael.profession,
          'Archangel, Prince of the Heavenly Host & Defender of the Church',
        );

        final michaelResults = SaintDatabase.searchSaints(
          saints,
          query: 'Michael',
        );
        expect(
          michaelResults.any((s) => s.id == 'michael-the-archangel'),
          isTrue,
        );

        final policeResults = SaintDatabase.searchSaints(
          saints,
          query: 'Police',
        );
        expect(
          policeResults.any((s) => s.id == 'michael-the-archangel'),
          isTrue,
        );

        // 2. St. Gabriel the Archangel
        final gabriel = saints.firstWhere(
          (s) => s.id == 'gabriel-the-archangel',
        );
        expect(gabriel.name, 'St. Gabriel the Archangel');
        expect(gabriel.isDoctor, false);
        expect(gabriel.feastDay, 'September 29');
        expect(gabriel.nationality, 'Angelic / Heavenly');

        final gabrielResults = SaintDatabase.searchSaints(
          saints,
          query: 'Gabriel',
        );
        expect(
          gabrielResults.any((s) => s.id == 'gabriel-the-archangel'),
          isTrue,
        );

        final annunciationResults = SaintDatabase.searchSaints(
          saints,
          query: 'Annunciation',
        );
        expect(
          annunciationResults.any((s) => s.id == 'gabriel-the-archangel'),
          isTrue,
        );

        // 3. St. Raphael the Archangel
        final raphael = saints.firstWhere(
          (s) => s.id == 'raphael-the-archangel',
        );
        expect(raphael.name, 'St. Raphael the Archangel');
        expect(raphael.isDoctor, false);
        expect(raphael.feastDay, 'September 29');
        expect(raphael.nationality, 'Angelic / Heavenly');

        final raphaelResults = SaintDatabase.searchSaints(
          saints,
          query: 'Raphael',
        );
        expect(
          raphaelResults.any((s) => s.id == 'raphael-the-archangel'),
          isTrue,
        );

        final tobiasResults = SaintDatabase.searchSaints(
          saints,
          query: 'Tobias',
        );
        expect(
          tobiasResults.any((s) => s.id == 'raphael-the-archangel'),
          isTrue,
        );

        // 4. Common search for Archangels
        final archangelResults = SaintDatabase.searchSaints(
          saints,
          query: 'Archangel',
        );
        expect(
          archangelResults.any((s) => s.id == 'michael-the-archangel'),
          isTrue,
        );
        expect(
          archangelResults.any((s) => s.id == 'gabriel-the-archangel'),
          isTrue,
        );
        expect(
          archangelResults.any((s) => s.id == 'raphael-the-archangel'),
          isTrue,
        );
      },
    );

    test('searchSaints filters Doctors of the Church correctly', () async {
      final saints = await SaintDatabase.loadSaints();

      final allDoctors = SaintDatabase.searchSaints(saints, doctorsOnly: true);
      expect(allDoctors.length, 37);
      expect(allDoctors.every((s) => s.isDoctor), isTrue);

      final spanishDoctors = SaintDatabase.searchSaints(
        saints,
        query: 'Spanish',
        doctorsOnly: true,
      );
      expect(spanishDoctors.isNotEmpty, isTrue);
      expect(spanishDoctors.every((s) => s.isDoctor), isTrue);
    });

    test('Database maintains exactly 37 Doctors of the Church', () async {
      final saints = await SaintDatabase.loadSaints();
      final doctors = saints.where((s) => s.isDoctor).toList();
      expect(
        doctors.length,
        equals(37),
        reason: 'Expected exactly 37 Doctors of the Church',
      );
    });

    test(
      'loadSaints correctly identifies beatified entries with isBlessed',
      () async {
        final saints = await SaintDatabase.loadSaints();
        final blessedEntries = saints.where((s) => s.isBlessed).toList();

        expect(blessedEntries.length, equals(2));
        for (final blessed in blessedEntries) {
          expect(
            blessed.name.startsWith('Blessed '),
            isTrue,
            reason: '${blessed.name} should start with Blessed',
          );
        }

        final miguelPro = saints.firstWhere((s) => s.id == 'miguel-pro');
        expect(miguelPro.name, 'Blessed Miguel Pro');
        expect(miguelPro.isBlessed, isTrue);

        final lauraVicuna = saints.firstWhere((s) => s.id == 'laura-vicuna');
        expect(lauraVicuna.name, 'Blessed Laura Vicuña');
        expect(lauraVicuna.isBlessed, isTrue);
      },
    );

    test(
      'loadSaints validates expanded dataset size and unique identifiers',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // Database has been doubled from original 92 to >= 187 saints
        expect(saints.length, greaterThanOrEqualTo(187));

        // Invariant: IDs must all be unique and non-empty
        final idSet = <String>{};
        for (final saint in saints) {
          expect(saint.id.isNotEmpty, isTrue);
          expect(saint.name.isNotEmpty, isTrue);
          expect(saint.nationality.isNotEmpty, isTrue);
          expect(saint.profession.isNotEmpty, isTrue);
          expect(
            idSet.add(saint.id),
            isTrue,
            reason: 'Duplicate saint ID found: ${saint.id}',
          );
        }
      },
    );

    test(
      'searchSaints finds newly added saints across historical and geographical categories',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // 1. Early Church Martyrs & Apostles
        final barnabas = SaintDatabase.searchSaints(saints, query: 'Barnabas');
        expect(barnabas.any((s) => s.id == 'barnabas'), isTrue);

        final perpetua = SaintDatabase.searchSaints(saints, query: 'Perpetua');
        expect(perpetua.any((s) => s.id == 'perpetua-and-felicity'), isTrue);

        final nicholas = SaintDatabase.searchSaints(
          saints,
          query: 'Nicholas of Myra',
        );
        expect(nicholas.any((s) => s.id == 'nicholas-of-myra'), isTrue);

        // 2. Desert Fathers & Monastic Pioneers
        final anthonyGreat = SaintDatabase.searchSaints(
          saints,
          query: 'Anthony the Great',
        );
        expect(anthonyGreat.any((s) => s.id == 'anthony-the-great'), isTrue);

        final columba = SaintDatabase.searchSaints(saints, query: 'Columba');
        expect(columba.any((s) => s.id == 'columba-of-iona'), isTrue);

        // 3. Medieval Saints, Sovereigns & Mystics
        final louis = SaintDatabase.searchSaints(saints, query: 'Louis IX');
        expect(louis.any((s) => s.id == 'louis-ix-of-france'), isTrue);

        final rita = SaintDatabase.searchSaints(
          saints,
          query: 'Rita of Cascia',
        );
        expect(rita.any((s) => s.id == 'rita-of-cascia'), isTrue);

        final raymondOfPenafort = SaintDatabase.searchSaints(
          saints,
          query: 'Raymond of Peñafort',
        );
        expect(
          raymondOfPenafort.any((s) => s.id == 'raymond-of-penafort'),
          isTrue,
        );

        final canonLawyers = SaintDatabase.searchSaints(
          saints,
          query: 'Canon Lawyers',
        );
        expect(canonLawyers.any((s) => s.id == 'raymond-of-penafort'), isTrue);

        final raymondNonnatus = SaintDatabase.searchSaints(
          saints,
          query: 'Raymond Nonnatus',
        );
        expect(raymondNonnatus.any((s) => s.id == 'raymond-nonnatus'), isTrue);

        final midwives = SaintDatabase.searchSaints(saints, query: 'Midwives');
        expect(midwives.any((s) => s.id == 'raymond-nonnatus'), isTrue);

        final wenceslaus = SaintDatabase.searchSaints(
          saints,
          query: 'Wenceslaus',
        );
        expect(wenceslaus.any((s) => s.id == 'wenceslaus'), isTrue);

        final peregrine = SaintDatabase.searchSaints(
          saints,
          query: 'Peregrine',
        );
        expect(peregrine.any((s) => s.id == 'peregrine-laziosi'), isTrue);

        final cancer = SaintDatabase.searchSaints(saints, query: 'Cancer');
        expect(cancer.any((s) => s.id == 'peregrine-laziosi'), isTrue);

        // 4. Counter-Reformation & Global Missionaries
        final martinDePorres = SaintDatabase.searchSaints(
          saints,
          query: 'Martin de Porres',
        );
        expect(martinDePorres.any((s) => s.id == 'martin-de-porres'), isTrue);

        final juanDiego = SaintDatabase.searchSaints(
          saints,
          query: 'Juan Diego',
        );
        expect(juanDiego.any((s) => s.id == 'juan-diego'), isTrue);

        final peterClaver = SaintDatabase.searchSaints(
          saints,
          query: 'Peter Claver',
        );
        expect(peterClaver.any((s) => s.id == 'peter-claver'), isTrue);

        final gerard = SaintDatabase.searchSaints(
          saints,
          query: 'Gerard Majella',
        );
        expect(gerard.any((s) => s.id == 'gerard-majella'), isTrue);

        final expectantMothers = SaintDatabase.searchSaints(
          saints,
          query: 'Expectant Mothers',
        );
        expect(expectantMothers.any((s) => s.id == 'gerard-majella'), isTrue);

        // 5. 19th & 20th Century Saints & Global Martyrs
        final charbel = SaintDatabase.searchSaints(saints, query: 'Charbel');
        expect(charbel.any((s) => s.id == 'charbel-makhlouf'), isTrue);

        final vianney = SaintDatabase.searchSaints(saints, query: 'Vianney');
        expect(vianney.any((s) => s.id == 'john-vianney'), isTrue);

        final korean = SaintDatabase.searchSaints(saints, query: 'Korean');
        expect(korean.any((s) => s.id == 'korean-martyrs'), isTrue);

        final ugandan = SaintDatabase.searchSaints(saints, query: 'Ugandan');
        expect(
          ugandan.any((s) => s.id == 'charles-lwanga-and-ugandan-martyrs'),
          isTrue,
        );

        final romero = SaintDatabase.searchSaints(saints, query: 'Romero');
        expect(romero.any((s) => s.id == 'oscar-romero'), isTrue);

        final mackillop = SaintDatabase.searchSaints(
          saints,
          query: 'MacKillop',
        );
        expect(mackillop.any((s) => s.id == 'mary-mackillop'), isTrue);
      },
    );

    test(
      'getSaintById retrieves saint by ID or returns null if not found',
      () async {
        final aquinas = await SaintDatabase.getSaintById('thomas-aquinas');
        expect(aquinas, isNotNull);
        expect(aquinas!.id, 'thomas-aquinas');
        expect(aquinas.name, 'St. Thomas Aquinas');

        final cyprian = await SaintDatabase.getSaintById('cyprian-of-carthage');
        expect(cyprian, isNotNull);
        expect(cyprian!.id, 'cyprian-of-carthage');
        expect(cyprian.name, 'St. Cyprian of Carthage');

        final vincent = await SaintDatabase.getSaintById('vincent-of-lerins');
        expect(vincent, isNotNull);
        expect(vincent!.id, 'vincent-of-lerins');
        expect(vincent.name, 'St. Vincent of Lérins');

        final montfort = await SaintDatabase.getSaintById(
          'louis-marie-de-montfort',
        );
        expect(montfort, isNotNull);
        expect(montfort!.id, 'louis-marie-de-montfort');
        expect(montfort.name, 'St. Louis-Marie de Montfort');

        final piusV = await SaintDatabase.getSaintById('pius-v');
        expect(piusV, isNotNull);
        expect(piusV!.id, 'pius-v');
        expect(piusV.name, 'St. Pius V (Antonio Ghislieri)');

        final nonExistent = await SaintDatabase.getSaintById(
          'unknown-saint-id',
        );
        expect(nonExistent, isNull);
      },
    );

    test(
      'buildFeastDayMap and getSaintsForDate correctly match feast days',
      () async {
        final saints = await SaintDatabase.loadSaints();
        final feastMap = SaintDatabase.buildFeastDayMap(saints);

        // 1. Single-date feast: St. Thomas Aquinas (January 28)
        final jan28Saints = SaintDatabase.getSaintsForDate(
          DateTime(2026, 1, 28),
          saints,
        );
        expect(jan28Saints.any((s) => s.id == 'thomas-aquinas'), isTrue);
        expect(feastMap['1_28']!.any((s) => s.id == 'thomas-aquinas'), isTrue);

        // 2. Multi-date feast: St. John the Baptist ("June 24 / August 29")
        final jun24Saints = SaintDatabase.getSaintsForDate(
          DateTime(2026, 6, 24),
          saints,
        );
        final aug29Saints = SaintDatabase.getSaintsForDate(
          DateTime(2026, 8, 29),
          saints,
        );
        expect(jun24Saints.any((s) => s.id == 'john-the-baptist'), isTrue);
        expect(aug29Saints.any((s) => s.id == 'john-the-baptist'), isTrue);
        expect(
          feastMap['6_24']!.any((s) => s.id == 'john-the-baptist'),
          isTrue,
        );
        expect(
          feastMap['8_29']!.any((s) => s.id == 'john-the-baptist'),
          isTrue,
        );

        // Multi-date feast: St. Joseph ("March 19 / May 1")
        final mar19Saints = SaintDatabase.getSaintsForDate(
          DateTime(2026, 3, 19),
          saints,
        );
        final may1Saints = SaintDatabase.getSaintsForDate(
          DateTime(2026, 5, 1),
          saints,
        );
        expect(mar19Saints.any((s) => s.id == 'joseph'), isTrue);
        expect(may1Saints.any((s) => s.id == 'joseph'), isTrue);
        expect(feastMap['3_19']!.any((s) => s.id == 'joseph'), isTrue);
        expect(feastMap['5_1']!.any((s) => s.id == 'joseph'), isTrue);

        // 3. Days with multiple saints: September 29 (Archangels Michael, Gabriel, Raphael)
        final sep29Saints = SaintDatabase.getSaintsForDate(
          DateTime(2026, 9, 29),
          saints,
        );
        expect(sep29Saints.length, greaterThanOrEqualTo(3));
        expect(sep29Saints.any((s) => s.id == 'michael-the-archangel'), isTrue);
        expect(sep29Saints.any((s) => s.id == 'gabriel-the-archangel'), isTrue);
        expect(sep29Saints.any((s) => s.id == 'raphael-the-archangel'), isTrue);
        expect(feastMap['9_29']!.length, greaterThanOrEqualTo(3));

        // June 29: Peter and Paul
        final jun29Saints = SaintDatabase.getSaintsForDate(
          DateTime(2026, 6, 29),
          saints,
        );
        expect(jun29Saints.any((s) => s.id == 'peter-the-apostle'), isTrue);
        expect(jun29Saints.any((s) => s.id == 'paul-the-apostle'), isTrue);

        // 4. Date without saints
        final jul4Saints = SaintDatabase.getSaintsForDate(
          DateTime(2026, 7, 4),
          saints,
        );
        expect(jul4Saints, isEmpty);
        expect(feastMap.containsKey('7_4'), isFalse);
      },
    );

    test(
      'loadSaints validates that all saints have valid gender attributes',
      () async {
        final saints = await SaintDatabase.loadSaints();
        expect(saints, isNotEmpty);

        final validGenders = {'male', 'female', 'group', 'other'};
        for (final saint in saints) {
          expect(
            saint.gender,
            isNotNull,
            reason: '${saint.id} should have non-null gender',
          );
          expect(
            validGenders.contains(saint.gender),
            isTrue,
            reason:
                '${saint.id} has invalid gender ${saint.gender}, expected male, female, or group',
          );
        }

        final femaleSaints = saints.where((s) => s.isFemale).toList();
        final maleSaints = saints.where((s) => s.isMale).toList();
        final groupSaints = saints.where((s) => s.gender == 'group').toList();
        final otherGenderSaints = saints
            .where((s) => s.gender == 'other')
            .toList();

        expect(femaleSaints.length, 43);
        expect(maleSaints.length, 146);
        expect(groupSaints.length, 4);
        expect(otherGenderSaints.length, 3);

        // Verify angels have gender 'other'
        final michael = saints.firstWhere(
          (s) => s.id == 'michael-the-archangel',
        );
        expect(michael.gender, 'other');
        expect(michael.isMale, isFalse);
        expect(michael.isFemale, isFalse);

        final gabriel = saints.firstWhere(
          (s) => s.id == 'gabriel-the-archangel',
        );
        expect(gabriel.gender, 'other');

        final raphael = saints.firstWhere(
          (s) => s.id == 'raphael-the-archangel',
        );
        expect(raphael.gender, 'other');

        // Verify specific prominent female saints
        final mary = saints.firstWhere((s) => s.id == 'mary-mother-of-god');
        expect(mary.gender, 'female');
        expect(mary.isFemale, isTrue);

        final agnes = saints.firstWhere((s) => s.id == 'agnes-of-rome');
        expect(agnes.gender, 'female');
        expect(agnes.isFemale, isTrue);

        final therese = saints.firstWhere((s) => s.id == 'therese-of-lisieux');
        expect(therese.gender, 'female');
        expect(therese.isFemale, isTrue);

        // Verify specific group saints
        final vietnamese = saints.firstWhere(
          (s) => s.id == 'vietnamese-martyrs',
        );
        expect(vietnamese.gender, 'group');
        expect(vietnamese.isMale, isFalse);
        expect(vietnamese.isFemale, isFalse);
      },
    );

    test('searchSaints filters by gender and combined criteria', () async {
      final saints = await SaintDatabase.loadSaints();

      // 1. Male saints filter
      final men = SaintDatabase.searchSaints(saints, gender: 'male');
      expect(men.length, 146);
      expect(men.every((s) => s.isMale), isTrue);

      // 2. Female saints filter
      final women = SaintDatabase.searchSaints(saints, gender: 'female');
      expect(women.length, 43);
      expect(women.every((s) => s.isFemale), isTrue);

      // 3. Female Doctors of the Church (4 total)
      final femaleDoctors = SaintDatabase.searchSaints(
        saints,
        gender: 'female',
        doctorsOnly: true,
      );
      expect(femaleDoctors.length, 4);
      expect(femaleDoctors.every((s) => s.isDoctor && s.isFemale), isTrue);
      expect(femaleDoctors.map((s) => s.id).toSet(), {
        'catherine-of-siena',
        'hildegard-of-bingen',
        'teresa-of-avila',
        'therese-of-lisieux',
      });

      // 4. Male Doctors of the Church (33 total)
      final maleDoctors = SaintDatabase.searchSaints(
        saints,
        gender: 'male',
        doctorsOnly: true,
      );
      expect(maleDoctors.length, 33);
      expect(maleDoctors.every((s) => s.isDoctor && s.isMale), isTrue);

      // 5. Keyword search matching gender terms
      final womenKeywords = SaintDatabase.searchSaints(saints, query: 'women');
      expect(womenKeywords.length, greaterThanOrEqualTo(42));
      expect(womenKeywords.any((s) => s.id == 'agnes-of-rome'), isTrue);

      final menKeywords = SaintDatabase.searchSaints(saints, query: 'men');
      expect(menKeywords.length, greaterThanOrEqualTo(149));
      expect(menKeywords.any((s) => s.id == 'thomas-aquinas'), isTrue);

      // 6. Search with gender + query
      final frenchWomen = SaintDatabase.searchSaints(
        saints,
        query: 'French',
        gender: 'female',
      );
      expect(frenchWomen.isNotEmpty, isTrue);
      expect(frenchWomen.every((s) => s.isFemale), isTrue);
      expect(frenchWomen.any((s) => s.id == 'joan-of-arc'), isTrue);
      expect(frenchWomen.any((s) => s.id == 'therese-of-lisieux'), isTrue);
    });

    test(
      'Saint category classification and icon mapping works properly',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // Doctors
        final aquinas = saints.firstWhere((s) => s.id == 'thomas-aquinas');
        expect(aquinas.category, SaintCategory.doctor);

        // Angels
        final michael = saints.firstWhere(
          (s) => s.id == 'michael-the-archangel',
        );
        expect(michael.category, SaintCategory.angel);
        expect(michael.categoryIcon, Icons.flare_rounded);

        final gabriel = saints.firstWhere(
          (s) => s.id == 'gabriel-the-archangel',
        );
        expect(gabriel.category, SaintCategory.angel);

        // Apostles
        final peter = saints.firstWhere((s) => s.id == 'peter-the-apostle');
        expect(peter.category, SaintCategory.apostle);
        expect(peter.categoryIcon, Icons.stars_rounded);

        final paul = saints.firstWhere((s) => s.id == 'paul-the-apostle');
        expect(paul.category, SaintCategory.apostle);

        // Evangelists
        final luke = saints.firstWhere((s) => s.id == 'luke-the-evangelist');
        expect(luke.category, SaintCategory.evangelist);
        expect(luke.categoryIcon, Icons.auto_stories_rounded);

        final mark = saints.firstWhere((s) => s.id == 'mark-the-evangelist');
        expect(mark.category, SaintCategory.evangelist);

        // Martyrs
        final agnes = saints.firstWhere((s) => s.id == 'agnes-of-rome');
        expect(agnes.category, SaintCategory.martyr);

        // Popes
        final piusV = saints.firstWhere((s) => s.id == 'pius-v');
        expect(piusV.category, SaintCategory.pope);
        expect(piusV.categoryIcon, Icons.vpn_key_rounded);

        final johnPaulII = saints.firstWhere((s) => s.id == 'john-paul-ii');
        expect(johnPaulII.category, SaintCategory.pope);

        // Bishops
        final nicholas = saints.firstWhere((s) => s.id == 'nicholas-of-myra');
        expect(nicholas.category, SaintCategory.bishop);
        expect(nicholas.categoryIcon, Icons.account_balance_rounded);

        final borromeo = saints.firstWhere((s) => s.id == 'charles-borromeo');
        expect(borromeo.category, SaintCategory.bishop);

        // Martyrs (including martyr bishops like Cyprian)
        final cyprian = saints.firstWhere((s) => s.id == 'cyprian-of-carthage');
        expect(cyprian.category, SaintCategory.martyr);

        // Priests & Religious
        final francis = saints.firstWhere((s) => s.id == 'francis-of-assisi');
        expect(francis.category, SaintCategory.priestReligious);

        // Monarchs / Royalty
        final louis = saints.firstWhere((s) => s.id == 'louis-ix-of-france');
        expect(louis.category, SaintCategory.monarch);
      },
    );

    test(
      'Saint approximateYear and era parsing work across historical periods',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // Early Church (<= 500)
        final polycarp = saints.firstWhere((s) => s.id == 'polycarp-of-smyrna');
        expect(polycarp.era, SaintEra.earlyChurch);

        // Medieval (501 - 1499)
        final aquinas = saints.firstWhere((s) => s.id == 'thomas-aquinas');
        expect(aquinas.era, SaintEra.medieval);

        // Reformation / Early Modern (1500 - 1799)
        final aloysius = saints.firstWhere((s) => s.id == 'aloysius-gonzaga');
        expect(aloysius.era, SaintEra.reformation);

        // Modern (1800+)
        final carlo = saints.firstWhere((s) => s.id == 'carlo-acutis');
        expect(carlo.era, SaintEra.modern);
        expect(carlo.approximateYear, 2006);
      },
    );

    test(
      'searchSaints sorts properly across all SaintSortOption values',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // 1. Name Ascending (A-Z)
        final nameAsc = SaintDatabase.searchSaints(
          saints,
          sortBy: SaintSortOption.nameAsc,
        );
        expect(nameAsc.first.name.compareTo(nameAsc.last.name), lessThan(0));

        // 2. Name Descending (Z-A)
        final nameDesc = SaintDatabase.searchSaints(
          saints,
          sortBy: SaintSortOption.nameDesc,
        );
        expect(
          nameDesc.first.name.compareTo(nameDesc.last.name),
          greaterThan(0),
        );

        // 3. Feast Day (Jan - Dec)
        final feastSorted = SaintDatabase.searchSaints(
          saints,
          sortBy: SaintSortOption.feastDay,
        );
        expect(feastSorted.first.feastMonth, 1); // January
        expect(feastSorted.last.feastMonth, 12); // December

        // 4. Chronological Ascending (Oldest first)
        final chronoAsc = SaintDatabase.searchSaints(
          saints,
          sortBy: SaintSortOption.chronologicalAsc,
        );
        expect(chronoAsc.first.approximateYear, lessThanOrEqualTo(100));

        // 5. Chronological Descending (Newest first)
        final chronoDesc = SaintDatabase.searchSaints(
          saints,
          sortBy: SaintSortOption.chronologicalDesc,
        );
        expect(chronoDesc.first.approximateYear, greaterThanOrEqualTo(2000));

        // 6. Doctors First
        final doctorsFirst = SaintDatabase.searchSaints(
          saints,
          sortBy: SaintSortOption.doctorsFirst,
        );
        expect(doctorsFirst.first.isDoctor, isTrue);
      },
    );

    test(
      'searchSaints filters by category, era, and feastMonth correctly',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // Category filter: Martyrs
        final martyrs = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.martyr,
        );
        expect(
          martyrs.every((s) => s.category == SaintCategory.martyr),
          isTrue,
        );

        // Category filter: Angels
        final angels = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.angel,
        );
        expect(angels.length, 3);
        expect(angels.every((s) => s.category == SaintCategory.angel), isTrue);
        expect(angels.any((s) => s.id == 'michael-the-archangel'), isTrue);

        // Category filter: Apostles (Biblical Apostles & Apostle to the Apostles)
        final apostles = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.apostle,
        );
        expect(apostles.length, 15);
        expect(
          apostles.every((s) => s.category == SaintCategory.apostle),
          isTrue,
        );
        expect(apostles.any((s) => s.id == 'peter-the-apostle'), isTrue);
        expect(apostles.any((s) => s.id == 'paul-the-apostle'), isTrue);
        expect(apostles.any((s) => s.id == 'andrew-the-apostle'), isTrue);
        expect(apostles.any((s) => s.id == 'james-the-greater'), isTrue);
        expect(apostles.any((s) => s.id == 'james-the-lesser'), isTrue);
        expect(apostles.any((s) => s.id == 'john-the-apostle'), isTrue);
        expect(apostles.any((s) => s.id == 'philip-the-apostle'), isTrue);
        expect(apostles.any((s) => s.id == 'bartholomew-the-apostle'), isTrue);
        expect(apostles.any((s) => s.id == 'thomas-the-apostle'), isTrue);
        expect(apostles.any((s) => s.id == 'matthew-the-apostle'), isTrue);
        expect(apostles.any((s) => s.id == 'jude-thaddeus'), isTrue);
        expect(apostles.any((s) => s.id == 'simon-the-zealot'), isTrue);
        expect(apostles.any((s) => s.id == 'matthias'), isTrue);
        expect(apostles.any((s) => s.id == 'barnabas'), isTrue);
        expect(apostles.any((s) => s.id == 'mary-magdalene'), isTrue);

        // Non-biblical saints with honorary "Apostle of..." titles should not be in apostle category
        expect(apostles.any((s) => s.id == 'patrick-of-ireland'), isFalse);
        expect(apostles.any((s) => s.id == 'aidan-of-lindisfarne'), isFalse);
        expect(apostles.any((s) => s.id == 'francis-xavier'), isFalse);
        expect(apostles.any((s) => s.id == 'columba-of-iona'), isFalse);
        expect(apostles.any((s) => s.id == 'damien-of-molokai'), isFalse);
        expect(apostles.any((s) => s.id == 'junipero-serra'), isFalse);
        expect(apostles.any((s) => s.id == 'philip-neri'), isFalse);
        expect(apostles.any((s) => s.id == 'carlo-acutis'), isFalse);

        // Category filter: Evangelists
        final evangelists = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.evangelist,
        );
        expect(evangelists.length, 2);
        expect(
          evangelists.every((s) => s.category == SaintCategory.evangelist),
          isTrue,
        );
        expect(evangelists.any((s) => s.id == 'luke-the-evangelist'), isTrue);
        expect(evangelists.any((s) => s.id == 'mark-the-evangelist'), isTrue);

        // Category filter: Popes
        final popes = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.pope,
        );
        expect(popes.length, 7);
        expect(popes.every((s) => s.category == SaintCategory.pope), isTrue);
        expect(popes.any((s) => s.id == 'pius-v'), isTrue);
        expect(popes.any((s) => s.id == 'pius-x'), isTrue);
        expect(popes.any((s) => s.id == 'john-paul-ii'), isTrue);
        expect(popes.any((s) => s.id == 'clement-of-rome'), isTrue);

        // Category filter: Bishops
        final bishops = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.bishop,
        );
        expect(bishops.length, 15);
        expect(
          bishops.every((s) => s.category == SaintCategory.bishop),
          isTrue,
        );
        expect(bishops.any((s) => s.id == 'nicholas-of-myra'), isTrue);
        expect(bishops.any((s) => s.id == 'charles-borromeo'), isTrue);
        expect(bishops.any((s) => s.id == 'patrick-of-ireland'), isTrue);
        expect(bishops.any((s) => s.id == 'aidan-of-lindisfarne'), isTrue);

        // Era filter: Modern
        final modernSaints = SaintDatabase.searchSaints(
          saints,
          era: SaintEra.modern,
        );
        expect(modernSaints.every((s) => s.era == SaintEra.modern), isTrue);

        // Feast Month filter: October (Month 10)
        final octoberSaints = SaintDatabase.searchSaints(
          saints,
          feastMonth: 10,
        );
        expect(octoberSaints.every((s) => s.feastMonth == 10), isTrue);
        expect(octoberSaints.any((s) => s.id == 'therese-of-lisieux'), isTrue);
        expect(octoberSaints.any((s) => s.id == 'francis-of-assisi'), isTrue);
        expect(octoberSaints.any((s) => s.id == 'carlo-acutis'), isTrue);
      },
    );

    test(
      'all saints in the dataset are assigned a specific, non-generic category',
      () async {
        final saints = await SaintDatabase.loadSaints();
        final unclassified = saints
            .where((s) => s.category == SaintCategory.other)
            .toList();
        expect(
          unclassified,
          isEmpty,
          reason:
              'All saints should be classified into a specific category, but found unclassified: ${unclassified.map((s) => s.id).toList()}',
        );

        // Verify Holy Family
        final mary = saints.firstWhere((s) => s.id == 'mary-mother-of-god');
        expect(mary.category, SaintCategory.holyFamily);
        expect(mary.categoryIcon, Icons.family_restroom_rounded);
        expect(mary.isFemale, isTrue);

        final joseph = saints.firstWhere((s) => s.id == 'joseph');
        expect(joseph.category, SaintCategory.holyFamily);
        expect(joseph.categoryIcon, Icons.family_restroom_rounded);

        // Verify Laity
        final dominicSavio = saints.firstWhere((s) => s.id == 'dominic-savio');
        expect(dominicSavio.category, SaintCategory.laity);
        expect(dominicSavio.categoryIcon, Icons.groups_rounded);

        final gianna = saints.firstWhere((s) => s.id == 'gianna-beretta-molla');
        expect(gianna.category, SaintCategory.laity);

        // Verify Mystics & Visionaries
        final faustina = saints.firstWhere((s) => s.id == 'faustina-kowalska');
        expect(faustina.category, SaintCategory.mystic);

        final bernadette = saints.firstWhere(
          (s) => s.id == 'bernadette-soubirous',
        );
        expect(bernadette.category, SaintCategory.mystic);
      },
    );

    test(
      'all saints follow standard name prefixing conventions and no saint starts with Pope St.',
      () async {
        final saints = await SaintDatabase.loadSaints();
        const validPrefixes = ['St. ', 'Sts. ', 'Blessed ', 'The '];

        for (final saint in saints) {
          expect(
            saint.name.startsWith('Pope St.'),
            isFalse,
            reason:
                'Saint ${saint.id} (${saint.name}) should not start with "Pope St."',
          );
          expect(
            validPrefixes.any((prefix) => saint.name.startsWith(prefix)),
            isTrue,
            reason:
                'Saint ${saint.id} (${saint.name}) should start with one of: $validPrefixes',
          );
        }
      },
    );
  });
}
