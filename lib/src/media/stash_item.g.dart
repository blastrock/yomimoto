// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stash_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStashItemCollection on Isar {
  IsarCollection<StashItem> get stashItems => this.collection();
}

const StashItemSchema = CollectionSchema(
  name: r'StashItem',
  id: 3717957383656956638,
  properties: {
    r'dateAdded': PropertySchema(
      id: 0,
      name: r'dateAdded',
      type: IsarType.dateTime,
    ),
    r'definitions': PropertySchema(
      id: 1,
      name: r'definitions',
      type: IsarType.stringList,
    ),
    r'dictionaryName': PropertySchema(
      id: 2,
      name: r'dictionaryName',
      type: IsarType.string,
    ),
    r'mediaIdentifier': PropertySchema(
      id: 3,
      name: r'mediaIdentifier',
      type: IsarType.string,
    ),
    r'mediaSourceIdentifier': PropertySchema(
      id: 4,
      name: r'mediaSourceIdentifier',
      type: IsarType.string,
    ),
    r'position': PropertySchema(id: 5, name: r'position', type: IsarType.long),
    r'reading': PropertySchema(id: 6, name: r'reading', type: IsarType.string),
    r'sentence': PropertySchema(
      id: 7,
      name: r'sentence',
      type: IsarType.string,
    ),
    r'stashKey': PropertySchema(
      id: 8,
      name: r'stashKey',
      type: IsarType.string,
    ),
    r'term': PropertySchema(id: 9, name: r'term', type: IsarType.string),
    r'wordLength': PropertySchema(
      id: 10,
      name: r'wordLength',
      type: IsarType.long,
    ),
    r'wordStart': PropertySchema(
      id: 11,
      name: r'wordStart',
      type: IsarType.long,
    ),
  },

  estimateSize: _stashItemEstimateSize,
  serialize: _stashItemSerialize,
  deserialize: _stashItemDeserialize,
  deserializeProp: _stashItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'stashKey': IndexSchema(
      id: -9185889110960600282,
      name: r'stashKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'stashKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _stashItemGetId,
  getLinks: _stashItemGetLinks,
  attach: _stashItemAttach,
  version: '3.3.2',
);

int _stashItemEstimateSize(
  StashItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.definitions.length * 3;
  {
    for (var i = 0; i < object.definitions.length; i++) {
      final value = object.definitions[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.dictionaryName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mediaIdentifier.length * 3;
  bytesCount += 3 + object.mediaSourceIdentifier.length * 3;
  bytesCount += 3 + object.reading.length * 3;
  bytesCount += 3 + object.sentence.length * 3;
  bytesCount += 3 + object.stashKey.length * 3;
  bytesCount += 3 + object.term.length * 3;
  return bytesCount;
}

void _stashItemSerialize(
  StashItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.dateAdded);
  writer.writeStringList(offsets[1], object.definitions);
  writer.writeString(offsets[2], object.dictionaryName);
  writer.writeString(offsets[3], object.mediaIdentifier);
  writer.writeString(offsets[4], object.mediaSourceIdentifier);
  writer.writeLong(offsets[5], object.position);
  writer.writeString(offsets[6], object.reading);
  writer.writeString(offsets[7], object.sentence);
  writer.writeString(offsets[8], object.stashKey);
  writer.writeString(offsets[9], object.term);
  writer.writeLong(offsets[10], object.wordLength);
  writer.writeLong(offsets[11], object.wordStart);
}

StashItem _stashItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StashItem(
    dateAdded: reader.readDateTime(offsets[0]),
    definitions: reader.readStringList(offsets[1]) ?? [],
    dictionaryName: reader.readStringOrNull(offsets[2]),
    id: id,
    mediaIdentifier: reader.readString(offsets[3]),
    mediaSourceIdentifier: reader.readString(offsets[4]),
    position: reader.readLong(offsets[5]),
    reading: reader.readString(offsets[6]),
    sentence: reader.readString(offsets[7]),
    term: reader.readString(offsets[9]),
    wordLength: reader.readLong(offsets[10]),
    wordStart: reader.readLong(offsets[11]),
  );
  return object;
}

P _stashItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _stashItemGetId(StashItem object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _stashItemGetLinks(StashItem object) {
  return [];
}

void _stashItemAttach(IsarCollection<dynamic> col, Id id, StashItem object) {
  object.id = id;
}

extension StashItemByIndex on IsarCollection<StashItem> {
  Future<StashItem?> getByStashKey(String stashKey) {
    return getByIndex(r'stashKey', [stashKey]);
  }

  StashItem? getByStashKeySync(String stashKey) {
    return getByIndexSync(r'stashKey', [stashKey]);
  }

  Future<bool> deleteByStashKey(String stashKey) {
    return deleteByIndex(r'stashKey', [stashKey]);
  }

  bool deleteByStashKeySync(String stashKey) {
    return deleteByIndexSync(r'stashKey', [stashKey]);
  }

  Future<List<StashItem?>> getAllByStashKey(List<String> stashKeyValues) {
    final values = stashKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'stashKey', values);
  }

  List<StashItem?> getAllByStashKeySync(List<String> stashKeyValues) {
    final values = stashKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'stashKey', values);
  }

  Future<int> deleteAllByStashKey(List<String> stashKeyValues) {
    final values = stashKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'stashKey', values);
  }

  int deleteAllByStashKeySync(List<String> stashKeyValues) {
    final values = stashKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'stashKey', values);
  }

  Future<Id> putByStashKey(StashItem object) {
    return putByIndex(r'stashKey', object);
  }

  Id putByStashKeySync(StashItem object, {bool saveLinks = true}) {
    return putByIndexSync(r'stashKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByStashKey(List<StashItem> objects) {
    return putAllByIndex(r'stashKey', objects);
  }

  List<Id> putAllByStashKeySync(
    List<StashItem> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'stashKey', objects, saveLinks: saveLinks);
  }
}

extension StashItemQueryWhereSort
    on QueryBuilder<StashItem, StashItem, QWhere> {
  QueryBuilder<StashItem, StashItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StashItemQueryWhere
    on QueryBuilder<StashItem, StashItem, QWhereClause> {
  QueryBuilder<StashItem, StashItem, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterWhereClause> stashKeyEqualTo(
    String stashKey,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'stashKey', value: [stashKey]),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterWhereClause> stashKeyNotEqualTo(
    String stashKey,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'stashKey',
                lower: [],
                upper: [stashKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'stashKey',
                lower: [stashKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'stashKey',
                lower: [stashKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'stashKey',
                lower: [],
                upper: [stashKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension StashItemQueryFilter
    on QueryBuilder<StashItem, StashItem, QFilterCondition> {
  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> dateAddedEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateAdded', value: value),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dateAddedGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateAdded',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> dateAddedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateAdded',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> dateAddedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateAdded',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'definitions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'definitions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'definitions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'definitions',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'definitions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'definitions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'definitions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'definitions',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'definitions', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'definitions', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'definitions', length, true, length, true);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'definitions', 0, true, 0, true);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'definitions', 0, false, 999999, true);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'definitions', 0, true, length, include);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'definitions', length, include, 999999, true);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  definitionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'definitions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'dictionaryName'),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'dictionaryName'),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dictionaryName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dictionaryName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dictionaryName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dictionaryName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dictionaryName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dictionaryName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dictionaryName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dictionaryName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dictionaryName', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  dictionaryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dictionaryName', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> idEqualTo(
    Id? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> idGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> idLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> idBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mediaIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mediaIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mediaIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mediaIdentifier',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mediaIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mediaIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mediaIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mediaIdentifier',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mediaIdentifier', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaIdentifierIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mediaIdentifier', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mediaSourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mediaSourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mediaSourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mediaSourceIdentifier',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mediaSourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mediaSourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mediaSourceIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mediaSourceIdentifier',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mediaSourceIdentifier', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  mediaSourceIdentifierIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'mediaSourceIdentifier',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> positionEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'position', value: value),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> positionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'position',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> positionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'position',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> positionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'position',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> readingEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'reading',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> readingGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reading',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> readingLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reading',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> readingBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reading',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> readingStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'reading',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> readingEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'reading',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> readingContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'reading',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> readingMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'reading',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> readingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reading', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  readingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'reading', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> sentenceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sentence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> sentenceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sentence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> sentenceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sentence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> sentenceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sentence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> sentenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sentence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> sentenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sentence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> sentenceContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sentence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> sentenceMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sentence',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> sentenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sentence', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  sentenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sentence', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> stashKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'stashKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> stashKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'stashKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> stashKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'stashKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> stashKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'stashKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> stashKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'stashKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> stashKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'stashKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> stashKeyContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'stashKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> stashKeyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'stashKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> stashKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'stashKey', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  stashKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'stashKey', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'term',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'term',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'term',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'term',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'term',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'term',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'term',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'term',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'term', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> termIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'term', value: ''),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> wordLengthEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'wordLength', value: value),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  wordLengthGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'wordLength',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> wordLengthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'wordLength',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> wordLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'wordLength',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> wordStartEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'wordStart', value: value),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition>
  wordStartGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'wordStart',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> wordStartLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'wordStart',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterFilterCondition> wordStartBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'wordStart',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension StashItemQueryObject
    on QueryBuilder<StashItem, StashItem, QFilterCondition> {}

extension StashItemQueryLinks
    on QueryBuilder<StashItem, StashItem, QFilterCondition> {}

extension StashItemQuerySortBy on QueryBuilder<StashItem, StashItem, QSortBy> {
  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByDateAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateAdded', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByDateAddedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateAdded', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByDictionaryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dictionaryName', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByDictionaryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dictionaryName', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByMediaIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaIdentifier', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByMediaIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaIdentifier', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy>
  sortByMediaSourceIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSourceIdentifier', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy>
  sortByMediaSourceIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSourceIdentifier', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByReading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reading', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByReadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reading', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortBySentence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentence', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortBySentenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentence', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByStashKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stashKey', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByStashKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stashKey', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByTerm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'term', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByTermDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'term', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByWordLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordLength', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByWordLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordLength', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByWordStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordStart', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> sortByWordStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordStart', Sort.desc);
    });
  }
}

extension StashItemQuerySortThenBy
    on QueryBuilder<StashItem, StashItem, QSortThenBy> {
  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByDateAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateAdded', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByDateAddedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateAdded', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByDictionaryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dictionaryName', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByDictionaryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dictionaryName', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByMediaIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaIdentifier', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByMediaIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaIdentifier', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy>
  thenByMediaSourceIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSourceIdentifier', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy>
  thenByMediaSourceIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaSourceIdentifier', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'position', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByReading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reading', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByReadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reading', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenBySentence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentence', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenBySentenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentence', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByStashKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stashKey', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByStashKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stashKey', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByTerm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'term', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByTermDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'term', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByWordLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordLength', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByWordLengthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordLength', Sort.desc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByWordStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordStart', Sort.asc);
    });
  }

  QueryBuilder<StashItem, StashItem, QAfterSortBy> thenByWordStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wordStart', Sort.desc);
    });
  }
}

extension StashItemQueryWhereDistinct
    on QueryBuilder<StashItem, StashItem, QDistinct> {
  QueryBuilder<StashItem, StashItem, QDistinct> distinctByDateAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateAdded');
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctByDefinitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'definitions');
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctByDictionaryName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'dictionaryName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctByMediaIdentifier({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'mediaIdentifier',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct>
  distinctByMediaSourceIdentifier({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'mediaSourceIdentifier',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctByPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'position');
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctByReading({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reading', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctBySentence({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sentence', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctByStashKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stashKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctByTerm({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'term', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctByWordLength() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wordLength');
    });
  }

  QueryBuilder<StashItem, StashItem, QDistinct> distinctByWordStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wordStart');
    });
  }
}

extension StashItemQueryProperty
    on QueryBuilder<StashItem, StashItem, QQueryProperty> {
  QueryBuilder<StashItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<StashItem, DateTime, QQueryOperations> dateAddedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateAdded');
    });
  }

  QueryBuilder<StashItem, List<String>, QQueryOperations>
  definitionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'definitions');
    });
  }

  QueryBuilder<StashItem, String?, QQueryOperations> dictionaryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dictionaryName');
    });
  }

  QueryBuilder<StashItem, String, QQueryOperations> mediaIdentifierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaIdentifier');
    });
  }

  QueryBuilder<StashItem, String, QQueryOperations>
  mediaSourceIdentifierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaSourceIdentifier');
    });
  }

  QueryBuilder<StashItem, int, QQueryOperations> positionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'position');
    });
  }

  QueryBuilder<StashItem, String, QQueryOperations> readingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reading');
    });
  }

  QueryBuilder<StashItem, String, QQueryOperations> sentenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sentence');
    });
  }

  QueryBuilder<StashItem, String, QQueryOperations> stashKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stashKey');
    });
  }

  QueryBuilder<StashItem, String, QQueryOperations> termProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'term');
    });
  }

  QueryBuilder<StashItem, int, QQueryOperations> wordLengthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wordLength');
    });
  }

  QueryBuilder<StashItem, int, QQueryOperations> wordStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wordStart');
    });
  }
}
