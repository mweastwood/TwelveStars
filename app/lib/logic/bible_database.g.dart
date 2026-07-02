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

abstract class _$BibleDatabase extends GeneratedDatabase {
  _$BibleDatabase(QueryExecutor e) : super(e);
  $BibleDatabaseManager get managers => $BibleDatabaseManager(this);
  late final BibleVerses bibleVerses = BibleVerses(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [bibleVerses];
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

class $BibleDatabaseManager {
  final _$BibleDatabase _db;
  $BibleDatabaseManager(this._db);
  $BibleVersesTableManager get bibleVerses =>
      $BibleVersesTableManager(_db, _db.bibleVerses);
}
