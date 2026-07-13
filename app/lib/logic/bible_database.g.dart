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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    primaryLanguageCode,
    compareLanguageCode,
    primaryBibleTranslation,
    compareBibleTranslation,
    preferredVersions,
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
  const UserSettingsTableCompanion({
    this.id = const Value.absent(),
    this.primaryLanguageCode = const Value.absent(),
    this.compareLanguageCode = const Value.absent(),
    this.primaryBibleTranslation = const Value.absent(),
    this.compareBibleTranslation = const Value.absent(),
    this.preferredVersions = const Value.absent(),
  });
  UserSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String primaryLanguageCode,
    required String compareLanguageCode,
    required String primaryBibleTranslation,
    required String compareBibleTranslation,
    this.preferredVersions = const Value.absent(),
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
    });
  }

  UserSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? primaryLanguageCode,
    Value<String>? compareLanguageCode,
    Value<String>? primaryBibleTranslation,
    Value<String>? compareBibleTranslation,
    Value<List<PrayerVersionPreference>?>? preferredVersions,
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
          ..write('preferredVersions: $preferredVersions')
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
    });
typedef $$UserSettingsTableTableUpdateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<String> primaryLanguageCode,
      Value<String> compareLanguageCode,
      Value<String> primaryBibleTranslation,
      Value<String> compareBibleTranslation,
      Value<List<PrayerVersionPreference>?> preferredVersions,
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
              }) => UserSettingsTableCompanion(
                id: id,
                primaryLanguageCode: primaryLanguageCode,
                compareLanguageCode: compareLanguageCode,
                primaryBibleTranslation: primaryBibleTranslation,
                compareBibleTranslation: compareBibleTranslation,
                preferredVersions: preferredVersions,
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
              }) => UserSettingsTableCompanion.insert(
                id: id,
                primaryLanguageCode: primaryLanguageCode,
                compareLanguageCode: compareLanguageCode,
                primaryBibleTranslation: primaryBibleTranslation,
                compareBibleTranslation: compareBibleTranslation,
                preferredVersions: preferredVersions,
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
  $$PrayersTableTableManager get prayers =>
      $$PrayersTableTableManager(_db, _db.prayers);
  $$UserSettingsTableTableTableManager get userSettingsTable =>
      $$UserSettingsTableTableTableManager(_db, _db.userSettingsTable);
}
