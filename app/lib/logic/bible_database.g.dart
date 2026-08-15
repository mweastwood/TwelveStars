// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_database.dart';

// ignore_for_file: type=lint
class BibleVerses extends Table with TableInfo<BibleVerses, BibleVerse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BibleVerses(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _bookNumberMeta = const VerificationMeta(
    'bookNumber',
  );
  late final GeneratedColumn<int> bookNumber = GeneratedColumn<int>(
    'book_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _verseNumberMeta = const VerificationMeta(
    'verseNumber',
  );
  late final GeneratedColumn<int> verseNumber = GeneratedColumn<int>(
    'verse_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _verseTextMeta = const VerificationMeta(
    'verseText',
  );
  late final GeneratedColumn<String> verseText = GeneratedColumn<String>(
    'verse_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _translationCodeMeta = const VerificationMeta(
    'translationCode',
  );
  late final GeneratedColumn<String> translationCode = GeneratedColumn<String>(
    'translation_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookNumber,
    bookName,
    chapter,
    verseNumber,
    verseText,
    translationCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bible_verses';
  @override
  VerificationContext validateIntegrity(
    Insertable<BibleVerse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_number')) {
      context.handle(
        _bookNumberMeta,
        bookNumber.isAcceptableOrUnknown(data['book_number']!, _bookNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNumberMeta);
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('verse_number')) {
      context.handle(
        _verseNumberMeta,
        verseNumber.isAcceptableOrUnknown(
          data['verse_number']!,
          _verseNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_verseNumberMeta);
    }
    if (data.containsKey('verse_text')) {
      context.handle(
        _verseTextMeta,
        verseText.isAcceptableOrUnknown(data['verse_text']!, _verseTextMeta),
      );
    } else if (isInserting) {
      context.missing(_verseTextMeta);
    }
    if (data.containsKey('translation_code')) {
      context.handle(
        _translationCodeMeta,
        translationCode.isAcceptableOrUnknown(
          data['translation_code']!,
          _translationCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationCodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BibleVerse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BibleVerse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_number'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      verseNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse_number'],
      )!,
      verseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_text'],
      )!,
      translationCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_code'],
      )!,
    );
  }

  @override
  BibleVerses createAlias(String alias) {
    return BibleVerses(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class BibleVerse extends DataClass implements Insertable<BibleVerse> {
  final int id;
  final int bookNumber;
  final String bookName;
  final int chapter;
  final int verseNumber;
  final String verseText;
  final String translationCode;
  const BibleVerse({
    required this.id,
    required this.bookNumber,
    required this.bookName,
    required this.chapter,
    required this.verseNumber,
    required this.verseText,
    required this.translationCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_number'] = Variable<int>(bookNumber);
    map['book_name'] = Variable<String>(bookName);
    map['chapter'] = Variable<int>(chapter);
    map['verse_number'] = Variable<int>(verseNumber);
    map['verse_text'] = Variable<String>(verseText);
    map['translation_code'] = Variable<String>(translationCode);
    return map;
  }

  BibleVersesCompanion toCompanion(bool nullToAbsent) {
    return BibleVersesCompanion(
      id: Value(id),
      bookNumber: Value(bookNumber),
      bookName: Value(bookName),
      chapter: Value(chapter),
      verseNumber: Value(verseNumber),
      verseText: Value(verseText),
      translationCode: Value(translationCode),
    );
  }

  factory BibleVerse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BibleVerse(
      id: serializer.fromJson<int>(json['id']),
      bookNumber: serializer.fromJson<int>(json['book_number']),
      bookName: serializer.fromJson<String>(json['book_name']),
      chapter: serializer.fromJson<int>(json['chapter']),
      verseNumber: serializer.fromJson<int>(json['verse_number']),
      verseText: serializer.fromJson<String>(json['verse_text']),
      translationCode: serializer.fromJson<String>(json['translation_code']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'book_number': serializer.toJson<int>(bookNumber),
      'book_name': serializer.toJson<String>(bookName),
      'chapter': serializer.toJson<int>(chapter),
      'verse_number': serializer.toJson<int>(verseNumber),
      'verse_text': serializer.toJson<String>(verseText),
      'translation_code': serializer.toJson<String>(translationCode),
    };
  }

  BibleVerse copyWith({
    int? id,
    int? bookNumber,
    String? bookName,
    int? chapter,
    int? verseNumber,
    String? verseText,
    String? translationCode,
  }) => BibleVerse(
    id: id ?? this.id,
    bookNumber: bookNumber ?? this.bookNumber,
    bookName: bookName ?? this.bookName,
    chapter: chapter ?? this.chapter,
    verseNumber: verseNumber ?? this.verseNumber,
    verseText: verseText ?? this.verseText,
    translationCode: translationCode ?? this.translationCode,
  );
  BibleVerse copyWithCompanion(BibleVersesCompanion data) {
    return BibleVerse(
      id: data.id.present ? data.id.value : this.id,
      bookNumber: data.bookNumber.present
          ? data.bookNumber.value
          : this.bookNumber,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verseNumber: data.verseNumber.present
          ? data.verseNumber.value
          : this.verseNumber,
      verseText: data.verseText.present ? data.verseText.value : this.verseText,
      translationCode: data.translationCode.present
          ? data.translationCode.value
          : this.translationCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BibleVerse(')
          ..write('id: $id, ')
          ..write('bookNumber: $bookNumber, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verseNumber: $verseNumber, ')
          ..write('verseText: $verseText, ')
          ..write('translationCode: $translationCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookNumber,
    bookName,
    chapter,
    verseNumber,
    verseText,
    translationCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BibleVerse &&
          other.id == this.id &&
          other.bookNumber == this.bookNumber &&
          other.bookName == this.bookName &&
          other.chapter == this.chapter &&
          other.verseNumber == this.verseNumber &&
          other.verseText == this.verseText &&
          other.translationCode == this.translationCode);
}

class BibleVersesCompanion extends UpdateCompanion<BibleVerse> {
  final Value<int> id;
  final Value<int> bookNumber;
  final Value<String> bookName;
  final Value<int> chapter;
  final Value<int> verseNumber;
  final Value<String> verseText;
  final Value<String> translationCode;
  const BibleVersesCompanion({
    this.id = const Value.absent(),
    this.bookNumber = const Value.absent(),
    this.bookName = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verseNumber = const Value.absent(),
    this.verseText = const Value.absent(),
    this.translationCode = const Value.absent(),
  });
  BibleVersesCompanion.insert({
    this.id = const Value.absent(),
    required int bookNumber,
    required String bookName,
    required int chapter,
    required int verseNumber,
    required String verseText,
    required String translationCode,
  }) : bookNumber = Value(bookNumber),
       bookName = Value(bookName),
       chapter = Value(chapter),
       verseNumber = Value(verseNumber),
       verseText = Value(verseText),
       translationCode = Value(translationCode);
  static Insertable<BibleVerse> custom({
    Expression<int>? id,
    Expression<int>? bookNumber,
    Expression<String>? bookName,
    Expression<int>? chapter,
    Expression<int>? verseNumber,
    Expression<String>? verseText,
    Expression<String>? translationCode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookNumber != null) 'book_number': bookNumber,
      if (bookName != null) 'book_name': bookName,
      if (chapter != null) 'chapter': chapter,
      if (verseNumber != null) 'verse_number': verseNumber,
      if (verseText != null) 'verse_text': verseText,
      if (translationCode != null) 'translation_code': translationCode,
    });
  }

  BibleVersesCompanion copyWith({
    Value<int>? id,
    Value<int>? bookNumber,
    Value<String>? bookName,
    Value<int>? chapter,
    Value<int>? verseNumber,
    Value<String>? verseText,
    Value<String>? translationCode,
  }) {
    return BibleVersesCompanion(
      id: id ?? this.id,
      bookNumber: bookNumber ?? this.bookNumber,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      verseNumber: verseNumber ?? this.verseNumber,
      verseText: verseText ?? this.verseText,
      translationCode: translationCode ?? this.translationCode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookNumber.present) {
      map['book_number'] = Variable<int>(bookNumber.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verseNumber.present) {
      map['verse_number'] = Variable<int>(verseNumber.value);
    }
    if (verseText.present) {
      map['verse_text'] = Variable<String>(verseText.value);
    }
    if (translationCode.present) {
      map['translation_code'] = Variable<String>(translationCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BibleVersesCompanion(')
          ..write('id: $id, ')
          ..write('bookNumber: $bookNumber, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verseNumber: $verseNumber, ')
          ..write('verseText: $verseText, ')
          ..write('translationCode: $translationCode')
          ..write(')'))
        .toString();
  }
}

class LectionaryReadings extends Table
    with TableInfo<LectionaryReadings, LectionaryReading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LectionaryReadings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _readingKeyMeta = const VerificationMeta(
    'readingKey',
  );
  late final GeneratedColumn<String> readingKey = GeneratedColumn<String>(
    'reading_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _readingTypeMeta = const VerificationMeta(
    'readingType',
  );
  late final GeneratedColumn<String> readingType = GeneratedColumn<String>(
    'reading_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bookNumberMeta = const VerificationMeta(
    'bookNumber',
  );
  late final GeneratedColumn<int> bookNumber = GeneratedColumn<int>(
    'book_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _verseRangeMeta = const VerificationMeta(
    'verseRange',
  );
  late final GeneratedColumn<String> verseRange = GeneratedColumn<String>(
    'verse_range',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _citationMeta = const VerificationMeta(
    'citation',
  );
  late final GeneratedColumn<String> citation = GeneratedColumn<String>(
    'citation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    readingKey,
    readingType,
    bookNumber,
    bookName,
    chapter,
    verseRange,
    citation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lectionary_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LectionaryReading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reading_key')) {
      context.handle(
        _readingKeyMeta,
        readingKey.isAcceptableOrUnknown(data['reading_key']!, _readingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_readingKeyMeta);
    }
    if (data.containsKey('reading_type')) {
      context.handle(
        _readingTypeMeta,
        readingType.isAcceptableOrUnknown(
          data['reading_type']!,
          _readingTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_readingTypeMeta);
    }
    if (data.containsKey('book_number')) {
      context.handle(
        _bookNumberMeta,
        bookNumber.isAcceptableOrUnknown(data['book_number']!, _bookNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNumberMeta);
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('verse_range')) {
      context.handle(
        _verseRangeMeta,
        verseRange.isAcceptableOrUnknown(data['verse_range']!, _verseRangeMeta),
      );
    } else if (isInserting) {
      context.missing(_verseRangeMeta);
    }
    if (data.containsKey('citation')) {
      context.handle(
        _citationMeta,
        citation.isAcceptableOrUnknown(data['citation']!, _citationMeta),
      );
    } else if (isInserting) {
      context.missing(_citationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LectionaryReading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LectionaryReading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      readingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_key'],
      )!,
      readingType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_type'],
      )!,
      bookNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_number'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      verseRange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_range'],
      )!,
      citation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}citation'],
      )!,
    );
  }

  @override
  LectionaryReadings createAlias(String alias) {
    return LectionaryReadings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class LectionaryReading extends DataClass
    implements Insertable<LectionaryReading> {
  final int id;
  final String readingKey;
  final String readingType;
  final int bookNumber;
  final String bookName;
  final int chapter;
  final String verseRange;
  final String citation;
  const LectionaryReading({
    required this.id,
    required this.readingKey,
    required this.readingType,
    required this.bookNumber,
    required this.bookName,
    required this.chapter,
    required this.verseRange,
    required this.citation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reading_key'] = Variable<String>(readingKey);
    map['reading_type'] = Variable<String>(readingType);
    map['book_number'] = Variable<int>(bookNumber);
    map['book_name'] = Variable<String>(bookName);
    map['chapter'] = Variable<int>(chapter);
    map['verse_range'] = Variable<String>(verseRange);
    map['citation'] = Variable<String>(citation);
    return map;
  }

  LectionaryReadingsCompanion toCompanion(bool nullToAbsent) {
    return LectionaryReadingsCompanion(
      id: Value(id),
      readingKey: Value(readingKey),
      readingType: Value(readingType),
      bookNumber: Value(bookNumber),
      bookName: Value(bookName),
      chapter: Value(chapter),
      verseRange: Value(verseRange),
      citation: Value(citation),
    );
  }

  factory LectionaryReading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LectionaryReading(
      id: serializer.fromJson<int>(json['id']),
      readingKey: serializer.fromJson<String>(json['reading_key']),
      readingType: serializer.fromJson<String>(json['reading_type']),
      bookNumber: serializer.fromJson<int>(json['book_number']),
      bookName: serializer.fromJson<String>(json['book_name']),
      chapter: serializer.fromJson<int>(json['chapter']),
      verseRange: serializer.fromJson<String>(json['verse_range']),
      citation: serializer.fromJson<String>(json['citation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reading_key': serializer.toJson<String>(readingKey),
      'reading_type': serializer.toJson<String>(readingType),
      'book_number': serializer.toJson<int>(bookNumber),
      'book_name': serializer.toJson<String>(bookName),
      'chapter': serializer.toJson<int>(chapter),
      'verse_range': serializer.toJson<String>(verseRange),
      'citation': serializer.toJson<String>(citation),
    };
  }

  LectionaryReading copyWith({
    int? id,
    String? readingKey,
    String? readingType,
    int? bookNumber,
    String? bookName,
    int? chapter,
    String? verseRange,
    String? citation,
  }) => LectionaryReading(
    id: id ?? this.id,
    readingKey: readingKey ?? this.readingKey,
    readingType: readingType ?? this.readingType,
    bookNumber: bookNumber ?? this.bookNumber,
    bookName: bookName ?? this.bookName,
    chapter: chapter ?? this.chapter,
    verseRange: verseRange ?? this.verseRange,
    citation: citation ?? this.citation,
  );
  LectionaryReading copyWithCompanion(LectionaryReadingsCompanion data) {
    return LectionaryReading(
      id: data.id.present ? data.id.value : this.id,
      readingKey: data.readingKey.present
          ? data.readingKey.value
          : this.readingKey,
      readingType: data.readingType.present
          ? data.readingType.value
          : this.readingType,
      bookNumber: data.bookNumber.present
          ? data.bookNumber.value
          : this.bookNumber,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verseRange: data.verseRange.present
          ? data.verseRange.value
          : this.verseRange,
      citation: data.citation.present ? data.citation.value : this.citation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LectionaryReading(')
          ..write('id: $id, ')
          ..write('readingKey: $readingKey, ')
          ..write('readingType: $readingType, ')
          ..write('bookNumber: $bookNumber, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verseRange: $verseRange, ')
          ..write('citation: $citation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    readingKey,
    readingType,
    bookNumber,
    bookName,
    chapter,
    verseRange,
    citation,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LectionaryReading &&
          other.id == this.id &&
          other.readingKey == this.readingKey &&
          other.readingType == this.readingType &&
          other.bookNumber == this.bookNumber &&
          other.bookName == this.bookName &&
          other.chapter == this.chapter &&
          other.verseRange == this.verseRange &&
          other.citation == this.citation);
}

class LectionaryReadingsCompanion extends UpdateCompanion<LectionaryReading> {
  final Value<int> id;
  final Value<String> readingKey;
  final Value<String> readingType;
  final Value<int> bookNumber;
  final Value<String> bookName;
  final Value<int> chapter;
  final Value<String> verseRange;
  final Value<String> citation;
  const LectionaryReadingsCompanion({
    this.id = const Value.absent(),
    this.readingKey = const Value.absent(),
    this.readingType = const Value.absent(),
    this.bookNumber = const Value.absent(),
    this.bookName = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verseRange = const Value.absent(),
    this.citation = const Value.absent(),
  });
  LectionaryReadingsCompanion.insert({
    this.id = const Value.absent(),
    required String readingKey,
    required String readingType,
    required int bookNumber,
    required String bookName,
    required int chapter,
    required String verseRange,
    required String citation,
  }) : readingKey = Value(readingKey),
       readingType = Value(readingType),
       bookNumber = Value(bookNumber),
       bookName = Value(bookName),
       chapter = Value(chapter),
       verseRange = Value(verseRange),
       citation = Value(citation);
  static Insertable<LectionaryReading> custom({
    Expression<int>? id,
    Expression<String>? readingKey,
    Expression<String>? readingType,
    Expression<int>? bookNumber,
    Expression<String>? bookName,
    Expression<int>? chapter,
    Expression<String>? verseRange,
    Expression<String>? citation,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (readingKey != null) 'reading_key': readingKey,
      if (readingType != null) 'reading_type': readingType,
      if (bookNumber != null) 'book_number': bookNumber,
      if (bookName != null) 'book_name': bookName,
      if (chapter != null) 'chapter': chapter,
      if (verseRange != null) 'verse_range': verseRange,
      if (citation != null) 'citation': citation,
    });
  }

  LectionaryReadingsCompanion copyWith({
    Value<int>? id,
    Value<String>? readingKey,
    Value<String>? readingType,
    Value<int>? bookNumber,
    Value<String>? bookName,
    Value<int>? chapter,
    Value<String>? verseRange,
    Value<String>? citation,
  }) {
    return LectionaryReadingsCompanion(
      id: id ?? this.id,
      readingKey: readingKey ?? this.readingKey,
      readingType: readingType ?? this.readingType,
      bookNumber: bookNumber ?? this.bookNumber,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      verseRange: verseRange ?? this.verseRange,
      citation: citation ?? this.citation,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (readingKey.present) {
      map['reading_key'] = Variable<String>(readingKey.value);
    }
    if (readingType.present) {
      map['reading_type'] = Variable<String>(readingType.value);
    }
    if (bookNumber.present) {
      map['book_number'] = Variable<int>(bookNumber.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verseRange.present) {
      map['verse_range'] = Variable<String>(verseRange.value);
    }
    if (citation.present) {
      map['citation'] = Variable<String>(citation.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LectionaryReadingsCompanion(')
          ..write('id: $id, ')
          ..write('readingKey: $readingKey, ')
          ..write('readingType: $readingType, ')
          ..write('bookNumber: $bookNumber, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verseRange: $verseRange, ')
          ..write('citation: $citation')
          ..write(')'))
        .toString();
  }
}

class FavoritePassages extends Table
    with TableInfo<FavoritePassages, FavoritePassage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FavoritePassages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _bookNumberMeta = const VerificationMeta(
    'bookNumber',
  );
  late final GeneratedColumn<int> bookNumber = GeneratedColumn<int>(
    'book_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _textPreviewMeta = const VerificationMeta(
    'textPreview',
  );
  late final GeneratedColumn<String> textPreview = GeneratedColumn<String>(
    'text_preview',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookNumber,
    bookName,
    chapter,
    startVerse,
    endVerse,
    textPreview,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_passages';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoritePassage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_number')) {
      context.handle(
        _bookNumberMeta,
        bookNumber.isAcceptableOrUnknown(data['book_number']!, _bookNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNumberMeta);
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    } else if (isInserting) {
      context.missing(_startVerseMeta);
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    } else if (isInserting) {
      context.missing(_endVerseMeta);
    }
    if (data.containsKey('text_preview')) {
      context.handle(
        _textPreviewMeta,
        textPreview.isAcceptableOrUnknown(
          data['text_preview']!,
          _textPreviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textPreviewMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoritePassage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoritePassage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_number'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      )!,
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      )!,
      textPreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_preview'],
      )!,
    );
  }

  @override
  FavoritePassages createAlias(String alias) {
    return FavoritePassages(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FavoritePassage extends DataClass implements Insertable<FavoritePassage> {
  final int id;
  final int bookNumber;
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String textPreview;
  const FavoritePassage({
    required this.id,
    required this.bookNumber,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.textPreview,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_number'] = Variable<int>(bookNumber);
    map['book_name'] = Variable<String>(bookName);
    map['chapter'] = Variable<int>(chapter);
    map['start_verse'] = Variable<int>(startVerse);
    map['end_verse'] = Variable<int>(endVerse);
    map['text_preview'] = Variable<String>(textPreview);
    return map;
  }

  FavoritePassagesCompanion toCompanion(bool nullToAbsent) {
    return FavoritePassagesCompanion(
      id: Value(id),
      bookNumber: Value(bookNumber),
      bookName: Value(bookName),
      chapter: Value(chapter),
      startVerse: Value(startVerse),
      endVerse: Value(endVerse),
      textPreview: Value(textPreview),
    );
  }

  factory FavoritePassage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoritePassage(
      id: serializer.fromJson<int>(json['id']),
      bookNumber: serializer.fromJson<int>(json['book_number']),
      bookName: serializer.fromJson<String>(json['book_name']),
      chapter: serializer.fromJson<int>(json['chapter']),
      startVerse: serializer.fromJson<int>(json['start_verse']),
      endVerse: serializer.fromJson<int>(json['end_verse']),
      textPreview: serializer.fromJson<String>(json['text_preview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'book_number': serializer.toJson<int>(bookNumber),
      'book_name': serializer.toJson<String>(bookName),
      'chapter': serializer.toJson<int>(chapter),
      'start_verse': serializer.toJson<int>(startVerse),
      'end_verse': serializer.toJson<int>(endVerse),
      'text_preview': serializer.toJson<String>(textPreview),
    };
  }

  FavoritePassage copyWith({
    int? id,
    int? bookNumber,
    String? bookName,
    int? chapter,
    int? startVerse,
    int? endVerse,
    String? textPreview,
  }) => FavoritePassage(
    id: id ?? this.id,
    bookNumber: bookNumber ?? this.bookNumber,
    bookName: bookName ?? this.bookName,
    chapter: chapter ?? this.chapter,
    startVerse: startVerse ?? this.startVerse,
    endVerse: endVerse ?? this.endVerse,
    textPreview: textPreview ?? this.textPreview,
  );
  FavoritePassage copyWithCompanion(FavoritePassagesCompanion data) {
    return FavoritePassage(
      id: data.id.present ? data.id.value : this.id,
      bookNumber: data.bookNumber.present
          ? data.bookNumber.value
          : this.bookNumber,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
      textPreview: data.textPreview.present
          ? data.textPreview.value
          : this.textPreview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoritePassage(')
          ..write('id: $id, ')
          ..write('bookNumber: $bookNumber, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('textPreview: $textPreview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookNumber,
    bookName,
    chapter,
    startVerse,
    endVerse,
    textPreview,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoritePassage &&
          other.id == this.id &&
          other.bookNumber == this.bookNumber &&
          other.bookName == this.bookName &&
          other.chapter == this.chapter &&
          other.startVerse == this.startVerse &&
          other.endVerse == this.endVerse &&
          other.textPreview == this.textPreview);
}

class FavoritePassagesCompanion extends UpdateCompanion<FavoritePassage> {
  final Value<int> id;
  final Value<int> bookNumber;
  final Value<String> bookName;
  final Value<int> chapter;
  final Value<int> startVerse;
  final Value<int> endVerse;
  final Value<String> textPreview;
  const FavoritePassagesCompanion({
    this.id = const Value.absent(),
    this.bookNumber = const Value.absent(),
    this.bookName = const Value.absent(),
    this.chapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.textPreview = const Value.absent(),
  });
  FavoritePassagesCompanion.insert({
    this.id = const Value.absent(),
    required int bookNumber,
    required String bookName,
    required int chapter,
    required int startVerse,
    required int endVerse,
    required String textPreview,
  }) : bookNumber = Value(bookNumber),
       bookName = Value(bookName),
       chapter = Value(chapter),
       startVerse = Value(startVerse),
       endVerse = Value(endVerse),
       textPreview = Value(textPreview);
  static Insertable<FavoritePassage> custom({
    Expression<int>? id,
    Expression<int>? bookNumber,
    Expression<String>? bookName,
    Expression<int>? chapter,
    Expression<int>? startVerse,
    Expression<int>? endVerse,
    Expression<String>? textPreview,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookNumber != null) 'book_number': bookNumber,
      if (bookName != null) 'book_name': bookName,
      if (chapter != null) 'chapter': chapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endVerse != null) 'end_verse': endVerse,
      if (textPreview != null) 'text_preview': textPreview,
    });
  }

  FavoritePassagesCompanion copyWith({
    Value<int>? id,
    Value<int>? bookNumber,
    Value<String>? bookName,
    Value<int>? chapter,
    Value<int>? startVerse,
    Value<int>? endVerse,
    Value<String>? textPreview,
  }) {
    return FavoritePassagesCompanion(
      id: id ?? this.id,
      bookNumber: bookNumber ?? this.bookNumber,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      textPreview: textPreview ?? this.textPreview,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookNumber.present) {
      map['book_number'] = Variable<int>(bookNumber.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (textPreview.present) {
      map['text_preview'] = Variable<String>(textPreview.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritePassagesCompanion(')
          ..write('id: $id, ')
          ..write('bookNumber: $bookNumber, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('textPreview: $textPreview')
          ..write(')'))
        .toString();
  }
}

class UserComments extends Table with TableInfo<UserComments, UserComment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  UserComments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sectionIndexMeta = const VerificationMeta(
    'sectionIndex',
  );
  late final GeneratedColumn<int> sectionIndex = GeneratedColumn<int>(
    'section_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _commentTextMeta = const VerificationMeta(
    'commentText',
  );
  late final GeneratedColumn<String> commentText = GeneratedColumn<String>(
    'comment_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _textPreviewMeta = const VerificationMeta(
    'textPreview',
  );
  late final GeneratedColumn<String> textPreview = GeneratedColumn<String>(
    'text_preview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    sectionIndex,
    nodeId,
    commentText,
    textPreview,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_comments';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserComment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('section_index')) {
      context.handle(
        _sectionIndexMeta,
        sectionIndex.isAcceptableOrUnknown(
          data['section_index']!,
          _sectionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionIndexMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('comment_text')) {
      context.handle(
        _commentTextMeta,
        commentText.isAcceptableOrUnknown(
          data['comment_text']!,
          _commentTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commentTextMeta);
    }
    if (data.containsKey('text_preview')) {
      context.handle(
        _textPreviewMeta,
        textPreview.isAcceptableOrUnknown(
          data['text_preview']!,
          _textPreviewMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserComment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserComment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      sectionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_index'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      commentText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment_text'],
      )!,
      textPreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_preview'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  UserComments createAlias(String alias) {
    return UserComments(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class UserComment extends DataClass implements Insertable<UserComment> {
  final int id;
  final String documentId;
  final int sectionIndex;
  final String nodeId;
  final String commentText;
  final String? textPreview;
  final DateTime createdAt;
  const UserComment({
    required this.id,
    required this.documentId,
    required this.sectionIndex,
    required this.nodeId,
    required this.commentText,
    this.textPreview,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document_id'] = Variable<String>(documentId);
    map['section_index'] = Variable<int>(sectionIndex);
    map['node_id'] = Variable<String>(nodeId);
    map['comment_text'] = Variable<String>(commentText);
    if (!nullToAbsent || textPreview != null) {
      map['text_preview'] = Variable<String>(textPreview);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserCommentsCompanion toCompanion(bool nullToAbsent) {
    return UserCommentsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      sectionIndex: Value(sectionIndex),
      nodeId: Value(nodeId),
      commentText: Value(commentText),
      textPreview: textPreview == null && nullToAbsent
          ? const Value.absent()
          : Value(textPreview),
      createdAt: Value(createdAt),
    );
  }

  factory UserComment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserComment(
      id: serializer.fromJson<int>(json['id']),
      documentId: serializer.fromJson<String>(json['document_id']),
      sectionIndex: serializer.fromJson<int>(json['section_index']),
      nodeId: serializer.fromJson<String>(json['node_id']),
      commentText: serializer.fromJson<String>(json['comment_text']),
      textPreview: serializer.fromJson<String?>(json['text_preview']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'document_id': serializer.toJson<String>(documentId),
      'section_index': serializer.toJson<int>(sectionIndex),
      'node_id': serializer.toJson<String>(nodeId),
      'comment_text': serializer.toJson<String>(commentText),
      'text_preview': serializer.toJson<String?>(textPreview),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserComment copyWith({
    int? id,
    String? documentId,
    int? sectionIndex,
    String? nodeId,
    String? commentText,
    Value<String?> textPreview = const Value.absent(),
    DateTime? createdAt,
  }) => UserComment(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    sectionIndex: sectionIndex ?? this.sectionIndex,
    nodeId: nodeId ?? this.nodeId,
    commentText: commentText ?? this.commentText,
    textPreview: textPreview.present ? textPreview.value : this.textPreview,
    createdAt: createdAt ?? this.createdAt,
  );
  UserComment copyWithCompanion(UserCommentsCompanion data) {
    return UserComment(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      sectionIndex: data.sectionIndex.present
          ? data.sectionIndex.value
          : this.sectionIndex,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      commentText: data.commentText.present
          ? data.commentText.value
          : this.commentText,
      textPreview: data.textPreview.present
          ? data.textPreview.value
          : this.textPreview,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserComment(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('nodeId: $nodeId, ')
          ..write('commentText: $commentText, ')
          ..write('textPreview: $textPreview, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    sectionIndex,
    nodeId,
    commentText,
    textPreview,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserComment &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.sectionIndex == this.sectionIndex &&
          other.nodeId == this.nodeId &&
          other.commentText == this.commentText &&
          other.textPreview == this.textPreview &&
          other.createdAt == this.createdAt);
}

class UserCommentsCompanion extends UpdateCompanion<UserComment> {
  final Value<int> id;
  final Value<String> documentId;
  final Value<int> sectionIndex;
  final Value<String> nodeId;
  final Value<String> commentText;
  final Value<String?> textPreview;
  final Value<DateTime> createdAt;
  const UserCommentsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.sectionIndex = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.commentText = const Value.absent(),
    this.textPreview = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserCommentsCompanion.insert({
    this.id = const Value.absent(),
    required String documentId,
    required int sectionIndex,
    required String nodeId,
    required String commentText,
    this.textPreview = const Value.absent(),
    required DateTime createdAt,
  }) : documentId = Value(documentId),
       sectionIndex = Value(sectionIndex),
       nodeId = Value(nodeId),
       commentText = Value(commentText),
       createdAt = Value(createdAt);
  static Insertable<UserComment> custom({
    Expression<int>? id,
    Expression<String>? documentId,
    Expression<int>? sectionIndex,
    Expression<String>? nodeId,
    Expression<String>? commentText,
    Expression<String>? textPreview,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (sectionIndex != null) 'section_index': sectionIndex,
      if (nodeId != null) 'node_id': nodeId,
      if (commentText != null) 'comment_text': commentText,
      if (textPreview != null) 'text_preview': textPreview,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserCommentsCompanion copyWith({
    Value<int>? id,
    Value<String>? documentId,
    Value<int>? sectionIndex,
    Value<String>? nodeId,
    Value<String>? commentText,
    Value<String?>? textPreview,
    Value<DateTime>? createdAt,
  }) {
    return UserCommentsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      sectionIndex: sectionIndex ?? this.sectionIndex,
      nodeId: nodeId ?? this.nodeId,
      commentText: commentText ?? this.commentText,
      textPreview: textPreview ?? this.textPreview,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (sectionIndex.present) {
      map['section_index'] = Variable<int>(sectionIndex.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (commentText.present) {
      map['comment_text'] = Variable<String>(commentText.value);
    }
    if (textPreview.present) {
      map['text_preview'] = Variable<String>(textPreview.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCommentsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('nodeId: $nodeId, ')
          ..write('commentText: $commentText, ')
          ..write('textPreview: $textPreview, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class LibraryBookmarks extends Table
    with TableInfo<LibraryBookmarks, LibraryBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LibraryBookmarks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sectionIndexMeta = const VerificationMeta(
    'sectionIndex',
  );
  late final GeneratedColumn<int> sectionIndex = GeneratedColumn<int>(
    'section_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _textPreviewMeta = const VerificationMeta(
    'textPreview',
  );
  late final GeneratedColumn<String> textPreview = GeneratedColumn<String>(
    'text_preview',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    sectionIndex,
    nodeId,
    textPreview,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryBookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('section_index')) {
      context.handle(
        _sectionIndexMeta,
        sectionIndex.isAcceptableOrUnknown(
          data['section_index']!,
          _sectionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionIndexMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('text_preview')) {
      context.handle(
        _textPreviewMeta,
        textPreview.isAcceptableOrUnknown(
          data['text_preview']!,
          _textPreviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textPreviewMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryBookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      sectionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_index'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      textPreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_preview'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  LibraryBookmarks createAlias(String alias) {
    return LibraryBookmarks(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class LibraryBookmark extends DataClass implements Insertable<LibraryBookmark> {
  final int id;
  final String documentId;
  final int sectionIndex;
  final String nodeId;
  final String textPreview;
  final DateTime createdAt;
  const LibraryBookmark({
    required this.id,
    required this.documentId,
    required this.sectionIndex,
    required this.nodeId,
    required this.textPreview,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document_id'] = Variable<String>(documentId);
    map['section_index'] = Variable<int>(sectionIndex);
    map['node_id'] = Variable<String>(nodeId);
    map['text_preview'] = Variable<String>(textPreview);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LibraryBookmarksCompanion toCompanion(bool nullToAbsent) {
    return LibraryBookmarksCompanion(
      id: Value(id),
      documentId: Value(documentId),
      sectionIndex: Value(sectionIndex),
      nodeId: Value(nodeId),
      textPreview: Value(textPreview),
      createdAt: Value(createdAt),
    );
  }

  factory LibraryBookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryBookmark(
      id: serializer.fromJson<int>(json['id']),
      documentId: serializer.fromJson<String>(json['document_id']),
      sectionIndex: serializer.fromJson<int>(json['section_index']),
      nodeId: serializer.fromJson<String>(json['node_id']),
      textPreview: serializer.fromJson<String>(json['text_preview']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'document_id': serializer.toJson<String>(documentId),
      'section_index': serializer.toJson<int>(sectionIndex),
      'node_id': serializer.toJson<String>(nodeId),
      'text_preview': serializer.toJson<String>(textPreview),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  LibraryBookmark copyWith({
    int? id,
    String? documentId,
    int? sectionIndex,
    String? nodeId,
    String? textPreview,
    DateTime? createdAt,
  }) => LibraryBookmark(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    sectionIndex: sectionIndex ?? this.sectionIndex,
    nodeId: nodeId ?? this.nodeId,
    textPreview: textPreview ?? this.textPreview,
    createdAt: createdAt ?? this.createdAt,
  );
  LibraryBookmark copyWithCompanion(LibraryBookmarksCompanion data) {
    return LibraryBookmark(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      sectionIndex: data.sectionIndex.present
          ? data.sectionIndex.value
          : this.sectionIndex,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      textPreview: data.textPreview.present
          ? data.textPreview.value
          : this.textPreview,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryBookmark(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('nodeId: $nodeId, ')
          ..write('textPreview: $textPreview, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, documentId, sectionIndex, nodeId, textPreview, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryBookmark &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.sectionIndex == this.sectionIndex &&
          other.nodeId == this.nodeId &&
          other.textPreview == this.textPreview &&
          other.createdAt == this.createdAt);
}

class LibraryBookmarksCompanion extends UpdateCompanion<LibraryBookmark> {
  final Value<int> id;
  final Value<String> documentId;
  final Value<int> sectionIndex;
  final Value<String> nodeId;
  final Value<String> textPreview;
  final Value<DateTime> createdAt;
  const LibraryBookmarksCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.sectionIndex = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.textPreview = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LibraryBookmarksCompanion.insert({
    this.id = const Value.absent(),
    required String documentId,
    required int sectionIndex,
    required String nodeId,
    required String textPreview,
    required DateTime createdAt,
  }) : documentId = Value(documentId),
       sectionIndex = Value(sectionIndex),
       nodeId = Value(nodeId),
       textPreview = Value(textPreview),
       createdAt = Value(createdAt);
  static Insertable<LibraryBookmark> custom({
    Expression<int>? id,
    Expression<String>? documentId,
    Expression<int>? sectionIndex,
    Expression<String>? nodeId,
    Expression<String>? textPreview,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (sectionIndex != null) 'section_index': sectionIndex,
      if (nodeId != null) 'node_id': nodeId,
      if (textPreview != null) 'text_preview': textPreview,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LibraryBookmarksCompanion copyWith({
    Value<int>? id,
    Value<String>? documentId,
    Value<int>? sectionIndex,
    Value<String>? nodeId,
    Value<String>? textPreview,
    Value<DateTime>? createdAt,
  }) {
    return LibraryBookmarksCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      sectionIndex: sectionIndex ?? this.sectionIndex,
      nodeId: nodeId ?? this.nodeId,
      textPreview: textPreview ?? this.textPreview,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (sectionIndex.present) {
      map['section_index'] = Variable<int>(sectionIndex.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (textPreview.present) {
      map['text_preview'] = Variable<String>(textPreview.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('nodeId: $nodeId, ')
          ..write('textPreview: $textPreview, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PrayersTable extends Prayers with TableInfo<$PrayersTable, Prayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _isarIdMeta = const VerificationMeta('isarId');
  @override
  late final GeneratedColumn<int> isarId = GeneratedColumn<int>(
    'isar_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _prayerIdMeta = const VerificationMeta(
    'prayerId',
  );
  @override
  late final GeneratedColumn<String> prayerId = GeneratedColumn<String>(
    'prayer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _defaultTitleMeta = const VerificationMeta(
    'defaultTitle',
  );
  @override
  late final GeneratedColumn<String> defaultTitle = GeneratedColumn<String>(
    'default_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultOrderMeta = const VerificationMeta(
    'defaultOrder',
  );
  @override
  late final GeneratedColumn<int> defaultOrder = GeneratedColumn<int>(
    'default_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasAmenMeta = const VerificationMeta(
    'hasAmen',
  );
  @override
  late final GeneratedColumn<bool> hasAmen = GeneratedColumn<bool>(
    'has_amen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_amen" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    List<LocalizedTranslations>?,
    String
  >
  localizedTranslations =
      GeneratedColumn<String>(
        'localized_translations',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<LocalizedTranslations>?>(
        $PrayersTable.$converterlocalizedTranslations,
      );
  @override
  List<GeneratedColumn> get $columns => [
    isarId,
    prayerId,
    defaultTitle,
    category,
    defaultOrder,
    hasAmen,
    hash,
    localizedTranslations,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('isar_id')) {
      context.handle(
        _isarIdMeta,
        isarId.isAcceptableOrUnknown(data['isar_id']!, _isarIdMeta),
      );
    }
    if (data.containsKey('prayer_id')) {
      context.handle(
        _prayerIdMeta,
        prayerId.isAcceptableOrUnknown(data['prayer_id']!, _prayerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerIdMeta);
    }
    if (data.containsKey('default_title')) {
      context.handle(
        _defaultTitleMeta,
        defaultTitle.isAcceptableOrUnknown(
          data['default_title']!,
          _defaultTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultTitleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('default_order')) {
      context.handle(
        _defaultOrderMeta,
        defaultOrder.isAcceptableOrUnknown(
          data['default_order']!,
          _defaultOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultOrderMeta);
    }
    if (data.containsKey('has_amen')) {
      context.handle(
        _hasAmenMeta,
        hasAmen.isAcceptableOrUnknown(data['has_amen']!, _hasAmenMeta),
      );
    } else if (isInserting) {
      context.missing(_hasAmenMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {isarId};
  @override
  Prayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prayer(
      isarId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}isar_id'],
      )!,
      prayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prayer_id'],
      )!,
      defaultTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      defaultOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_order'],
      )!,
      hasAmen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_amen'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      localizedTranslations: $PrayersTable.$converterlocalizedTranslations
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}localized_translations'],
            ),
          ),
    );
  }

  @override
  $PrayersTable createAlias(String alias) {
    return $PrayersTable(attachedDatabase, alias);
  }

  static TypeConverter<List<LocalizedTranslations>?, String?>
  $converterlocalizedTranslations = NullAwareTypeConverter.wrap(
    const LocalizedTranslationsConverter(),
  );
}

class PrayersCompanion extends UpdateCompanion<Prayer> {
  final Value<int> isarId;
  final Value<String> prayerId;
  final Value<String> defaultTitle;
  final Value<String> category;
  final Value<int> defaultOrder;
  final Value<bool> hasAmen;
  final Value<String> hash;
  final Value<List<LocalizedTranslations>?> localizedTranslations;
  const PrayersCompanion({
    this.isarId = const Value.absent(),
    this.prayerId = const Value.absent(),
    this.defaultTitle = const Value.absent(),
    this.category = const Value.absent(),
    this.defaultOrder = const Value.absent(),
    this.hasAmen = const Value.absent(),
    this.hash = const Value.absent(),
    this.localizedTranslations = const Value.absent(),
  });
  PrayersCompanion.insert({
    this.isarId = const Value.absent(),
    required String prayerId,
    required String defaultTitle,
    required String category,
    required int defaultOrder,
    required bool hasAmen,
    required String hash,
    this.localizedTranslations = const Value.absent(),
  }) : prayerId = Value(prayerId),
       defaultTitle = Value(defaultTitle),
       category = Value(category),
       defaultOrder = Value(defaultOrder),
       hasAmen = Value(hasAmen),
       hash = Value(hash);
  static Insertable<Prayer> custom({
    Expression<int>? isarId,
    Expression<String>? prayerId,
    Expression<String>? defaultTitle,
    Expression<String>? category,
    Expression<int>? defaultOrder,
    Expression<bool>? hasAmen,
    Expression<String>? hash,
    Expression<String>? localizedTranslations,
  }) {
    return RawValuesInsertable({
      if (isarId != null) 'isar_id': isarId,
      if (prayerId != null) 'prayer_id': prayerId,
      if (defaultTitle != null) 'default_title': defaultTitle,
      if (category != null) 'category': category,
      if (defaultOrder != null) 'default_order': defaultOrder,
      if (hasAmen != null) 'has_amen': hasAmen,
      if (hash != null) 'hash': hash,
      if (localizedTranslations != null)
        'localized_translations': localizedTranslations,
    });
  }

  PrayersCompanion copyWith({
    Value<int>? isarId,
    Value<String>? prayerId,
    Value<String>? defaultTitle,
    Value<String>? category,
    Value<int>? defaultOrder,
    Value<bool>? hasAmen,
    Value<String>? hash,
    Value<List<LocalizedTranslations>?>? localizedTranslations,
  }) {
    return PrayersCompanion(
      isarId: isarId ?? this.isarId,
      prayerId: prayerId ?? this.prayerId,
      defaultTitle: defaultTitle ?? this.defaultTitle,
      category: category ?? this.category,
      defaultOrder: defaultOrder ?? this.defaultOrder,
      hasAmen: hasAmen ?? this.hasAmen,
      hash: hash ?? this.hash,
      localizedTranslations:
          localizedTranslations ?? this.localizedTranslations,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (isarId.present) {
      map['isar_id'] = Variable<int>(isarId.value);
    }
    if (prayerId.present) {
      map['prayer_id'] = Variable<String>(prayerId.value);
    }
    if (defaultTitle.present) {
      map['default_title'] = Variable<String>(defaultTitle.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (defaultOrder.present) {
      map['default_order'] = Variable<int>(defaultOrder.value);
    }
    if (hasAmen.present) {
      map['has_amen'] = Variable<bool>(hasAmen.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (localizedTranslations.present) {
      map['localized_translations'] = Variable<String>(
        $PrayersTable.$converterlocalizedTranslations.toSql(
          localizedTranslations.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayersCompanion(')
          ..write('isarId: $isarId, ')
          ..write('prayerId: $prayerId, ')
          ..write('defaultTitle: $defaultTitle, ')
          ..write('category: $category, ')
          ..write('defaultOrder: $defaultOrder, ')
          ..write('hasAmen: $hasAmen, ')
          ..write('hash: $hash, ')
          ..write('localizedTranslations: $localizedTranslations')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTableTable extends UserSettingsTable
    with TableInfo<$UserSettingsTableTable, UserSettings> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _primaryLanguageCodeMeta =
      const VerificationMeta('primaryLanguageCode');
  @override
  late final GeneratedColumn<String> primaryLanguageCode =
      GeneratedColumn<String>(
        'primary_language_code',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _compareLanguageCodeMeta =
      const VerificationMeta('compareLanguageCode');
  @override
  late final GeneratedColumn<String> compareLanguageCode =
      GeneratedColumn<String>(
        'compare_language_code',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _primaryBibleTranslationMeta =
      const VerificationMeta('primaryBibleTranslation');
  @override
  late final GeneratedColumn<String> primaryBibleTranslation =
      GeneratedColumn<String>(
        'primary_bible_translation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _compareBibleTranslationMeta =
      const VerificationMeta('compareBibleTranslation');
  @override
  late final GeneratedColumn<String> compareBibleTranslation =
      GeneratedColumn<String>(
        'compare_bible_translation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<
    List<PrayerVersionPreference>?,
    String
  >
  preferredVersions =
      GeneratedColumn<String>(
        'preferred_versions',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<PrayerVersionPreference>?>(
        $UserSettingsTableTable.$converterpreferredVersions,
      );
  static const VerificationMeta _hapticsEnabledMeta = const VerificationMeta(
    'hapticsEnabled',
  );
  @override
  late final GeneratedColumn<bool> hapticsEnabled = GeneratedColumn<bool>(
    'haptics_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("haptics_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _appThemeModeCodeMeta = const VerificationMeta(
    'appThemeModeCode',
  );
  @override
  late final GeneratedColumn<String> appThemeModeCode = GeneratedColumn<String>(
    'app_theme_mode_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('marian_blue'),
  );
  static const VerificationMeta _sundayNotificationsEnabledMeta =
      const VerificationMeta('sundayNotificationsEnabled');
  @override
  late final GeneratedColumn<bool> sundayNotificationsEnabled =
      GeneratedColumn<bool>(
        'sunday_notifications_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sunday_notifications_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _showBibleTranslationSelectorsMeta =
      const VerificationMeta('showBibleTranslationSelectors');
  @override
  late final GeneratedColumn<bool> showBibleTranslationSelectors =
      GeneratedColumn<bool>(
        'show_bible_translation_selectors',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_bible_translation_selectors" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    primaryLanguageCode,
    compareLanguageCode,
    primaryBibleTranslation,
    compareBibleTranslation,
    preferredVersions,
    hapticsEnabled,
    appThemeModeCode,
    sundayNotificationsEnabled,
    showBibleTranslationSelectors,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSettings> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('primary_language_code')) {
      context.handle(
        _primaryLanguageCodeMeta,
        primaryLanguageCode.isAcceptableOrUnknown(
          data['primary_language_code']!,
          _primaryLanguageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primaryLanguageCodeMeta);
    }
    if (data.containsKey('compare_language_code')) {
      context.handle(
        _compareLanguageCodeMeta,
        compareLanguageCode.isAcceptableOrUnknown(
          data['compare_language_code']!,
          _compareLanguageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_compareLanguageCodeMeta);
    }
    if (data.containsKey('primary_bible_translation')) {
      context.handle(
        _primaryBibleTranslationMeta,
        primaryBibleTranslation.isAcceptableOrUnknown(
          data['primary_bible_translation']!,
          _primaryBibleTranslationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primaryBibleTranslationMeta);
    }
    if (data.containsKey('compare_bible_translation')) {
      context.handle(
        _compareBibleTranslationMeta,
        compareBibleTranslation.isAcceptableOrUnknown(
          data['compare_bible_translation']!,
          _compareBibleTranslationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_compareBibleTranslationMeta);
    }
    if (data.containsKey('haptics_enabled')) {
      context.handle(
        _hapticsEnabledMeta,
        hapticsEnabled.isAcceptableOrUnknown(
          data['haptics_enabled']!,
          _hapticsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('app_theme_mode_code')) {
      context.handle(
        _appThemeModeCodeMeta,
        appThemeModeCode.isAcceptableOrUnknown(
          data['app_theme_mode_code']!,
          _appThemeModeCodeMeta,
        ),
      );
    }
    if (data.containsKey('sunday_notifications_enabled')) {
      context.handle(
        _sundayNotificationsEnabledMeta,
        sundayNotificationsEnabled.isAcceptableOrUnknown(
          data['sunday_notifications_enabled']!,
          _sundayNotificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('show_bible_translation_selectors')) {
      context.handle(
        _showBibleTranslationSelectorsMeta,
        showBibleTranslationSelectors.isAcceptableOrUnknown(
          data['show_bible_translation_selectors']!,
          _showBibleTranslationSelectorsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettings map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettings(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      primaryLanguageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_language_code'],
      )!,
      compareLanguageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}compare_language_code'],
      )!,
      primaryBibleTranslation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_bible_translation'],
      )!,
      compareBibleTranslation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}compare_bible_translation'],
      )!,
      preferredVersions: $UserSettingsTableTable.$converterpreferredVersions
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}preferred_versions'],
            ),
          ),
      hapticsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}haptics_enabled'],
      )!,
      appThemeModeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_theme_mode_code'],
      )!,
      sundayNotificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sunday_notifications_enabled'],
      )!,
      showBibleTranslationSelectors: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_bible_translation_selectors'],
      )!,
    );
  }

  @override
  $UserSettingsTableTable createAlias(String alias) {
    return $UserSettingsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<PrayerVersionPreference>?, String?>
  $converterpreferredVersions = NullAwareTypeConverter.wrap(
    const PreferredVersionsConverter(),
  );
}

class UserSettingsTableCompanion extends UpdateCompanion<UserSettings> {
  final Value<int> id;
  final Value<String> primaryLanguageCode;
  final Value<String> compareLanguageCode;
  final Value<String> primaryBibleTranslation;
  final Value<String> compareBibleTranslation;
  final Value<List<PrayerVersionPreference>?> preferredVersions;
  final Value<bool> hapticsEnabled;
  final Value<String> appThemeModeCode;
  final Value<bool> sundayNotificationsEnabled;
  final Value<bool> showBibleTranslationSelectors;
  const UserSettingsTableCompanion({
    this.id = const Value.absent(),
    this.primaryLanguageCode = const Value.absent(),
    this.compareLanguageCode = const Value.absent(),
    this.primaryBibleTranslation = const Value.absent(),
    this.compareBibleTranslation = const Value.absent(),
    this.preferredVersions = const Value.absent(),
    this.hapticsEnabled = const Value.absent(),
    this.appThemeModeCode = const Value.absent(),
    this.sundayNotificationsEnabled = const Value.absent(),
    this.showBibleTranslationSelectors = const Value.absent(),
  });
  UserSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String primaryLanguageCode,
    required String compareLanguageCode,
    required String primaryBibleTranslation,
    required String compareBibleTranslation,
    this.preferredVersions = const Value.absent(),
    this.hapticsEnabled = const Value.absent(),
    this.appThemeModeCode = const Value.absent(),
    this.sundayNotificationsEnabled = const Value.absent(),
    this.showBibleTranslationSelectors = const Value.absent(),
  }) : primaryLanguageCode = Value(primaryLanguageCode),
       compareLanguageCode = Value(compareLanguageCode),
       primaryBibleTranslation = Value(primaryBibleTranslation),
       compareBibleTranslation = Value(compareBibleTranslation);
  static Insertable<UserSettings> custom({
    Expression<int>? id,
    Expression<String>? primaryLanguageCode,
    Expression<String>? compareLanguageCode,
    Expression<String>? primaryBibleTranslation,
    Expression<String>? compareBibleTranslation,
    Expression<String>? preferredVersions,
    Expression<bool>? hapticsEnabled,
    Expression<String>? appThemeModeCode,
    Expression<bool>? sundayNotificationsEnabled,
    Expression<bool>? showBibleTranslationSelectors,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (primaryLanguageCode != null)
        'primary_language_code': primaryLanguageCode,
      if (compareLanguageCode != null)
        'compare_language_code': compareLanguageCode,
      if (primaryBibleTranslation != null)
        'primary_bible_translation': primaryBibleTranslation,
      if (compareBibleTranslation != null)
        'compare_bible_translation': compareBibleTranslation,
      if (preferredVersions != null) 'preferred_versions': preferredVersions,
      if (hapticsEnabled != null) 'haptics_enabled': hapticsEnabled,
      if (appThemeModeCode != null) 'app_theme_mode_code': appThemeModeCode,
      if (sundayNotificationsEnabled != null)
        'sunday_notifications_enabled': sundayNotificationsEnabled,
      if (showBibleTranslationSelectors != null)
        'show_bible_translation_selectors': showBibleTranslationSelectors,
    });
  }

  UserSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? primaryLanguageCode,
    Value<String>? compareLanguageCode,
    Value<String>? primaryBibleTranslation,
    Value<String>? compareBibleTranslation,
    Value<List<PrayerVersionPreference>?>? preferredVersions,
    Value<bool>? hapticsEnabled,
    Value<String>? appThemeModeCode,
    Value<bool>? sundayNotificationsEnabled,
    Value<bool>? showBibleTranslationSelectors,
  }) {
    return UserSettingsTableCompanion(
      id: id ?? this.id,
      primaryLanguageCode: primaryLanguageCode ?? this.primaryLanguageCode,
      compareLanguageCode: compareLanguageCode ?? this.compareLanguageCode,
      primaryBibleTranslation:
          primaryBibleTranslation ?? this.primaryBibleTranslation,
      compareBibleTranslation:
          compareBibleTranslation ?? this.compareBibleTranslation,
      preferredVersions: preferredVersions ?? this.preferredVersions,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      appThemeModeCode: appThemeModeCode ?? this.appThemeModeCode,
      sundayNotificationsEnabled:
          sundayNotificationsEnabled ?? this.sundayNotificationsEnabled,
      showBibleTranslationSelectors:
          showBibleTranslationSelectors ?? this.showBibleTranslationSelectors,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (primaryLanguageCode.present) {
      map['primary_language_code'] = Variable<String>(
        primaryLanguageCode.value,
      );
    }
    if (compareLanguageCode.present) {
      map['compare_language_code'] = Variable<String>(
        compareLanguageCode.value,
      );
    }
    if (primaryBibleTranslation.present) {
      map['primary_bible_translation'] = Variable<String>(
        primaryBibleTranslation.value,
      );
    }
    if (compareBibleTranslation.present) {
      map['compare_bible_translation'] = Variable<String>(
        compareBibleTranslation.value,
      );
    }
    if (preferredVersions.present) {
      map['preferred_versions'] = Variable<String>(
        $UserSettingsTableTable.$converterpreferredVersions.toSql(
          preferredVersions.value,
        ),
      );
    }
    if (hapticsEnabled.present) {
      map['haptics_enabled'] = Variable<bool>(hapticsEnabled.value);
    }
    if (appThemeModeCode.present) {
      map['app_theme_mode_code'] = Variable<String>(appThemeModeCode.value);
    }
    if (sundayNotificationsEnabled.present) {
      map['sunday_notifications_enabled'] = Variable<bool>(
        sundayNotificationsEnabled.value,
      );
    }
    if (showBibleTranslationSelectors.present) {
      map['show_bible_translation_selectors'] = Variable<bool>(
        showBibleTranslationSelectors.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('primaryLanguageCode: $primaryLanguageCode, ')
          ..write('compareLanguageCode: $compareLanguageCode, ')
          ..write('primaryBibleTranslation: $primaryBibleTranslation, ')
          ..write('compareBibleTranslation: $compareBibleTranslation, ')
          ..write('preferredVersions: $preferredVersions, ')
          ..write('hapticsEnabled: $hapticsEnabled, ')
          ..write('appThemeModeCode: $appThemeModeCode, ')
          ..write('sundayNotificationsEnabled: $sundayNotificationsEnabled, ')
          ..write(
            'showBibleTranslationSelectors: $showBibleTranslationSelectors',
          )
          ..write(')'))
        .toString();
  }
}

abstract class _$BibleDatabase extends GeneratedDatabase {
  _$BibleDatabase(QueryExecutor e) : super(e);
  $BibleDatabaseManager get managers => $BibleDatabaseManager(this);
  late final BibleVerses bibleVerses = BibleVerses(this);
  late final LectionaryReadings lectionaryReadings = LectionaryReadings(this);
  late final FavoritePassages favoritePassages = FavoritePassages(this);
  late final UserComments userComments = UserComments(this);
  late final LibraryBookmarks libraryBookmarks = LibraryBookmarks(this);
  late final $PrayersTable prayers = $PrayersTable(this);
  late final $UserSettingsTableTable userSettingsTable =
      $UserSettingsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bibleVerses,
    lectionaryReadings,
    favoritePassages,
    userComments,
    libraryBookmarks,
    prayers,
    userSettingsTable,
  ];
}

typedef $BibleVersesCreateCompanionBuilder =
    BibleVersesCompanion Function({
      Value<int> id,
      required int bookNumber,
      required String bookName,
      required int chapter,
      required int verseNumber,
      required String verseText,
      required String translationCode,
    });
typedef $BibleVersesUpdateCompanionBuilder =
    BibleVersesCompanion Function({
      Value<int> id,
      Value<int> bookNumber,
      Value<String> bookName,
      Value<int> chapter,
      Value<int> verseNumber,
      Value<String> verseText,
      Value<String> translationCode,
    });

class $BibleVersesFilterComposer
    extends Composer<_$BibleDatabase, BibleVerses> {
  $BibleVersesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookNumber => $composableBuilder(
    column: $table.bookNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verseNumber => $composableBuilder(
    column: $table.verseNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verseText => $composableBuilder(
    column: $table.verseText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationCode => $composableBuilder(
    column: $table.translationCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $BibleVersesOrderingComposer
    extends Composer<_$BibleDatabase, BibleVerses> {
  $BibleVersesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookNumber => $composableBuilder(
    column: $table.bookNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verseNumber => $composableBuilder(
    column: $table.verseNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verseText => $composableBuilder(
    column: $table.verseText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationCode => $composableBuilder(
    column: $table.translationCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $BibleVersesAnnotationComposer
    extends Composer<_$BibleDatabase, BibleVerses> {
  $BibleVersesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get bookNumber => $composableBuilder(
    column: $table.bookNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get verseNumber => $composableBuilder(
    column: $table.verseNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verseText =>
      $composableBuilder(column: $table.verseText, builder: (column) => column);

  GeneratedColumn<String> get translationCode => $composableBuilder(
    column: $table.translationCode,
    builder: (column) => column,
  );
}

class $BibleVersesTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          BibleVerses,
          BibleVerse,
          $BibleVersesFilterComposer,
          $BibleVersesOrderingComposer,
          $BibleVersesAnnotationComposer,
          $BibleVersesCreateCompanionBuilder,
          $BibleVersesUpdateCompanionBuilder,
          (
            BibleVerse,
            BaseReferences<_$BibleDatabase, BibleVerses, BibleVerse>,
          ),
          BibleVerse,
          PrefetchHooks Function()
        > {
  $BibleVersesTableManager(_$BibleDatabase db, BibleVerses table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $BibleVersesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $BibleVersesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $BibleVersesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookNumber = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> verseNumber = const Value.absent(),
                Value<String> verseText = const Value.absent(),
                Value<String> translationCode = const Value.absent(),
              }) => BibleVersesCompanion(
                id: id,
                bookNumber: bookNumber,
                bookName: bookName,
                chapter: chapter,
                verseNumber: verseNumber,
                verseText: verseText,
                translationCode: translationCode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookNumber,
                required String bookName,
                required int chapter,
                required int verseNumber,
                required String verseText,
                required String translationCode,
              }) => BibleVersesCompanion.insert(
                id: id,
                bookNumber: bookNumber,
                bookName: bookName,
                chapter: chapter,
                verseNumber: verseNumber,
                verseText: verseText,
                translationCode: translationCode,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $BibleVersesProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      BibleVerses,
      BibleVerse,
      $BibleVersesFilterComposer,
      $BibleVersesOrderingComposer,
      $BibleVersesAnnotationComposer,
      $BibleVersesCreateCompanionBuilder,
      $BibleVersesUpdateCompanionBuilder,
      (BibleVerse, BaseReferences<_$BibleDatabase, BibleVerses, BibleVerse>),
      BibleVerse,
      PrefetchHooks Function()
    >;
typedef $LectionaryReadingsCreateCompanionBuilder =
    LectionaryReadingsCompanion Function({
      Value<int> id,
      required String readingKey,
      required String readingType,
      required int bookNumber,
      required String bookName,
      required int chapter,
      required String verseRange,
      required String citation,
    });
typedef $LectionaryReadingsUpdateCompanionBuilder =
    LectionaryReadingsCompanion Function({
      Value<int> id,
      Value<String> readingKey,
      Value<String> readingType,
      Value<int> bookNumber,
      Value<String> bookName,
      Value<int> chapter,
      Value<String> verseRange,
      Value<String> citation,
    });

class $LectionaryReadingsFilterComposer
    extends Composer<_$BibleDatabase, LectionaryReadings> {
  $LectionaryReadingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readingKey => $composableBuilder(
    column: $table.readingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readingType => $composableBuilder(
    column: $table.readingType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookNumber => $composableBuilder(
    column: $table.bookNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verseRange => $composableBuilder(
    column: $table.verseRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get citation => $composableBuilder(
    column: $table.citation,
    builder: (column) => ColumnFilters(column),
  );
}

class $LectionaryReadingsOrderingComposer
    extends Composer<_$BibleDatabase, LectionaryReadings> {
  $LectionaryReadingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingKey => $composableBuilder(
    column: $table.readingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingType => $composableBuilder(
    column: $table.readingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookNumber => $composableBuilder(
    column: $table.bookNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verseRange => $composableBuilder(
    column: $table.verseRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get citation => $composableBuilder(
    column: $table.citation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LectionaryReadingsAnnotationComposer
    extends Composer<_$BibleDatabase, LectionaryReadings> {
  $LectionaryReadingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get readingKey => $composableBuilder(
    column: $table.readingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readingType => $composableBuilder(
    column: $table.readingType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bookNumber => $composableBuilder(
    column: $table.bookNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<String> get verseRange => $composableBuilder(
    column: $table.verseRange,
    builder: (column) => column,
  );

  GeneratedColumn<String> get citation =>
      $composableBuilder(column: $table.citation, builder: (column) => column);
}

class $LectionaryReadingsTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          LectionaryReadings,
          LectionaryReading,
          $LectionaryReadingsFilterComposer,
          $LectionaryReadingsOrderingComposer,
          $LectionaryReadingsAnnotationComposer,
          $LectionaryReadingsCreateCompanionBuilder,
          $LectionaryReadingsUpdateCompanionBuilder,
          (
            LectionaryReading,
            BaseReferences<
              _$BibleDatabase,
              LectionaryReadings,
              LectionaryReading
            >,
          ),
          LectionaryReading,
          PrefetchHooks Function()
        > {
  $LectionaryReadingsTableManager(_$BibleDatabase db, LectionaryReadings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LectionaryReadingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LectionaryReadingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LectionaryReadingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> readingKey = const Value.absent(),
                Value<String> readingType = const Value.absent(),
                Value<int> bookNumber = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<String> verseRange = const Value.absent(),
                Value<String> citation = const Value.absent(),
              }) => LectionaryReadingsCompanion(
                id: id,
                readingKey: readingKey,
                readingType: readingType,
                bookNumber: bookNumber,
                bookName: bookName,
                chapter: chapter,
                verseRange: verseRange,
                citation: citation,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String readingKey,
                required String readingType,
                required int bookNumber,
                required String bookName,
                required int chapter,
                required String verseRange,
                required String citation,
              }) => LectionaryReadingsCompanion.insert(
                id: id,
                readingKey: readingKey,
                readingType: readingType,
                bookNumber: bookNumber,
                bookName: bookName,
                chapter: chapter,
                verseRange: verseRange,
                citation: citation,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LectionaryReadingsProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      LectionaryReadings,
      LectionaryReading,
      $LectionaryReadingsFilterComposer,
      $LectionaryReadingsOrderingComposer,
      $LectionaryReadingsAnnotationComposer,
      $LectionaryReadingsCreateCompanionBuilder,
      $LectionaryReadingsUpdateCompanionBuilder,
      (
        LectionaryReading,
        BaseReferences<_$BibleDatabase, LectionaryReadings, LectionaryReading>,
      ),
      LectionaryReading,
      PrefetchHooks Function()
    >;
typedef $FavoritePassagesCreateCompanionBuilder =
    FavoritePassagesCompanion Function({
      Value<int> id,
      required int bookNumber,
      required String bookName,
      required int chapter,
      required int startVerse,
      required int endVerse,
      required String textPreview,
    });
typedef $FavoritePassagesUpdateCompanionBuilder =
    FavoritePassagesCompanion Function({
      Value<int> id,
      Value<int> bookNumber,
      Value<String> bookName,
      Value<int> chapter,
      Value<int> startVerse,
      Value<int> endVerse,
      Value<String> textPreview,
    });

class $FavoritePassagesFilterComposer
    extends Composer<_$BibleDatabase, FavoritePassages> {
  $FavoritePassagesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookNumber => $composableBuilder(
    column: $table.bookNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textPreview => $composableBuilder(
    column: $table.textPreview,
    builder: (column) => ColumnFilters(column),
  );
}

class $FavoritePassagesOrderingComposer
    extends Composer<_$BibleDatabase, FavoritePassages> {
  $FavoritePassagesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookNumber => $composableBuilder(
    column: $table.bookNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textPreview => $composableBuilder(
    column: $table.textPreview,
    builder: (column) => ColumnOrderings(column),
  );
}

class $FavoritePassagesAnnotationComposer
    extends Composer<_$BibleDatabase, FavoritePassages> {
  $FavoritePassagesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get bookNumber => $composableBuilder(
    column: $table.bookNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  GeneratedColumn<String> get textPreview => $composableBuilder(
    column: $table.textPreview,
    builder: (column) => column,
  );
}

class $FavoritePassagesTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          FavoritePassages,
          FavoritePassage,
          $FavoritePassagesFilterComposer,
          $FavoritePassagesOrderingComposer,
          $FavoritePassagesAnnotationComposer,
          $FavoritePassagesCreateCompanionBuilder,
          $FavoritePassagesUpdateCompanionBuilder,
          (
            FavoritePassage,
            BaseReferences<_$BibleDatabase, FavoritePassages, FavoritePassage>,
          ),
          FavoritePassage,
          PrefetchHooks Function()
        > {
  $FavoritePassagesTableManager(_$BibleDatabase db, FavoritePassages table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FavoritePassagesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FavoritePassagesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FavoritePassagesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookNumber = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> startVerse = const Value.absent(),
                Value<int> endVerse = const Value.absent(),
                Value<String> textPreview = const Value.absent(),
              }) => FavoritePassagesCompanion(
                id: id,
                bookNumber: bookNumber,
                bookName: bookName,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                textPreview: textPreview,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookNumber,
                required String bookName,
                required int chapter,
                required int startVerse,
                required int endVerse,
                required String textPreview,
              }) => FavoritePassagesCompanion.insert(
                id: id,
                bookNumber: bookNumber,
                bookName: bookName,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                textPreview: textPreview,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $FavoritePassagesProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      FavoritePassages,
      FavoritePassage,
      $FavoritePassagesFilterComposer,
      $FavoritePassagesOrderingComposer,
      $FavoritePassagesAnnotationComposer,
      $FavoritePassagesCreateCompanionBuilder,
      $FavoritePassagesUpdateCompanionBuilder,
      (
        FavoritePassage,
        BaseReferences<_$BibleDatabase, FavoritePassages, FavoritePassage>,
      ),
      FavoritePassage,
      PrefetchHooks Function()
    >;
typedef $UserCommentsCreateCompanionBuilder =
    UserCommentsCompanion Function({
      Value<int> id,
      required String documentId,
      required int sectionIndex,
      required String nodeId,
      required String commentText,
      Value<String?> textPreview,
      required DateTime createdAt,
    });
typedef $UserCommentsUpdateCompanionBuilder =
    UserCommentsCompanion Function({
      Value<int> id,
      Value<String> documentId,
      Value<int> sectionIndex,
      Value<String> nodeId,
      Value<String> commentText,
      Value<String?> textPreview,
      Value<DateTime> createdAt,
    });

class $UserCommentsFilterComposer
    extends Composer<_$BibleDatabase, UserComments> {
  $UserCommentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commentText => $composableBuilder(
    column: $table.commentText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textPreview => $composableBuilder(
    column: $table.textPreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $UserCommentsOrderingComposer
    extends Composer<_$BibleDatabase, UserComments> {
  $UserCommentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commentText => $composableBuilder(
    column: $table.commentText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textPreview => $composableBuilder(
    column: $table.textPreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $UserCommentsAnnotationComposer
    extends Composer<_$BibleDatabase, UserComments> {
  $UserCommentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get commentText => $composableBuilder(
    column: $table.commentText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textPreview => $composableBuilder(
    column: $table.textPreview,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $UserCommentsTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          UserComments,
          UserComment,
          $UserCommentsFilterComposer,
          $UserCommentsOrderingComposer,
          $UserCommentsAnnotationComposer,
          $UserCommentsCreateCompanionBuilder,
          $UserCommentsUpdateCompanionBuilder,
          (
            UserComment,
            BaseReferences<_$BibleDatabase, UserComments, UserComment>,
          ),
          UserComment,
          PrefetchHooks Function()
        > {
  $UserCommentsTableManager(_$BibleDatabase db, UserComments table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $UserCommentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $UserCommentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $UserCommentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> sectionIndex = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> commentText = const Value.absent(),
                Value<String?> textPreview = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserCommentsCompanion(
                id: id,
                documentId: documentId,
                sectionIndex: sectionIndex,
                nodeId: nodeId,
                commentText: commentText,
                textPreview: textPreview,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String documentId,
                required int sectionIndex,
                required String nodeId,
                required String commentText,
                Value<String?> textPreview = const Value.absent(),
                required DateTime createdAt,
              }) => UserCommentsCompanion.insert(
                id: id,
                documentId: documentId,
                sectionIndex: sectionIndex,
                nodeId: nodeId,
                commentText: commentText,
                textPreview: textPreview,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $UserCommentsProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      UserComments,
      UserComment,
      $UserCommentsFilterComposer,
      $UserCommentsOrderingComposer,
      $UserCommentsAnnotationComposer,
      $UserCommentsCreateCompanionBuilder,
      $UserCommentsUpdateCompanionBuilder,
      (UserComment, BaseReferences<_$BibleDatabase, UserComments, UserComment>),
      UserComment,
      PrefetchHooks Function()
    >;
typedef $LibraryBookmarksCreateCompanionBuilder =
    LibraryBookmarksCompanion Function({
      Value<int> id,
      required String documentId,
      required int sectionIndex,
      required String nodeId,
      required String textPreview,
      required DateTime createdAt,
    });
typedef $LibraryBookmarksUpdateCompanionBuilder =
    LibraryBookmarksCompanion Function({
      Value<int> id,
      Value<String> documentId,
      Value<int> sectionIndex,
      Value<String> nodeId,
      Value<String> textPreview,
      Value<DateTime> createdAt,
    });

class $LibraryBookmarksFilterComposer
    extends Composer<_$BibleDatabase, LibraryBookmarks> {
  $LibraryBookmarksFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textPreview => $composableBuilder(
    column: $table.textPreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $LibraryBookmarksOrderingComposer
    extends Composer<_$BibleDatabase, LibraryBookmarks> {
  $LibraryBookmarksOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textPreview => $composableBuilder(
    column: $table.textPreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LibraryBookmarksAnnotationComposer
    extends Composer<_$BibleDatabase, LibraryBookmarks> {
  $LibraryBookmarksAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get textPreview => $composableBuilder(
    column: $table.textPreview,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $LibraryBookmarksTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          LibraryBookmarks,
          LibraryBookmark,
          $LibraryBookmarksFilterComposer,
          $LibraryBookmarksOrderingComposer,
          $LibraryBookmarksAnnotationComposer,
          $LibraryBookmarksCreateCompanionBuilder,
          $LibraryBookmarksUpdateCompanionBuilder,
          (
            LibraryBookmark,
            BaseReferences<_$BibleDatabase, LibraryBookmarks, LibraryBookmark>,
          ),
          LibraryBookmark,
          PrefetchHooks Function()
        > {
  $LibraryBookmarksTableManager(_$BibleDatabase db, LibraryBookmarks table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LibraryBookmarksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LibraryBookmarksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LibraryBookmarksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> sectionIndex = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> textPreview = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LibraryBookmarksCompanion(
                id: id,
                documentId: documentId,
                sectionIndex: sectionIndex,
                nodeId: nodeId,
                textPreview: textPreview,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String documentId,
                required int sectionIndex,
                required String nodeId,
                required String textPreview,
                required DateTime createdAt,
              }) => LibraryBookmarksCompanion.insert(
                id: id,
                documentId: documentId,
                sectionIndex: sectionIndex,
                nodeId: nodeId,
                textPreview: textPreview,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LibraryBookmarksProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      LibraryBookmarks,
      LibraryBookmark,
      $LibraryBookmarksFilterComposer,
      $LibraryBookmarksOrderingComposer,
      $LibraryBookmarksAnnotationComposer,
      $LibraryBookmarksCreateCompanionBuilder,
      $LibraryBookmarksUpdateCompanionBuilder,
      (
        LibraryBookmark,
        BaseReferences<_$BibleDatabase, LibraryBookmarks, LibraryBookmark>,
      ),
      LibraryBookmark,
      PrefetchHooks Function()
    >;
typedef $$PrayersTableCreateCompanionBuilder =
    PrayersCompanion Function({
      Value<int> isarId,
      required String prayerId,
      required String defaultTitle,
      required String category,
      required int defaultOrder,
      required bool hasAmen,
      required String hash,
      Value<List<LocalizedTranslations>?> localizedTranslations,
    });
typedef $$PrayersTableUpdateCompanionBuilder =
    PrayersCompanion Function({
      Value<int> isarId,
      Value<String> prayerId,
      Value<String> defaultTitle,
      Value<String> category,
      Value<int> defaultOrder,
      Value<bool> hasAmen,
      Value<String> hash,
      Value<List<LocalizedTranslations>?> localizedTranslations,
    });

class $$PrayersTableFilterComposer
    extends Composer<_$BibleDatabase, $PrayersTable> {
  $$PrayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get isarId => $composableBuilder(
    column: $table.isarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prayerId => $composableBuilder(
    column: $table.prayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultTitle => $composableBuilder(
    column: $table.defaultTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultOrder => $composableBuilder(
    column: $table.defaultOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasAmen => $composableBuilder(
    column: $table.hasAmen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<LocalizedTranslations>?,
    List<LocalizedTranslations>,
    String
  >
  get localizedTranslations => $composableBuilder(
    column: $table.localizedTranslations,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$PrayersTableOrderingComposer
    extends Composer<_$BibleDatabase, $PrayersTable> {
  $$PrayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get isarId => $composableBuilder(
    column: $table.isarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prayerId => $composableBuilder(
    column: $table.prayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultTitle => $composableBuilder(
    column: $table.defaultTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultOrder => $composableBuilder(
    column: $table.defaultOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasAmen => $composableBuilder(
    column: $table.hasAmen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localizedTranslations => $composableBuilder(
    column: $table.localizedTranslations,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayersTableAnnotationComposer
    extends Composer<_$BibleDatabase, $PrayersTable> {
  $$PrayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get isarId =>
      $composableBuilder(column: $table.isarId, builder: (column) => column);

  GeneratedColumn<String> get prayerId =>
      $composableBuilder(column: $table.prayerId, builder: (column) => column);

  GeneratedColumn<String> get defaultTitle => $composableBuilder(
    column: $table.defaultTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get defaultOrder => $composableBuilder(
    column: $table.defaultOrder,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasAmen =>
      $composableBuilder(column: $table.hasAmen, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<LocalizedTranslations>?, String>
  get localizedTranslations => $composableBuilder(
    column: $table.localizedTranslations,
    builder: (column) => column,
  );
}

class $$PrayersTableTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          $PrayersTable,
          Prayer,
          $$PrayersTableFilterComposer,
          $$PrayersTableOrderingComposer,
          $$PrayersTableAnnotationComposer,
          $$PrayersTableCreateCompanionBuilder,
          $$PrayersTableUpdateCompanionBuilder,
          (Prayer, BaseReferences<_$BibleDatabase, $PrayersTable, Prayer>),
          Prayer,
          PrefetchHooks Function()
        > {
  $$PrayersTableTableManager(_$BibleDatabase db, $PrayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> isarId = const Value.absent(),
                Value<String> prayerId = const Value.absent(),
                Value<String> defaultTitle = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> defaultOrder = const Value.absent(),
                Value<bool> hasAmen = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<List<LocalizedTranslations>?> localizedTranslations =
                    const Value.absent(),
              }) => PrayersCompanion(
                isarId: isarId,
                prayerId: prayerId,
                defaultTitle: defaultTitle,
                category: category,
                defaultOrder: defaultOrder,
                hasAmen: hasAmen,
                hash: hash,
                localizedTranslations: localizedTranslations,
              ),
          createCompanionCallback:
              ({
                Value<int> isarId = const Value.absent(),
                required String prayerId,
                required String defaultTitle,
                required String category,
                required int defaultOrder,
                required bool hasAmen,
                required String hash,
                Value<List<LocalizedTranslations>?> localizedTranslations =
                    const Value.absent(),
              }) => PrayersCompanion.insert(
                isarId: isarId,
                prayerId: prayerId,
                defaultTitle: defaultTitle,
                category: category,
                defaultOrder: defaultOrder,
                hasAmen: hasAmen,
                hash: hash,
                localizedTranslations: localizedTranslations,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayersTableProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      $PrayersTable,
      Prayer,
      $$PrayersTableFilterComposer,
      $$PrayersTableOrderingComposer,
      $$PrayersTableAnnotationComposer,
      $$PrayersTableCreateCompanionBuilder,
      $$PrayersTableUpdateCompanionBuilder,
      (Prayer, BaseReferences<_$BibleDatabase, $PrayersTable, Prayer>),
      Prayer,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableTableCreateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      required String primaryLanguageCode,
      required String compareLanguageCode,
      required String primaryBibleTranslation,
      required String compareBibleTranslation,
      Value<List<PrayerVersionPreference>?> preferredVersions,
      Value<bool> hapticsEnabled,
      Value<String> appThemeModeCode,
      Value<bool> sundayNotificationsEnabled,
      Value<bool> showBibleTranslationSelectors,
    });
typedef $$UserSettingsTableTableUpdateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<String> primaryLanguageCode,
      Value<String> compareLanguageCode,
      Value<String> primaryBibleTranslation,
      Value<String> compareBibleTranslation,
      Value<List<PrayerVersionPreference>?> preferredVersions,
      Value<bool> hapticsEnabled,
      Value<String> appThemeModeCode,
      Value<bool> sundayNotificationsEnabled,
      Value<bool> showBibleTranslationSelectors,
    });

class $$UserSettingsTableTableFilterComposer
    extends Composer<_$BibleDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryLanguageCode => $composableBuilder(
    column: $table.primaryLanguageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get compareLanguageCode => $composableBuilder(
    column: $table.compareLanguageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryBibleTranslation => $composableBuilder(
    column: $table.primaryBibleTranslation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get compareBibleTranslation => $composableBuilder(
    column: $table.compareBibleTranslation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<PrayerVersionPreference>?,
    List<PrayerVersionPreference>,
    String
  >
  get preferredVersions => $composableBuilder(
    column: $table.preferredVersions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get hapticsEnabled => $composableBuilder(
    column: $table.hapticsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appThemeModeCode => $composableBuilder(
    column: $table.appThemeModeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sundayNotificationsEnabled => $composableBuilder(
    column: $table.sundayNotificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showBibleTranslationSelectors => $composableBuilder(
    column: $table.showBibleTranslationSelectors,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableTableOrderingComposer
    extends Composer<_$BibleDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryLanguageCode => $composableBuilder(
    column: $table.primaryLanguageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get compareLanguageCode => $composableBuilder(
    column: $table.compareLanguageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryBibleTranslation => $composableBuilder(
    column: $table.primaryBibleTranslation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get compareBibleTranslation => $composableBuilder(
    column: $table.compareBibleTranslation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredVersions => $composableBuilder(
    column: $table.preferredVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hapticsEnabled => $composableBuilder(
    column: $table.hapticsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appThemeModeCode => $composableBuilder(
    column: $table.appThemeModeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sundayNotificationsEnabled => $composableBuilder(
    column: $table.sundayNotificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showBibleTranslationSelectors => $composableBuilder(
    column: $table.showBibleTranslationSelectors,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableTableAnnotationComposer
    extends Composer<_$BibleDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get primaryLanguageCode => $composableBuilder(
    column: $table.primaryLanguageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get compareLanguageCode => $composableBuilder(
    column: $table.compareLanguageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryBibleTranslation => $composableBuilder(
    column: $table.primaryBibleTranslation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get compareBibleTranslation => $composableBuilder(
    column: $table.compareBibleTranslation,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<PrayerVersionPreference>?, String>
  get preferredVersions => $composableBuilder(
    column: $table.preferredVersions,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hapticsEnabled => $composableBuilder(
    column: $table.hapticsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appThemeModeCode => $composableBuilder(
    column: $table.appThemeModeCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sundayNotificationsEnabled => $composableBuilder(
    column: $table.sundayNotificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showBibleTranslationSelectors => $composableBuilder(
    column: $table.showBibleTranslationSelectors,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableTableManager
    extends
        RootTableManager<
          _$BibleDatabase,
          $UserSettingsTableTable,
          UserSettings,
          $$UserSettingsTableTableFilterComposer,
          $$UserSettingsTableTableOrderingComposer,
          $$UserSettingsTableTableAnnotationComposer,
          $$UserSettingsTableTableCreateCompanionBuilder,
          $$UserSettingsTableTableUpdateCompanionBuilder,
          (
            UserSettings,
            BaseReferences<
              _$BibleDatabase,
              $UserSettingsTableTable,
              UserSettings
            >,
          ),
          UserSettings,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableTableManager(
    _$BibleDatabase db,
    $UserSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> primaryLanguageCode = const Value.absent(),
                Value<String> compareLanguageCode = const Value.absent(),
                Value<String> primaryBibleTranslation = const Value.absent(),
                Value<String> compareBibleTranslation = const Value.absent(),
                Value<List<PrayerVersionPreference>?> preferredVersions =
                    const Value.absent(),
                Value<bool> hapticsEnabled = const Value.absent(),
                Value<String> appThemeModeCode = const Value.absent(),
                Value<bool> sundayNotificationsEnabled = const Value.absent(),
                Value<bool> showBibleTranslationSelectors =
                    const Value.absent(),
              }) => UserSettingsTableCompanion(
                id: id,
                primaryLanguageCode: primaryLanguageCode,
                compareLanguageCode: compareLanguageCode,
                primaryBibleTranslation: primaryBibleTranslation,
                compareBibleTranslation: compareBibleTranslation,
                preferredVersions: preferredVersions,
                hapticsEnabled: hapticsEnabled,
                appThemeModeCode: appThemeModeCode,
                sundayNotificationsEnabled: sundayNotificationsEnabled,
                showBibleTranslationSelectors: showBibleTranslationSelectors,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String primaryLanguageCode,
                required String compareLanguageCode,
                required String primaryBibleTranslation,
                required String compareBibleTranslation,
                Value<List<PrayerVersionPreference>?> preferredVersions =
                    const Value.absent(),
                Value<bool> hapticsEnabled = const Value.absent(),
                Value<String> appThemeModeCode = const Value.absent(),
                Value<bool> sundayNotificationsEnabled = const Value.absent(),
                Value<bool> showBibleTranslationSelectors =
                    const Value.absent(),
              }) => UserSettingsTableCompanion.insert(
                id: id,
                primaryLanguageCode: primaryLanguageCode,
                compareLanguageCode: compareLanguageCode,
                primaryBibleTranslation: primaryBibleTranslation,
                compareBibleTranslation: compareBibleTranslation,
                preferredVersions: preferredVersions,
                hapticsEnabled: hapticsEnabled,
                appThemeModeCode: appThemeModeCode,
                sundayNotificationsEnabled: sundayNotificationsEnabled,
                showBibleTranslationSelectors: showBibleTranslationSelectors,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$BibleDatabase,
      $UserSettingsTableTable,
      UserSettings,
      $$UserSettingsTableTableFilterComposer,
      $$UserSettingsTableTableOrderingComposer,
      $$UserSettingsTableTableAnnotationComposer,
      $$UserSettingsTableTableCreateCompanionBuilder,
      $$UserSettingsTableTableUpdateCompanionBuilder,
      (
        UserSettings,
        BaseReferences<_$BibleDatabase, $UserSettingsTableTable, UserSettings>,
      ),
      UserSettings,
      PrefetchHooks Function()
    >;

class $BibleDatabaseManager {
  final _$BibleDatabase _db;
  $BibleDatabaseManager(this._db);
  $BibleVersesTableManager get bibleVerses =>
      $BibleVersesTableManager(_db, _db.bibleVerses);
  $LectionaryReadingsTableManager get lectionaryReadings =>
      $LectionaryReadingsTableManager(_db, _db.lectionaryReadings);
  $FavoritePassagesTableManager get favoritePassages =>
      $FavoritePassagesTableManager(_db, _db.favoritePassages);
  $UserCommentsTableManager get userComments =>
      $UserCommentsTableManager(_db, _db.userComments);
  $LibraryBookmarksTableManager get libraryBookmarks =>
      $LibraryBookmarksTableManager(_db, _db.libraryBookmarks);
  $$PrayersTableTableManager get prayers =>
      $$PrayersTableTableManager(_db, _db.prayers);
  $$UserSettingsTableTableTableManager get userSettingsTable =>
      $$UserSettingsTableTableTableManager(_db, _db.userSettingsTable);
}
