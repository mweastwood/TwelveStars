// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayers.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetPrayerCollection on Isar {
  IsarCollection<int, Prayer> get prayers => this.collection();
}

final PrayerSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Prayer',
    idName: 'isarId',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'prayerId', type: IsarType.string),
      IsarPropertySchema(name: 'defaultTitle', type: IsarType.string),
      IsarPropertySchema(name: 'category', type: IsarType.string),
      IsarPropertySchema(name: 'defaultOrder', type: IsarType.long),
      IsarPropertySchema(
        name: 'localizedTranslations',
        type: IsarType.objectList,
        target: 'LocalizedTranslations',
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'prayerId',
        properties: ["prayerId"],
        unique: true,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, Prayer>(
    serialize: serializePrayer,
    deserialize: deserializePrayer,
    deserializeProperty: deserializePrayerProp,
  ),
  getEmbeddedSchemas: () => [
    LocalizedTranslationsSchema,
    PrayerTranslationSchema,
    ChineseLineSchema,
    ChineseCharSchema,
    PrayerTokenSchema,
  ],
);

@isarProtected
int serializePrayer(IsarWriter writer, Prayer object) {
  IsarCore.writeString(writer, 1, object.prayerId);
  IsarCore.writeString(writer, 2, object.defaultTitle);
  IsarCore.writeString(writer, 3, object.category);
  IsarCore.writeLong(writer, 4, object.defaultOrder);
  {
    final list = object.localizedTranslations;
    if (list == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      final listWriter = IsarCore.beginList(writer, 5, list.length);
      for (var i = 0; i < list.length; i++) {
        {
          final value = list[i];
          final objectWriter = IsarCore.beginObject(listWriter, i);
          serializeLocalizedTranslations(objectWriter, value);
          IsarCore.endObject(listWriter, objectWriter);
        }
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  return object.isarId;
}

@isarProtected
Prayer deserializePrayer(IsarReader reader) {
  final int _isarId;
  _isarId = IsarCore.readId(reader);
  final String _prayerId;
  _prayerId = IsarCore.readString(reader, 1) ?? '';
  final String _defaultTitle;
  _defaultTitle = IsarCore.readString(reader, 2) ?? '';
  final String _category;
  _category = IsarCore.readString(reader, 3) ?? '';
  final int _defaultOrder;
  {
    final value = IsarCore.readLong(reader, 4);
    if (value == -9223372036854775808) {
      _defaultOrder = 0;
    } else {
      _defaultOrder = value;
    }
  }
  final List<LocalizedTranslations>? _localizedTranslations;
  {
    final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _localizedTranslations = null;
      } else {
        final list = List<LocalizedTranslations>.filled(
          length,
          LocalizedTranslations(),
          growable: true,
        );
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = LocalizedTranslations();
            } else {
              final embedded = deserializeLocalizedTranslations(objectReader);
              IsarCore.freeReader(objectReader);
              list[i] = embedded;
            }
          }
        }
        IsarCore.freeReader(reader);
        _localizedTranslations = list;
      }
    }
  }
  final object = Prayer(
    isarId: _isarId,
    prayerId: _prayerId,
    defaultTitle: _defaultTitle,
    category: _category,
    defaultOrder: _defaultOrder,
    localizedTranslations: _localizedTranslations,
  );
  return object;
}

@isarProtected
dynamic deserializePrayerProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      {
        final value = IsarCore.readLong(reader, 4);
        if (value == -9223372036854775808) {
          return 0;
        } else {
          return value;
        }
      }
    case 5:
      {
        final length = IsarCore.readList(reader, 5, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return null;
          } else {
            final list = List<LocalizedTranslations>.filled(
              length,
              LocalizedTranslations(),
              growable: true,
            );
            for (var i = 0; i < length; i++) {
              {
                final objectReader = IsarCore.readObject(reader, i);
                if (objectReader.isNull) {
                  list[i] = LocalizedTranslations();
                } else {
                  final embedded = deserializeLocalizedTranslations(
                    objectReader,
                  );
                  IsarCore.freeReader(objectReader);
                  list[i] = embedded;
                }
              }
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _PrayerUpdate {
  bool call({
    required int isarId,
    String? prayerId,
    String? defaultTitle,
    String? category,
    int? defaultOrder,
  });
}

class _PrayerUpdateImpl implements _PrayerUpdate {
  const _PrayerUpdateImpl(this.collection);

  final IsarCollection<int, Prayer> collection;

  @override
  bool call({
    required int isarId,
    Object? prayerId = ignore,
    Object? defaultTitle = ignore,
    Object? category = ignore,
    Object? defaultOrder = ignore,
  }) {
    return collection.updateProperties(
          [isarId],
          {
            if (prayerId != ignore) 1: prayerId as String?,
            if (defaultTitle != ignore) 2: defaultTitle as String?,
            if (category != ignore) 3: category as String?,
            if (defaultOrder != ignore) 4: defaultOrder as int?,
          },
        ) >
        0;
  }
}

sealed class _PrayerUpdateAll {
  int call({
    required List<int> isarId,
    String? prayerId,
    String? defaultTitle,
    String? category,
    int? defaultOrder,
  });
}

class _PrayerUpdateAllImpl implements _PrayerUpdateAll {
  const _PrayerUpdateAllImpl(this.collection);

  final IsarCollection<int, Prayer> collection;

  @override
  int call({
    required List<int> isarId,
    Object? prayerId = ignore,
    Object? defaultTitle = ignore,
    Object? category = ignore,
    Object? defaultOrder = ignore,
  }) {
    return collection.updateProperties(isarId, {
      if (prayerId != ignore) 1: prayerId as String?,
      if (defaultTitle != ignore) 2: defaultTitle as String?,
      if (category != ignore) 3: category as String?,
      if (defaultOrder != ignore) 4: defaultOrder as int?,
    });
  }
}

extension PrayerUpdate on IsarCollection<int, Prayer> {
  _PrayerUpdate get update => _PrayerUpdateImpl(this);

  _PrayerUpdateAll get updateAll => _PrayerUpdateAllImpl(this);
}

sealed class _PrayerQueryUpdate {
  int call({
    String? prayerId,
    String? defaultTitle,
    String? category,
    int? defaultOrder,
  });
}

class _PrayerQueryUpdateImpl implements _PrayerQueryUpdate {
  const _PrayerQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Prayer> query;
  final int? limit;

  @override
  int call({
    Object? prayerId = ignore,
    Object? defaultTitle = ignore,
    Object? category = ignore,
    Object? defaultOrder = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (prayerId != ignore) 1: prayerId as String?,
      if (defaultTitle != ignore) 2: defaultTitle as String?,
      if (category != ignore) 3: category as String?,
      if (defaultOrder != ignore) 4: defaultOrder as int?,
    });
  }
}

extension PrayerQueryUpdate on IsarQuery<Prayer> {
  _PrayerQueryUpdate get updateFirst => _PrayerQueryUpdateImpl(this, limit: 1);

  _PrayerQueryUpdate get updateAll => _PrayerQueryUpdateImpl(this);
}

class _PrayerQueryBuilderUpdateImpl implements _PrayerQueryUpdate {
  const _PrayerQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Prayer, Prayer, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? prayerId = ignore,
    Object? defaultTitle = ignore,
    Object? category = ignore,
    Object? defaultOrder = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (prayerId != ignore) 1: prayerId as String?,
        if (defaultTitle != ignore) 2: defaultTitle as String?,
        if (category != ignore) 3: category as String?,
        if (defaultOrder != ignore) 4: defaultOrder as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension PrayerQueryBuilderUpdate
    on QueryBuilder<Prayer, Prayer, QOperations> {
  _PrayerQueryUpdate get updateFirst =>
      _PrayerQueryBuilderUpdateImpl(this, limit: 1);

  _PrayerQueryUpdate get updateAll => _PrayerQueryBuilderUpdateImpl(this);
}

extension PrayerQueryFilter on QueryBuilder<Prayer, Prayer, QFilterCondition> {
  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> isarIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> isarIdGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  isarIdGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> isarIdLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> isarIdLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> isarIdBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  prayerIdGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> prayerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  defaultTitleGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  defaultTitleLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  categoryGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultOrderEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultOrderGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  defaultOrderGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultOrderLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 4, value: value));
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  defaultOrderLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition> defaultOrderBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 4, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  localizedTranslationsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  localizedTranslationsIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  localizedTranslationsIsEmpty() {
    return not().group(
      (q) => q
          .localizedTranslationsIsNull()
          .or()
          .localizedTranslationsIsNotEmpty(),
    );
  }

  QueryBuilder<Prayer, Prayer, QAfterFilterCondition>
  localizedTranslationsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 5, value: null),
      );
    });
  }
}

extension PrayerQueryObject on QueryBuilder<Prayer, Prayer, QFilterCondition> {}

extension PrayerQuerySortBy on QueryBuilder<Prayer, Prayer, QSortBy> {
  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByPrayerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByPrayerIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByDefaultTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByDefaultTitleDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByCategoryDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByDefaultOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> sortByDefaultOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }
}

extension PrayerQuerySortThenBy on QueryBuilder<Prayer, Prayer, QSortThenBy> {
  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByPrayerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByPrayerIdDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByDefaultTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByDefaultTitleDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByCategoryDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByDefaultOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterSortBy> thenByDefaultOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }
}

extension PrayerQueryWhereDistinct on QueryBuilder<Prayer, Prayer, QDistinct> {
  QueryBuilder<Prayer, Prayer, QAfterDistinct> distinctByPrayerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterDistinct> distinctByDefaultTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterDistinct> distinctByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Prayer, Prayer, QAfterDistinct> distinctByDefaultOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }
}

extension PrayerQueryProperty1 on QueryBuilder<Prayer, Prayer, QProperty> {
  QueryBuilder<Prayer, int, QAfterProperty> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Prayer, String, QAfterProperty> prayerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Prayer, String, QAfterProperty> defaultTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Prayer, String, QAfterProperty> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Prayer, int, QAfterProperty> defaultOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Prayer, List<LocalizedTranslations>?, QAfterProperty>
  localizedTranslationsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension PrayerQueryProperty2<R> on QueryBuilder<Prayer, R, QAfterProperty> {
  QueryBuilder<Prayer, (R, int), QAfterProperty> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Prayer, (R, String), QAfterProperty> prayerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Prayer, (R, String), QAfterProperty> defaultTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Prayer, (R, String), QAfterProperty> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Prayer, (R, int), QAfterProperty> defaultOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Prayer, (R, List<LocalizedTranslations>?), QAfterProperty>
  localizedTranslationsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension PrayerQueryProperty3<R1, R2>
    on QueryBuilder<Prayer, (R1, R2), QAfterProperty> {
  QueryBuilder<Prayer, (R1, R2, int), QOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Prayer, (R1, R2, String), QOperations> prayerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Prayer, (R1, R2, String), QOperations> defaultTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Prayer, (R1, R2, String), QOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Prayer, (R1, R2, int), QOperations> defaultOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Prayer, (R1, R2, List<LocalizedTranslations>?), QOperations>
  localizedTranslationsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

// **************************************************************************
// _IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

final ChineseCharSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'ChineseChar',

    embedded: true,
    properties: [
      IsarPropertySchema(name: 'char', type: IsarType.string),
      IsarPropertySchema(name: 'pinyin', type: IsarType.string),
      IsarPropertySchema(name: 'phraseId', type: IsarType.string),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, ChineseChar>(
    serialize: serializeChineseChar,
    deserialize: deserializeChineseChar,
  ),
);

@isarProtected
int serializeChineseChar(IsarWriter writer, ChineseChar object) {
  IsarCore.writeString(writer, 1, object.char);
  IsarCore.writeString(writer, 2, object.pinyin);
  {
    final value = object.phraseId;
    if (value == null) {
      IsarCore.writeNull(writer, 3);
    } else {
      IsarCore.writeString(writer, 3, value);
    }
  }
  return 0;
}

@isarProtected
ChineseChar deserializeChineseChar(IsarReader reader) {
  final String _char;
  _char = IsarCore.readString(reader, 1) ?? '';
  final String _pinyin;
  _pinyin = IsarCore.readString(reader, 2) ?? '';
  final String? _phraseId;
  _phraseId = IsarCore.readString(reader, 3);
  final object = ChineseChar(_char, _pinyin, _phraseId);
  return object;
}

extension ChineseCharQueryFilter
    on QueryBuilder<ChineseChar, ChineseChar, QFilterCondition> {
  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> charEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> charGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  charGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> charLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  charLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> charBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> charStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> charEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> charContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> charMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> charIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  charIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> pinyinEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  pinyinGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  pinyinGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> pinyinLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  pinyinLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> pinyinBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  pinyinStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> pinyinEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> pinyinContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> pinyinMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  pinyinIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  pinyinIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> phraseIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> phraseIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition> phraseIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<ChineseChar, ChineseChar, QAfterFilterCondition>
  phraseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }
}

extension ChineseCharQueryObject
    on QueryBuilder<ChineseChar, ChineseChar, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

final ChineseLineSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'ChineseLine',

    embedded: true,
    properties: [
      IsarPropertySchema(
        name: 'chars',
        type: IsarType.objectList,
        target: 'ChineseChar',
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, ChineseLine>(
    serialize: serializeChineseLine,
    deserialize: deserializeChineseLine,
  ),
);

@isarProtected
int serializeChineseLine(IsarWriter writer, ChineseLine object) {
  {
    final list = object.chars;
    if (list == null) {
      IsarCore.writeNull(writer, 1);
    } else {
      final listWriter = IsarCore.beginList(writer, 1, list.length);
      for (var i = 0; i < list.length; i++) {
        {
          final value = list[i];
          final objectWriter = IsarCore.beginObject(listWriter, i);
          serializeChineseChar(objectWriter, value);
          IsarCore.endObject(listWriter, objectWriter);
        }
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  return 0;
}

@isarProtected
ChineseLine deserializeChineseLine(IsarReader reader) {
  final List<ChineseChar>? _chars;
  {
    final length = IsarCore.readList(reader, 1, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _chars = null;
      } else {
        final list = List<ChineseChar>.filled(
          length,
          ChineseChar(),
          growable: true,
        );
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = ChineseChar();
            } else {
              final embedded = deserializeChineseChar(objectReader);
              IsarCore.freeReader(objectReader);
              list[i] = embedded;
            }
          }
        }
        IsarCore.freeReader(reader);
        _chars = list;
      }
    }
  }
  final object = ChineseLine(chars: _chars);
  return object;
}

extension ChineseLineQueryFilter
    on QueryBuilder<ChineseLine, ChineseLine, QFilterCondition> {
  QueryBuilder<ChineseLine, ChineseLine, QAfterFilterCondition> charsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<ChineseLine, ChineseLine, QAfterFilterCondition>
  charsIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<ChineseLine, ChineseLine, QAfterFilterCondition> charsIsEmpty() {
    return not().group((q) => q.charsIsNull().or().charsIsNotEmpty());
  }

  QueryBuilder<ChineseLine, ChineseLine, QAfterFilterCondition>
  charsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 1, value: null),
      );
    });
  }
}

extension ChineseLineQueryObject
    on QueryBuilder<ChineseLine, ChineseLine, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

final PrayerTokenSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'PrayerToken',

    embedded: true,
    properties: [
      IsarPropertySchema(name: 'text', type: IsarType.string),
      IsarPropertySchema(name: 'id', type: IsarType.string),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, PrayerToken>(
    serialize: serializePrayerToken,
    deserialize: deserializePrayerToken,
  ),
);

@isarProtected
int serializePrayerToken(IsarWriter writer, PrayerToken object) {
  IsarCore.writeString(writer, 1, object.text);
  {
    final value = object.id;
    if (value == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      IsarCore.writeString(writer, 2, value);
    }
  }
  return 0;
}

@isarProtected
PrayerToken deserializePrayerToken(IsarReader reader) {
  final String _text;
  _text = IsarCore.readString(reader, 1) ?? '';
  final String? _id;
  _id = IsarCore.readString(reader, 2);
  final object = PrayerToken(_text, _id);
  return object;
}

extension PrayerTokenQueryFilter
    on QueryBuilder<PrayerToken, PrayerToken, QFilterCondition> {
  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> textGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition>
  textGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> textLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition>
  textLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> textBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> textContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> textMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition>
  idGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition>
  idLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<PrayerToken, PrayerToken, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }
}

extension PrayerTokenQueryObject
    on QueryBuilder<PrayerToken, PrayerToken, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

final PrayerTranslationSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'PrayerTranslation',

    embedded: true,
    properties: [
      IsarPropertySchema(name: 'title', type: IsarType.string),
      IsarPropertySchema(name: 'subtitle', type: IsarType.string),
      IsarPropertySchema(name: 'text', type: IsarType.string),
      IsarPropertySchema(name: 'sourceName', type: IsarType.string),
      IsarPropertySchema(name: 'sourceUrl', type: IsarType.string),
      IsarPropertySchema(
        name: 'chineseLines',
        type: IsarType.objectList,
        target: 'ChineseLine',
      ),
      IsarPropertySchema(
        name: 'tokens',
        type: IsarType.objectList,
        target: 'PrayerToken',
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, PrayerTranslation>(
    serialize: serializePrayerTranslation,
    deserialize: deserializePrayerTranslation,
  ),
);

@isarProtected
int serializePrayerTranslation(IsarWriter writer, PrayerTranslation object) {
  IsarCore.writeString(writer, 1, object.title);
  IsarCore.writeString(writer, 2, object.subtitle);
  IsarCore.writeString(writer, 3, object.text);
  IsarCore.writeString(writer, 4, object.sourceName);
  IsarCore.writeString(writer, 5, object.sourceUrl);
  {
    final list = object.chineseLines;
    if (list == null) {
      IsarCore.writeNull(writer, 6);
    } else {
      final listWriter = IsarCore.beginList(writer, 6, list.length);
      for (var i = 0; i < list.length; i++) {
        {
          final value = list[i];
          final objectWriter = IsarCore.beginObject(listWriter, i);
          serializeChineseLine(objectWriter, value);
          IsarCore.endObject(listWriter, objectWriter);
        }
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  {
    final list = object.tokens;
    if (list == null) {
      IsarCore.writeNull(writer, 7);
    } else {
      final listWriter = IsarCore.beginList(writer, 7, list.length);
      for (var i = 0; i < list.length; i++) {
        {
          final value = list[i];
          final objectWriter = IsarCore.beginObject(listWriter, i);
          serializePrayerToken(objectWriter, value);
          IsarCore.endObject(listWriter, objectWriter);
        }
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  return 0;
}

@isarProtected
PrayerTranslation deserializePrayerTranslation(IsarReader reader) {
  final String _title;
  _title = IsarCore.readString(reader, 1) ?? '';
  final String _subtitle;
  _subtitle = IsarCore.readString(reader, 2) ?? '';
  final String _text;
  _text = IsarCore.readString(reader, 3) ?? '';
  final String _sourceName;
  _sourceName = IsarCore.readString(reader, 4) ?? '';
  final String _sourceUrl;
  _sourceUrl = IsarCore.readString(reader, 5) ?? '';
  final List<ChineseLine>? _chineseLines;
  {
    final length = IsarCore.readList(reader, 6, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _chineseLines = null;
      } else {
        final list = List<ChineseLine>.filled(
          length,
          ChineseLine(),
          growable: true,
        );
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = ChineseLine();
            } else {
              final embedded = deserializeChineseLine(objectReader);
              IsarCore.freeReader(objectReader);
              list[i] = embedded;
            }
          }
        }
        IsarCore.freeReader(reader);
        _chineseLines = list;
      }
    }
  }
  final List<PrayerToken>? _tokens;
  {
    final length = IsarCore.readList(reader, 7, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _tokens = null;
      } else {
        final list = List<PrayerToken>.filled(
          length,
          PrayerToken(),
          growable: true,
        );
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = PrayerToken();
            } else {
              final embedded = deserializePrayerToken(objectReader);
              IsarCore.freeReader(objectReader);
              list[i] = embedded;
            }
          }
        }
        IsarCore.freeReader(reader);
        _tokens = list;
      }
    }
  }
  final object = PrayerTranslation(
    title: _title,
    subtitle: _subtitle,
    text: _text,
    sourceName: _sourceName,
    sourceUrl: _sourceUrl,
    chineseLines: _chineseLines,
    tokens: _tokens,
  );
  return object;
}

extension PrayerTranslationQueryFilter
    on QueryBuilder<PrayerTranslation, PrayerTranslation, QFilterCondition> {
  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleBetween(String lower, String upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleBetween(String lower, String upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  subtitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textBetween(String lower, String upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameBetween(String lower, String upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 4,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlBetween(String lower, String upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  sourceUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  chineseLinesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  chineseLinesIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  chineseLinesIsEmpty() {
    return not().group(
      (q) => q.chineseLinesIsNull().or().chineseLinesIsNotEmpty(),
    );
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  chineseLinesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 6, value: null),
      );
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  tokensIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  tokensIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  tokensIsEmpty() {
    return not().group((q) => q.tokensIsNull().or().tokensIsNotEmpty());
  }

  QueryBuilder<PrayerTranslation, PrayerTranslation, QAfterFilterCondition>
  tokensIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 7, value: null),
      );
    });
  }
}

extension PrayerTranslationQueryObject
    on QueryBuilder<PrayerTranslation, PrayerTranslation, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

final LocalizedTranslationsSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'LocalizedTranslations',

    embedded: true,
    properties: [
      IsarPropertySchema(name: 'languageCode', type: IsarType.string),
      IsarPropertySchema(
        name: 'list',
        type: IsarType.objectList,
        target: 'PrayerTranslation',
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, LocalizedTranslations>(
    serialize: serializeLocalizedTranslations,
    deserialize: deserializeLocalizedTranslations,
  ),
);

@isarProtected
int serializeLocalizedTranslations(
  IsarWriter writer,
  LocalizedTranslations object,
) {
  IsarCore.writeString(writer, 1, object.languageCode);
  {
    final list = object.list;
    if (list == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      final listWriter = IsarCore.beginList(writer, 2, list.length);
      for (var i = 0; i < list.length; i++) {
        {
          final value = list[i];
          final objectWriter = IsarCore.beginObject(listWriter, i);
          serializePrayerTranslation(objectWriter, value);
          IsarCore.endObject(listWriter, objectWriter);
        }
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  return 0;
}

@isarProtected
LocalizedTranslations deserializeLocalizedTranslations(IsarReader reader) {
  final String _languageCode;
  _languageCode = IsarCore.readString(reader, 1) ?? '';
  final List<PrayerTranslation>? _list;
  {
    final length = IsarCore.readList(reader, 2, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _list = null;
      } else {
        final list = List<PrayerTranslation>.filled(
          length,
          PrayerTranslation(),
          growable: true,
        );
        for (var i = 0; i < length; i++) {
          {
            final objectReader = IsarCore.readObject(reader, i);
            if (objectReader.isNull) {
              list[i] = PrayerTranslation();
            } else {
              final embedded = deserializePrayerTranslation(objectReader);
              IsarCore.freeReader(objectReader);
              list[i] = embedded;
            }
          }
        }
        IsarCore.freeReader(reader);
        _list = list;
      }
    }
  }
  final object = LocalizedTranslations(
    languageCode: _languageCode,
    list: _list,
  );
  return object;
}

extension LocalizedTranslationsQueryFilter
    on
        QueryBuilder<
          LocalizedTranslations,
          LocalizedTranslations,
          QFilterCondition
        > {
  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeBetween(String lower, String upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  languageCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  listIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  listIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  listIsEmpty() {
    return not().group((q) => q.listIsNull().or().listIsNotEmpty());
  }

  QueryBuilder<
    LocalizedTranslations,
    LocalizedTranslations,
    QAfterFilterCondition
  >
  listIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 2, value: null),
      );
    });
  }
}

extension LocalizedTranslationsQueryObject
    on
        QueryBuilder<
          LocalizedTranslations,
          LocalizedTranslations,
          QFilterCondition
        > {}
