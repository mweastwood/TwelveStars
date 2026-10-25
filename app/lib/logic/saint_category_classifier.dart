import 'saint_models.dart';

/// Heuristic classifier that derives [SaintCategory] tags from a saint's ID,
/// name, nationality, profession, and Doctor of the Church status when explicit
/// categories are not provided in JSON.
class SaintCategoryClassifier {
  const SaintCategoryClassifier._();

  static final RegExp _angelRegex = RegExp(r'\barchangels?\b|\bangels?\b');

  static List<SaintCategory> computeCategories({
    required String id,
    required String name,
    required String nationality,
    required String profession,
    bool isDoctor = false,
  }) {
    final List<SaintCategory> list = [];
    final profLower = profession.toLowerCase();
    final nameLower = name.toLowerCase();
    final natLower = nationality.toLowerCase();

    // 0. Group
    final isKnownGroup = const {
      'vietnamese-martyrs',
      'korean-martyrs',
      'paul-miki-and-companions',
      'charles-lwanga-and-ugandan-martyrs',
      'perpetua-and-felicity',
    }.contains(id);

    if (isKnownGroup ||
        profLower.contains('martyrs of') ||
        profLower.contains('companions') ||
        nameLower.contains('companions') ||
        nameLower.contains('martyrs')) {
      list.add(SaintCategory.group);
    }

    // 1. Doctor of the Church
    if (isDoctor) {
      list.add(SaintCategory.doctor);
    }

    // 2. Angel
    if (natLower.contains('angelic') ||
        profLower.contains('archangel') ||
        nameLower.contains('archangel') ||
        _angelRegex.hasMatch(profLower) ||
        _angelRegex.hasMatch(nameLower)) {
      list.add(SaintCategory.angel);
    }

    // 3. Holy Family
    if (profLower.contains('foster father') ||
        profLower.contains('father of jesus') ||
        profLower.contains('spouse of mary') ||
        profLower.contains('spouse of the virgin mary') ||
        profLower.contains('mother of god') ||
        profLower.contains('theotokos') ||
        profLower.contains('holy family') ||
        nameLower.contains('blessed virgin mary') ||
        (nameLower.contains('joseph') && profLower.contains('carpenter'))) {
      list.add(SaintCategory.holyFamily);
    }

    // 3.1 Patriarch
    final isBiblicalPatriarch = const {
      'abraham-the-patriarch',
      'job-the-righteous',
      'abel-the-righteous',
      'melchizedek-the-king',
    }.contains(id);

    if (isBiblicalPatriarch ||
        profLower.contains('patriarch & father of faith') ||
        profLower.contains('patriarch & man of patience') ||
        nameLower.contains('the patriarch')) {
      list.add(SaintCategory.patriarch);
    }

    // 3.2 Prophet
    final isBiblicalProphet = const {
      'moses-the-prophet',
      'elijah-the-prophet',
      'elisha-the-prophet',
      'isaiah-the-prophet',
      'jeremiah-the-prophet',
      'daniel-the-prophet',
      'samuel-the-prophet',
      'david-the-king',
      'aaron-the-high-priest',
      'amos-the-prophet',
      'ezekiel-the-prophet',
      'ezra-the-scribe',
      'habakkuk-the-prophet',
      'haggai-the-prophet',
      'hosea-the-prophet',
      'joel-the-prophet',
      'jonah-the-prophet',
      'joshua-the-judge',
      'micah-the-prophet',
      'nahum-the-prophet',
      'obadiah-the-prophet',
      'zechariah-the-prophet',
      'zephaniah-the-prophet',
    }.contains(id);

    if (isBiblicalProphet ||
        profLower.contains('prophet') ||
        nameLower.contains('the prophet')) {
      list.add(SaintCategory.prophet);
    }

    // 3.3 Judge
    final isBiblicalJudge = const {
      'samuel-the-prophet',
      'gideon-the-judge',
      'joshua-the-judge',
    }.contains(id);

    if (isBiblicalJudge || profLower.contains('judge')) {
      list.add(SaintCategory.judge);
    }

    // 4. Apostle
    final isBiblicalApostle = const {
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
    }.contains(id);

    if (isBiblicalApostle ||
        profLower.contains('apostle to the apostles') ||
        profLower.contains('apostola apostolorum') ||
        (profLower.contains('apostle') &&
            !profLower.contains('apostle of') &&
            !profLower.contains('apostle to') &&
            !profLower.contains('cyber-apostle') &&
            (nameLower.contains('the apostle') ||
                nameLower.contains('barnabas') ||
                nameLower.contains('matthias') ||
                nameLower.contains('thaddeus') ||
                nameLower.contains('zealot')))) {
      list.add(SaintCategory.apostle);
    }

    // 5. Evangelist
    if (profLower.contains('evangelist') || nameLower.contains('evangelist')) {
      list.add(SaintCategory.evangelist);
    }

    // 6. Pope
    if (profLower.contains('pope') || nameLower.contains('pope')) {
      list.add(SaintCategory.pope);
    }

    // 7. Martyr
    final isMartyredApostleOrEvangelist = const {
      'peter-the-apostle',
      'paul-the-apostle',
      'andrew-the-apostle',
      'james-the-greater',
      'james-the-lesser',
      'philip-the-apostle',
      'bartholomew-the-apostle',
      'thomas-the-apostle',
      'matthew-the-apostle',
      'jude-thaddeus',
      'simon-the-zealot',
      'matthias',
      'barnabas',
      'mark-the-evangelist',
      'polycarp-of-smyrna',
      'teresa-benedicta-of-the-cross',
      'john-of-nepomuk',
    }.contains(id);

    if (profLower.contains('martyr') ||
        nameLower.contains('martyrs') ||
        isMartyredApostleOrEvangelist) {
      list.add(SaintCategory.martyr);
    }

    // 8. Bishop
    final isEpiscopalTitle =
        profLower.contains('bishop') ||
        profLower.contains('archbishop') ||
        profLower.contains('cardinal') ||
        (profLower.contains('patriarch') &&
            !profLower.contains('patriarch of christian monasticism') &&
            !profLower.contains('patriarch of western monasticism') &&
            !profLower.contains('patriarch & father of faith') &&
            !profLower.contains('patriarch & man of patience') &&
            !profLower.contains('holy patriarch') &&
            !id.contains('abraham') &&
            !id.contains('job') &&
            !id.contains('aaron') &&
            !id.contains('abel') &&
            !id.contains('eleazar') &&
            !id.contains('ezra') &&
            !id.contains('melchizedek'));
    if (isEpiscopalTitle) {
      list.add(SaintCategory.bishop);
    }

    // 9. Monarch / Ruler
    final isMonarchTitle =
        profLower.contains('king') ||
        (profLower.contains('queen') &&
            !profLower.contains('queen of heaven') &&
            !profLower.contains('queen of all saints') &&
            !profLower.contains('queen of the apostles')) ||
        profLower.contains('emperor') ||
        profLower.contains('empress') ||
        profLower.contains('ruler') ||
        (profLower.contains('prince') &&
            !profLower.contains('prince of the heavenly') &&
            !profLower.contains('prince of the apostles')) ||
        profLower.contains('princess') ||
        profLower.contains('duke') ||
        profLower.contains('duchess') ||
        profLower.contains('monarch');
    if (isMonarchTitle) {
      list.add(SaintCategory.monarch);
    }

    // 10. Mystic & Contemplative
    final isProminentMystic = const {
      'mary-mother-of-god',
      'mary-magdalene',
      'anthony-the-great',
      'thomas-aquinas',
      'bonaventure',
      'bernard-of-clairvaux',
      'francis-de-sales',
      'francis-of-assisi',
      'ignatius-of-loyola',
      'peter-damian',
      'gregory-of-narek',
      'charbel-makhlouf',
      'joseph-of-cupertino',
      'paul-of-the-cross',
      'gerard-majella',
      'rita-of-cascia',
      'rafqa-pietra-choboq-ar-rayes',
      'kateri-tekakwitha',
      'rose-of-lima',
      'titus-brandsma',
      'mother-teresa',
      'teresa-of-avila',
      'therese-of-lisieux',
      'john-of-the-cross',
      'catherine-of-siena',
      'faustina-kowalska',
      'bernadette-soubirous',
      'bridget-of-sweden',
      'clare-of-assisi',
      'clare-of-montefalco',
      'gertrude-the-great',
      'mechtilde-of-hackeborn',
      'hildegard-of-bingen',
      'padre-pio',
      'juan-diego',
      'teresa-benedicta-of-the-cross',
    }.contains(id);

    if (isProminentMystic ||
        profLower.contains('mystic') ||
        profLower.contains('stigmatist') ||
        profLower.contains('visionary') ||
        profLower.contains('contemplative') ||
        profLower.contains('divine mercy')) {
      list.add(SaintCategory.mystic);
    }

    // 11. Laity
    final isKnownLaySaint = const {
      'joseph',
      'carlo-acutis',
      'gianna-beretta-molla',
      'giuseppe-moscati',
      'kateri-tekakwitha',
      'thomas-more',
      'margaret-clitherow',
      'maria-goretti',
      'dominic-savio',
      'pancras',
      'tarcisius',
      'jose-sanchez-del-rio',
      'pedro-calungsod',
      'lorenzo-ruiz',
      'perpetua-and-felicity',
      'charles-lwanga-and-ugandan-martyrs',
      'roch',
      'philip-howard',
      'cecilia',
      'juan-diego',
      'joan-of-arc',
      'bridget-of-sweden',
      'rita-of-cascia',
      'andre-bessette',
      'martin-de-porres',
      'gerard-majella',
      'louis-ix-of-france',
      'elizabeth-of-hungary',
      'wenceslaus',
      'edward-the-confessor',
      'margaret-of-scotland',
      'stephen-of-hungary',
      'eric-of-sweden',
      'olaf-ii-of-norway',
      'casimir',
      'francis-borgia',
      'vietnamese-martyrs',
      'korean-martyrs',
    }.contains(id);

    final isExplicitLayKeyword =
        (profLower.contains('layman') ||
            profLower.contains('laywoman') ||
            profLower.contains('layperson') ||
            profLower.contains('laity') ||
            profLower.contains('lay ') ||
            profLower.contains('student') ||
            profLower.contains('pupil') ||
            profLower.contains('peasant girl') ||
            profLower.contains('pediatrician') ||
            profLower.contains('calligrapher') ||
            profLower.contains('programmer') ||
            profLower.contains('web developer') ||
            profLower.contains('married') ||
            profLower.contains('homemaker') ||
            profLower.contains('matron') ||
            profLower.contains('craftsman') ||
            profLower.contains('lawyer') ||
            profLower.contains('statesman') ||
            profLower.contains('chancellor') ||
            profLower.contains('cavalry officer') ||
            (profLower.contains('carpenter') &&
                !profLower.contains('foster father')) ||
            (profLower.contains('mother') &&
                !profLower.contains('mother of god') &&
                !profLower.contains('mother cabrini') &&
                !profLower.contains('mother teresa') &&
                !profLower.contains('mother marianne') &&
                !profLower.contains('mother superior') &&
                !profLower.contains('foundress') &&
                !profLower.contains('seraphic mother')) ||
            (profLower.contains('father') &&
                !profLower.contains('church father') &&
                !profLower.contains('desert father') &&
                !profLower.contains('apostolic father') &&
                !profLower.contains('cappadocian father') &&
                !profLower.contains('latin church father') &&
                !profLower.contains('father of the church') &&
                !profLower.contains('father of western monasticism') &&
                !profLower.contains('father of christian monasticism') &&
                !profLower.contains('father of faith') &&
                !profLower.contains('spiritual father') &&
                !profLower.contains('foster father') &&
                !profLower.contains('picpus fathers') &&
                !profLower.contains('holy father'))) &&
        !list.contains(SaintCategory.holyFamily) &&
        !list.contains(SaintCategory.bishop) &&
        !list.contains(SaintCategory.pope) &&
        !list.contains(SaintCategory.apostle) &&
        !list.contains(SaintCategory.patriarch) &&
        !list.contains(SaintCategory.prophet) &&
        !list.contains(SaintCategory.judge);

    if ((isExplicitLayKeyword || isKnownLaySaint) &&
        !list.contains(SaintCategory.holyFamily) &&
        !list.contains(SaintCategory.apostle) &&
        !list.contains(SaintCategory.patriarch) &&
        !list.contains(SaintCategory.prophet) &&
        !list.contains(SaintCategory.judge)) {
      list.add(SaintCategory.laity);
    }

    // 12. Healer & Missionary
    final isKnownHealerOrMissionary = const {
      'francis-xavier',
      'damien-of-molokai',
      'marianne-cope',
      'mother-teresa',
      'frances-xavier-cabrini',
      'junipero-serra',
      'peter-claver',
      'camillus-de-lellis',
      'vincent-de-paul',
      'john-bosco',
      'andre-bessette',
      'martin-de-porres',
      'giuseppe-moscati',
      'gianna-beretta-molla',
      'roch',
      'blaise',
      'luke-the-evangelist',
      'raphael-the-archangel',
      'patrick-of-ireland',
      'aidan-of-lindisfarne',
      'columba-of-iona',
      'columbanus',
      'peter-canisius',
      'lawrence-of-brindisi',
      'john-of-avila',
      'louis-marie-de-montfort',
      'turibius-of-mogrovejo',
      'jacques-berthieu',
      'pedro-calungsod',
      'carlo-acutis',
      'barnabas',
      'philip-the-apostle',
      'thomas-the-apostle',
      'simon-the-zealot',
      'paul-the-apostle',
      'nicholas-of-myra',
      'anastasia-of-sirmium',
      'anthony-of-padua',
    }.contains(id);

    if (isKnownHealerOrMissionary ||
        profLower.contains('physician') ||
        profLower.contains('pediatrician') ||
        profLower.contains('surgeon') ||
        profLower.contains('healer') ||
        profLower.contains('nurse') ||
        profLower.contains('medical') ||
        profLower.contains('missionary') ||
        profLower.contains('missionaries') ||
        profLower.contains('apostle of') ||
        profLower.contains('apostle to the lepers') ||
        profLower.contains('cyber-apostle')) {
      list.add(SaintCategory.healerMissionary);
    }

    // 13. Virgin & Consecrated
    final isKnownVirginOrConsecrated = const {
      'mary-mother-of-god',
      'agnes-of-rome',
      'barbara',
      'cecilia',
      'lucy-of-syracuse',
      'maria-goretti',
      'apollonia',
      'anastasia-of-sirmium',
      'kateri-tekakwitha',
      'rose-of-lima',
      'scholastica',
      'clare-of-assisi',
      'clare-of-montefalco',
      'catherine-of-bologna',
      'gertrude-the-great',
      'mechtilde-of-hackeborn',
      'rafqa-pietra-choboq-ar-rayes',
      'teresa-of-avila',
      'therese-of-lisieux',
      'catherine-of-siena',
      'hildegard-of-bingen',
      'bernadette-soubirous',
      'faustina-kowalska',
      'joan-of-arc',
      'teresa-benedicta-of-the-cross',
      'dominic-savio',
      'aloysius-gonzaga',
      'stanislaus-kostka',
      'john-berchmans',
      'elizabeth-ann-seton',
      'frances-xavier-cabrini',
      'katharine-drexel',
      'louise-de-marillac',
      'marianne-cope',
      'mary-mackillop',
      'mother-teresa',
      'jane-frances-de-chantal',
    }.contains(id);

    if (isKnownVirginOrConsecrated ||
        profLower.contains('virgin') ||
        profLower.contains('lily of the mohawks') ||
        profLower.contains('consecrated')) {
      list.add(SaintCategory.virgin);
    }

    // 14. Priest
    final isKnownPriest = const {
      'aaron-the-high-priest',
      'ezekiel-the-prophet',
      'ezra-the-scribe',
      'zechariah-the-prophet',
      'anthony-of-padua',
      'bede-the-venerable',
      'bernard-of-clairvaux',
      'bruno-of-cologne',
      'camillus-de-lellis',
      'charbel-makhlouf',
      'charles-de-foucauld',
      'columba-of-iona',
      'columbanus',
      'damien-of-molokai',
      'dominic-de-guzman',
      'edmund-campion',
      'francis-borgia',
      'francis-xavier',
      'gregory-of-narek',
      'ignatius-of-loyola',
      'jacques-berthieu',
      'jerome',
      'john-bosco',
      'john-damascene',
      'john-of-avila',
      'john-of-nepomuk',
      'john-of-the-cross',
      'john-vianney',
      'josemaria-escriva',
      'joseph-of-cupertino',
      'junipero-serra',
      'lawrence-of-brindisi',
      'louis-marie-de-montfort',
      'maximilian-kolbe',
      'nimatullah-kassab',
      'padre-pio',
      'paul-of-the-cross',
      'peregrine-laziosi',
      'peter-canisius',
      'peter-claver',
      'philip-neri',
      'raymond-of-penafort',
      'thomas-aquinas',
      'titus-brandsma',
      'vincent-de-paul',
    }.contains(id);

    if (isKnownPriest ||
        ((profLower.contains('priest') ||
                profLower.contains('presbyter') ||
                profLower.contains('parish priest') ||
                profLower.contains('curé') ||
                profLower.contains('confessor')) &&
            !list.contains(SaintCategory.pope) &&
            !list.contains(SaintCategory.bishop) &&
            !list.contains(SaintCategory.patriarch) &&
            !list.contains(SaintCategory.prophet) &&
            !list.contains(SaintCategory.judge))) {
      list.add(SaintCategory.priest);
    }

    // 14.5 Deacon
    final isKnownDeacon = const {
      'stephen-first-martyr',
      'lawrence-of-rome',
      'ephrem-the-syrian',
    }.contains(id);

    if (isKnownDeacon ||
        ((profLower.contains('deacon') || profLower.contains('archdeacon')) &&
            !profLower.contains('deaconess') &&
            !list.contains(SaintCategory.pope) &&
            !list.contains(SaintCategory.bishop) &&
            !list.contains(SaintCategory.priest))) {
      list.add(SaintCategory.deacon);
    }

    // 15. Brother
    final isKnownBrother = const {
      'aloysius-gonzaga',
      'andre-bessette',
      'anthony-the-great',
      'benedict-of-nursia',
      'francis-of-assisi',
      'gerard-majella',
      'john-berchmans',
      'martin-de-porres',
      'pachomius',
      'paul-miki-and-companions',
      'paul-the-first-hermit',
      'romuald',
      'stanislaus-kostka',
      'vincent-of-lerins',
    }.contains(id);

    if (isKnownBrother ||
        ((profLower.contains('brother') ||
                profLower.contains('friar') ||
                profLower.contains('monk') ||
                profLower.contains('abbot') ||
                profLower.contains('hermit') ||
                profLower.contains('novice') ||
                profLower.contains('scholastic')) &&
            !list.contains(SaintCategory.pope) &&
            !list.contains(SaintCategory.bishop) &&
            !list.contains(SaintCategory.priest) &&
            !list.contains(SaintCategory.deacon))) {
      list.add(SaintCategory.brother);
    }

    // 16. Nun
    final isKnownNun = const {
      'bernadette-soubirous',
      'bridget-of-sweden',
      'brigid-of-kildare',
      'catherine-of-bologna',
      'catherine-of-siena',
      'clare-of-assisi',
      'clare-of-montefalco',
      'elizabeth-ann-seton',
      'faustina-kowalska',
      'frances-xavier-cabrini',
      'gertrude-the-great',
      'hildegard-of-bingen',
      'jane-frances-de-chantal',
      'katharine-drexel',
      'louise-de-marillac',
      'marianne-cope',
      'mary-mackillop',
      'mechtilde-of-hackeborn',
      'mother-teresa',
      'rafqa-pietra-choboq-ar-rayes',
      'rita-of-cascia',
      'rose-of-lima',
      'scholastica',
      'teresa-benedicta-of-the-cross',
      'teresa-of-avila',
      'teresa-of-the-andes',
      'therese-of-lisieux',
    }.contains(id);

    if (isKnownNun ||
        profLower.contains('nun') ||
        profLower.contains('abbess') ||
        profLower.contains('sister') ||
        profLower.contains('sisters') ||
        profLower.contains('foundress') ||
        profLower.contains('clares')) {
      list.add(SaintCategory.nun);
    }

    if (list.isEmpty) {
      list.add(SaintCategory.other);
    }

    return list.toSet().toList();
  }
}
