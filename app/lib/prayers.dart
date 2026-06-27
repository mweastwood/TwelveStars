enum PrayerLanguage {
  english(name: 'English', nativeName: 'English', flag: '🇺🇸'),
  spanish(name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
  latin(name: 'Latin', nativeName: 'Latina', flag: '🇻🇦'),
  vietnamese(name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳');

  final String name;
  final String nativeName;
  final String flag;

  const PrayerLanguage({
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class PrayerTranslation {
  final String title;
  final String subtitle;
  final String text;
  final String sourceName;
  final String sourceUrl;

  const PrayerTranslation({
    required this.title,
    required this.subtitle,
    required this.text,
    required this.sourceName,
    required this.sourceUrl,
  });
}

class Prayer {
  final String id;
  final String defaultTitle;
  final Map<PrayerLanguage, PrayerTranslation> translations;

  const Prayer({
    required this.id,
    required this.defaultTitle,
    required this.translations,
  });
}

final List<Prayer> defaultPrayers = [
  Prayer(
    id: 'our_father',
    defaultTitle: 'Our Father',
    translations: {
      PrayerLanguage.english: const PrayerTranslation(
        title: 'Our Father',
        subtitle: "The Lord's Prayer",
        text:
            'Our Father, who art in heaven,\nhallowed be thy name;\nthy kingdom come;\nthy will be done\non earth as it is in heaven.\n\nGive us this day our daily bread;\nand forgive us our trespasses\nas we forgive those who trespass against us;\nand lead us not into temptation,\nbut deliver us from evil.\n\nAmen.',
        sourceName: 'United States Conference of Catholic Bishops (USCCB)',
        sourceUrl: 'https://www.usccb.org/prayers/basic-prayers',
      ),
      PrayerLanguage.spanish: const PrayerTranslation(
        title: 'Padre Nuestro',
        subtitle: 'El Padre Nuestro',
        text:
            'Padre nuestro, que estás en el cielo,\nsantificado sea tu Nombre;\nvenga a nosotros tu reino;\nhágase tu voluntad\nen la tierra como en el cielo.\n\nDanos hoy nuestro pan de cada día;\nperdona nuestras ofensas,\ncomo también nosotros perdonamos\na los que nos ofenden;\nno nos dejes caer en la tentación,\ny líbranos del mal.\n\nAmén.',
        sourceName: 'Catecismo de la Iglesia Católica (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_sp.html',
      ),
      PrayerLanguage.latin: const PrayerTranslation(
        title: 'Pater Noster',
        subtitle: 'Oratio Dominica',
        text:
            'Pater noster, qui es in caelis,\nsanctificetur nomen tuum;\nadveniat regnum tuum;\nfiat voluntas tua,\nsicut in caelo, et in terra.\n\nPanem nostrum cotidianum da nobis hodie;\net dimitte nobis debita nostra,\nsicut et nos dimittimus debitoribus nostris;\net ne nos inducas in tentationem;\nsed libera nos a malo.\n\nAmen.',
        sourceName: 'Catechismus Catholicae Ecclesiae (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_lt.html',
      ),
      PrayerLanguage.vietnamese: const PrayerTranslation(
        title: 'Kinh Lạy Cha',
        subtitle: 'Kinh Lạy Cha',
        text:
            'Lạy Cha chúng con ở trên trời,\nchúng con nguyện danh Cha cả sáng,\nnước Cha trị đến,\ný Cha thể hiện dưới đất cũng như trên trời.\n\nXin Cha cho chúng con hôm nay\nlương thực hằng ngày,\nvà tha nợ chúng con\nnhư chúng con cũng tha kẻ có nợ chúng con.\n\nXin chớ để chúng con sa chước cám dỗ,\nnhưng cứu chúng con cho khỏi sự dữ.\n\nAmen.',
        sourceName: 'Tổng Giáo Phận Sài Gòn (Archdiocese of Saigon)',
        sourceUrl: 'https://tgpsaigon.net',
      ),
    },
  ),
  Prayer(
    id: 'hail_mary',
    defaultTitle: 'Hail Mary',
    translations: {
      PrayerLanguage.english: const PrayerTranslation(
        title: 'Hail Mary',
        subtitle: 'Ave Maria',
        text:
            'Hail Mary, full of grace,\nthe Lord is with you;\nblessed are you among women,\nand blessed is the fruit of your womb, Jesus.\n\nHoly Mary, Mother of God,\npray for us sinners\nnow and at the hour of our death.\n\nAmen.',
        sourceName: 'United States Conference of Catholic Bishops (USCCB)',
        sourceUrl: 'https://www.usccb.org/prayers/basic-prayers',
      ),
      PrayerLanguage.spanish: const PrayerTranslation(
        title: 'Ave María',
        subtitle: 'El Ave María',
        text:
            'Dios te salve, María, llena eres de gracia,\nel Señor es contigo.\nBendita tú eres entre todas las mujeres,\ny bendito es el fruto de tu vientre, Jesús.\n\nSanta María, Madre de Dios,\nruega por nosotros, pecadores,\nahora y en la hora de nuestra muerte.\n\nAmén.',
        sourceName: 'Catecismo de la Iglesia Católica (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_sp.html',
      ),
      PrayerLanguage.latin: const PrayerTranslation(
        title: 'Ave Maria',
        subtitle: 'Salutatio Angelica',
        text:
            'Ave Maria, gratia plena, Dominus tecum.\nBenedicta tu in mulieribus,\net benedictus fructus ventris tui, Iesus.\n\nSancta Maria, Mater Dei,\nora pro nobis peccatoribus,\nnunc et in hora mortis nostrae.\n\nAmen.',
        sourceName: 'Catechismus Catholicae Ecclesiae (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_lt.html',
      ),
      PrayerLanguage.vietnamese: const PrayerTranslation(
        title: 'Kinh Kính Mừng',
        subtitle: 'Kinh Kính Mừng',
        text:
            'Kính mừng Maria đầy ơn phúc,\nĐức Chúa Trời ở cùng Bà,\nBà có phúc lạ hơn mọi người nữ,\nvà Giêsu con lòng Bà gồm phúc lạ.\n\nThánh Maria, Đức Mẹ Chúa Trời,\ncầu cho chúng con là kẻ có tội,\nkhi nay và trong giờ lâm tử.\n\nAmen.',
        sourceName: 'Tổng Giáo Phận Sài Gòn (Archdiocese of Saigon)',
        sourceUrl: 'https://tgpsaigon.net',
      ),
    },
  ),
  Prayer(
    id: 'glory_be',
    defaultTitle: 'Glory Be',
    translations: {
      PrayerLanguage.english: const PrayerTranslation(
        title: 'Glory Be',
        subtitle: 'Doxology',
        text:
            'Glory be to the Father,\nand to the Son,\nand to the Holy Spirit;\nas it was in the beginning,\nis now, and ever shall be,\nworld without end.\n\nAmen.',
        sourceName: 'United States Conference of Catholic Bishops (USCCB)',
        sourceUrl: 'https://www.usccb.org/prayers/basic-prayers',
      ),
      PrayerLanguage.spanish: const PrayerTranslation(
        title: 'Gloria al Padre',
        subtitle: 'El Gloria',
        text:
            'Gloria al Padre,\ny al Hijo,\ny al Espíritu Santo.\n\nComo era en el principio,\nahora y siempre,\npor los siglos de los siglos.\n\nAmén.',
        sourceName: 'Catecismo de la Iglesia Católica (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_sp.html',
      ),
      PrayerLanguage.latin: const PrayerTranslation(
        title: 'Gloria Patri',
        subtitle: 'Doxologia Minor',
        text:
            'Gloria Patri, et Filio, et Spiritui Sancto.\n\nSicut erat in principio,\net nunc, et semper,\net in saecula saeculorum.\n\nAmen.',
        sourceName: 'Catechismus Catholicae Ecclesiae (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_lt.html',
      ),
      PrayerLanguage.vietnamese: const PrayerTranslation(
        title: 'Kinh Sáng Danh',
        subtitle: 'Kinh Sáng Danh',
        text:
            'Sáng danh Đức Chúa Cha,\nvà Đức Chúa Con,\nvà Đức Chúa Thánh Thần.\n\nNhư đã có trước vô cùng,\nvà bây giờ, và hằng có,\nvà đời đời chẳng cùng.\n\nAmen.',
        sourceName: 'Tổng Giáo Phận Sài Gòn (Archdiocese of Saigon)',
        sourceUrl: 'https://tgpsaigon.net',
      ),
    },
  ),
];
