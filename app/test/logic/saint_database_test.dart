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
      expect(saint.dateRange, '1225 – 1274');

      final serialized = saint.toJson();
      expect(serialized['id'], 'thomas-aquinas');
      expect(serialized['isDoctor'], true);
      expect(serialized['isBlessed'], null);
      expect(serialized['patronage'], 'Academics, Students, Theologians');

      const blessedSaint = Saint(
        id: 'miguel-pro',
        name: 'Blessed Miguel Pro',
        nationality: 'Mexican',
        profession: 'Priest',
        isBlessed: true,
      );
      expect(blessedSaint.toJson()['isBlessed'], true);
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
        expect(piusV.name, contains('Pius V'));

        final nonExistent = await SaintDatabase.getSaintById(
          'unknown-saint-id',
        );
        expect(nonExistent, isNull);
      },
    );
  });
}
