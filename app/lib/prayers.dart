enum PrayerLanguage {
  english(name: 'English', nativeName: 'English', flag: '🇺🇸'),
  spanish(name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
  french(name: 'French', nativeName: 'Français', flag: '🇫🇷'),
  italian(name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
  latin(name: 'Latin', nativeName: 'Latina', flag: '🇻🇦'),
  vietnamese(name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
  tagalog(name: 'Tagalog', nativeName: 'Tagalog', flag: '🇵🇭'),
  traditionalChinese(
    name: 'Traditional Chinese',
    nativeName: '繁體中文',
    flag: '🇹🇼',
  );

  final String name;
  final String nativeName;
  final String flag;

  const PrayerLanguage({
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class ChineseChar {
  final String char;
  final String pinyin;

  const ChineseChar(this.char, [this.pinyin = '']);
}

class PrayerTranslation {
  final String title;
  final String subtitle;
  final String text;
  final String sourceName;
  final String sourceUrl;
  final List<List<ChineseChar>>? chineseLines;

  const PrayerTranslation({
    required this.title,
    required this.subtitle,
    required this.text,
    required this.sourceName,
    required this.sourceUrl,
    this.chineseLines,
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
            'Padre nuestro, que estás en el cielo,\nsantificado sea tu Nombre;\nvenga a nosotros tu reino;\nhágase tu voluntad\nen la tierra como en el cielo.\n\nDanos hoy nuestro pan di cada día;\nperdona nuestras ofensas,\ncomo también nosotros perdonamos\na los que nos ofenden;\nno nos dejes caer en la tentación,\ny líbranos del mal.\n\nAmén.',
        sourceName: 'Catecismo de la Iglesia Católica (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_sp.html',
      ),
      PrayerLanguage.french: const PrayerTranslation(
        title: 'Notre Père',
        subtitle: "L'Oraison Dominicale",
        text:
            'Notre Père, qui es aux cieux,\nque ton nom soit sanctifié,\nque ton règne vienne,\nque ta volonté soit faite\nsur la terre comme au ciel.\n\nDonne-nous aujourd’hui notre pain de ce jour.\nPardonne-nous nos offenses,\ncomme nous pardonnons aussi\nà ceux qui nous ont offensés.\nEt ne nous laisse pas entrer en tentation,\nmais délivre-nous du Mal.\n\nAmen.',
        sourceName: 'Compendium du Catéchisme de l’Église Catholique (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_fr.html',
      ),
      PrayerLanguage.italian: const PrayerTranslation(
        title: 'Padre Nostro',
        subtitle: 'Preghiera del Signore',
        text:
            'Padre nostro, che sei nei cieli,\nsia santificato il tuo nome,\nvenga il tuo regno,\nsia fatta la tua volontà,\ncome in cielo così in terra.\n\nDacci oggi il nostro pane quotidiano,\ne rimetti a noi i nostri debiti\ncome anche noi li rimettiamo ai nostri debitori,\ne non abbandonarci alla tentazione,\nma liberaci dal male.\n\nAmen.',
        sourceName: 'Compendio del Catechismo della Chiesa Cattolica (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_it.html',
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
      PrayerLanguage.tagalog: const PrayerTranslation(
        title: 'Ama Namin',
        subtitle: 'Panalangin ng Panginoon',
        text:
            'Ama namin, sumasalangit Ka.\nSambahin ang ngalan Mo.\nMapasaamin ang kaharian Mo.\nSundin ang loob Mo dito sa lupa, para nang sa langit.\n\nBigyan Mo kami ngayon ng aming kakanin sa araw-araw;\nAt patawarin Mo kami sa aming mga sala,\nPara nang pagpapatawad namin sa mga nagkakasala sa amin;\nAt huwag Mo kaming ipahintulot sa tukso,\nAt iadya Mo kami sa lahat ng masama.\n\nAmen.',
        sourceName: 'Catholic Bishops’ Conference of the Philippines (CBCP)',
        sourceUrl: 'https://cbcpnews.net',
      ),
      PrayerLanguage.traditionalChinese: const PrayerTranslation(
        title: '天主經',
        subtitle: 'Lord’s Prayer',
        text:
            '我們的天父，願祢的名受顯揚；願祢的國來臨；願祢的旨意奉行在人間，如同在天上。求祢今天賞給我們日用的食糧；求祢寬恕我們的罪過，如同我們寬恕別人一樣；不要讓我們陷於誘惑；但救我們免於凶惡。亞孟。',
        sourceName: '台灣地區主教團 (Bishops’ Conference of Taiwan)',
        sourceUrl: 'https://www.catholic.org.tw',
        chineseLines: [
          [
            ChineseChar('我', 'wǒ'),
            ChineseChar('們', 'men'),
            ChineseChar('的', 'de'),
            ChineseChar('天', 'tiān'),
            ChineseChar('父', 'fù'),
            ChineseChar('，', ''),
          ],
          [
            ChineseChar('願', 'yuàn'),
            ChineseChar('祢', 'nǐ'),
            ChineseChar('的', 'de'),
            ChineseChar('名', 'míng'),
            ChineseChar('受', 'shòu'),
            ChineseChar('顯', 'xiǎn'),
            ChineseChar('揚', 'yáng'),
            ChineseChar('；', ''),
          ],
          [
            ChineseChar('願', 'yuàn'),
            ChineseChar('祢', 'nǐ'),
            ChineseChar('的', 'de'),
            ChineseChar('國', 'guó'),
            ChineseChar('來', 'lái'),
            ChineseChar('臨', 'lín'),
            ChineseChar('；', ''),
          ],
          [
            ChineseChar('願', 'yuàn'),
            ChineseChar('祢', 'nǐ'),
            ChineseChar('的', 'de'),
            ChineseChar('旨', 'zhǐ'),
            ChineseChar('意', 'yì'),
            ChineseChar('奉', 'fèng'),
            ChineseChar('行', 'xíng'),
            ChineseChar('在', 'zài'),
            ChineseChar('人', 'rén'),
            ChineseChar('間', 'jiān'),
            ChineseChar('，', ''),
            ChineseChar('如', 'rú'),
            ChineseChar('同', 'tóng'),
            ChineseChar('在', 'zài'),
            ChineseChar('天', 'tiān'),
            ChineseChar('上', 'shàng'),
            ChineseChar('。', ''),
          ],
          [
            ChineseChar('求', 'qiú'),
            ChineseChar('祢', 'nǐ'),
            ChineseChar('今', 'jīn'),
            ChineseChar('天', 'tiān'),
            ChineseChar('賞', 'shǎng'),
            ChineseChar('給', 'gěi'),
            ChineseChar('我', 'wǒ'),
            ChineseChar('們', 'men'),
            ChineseChar('日', 'rì'),
            ChineseChar('用', 'yòng'),
            ChineseChar('的', 'de'),
            ChineseChar('食', 'shí'),
            ChineseChar('糧', 'liáng'),
            ChineseChar('；', ''),
          ],
          [
            ChineseChar('求', 'qiú'),
            ChineseChar('祢', 'nǐ'),
            ChineseChar('寬', 'kuān'),
            ChineseChar('恕', 'shù'),
            ChineseChar('我', 'wǒ'),
            ChineseChar('們', 'men'),
            ChineseChar('的', 'de'),
            ChineseChar('罪', 'zuì'),
            ChineseChar('過', 'guò'),
            ChineseChar('，', ''),
            ChineseChar('如', 'rú'),
            ChineseChar('同', 'tóng'),
            ChineseChar('我', 'wǒ'),
            ChineseChar('們', 'men'),
            ChineseChar('寬', 'kuān'),
            ChineseChar('恕', 'shù'),
            ChineseChar('別', 'bié'),
            ChineseChar('人', 'rén'),
            ChineseChar('一', 'yī'),
            ChineseChar('樣', 'yàng'),
            ChineseChar('；', ''),
          ],
          [
            ChineseChar('不', 'bù'),
            ChineseChar('要', 'yào'),
            ChineseChar('讓', 'ràng'),
            ChineseChar('我', 'wǒ'),
            ChineseChar('們', 'men'),
            ChineseChar('陷', 'xiàn'),
            ChineseChar('於', 'yú'),
            ChineseChar('誘', 'yòu'),
            ChineseChar('惑', 'huò'),
            ChineseChar('；', ''),
          ],
          [
            ChineseChar('但', 'dàn'),
            ChineseChar('救', 'jiù'),
            ChineseChar('我', 'wǒ'),
            ChineseChar('們', 'men'),
            ChineseChar('免', 'miǎn'),
            ChineseChar('於', 'yú'),
            ChineseChar('凶', 'xiōng'),
            ChineseChar('惡', 'è'),
            ChineseChar('。', ''),
          ],
          [
            ChineseChar('亞', 'yà'),
            ChineseChar('孟', 'mèng'),
            ChineseChar('。', ''),
          ],
        ],
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
      PrayerLanguage.french: const PrayerTranslation(
        title: 'Je vous salue Marie',
        subtitle: 'Salutation Angélique',
        text:
            'Je vous salue, Marie pleine de grâce ;\nle Seigneur est avec vous.\nVous êtes bénie entre toutes les femmes\net Jésus, le fruit de vos entrailles, est béni.\n\nSainte Marie, Mère de Dieu,\npriez pour nous pauvres pécheurs,\nmaintenant et à l’heure de notre mort.\n\nAmen.',
        sourceName: 'Compendium du Catéchisme de l’Église Catholique (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_fr.html',
      ),
      PrayerLanguage.italian: const PrayerTranslation(
        title: 'Ave Maria',
        subtitle: 'Saluto Angelico',
        text:
            'Ave, o Maria, piena di grazia,\nil Signore è con te.\nTu sei benedetta tra le donne\ne benedetto è il frutto del tuo seno, Gesù.\n\nSanta Maria, Madre di Dio,\nprega per noi peccatori,\nadesso e nell’ora della nostra morte.\n\nAmen.',
        sourceName: 'Compendio del Catechismo della Chiesa Cattolica (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_it.html',
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
      PrayerLanguage.tagalog: const PrayerTranslation(
        title: 'Aba Ginoong Maria',
        subtitle: 'Ave Maria',
        text:
            'Aba Ginoong Maria, napupuno ka ng grasya.\nAng Panginoong Diyos ay sumasaiyo.\nBukod kang pinagpala sa babaeng lahat\nAt pinagpala naman ang iyong Anak na si Hesus.\n\nSanta Maria, Ina ng Diyos,\nIpanalangin mo kaming makasalanan,\nNgayon at kung kami’y mamamatay.\n\nAmen.',
        sourceName: 'Catholic Bishops’ Conference of the Philippines (CBCP)',
        sourceUrl: 'https://cbcpnews.net',
      ),
      PrayerLanguage.traditionalChinese: const PrayerTranslation(
        title: '聖母經',
        subtitle: 'Hail Mary',
        text:
            '萬福瑪利亞，妳充滿聖寵。主與妳同在。妳在婦女中受讚頌，妳的親子耶穌同受讚頌。天主聖母瑪利亞，求妳現在 and 我們臨終時，為我們罪人祈求天主。亞孟。',
        sourceName: '台灣地區主教團 (Bishops’ Conference of Taiwan)',
        sourceUrl: 'https://www.catholic.org.tw',
        chineseLines: [
          [
            ChineseChar('萬', 'wàn'),
            ChineseChar('福', 'fú'),
            ChineseChar('瑪', 'mǎ'),
            ChineseChar('利', 'lì'),
            ChineseChar('亞', 'yà'),
            ChineseChar('，', ''),
            ChineseChar('妳', 'nǐ'),
            ChineseChar('充', 'chōng'),
            ChineseChar('滿', 'mǎn'),
            ChineseChar('聖', 'shèng'),
            ChineseChar('寵', 'chǒng'),
            ChineseChar('。', ''),
          ],
          [
            ChineseChar('主', 'zhǔ'),
            ChineseChar('與', 'yǔ'),
            ChineseChar('妳', 'nǐ'),
            ChineseChar('同', 'tóng'),
            ChineseChar('在', 'zài'),
            ChineseChar('。', ''),
          ],
          [
            ChineseChar('妳', 'nǐ'),
            ChineseChar('在', 'zài'),
            ChineseChar('婦', 'fù'),
            ChineseChar('女', 'nǚ'),
            ChineseChar('中', 'zhōng'),
            ChineseChar('受', 'shòu'),
            ChineseChar('讚', 'zàn'),
            ChineseChar('頌', 'sòng'),
            ChineseChar('，', ''),
            ChineseChar('妳', 'nǐ'),
            ChineseChar('的', 'de'),
            ChineseChar('親', 'qīn'),
            ChineseChar('子', 'zǐ'),
            ChineseChar('耶', 'yé'),
            ChineseChar('穌', 'sū'),
            ChineseChar('同', 'tóng'),
            ChineseChar('受', 'shòu'),
            ChineseChar('讚', 'zàn'),
            ChineseChar('頌', 'sòng'),
            ChineseChar('。', ''),
          ],
          [
            ChineseChar('天', 'tiān'),
            ChineseChar('主', 'zhǔ'),
            ChineseChar('聖', 'shèng'),
            ChineseChar('母', 'mǔ'),
            ChineseChar('瑪', 'mǎ'),
            ChineseChar('利', 'lì'),
            ChineseChar('亞', 'yà'),
            ChineseChar('，', ''),
            ChineseChar('求', 'qiú'),
            ChineseChar('妳', 'nǐ'),
            ChineseChar('現', 'xiàn'),
            ChineseChar('在', 'zài'),
            ChineseChar('和', 'hé'),
            ChineseChar('我', 'wǒ'),
            ChineseChar('們', 'men'),
            ChineseChar('臨', 'lín'),
            ChineseChar('終', 'zhōng'),
            ChineseChar('時', 'shí'),
            ChineseChar('，', ''),
            ChineseChar('為', 'wèi'),
            ChineseChar('我', 'wǒ'),
            ChineseChar('們', 'men'),
            ChineseChar('罪', 'zuì'),
            ChineseChar('人', 'rén'),
            ChineseChar('祈', 'qí'),
            ChineseChar('求', 'qiú'),
            ChineseChar('天', 'tiān'),
            ChineseChar('主', 'zhǔ'),
            ChineseChar('。', ''),
          ],
          [
            ChineseChar('亞', 'yà'),
            ChineseChar('孟', 'mèng'),
            ChineseChar('。', ''),
          ],
        ],
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
      PrayerLanguage.french: const PrayerTranslation(
        title: 'Gloire au Père',
        subtitle: 'Doxologie',
        text:
            'Gloire au Père,\net au Fils,\net au Saint-Esprit.\n\nComme il était au commencement,\nmaintenant et toujours,\net dans les siècles des siècles.\n\nAmen.',
        sourceName: 'Compendium du Catéchisme de l’Église Catholique (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_fr.html',
      ),
      PrayerLanguage.italian: const PrayerTranslation(
        title: 'Gloria al Padre',
        subtitle: 'Doxologia Minor',
        text:
            'Gloria al Padre e al Figlio\ne allo Spirito Santo.\n\nCome era nel principio,\ne ora e sempre\nnei secoli dei secoli.\n\nAmen.',
        sourceName: 'Compendio del Catechismo della Chiesa Cattolica (Vatican)',
        sourceUrl:
            'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_it.html',
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
      PrayerLanguage.tagalog: const PrayerTranslation(
        title: 'Luwalhati sa Ama',
        subtitle: 'Luwalhati',
        text:
            'Luwalhati sa Ama, at sa Anak, at sa Espiritu Santo.\n\nKapara nang sa una, gayon din ngayon\nat magpakailanman\nAt magpasawalang hanggan.\n\nAmen.',
        sourceName: 'Catholic Bishops’ Conference of the Philippines (CBCP)',
        sourceUrl: 'https://cbcpnews.net',
      ),
      PrayerLanguage.traditionalChinese: const PrayerTranslation(
        title: '聖三光榮頌',
        subtitle: 'Glory Be',
        text: '願光榮歸於父、及子、及聖神。起初如何，今日亦然，直到永遠。亞孟。',
        sourceName: '台灣地區主教團 (Bishops’ Conference of Taiwan)',
        sourceUrl: 'https://www.catholic.org.tw',
        chineseLines: [
          [
            ChineseChar('願', 'yuàn'),
            ChineseChar('光', 'guāng'),
            ChineseChar('榮', 'róng'),
            ChineseChar('歸', 'guī'),
            ChineseChar('於', 'yú'),
            ChineseChar('父', 'fù'),
            ChineseChar('、', ''),
            ChineseChar('及', 'jí'),
            ChineseChar('子', 'zǐ'),
            ChineseChar('、', ''),
            ChineseChar('及', 'jí'),
            ChineseChar('聖', 'shèng'),
            ChineseChar('神', 'shén'),
            ChineseChar('。', ''),
          ],
          [
            ChineseChar('起', 'qǐ'),
            ChineseChar('初', 'chū'),
            ChineseChar('如', 'rú'),
            ChineseChar('何', 'hé'),
            ChineseChar('，', ''),
            ChineseChar('今', 'jīn'),
            ChineseChar('日', 'rì'),
            ChineseChar('亦', 'yì'),
            ChineseChar('然', 'rán'),
            ChineseChar('，', ''),
            ChineseChar('直', 'zhí'),
            ChineseChar('到', 'dào'),
            ChineseChar('永', 'yǒng'),
            ChineseChar('遠', 'yuǎn'),
            ChineseChar('。', ''),
          ],
          [
            ChineseChar('亞', 'yà'),
            ChineseChar('孟', 'mèng'),
            ChineseChar('。', ''),
          ],
        ],
      ),
    },
  ),
];
