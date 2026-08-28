import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
        'categories': ['doctor', 'priest', 'mystic'],
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
      expect(saint.categories, [
        SaintCategory.doctor,
        SaintCategory.priest,
        SaintCategory.mystic,
      ]);
      expect(saint.isDoctor, true);
      expect(saint.isBlessed, false);
      expect(saint.feastDay, 'January 28');
      expect(saint.patronage, 'Academics, Students, Theologians');
      expect(saint.summary, 'Author of the Summa Theologiae.');
      expect(saint.gender, 'male');
      expect(saint.isMale, isTrue);
      expect(saint.isFemale, isFalse);
      expect(saint.dateRange, '1225 – 1274');
      expect(saint.shortName, 'Thomas Aquinas');

      const testBlessedSaint = Saint(
        id: 'carlo-acutis',
        name: 'Blessed Carlo Acutis',
        nationality: 'Italian',
        profession: 'Gamer & Computer Programmer',
      );
      expect(testBlessedSaint.shortName, 'Carlo Acutis');

      const testGroupSaint = Saint(
        id: 'vietnamese-martyrs',
        name: 'The Vietnamese Martyrs',
        nationality: 'Vietnamese',
        profession: 'Martyrs',
      );
      expect(testGroupSaint.shortName, 'Vietnamese Martyrs');
      expect(testGroupSaint.invocationName, 'The Vietnamese Martyrs');

      const testPluralSaint = Saint(
        id: 'perpetua-felicity',
        name: 'Sts. Perpetua and Felicity',
        nationality: 'Roman',
        profession: 'Martyrs',
      );
      expect(testPluralSaint.shortName, 'Perpetua and Felicity');
      expect(testPluralSaint.invocationName, 'Sts. Perpetua and Felicity');

      const testAbbrevBlessedSaint = Saint(
        id: 'bl-pier-giorgio',
        name: 'Bl. Pier Giorgio Frassati',
        nationality: 'Italian',
        profession: 'Lay Dominican',
      );
      expect(testAbbrevBlessedSaint.shortName, 'Pier Giorgio Frassati');
      expect(
        testAbbrevBlessedSaint.invocationName,
        'Bl. Pier Giorgio Frassati',
      );

      const testVenerableSaint = Saint(
        id: 'venerable-fulton-sheen',
        name: 'Venerable Fulton Sheen',
        nationality: 'American',
        profession: 'Archbishop',
      );
      expect(testVenerableSaint.shortName, 'Fulton Sheen');
      expect(testVenerableSaint.invocationName, 'Venerable Fulton Sheen');

      const testVenSaint = Saint(
        id: 'ven-alois',
        name: 'Ven. Aloysius',
        nationality: 'Italian',
        profession: 'Monk',
      );
      expect(testVenSaint.shortName, 'Aloysius');
      expect(testVenSaint.invocationName, 'Ven. Aloysius');

      const testOtSaint = Saint(
        id: 'moses-the-prophet',
        name: 'Moses the Prophet',
        birthDate: 'c. 1527 BC',
        deathDate: 'c. 1407 BC',
        nationality: 'Israelite',
        profession: 'Prophet',
      );
      expect(testOtSaint.shortName, 'Moses the Prophet');
      expect(testOtSaint.invocationName, 'Moses the Prophet');

      final serialized = saint.toJson();
      expect(serialized['id'], 'thomas-aquinas');
      expect(serialized['categories'], ['doctor', 'priest', 'mystic']);
      expect(serialized['isDoctor'], true);
      expect(serialized['isBlessed'], null);
      expect(serialized['patronage'], 'Academics, Students, Theologians');
      expect(serialized['gender'], 'male');

      const blessedSaint = Saint(
        id: 'laura-vicuna',
        name: 'Blessed Laura Vicuña',
        nationality: 'Chilean / Argentine',
        profession: 'Salesian Pupil & Virgin',
        categories: [SaintCategory.laity, SaintCategory.virgin],
        isBlessed: true,
        gender: 'female',
      );
      expect(blessedSaint.toJson()['isBlessed'], true);
      expect(blessedSaint.toJson()['categories'], ['virgin', 'laity']);
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

    test(
      'approximateYear correctly parses various date formats using precompiled regexes',
      () {
        const millenniumBc = Saint(
          id: 'm-bc',
          name: 'Millennium BC Saint',
          birthDate: '2nd millennium BC',
          nationality: 'Ancient',
          profession: 'Patriarch',
        );
        expect(millenniumBc.approximateYear, -1500);

        const millenniumAd = Saint(
          id: 'm-ad',
          name: 'Millennium AD Saint',
          birthDate: '1st millennium',
          nationality: 'Ancient',
          profession: 'Patriarch',
        );
        expect(millenniumAd.approximateYear, 500);

        const centuryBc = Saint(
          id: 'c-bc',
          name: 'Century BC Saint',
          birthDate: '5th century BC',
          nationality: 'Ancient',
          profession: 'Prophet',
        );
        expect(centuryBc.approximateYear, -450);

        const centuryAd = Saint(
          id: 'c-ad',
          name: 'Century AD Saint',
          birthDate: '4th c.',
          nationality: 'Roman',
          profession: 'Bishop',
        );
        expect(centuryAd.approximateYear, 350);

        const yearNumeric = Saint(
          id: 'y-num',
          name: 'Numeric Year Saint',
          deathDate: '1274',
          nationality: 'Italian',
          profession: 'Doctor',
        );
        expect(yearNumeric.approximateYear, 1274);

        const yearBcNumeric = Saint(
          id: 'y-bc-num',
          name: 'Numeric Year BC Saint',
          deathDate: 'c. 1407 BC',
          nationality: 'Israelite',
          profession: 'Prophet',
        );
        expect(yearBcNumeric.approximateYear, -1407);

        const angelicSaint = Saint(
          id: 'angelic',
          name: 'Angel Saint',
          nationality: 'Angelic / Heavenly',
          profession: 'Archangel',
        );
        expect(angelicSaint.approximateYear, -9999);
      },
    );

    test(
      'feastMonth and feastDayOfMonth parse feast days using precompiled regex',
      () {
        const saintWithFeast = Saint(
          id: 'feast-test',
          name: 'Feast Saint',
          feastDay: 'October 12',
          nationality: 'Italian',
          profession: 'Programmer',
        );
        expect(saintWithFeast.feastMonth, 10);
        expect(saintWithFeast.feastDayOfMonth, 12);

        const saintWithoutFeast = Saint(
          id: 'no-feast',
          name: 'No Feast Saint',
          nationality: 'Unknown',
          profession: 'Unknown',
        );
        expect(saintWithoutFeast.feastMonth, isNull);
        expect(saintWithoutFeast.feastDayOfMonth, isNull);

        const invalidFeast = Saint(
          id: 'inv-feast',
          name: 'Invalid Feast',
          feastDay: 'NotADate',
          nationality: 'Unknown',
          profession: 'Unknown',
        );
        expect(invalidFeast.feastMonth, isNull);
        expect(invalidFeast.feastDayOfMonth, isNull);
      },
    );

    test(
      'computeCategories detects angel category using precompiled angel regex',
      () {
        final categories = Saint.computeCategories(
          id: 'custom-angel',
          name: 'Holy Angel of Peace',
          nationality: 'Heavenly',
          profession: 'Archangel messenger',
        );
        expect(categories, contains(SaintCategory.angel));
      },
    );
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
        expect(saints.where((s) => s.isBlessed), isEmpty);
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

        expect(femaleSaints.length, 42);
        expect(maleSaints.length, 174);
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
      expect(men.length, 174);
      expect(men.every((s) => s.isMale), isTrue);

      // 2. Female saints filter
      final women = SaintDatabase.searchSaints(saints, gender: 'female');
      expect(women.length, 42);
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

        // Bishops & Martyrs
        final cyprian = saints.firstWhere((s) => s.id == 'cyprian-of-carthage');
        expect(cyprian.category, SaintCategory.bishop);
        expect(cyprian.categories, contains(SaintCategory.martyr));

        // Priests, Brothers & Religious
        final francis = saints.firstWhere((s) => s.id == 'francis-of-assisi');
        expect(francis.category, SaintCategory.brother);

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
          martyrs.every((s) => s.categories.contains(SaintCategory.martyr)),
          isTrue,
        );
        expect(martyrs.any((s) => s.id == 'agnes-of-rome'), isTrue);
        expect(martyrs.any((s) => s.id == 'thomas-more'), isTrue);
        expect(martyrs.any((s) => s.id == 'wenceslaus'), isTrue);

        // Category filter: Angels
        final angels = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.angel,
        );
        expect(angels.length, 3);
        expect(
          angels.every((s) => s.categories.contains(SaintCategory.angel)),
          isTrue,
        );
        expect(angels.any((s) => s.id == 'michael-the-archangel'), isTrue);

        // Category filter: Apostles (Biblical Apostles & Apostle to the Apostles)
        final apostles = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.apostle,
        );
        expect(apostles.length, 15);
        expect(
          apostles.every((s) => s.categories.contains(SaintCategory.apostle)),
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
        expect(evangelists.length, 4); // Matthew, Mark, Luke, John
        expect(
          evangelists.every(
            (s) => s.categories.contains(SaintCategory.evangelist),
          ),
          isTrue,
        );
        expect(evangelists.any((s) => s.id == 'luke-the-evangelist'), isTrue);
        expect(evangelists.any((s) => s.id == 'mark-the-evangelist'), isTrue);
        expect(evangelists.any((s) => s.id == 'matthew-the-apostle'), isTrue);
        expect(evangelists.any((s) => s.id == 'john-the-apostle'), isTrue);

        // Category filter: Popes
        final popes = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.pope,
        );
        expect(popes.length, greaterThanOrEqualTo(7));
        expect(
          popes.every((s) => s.categories.contains(SaintCategory.pope)),
          isTrue,
        );
        expect(popes.any((s) => s.id == 'pius-v'), isTrue);
        expect(popes.any((s) => s.id == 'pius-x'), isTrue);
        expect(popes.any((s) => s.id == 'john-paul-ii'), isTrue);
        expect(popes.any((s) => s.id == 'clement-of-rome'), isTrue);
        expect(popes.any((s) => s.id == 'peter-the-apostle'), isTrue);

        // Category filter: Bishops
        final bishops = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.bishop,
        );
        expect(
          bishops.every((s) => s.categories.contains(SaintCategory.bishop)),
          isTrue,
        );
        expect(bishops.any((s) => s.id == 'nicholas-of-myra'), isTrue);
        expect(bishops.any((s) => s.id == 'charles-borromeo'), isTrue);
        expect(bishops.any((s) => s.id == 'patrick-of-ireland'), isTrue);
        expect(bishops.any((s) => s.id == 'aidan-of-lindisfarne'), isTrue);
        expect(bishops.any((s) => s.id == 'augustine-of-hippo'), isTrue);
        expect(bishops.any((s) => s.id == 'alphonsus-liguori'), isTrue);

        // Category filter: Mystics & Contemplatives
        final mystics = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.mystic,
        );
        expect(
          mystics.every((s) => s.categories.contains(SaintCategory.mystic)),
          isTrue,
        );
        expect(mystics.any((s) => s.id == 'padre-pio'), isTrue);
        expect(mystics.any((s) => s.id == 'john-of-the-cross'), isTrue);
        expect(mystics.any((s) => s.id == 'faustina-kowalska'), isTrue);
        expect(mystics.any((s) => s.id == 'catherine-of-siena'), isTrue);

        // Category filter: Healers & Missionaries
        final healers = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.healerMissionary,
        );
        expect(
          healers.every(
            (s) => s.categories.contains(SaintCategory.healerMissionary),
          ),
          isTrue,
        );
        expect(healers.any((s) => s.id == 'gianna-beretta-molla'), isTrue);
        expect(healers.any((s) => s.id == 'giuseppe-moscati'), isTrue);
        expect(healers.any((s) => s.id == 'francis-xavier'), isTrue);
        expect(healers.any((s) => s.id == 'mother-teresa'), isTrue);

        // Category filter: Rulers & Monarchs
        final monarchs = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.monarch,
        );
        expect(
          monarchs.every((s) => s.categories.contains(SaintCategory.monarch)),
          isTrue,
        );
        expect(monarchs.any((s) => s.id == 'louis-ix-of-france'), isTrue);
        expect(monarchs.any((s) => s.id == 'wenceslaus'), isTrue);
        expect(monarchs.any((s) => s.id == 'edward-the-confessor'), isTrue);

        // Category filter: Virgins & Consecrated
        final virgins = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.virgin,
        );
        expect(
          virgins.every((s) => s.categories.contains(SaintCategory.virgin)),
          isTrue,
        );
        expect(virgins.any((s) => s.id == 'agnes-of-rome'), isTrue);
        expect(virgins.any((s) => s.id == 'kateri-tekakwitha'), isTrue);
        expect(virgins.any((s) => s.id == 'maria-goretti'), isTrue);
        expect(virgins.any((s) => s.id == 'cecilia'), isTrue);

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
        expect(dominicSavio.categories, contains(SaintCategory.laity));
        expect(dominicSavio.categories, contains(SaintCategory.virgin));

        final gianna = saints.firstWhere((s) => s.id == 'gianna-beretta-molla');
        expect(gianna.categories, contains(SaintCategory.laity));
        expect(gianna.categories, contains(SaintCategory.healerMissionary));

        // Verify Mystics & Visionaries
        final faustina = saints.firstWhere((s) => s.id == 'faustina-kowalska');
        expect(faustina.categories, contains(SaintCategory.mystic));
        expect(faustina.categories, contains(SaintCategory.nun));

        final bernadette = saints.firstWhere(
          (s) => s.id == 'bernadette-soubirous',
        );
        expect(bernadette.categories, contains(SaintCategory.mystic));
        expect(bernadette.categories, contains(SaintCategory.nun));
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
          if (saint.era == SaintEra.oldCovenant) {
            // Old Testament figures do not use "St." title
            expect(
              saint.name.startsWith('St. '),
              isFalse,
              reason:
                  'Old Covenant figure ${saint.id} (${saint.name}) should not start with "St."',
            );
          } else {
            expect(
              validPrefixes.any((prefix) => saint.name.startsWith(prefix)),
              isTrue,
              reason:
                  'Saint ${saint.id} (${saint.name}) should start with one of: $validPrefixes',
            );
          }
        }
      },
    );

    test(
      'multi-category resolution resolves dual and triple category memberships correctly',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // 1. Priests that are also mystics
        final padrePio = saints.firstWhere((s) => s.id == 'padre-pio');
        expect(padrePio.categories, contains(SaintCategory.mystic));
        expect(padrePio.categories, contains(SaintCategory.priest));

        // 2. Doctor, mystic, and priest
        final johnOfTheCross = saints.firstWhere(
          (s) => s.id == 'john-of-the-cross',
        );
        expect(johnOfTheCross.categories, contains(SaintCategory.doctor));
        expect(johnOfTheCross.categories, contains(SaintCategory.mystic));
        expect(johnOfTheCross.categories, contains(SaintCategory.priest));

        // 3. Martyrs that were also laity
        final thomasMore = saints.firstWhere((s) => s.id == 'thomas-more');
        expect(thomasMore.categories, contains(SaintCategory.martyr));
        expect(thomasMore.categories, contains(SaintCategory.laity));

        // 4. St. Dominic Savio: Virgin, Laity
        final dominicSavio = saints.firstWhere((s) => s.id == 'dominic-savio');
        expect(dominicSavio.categories, contains(SaintCategory.laity));
        expect(dominicSavio.categories, contains(SaintCategory.virgin));

        // 5. Doctor and Bishop
        final augustine = saints.firstWhere(
          (s) => s.id == 'augustine-of-hippo',
        );
        expect(augustine.categories, contains(SaintCategory.doctor));
        expect(augustine.categories, contains(SaintCategory.bishop));

        final alphonsus = saints.firstWhere((s) => s.id == 'alphonsus-liguori');
        expect(alphonsus.categories, contains(SaintCategory.doctor));
        expect(alphonsus.categories, contains(SaintCategory.bishop));

        final anselm = saints.firstWhere((s) => s.id == 'anselm-of-canterbury');
        expect(anselm.categories, contains(SaintCategory.doctor));
        expect(anselm.categories, contains(SaintCategory.bishop));

        final bonaventure = saints.firstWhere((s) => s.id == 'bonaventure');
        expect(bonaventure.categories, contains(SaintCategory.doctor));
        expect(bonaventure.categories, contains(SaintCategory.bishop));

        // 6. St. Teresa of Ávila & St. Catherine of Siena
        final teresaAvila = saints.firstWhere((s) => s.id == 'teresa-of-avila');
        expect(teresaAvila.categories, contains(SaintCategory.doctor));
        expect(teresaAvila.categories, contains(SaintCategory.mystic));
        expect(teresaAvila.categories, contains(SaintCategory.virgin));
        expect(teresaAvila.categories, contains(SaintCategory.nun));

        final catherineSiena = saints.firstWhere(
          (s) => s.id == 'catherine-of-siena',
        );
        expect(catherineSiena.categories, contains(SaintCategory.doctor));
        expect(catherineSiena.categories, contains(SaintCategory.mystic));
        expect(catherineSiena.categories, contains(SaintCategory.virgin));
        expect(catherineSiena.categories, contains(SaintCategory.nun));

        // 7. St. Gianna: Laity & Healer
        final gianna = saints.firstWhere((s) => s.id == 'gianna-beretta-molla');
        expect(gianna.categories, contains(SaintCategory.laity));
        expect(gianna.categories, contains(SaintCategory.healerMissionary));

        // 8. Rulers & Monarchs
        final wenceslaus = saints.firstWhere((s) => s.id == 'wenceslaus');
        expect(wenceslaus.categories, contains(SaintCategory.martyr));
        expect(wenceslaus.categories, contains(SaintCategory.monarch));

        final louisIX = saints.firstWhere((s) => s.id == 'louis-ix-of-france');
        expect(louisIX.categories, contains(SaintCategory.monarch));
        expect(louisIX.categories, contains(SaintCategory.laity));

        // 9. Apostles who were also Martyrs / Popes / Evangelists / Missionaries
        final peter = saints.firstWhere((s) => s.id == 'peter-the-apostle');
        expect(peter.categories, contains(SaintCategory.apostle));
        expect(peter.categories, contains(SaintCategory.pope));
        expect(peter.categories, contains(SaintCategory.martyr));

        final paul = saints.firstWhere((s) => s.id == 'paul-the-apostle');
        expect(paul.categories, contains(SaintCategory.apostle));
        expect(paul.categories, contains(SaintCategory.martyr));
        expect(paul.categories, contains(SaintCategory.healerMissionary));

        final matthew = saints.firstWhere((s) => s.id == 'matthew-the-apostle');
        expect(matthew.categories, contains(SaintCategory.apostle));
        expect(matthew.categories, contains(SaintCategory.evangelist));
        expect(matthew.categories, contains(SaintCategory.martyr));

        // 10. Popes who are Martyrs
        final clement = saints.firstWhere((s) => s.id == 'clement-of-rome');
        expect(clement.categories, contains(SaintCategory.pope));
        expect(clement.categories, contains(SaintCategory.martyr));

        final piusV = saints.firstWhere((s) => s.id == 'pius-v');
        expect(piusV.categories, contains(SaintCategory.pope));

        // 11. Holy Family: Mary & Joseph
        final mary = saints.firstWhere((s) => s.id == 'mary-mother-of-god');
        expect(mary.categories, contains(SaintCategory.holyFamily));
        expect(mary.categories, contains(SaintCategory.mystic));
        expect(mary.categories, contains(SaintCategory.virgin));
        expect(mary.categories.contains(SaintCategory.laity), isFalse);

        final joseph = saints.firstWhere((s) => s.id == 'joseph');
        expect(joseph.categories, contains(SaintCategory.holyFamily));
        expect(joseph.categories.contains(SaintCategory.laity), isFalse);

        // 12. Missionaries & Healers: Mother Teresa, Damien, Cabrini, Martin de Porres
        final motherTeresa = saints.firstWhere((s) => s.id == 'mother-teresa');
        expect(
          motherTeresa.categories,
          contains(SaintCategory.healerMissionary),
        );
        expect(motherTeresa.categories, contains(SaintCategory.mystic));
        expect(motherTeresa.categories, contains(SaintCategory.virgin));
        expect(motherTeresa.categories, contains(SaintCategory.nun));

        final damien = saints.firstWhere((s) => s.id == 'damien-of-molokai');
        expect(damien.categories, contains(SaintCategory.healerMissionary));
        expect(damien.categories, contains(SaintCategory.priest));

        // 13. Deacons: Stephen, Lawrence, Ephrem
        final stephen = saints.firstWhere(
          (s) => s.id == 'stephen-first-martyr',
        );
        expect(stephen.categories, contains(SaintCategory.deacon));
        expect(stephen.categories, contains(SaintCategory.martyr));

        final lawrence = saints.firstWhere((s) => s.id == 'lawrence-of-rome');
        expect(lawrence.categories, contains(SaintCategory.deacon));
        expect(lawrence.categories, contains(SaintCategory.martyr));

        final ephrem = saints.firstWhere((s) => s.id == 'ephrem-the-syrian');
        expect(ephrem.categories, contains(SaintCategory.doctor));
        expect(ephrem.categories, contains(SaintCategory.deacon));

        // 14. Groups with mixed states of life
        final vietnamese = saints.firstWhere(
          (s) => s.id == 'vietnamese-martyrs',
        );
        expect(vietnamese.categories, contains(SaintCategory.group));
        expect(vietnamese.categories, contains(SaintCategory.bishop));
        expect(vietnamese.categories, contains(SaintCategory.priest));
        expect(vietnamese.categories, contains(SaintCategory.brother));
        expect(vietnamese.categories, contains(SaintCategory.martyr));
        expect(vietnamese.categories, contains(SaintCategory.laity));

        final korean = saints.firstWhere((s) => s.id == 'korean-martyrs');
        expect(korean.categories, contains(SaintCategory.group));
        expect(korean.categories, contains(SaintCategory.bishop));
        expect(korean.categories, contains(SaintCategory.priest));
        expect(korean.categories, contains(SaintCategory.martyr));
        expect(korean.categories, contains(SaintCategory.laity));

        final paulMiki = saints.firstWhere(
          (s) => s.id == 'paul-miki-and-companions',
        );
        expect(paulMiki.categories, contains(SaintCategory.group));
        expect(paulMiki.categories, contains(SaintCategory.priest));
        expect(paulMiki.categories, contains(SaintCategory.brother));
        expect(paulMiki.categories, contains(SaintCategory.martyr));
        expect(paulMiki.categories, contains(SaintCategory.laity));
      },
    );

    test(
      'searchSaints text search matches keywords across all assigned category labels',
      () async {
        final saints = await SaintDatabase.loadSaints();

        // Search for "Mystic" should find Padre Pio and John of the Cross
        final mysticResults = SaintDatabase.searchSaints(
          saints,
          query: 'Mystic',
        );
        expect(mysticResults.any((s) => s.id == 'padre-pio'), isTrue);
        expect(mysticResults.any((s) => s.id == 'john-of-the-cross'), isTrue);
        expect(mysticResults.any((s) => s.id == 'faustina-kowalska'), isTrue);

        // Search for "Monarch" should find Louis IX and Wenceslaus
        final monarchResults = SaintDatabase.searchSaints(
          saints,
          query: 'Monarch',
        );
        expect(monarchResults.any((s) => s.id == 'louis-ix-of-france'), isTrue);
        expect(monarchResults.any((s) => s.id == 'wenceslaus'), isTrue);

        // Search for "Healer" should find Gianna and Luke
        final healerResults = SaintDatabase.searchSaints(
          saints,
          query: 'Healer',
        );
        expect(
          healerResults.any((s) => s.id == 'gianna-beretta-molla'),
          isTrue,
        );
        expect(healerResults.any((s) => s.id == 'luke-the-evangelist'), isTrue);
      },
    );

    test(
      'every saint entry in assets/saints.json contains a non-empty categories array with valid enum values',
      () async {
        final file = File('assets/saints.json');
        final jsonString = file.readAsStringSync();
        final list = jsonDecode(jsonString) as List<dynamic>;

        expect(list, isNotEmpty);
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          expect(
            map.containsKey('categories'),
            isTrue,
            reason: 'Saint ${map['id']} should have a categories key',
          );
          final categories = map['categories'] as List<dynamic>;
          expect(
            categories,
            isNotEmpty,
            reason: 'Saint ${map['id']} should have at least one category',
          );

          for (final catName in categories) {
            final matchedEnum = SaintCategory.values
                .cast<SaintCategory?>()
                .firstWhere((c) => c?.name == catName, orElse: () => null);
            expect(
              matchedEnum,
              isNotNull,
              reason:
                  'Saint ${map['id']} has invalid category string: "$catName"',
            );
          }
        }
      },
    );

    test('no saint can be labeled as apostle and laity simultaneously', () async {
      final saints = await SaintDatabase.loadSaints();
      for (final saint in saints) {
        final isApostle = saint.categories.contains(SaintCategory.apostle);
        final isLaity = saint.categories.contains(SaintCategory.laity);
        expect(
          isApostle && isLaity,
          isFalse,
          reason:
              'Saint ${saint.id} (${saint.name}) cannot be labeled as both apostle and laity simultaneously',
        );
      }

      // Also test dynamic category inference on individual Saint models
      for (final id in const [
        'andrew-the-apostle',
        'barnabas',
        'bartholomew-the-apostle',
        'james-the-greater',
        'james-the-lesser',
        'john-the-apostle',
        'jude-thaddeus',
        'mary-magdalene',
        'matthew-the-apostle',
        'matthias',
        'paul-the-apostle',
        'peter-the-apostle',
        'philip-the-apostle',
        'simon-the-zealot',
        'thomas-the-apostle',
      ]) {
        final inferred = Saint.computeCategories(
          id: id,
          name: 'Apostle Test',
          nationality: 'Galilean',
          profession: 'Fisherman & Apostle',
        );
        expect(inferred.contains(SaintCategory.apostle), isTrue);
        expect(
          inferred.contains(SaintCategory.laity),
          isFalse,
          reason: 'Inferred categories for $id must not include laity',
        );
      }
    });

    test('Old Covenant figures category inference does not include laity', () {
      final otEntries = [
        (
          'abraham-the-patriarch',
          'Abraham the Patriarch',
          'Hebrew',
          'Patriarch & Father of Faith',
          SaintCategory.patriarch,
        ),
        (
          'job-the-righteous',
          'Job the Righteous',
          'Uzite / Ancient Near East',
          'Patriarch & Man of Patience',
          SaintCategory.patriarch,
        ),
        (
          'moses-the-prophet',
          'Moses the Prophet',
          'Hebrew / Israelite',
          'Prophet, Lawgiver & Leader of Israel',
          SaintCategory.prophet,
        ),
        (
          'elijah-the-prophet',
          'Elijah the Prophet',
          'Israelite',
          'Prophet & Spiritual Father of the Carmelites',
          SaintCategory.prophet,
        ),
        (
          'elisha-the-prophet',
          'Elisha the Prophet',
          'Israelite',
          'Prophet & Wonderworker',
          SaintCategory.prophet,
        ),
        (
          'isaiah-the-prophet',
          'Isaiah the Prophet',
          'Judean',
          'Major Prophet & Martyr',
          SaintCategory.prophet,
        ),
        (
          'jeremiah-the-prophet',
          'Jeremiah the Prophet',
          'Judean',
          'Major Prophet & Author',
          SaintCategory.prophet,
        ),
        (
          'daniel-the-prophet',
          'Daniel the Prophet',
          'Judean',
          'Major Prophet & Court Official',
          SaintCategory.prophet,
        ),
        (
          'samuel-the-prophet',
          'Samuel the Prophet',
          'Israelite',
          'Prophet & Judge',
          SaintCategory.prophet,
        ),
        (
          'david-the-king',
          'David the King & Prophet',
          'Israelite',
          'King of Israel, Prophet & Psalmist',
          SaintCategory.prophet,
        ),
      ];

      for (final entry in otEntries) {
        final inferred = Saint.computeCategories(
          id: entry.$1,
          name: entry.$2,
          nationality: entry.$3,
          profession: entry.$4,
        );
        expect(
          inferred.contains(entry.$5),
          isTrue,
          reason:
              'Inferred categories for ${entry.$1} should contain ${entry.$5.name}',
        );
        expect(
          inferred.contains(SaintCategory.laity),
          isFalse,
          reason: 'Inferred categories for ${entry.$1} must not include laity',
        );
      }
    });

    test(
      'every saint adheres to state-of-life exclusivity rules (exactly one religious state for individuals, zero for angels, multiple for groups)',
      () async {
        final saints = await SaintDatabase.loadSaints();
        const stateOfLifeCategories = {
          SaintCategory.holyFamily,
          SaintCategory.apostle,
          SaintCategory.pope,
          SaintCategory.bishop,
          SaintCategory.priest,
          SaintCategory.deacon,
          SaintCategory.brother,
          SaintCategory.nun,
          SaintCategory.laity,
          SaintCategory.patriarch,
          SaintCategory.prophet,
          SaintCategory.judge,
        };

        for (final saint in saints) {
          final assignedStates = saint.categories
              .where(stateOfLifeCategories.contains)
              .toList();

          if (saint.categories.contains(SaintCategory.angel)) {
            // Angels are pure celestial spirits and have 0 human states of life
            expect(
              assignedStates,
              isEmpty,
              reason:
                  'Angel saint ${saint.id} (${saint.name}) should have no human state of life, but found $assignedStates',
            );
          } else if (saint.categories.contains(SaintCategory.group)) {
            // Groups can contain a mixture of clergy, religious, and laity
            expect(
              assignedStates,
              isNotEmpty,
              reason:
                  'Group saint ${saint.id} (${saint.name}) should have at least one state of life, but found none',
            );
          } else if (saint.categories.contains(SaintCategory.apostle) &&
              (saint.categories.contains(SaintCategory.pope) ||
                  saint.categories.contains(SaintCategory.bishop))) {
            // Apostles who were also Popes (Peter) or Bishops (James the Lesser) hold dual apostolic/episcopal office
            expect(
              assignedStates.length,
              2,
              reason:
                  'Apostle saint ${saint.id} (${saint.name}) holding episcopal/papal office must have exactly two states of life (apostle + pope/bishop), but found ${assignedStates.map((c) => c.name).toList()}',
            );
          } else if (saint.era == SaintEra.oldCovenant) {
            // Old Covenant figures may have Old Testament roles (Patriarch, Prophet, Judge, Priest) or Martyr status
            expect(
              saint.categories.contains(SaintCategory.laity),
              isFalse,
              reason:
                  'Old Covenant figure ${saint.id} (${saint.name}) should not be categorized as laity',
            );
          } else {
            // Every individual human Christian saint MUST have EXACTLY ONE state of life
            expect(
              assignedStates.length,
              1,
              reason:
                  'Individual saint ${saint.id} (${saint.name}) must have exactly one religious state of life, but found ${assignedStates.map((c) => c.name).toList()}',
            );
          }
        }
      },
    );

    test('every saint categories array follows canonical UI ordering', () async {
      final saints = await SaintDatabase.loadSaints();
      for (final saint in saints) {
        final categories = saint.categories;
        final sorted = List<SaintCategory>.from(categories)
          ..sort((a, b) => a.index.compareTo(b.index));
        expect(
          categories,
          equals(sorted),
          reason:
              'Saint ${saint.id} categories should follow canonical enum declaration order',
        );
      }
    });

    test(
      'Old Testament saints are loaded, categorized, and searchable',
      () async {
        final saints = await SaintDatabase.loadSaints();

        final otIds = [
          'abel-the-righteous',
          'abraham-the-patriarch',
          'job-the-righteous',
          'melchizedek-the-king',
          'aaron-the-high-priest',
          'moses-the-prophet',
          'joshua-the-judge',
          'gideon-the-judge',
          'samuel-the-prophet',
          'david-the-king',
          'elijah-the-prophet',
          'elisha-the-prophet',
          'isaiah-the-prophet',
          'jeremiah-the-prophet',
          'ezekiel-the-prophet',
          'daniel-the-prophet',
          'hosea-the-prophet',
          'joel-the-prophet',
          'amos-the-prophet',
          'obadiah-the-prophet',
          'jonah-the-prophet',
          'micah-the-prophet',
          'nahum-the-prophet',
          'habakkuk-the-prophet',
          'zephaniah-the-prophet',
          'haggai-the-prophet',
          'zechariah-the-prophet',
          'ezra-the-scribe',
          'eleazar-the-scribe',
        ];

        for (final id in otIds) {
          final saint = await SaintDatabase.getSaintById(id);
          expect(
            saint,
            isNotNull,
            reason: 'Saint $id should exist in database',
          );
          expect(saint!.gender, 'male');
          expect(saint.isDoctor, isFalse);
          expect(saint.isBlessed, isFalse);
          expect(saint.era, SaintEra.oldCovenant);
          expect(saint.categories.contains(SaintCategory.laity), isFalse);
          expect(
            saint.categories.any(
              (c) =>
                  c == SaintCategory.patriarch ||
                  c == SaintCategory.prophet ||
                  c == SaintCategory.judge ||
                  c == SaintCategory.priest ||
                  c == SaintCategory.martyr,
            ),
            isTrue,
          );
        }

        // Check specific details for sample OT figures
        final abel = await SaintDatabase.getSaintById('abel-the-righteous');
        expect(abel!.name, 'Abel the Righteous');
        expect(abel.feastDay, 'January 3');
        expect(abel.categories, contains(SaintCategory.patriarch));
        expect(abel.categories, contains(SaintCategory.martyr));
        expect(abel.approximateYear, -3500);

        final aaron = await SaintDatabase.getSaintById('aaron-the-high-priest');
        expect(aaron!.name, 'Aaron the High Priest');
        expect(aaron.feastDay, 'July 1');
        expect(aaron.categories, contains(SaintCategory.priest));
        expect(aaron.categories, contains(SaintCategory.prophet));
        expect(aaron.categories.contains(SaintCategory.patriarch), isFalse);
        expect(aaron.approximateYear, -1250);

        final amos = await SaintDatabase.getSaintById('amos-the-prophet');
        expect(amos!.name, 'Amos the Prophet');
        expect(amos.feastDay, 'June 15');
        expect(amos.categories, contains(SaintCategory.prophet));
        expect(amos.approximateYear, -750);

        final moses = await SaintDatabase.getSaintById('moses-the-prophet');
        expect(moses!.name, 'Moses the Prophet');
        expect(moses.feastDay, 'September 4');
        expect(moses.categories, contains(SaintCategory.prophet));
        expect(moses.categories.contains(SaintCategory.judge), isFalse);
        expect(moses.approximateYear, -1271);

        final elijah = await SaintDatabase.getSaintById('elijah-the-prophet');
        expect(elijah!.name, 'Elijah the Prophet');
        expect(elijah.feastDay, 'July 20');
        expect(elijah.categories, contains(SaintCategory.prophet));
        expect(elijah.approximateYear, -850);

        final abraham = await SaintDatabase.getSaintById(
          'abraham-the-patriarch',
        );
        expect(abraham!.name, 'Abraham the Patriarch');
        expect(abraham.feastDay, 'October 9');
        expect(abraham.categories, contains(SaintCategory.patriarch));
        expect(abraham.approximateYear, -1750);

        final david = await SaintDatabase.getSaintById('david-the-king');
        expect(david!.name, 'David the King & Prophet');
        expect(david.feastDay, 'December 29');
        expect(david.categories, contains(SaintCategory.prophet));
        expect(david.categories, contains(SaintCategory.monarch));
        expect(david.approximateYear, -970);

        final isaiah = await SaintDatabase.getSaintById('isaiah-the-prophet');
        expect(isaiah!.name, 'Isaiah the Prophet');
        expect(isaiah.feastDay, 'May 9');
        expect(isaiah.categories, contains(SaintCategory.prophet));
        expect(isaiah.categories, contains(SaintCategory.martyr));
        expect(isaiah.approximateYear, -750);

        final jeremiah = await SaintDatabase.getSaintById(
          'jeremiah-the-prophet',
        );
        expect(jeremiah!.name, 'Jeremiah the Prophet');
        expect(jeremiah.feastDay, 'May 1');
        expect(jeremiah.categories, contains(SaintCategory.prophet));
        expect(jeremiah.approximateYear, -570);

        final daniel = await SaintDatabase.getSaintById('daniel-the-prophet');
        expect(daniel!.name, 'Daniel the Prophet');
        expect(daniel.feastDay, 'July 21');
        expect(daniel.categories, contains(SaintCategory.prophet));
        expect(daniel.approximateYear, -550);

        final elisha = await SaintDatabase.getSaintById('elisha-the-prophet');
        expect(elisha!.name, 'Elisha the Prophet');
        expect(elisha.feastDay, 'June 14');
        expect(elisha.categories, contains(SaintCategory.prophet));
        expect(elisha.approximateYear, -850);

        final samuel = await SaintDatabase.getSaintById('samuel-the-prophet');
        expect(samuel!.name, 'Samuel the Prophet');
        expect(samuel.feastDay, 'August 20');
        expect(samuel.categories, contains(SaintCategory.prophet));
        expect(samuel.categories, contains(SaintCategory.judge));
        expect(samuel.approximateYear, -1050);

        final job = await SaintDatabase.getSaintById('job-the-righteous');
        expect(job!.name, 'Job the Righteous');
        expect(job.feastDay, 'May 10');
        expect(job.categories, contains(SaintCategory.patriarch));
        expect(job.approximateYear, -1500);

        final ezekiel = await SaintDatabase.getSaintById('ezekiel-the-prophet');
        expect(ezekiel!.name, 'Ezekiel the Prophet');
        expect(ezekiel.feastDay, 'July 23');
        expect(ezekiel.categories, contains(SaintCategory.prophet));
        expect(ezekiel.categories, contains(SaintCategory.priest));
        expect(ezekiel.approximateYear, -570);

        final eleazar = await SaintDatabase.getSaintById('eleazar-the-scribe');
        expect(eleazar!.name, 'Eleazar the Scribe & Martyr');
        expect(eleazar.feastDay, 'August 1');
        expect(eleazar.categories.contains(SaintCategory.patriarch), isFalse);
        expect(eleazar.categories, contains(SaintCategory.martyr));
        expect(eleazar.approximateYear, -167);

        final melchizedek = await SaintDatabase.getSaintById(
          'melchizedek-the-king',
        );
        expect(melchizedek!.name, 'Melchizedek King & Priest');
        expect(melchizedek.feastDay, 'August 26');
        expect(melchizedek.categories, contains(SaintCategory.patriarch));
        expect(melchizedek.categories, contains(SaintCategory.monarch));
        expect(melchizedek.approximateYear, -1750);

        final joshua = await SaintDatabase.getSaintById('joshua-the-judge');
        expect(joshua!.name, 'Joshua the Judge & Leader');
        expect(joshua.feastDay, 'September 1');
        expect(joshua.categories, contains(SaintCategory.judge));
        expect(joshua.categories, contains(SaintCategory.prophet));
        expect(joshua.approximateYear, -1250);

        final gideon = await SaintDatabase.getSaintById('gideon-the-judge');
        expect(gideon!.name, 'Gideon the Judge');
        expect(gideon.feastDay, 'September 26');
        expect(gideon.categories, contains(SaintCategory.judge));
        expect(gideon.approximateYear, -1150);

        final jonah = await SaintDatabase.getSaintById('jonah-the-prophet');
        expect(jonah!.name, 'Jonah the Prophet');
        expect(jonah.feastDay, 'September 21');
        expect(jonah.categories, contains(SaintCategory.prophet));
        expect(jonah.approximateYear, -750);

        // Verify search queries find OT figures
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Abel',
          ).any((s) => s.id == 'abel-the-righteous'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Aaron',
          ).any((s) => s.id == 'aaron-the-high-priest'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Moses',
          ).any((s) => s.id == 'moses-the-prophet'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Elijah',
          ).any((s) => s.id == 'elijah-the-prophet'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Abraham',
          ).any((s) => s.id == 'abraham-the-patriarch'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'David',
          ).any((s) => s.id == 'david-the-king'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Isaiah',
          ).any((s) => s.id == 'isaiah-the-prophet'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Jeremiah',
          ).any((s) => s.id == 'jeremiah-the-prophet'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Daniel',
          ).any((s) => s.id == 'daniel-the-prophet'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Elisha',
          ).any((s) => s.id == 'elisha-the-prophet'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Samuel',
          ).any((s) => s.id == 'samuel-the-prophet'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Job',
          ).any((s) => s.id == 'job-the-righteous'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Melchizedek',
          ).any((s) => s.id == 'melchizedek-the-king'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Gideon',
          ).any((s) => s.id == 'gideon-the-judge'),
          isTrue,
        );
        expect(
          SaintDatabase.searchSaints(
            saints,
            query: 'Joshua',
          ).any((s) => s.id == 'joshua-the-judge'),
          isTrue,
        );

        // Verify Era filter for Old Covenant returns all 29 OT figures
        final oldCovenantSaints = SaintDatabase.searchSaints(
          saints,
          era: SaintEra.oldCovenant,
        );
        expect(oldCovenantSaints.length, 29);
        for (final id in otIds) {
          expect(oldCovenantSaints.any((s) => s.id == id), isTrue);
        }

        // Verify Category filters for Patriarchs, Prophets, Judges, and Priests
        final patriarchs = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.patriarch,
        );
        expect(patriarchs.any((s) => s.id == 'abraham-the-patriarch'), isTrue);
        expect(patriarchs.any((s) => s.id == 'job-the-righteous'), isTrue);
        expect(patriarchs.any((s) => s.id == 'abel-the-righteous'), isTrue);
        expect(patriarchs.any((s) => s.id == 'melchizedek-the-king'), isTrue);
        expect(patriarchs.any((s) => s.id == 'aaron-the-high-priest'), isFalse);
        expect(patriarchs.any((s) => s.id == 'ezra-the-scribe'), isFalse);
        expect(patriarchs.any((s) => s.id == 'eleazar-the-scribe'), isFalse);

        final prophets = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.prophet,
        );
        expect(prophets.any((s) => s.id == 'moses-the-prophet'), isTrue);
        expect(prophets.any((s) => s.id == 'aaron-the-high-priest'), isTrue);
        expect(prophets.any((s) => s.id == 'ezra-the-scribe'), isTrue);
        expect(prophets.any((s) => s.id == 'elijah-the-prophet'), isTrue);
        expect(prophets.any((s) => s.id == 'david-the-king'), isTrue);
        expect(prophets.any((s) => s.id == 'isaiah-the-prophet'), isTrue);
        expect(prophets.any((s) => s.id == 'amos-the-prophet'), isTrue);
        expect(prophets.any((s) => s.id == 'ezekiel-the-prophet'), isTrue);
        expect(prophets.any((s) => s.id == 'zechariah-the-prophet'), isTrue);

        final judges = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.judge,
        );
        expect(judges.any((s) => s.id == 'moses-the-prophet'), isFalse);
        expect(judges.any((s) => s.id == 'samuel-the-prophet'), isTrue);
        expect(judges.any((s) => s.id == 'gideon-the-judge'), isTrue);
        expect(judges.any((s) => s.id == 'joshua-the-judge'), isTrue);

        final priests = SaintDatabase.searchSaints(
          saints,
          category: SaintCategory.priest,
        );
        expect(priests.any((s) => s.id == 'aaron-the-high-priest'), isTrue);
        expect(priests.any((s) => s.id == 'ezra-the-scribe'), isTrue);
        expect(priests.any((s) => s.id == 'ezekiel-the-prophet'), isTrue);
        expect(priests.any((s) => s.id == 'zechariah-the-prophet'), isTrue);

        // Verify chronological sorting puts Abel, Abraham, Melchizedek, Job first (excluding angelic -9999)
        final chronoAsc = SaintDatabase.searchSaints(
          saints,
          sortBy: SaintSortOption.chronologicalAsc,
        );
        final humanChrono = chronoAsc
            .where(
              (s) => s.approximateYear != null && s.approximateYear! > -9000,
            )
            .toList();
        expect(humanChrono.first.id, 'abel-the-righteous');
        expect(humanChrono.any((s) => s.id == 'abraham-the-patriarch'), isTrue);
        expect(humanChrono.any((s) => s.id == 'job-the-righteous'), isTrue);
      },
    );

    test(
      'SaintEmbedding computes similarity correctly and loads on all bundled saints',
      () async {
        final json = {
          'id': 'test-saint',
          'name': 'Test Saint',
          'nationality': 'Roman',
          'profession': 'Martyr',
          'categories': ['martyr'],
          'embedding': {
            'contemplativeVsActive': -0.5,
            'intellectualVsDevotional': 0.8,
            'courageVsMercy': -0.9,
            'ancientVsModern': -0.8,
            'simplicityVsLeadership': -0.4,
            'pioneeringVsPreservation': 0.5,
          },
        };

        final saint = Saint.fromJson(json);
        expect(saint.embedding, isNotNull);
        expect(saint.embedding!.contemplativeVsActive, -0.5);
        expect(saint.embedding!.intellectualVsDevotional, 0.8);
        expect(saint.embedding!.courageVsMercy, -0.9);
        expect(saint.embedding!.ancientVsModern, -0.8);
        expect(saint.embedding!.simplicityVsLeadership, -0.4);
        expect(saint.embedding!.pioneeringVsPreservation, 0.5);

        final vector = saint.embedding!.toVector();
        expect(vector, [-0.5, 0.8, -0.9, -0.8, -0.4, 0.5]);

        // Cosine similarity with self is 1.0
        final selfSim = saint.embedding!.similarityWith(vector);
        expect(selfSim, closeTo(1.0, 0.0001));

        // With noise
        final jitteredSim = saint.embedding!.similarityWith(
          vector,
          noiseMagnitude: 0.1,
          random: Random(42),
        );
        expect(jitteredSim, isNot(1.0));
        expect(jitteredSim, inInclusiveRange(-1.0, 1.0));

        // Check serialization
        final serialized = saint.toJson();
        expect(serialized['embedding'], isNotNull);
        expect(serialized['embedding']['courageVsMercy'], -0.9);

        // Check that all bundled saints have valid embeddings
        SaintDatabase.mockSaints = null;
        final saints = await SaintDatabase.loadSaints();
        for (final s in saints) {
          expect(
            s.embedding,
            isNotNull,
            reason: '${s.id} should have embedding',
          );
          final v = s.embedding!.toVector();
          for (final val in v) {
            expect(val, inInclusiveRange(-1.0, 1.0));
          }
        }
      },
    );
  });
}
