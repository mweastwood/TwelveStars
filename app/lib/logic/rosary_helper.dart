enum RosaryMysteryType {
  joyful(name: 'Joyful Mysteries', days: 'Mondays & Saturdays'),
  sorrowful(name: 'Sorrowful Mysteries', days: 'Tuesdays & Fridays'),
  glorious(name: 'Glorious Mysteries', days: 'Wednesdays & Sundays'),
  luminous(name: 'Luminous Mysteries', days: 'Thursdays');

  final String name;
  final String days;
  const RosaryMysteryType({required this.name, required this.days});
}

enum RosaryBeadType { crucifix, large, small, medal, chainLink }

class RosaryMystery {
  final int number;
  final String title;
  final String description;

  const RosaryMystery({
    required this.number,
    required this.title,
    required this.description,
  });
}

class RosaryStep {
  final String title;
  final String? subtitle;
  final String prayerId;
  final String?
  secondaryPrayerId; // e.g. for Glory Be + Fatima Prayer combo step
  final String?
  tertiaryPrayerId; // e.g. for closing Hail Holy Queen + Final Prayer + Sign of the Cross
  final RosaryBeadType beadType;
  final RosaryMystery? mystery;
  final int? decadeIndex;
  final int? beadIndexInDecade; // 1-10 for Hail Marys

  const RosaryStep({
    required this.title,
    this.subtitle,
    required this.prayerId,
    this.secondaryPrayerId,
    this.tertiaryPrayerId,
    required this.beadType,
    this.mystery,
    this.decadeIndex,
    this.beadIndexInDecade,
  });
}

class RosaryHelper {
  static const Map<RosaryMysteryType, List<RosaryMystery>> mysteries = {
    RosaryMysteryType.joyful: [
      RosaryMystery(
        number: 1,
        title: 'The Annunciation',
        description:
            'The Angel Gabriel appears to Mary to announce that she will conceive the Son of God by the Holy Spirit.',
      ),
      RosaryMystery(
        number: 2,
        title: 'The Visitation',
        description:
            'Mary visits her cousin Elizabeth, who is pregnant with John the Baptist, and sings her Magnificat.',
      ),
      RosaryMystery(
        number: 3,
        title: 'The Nativity',
        description:
            'Jesus is born in Bethlehem in a humble stable, wrapped in swaddling clothes and laid in a manger.',
      ),
      RosaryMystery(
        number: 4,
        title: 'The Presentation',
        description:
            'Mary and Joseph present the infant Jesus in the Temple, in accordance with the Law of Moses.',
      ),
      RosaryMystery(
        number: 5,
        title: 'The Finding in the Temple',
        description:
            'After searching for three days, Mary and Joseph find the twelve-year-old Jesus teaching the teachers in the Temple.',
      ),
    ],
    RosaryMysteryType.sorrowful: [
      RosaryMystery(
        number: 1,
        title: 'The Agony in the Garden',
        description:
            'Jesus prays in Gethsemane on the eve of His Passion, sweating blood while submitting to the Father\'s will.',
      ),
      RosaryMystery(
        number: 2,
        title: 'The Scourging at the Pillar',
        description:
            'Jesus is bound to a stone pillar and brutally whipped by Roman soldiers under Pilate\'s command.',
      ),
      RosaryMystery(
        number: 3,
        title: 'The Crowning with Thorns',
        description:
            'A crown of sharp thorns is pressed into Jesus\' head, and soldiers mock Him as the King of the Jews.',
      ),
      RosaryMystery(
        number: 4,
        title: 'The Carrying of the Cross',
        description:
            'Jesus carries His heavy wooden cross through the streets of Jerusalem to Calvary while scourged and mocked.',
      ),
      RosaryMystery(
        number: 5,
        title: 'The Crucifixion',
        description:
            'Jesus is nailed to the cross on Calvary, dying after three hours of agony to redeem humanity.',
      ),
    ],
    RosaryMysteryType.glorious: [
      RosaryMystery(
        number: 1,
        title: 'The Resurrection',
        description:
            'Jesus rises glorious from the dead on the third day, conquering sin and death and bringing new life.',
      ),
      RosaryMystery(
        number: 2,
        title: 'The Ascension',
        description:
            'Forty days after His Resurrection, Jesus ascends body and soul into Heaven in the presence of His disciples.',
      ),
      RosaryMystery(
        number: 3,
        title: 'The Descent of the Holy Spirit',
        description:
            'The Holy Spirit descends as tongues of fire upon Mary and the Apostles in the Upper Room on Pentecost.',
      ),
      RosaryMystery(
        number: 4,
        title: 'The Assumption',
        description:
            'At the end of her earthly life, Mary is assumed body and soul into heavenly glory by God.',
      ),
      RosaryMystery(
        number: 5,
        title: 'The Coronation of Mary',
        description:
            'Mary is crowned by her Son as Queen of Heaven and Earth, surrounded by all the saints and angels.',
      ),
    ],
    RosaryMysteryType.luminous: [
      RosaryMystery(
        number: 1,
        title: 'The Baptism of Christ',
        description:
            'John baptizes Jesus in the Jordan River, the Holy Spirit descends like a dove, and the Father speaks from Heaven.',
      ),
      RosaryMystery(
        number: 2,
        title: 'The Wedding at Cana',
        description:
            'At Mary\'s request, Jesus performs His first public miracle by turning water into wine, revealing His glory.',
      ),
      RosaryMystery(
        number: 3,
        title: 'The Proclamation of the Kingdom',
        description:
            'Jesus announces the arrival of the Kingdom of God and calls all people to repentance and faith.',
      ),
      RosaryMystery(
        number: 4,
        title: 'The Transfiguration',
        description:
            'Jesus is transfigured in radiant light on Mount Tabor before Peter, James, and John, joined by Moses and Elijah.',
      ),
      RosaryMystery(
        number: 5,
        title: 'The Institution of the Eucharist',
        description:
            'At the Last Supper, Jesus offers His Body and Blood under the appearances of bread and wine, establishing the New Covenant.',
      ),
    ],
  };

  static List<RosaryStep> generateSteps(RosaryMysteryType type) {
    final list = <RosaryStep>[];
    final selectedMysteries = mysteries[type]!;

    // 0. Opening Prayers (Crucifix) - Merges Sign of the Cross and Apostles' Creed
    list.add(
      const RosaryStep(
        title: 'Opening Prayers',
        subtitle: 'Sign of the Cross & Apostles\' Creed',
        prayerId: 'sign_of_the_cross',
        secondaryPrayerId: 'apostles_creed',
        beadType: RosaryBeadType.crucifix,
      ),
    );

    // 1. Our Father (Intro)
    list.add(
      const RosaryStep(
        title: 'Our Father',
        subtitle: 'For the intentions of the Holy Father',
        prayerId: 'our_father',
        beadType: RosaryBeadType.large,
      ),
    );

    // 3. Three Hail Marys (Intro)
    list.add(
      const RosaryStep(
        title: 'Hail Mary',
        subtitle: 'For the increase of Faith',
        prayerId: 'hail_mary',
        beadType: RosaryBeadType.small,
      ),
    );
    list.add(
      const RosaryStep(
        title: 'Hail Mary',
        subtitle: 'For the increase of Hope',
        prayerId: 'hail_mary',
        beadType: RosaryBeadType.small,
      ),
    );
    list.add(
      const RosaryStep(
        title: 'Hail Mary',
        subtitle: 'For the increase of Charity',
        prayerId: 'hail_mary',
        beadType: RosaryBeadType.small,
      ),
    );

    // 4. Glory Be (Intro)
    list.add(
      const RosaryStep(
        title: 'Glory Be',
        subtitle: 'Concluding Intro Prayers',
        prayerId: 'glory_be',
        beadType: RosaryBeadType.chainLink,
      ),
    );

    // 5. Five Decades
    for (int d = 0; d < 5; d++) {
      final mystery = selectedMysteries[d];

      // Decade Our Father + Mystery Announcement
      list.add(
        RosaryStep(
          title: 'Our Father',
          subtitle: 'Decade ${d + 1}',
          prayerId: 'our_father',
          beadType: RosaryBeadType.large,
          mystery: mystery,
          decadeIndex: d,
        ),
      );

      // 10 Hail Marys
      for (int h = 0; h < 10; h++) {
        list.add(
          RosaryStep(
            title: 'Hail Mary',
            subtitle: 'Bead ${h + 1} of 10',
            prayerId: 'hail_mary',
            beadType: RosaryBeadType.small,
            mystery: mystery,
            decadeIndex: d,
            beadIndexInDecade: h + 1,
          ),
        );
      }

      // Glory Be + Fatima Prayer
      list.add(
        RosaryStep(
          title: 'Glory Be & Fatima Prayer',
          subtitle: 'Concludes Decade ${d + 1}',
          prayerId: 'glory_be',
          secondaryPrayerId: 'fatima_prayer',
          beadType: RosaryBeadType.chainLink,
          mystery: mystery,
          decadeIndex: d,
        ),
      );
    }

    // 6. Closing Prayers (Medal) - Merges Hail Holy Queen, Final Prayer, and closing Sign of the Cross
    list.add(
      const RosaryStep(
        title: 'Closing Prayers',
        subtitle: 'Hail Holy Queen, Final Prayer, & Sign of the Cross',
        prayerId: 'hail_holy_queen',
        secondaryPrayerId: 'final_prayer_rosary',
        tertiaryPrayerId: 'sign_of_the_cross',
        beadType: RosaryBeadType.medal,
      ),
    );

    return list;
  }

  static RosaryMysteryType getMysteryForDay(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
      case DateTime.saturday:
        return RosaryMysteryType.joyful;
      case DateTime.tuesday:
      case DateTime.friday:
        return RosaryMysteryType.sorrowful;
      case DateTime.wednesday:
      case DateTime.sunday:
        return RosaryMysteryType.glorious;
      case DateTime.thursday:
        return RosaryMysteryType.luminous;
      default:
        return RosaryMysteryType.joyful;
    }
  }
}
