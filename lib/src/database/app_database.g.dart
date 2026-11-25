// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HeadingsTable extends Headings
    with TableInfo<$HeadingsTable, HeadingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, term, reading];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heading';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeadingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {term, reading},
  ];
  @override
  HeadingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeadingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
    );
  }

  @override
  $HeadingsTable createAlias(String alias) {
    return $HeadingsTable(attachedDatabase, alias);
  }
}

class HeadingRow extends DataClass implements Insertable<HeadingRow> {
  /// Assigned by SQLite on insert.
  final int id;

  /// The word as written.
  final String term;

  /// The word's reading, empty for kanji entries and words given no reading.
  final String reading;
  const HeadingRow({
    required this.id,
    required this.term,
    required this.reading,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['term'] = Variable<String>(term);
    map['reading'] = Variable<String>(reading);
    return map;
  }

  HeadingsCompanion toCompanion(bool nullToAbsent) {
    return HeadingsCompanion(
      id: Value(id),
      term: Value(term),
      reading: Value(reading),
    );
  }

  factory HeadingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeadingRow(
      id: serializer.fromJson<int>(json['id']),
      term: serializer.fromJson<String>(json['term']),
      reading: serializer.fromJson<String>(json['reading']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'term': serializer.toJson<String>(term),
      'reading': serializer.toJson<String>(reading),
    };
  }

  HeadingRow copyWith({int? id, String? term, String? reading}) => HeadingRow(
    id: id ?? this.id,
    term: term ?? this.term,
    reading: reading ?? this.reading,
  );
  HeadingRow copyWithCompanion(HeadingsCompanion data) {
    return HeadingRow(
      id: data.id.present ? data.id.value : this.id,
      term: data.term.present ? data.term.value : this.term,
      reading: data.reading.present ? data.reading.value : this.reading,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeadingRow(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('reading: $reading')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, term, reading);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeadingRow &&
          other.id == this.id &&
          other.term == this.term &&
          other.reading == this.reading);
}

class HeadingsCompanion extends UpdateCompanion<HeadingRow> {
  final Value<int> id;
  final Value<String> term;
  final Value<String> reading;
  const HeadingsCompanion({
    this.id = const Value.absent(),
    this.term = const Value.absent(),
    this.reading = const Value.absent(),
  });
  HeadingsCompanion.insert({
    this.id = const Value.absent(),
    required String term,
    required String reading,
  }) : term = Value(term),
       reading = Value(reading);
  static Insertable<HeadingRow> custom({
    Expression<int>? id,
    Expression<String>? term,
    Expression<String>? reading,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (term != null) 'term': term,
      if (reading != null) 'reading': reading,
    });
  }

  HeadingsCompanion copyWith({
    Value<int>? id,
    Value<String>? term,
    Value<String>? reading,
  }) {
    return HeadingsCompanion(
      id: id ?? this.id,
      term: term ?? this.term,
      reading: reading ?? this.reading,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeadingsCompanion(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('reading: $reading')
          ..write(')'))
        .toString();
  }
}

class $DictionariesTable extends Dictionaries
    with TableInfo<$DictionariesTable, Dictionary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _formatKeyMeta = const VerificationMeta(
    'formatKey',
  );
  @override
  late final GeneratedColumn<String> formatKey = GeneratedColumn<String>(
    'format_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCollapsedMeta = const VerificationMeta(
    'isCollapsed',
  );
  @override
  late final GeneratedColumn<bool> isCollapsed = GeneratedColumn<bool>(
    'is_collapsed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_collapsed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    formatKey,
    order,
    isHidden,
    isCollapsed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary';
  @override
  VerificationContext validateIntegrity(
    Insertable<Dictionary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('format_key')) {
      context.handle(
        _formatKeyMeta,
        formatKey.isAcceptableOrUnknown(data['format_key']!, _formatKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_formatKeyMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('is_collapsed')) {
      context.handle(
        _isCollapsedMeta,
        isCollapsed.isAcceptableOrUnknown(
          data['is_collapsed']!,
          _isCollapsedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Dictionary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dictionary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      formatKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format_key'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      isCollapsed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_collapsed'],
      )!,
    );
  }

  @override
  $DictionariesTable createAlias(String alias) {
    return $DictionariesTable(attachedDatabase, alias);
  }
}

class DictionariesCompanion extends UpdateCompanion<Dictionary> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> formatKey;
  final Value<int> order;
  final Value<bool> isHidden;
  final Value<bool> isCollapsed;
  const DictionariesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.formatKey = const Value.absent(),
    this.order = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isCollapsed = const Value.absent(),
  });
  DictionariesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String formatKey,
    required int order,
    this.isHidden = const Value.absent(),
    this.isCollapsed = const Value.absent(),
  }) : name = Value(name),
       formatKey = Value(formatKey),
       order = Value(order);
  static Insertable<Dictionary> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? formatKey,
    Expression<int>? order,
    Expression<bool>? isHidden,
    Expression<bool>? isCollapsed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (formatKey != null) 'format_key': formatKey,
      if (order != null) 'order': order,
      if (isHidden != null) 'is_hidden': isHidden,
      if (isCollapsed != null) 'is_collapsed': isCollapsed,
    });
  }

  DictionariesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? formatKey,
    Value<int>? order,
    Value<bool>? isHidden,
    Value<bool>? isCollapsed,
  }) {
    return DictionariesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      formatKey: formatKey ?? this.formatKey,
      order: order ?? this.order,
      isHidden: isHidden ?? this.isHidden,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (formatKey.present) {
      map['format_key'] = Variable<String>(formatKey.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (isCollapsed.present) {
      map['is_collapsed'] = Variable<bool>(isCollapsed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionariesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('formatKey: $formatKey, ')
          ..write('order: $order, ')
          ..write('isHidden: $isHidden, ')
          ..write('isCollapsed: $isCollapsed')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, EntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingIdMeta = const VerificationMeta(
    'headingId',
  );
  @override
  late final GeneratedColumn<int> headingId = GeneratedColumn<int>(
    'heading_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES heading (id)',
    ),
  );
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<int> dictionaryId = GeneratedColumn<int>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dictionary (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  definitions = GeneratedColumn<String>(
    'definitions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($EntriesTable.$converterdefinitions);
  static const VerificationMeta _popularityMeta = const VerificationMeta(
    'popularity',
  );
  @override
  late final GeneratedColumn<double> popularity = GeneratedColumn<double>(
    'popularity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    headingId,
    dictionaryId,
    definitions,
    popularity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('heading_id')) {
      context.handle(
        _headingIdMeta,
        headingId.isAcceptableOrUnknown(data['heading_id']!, _headingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_headingIdMeta);
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('popularity')) {
      context.handle(
        _popularityMeta,
        popularity.isAcceptableOrUnknown(data['popularity']!, _popularityMeta),
      );
    } else if (isInserting) {
      context.missing(_popularityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      headingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heading_id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dictionary_id'],
      )!,
      definitions: $EntriesTable.$converterdefinitions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}definitions'],
        )!,
      ),
      popularity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}popularity'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterdefinitions =
      const StringListConverter();
}

class EntryRow extends DataClass implements Insertable<EntryRow> {
  /// Assigned by SQLite on insert.
  final int id;

  /// The word defined.
  final int headingId;

  /// The dictionary giving the definitions.
  final int dictionaryId;

  /// The definitions: plain text, or a structured content JSON document.
  final List<String> definitions;

  /// The dictionary's popularity score for this entry; higher is commoner.
  final double popularity;
  const EntryRow({
    required this.id,
    required this.headingId,
    required this.dictionaryId,
    required this.definitions,
    required this.popularity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['heading_id'] = Variable<int>(headingId);
    map['dictionary_id'] = Variable<int>(dictionaryId);
    {
      map['definitions'] = Variable<String>(
        $EntriesTable.$converterdefinitions.toSql(definitions),
      );
    }
    map['popularity'] = Variable<double>(popularity);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      headingId: Value(headingId),
      dictionaryId: Value(dictionaryId),
      definitions: Value(definitions),
      popularity: Value(popularity),
    );
  }

  factory EntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryRow(
      id: serializer.fromJson<int>(json['id']),
      headingId: serializer.fromJson<int>(json['headingId']),
      dictionaryId: serializer.fromJson<int>(json['dictionaryId']),
      definitions: serializer.fromJson<List<String>>(json['definitions']),
      popularity: serializer.fromJson<double>(json['popularity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'headingId': serializer.toJson<int>(headingId),
      'dictionaryId': serializer.toJson<int>(dictionaryId),
      'definitions': serializer.toJson<List<String>>(definitions),
      'popularity': serializer.toJson<double>(popularity),
    };
  }

  EntryRow copyWith({
    int? id,
    int? headingId,
    int? dictionaryId,
    List<String>? definitions,
    double? popularity,
  }) => EntryRow(
    id: id ?? this.id,
    headingId: headingId ?? this.headingId,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    definitions: definitions ?? this.definitions,
    popularity: popularity ?? this.popularity,
  );
  EntryRow copyWithCompanion(EntriesCompanion data) {
    return EntryRow(
      id: data.id.present ? data.id.value : this.id,
      headingId: data.headingId.present ? data.headingId.value : this.headingId,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      definitions: data.definitions.present
          ? data.definitions.value
          : this.definitions,
      popularity: data.popularity.present
          ? data.popularity.value
          : this.popularity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryRow(')
          ..write('id: $id, ')
          ..write('headingId: $headingId, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('definitions: $definitions, ')
          ..write('popularity: $popularity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, headingId, dictionaryId, definitions, popularity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryRow &&
          other.id == this.id &&
          other.headingId == this.headingId &&
          other.dictionaryId == this.dictionaryId &&
          other.definitions == this.definitions &&
          other.popularity == this.popularity);
}

class EntriesCompanion extends UpdateCompanion<EntryRow> {
  final Value<int> id;
  final Value<int> headingId;
  final Value<int> dictionaryId;
  final Value<List<String>> definitions;
  final Value<double> popularity;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.headingId = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.definitions = const Value.absent(),
    this.popularity = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required int headingId,
    required int dictionaryId,
    required List<String> definitions,
    required double popularity,
  }) : headingId = Value(headingId),
       dictionaryId = Value(dictionaryId),
       definitions = Value(definitions),
       popularity = Value(popularity);
  static Insertable<EntryRow> custom({
    Expression<int>? id,
    Expression<int>? headingId,
    Expression<int>? dictionaryId,
    Expression<String>? definitions,
    Expression<double>? popularity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (headingId != null) 'heading_id': headingId,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (definitions != null) 'definitions': definitions,
      if (popularity != null) 'popularity': popularity,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? headingId,
    Value<int>? dictionaryId,
    Value<List<String>>? definitions,
    Value<double>? popularity,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      headingId: headingId ?? this.headingId,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      definitions: definitions ?? this.definitions,
      popularity: popularity ?? this.popularity,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (headingId.present) {
      map['heading_id'] = Variable<int>(headingId.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<int>(dictionaryId.value);
    }
    if (definitions.present) {
      map['definitions'] = Variable<String>(
        $EntriesTable.$converterdefinitions.toSql(definitions.value),
      );
    }
    if (popularity.present) {
      map['popularity'] = Variable<double>(popularity.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('headingId: $headingId, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('definitions: $definitions, ')
          ..write('popularity: $popularity')
          ..write(')'))
        .toString();
  }
}

class $PitchesTable extends Pitches with TableInfo<$PitchesTable, PitchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PitchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingIdMeta = const VerificationMeta(
    'headingId',
  );
  @override
  late final GeneratedColumn<int> headingId = GeneratedColumn<int>(
    'heading_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES heading (id)',
    ),
  );
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<int> dictionaryId = GeneratedColumn<int>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dictionary (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _downstepMeta = const VerificationMeta(
    'downstep',
  );
  @override
  late final GeneratedColumn<int> downstep = GeneratedColumn<int>(
    'downstep',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, headingId, dictionaryId, downstep];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pitch';
  @override
  VerificationContext validateIntegrity(
    Insertable<PitchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('heading_id')) {
      context.handle(
        _headingIdMeta,
        headingId.isAcceptableOrUnknown(data['heading_id']!, _headingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_headingIdMeta);
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('downstep')) {
      context.handle(
        _downstepMeta,
        downstep.isAcceptableOrUnknown(data['downstep']!, _downstepMeta),
      );
    } else if (isInserting) {
      context.missing(_downstepMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PitchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PitchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      headingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heading_id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dictionary_id'],
      )!,
      downstep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downstep'],
      )!,
    );
  }

  @override
  $PitchesTable createAlias(String alias) {
    return $PitchesTable(attachedDatabase, alias);
  }
}

class PitchRow extends DataClass implements Insertable<PitchRow> {
  /// Assigned by SQLite on insert.
  final int id;

  /// The word.
  final int headingId;

  /// The pitch dictionary it comes from.
  final int dictionaryId;

  /// The mora after which the pitch drops; 0 for a flat pattern.
  final int downstep;
  const PitchRow({
    required this.id,
    required this.headingId,
    required this.dictionaryId,
    required this.downstep,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['heading_id'] = Variable<int>(headingId);
    map['dictionary_id'] = Variable<int>(dictionaryId);
    map['downstep'] = Variable<int>(downstep);
    return map;
  }

  PitchesCompanion toCompanion(bool nullToAbsent) {
    return PitchesCompanion(
      id: Value(id),
      headingId: Value(headingId),
      dictionaryId: Value(dictionaryId),
      downstep: Value(downstep),
    );
  }

  factory PitchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PitchRow(
      id: serializer.fromJson<int>(json['id']),
      headingId: serializer.fromJson<int>(json['headingId']),
      dictionaryId: serializer.fromJson<int>(json['dictionaryId']),
      downstep: serializer.fromJson<int>(json['downstep']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'headingId': serializer.toJson<int>(headingId),
      'dictionaryId': serializer.toJson<int>(dictionaryId),
      'downstep': serializer.toJson<int>(downstep),
    };
  }

  PitchRow copyWith({
    int? id,
    int? headingId,
    int? dictionaryId,
    int? downstep,
  }) => PitchRow(
    id: id ?? this.id,
    headingId: headingId ?? this.headingId,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    downstep: downstep ?? this.downstep,
  );
  PitchRow copyWithCompanion(PitchesCompanion data) {
    return PitchRow(
      id: data.id.present ? data.id.value : this.id,
      headingId: data.headingId.present ? data.headingId.value : this.headingId,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      downstep: data.downstep.present ? data.downstep.value : this.downstep,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PitchRow(')
          ..write('id: $id, ')
          ..write('headingId: $headingId, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('downstep: $downstep')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, headingId, dictionaryId, downstep);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PitchRow &&
          other.id == this.id &&
          other.headingId == this.headingId &&
          other.dictionaryId == this.dictionaryId &&
          other.downstep == this.downstep);
}

class PitchesCompanion extends UpdateCompanion<PitchRow> {
  final Value<int> id;
  final Value<int> headingId;
  final Value<int> dictionaryId;
  final Value<int> downstep;
  const PitchesCompanion({
    this.id = const Value.absent(),
    this.headingId = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.downstep = const Value.absent(),
  });
  PitchesCompanion.insert({
    this.id = const Value.absent(),
    required int headingId,
    required int dictionaryId,
    required int downstep,
  }) : headingId = Value(headingId),
       dictionaryId = Value(dictionaryId),
       downstep = Value(downstep);
  static Insertable<PitchRow> custom({
    Expression<int>? id,
    Expression<int>? headingId,
    Expression<int>? dictionaryId,
    Expression<int>? downstep,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (headingId != null) 'heading_id': headingId,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (downstep != null) 'downstep': downstep,
    });
  }

  PitchesCompanion copyWith({
    Value<int>? id,
    Value<int>? headingId,
    Value<int>? dictionaryId,
    Value<int>? downstep,
  }) {
    return PitchesCompanion(
      id: id ?? this.id,
      headingId: headingId ?? this.headingId,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      downstep: downstep ?? this.downstep,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (headingId.present) {
      map['heading_id'] = Variable<int>(headingId.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<int>(dictionaryId.value);
    }
    if (downstep.present) {
      map['downstep'] = Variable<int>(downstep.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PitchesCompanion(')
          ..write('id: $id, ')
          ..write('headingId: $headingId, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('downstep: $downstep')
          ..write(')'))
        .toString();
  }
}

class $FrequenciesTable extends Frequencies
    with TableInfo<$FrequenciesTable, FrequencyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrequenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingIdMeta = const VerificationMeta(
    'headingId',
  );
  @override
  late final GeneratedColumn<int> headingId = GeneratedColumn<int>(
    'heading_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES heading (id)',
    ),
  );
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<int> dictionaryId = GeneratedColumn<int>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dictionary (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayValueMeta = const VerificationMeta(
    'displayValue',
  );
  @override
  late final GeneratedColumn<String> displayValue = GeneratedColumn<String>(
    'display_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    headingId,
    dictionaryId,
    value,
    displayValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'frequency';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrequencyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('heading_id')) {
      context.handle(
        _headingIdMeta,
        headingId.isAcceptableOrUnknown(data['heading_id']!, _headingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_headingIdMeta);
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('display_value')) {
      context.handle(
        _displayValueMeta,
        displayValue.isAcceptableOrUnknown(
          data['display_value']!,
          _displayValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FrequencyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrequencyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      headingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heading_id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dictionary_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      displayValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_value'],
      )!,
    );
  }

  @override
  $FrequenciesTable createAlias(String alias) {
    return $FrequenciesTable(attachedDatabase, alias);
  }
}

class FrequencyRow extends DataClass implements Insertable<FrequencyRow> {
  /// Assigned by SQLite on insert.
  final int id;

  /// The word.
  final int headingId;

  /// The frequency dictionary it comes from.
  final int dictionaryId;

  /// The rank, for sorting; lower is more frequent.
  final double value;

  /// The rank as the dictionary displays it.
  final String displayValue;
  const FrequencyRow({
    required this.id,
    required this.headingId,
    required this.dictionaryId,
    required this.value,
    required this.displayValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['heading_id'] = Variable<int>(headingId);
    map['dictionary_id'] = Variable<int>(dictionaryId);
    map['value'] = Variable<double>(value);
    map['display_value'] = Variable<String>(displayValue);
    return map;
  }

  FrequenciesCompanion toCompanion(bool nullToAbsent) {
    return FrequenciesCompanion(
      id: Value(id),
      headingId: Value(headingId),
      dictionaryId: Value(dictionaryId),
      value: Value(value),
      displayValue: Value(displayValue),
    );
  }

  factory FrequencyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrequencyRow(
      id: serializer.fromJson<int>(json['id']),
      headingId: serializer.fromJson<int>(json['headingId']),
      dictionaryId: serializer.fromJson<int>(json['dictionaryId']),
      value: serializer.fromJson<double>(json['value']),
      displayValue: serializer.fromJson<String>(json['displayValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'headingId': serializer.toJson<int>(headingId),
      'dictionaryId': serializer.toJson<int>(dictionaryId),
      'value': serializer.toJson<double>(value),
      'displayValue': serializer.toJson<String>(displayValue),
    };
  }

  FrequencyRow copyWith({
    int? id,
    int? headingId,
    int? dictionaryId,
    double? value,
    String? displayValue,
  }) => FrequencyRow(
    id: id ?? this.id,
    headingId: headingId ?? this.headingId,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    value: value ?? this.value,
    displayValue: displayValue ?? this.displayValue,
  );
  FrequencyRow copyWithCompanion(FrequenciesCompanion data) {
    return FrequencyRow(
      id: data.id.present ? data.id.value : this.id,
      headingId: data.headingId.present ? data.headingId.value : this.headingId,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      value: data.value.present ? data.value.value : this.value,
      displayValue: data.displayValue.present
          ? data.displayValue.value
          : this.displayValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrequencyRow(')
          ..write('id: $id, ')
          ..write('headingId: $headingId, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('value: $value, ')
          ..write('displayValue: $displayValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, headingId, dictionaryId, value, displayValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrequencyRow &&
          other.id == this.id &&
          other.headingId == this.headingId &&
          other.dictionaryId == this.dictionaryId &&
          other.value == this.value &&
          other.displayValue == this.displayValue);
}

class FrequenciesCompanion extends UpdateCompanion<FrequencyRow> {
  final Value<int> id;
  final Value<int> headingId;
  final Value<int> dictionaryId;
  final Value<double> value;
  final Value<String> displayValue;
  const FrequenciesCompanion({
    this.id = const Value.absent(),
    this.headingId = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.value = const Value.absent(),
    this.displayValue = const Value.absent(),
  });
  FrequenciesCompanion.insert({
    this.id = const Value.absent(),
    required int headingId,
    required int dictionaryId,
    required double value,
    required String displayValue,
  }) : headingId = Value(headingId),
       dictionaryId = Value(dictionaryId),
       value = Value(value),
       displayValue = Value(displayValue);
  static Insertable<FrequencyRow> custom({
    Expression<int>? id,
    Expression<int>? headingId,
    Expression<int>? dictionaryId,
    Expression<double>? value,
    Expression<String>? displayValue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (headingId != null) 'heading_id': headingId,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (value != null) 'value': value,
      if (displayValue != null) 'display_value': displayValue,
    });
  }

  FrequenciesCompanion copyWith({
    Value<int>? id,
    Value<int>? headingId,
    Value<int>? dictionaryId,
    Value<double>? value,
    Value<String>? displayValue,
  }) {
    return FrequenciesCompanion(
      id: id ?? this.id,
      headingId: headingId ?? this.headingId,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      value: value ?? this.value,
      displayValue: displayValue ?? this.displayValue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (headingId.present) {
      map['heading_id'] = Variable<int>(headingId.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<int>(dictionaryId.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (displayValue.present) {
      map['display_value'] = Variable<String>(displayValue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrequenciesCompanion(')
          ..write('id: $id, ')
          ..write('headingId: $headingId, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('value: $value, ')
          ..write('displayValue: $displayValue')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<int> dictionaryId = GeneratedColumn<int>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dictionary (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
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
  static const VerificationMeta _sortingOrderMeta = const VerificationMeta(
    'sortingOrder',
  );
  @override
  late final GeneratedColumn<int> sortingOrder = GeneratedColumn<int>(
    'sorting_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _popularityMeta = const VerificationMeta(
    'popularity',
  );
  @override
  late final GeneratedColumn<double> popularity = GeneratedColumn<double>(
    'popularity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictionaryId,
    name,
    category,
    sortingOrder,
    notes,
    popularity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sorting_order')) {
      context.handle(
        _sortingOrderMeta,
        sortingOrder.isAcceptableOrUnknown(
          data['sorting_order']!,
          _sortingOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sortingOrderMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('popularity')) {
      context.handle(
        _popularityMeta,
        popularity.isAcceptableOrUnknown(data['popularity']!, _popularityMeta),
      );
    } else if (isInserting) {
      context.missing(_popularityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {dictionaryId, name},
  ];
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dictionary_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      sortingOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sorting_order'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      popularity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}popularity'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  /// Assigned by SQLite on insert.
  final int id;

  /// The dictionary defining the tag.
  final int dictionaryId;

  /// The short label, such as `v1` or `P`.
  final String name;

  /// The kind of tag; picks its colour.
  final String category;

  /// Display order among tags.
  final int sortingOrder;

  /// What the label means.
  final String notes;

  /// The dictionary's score for the tag.
  final double popularity;
  const TagRow({
    required this.id,
    required this.dictionaryId,
    required this.name,
    required this.category,
    required this.sortingOrder,
    required this.notes,
    required this.popularity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dictionary_id'] = Variable<int>(dictionaryId);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['sorting_order'] = Variable<int>(sortingOrder);
    map['notes'] = Variable<String>(notes);
    map['popularity'] = Variable<double>(popularity);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      dictionaryId: Value(dictionaryId),
      name: Value(name),
      category: Value(category),
      sortingOrder: Value(sortingOrder),
      notes: Value(notes),
      popularity: Value(popularity),
    );
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<int>(json['id']),
      dictionaryId: serializer.fromJson<int>(json['dictionaryId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      sortingOrder: serializer.fromJson<int>(json['sortingOrder']),
      notes: serializer.fromJson<String>(json['notes']),
      popularity: serializer.fromJson<double>(json['popularity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictionaryId': serializer.toJson<int>(dictionaryId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'sortingOrder': serializer.toJson<int>(sortingOrder),
      'notes': serializer.toJson<String>(notes),
      'popularity': serializer.toJson<double>(popularity),
    };
  }

  TagRow copyWith({
    int? id,
    int? dictionaryId,
    String? name,
    String? category,
    int? sortingOrder,
    String? notes,
    double? popularity,
  }) => TagRow(
    id: id ?? this.id,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    name: name ?? this.name,
    category: category ?? this.category,
    sortingOrder: sortingOrder ?? this.sortingOrder,
    notes: notes ?? this.notes,
    popularity: popularity ?? this.popularity,
  );
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      sortingOrder: data.sortingOrder.present
          ? data.sortingOrder.value
          : this.sortingOrder,
      notes: data.notes.present ? data.notes.value : this.notes,
      popularity: data.popularity.present
          ? data.popularity.value
          : this.popularity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('sortingOrder: $sortingOrder, ')
          ..write('notes: $notes, ')
          ..write('popularity: $popularity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dictionaryId,
    name,
    category,
    sortingOrder,
    notes,
    popularity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.dictionaryId == this.dictionaryId &&
          other.name == this.name &&
          other.category == this.category &&
          other.sortingOrder == this.sortingOrder &&
          other.notes == this.notes &&
          other.popularity == this.popularity);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<int> id;
  final Value<int> dictionaryId;
  final Value<String> name;
  final Value<String> category;
  final Value<int> sortingOrder;
  final Value<String> notes;
  final Value<double> popularity;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.sortingOrder = const Value.absent(),
    this.notes = const Value.absent(),
    this.popularity = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required int dictionaryId,
    required String name,
    required String category,
    required int sortingOrder,
    required String notes,
    required double popularity,
  }) : dictionaryId = Value(dictionaryId),
       name = Value(name),
       category = Value(category),
       sortingOrder = Value(sortingOrder),
       notes = Value(notes),
       popularity = Value(popularity);
  static Insertable<TagRow> custom({
    Expression<int>? id,
    Expression<int>? dictionaryId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? sortingOrder,
    Expression<String>? notes,
    Expression<double>? popularity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (sortingOrder != null) 'sorting_order': sortingOrder,
      if (notes != null) 'notes': notes,
      if (popularity != null) 'popularity': popularity,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<int>? dictionaryId,
    Value<String>? name,
    Value<String>? category,
    Value<int>? sortingOrder,
    Value<String>? notes,
    Value<double>? popularity,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      name: name ?? this.name,
      category: category ?? this.category,
      sortingOrder: sortingOrder ?? this.sortingOrder,
      notes: notes ?? this.notes,
      popularity: popularity ?? this.popularity,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<int>(dictionaryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sortingOrder.present) {
      map['sorting_order'] = Variable<int>(sortingOrder.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (popularity.present) {
      map['popularity'] = Variable<double>(popularity.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('sortingOrder: $sortingOrder, ')
          ..write('notes: $notes, ')
          ..write('popularity: $popularity')
          ..write(')'))
        .toString();
  }
}

class $HeadingTagsTable extends HeadingTags
    with TableInfo<$HeadingTagsTable, HeadingTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeadingTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _headingIdMeta = const VerificationMeta(
    'headingId',
  );
  @override
  late final GeneratedColumn<int> headingId = GeneratedColumn<int>(
    'heading_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES heading (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tag (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [headingId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heading_tag';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeadingTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('heading_id')) {
      context.handle(
        _headingIdMeta,
        headingId.isAcceptableOrUnknown(data['heading_id']!, _headingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_headingIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {headingId, tagId};
  @override
  HeadingTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeadingTagRow(
      headingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heading_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $HeadingTagsTable createAlias(String alias) {
    return $HeadingTagsTable(attachedDatabase, alias);
  }
}

class HeadingTagRow extends DataClass implements Insertable<HeadingTagRow> {
  /// The heading tagged.
  final int headingId;

  /// The tag.
  final int tagId;
  const HeadingTagRow({required this.headingId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['heading_id'] = Variable<int>(headingId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  HeadingTagsCompanion toCompanion(bool nullToAbsent) {
    return HeadingTagsCompanion(
      headingId: Value(headingId),
      tagId: Value(tagId),
    );
  }

  factory HeadingTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeadingTagRow(
      headingId: serializer.fromJson<int>(json['headingId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'headingId': serializer.toJson<int>(headingId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  HeadingTagRow copyWith({int? headingId, int? tagId}) => HeadingTagRow(
    headingId: headingId ?? this.headingId,
    tagId: tagId ?? this.tagId,
  );
  HeadingTagRow copyWithCompanion(HeadingTagsCompanion data) {
    return HeadingTagRow(
      headingId: data.headingId.present ? data.headingId.value : this.headingId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeadingTagRow(')
          ..write('headingId: $headingId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(headingId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeadingTagRow &&
          other.headingId == this.headingId &&
          other.tagId == this.tagId);
}

class HeadingTagsCompanion extends UpdateCompanion<HeadingTagRow> {
  final Value<int> headingId;
  final Value<int> tagId;
  final Value<int> rowid;
  const HeadingTagsCompanion({
    this.headingId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeadingTagsCompanion.insert({
    required int headingId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : headingId = Value(headingId),
       tagId = Value(tagId);
  static Insertable<HeadingTagRow> custom({
    Expression<int>? headingId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (headingId != null) 'heading_id': headingId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeadingTagsCompanion copyWith({
    Value<int>? headingId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return HeadingTagsCompanion(
      headingId: headingId ?? this.headingId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (headingId.present) {
      map['heading_id'] = Variable<int>(headingId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeadingTagsCompanion(')
          ..write('headingId: $headingId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryTagsTable extends EntryTags
    with TableInfo<$EntryTagsTable, EntryTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entry (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tag (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_tag';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, tagId};
  @override
  EntryTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryTagRow(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $EntryTagsTable createAlias(String alias) {
    return $EntryTagsTable(attachedDatabase, alias);
  }
}

class EntryTagRow extends DataClass implements Insertable<EntryTagRow> {
  /// The entry tagged.
  final int entryId;

  /// The tag.
  final int tagId;
  const EntryTagRow({required this.entryId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<int>(entryId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  EntryTagsCompanion toCompanion(bool nullToAbsent) {
    return EntryTagsCompanion(entryId: Value(entryId), tagId: Value(tagId));
  }

  factory EntryTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryTagRow(
      entryId: serializer.fromJson<int>(json['entryId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<int>(entryId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  EntryTagRow copyWith({int? entryId, int? tagId}) =>
      EntryTagRow(entryId: entryId ?? this.entryId, tagId: tagId ?? this.tagId);
  EntryTagRow copyWithCompanion(EntryTagsCompanion data) {
    return EntryTagRow(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryTagRow(')
          ..write('entryId: $entryId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryTagRow &&
          other.entryId == this.entryId &&
          other.tagId == this.tagId);
}

class EntryTagsCompanion extends UpdateCompanion<EntryTagRow> {
  final Value<int> entryId;
  final Value<int> tagId;
  final Value<int> rowid;
  const EntryTagsCompanion({
    this.entryId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryTagsCompanion.insert({
    required int entryId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       tagId = Value(tagId);
  static Insertable<EntryTagRow> custom({
    Expression<int>? entryId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryTagsCompanion copyWith({
    Value<int>? entryId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return EntryTagsCompanion(
      entryId: entryId ?? this.entryId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryTagsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mediaSourceIdentifierMeta =
      const VerificationMeta('mediaSourceIdentifier');
  @override
  late final GeneratedColumn<String> mediaSourceIdentifier =
      GeneratedColumn<String>(
        'media_source_identifier',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _mediaIdentifierMeta = const VerificationMeta(
    'mediaIdentifier',
  );
  @override
  late final GeneratedColumn<String> mediaIdentifier = GeneratedColumn<String>(
    'media_identifier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMetadataMeta = const VerificationMeta(
    'sourceMetadata',
  );
  @override
  late final GeneratedColumn<String> sourceMetadata = GeneratedColumn<String>(
    'source_metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canDeleteMeta = const VerificationMeta(
    'canDelete',
  );
  @override
  late final GeneratedColumn<bool> canDelete = GeneratedColumn<bool>(
    'can_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_delete" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canEditMeta = const VerificationMeta(
    'canEdit',
  );
  @override
  late final GeneratedColumn<bool> canEdit = GeneratedColumn<bool>(
    'can_edit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_edit" IN (0, 1))',
    ),
  );
  static const VerificationMeta _overrideTitleMeta = const VerificationMeta(
    'overrideTitle',
  );
  @override
  late final GeneratedColumn<String> overrideTitle = GeneratedColumn<String>(
    'override_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> lastOpenedAt =
      GeneratedColumn<int>(
        'last_opened_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($MediaItemsTable.$converterlastOpenedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaSourceIdentifier,
    mediaIdentifier,
    title,
    imageUrl,
    sourceMetadata,
    position,
    duration,
    canDelete,
    canEdit,
    overrideTitle,
    lastOpenedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('media_source_identifier')) {
      context.handle(
        _mediaSourceIdentifierMeta,
        mediaSourceIdentifier.isAcceptableOrUnknown(
          data['media_source_identifier']!,
          _mediaSourceIdentifierMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaSourceIdentifierMeta);
    }
    if (data.containsKey('media_identifier')) {
      context.handle(
        _mediaIdentifierMeta,
        mediaIdentifier.isAcceptableOrUnknown(
          data['media_identifier']!,
          _mediaIdentifierMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaIdentifierMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('source_metadata')) {
      context.handle(
        _sourceMetadataMeta,
        sourceMetadata.isAcceptableOrUnknown(
          data['source_metadata']!,
          _sourceMetadataMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('can_delete')) {
      context.handle(
        _canDeleteMeta,
        canDelete.isAcceptableOrUnknown(data['can_delete']!, _canDeleteMeta),
      );
    } else if (isInserting) {
      context.missing(_canDeleteMeta);
    }
    if (data.containsKey('can_edit')) {
      context.handle(
        _canEditMeta,
        canEdit.isAcceptableOrUnknown(data['can_edit']!, _canEditMeta),
      );
    } else if (isInserting) {
      context.missing(_canEditMeta);
    }
    if (data.containsKey('override_title')) {
      context.handle(
        _overrideTitleMeta,
        overrideTitle.isAcceptableOrUnknown(
          data['override_title']!,
          _overrideTitleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {mediaSourceIdentifier, mediaIdentifier},
  ];
  @override
  MediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItem(
      mediaIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_identifier'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      mediaSourceIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_source_identifier'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      canDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_delete'],
      )!,
      canEdit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_edit'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      sourceMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_metadata'],
      ),
      lastOpenedAt: $MediaItemsTable.$converterlastOpenedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_opened_at'],
        )!,
      ),
      overrideTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_title'],
      ),
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterlastOpenedAt =
      const MicrosecondsConverter();
}

class MediaItemsCompanion extends UpdateCompanion<MediaItem> {
  final Value<int> id;
  final Value<String> mediaSourceIdentifier;
  final Value<String> mediaIdentifier;
  final Value<String> title;
  final Value<String?> imageUrl;
  final Value<String?> sourceMetadata;
  final Value<int> position;
  final Value<int> duration;
  final Value<bool> canDelete;
  final Value<bool> canEdit;
  final Value<String?> overrideTitle;
  final Value<DateTime> lastOpenedAt;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.mediaSourceIdentifier = const Value.absent(),
    this.mediaIdentifier = const Value.absent(),
    this.title = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.sourceMetadata = const Value.absent(),
    this.position = const Value.absent(),
    this.duration = const Value.absent(),
    this.canDelete = const Value.absent(),
    this.canEdit = const Value.absent(),
    this.overrideTitle = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    this.id = const Value.absent(),
    required String mediaSourceIdentifier,
    required String mediaIdentifier,
    required String title,
    this.imageUrl = const Value.absent(),
    this.sourceMetadata = const Value.absent(),
    required int position,
    required int duration,
    required bool canDelete,
    required bool canEdit,
    this.overrideTitle = const Value.absent(),
    required DateTime lastOpenedAt,
  }) : mediaSourceIdentifier = Value(mediaSourceIdentifier),
       mediaIdentifier = Value(mediaIdentifier),
       title = Value(title),
       position = Value(position),
       duration = Value(duration),
       canDelete = Value(canDelete),
       canEdit = Value(canEdit),
       lastOpenedAt = Value(lastOpenedAt);
  static Insertable<MediaItem> custom({
    Expression<int>? id,
    Expression<String>? mediaSourceIdentifier,
    Expression<String>? mediaIdentifier,
    Expression<String>? title,
    Expression<String>? imageUrl,
    Expression<String>? sourceMetadata,
    Expression<int>? position,
    Expression<int>? duration,
    Expression<bool>? canDelete,
    Expression<bool>? canEdit,
    Expression<String>? overrideTitle,
    Expression<int>? lastOpenedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaSourceIdentifier != null)
        'media_source_identifier': mediaSourceIdentifier,
      if (mediaIdentifier != null) 'media_identifier': mediaIdentifier,
      if (title != null) 'title': title,
      if (imageUrl != null) 'image_url': imageUrl,
      if (sourceMetadata != null) 'source_metadata': sourceMetadata,
      if (position != null) 'position': position,
      if (duration != null) 'duration': duration,
      if (canDelete != null) 'can_delete': canDelete,
      if (canEdit != null) 'can_edit': canEdit,
      if (overrideTitle != null) 'override_title': overrideTitle,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
    });
  }

  MediaItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? mediaSourceIdentifier,
    Value<String>? mediaIdentifier,
    Value<String>? title,
    Value<String?>? imageUrl,
    Value<String?>? sourceMetadata,
    Value<int>? position,
    Value<int>? duration,
    Value<bool>? canDelete,
    Value<bool>? canEdit,
    Value<String?>? overrideTitle,
    Value<DateTime>? lastOpenedAt,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      mediaSourceIdentifier:
          mediaSourceIdentifier ?? this.mediaSourceIdentifier,
      mediaIdentifier: mediaIdentifier ?? this.mediaIdentifier,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceMetadata: sourceMetadata ?? this.sourceMetadata,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      canDelete: canDelete ?? this.canDelete,
      canEdit: canEdit ?? this.canEdit,
      overrideTitle: overrideTitle ?? this.overrideTitle,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mediaSourceIdentifier.present) {
      map['media_source_identifier'] = Variable<String>(
        mediaSourceIdentifier.value,
      );
    }
    if (mediaIdentifier.present) {
      map['media_identifier'] = Variable<String>(mediaIdentifier.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (sourceMetadata.present) {
      map['source_metadata'] = Variable<String>(sourceMetadata.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (canDelete.present) {
      map['can_delete'] = Variable<bool>(canDelete.value);
    }
    if (canEdit.present) {
      map['can_edit'] = Variable<bool>(canEdit.value);
    }
    if (overrideTitle.present) {
      map['override_title'] = Variable<String>(overrideTitle.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<int>(
        $MediaItemsTable.$converterlastOpenedAt.toSql(lastOpenedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('mediaSourceIdentifier: $mediaSourceIdentifier, ')
          ..write('mediaIdentifier: $mediaIdentifier, ')
          ..write('title: $title, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sourceMetadata: $sourceMetadata, ')
          ..write('position: $position, ')
          ..write('duration: $duration, ')
          ..write('canDelete: $canDelete, ')
          ..write('canEdit: $canEdit, ')
          ..write('overrideTitle: $overrideTitle, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }
}

class $StashItemsTable extends StashItems
    with TableInfo<$StashItemsTable, StashItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StashItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mediaItemIdMeta = const VerificationMeta(
    'mediaItemId',
  );
  @override
  late final GeneratedColumn<int> mediaItemId = GeneratedColumn<int>(
    'media_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_item (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dictionaryNameMeta = const VerificationMeta(
    'dictionaryName',
  );
  @override
  late final GeneratedColumn<String> dictionaryName = GeneratedColumn<String>(
    'dictionary_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  definitions = GeneratedColumn<String>(
    'definitions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($StashItemsTable.$converterdefinitions);
  static const VerificationMeta _sentenceMeta = const VerificationMeta(
    'sentence',
  );
  @override
  late final GeneratedColumn<String> sentence = GeneratedColumn<String>(
    'sentence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordStartMeta = const VerificationMeta(
    'wordStart',
  );
  @override
  late final GeneratedColumn<int> wordStart = GeneratedColumn<int>(
    'word_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordLengthMeta = const VerificationMeta(
    'wordLength',
  );
  @override
  late final GeneratedColumn<int> wordLength = GeneratedColumn<int>(
    'word_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaItemId,
    term,
    reading,
    dictionaryName,
    definitions,
    sentence,
    wordStart,
    wordLength,
    position,
    dateAdded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stash_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<StashItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('media_item_id')) {
      context.handle(
        _mediaItemIdMeta,
        mediaItemId.isAcceptableOrUnknown(
          data['media_item_id']!,
          _mediaItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaItemIdMeta);
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('dictionary_name')) {
      context.handle(
        _dictionaryNameMeta,
        dictionaryName.isAcceptableOrUnknown(
          data['dictionary_name']!,
          _dictionaryNameMeta,
        ),
      );
    }
    if (data.containsKey('sentence')) {
      context.handle(
        _sentenceMeta,
        sentence.isAcceptableOrUnknown(data['sentence']!, _sentenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sentenceMeta);
    }
    if (data.containsKey('word_start')) {
      context.handle(
        _wordStartMeta,
        wordStart.isAcceptableOrUnknown(data['word_start']!, _wordStartMeta),
      );
    } else if (isInserting) {
      context.missing(_wordStartMeta);
    }
    if (data.containsKey('word_length')) {
      context.handle(
        _wordLengthMeta,
        wordLength.isAcceptableOrUnknown(data['word_length']!, _wordLengthMeta),
      );
    } else if (isInserting) {
      context.missing(_wordLengthMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    } else if (isInserting) {
      context.missing(_dateAddedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {mediaItemId, term, reading},
  ];
  @override
  StashItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StashItem(
      mediaItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_item_id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      dictionaryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dictionary_name'],
      ),
      definitions: $StashItemsTable.$converterdefinitions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}definitions'],
        )!,
      ),
      sentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence'],
      )!,
      wordStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_start'],
      )!,
      wordLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_length'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $StashItemsTable createAlias(String alias) {
    return $StashItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterdefinitions =
      const StringListConverter();
}

class StashItemsCompanion extends UpdateCompanion<StashItem> {
  final Value<int> id;
  final Value<int> mediaItemId;
  final Value<String> term;
  final Value<String> reading;
  final Value<String?> dictionaryName;
  final Value<List<String>> definitions;
  final Value<String> sentence;
  final Value<int> wordStart;
  final Value<int> wordLength;
  final Value<int> position;
  final Value<DateTime> dateAdded;
  const StashItemsCompanion({
    this.id = const Value.absent(),
    this.mediaItemId = const Value.absent(),
    this.term = const Value.absent(),
    this.reading = const Value.absent(),
    this.dictionaryName = const Value.absent(),
    this.definitions = const Value.absent(),
    this.sentence = const Value.absent(),
    this.wordStart = const Value.absent(),
    this.wordLength = const Value.absent(),
    this.position = const Value.absent(),
    this.dateAdded = const Value.absent(),
  });
  StashItemsCompanion.insert({
    this.id = const Value.absent(),
    required int mediaItemId,
    required String term,
    required String reading,
    this.dictionaryName = const Value.absent(),
    required List<String> definitions,
    required String sentence,
    required int wordStart,
    required int wordLength,
    required int position,
    required DateTime dateAdded,
  }) : mediaItemId = Value(mediaItemId),
       term = Value(term),
       reading = Value(reading),
       definitions = Value(definitions),
       sentence = Value(sentence),
       wordStart = Value(wordStart),
       wordLength = Value(wordLength),
       position = Value(position),
       dateAdded = Value(dateAdded);
  static Insertable<StashItem> custom({
    Expression<int>? id,
    Expression<int>? mediaItemId,
    Expression<String>? term,
    Expression<String>? reading,
    Expression<String>? dictionaryName,
    Expression<String>? definitions,
    Expression<String>? sentence,
    Expression<int>? wordStart,
    Expression<int>? wordLength,
    Expression<int>? position,
    Expression<DateTime>? dateAdded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaItemId != null) 'media_item_id': mediaItemId,
      if (term != null) 'term': term,
      if (reading != null) 'reading': reading,
      if (dictionaryName != null) 'dictionary_name': dictionaryName,
      if (definitions != null) 'definitions': definitions,
      if (sentence != null) 'sentence': sentence,
      if (wordStart != null) 'word_start': wordStart,
      if (wordLength != null) 'word_length': wordLength,
      if (position != null) 'position': position,
      if (dateAdded != null) 'date_added': dateAdded,
    });
  }

  StashItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? mediaItemId,
    Value<String>? term,
    Value<String>? reading,
    Value<String?>? dictionaryName,
    Value<List<String>>? definitions,
    Value<String>? sentence,
    Value<int>? wordStart,
    Value<int>? wordLength,
    Value<int>? position,
    Value<DateTime>? dateAdded,
  }) {
    return StashItemsCompanion(
      id: id ?? this.id,
      mediaItemId: mediaItemId ?? this.mediaItemId,
      term: term ?? this.term,
      reading: reading ?? this.reading,
      dictionaryName: dictionaryName ?? this.dictionaryName,
      definitions: definitions ?? this.definitions,
      sentence: sentence ?? this.sentence,
      wordStart: wordStart ?? this.wordStart,
      wordLength: wordLength ?? this.wordLength,
      position: position ?? this.position,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mediaItemId.present) {
      map['media_item_id'] = Variable<int>(mediaItemId.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (dictionaryName.present) {
      map['dictionary_name'] = Variable<String>(dictionaryName.value);
    }
    if (definitions.present) {
      map['definitions'] = Variable<String>(
        $StashItemsTable.$converterdefinitions.toSql(definitions.value),
      );
    }
    if (sentence.present) {
      map['sentence'] = Variable<String>(sentence.value);
    }
    if (wordStart.present) {
      map['word_start'] = Variable<int>(wordStart.value);
    }
    if (wordLength.present) {
      map['word_length'] = Variable<int>(wordLength.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StashItemsCompanion(')
          ..write('id: $id, ')
          ..write('mediaItemId: $mediaItemId, ')
          ..write('term: $term, ')
          ..write('reading: $reading, ')
          ..write('dictionaryName: $dictionaryName, ')
          ..write('definitions: $definitions, ')
          ..write('sentence: $sentence, ')
          ..write('wordStart: $wordStart, ')
          ..write('wordLength: $wordLength, ')
          ..write('position: $position, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }
}

class $AnkiMappingsTable extends AnkiMappings
    with TableInfo<$AnkiMappingsTable, AnkiMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnkiMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String?>, String>
  exportFieldKeys = GeneratedColumn<String>(
    'export_field_keys',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String?>>($AnkiMappingsTable.$converterexportFieldKeys);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  creatorFieldKeys = GeneratedColumn<String>(
    'creator_field_keys',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($AnkiMappingsTable.$convertercreatorFieldKeys);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  creatorCollapsedFieldKeys =
      GeneratedColumn<String>(
        'creator_collapsed_field_keys',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>(
        $AnkiMappingsTable.$convertercreatorCollapsedFieldKeys,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($AnkiMappingsTable.$convertertags);
  @override
  late final GeneratedColumnWithTypeConverter<
    Map<String, Map<int, String>>,
    String
  >
  enhancements =
      GeneratedColumn<String>(
        'enhancements',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Map<String, Map<int, String>>>(
        $AnkiMappingsTable.$converterenhancements,
      );
  static const VerificationMeta _exportMediaTagsMeta = const VerificationMeta(
    'exportMediaTags',
  );
  @override
  late final GeneratedColumn<bool> exportMediaTags = GeneratedColumn<bool>(
    'export_media_tags',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("export_media_tags" IN (0, 1))',
    ),
  );
  static const VerificationMeta _useBrTagsMeta = const VerificationMeta(
    'useBrTags',
  );
  @override
  late final GeneratedColumn<bool> useBrTags = GeneratedColumn<bool>(
    'use_br_tags',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_br_tags" IN (0, 1))',
    ),
  );
  static const VerificationMeta _prependDictionaryNamesMeta =
      const VerificationMeta('prependDictionaryNames');
  @override
  late final GeneratedColumn<bool> prependDictionaryNames =
      GeneratedColumn<bool>(
        'prepend_dictionary_names',
        aliasedName,
        true,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("prepend_dictionary_names" IN (0, 1))',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    model,
    order,
    exportFieldKeys,
    creatorFieldKeys,
    creatorCollapsedFieldKeys,
    tags,
    enhancements,
    exportMediaTags,
    useBrTags,
    prependDictionaryNames,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anki_mapping';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnkiMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('export_media_tags')) {
      context.handle(
        _exportMediaTagsMeta,
        exportMediaTags.isAcceptableOrUnknown(
          data['export_media_tags']!,
          _exportMediaTagsMeta,
        ),
      );
    }
    if (data.containsKey('use_br_tags')) {
      context.handle(
        _useBrTagsMeta,
        useBrTags.isAcceptableOrUnknown(data['use_br_tags']!, _useBrTagsMeta),
      );
    }
    if (data.containsKey('prepend_dictionary_names')) {
      context.handle(
        _prependDictionaryNamesMeta,
        prependDictionaryNames.isAcceptableOrUnknown(
          data['prepend_dictionary_names']!,
          _prependDictionaryNamesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnkiMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnkiMapping(
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      exportFieldKeys: $AnkiMappingsTable.$converterexportFieldKeys.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}export_field_keys'],
        )!,
      ),
      creatorFieldKeys: $AnkiMappingsTable.$convertercreatorFieldKeys.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}creator_field_keys'],
        )!,
      ),
      creatorCollapsedFieldKeys: $AnkiMappingsTable
          .$convertercreatorCollapsedFieldKeys
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}creator_collapsed_field_keys'],
            )!,
          ),
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      tags: $AnkiMappingsTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      exportMediaTags: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}export_media_tags'],
      ),
      useBrTags: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_br_tags'],
      ),
      prependDictionaryNames: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}prepend_dictionary_names'],
      ),
      enhancements: $AnkiMappingsTable.$converterenhancements.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}enhancements'],
        )!,
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $AnkiMappingsTable createAlias(String alias) {
    return $AnkiMappingsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String?>, String> $converterexportFieldKeys =
      const NullableStringListConverter();
  static TypeConverter<List<String>, String> $convertercreatorFieldKeys =
      const StringListConverter();
  static TypeConverter<List<String>, String>
  $convertercreatorCollapsedFieldKeys = const StringListConverter();
  static TypeConverter<List<String>, String> $convertertags =
      const StringListConverter();
  static TypeConverter<Map<String, Map<int, String>>, String>
  $converterenhancements = const EnhancementsColumnConverter();
}

class AnkiMappingsCompanion extends UpdateCompanion<AnkiMapping> {
  final Value<int> id;
  final Value<String> label;
  final Value<String> model;
  final Value<int> order;
  final Value<List<String?>> exportFieldKeys;
  final Value<List<String>> creatorFieldKeys;
  final Value<List<String>> creatorCollapsedFieldKeys;
  final Value<List<String>> tags;
  final Value<Map<String, Map<int, String>>> enhancements;
  final Value<bool?> exportMediaTags;
  final Value<bool?> useBrTags;
  final Value<bool?> prependDictionaryNames;
  const AnkiMappingsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.model = const Value.absent(),
    this.order = const Value.absent(),
    this.exportFieldKeys = const Value.absent(),
    this.creatorFieldKeys = const Value.absent(),
    this.creatorCollapsedFieldKeys = const Value.absent(),
    this.tags = const Value.absent(),
    this.enhancements = const Value.absent(),
    this.exportMediaTags = const Value.absent(),
    this.useBrTags = const Value.absent(),
    this.prependDictionaryNames = const Value.absent(),
  });
  AnkiMappingsCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    required String model,
    required int order,
    required List<String?> exportFieldKeys,
    required List<String> creatorFieldKeys,
    required List<String> creatorCollapsedFieldKeys,
    required List<String> tags,
    required Map<String, Map<int, String>> enhancements,
    this.exportMediaTags = const Value.absent(),
    this.useBrTags = const Value.absent(),
    this.prependDictionaryNames = const Value.absent(),
  }) : label = Value(label),
       model = Value(model),
       order = Value(order),
       exportFieldKeys = Value(exportFieldKeys),
       creatorFieldKeys = Value(creatorFieldKeys),
       creatorCollapsedFieldKeys = Value(creatorCollapsedFieldKeys),
       tags = Value(tags),
       enhancements = Value(enhancements);
  static Insertable<AnkiMapping> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<String>? model,
    Expression<int>? order,
    Expression<String>? exportFieldKeys,
    Expression<String>? creatorFieldKeys,
    Expression<String>? creatorCollapsedFieldKeys,
    Expression<String>? tags,
    Expression<String>? enhancements,
    Expression<bool>? exportMediaTags,
    Expression<bool>? useBrTags,
    Expression<bool>? prependDictionaryNames,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (model != null) 'model': model,
      if (order != null) 'order': order,
      if (exportFieldKeys != null) 'export_field_keys': exportFieldKeys,
      if (creatorFieldKeys != null) 'creator_field_keys': creatorFieldKeys,
      if (creatorCollapsedFieldKeys != null)
        'creator_collapsed_field_keys': creatorCollapsedFieldKeys,
      if (tags != null) 'tags': tags,
      if (enhancements != null) 'enhancements': enhancements,
      if (exportMediaTags != null) 'export_media_tags': exportMediaTags,
      if (useBrTags != null) 'use_br_tags': useBrTags,
      if (prependDictionaryNames != null)
        'prepend_dictionary_names': prependDictionaryNames,
    });
  }

  AnkiMappingsCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<String>? model,
    Value<int>? order,
    Value<List<String?>>? exportFieldKeys,
    Value<List<String>>? creatorFieldKeys,
    Value<List<String>>? creatorCollapsedFieldKeys,
    Value<List<String>>? tags,
    Value<Map<String, Map<int, String>>>? enhancements,
    Value<bool?>? exportMediaTags,
    Value<bool?>? useBrTags,
    Value<bool?>? prependDictionaryNames,
  }) {
    return AnkiMappingsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      model: model ?? this.model,
      order: order ?? this.order,
      exportFieldKeys: exportFieldKeys ?? this.exportFieldKeys,
      creatorFieldKeys: creatorFieldKeys ?? this.creatorFieldKeys,
      creatorCollapsedFieldKeys:
          creatorCollapsedFieldKeys ?? this.creatorCollapsedFieldKeys,
      tags: tags ?? this.tags,
      enhancements: enhancements ?? this.enhancements,
      exportMediaTags: exportMediaTags ?? this.exportMediaTags,
      useBrTags: useBrTags ?? this.useBrTags,
      prependDictionaryNames:
          prependDictionaryNames ?? this.prependDictionaryNames,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (exportFieldKeys.present) {
      map['export_field_keys'] = Variable<String>(
        $AnkiMappingsTable.$converterexportFieldKeys.toSql(
          exportFieldKeys.value,
        ),
      );
    }
    if (creatorFieldKeys.present) {
      map['creator_field_keys'] = Variable<String>(
        $AnkiMappingsTable.$convertercreatorFieldKeys.toSql(
          creatorFieldKeys.value,
        ),
      );
    }
    if (creatorCollapsedFieldKeys.present) {
      map['creator_collapsed_field_keys'] = Variable<String>(
        $AnkiMappingsTable.$convertercreatorCollapsedFieldKeys.toSql(
          creatorCollapsedFieldKeys.value,
        ),
      );
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $AnkiMappingsTable.$convertertags.toSql(tags.value),
      );
    }
    if (enhancements.present) {
      map['enhancements'] = Variable<String>(
        $AnkiMappingsTable.$converterenhancements.toSql(enhancements.value),
      );
    }
    if (exportMediaTags.present) {
      map['export_media_tags'] = Variable<bool>(exportMediaTags.value);
    }
    if (useBrTags.present) {
      map['use_br_tags'] = Variable<bool>(useBrTags.value);
    }
    if (prependDictionaryNames.present) {
      map['prepend_dictionary_names'] = Variable<bool>(
        prependDictionaryNames.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnkiMappingsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('model: $model, ')
          ..write('order: $order, ')
          ..write('exportFieldKeys: $exportFieldKeys, ')
          ..write('creatorFieldKeys: $creatorFieldKeys, ')
          ..write('creatorCollapsedFieldKeys: $creatorCollapsedFieldKeys, ')
          ..write('tags: $tags, ')
          ..write('enhancements: $enhancements, ')
          ..write('exportMediaTags: $exportMediaTags, ')
          ..write('useBrTags: $useBrTags, ')
          ..write('prependDictionaryNames: $prependDictionaryNames')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryItemsTable extends SearchHistoryItems
    with TableInfo<$SearchHistoryItemsTable, SearchHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _searchTermMeta = const VerificationMeta(
    'searchTerm',
  );
  @override
  late final GeneratedColumn<String> searchTerm = GeneratedColumn<String>(
    'search_term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, searchTerm];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('search_term')) {
      context.handle(
        _searchTermMeta,
        searchTerm.isAcceptableOrUnknown(data['search_term']!, _searchTermMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTermMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      searchTerm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_term'],
      )!,
    );
  }

  @override
  $SearchHistoryItemsTable createAlias(String alias) {
    return $SearchHistoryItemsTable(attachedDatabase, alias);
  }
}

class SearchHistoryRow extends DataClass
    implements Insertable<SearchHistoryRow> {
  /// Assigned on insert; never reused, so it orders by recency.
  final int id;

  /// The term searched.
  final String searchTerm;
  const SearchHistoryRow({required this.id, required this.searchTerm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['search_term'] = Variable<String>(searchTerm);
    return map;
  }

  SearchHistoryItemsCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryItemsCompanion(
      id: Value(id),
      searchTerm: Value(searchTerm),
    );
  }

  factory SearchHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      searchTerm: serializer.fromJson<String>(json['searchTerm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'searchTerm': serializer.toJson<String>(searchTerm),
    };
  }

  SearchHistoryRow copyWith({int? id, String? searchTerm}) => SearchHistoryRow(
    id: id ?? this.id,
    searchTerm: searchTerm ?? this.searchTerm,
  );
  SearchHistoryRow copyWithCompanion(SearchHistoryItemsCompanion data) {
    return SearchHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      searchTerm: data.searchTerm.present
          ? data.searchTerm.value
          : this.searchTerm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryRow(')
          ..write('id: $id, ')
          ..write('searchTerm: $searchTerm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, searchTerm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryRow &&
          other.id == this.id &&
          other.searchTerm == this.searchTerm);
}

class SearchHistoryItemsCompanion extends UpdateCompanion<SearchHistoryRow> {
  final Value<int> id;
  final Value<String> searchTerm;
  const SearchHistoryItemsCompanion({
    this.id = const Value.absent(),
    this.searchTerm = const Value.absent(),
  });
  SearchHistoryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String searchTerm,
  }) : searchTerm = Value(searchTerm);
  static Insertable<SearchHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? searchTerm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (searchTerm != null) 'search_term': searchTerm,
    });
  }

  SearchHistoryItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? searchTerm,
  }) {
    return SearchHistoryItemsCompanion(
      id: id ?? this.id,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (searchTerm.present) {
      map['search_term'] = Variable<String>(searchTerm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('searchTerm: $searchTerm')
          ..write(')'))
        .toString();
  }
}

class $DictionaryHistoryItemsTable extends DictionaryHistoryItems
    with TableInfo<$DictionaryHistoryItemsTable, DictionaryHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryHistoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _searchTermMeta = const VerificationMeta(
    'searchTerm',
  );
  @override
  late final GeneratedColumn<String> searchTerm = GeneratedColumn<String>(
    'search_term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _searchWithWildcardsMeta =
      const VerificationMeta('searchWithWildcards');
  @override
  late final GeneratedColumn<bool> searchWithWildcards = GeneratedColumn<bool>(
    'search_with_wildcards',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("search_with_wildcards" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, searchTerm, searchWithWildcards];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('search_term')) {
      context.handle(
        _searchTermMeta,
        searchTerm.isAcceptableOrUnknown(data['search_term']!, _searchTermMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTermMeta);
    }
    if (data.containsKey('search_with_wildcards')) {
      context.handle(
        _searchWithWildcardsMeta,
        searchWithWildcards.isAcceptableOrUnknown(
          data['search_with_wildcards']!,
          _searchWithWildcardsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictionaryHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      searchTerm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_term'],
      )!,
      searchWithWildcards: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}search_with_wildcards'],
      )!,
    );
  }

  @override
  $DictionaryHistoryItemsTable createAlias(String alias) {
    return $DictionaryHistoryItemsTable(attachedDatabase, alias);
  }
}

class DictionaryHistoryRow extends DataClass
    implements Insertable<DictionaryHistoryRow> {
  /// Assigned on insert; never reused, so it orders by recency.
  final int id;

  /// The term searched.
  final String searchTerm;

  /// Whether the term was searched with wildcards, so that it is searched
  /// again the same way.
  final bool searchWithWildcards;
  const DictionaryHistoryRow({
    required this.id,
    required this.searchTerm,
    required this.searchWithWildcards,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['search_term'] = Variable<String>(searchTerm);
    map['search_with_wildcards'] = Variable<bool>(searchWithWildcards);
    return map;
  }

  DictionaryHistoryItemsCompanion toCompanion(bool nullToAbsent) {
    return DictionaryHistoryItemsCompanion(
      id: Value(id),
      searchTerm: Value(searchTerm),
      searchWithWildcards: Value(searchWithWildcards),
    );
  }

  factory DictionaryHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      searchTerm: serializer.fromJson<String>(json['searchTerm']),
      searchWithWildcards: serializer.fromJson<bool>(
        json['searchWithWildcards'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'searchTerm': serializer.toJson<String>(searchTerm),
      'searchWithWildcards': serializer.toJson<bool>(searchWithWildcards),
    };
  }

  DictionaryHistoryRow copyWith({
    int? id,
    String? searchTerm,
    bool? searchWithWildcards,
  }) => DictionaryHistoryRow(
    id: id ?? this.id,
    searchTerm: searchTerm ?? this.searchTerm,
    searchWithWildcards: searchWithWildcards ?? this.searchWithWildcards,
  );
  DictionaryHistoryRow copyWithCompanion(DictionaryHistoryItemsCompanion data) {
    return DictionaryHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      searchTerm: data.searchTerm.present
          ? data.searchTerm.value
          : this.searchTerm,
      searchWithWildcards: data.searchWithWildcards.present
          ? data.searchWithWildcards.value
          : this.searchWithWildcards,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryHistoryRow(')
          ..write('id: $id, ')
          ..write('searchTerm: $searchTerm, ')
          ..write('searchWithWildcards: $searchWithWildcards')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, searchTerm, searchWithWildcards);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryHistoryRow &&
          other.id == this.id &&
          other.searchTerm == this.searchTerm &&
          other.searchWithWildcards == this.searchWithWildcards);
}

class DictionaryHistoryItemsCompanion
    extends UpdateCompanion<DictionaryHistoryRow> {
  final Value<int> id;
  final Value<String> searchTerm;
  final Value<bool> searchWithWildcards;
  const DictionaryHistoryItemsCompanion({
    this.id = const Value.absent(),
    this.searchTerm = const Value.absent(),
    this.searchWithWildcards = const Value.absent(),
  });
  DictionaryHistoryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String searchTerm,
    this.searchWithWildcards = const Value.absent(),
  }) : searchTerm = Value(searchTerm);
  static Insertable<DictionaryHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? searchTerm,
    Expression<bool>? searchWithWildcards,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (searchTerm != null) 'search_term': searchTerm,
      if (searchWithWildcards != null)
        'search_with_wildcards': searchWithWildcards,
    });
  }

  DictionaryHistoryItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? searchTerm,
    Value<bool>? searchWithWildcards,
  }) {
    return DictionaryHistoryItemsCompanion(
      id: id ?? this.id,
      searchTerm: searchTerm ?? this.searchTerm,
      searchWithWildcards: searchWithWildcards ?? this.searchWithWildcards,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (searchTerm.present) {
      map['search_term'] = Variable<String>(searchTerm.value);
    }
    if (searchWithWildcards.present) {
      map['search_with_wildcards'] = Variable<bool>(searchWithWildcards.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryHistoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('searchTerm: $searchTerm, ')
          ..write('searchWithWildcards: $searchWithWildcards')
          ..write(')'))
        .toString();
  }
}

class $PreferenceEntriesTable extends PreferenceEntries
    with TableInfo<$PreferenceEntriesTable, PreferenceEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferenceEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preference';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenceEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PreferenceEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenceEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferenceEntriesTable createAlias(String alias) {
    return $PreferenceEntriesTable(attachedDatabase, alias);
  }
}

class PreferenceEntry extends DataClass implements Insertable<PreferenceEntry> {
  /// The setting's name. Per-source settings are prefixed with the source's
  /// `uniqueKey` and a `/`.
  final String key;

  /// The setting's value, as JSON.
  final String value;
  const PreferenceEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferenceEntriesCompanion toCompanion(bool nullToAbsent) {
    return PreferenceEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory PreferenceEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenceEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  PreferenceEntry copyWith({String? key, String? value}) =>
      PreferenceEntry(key: key ?? this.key, value: value ?? this.value);
  PreferenceEntry copyWithCompanion(PreferenceEntriesCompanion data) {
    return PreferenceEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferenceEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferenceEntriesCompanion extends UpdateCompanion<PreferenceEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferenceEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferenceEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<PreferenceEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferenceEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferenceEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HeadingsTable headings = $HeadingsTable(this);
  late final $DictionariesTable dictionaries = $DictionariesTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $PitchesTable pitches = $PitchesTable(this);
  late final $FrequenciesTable frequencies = $FrequenciesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $HeadingTagsTable headingTags = $HeadingTagsTable(this);
  late final $EntryTagsTable entryTags = $EntryTagsTable(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $StashItemsTable stashItems = $StashItemsTable(this);
  late final $AnkiMappingsTable ankiMappings = $AnkiMappingsTable(this);
  late final $SearchHistoryItemsTable searchHistoryItems =
      $SearchHistoryItemsTable(this);
  late final $DictionaryHistoryItemsTable dictionaryHistoryItems =
      $DictionaryHistoryItemsTable(this);
  late final $PreferenceEntriesTable preferenceEntries =
      $PreferenceEntriesTable(this);
  late final Index headingReading = Index(
    'heading_reading',
    'CREATE INDEX heading_reading ON heading (reading)',
  );
  late final Index entryHeadingId = Index(
    'entry_heading_id',
    'CREATE INDEX entry_heading_id ON entry (heading_id)',
  );
  late final Index entryDictionaryId = Index(
    'entry_dictionary_id',
    'CREATE INDEX entry_dictionary_id ON entry (dictionary_id)',
  );
  late final Index pitchHeadingId = Index(
    'pitch_heading_id',
    'CREATE INDEX pitch_heading_id ON pitch (heading_id)',
  );
  late final Index pitchDictionaryId = Index(
    'pitch_dictionary_id',
    'CREATE INDEX pitch_dictionary_id ON pitch (dictionary_id)',
  );
  late final Index frequencyHeadingId = Index(
    'frequency_heading_id',
    'CREATE INDEX frequency_heading_id ON frequency (heading_id)',
  );
  late final Index frequencyDictionaryId = Index(
    'frequency_dictionary_id',
    'CREATE INDEX frequency_dictionary_id ON frequency (dictionary_id)',
  );
  late final Index headingTagTagId = Index(
    'heading_tag_tag_id',
    'CREATE INDEX heading_tag_tag_id ON heading_tag (tag_id)',
  );
  late final Index entryTagTagId = Index(
    'entry_tag_tag_id',
    'CREATE INDEX entry_tag_tag_id ON entry_tag (tag_id)',
  );
  Selectable<int> headingCountByTerm({required String term}) {
    return customSelect(
      'SELECT COUNT(*) AS _c0 FROM heading WHERE term = ?1',
      variables: [Variable<String>(term)],
      readsFrom: {this.headings},
    ).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<HeadingRow> headingsByTerms({required List<String> terms}) {
    var $arrayStartIndex = 1;
    final expandedterms = $expandVar($arrayStartIndex, terms.length);
    $arrayStartIndex += terms.length;
    return customSelect(
      'SELECT * FROM heading WHERE term IN ($expandedterms) AND EXISTS (SELECT 1 AS _c0 FROM entry WHERE entry.heading_id = heading.id) ORDER BY id',
      variables: [for (var $ in terms) Variable<String>($)],
      readsFrom: {this.headings, this.entries},
    ).asyncMap(this.headings.mapFromRow);
  }

  Selectable<HeadingRow> headingsByTermsByPopularity({
    required List<String> terms,
  }) {
    var $arrayStartIndex = 1;
    final expandedterms = $expandVar($arrayStartIndex, terms.length);
    $arrayStartIndex += terms.length;
    return customSelect(
      'SELECT * FROM heading WHERE term IN ($expandedterms) AND EXISTS (SELECT 1 AS _c0 FROM entry WHERE entry.heading_id = heading.id) ORDER BY (SELECT SUM(popularity) FROM entry WHERE entry.heading_id = heading.id) DESC, id',
      variables: [for (var $ in terms) Variable<String>($)],
      readsFrom: {this.headings, this.entries},
    ).asyncMap(this.headings.mapFromRow);
  }

  Selectable<HeadingRow> headingsByReadings({
    required List<String> readings,
    required int limit,
  }) {
    var $arrayStartIndex = 2;
    final expandedreadings = $expandVar($arrayStartIndex, readings.length);
    $arrayStartIndex += readings.length;
    return customSelect(
      'SELECT * FROM heading WHERE reading IN ($expandedreadings) AND EXISTS (SELECT 1 AS _c0 FROM entry WHERE entry.heading_id = heading.id) ORDER BY id LIMIT ?1',
      variables: [
        Variable<int>(limit),
        for (var $ in readings) Variable<String>($),
      ],
      readsFrom: {this.headings, this.entries},
    ).asyncMap(this.headings.mapFromRow);
  }

  Selectable<HeadingRow> headingsByTermPrefix({
    required String prefix,
    required String prefixEnd,
    required int limit,
  }) {
    return customSelect(
      'SELECT * FROM heading WHERE term >= ?1 AND term < ?2 AND EXISTS (SELECT 1 AS _c0 FROM entry WHERE entry.heading_id = heading.id) ORDER BY length(term), id LIMIT ?3',
      variables: [
        Variable<String>(prefix),
        Variable<String>(prefixEnd),
        Variable<int>(limit),
      ],
      readsFrom: {this.headings, this.entries},
    ).asyncMap(this.headings.mapFromRow);
  }

  Selectable<HeadingRow> headingsByTermGlob({
    required String pattern,
    required int minimumLength,
    required int maximumLength,
    required int limit,
  }) {
    return customSelect(
      'SELECT * FROM heading WHERE term GLOB ?1 AND length(term) BETWEEN ?2 AND ?3 AND EXISTS (SELECT 1 AS _c0 FROM entry WHERE entry.heading_id = heading.id) ORDER BY id LIMIT ?4',
      variables: [
        Variable<String>(pattern),
        Variable<int>(minimumLength),
        Variable<int>(maximumLength),
        Variable<int>(limit),
      ],
      readsFrom: {this.headings, this.entries},
    ).asyncMap(this.headings.mapFromRow);
  }

  Selectable<HeadingRow> headingsByReadingGlob({
    required String pattern,
    required String alternativePattern,
    required int limit,
  }) {
    return customSelect(
      'SELECT * FROM heading WHERE(reading GLOB ?1 OR reading GLOB ?2)AND EXISTS (SELECT 1 AS _c0 FROM entry WHERE entry.heading_id = heading.id) ORDER BY id LIMIT ?3',
      variables: [
        Variable<String>(pattern),
        Variable<String>(alternativePattern),
        Variable<int>(limit),
      ],
      readsFrom: {this.headings, this.entries},
    ).asyncMap(this.headings.mapFromRow);
  }

  Selectable<HeadingRow> headingWithEntries({
    required String term,
    required String reading,
  }) {
    return customSelect(
      'SELECT * FROM heading WHERE term = ?1 AND reading = ?2 AND EXISTS (SELECT 1 AS _c0 FROM entry WHERE entry.heading_id = heading.id)',
      variables: [Variable<String>(term), Variable<String>(reading)],
      readsFrom: {this.headings, this.entries},
    ).asyncMap(this.headings.mapFromRow);
  }

  Selectable<HeadingRow> headingByTermAndReading({
    required String term,
    required String reading,
  }) {
    return customSelect(
      'SELECT * FROM heading WHERE term = ?1 AND reading = ?2',
      variables: [Variable<String>(term), Variable<String>(reading)],
      readsFrom: {this.headings},
    ).asyncMap(this.headings.mapFromRow);
  }

  Selectable<HeadingRow> headingsByIds({required List<int> ids}) {
    var $arrayStartIndex = 1;
    final expandedids = $expandVar($arrayStartIndex, ids.length);
    $arrayStartIndex += ids.length;
    return customSelect(
      'SELECT * FROM heading WHERE id IN ($expandedids)',
      variables: [for (var $ in ids) Variable<int>($)],
      readsFrom: {this.headings},
    ).asyncMap(this.headings.mapFromRow);
  }

  Selectable<EntryRow> entriesByHeadings({required List<int> ids}) {
    var $arrayStartIndex = 1;
    final expandedids = $expandVar($arrayStartIndex, ids.length);
    $arrayStartIndex += ids.length;
    return customSelect(
      'SELECT * FROM entry WHERE heading_id IN ($expandedids) ORDER BY id',
      variables: [for (var $ in ids) Variable<int>($)],
      readsFrom: {this.entries},
    ).asyncMap(this.entries.mapFromRow);
  }

  Selectable<PitchRow> pitchesByHeadings({required List<int> ids}) {
    var $arrayStartIndex = 1;
    final expandedids = $expandVar($arrayStartIndex, ids.length);
    $arrayStartIndex += ids.length;
    return customSelect(
      'SELECT * FROM pitch WHERE heading_id IN ($expandedids) ORDER BY id',
      variables: [for (var $ in ids) Variable<int>($)],
      readsFrom: {this.pitches},
    ).asyncMap(this.pitches.mapFromRow);
  }

  Selectable<FrequencyRow> frequenciesByHeadings({required List<int> ids}) {
    var $arrayStartIndex = 1;
    final expandedids = $expandVar($arrayStartIndex, ids.length);
    $arrayStartIndex += ids.length;
    return customSelect(
      'SELECT * FROM frequency WHERE heading_id IN ($expandedids) ORDER BY id',
      variables: [for (var $ in ids) Variable<int>($)],
      readsFrom: {this.frequencies},
    ).asyncMap(this.frequencies.mapFromRow);
  }

  Selectable<HeadingTagsByHeadingsResult> headingTagsByHeadings({
    required List<int> ids,
  }) {
    var $arrayStartIndex = 1;
    final expandedids = $expandVar($arrayStartIndex, ids.length);
    $arrayStartIndex += ids.length;
    return customSelect(
      'SELECT heading_tag.heading_id AS owner_id,"tag"."id" AS "nested_0.id", "tag"."dictionary_id" AS "nested_0.dictionary_id", "tag"."name" AS "nested_0.name", "tag"."category" AS "nested_0.category", "tag"."sorting_order" AS "nested_0.sorting_order", "tag"."notes" AS "nested_0.notes", "tag"."popularity" AS "nested_0.popularity" FROM heading_tag INNER JOIN tag ON tag.id = heading_tag.tag_id WHERE heading_tag.heading_id IN ($expandedids) ORDER BY tag.id',
      variables: [for (var $ in ids) Variable<int>($)],
      readsFrom: {this.headingTags, this.tags},
    ).asyncMap(
      (QueryRow row) async => HeadingTagsByHeadingsResult(
        ownerId: row.read<int>('owner_id'),
        tag: await this.tags.mapFromRow(row, tablePrefix: 'nested_0'),
      ),
    );
  }

  Selectable<EntryTagsByEntriesResult> entryTagsByEntries({
    required List<int> ids,
  }) {
    var $arrayStartIndex = 1;
    final expandedids = $expandVar($arrayStartIndex, ids.length);
    $arrayStartIndex += ids.length;
    return customSelect(
      'SELECT entry_tag.entry_id AS owner_id,"tag"."id" AS "nested_0.id", "tag"."dictionary_id" AS "nested_0.dictionary_id", "tag"."name" AS "nested_0.name", "tag"."category" AS "nested_0.category", "tag"."sorting_order" AS "nested_0.sorting_order", "tag"."notes" AS "nested_0.notes", "tag"."popularity" AS "nested_0.popularity" FROM entry_tag INNER JOIN tag ON tag.id = entry_tag.tag_id WHERE entry_tag.entry_id IN ($expandedids) ORDER BY tag.id',
      variables: [for (var $ in ids) Variable<int>($)],
      readsFrom: {this.entryTags, this.tags},
    ).asyncMap(
      (QueryRow row) async => EntryTagsByEntriesResult(
        ownerId: row.read<int>('owner_id'),
        tag: await this.tags.mapFromRow(row, tablePrefix: 'nested_0'),
      ),
    );
  }

  Selectable<NoReadingFrequenciesResult> noReadingFrequencies({
    required List<String> terms,
  }) {
    var $arrayStartIndex = 1;
    final expandedterms = $expandVar($arrayStartIndex, terms.length);
    $arrayStartIndex += terms.length;
    return customSelect(
      'SELECT heading.term AS term,"frequency"."id" AS "nested_0.id", "frequency"."heading_id" AS "nested_0.heading_id", "frequency"."dictionary_id" AS "nested_0.dictionary_id", "frequency"."value" AS "nested_0.value", "frequency"."display_value" AS "nested_0.display_value" FROM frequency INNER JOIN heading ON heading.id = frequency.heading_id WHERE heading.reading = \'\' AND heading.term IN ($expandedterms) ORDER BY frequency.id',
      variables: [for (var $ in terms) Variable<String>($)],
      readsFrom: {this.headings, this.frequencies},
    ).asyncMap(
      (QueryRow row) async => NoReadingFrequenciesResult(
        term: row.read<String>('term'),
        frequency: await this.frequencies.mapFromRow(
          row,
          tablePrefix: 'nested_0',
        ),
      ),
    );
  }

  Selectable<Dictionary> allDictionaries() {
    return customSelect(
      'SELECT * FROM dictionary ORDER BY "order"',
      variables: [],
      readsFrom: {this.dictionaries},
    ).asyncMap(this.dictionaries.mapFromRow);
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    headings,
    dictionaries,
    entries,
    pitches,
    frequencies,
    tags,
    headingTags,
    entryTags,
    mediaItems,
    stashItems,
    ankiMappings,
    searchHistoryItems,
    dictionaryHistoryItems,
    preferenceEntries,
    headingReading,
    entryHeadingId,
    entryDictionaryId,
    pitchHeadingId,
    pitchDictionaryId,
    frequencyHeadingId,
    frequencyDictionaryId,
    headingTagTagId,
    entryTagTagId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dictionary',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dictionary',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pitch', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dictionary',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('frequency', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dictionary',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tag', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'heading',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('heading_tag', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tag',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('heading_tag', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entry',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry_tag', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tag',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry_tag', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_item',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stash_item', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HeadingsTableCreateCompanionBuilder = HeadingsCompanion Function({
  Value<int> id,
  required String term,
  required String reading,
});
typedef $$HeadingsTableUpdateCompanionBuilder = HeadingsCompanion Function({
  Value<int> id,
  Value<String> term,
  Value<String> reading,
});

final class $$HeadingsTableReferences
    extends BaseReferences<_$AppDatabase, $HeadingsTable, HeadingRow> {
  $$HeadingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntriesTable, List<EntryRow>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'heading__id__entry__heading_id',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.headingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PitchesTable, List<PitchRow>> _pitchesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.pitches,
    aliasName: 'heading__id__pitch__heading_id',
  );

  $$PitchesTableProcessedTableManager get pitchesRefs {
    final manager = $$PitchesTableTableManager(
      $_db,
      $_db.pitches,
    ).filter((f) => f.headingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pitchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FrequenciesTable, List<FrequencyRow>>
  _frequenciesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.frequencies,
    aliasName: 'heading__id__frequency__heading_id',
  );

  $$FrequenciesTableProcessedTableManager get frequenciesRefs {
    final manager = $$FrequenciesTableTableManager(
      $_db,
      $_db.frequencies,
    ).filter((f) => f.headingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_frequenciesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HeadingTagsTable, List<HeadingTagRow>>
  _headingTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.headingTags,
    aliasName: 'heading__id__heading_tag__heading_id',
  );

  $$HeadingTagsTableProcessedTableManager get headingTagsRefs {
    final manager = $$HeadingTagsTableTableManager(
      $_db,
      $_db.headingTags,
    ).filter((f) => f.headingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_headingTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HeadingsTableFilterComposer
    extends Composer<_$AppDatabase, $HeadingsTable> {
  $$HeadingsTableFilterComposer({
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

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.headingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pitchesRefs(
    Expression<bool> Function($$PitchesTableFilterComposer f) f,
  ) {
    final $$PitchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pitches,
      getReferencedColumn: (t) => t.headingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PitchesTableFilterComposer(
            $db: $db,
            $table: $db.pitches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> frequenciesRefs(
    Expression<bool> Function($$FrequenciesTableFilterComposer f) f,
  ) {
    final $$FrequenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frequencies,
      getReferencedColumn: (t) => t.headingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequenciesTableFilterComposer(
            $db: $db,
            $table: $db.frequencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> headingTagsRefs(
    Expression<bool> Function($$HeadingTagsTableFilterComposer f) f,
  ) {
    final $$HeadingTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.headingTags,
      getReferencedColumn: (t) => t.headingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingTagsTableFilterComposer(
            $db: $db,
            $table: $db.headingTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HeadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $HeadingsTable> {
  $$HeadingsTableOrderingComposer({
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

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HeadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeadingsTable> {
  $$HeadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.headingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pitchesRefs<T extends Object>(
    Expression<T> Function($$PitchesTableAnnotationComposer a) f,
  ) {
    final $$PitchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pitches,
      getReferencedColumn: (t) => t.headingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PitchesTableAnnotationComposer(
            $db: $db,
            $table: $db.pitches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> frequenciesRefs<T extends Object>(
    Expression<T> Function($$FrequenciesTableAnnotationComposer a) f,
  ) {
    final $$FrequenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frequencies,
      getReferencedColumn: (t) => t.headingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.frequencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> headingTagsRefs<T extends Object>(
    Expression<T> Function($$HeadingTagsTableAnnotationComposer a) f,
  ) {
    final $$HeadingTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.headingTags,
      getReferencedColumn: (t) => t.headingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.headingTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HeadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeadingsTable,
          HeadingRow,
          $$HeadingsTableFilterComposer,
          $$HeadingsTableOrderingComposer,
          $$HeadingsTableAnnotationComposer,
          $$HeadingsTableCreateCompanionBuilder,
          $$HeadingsTableUpdateCompanionBuilder,
          (HeadingRow, $$HeadingsTableReferences),
          HeadingRow,
          PrefetchHooks Function({
            bool entriesRefs,
            bool pitchesRefs,
            bool frequenciesRefs,
            bool headingTagsRefs,
          })
        > {
  $$HeadingsTableTableManager(_$AppDatabase db, $HeadingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> term = const Value.absent(),
            Value<String> reading = const Value.absent(),
          }) => HeadingsCompanion(id: id, term: term, reading: reading),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String term,
            required String reading,
          }) => HeadingsCompanion.insert(id: id, term: term, reading: reading),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HeadingsTable, HeadingRow>(table),
                  $$HeadingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                entriesRefs = false,
                pitchesRefs = false,
                frequenciesRefs = false,
                headingTagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entriesRefs) db.entries,
                    if (pitchesRefs) db.pitches,
                    if (frequenciesRefs) db.frequencies,
                    if (headingTagsRefs) db.headingTags,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entriesRefs)
                        await $_getPrefetchedDataByColumns<
                          HeadingRow,
                          $HeadingsTable,
                          EntryRow,
                          $EntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$HeadingsTableReferences
                              ._entriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HeadingsTableReferences(
                                db,
                                table,
                                p0,
                              ).entriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'heading_id',
                          typedResults: items,
                        ),
                      if (pitchesRefs)
                        await $_getPrefetchedDataByColumns<
                          HeadingRow,
                          $HeadingsTable,
                          PitchRow,
                          $PitchesTable
                        >(
                          currentTable: table,
                          referencedTable: $$HeadingsTableReferences
                              ._pitchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HeadingsTableReferences(
                                db,
                                table,
                                p0,
                              ).pitchesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'heading_id',
                          typedResults: items,
                        ),
                      if (frequenciesRefs)
                        await $_getPrefetchedDataByColumns<
                          HeadingRow,
                          $HeadingsTable,
                          FrequencyRow,
                          $FrequenciesTable
                        >(
                          currentTable: table,
                          referencedTable: $$HeadingsTableReferences
                              ._frequenciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HeadingsTableReferences(
                                db,
                                table,
                                p0,
                              ).frequenciesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'heading_id',
                          typedResults: items,
                        ),
                      if (headingTagsRefs)
                        await $_getPrefetchedDataByColumns<
                          HeadingRow,
                          $HeadingsTable,
                          HeadingTagRow,
                          $HeadingTagsTable
                        >(
                          currentTable: table,
                          referencedTable: $$HeadingsTableReferences
                              ._headingTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HeadingsTableReferences(
                                db,
                                table,
                                p0,
                              ).headingTagsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'heading_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HeadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeadingsTable,
      HeadingRow,
      $$HeadingsTableFilterComposer,
      $$HeadingsTableOrderingComposer,
      $$HeadingsTableAnnotationComposer,
      $$HeadingsTableCreateCompanionBuilder,
      $$HeadingsTableUpdateCompanionBuilder,
      (HeadingRow, $$HeadingsTableReferences),
      HeadingRow,
      PrefetchHooks Function({
        bool entriesRefs,
        bool pitchesRefs,
        bool frequenciesRefs,
        bool headingTagsRefs,
      })
    >;
typedef $$DictionariesTableCreateCompanionBuilder =
    DictionariesCompanion Function({
      Value<int> id,
      required String name,
      required String formatKey,
      required int order,
      Value<bool> isHidden,
      Value<bool> isCollapsed,
    });
typedef $$DictionariesTableUpdateCompanionBuilder =
    DictionariesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> formatKey,
      Value<int> order,
      Value<bool> isHidden,
      Value<bool> isCollapsed,
    });

final class $$DictionariesTableReferences
    extends BaseReferences<_$AppDatabase, $DictionariesTable, Dictionary> {
  $$DictionariesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntriesTable, List<EntryRow>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'dictionary__id__entry__dictionary_id',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.dictionaryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PitchesTable, List<PitchRow>> _pitchesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.pitches,
    aliasName: 'dictionary__id__pitch__dictionary_id',
  );

  $$PitchesTableProcessedTableManager get pitchesRefs {
    final manager = $$PitchesTableTableManager(
      $_db,
      $_db.pitches,
    ).filter((f) => f.dictionaryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pitchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FrequenciesTable, List<FrequencyRow>>
  _frequenciesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.frequencies,
    aliasName: 'dictionary__id__frequency__dictionary_id',
  );

  $$FrequenciesTableProcessedTableManager get frequenciesRefs {
    final manager = $$FrequenciesTableTableManager(
      $_db,
      $_db.frequencies,
    ).filter((f) => f.dictionaryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_frequenciesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TagsTable, List<TagRow>> _tagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tags,
    aliasName: 'dictionary__id__tag__dictionary_id',
  );

  $$TagsTableProcessedTableManager get tagsRefs {
    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.dictionaryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DictionariesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionariesTable> {
  $$DictionariesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formatKey => $composableBuilder(
    column: $table.formatKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCollapsed => $composableBuilder(
    column: $table.isCollapsed,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pitchesRefs(
    Expression<bool> Function($$PitchesTableFilterComposer f) f,
  ) {
    final $$PitchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pitches,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PitchesTableFilterComposer(
            $db: $db,
            $table: $db.pitches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> frequenciesRefs(
    Expression<bool> Function($$FrequenciesTableFilterComposer f) f,
  ) {
    final $$FrequenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frequencies,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequenciesTableFilterComposer(
            $db: $db,
            $table: $db.frequencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tagsRefs(
    Expression<bool> Function($$TagsTableFilterComposer f) f,
  ) {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DictionariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionariesTable> {
  $$DictionariesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formatKey => $composableBuilder(
    column: $table.formatKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCollapsed => $composableBuilder(
    column: $table.isCollapsed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionariesTable> {
  $$DictionariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get formatKey =>
      $composableBuilder(column: $table.formatKey, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<bool> get isCollapsed => $composableBuilder(
    column: $table.isCollapsed,
    builder: (column) => column,
  );

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pitchesRefs<T extends Object>(
    Expression<T> Function($$PitchesTableAnnotationComposer a) f,
  ) {
    final $$PitchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pitches,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PitchesTableAnnotationComposer(
            $db: $db,
            $table: $db.pitches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> frequenciesRefs<T extends Object>(
    Expression<T> Function($$FrequenciesTableAnnotationComposer a) f,
  ) {
    final $$FrequenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.frequencies,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FrequenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.frequencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tagsRefs<T extends Object>(
    Expression<T> Function($$TagsTableAnnotationComposer a) f,
  ) {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DictionariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionariesTable,
          Dictionary,
          $$DictionariesTableFilterComposer,
          $$DictionariesTableOrderingComposer,
          $$DictionariesTableAnnotationComposer,
          $$DictionariesTableCreateCompanionBuilder,
          $$DictionariesTableUpdateCompanionBuilder,
          (Dictionary, $$DictionariesTableReferences),
          Dictionary,
          PrefetchHooks Function({
            bool entriesRefs,
            bool pitchesRefs,
            bool frequenciesRefs,
            bool tagsRefs,
          })
        > {
  $$DictionariesTableTableManager(_$AppDatabase db, $DictionariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> formatKey = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isCollapsed = const Value.absent(),
              }) => DictionariesCompanion(
                id: id,
                name: name,
                formatKey: formatKey,
                order: order,
                isHidden: isHidden,
                isCollapsed: isCollapsed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String formatKey,
                required int order,
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isCollapsed = const Value.absent(),
              }) => DictionariesCompanion.insert(
                id: id,
                name: name,
                formatKey: formatKey,
                order: order,
                isHidden: isHidden,
                isCollapsed: isCollapsed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DictionariesTable, Dictionary>(table),
                  $$DictionariesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                entriesRefs = false,
                pitchesRefs = false,
                frequenciesRefs = false,
                tagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entriesRefs) db.entries,
                    if (pitchesRefs) db.pitches,
                    if (frequenciesRefs) db.frequencies,
                    if (tagsRefs) db.tags,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entriesRefs)
                        await $_getPrefetchedDataByColumns<
                          Dictionary,
                          $DictionariesTable,
                          EntryRow,
                          $EntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$DictionariesTableReferences
                              ._entriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DictionariesTableReferences(
                                db,
                                table,
                                p0,
                              ).entriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'dictionary_id',
                          typedResults: items,
                        ),
                      if (pitchesRefs)
                        await $_getPrefetchedDataByColumns<
                          Dictionary,
                          $DictionariesTable,
                          PitchRow,
                          $PitchesTable
                        >(
                          currentTable: table,
                          referencedTable: $$DictionariesTableReferences
                              ._pitchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DictionariesTableReferences(
                                db,
                                table,
                                p0,
                              ).pitchesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'dictionary_id',
                          typedResults: items,
                        ),
                      if (frequenciesRefs)
                        await $_getPrefetchedDataByColumns<
                          Dictionary,
                          $DictionariesTable,
                          FrequencyRow,
                          $FrequenciesTable
                        >(
                          currentTable: table,
                          referencedTable: $$DictionariesTableReferences
                              ._frequenciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DictionariesTableReferences(
                                db,
                                table,
                                p0,
                              ).frequenciesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'dictionary_id',
                          typedResults: items,
                        ),
                      if (tagsRefs)
                        await $_getPrefetchedDataByColumns<
                          Dictionary,
                          $DictionariesTable,
                          TagRow,
                          $TagsTable
                        >(
                          currentTable: table,
                          referencedTable: $$DictionariesTableReferences
                              ._tagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DictionariesTableReferences(
                                db,
                                table,
                                p0,
                              ).tagsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'dictionary_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DictionariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionariesTable,
      Dictionary,
      $$DictionariesTableFilterComposer,
      $$DictionariesTableOrderingComposer,
      $$DictionariesTableAnnotationComposer,
      $$DictionariesTableCreateCompanionBuilder,
      $$DictionariesTableUpdateCompanionBuilder,
      (Dictionary, $$DictionariesTableReferences),
      Dictionary,
      PrefetchHooks Function({
        bool entriesRefs,
        bool pitchesRefs,
        bool frequenciesRefs,
        bool tagsRefs,
      })
    >;
typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  required int headingId,
  required int dictionaryId,
  required List<String> definitions,
  required double popularity,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  Value<int> headingId,
  Value<int> dictionaryId,
  Value<List<String>> definitions,
  Value<double> popularity,
});

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, EntryRow> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HeadingsTable _headingIdTable(_$AppDatabase db) =>
      db.headings.createAlias('entry__heading_id__heading__id');

  $$HeadingsTableProcessedTableManager get headingId {
    final $_column = $_itemColumn<int>('heading_id')!;

    final manager = $$HeadingsTableTableManager(
      $_db,
      $_db.headings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_headingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DictionariesTable _dictionaryIdTable(_$AppDatabase db) =>
      db.dictionaries.createAlias('entry__dictionary_id__dictionary__id');

  $$DictionariesTableProcessedTableManager get dictionaryId {
    final $_column = $_itemColumn<int>('dictionary_id')!;

    final manager = $$DictionariesTableTableManager(
      $_db,
      $_db.dictionaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dictionaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EntryTagsTable, List<EntryTagRow>>
  _entryTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entryTags,
    aliasName: 'entry__id__entry_tag__entry_id',
  );

  $$EntryTagsTableProcessedTableManager get entryTagsRefs {
    final manager = $$EntryTagsTableTableManager(
      $_db,
      $_db.entryTags,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entryTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnFilters(column),
  );

  $$HeadingsTableFilterComposer get headingId {
    final $$HeadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableFilterComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DictionariesTableFilterComposer get dictionaryId {
    final $$DictionariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableFilterComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> entryTagsRefs(
    Expression<bool> Function($$EntryTagsTableFilterComposer f) f,
  ) {
    final $$EntryTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryTags,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryTagsTableFilterComposer(
            $db: $db,
            $table: $db.entryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
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

  ColumnOrderings<String> get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnOrderings(column),
  );

  $$HeadingsTableOrderingComposer get headingId {
    final $$HeadingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableOrderingComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DictionariesTableOrderingComposer get dictionaryId {
    final $$DictionariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableOrderingComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get definitions =>
      $composableBuilder(
        column: $table.definitions,
        builder: (column) => column,
      );

  GeneratedColumn<double> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => column,
  );

  $$HeadingsTableAnnotationComposer get headingId {
    final $$HeadingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableAnnotationComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DictionariesTableAnnotationComposer get dictionaryId {
    final $$DictionariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableAnnotationComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> entryTagsRefs<T extends Object>(
    Expression<T> Function($$EntryTagsTableAnnotationComposer a) f,
  ) {
    final $$EntryTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryTags,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.entryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          EntryRow,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (EntryRow, $$EntriesTableReferences),
          EntryRow,
          PrefetchHooks Function({
            bool headingId,
            bool dictionaryId,
            bool entryTagsRefs,
          })
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> headingId = const Value.absent(),
                Value<int> dictionaryId = const Value.absent(),
                Value<List<String>> definitions = const Value.absent(),
                Value<double> popularity = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                headingId: headingId,
                dictionaryId: dictionaryId,
                definitions: definitions,
                popularity: popularity,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int headingId,
                required int dictionaryId,
                required List<String> definitions,
                required double popularity,
              }) => EntriesCompanion.insert(
                id: id,
                headingId: headingId,
                dictionaryId: dictionaryId,
                definitions: definitions,
                popularity: popularity,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntriesTable, EntryRow>(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                headingId = false,
                dictionaryId = false,
                entryTagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (entryTagsRefs) db.entryTags],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (headingId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.headingId,
                            referencedTable: $$EntriesTableReferences
                                ._headingIdTable(db),
                            referencedColumn: $$EntriesTableReferences
                                ._headingIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (dictionaryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.dictionaryId,
                            referencedTable: $$EntriesTableReferences
                                ._dictionaryIdTable(db),
                            referencedColumn: $$EntriesTableReferences
                                ._dictionaryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entryTagsRefs)
                        await $_getPrefetchedDataByColumns<
                          EntryRow,
                          $EntriesTable,
                          EntryTagRow,
                          $EntryTagsTable
                        >(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences
                              ._entryTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).entryTagsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'entry_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      EntryRow,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (EntryRow, $$EntriesTableReferences),
      EntryRow,
      PrefetchHooks Function({
        bool headingId,
        bool dictionaryId,
        bool entryTagsRefs,
      })
    >;
typedef $$PitchesTableCreateCompanionBuilder = PitchesCompanion Function({
  Value<int> id,
  required int headingId,
  required int dictionaryId,
  required int downstep,
});
typedef $$PitchesTableUpdateCompanionBuilder = PitchesCompanion Function({
  Value<int> id,
  Value<int> headingId,
  Value<int> dictionaryId,
  Value<int> downstep,
});

final class $$PitchesTableReferences
    extends BaseReferences<_$AppDatabase, $PitchesTable, PitchRow> {
  $$PitchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HeadingsTable _headingIdTable(_$AppDatabase db) =>
      db.headings.createAlias('pitch__heading_id__heading__id');

  $$HeadingsTableProcessedTableManager get headingId {
    final $_column = $_itemColumn<int>('heading_id')!;

    final manager = $$HeadingsTableTableManager(
      $_db,
      $_db.headings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_headingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DictionariesTable _dictionaryIdTable(_$AppDatabase db) =>
      db.dictionaries.createAlias('pitch__dictionary_id__dictionary__id');

  $$DictionariesTableProcessedTableManager get dictionaryId {
    final $_column = $_itemColumn<int>('dictionary_id')!;

    final manager = $$DictionariesTableTableManager(
      $_db,
      $_db.dictionaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dictionaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PitchesTableFilterComposer
    extends Composer<_$AppDatabase, $PitchesTable> {
  $$PitchesTableFilterComposer({
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

  ColumnFilters<int> get downstep => $composableBuilder(
    column: $table.downstep,
    builder: (column) => ColumnFilters(column),
  );

  $$HeadingsTableFilterComposer get headingId {
    final $$HeadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableFilterComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DictionariesTableFilterComposer get dictionaryId {
    final $$DictionariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableFilterComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PitchesTableOrderingComposer
    extends Composer<_$AppDatabase, $PitchesTable> {
  $$PitchesTableOrderingComposer({
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

  ColumnOrderings<int> get downstep => $composableBuilder(
    column: $table.downstep,
    builder: (column) => ColumnOrderings(column),
  );

  $$HeadingsTableOrderingComposer get headingId {
    final $$HeadingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableOrderingComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DictionariesTableOrderingComposer get dictionaryId {
    final $$DictionariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableOrderingComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PitchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PitchesTable> {
  $$PitchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get downstep =>
      $composableBuilder(column: $table.downstep, builder: (column) => column);

  $$HeadingsTableAnnotationComposer get headingId {
    final $$HeadingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableAnnotationComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DictionariesTableAnnotationComposer get dictionaryId {
    final $$DictionariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableAnnotationComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PitchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PitchesTable,
          PitchRow,
          $$PitchesTableFilterComposer,
          $$PitchesTableOrderingComposer,
          $$PitchesTableAnnotationComposer,
          $$PitchesTableCreateCompanionBuilder,
          $$PitchesTableUpdateCompanionBuilder,
          (PitchRow, $$PitchesTableReferences),
          PitchRow,
          PrefetchHooks Function({bool headingId, bool dictionaryId})
        > {
  $$PitchesTableTableManager(_$AppDatabase db, $PitchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PitchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PitchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PitchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> headingId = const Value.absent(),
                Value<int> dictionaryId = const Value.absent(),
                Value<int> downstep = const Value.absent(),
              }) => PitchesCompanion(
                id: id,
                headingId: headingId,
                dictionaryId: dictionaryId,
                downstep: downstep,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int headingId,
                required int dictionaryId,
                required int downstep,
              }) => PitchesCompanion.insert(
                id: id,
                headingId: headingId,
                dictionaryId: dictionaryId,
                downstep: downstep,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PitchesTable, PitchRow>(table),
                  $$PitchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({headingId = false, dictionaryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (headingId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.headingId,
                        referencedTable: $$PitchesTableReferences
                            ._headingIdTable(db),
                        referencedColumn: $$PitchesTableReferences
                            ._headingIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (dictionaryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.dictionaryId,
                        referencedTable: $$PitchesTableReferences
                            ._dictionaryIdTable(db),
                        referencedColumn: $$PitchesTableReferences
                            ._dictionaryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PitchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PitchesTable,
      PitchRow,
      $$PitchesTableFilterComposer,
      $$PitchesTableOrderingComposer,
      $$PitchesTableAnnotationComposer,
      $$PitchesTableCreateCompanionBuilder,
      $$PitchesTableUpdateCompanionBuilder,
      (PitchRow, $$PitchesTableReferences),
      PitchRow,
      PrefetchHooks Function({bool headingId, bool dictionaryId})
    >;
typedef $$FrequenciesTableCreateCompanionBuilder =
    FrequenciesCompanion Function({
      Value<int> id,
      required int headingId,
      required int dictionaryId,
      required double value,
      required String displayValue,
    });
typedef $$FrequenciesTableUpdateCompanionBuilder =
    FrequenciesCompanion Function({
      Value<int> id,
      Value<int> headingId,
      Value<int> dictionaryId,
      Value<double> value,
      Value<String> displayValue,
    });

final class $$FrequenciesTableReferences
    extends BaseReferences<_$AppDatabase, $FrequenciesTable, FrequencyRow> {
  $$FrequenciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HeadingsTable _headingIdTable(_$AppDatabase db) =>
      db.headings.createAlias('frequency__heading_id__heading__id');

  $$HeadingsTableProcessedTableManager get headingId {
    final $_column = $_itemColumn<int>('heading_id')!;

    final manager = $$HeadingsTableTableManager(
      $_db,
      $_db.headings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_headingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DictionariesTable _dictionaryIdTable(_$AppDatabase db) =>
      db.dictionaries.createAlias('frequency__dictionary_id__dictionary__id');

  $$DictionariesTableProcessedTableManager get dictionaryId {
    final $_column = $_itemColumn<int>('dictionary_id')!;

    final manager = $$DictionariesTableTableManager(
      $_db,
      $_db.dictionaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dictionaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FrequenciesTableFilterComposer
    extends Composer<_$AppDatabase, $FrequenciesTable> {
  $$FrequenciesTableFilterComposer({
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

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => ColumnFilters(column),
  );

  $$HeadingsTableFilterComposer get headingId {
    final $$HeadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableFilterComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DictionariesTableFilterComposer get dictionaryId {
    final $$DictionariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableFilterComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrequenciesTableOrderingComposer
    extends Composer<_$AppDatabase, $FrequenciesTable> {
  $$FrequenciesTableOrderingComposer({
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

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => ColumnOrderings(column),
  );

  $$HeadingsTableOrderingComposer get headingId {
    final $$HeadingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableOrderingComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DictionariesTableOrderingComposer get dictionaryId {
    final $$DictionariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableOrderingComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrequenciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FrequenciesTable> {
  $$FrequenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => column,
  );

  $$HeadingsTableAnnotationComposer get headingId {
    final $$HeadingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableAnnotationComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DictionariesTableAnnotationComposer get dictionaryId {
    final $$DictionariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableAnnotationComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FrequenciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FrequenciesTable,
          FrequencyRow,
          $$FrequenciesTableFilterComposer,
          $$FrequenciesTableOrderingComposer,
          $$FrequenciesTableAnnotationComposer,
          $$FrequenciesTableCreateCompanionBuilder,
          $$FrequenciesTableUpdateCompanionBuilder,
          (FrequencyRow, $$FrequenciesTableReferences),
          FrequencyRow,
          PrefetchHooks Function({bool headingId, bool dictionaryId})
        > {
  $$FrequenciesTableTableManager(_$AppDatabase db, $FrequenciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrequenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrequenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrequenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> headingId = const Value.absent(),
                Value<int> dictionaryId = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> displayValue = const Value.absent(),
              }) => FrequenciesCompanion(
                id: id,
                headingId: headingId,
                dictionaryId: dictionaryId,
                value: value,
                displayValue: displayValue,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int headingId,
                required int dictionaryId,
                required double value,
                required String displayValue,
              }) => FrequenciesCompanion.insert(
                id: id,
                headingId: headingId,
                dictionaryId: dictionaryId,
                value: value,
                displayValue: displayValue,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FrequenciesTable, FrequencyRow>(table),
                  $$FrequenciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({headingId = false, dictionaryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (headingId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.headingId,
                        referencedTable: $$FrequenciesTableReferences
                            ._headingIdTable(db),
                        referencedColumn: $$FrequenciesTableReferences
                            ._headingIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (dictionaryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.dictionaryId,
                        referencedTable: $$FrequenciesTableReferences
                            ._dictionaryIdTable(db),
                        referencedColumn: $$FrequenciesTableReferences
                            ._dictionaryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FrequenciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FrequenciesTable,
      FrequencyRow,
      $$FrequenciesTableFilterComposer,
      $$FrequenciesTableOrderingComposer,
      $$FrequenciesTableAnnotationComposer,
      $$FrequenciesTableCreateCompanionBuilder,
      $$FrequenciesTableUpdateCompanionBuilder,
      (FrequencyRow, $$FrequenciesTableReferences),
      FrequencyRow,
      PrefetchHooks Function({bool headingId, bool dictionaryId})
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  required int dictionaryId,
  required String name,
  required String category,
  required int sortingOrder,
  required String notes,
  required double popularity,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<int> dictionaryId,
  Value<String> name,
  Value<String> category,
  Value<int> sortingOrder,
  Value<String> notes,
  Value<double> popularity,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DictionariesTable _dictionaryIdTable(_$AppDatabase db) =>
      db.dictionaries.createAlias('tag__dictionary_id__dictionary__id');

  $$DictionariesTableProcessedTableManager get dictionaryId {
    final $_column = $_itemColumn<int>('dictionary_id')!;

    final manager = $$DictionariesTableTableManager(
      $_db,
      $_db.dictionaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dictionaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$HeadingTagsTable, List<HeadingTagRow>>
  _headingTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.headingTags,
    aliasName: 'tag__id__heading_tag__tag_id',
  );

  $$HeadingTagsTableProcessedTableManager get headingTagsRefs {
    final manager = $$HeadingTagsTableTableManager(
      $_db,
      $_db.headingTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_headingTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntryTagsTable, List<EntryTagRow>>
  _entryTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entryTags,
    aliasName: 'tag__id__entry_tag__tag_id',
  );

  $$EntryTagsTableProcessedTableManager get entryTagsRefs {
    final manager = $$EntryTagsTableTableManager(
      $_db,
      $_db.entryTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entryTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortingOrder => $composableBuilder(
    column: $table.sortingOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnFilters(column),
  );

  $$DictionariesTableFilterComposer get dictionaryId {
    final $$DictionariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableFilterComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> headingTagsRefs(
    Expression<bool> Function($$HeadingTagsTableFilterComposer f) f,
  ) {
    final $$HeadingTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.headingTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingTagsTableFilterComposer(
            $db: $db,
            $table: $db.headingTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entryTagsRefs(
    Expression<bool> Function($$EntryTagsTableFilterComposer f) f,
  ) {
    final $$EntryTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryTagsTableFilterComposer(
            $db: $db,
            $table: $db.entryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortingOrder => $composableBuilder(
    column: $table.sortingOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnOrderings(column),
  );

  $$DictionariesTableOrderingComposer get dictionaryId {
    final $$DictionariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableOrderingComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get sortingOrder => $composableBuilder(
    column: $table.sortingOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<double> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => column,
  );

  $$DictionariesTableAnnotationComposer get dictionaryId {
    final $$DictionariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableAnnotationComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> headingTagsRefs<T extends Object>(
    Expression<T> Function($$HeadingTagsTableAnnotationComposer a) f,
  ) {
    final $$HeadingTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.headingTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.headingTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> entryTagsRefs<T extends Object>(
    Expression<T> Function($$EntryTagsTableAnnotationComposer a) f,
  ) {
    final $$EntryTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.entryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          TagRow,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagRow, $$TagsTableReferences),
          TagRow,
          PrefetchHooks Function({
            bool dictionaryId,
            bool headingTagsRefs,
            bool entryTagsRefs,
          })
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dictionaryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> sortingOrder = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<double> popularity = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                dictionaryId: dictionaryId,
                name: name,
                category: category,
                sortingOrder: sortingOrder,
                notes: notes,
                popularity: popularity,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dictionaryId,
                required String name,
                required String category,
                required int sortingOrder,
                required String notes,
                required double popularity,
              }) => TagsCompanion.insert(
                id: id,
                dictionaryId: dictionaryId,
                name: name,
                category: category,
                sortingOrder: sortingOrder,
                notes: notes,
                popularity: popularity,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, TagRow>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                dictionaryId = false,
                headingTagsRefs = false,
                entryTagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (headingTagsRefs) db.headingTags,
                    if (entryTagsRefs) db.entryTags,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (dictionaryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.dictionaryId,
                            referencedTable: $$TagsTableReferences
                                ._dictionaryIdTable(db),
                            referencedColumn: $$TagsTableReferences
                                ._dictionaryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (headingTagsRefs)
                        await $_getPrefetchedDataByColumns<
                          TagRow,
                          $TagsTable,
                          HeadingTagRow,
                          $HeadingTagsTable
                        >(
                          currentTable: table,
                          referencedTable: $$TagsTableReferences
                              ._headingTagsRefsTable(db),
                          managerFromTypedResult: (p0) => $$TagsTableReferences(
                            db,
                            table,
                            p0,
                          ).headingTagsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'tag_id',
                          typedResults: items,
                        ),
                      if (entryTagsRefs)
                        await $_getPrefetchedDataByColumns<
                          TagRow,
                          $TagsTable,
                          EntryTagRow,
                          $EntryTagsTable
                        >(
                          currentTable: table,
                          referencedTable: $$TagsTableReferences
                              ._entryTagsRefsTable(db),
                          managerFromTypedResult: (p0) => $$TagsTableReferences(
                            db,
                            table,
                            p0,
                          ).entryTagsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'tag_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      TagRow,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagRow, $$TagsTableReferences),
      TagRow,
      PrefetchHooks Function({
        bool dictionaryId,
        bool headingTagsRefs,
        bool entryTagsRefs,
      })
    >;
typedef $$HeadingTagsTableCreateCompanionBuilder =
    HeadingTagsCompanion Function({
      required int headingId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$HeadingTagsTableUpdateCompanionBuilder =
    HeadingTagsCompanion Function({
      Value<int> headingId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$HeadingTagsTableReferences
    extends BaseReferences<_$AppDatabase, $HeadingTagsTable, HeadingTagRow> {
  $$HeadingTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HeadingsTable _headingIdTable(_$AppDatabase db) =>
      db.headings.createAlias('heading_tag__heading_id__heading__id');

  $$HeadingsTableProcessedTableManager get headingId {
    final $_column = $_itemColumn<int>('heading_id')!;

    final manager = $$HeadingsTableTableManager(
      $_db,
      $_db.headings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_headingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('heading_tag__tag_id__tag__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HeadingTagsTableFilterComposer
    extends Composer<_$AppDatabase, $HeadingTagsTable> {
  $$HeadingTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$HeadingsTableFilterComposer get headingId {
    final $$HeadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableFilterComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeadingTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $HeadingTagsTable> {
  $$HeadingTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$HeadingsTableOrderingComposer get headingId {
    final $$HeadingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableOrderingComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeadingTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeadingTagsTable> {
  $$HeadingTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$HeadingsTableAnnotationComposer get headingId {
    final $$HeadingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.headingId,
      referencedTable: $db.headings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeadingsTableAnnotationComposer(
            $db: $db,
            $table: $db.headings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeadingTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeadingTagsTable,
          HeadingTagRow,
          $$HeadingTagsTableFilterComposer,
          $$HeadingTagsTableOrderingComposer,
          $$HeadingTagsTableAnnotationComposer,
          $$HeadingTagsTableCreateCompanionBuilder,
          $$HeadingTagsTableUpdateCompanionBuilder,
          (HeadingTagRow, $$HeadingTagsTableReferences),
          HeadingTagRow,
          PrefetchHooks Function({bool headingId, bool tagId})
        > {
  $$HeadingTagsTableTableManager(_$AppDatabase db, $HeadingTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeadingTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeadingTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeadingTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> headingId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeadingTagsCompanion(
                headingId: headingId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int headingId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => HeadingTagsCompanion.insert(
                headingId: headingId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HeadingTagsTable, HeadingTagRow>(table),
                  $$HeadingTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({headingId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (headingId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.headingId,
                        referencedTable: $$HeadingTagsTableReferences
                            ._headingIdTable(db),
                        referencedColumn: $$HeadingTagsTableReferences
                            ._headingIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$HeadingTagsTableReferences
                            ._tagIdTable(db),
                        referencedColumn: $$HeadingTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HeadingTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeadingTagsTable,
      HeadingTagRow,
      $$HeadingTagsTableFilterComposer,
      $$HeadingTagsTableOrderingComposer,
      $$HeadingTagsTableAnnotationComposer,
      $$HeadingTagsTableCreateCompanionBuilder,
      $$HeadingTagsTableUpdateCompanionBuilder,
      (HeadingTagRow, $$HeadingTagsTableReferences),
      HeadingTagRow,
      PrefetchHooks Function({bool headingId, bool tagId})
    >;
typedef $$EntryTagsTableCreateCompanionBuilder = EntryTagsCompanion Function({
  required int entryId,
  required int tagId,
  Value<int> rowid,
});
typedef $$EntryTagsTableUpdateCompanionBuilder = EntryTagsCompanion Function({
  Value<int> entryId,
  Value<int> tagId,
  Value<int> rowid,
});

final class $$EntryTagsTableReferences
    extends BaseReferences<_$AppDatabase, $EntryTagsTable, EntryTagRow> {
  $$EntryTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _entryIdTable(_$AppDatabase db) =>
      db.entries.createAlias('entry_tag__entry_id__entry__id');

  $$EntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('entry_tag__tag_id__tag__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntryTagsTableFilterComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntriesTableFilterComposer get entryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntriesTableOrderingComposer get entryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntriesTableAnnotationComposer get entryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryTagsTable,
          EntryTagRow,
          $$EntryTagsTableFilterComposer,
          $$EntryTagsTableOrderingComposer,
          $$EntryTagsTableAnnotationComposer,
          $$EntryTagsTableCreateCompanionBuilder,
          $$EntryTagsTableUpdateCompanionBuilder,
          (EntryTagRow, $$EntryTagsTableReferences),
          EntryTagRow,
          PrefetchHooks Function({bool entryId, bool tagId})
        > {
  $$EntryTagsTableTableManager(_$AppDatabase db, $EntryTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> entryId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryTagsCompanion(
                entryId: entryId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int entryId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => EntryTagsCompanion.insert(
                entryId: entryId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntryTagsTable, EntryTagRow>(table),
                  $$EntryTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$EntryTagsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$EntryTagsTableReferences
                            ._entryIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$EntryTagsTableReferences._tagIdTable(
                          db,
                        ),
                        referencedColumn: $$EntryTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntryTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryTagsTable,
      EntryTagRow,
      $$EntryTagsTableFilterComposer,
      $$EntryTagsTableOrderingComposer,
      $$EntryTagsTableAnnotationComposer,
      $$EntryTagsTableCreateCompanionBuilder,
      $$EntryTagsTableUpdateCompanionBuilder,
      (EntryTagRow, $$EntryTagsTableReferences),
      EntryTagRow,
      PrefetchHooks Function({bool entryId, bool tagId})
    >;
typedef $$MediaItemsTableCreateCompanionBuilder = MediaItemsCompanion Function({
  Value<int> id,
  required String mediaSourceIdentifier,
  required String mediaIdentifier,
  required String title,
  Value<String?> imageUrl,
  Value<String?> sourceMetadata,
  required int position,
  required int duration,
  required bool canDelete,
  required bool canEdit,
  Value<String?> overrideTitle,
  required DateTime lastOpenedAt,
});
typedef $$MediaItemsTableUpdateCompanionBuilder = MediaItemsCompanion Function({
  Value<int> id,
  Value<String> mediaSourceIdentifier,
  Value<String> mediaIdentifier,
  Value<String> title,
  Value<String?> imageUrl,
  Value<String?> sourceMetadata,
  Value<int> position,
  Value<int> duration,
  Value<bool> canDelete,
  Value<bool> canEdit,
  Value<String?> overrideTitle,
  Value<DateTime> lastOpenedAt,
});

final class $$MediaItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem> {
  $$MediaItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StashItemsTable, List<StashItem>>
  _stashItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stashItems,
    aliasName: 'media_item__id__stash_item__media_item_id',
  );

  $$StashItemsTableProcessedTableManager get stashItemsRefs {
    final manager = $$StashItemsTableTableManager(
      $_db,
      $_db.stashItems,
    ).filter((f) => f.mediaItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stashItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
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

  ColumnFilters<String> get mediaSourceIdentifier => $composableBuilder(
    column: $table.mediaSourceIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaIdentifier => $composableBuilder(
    column: $table.mediaIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceMetadata => $composableBuilder(
    column: $table.sourceMetadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canDelete => $composableBuilder(
    column: $table.canDelete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canEdit => $composableBuilder(
    column: $table.canEdit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideTitle => $composableBuilder(
    column: $table.overrideTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get lastOpenedAt =>
      $composableBuilder(
        column: $table.lastOpenedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> stashItemsRefs(
    Expression<bool> Function($$StashItemsTableFilterComposer f) f,
  ) {
    final $$StashItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stashItems,
      getReferencedColumn: (t) => t.mediaItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StashItemsTableFilterComposer(
            $db: $db,
            $table: $db.stashItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
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

  ColumnOrderings<String> get mediaSourceIdentifier => $composableBuilder(
    column: $table.mediaSourceIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaIdentifier => $composableBuilder(
    column: $table.mediaIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceMetadata => $composableBuilder(
    column: $table.sourceMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canDelete => $composableBuilder(
    column: $table.canDelete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canEdit => $composableBuilder(
    column: $table.canEdit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideTitle => $composableBuilder(
    column: $table.overrideTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaSourceIdentifier => $composableBuilder(
    column: $table.mediaSourceIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaIdentifier => $composableBuilder(
    column: $table.mediaIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceMetadata => $composableBuilder(
    column: $table.sourceMetadata,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<bool> get canDelete =>
      $composableBuilder(column: $table.canDelete, builder: (column) => column);

  GeneratedColumn<bool> get canEdit =>
      $composableBuilder(column: $table.canEdit, builder: (column) => column);

  GeneratedColumn<String> get overrideTitle => $composableBuilder(
    column: $table.overrideTitle,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get lastOpenedAt =>
      $composableBuilder(
        column: $table.lastOpenedAt,
        builder: (column) => column,
      );

  Expression<T> stashItemsRefs<T extends Object>(
    Expression<T> Function($$StashItemsTableAnnotationComposer a) f,
  ) {
    final $$StashItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stashItems,
      getReferencedColumn: (t) => t.mediaItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StashItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.stashItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaItemsTable,
          MediaItem,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (MediaItem, $$MediaItemsTableReferences),
          MediaItem,
          PrefetchHooks Function({bool stashItemsRefs})
        > {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mediaSourceIdentifier = const Value.absent(),
                Value<String> mediaIdentifier = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> sourceMetadata = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<bool> canDelete = const Value.absent(),
                Value<bool> canEdit = const Value.absent(),
                Value<String?> overrideTitle = const Value.absent(),
                Value<DateTime> lastOpenedAt = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                mediaSourceIdentifier: mediaSourceIdentifier,
                mediaIdentifier: mediaIdentifier,
                title: title,
                imageUrl: imageUrl,
                sourceMetadata: sourceMetadata,
                position: position,
                duration: duration,
                canDelete: canDelete,
                canEdit: canEdit,
                overrideTitle: overrideTitle,
                lastOpenedAt: lastOpenedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mediaSourceIdentifier,
                required String mediaIdentifier,
                required String title,
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> sourceMetadata = const Value.absent(),
                required int position,
                required int duration,
                required bool canDelete,
                required bool canEdit,
                Value<String?> overrideTitle = const Value.absent(),
                required DateTime lastOpenedAt,
              }) => MediaItemsCompanion.insert(
                id: id,
                mediaSourceIdentifier: mediaSourceIdentifier,
                mediaIdentifier: mediaIdentifier,
                title: title,
                imageUrl: imageUrl,
                sourceMetadata: sourceMetadata,
                position: position,
                duration: duration,
                canDelete: canDelete,
                canEdit: canEdit,
                overrideTitle: overrideTitle,
                lastOpenedAt: lastOpenedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaItemsTable, MediaItem>(table),
                  $$MediaItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stashItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (stashItemsRefs) db.stashItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stashItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      MediaItem,
                      $MediaItemsTable,
                      StashItem,
                      $StashItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$MediaItemsTableReferences
                          ._stashItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MediaItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).stashItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'media_item_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaItemsTable,
      MediaItem,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (MediaItem, $$MediaItemsTableReferences),
      MediaItem,
      PrefetchHooks Function({bool stashItemsRefs})
    >;
typedef $$StashItemsTableCreateCompanionBuilder = StashItemsCompanion Function({
  Value<int> id,
  required int mediaItemId,
  required String term,
  required String reading,
  Value<String?> dictionaryName,
  required List<String> definitions,
  required String sentence,
  required int wordStart,
  required int wordLength,
  required int position,
  required DateTime dateAdded,
});
typedef $$StashItemsTableUpdateCompanionBuilder = StashItemsCompanion Function({
  Value<int> id,
  Value<int> mediaItemId,
  Value<String> term,
  Value<String> reading,
  Value<String?> dictionaryName,
  Value<List<String>> definitions,
  Value<String> sentence,
  Value<int> wordStart,
  Value<int> wordLength,
  Value<int> position,
  Value<DateTime> dateAdded,
});

final class $$StashItemsTableReferences
    extends BaseReferences<_$AppDatabase, $StashItemsTable, StashItem> {
  $$StashItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaItemsTable _mediaItemIdTable(_$AppDatabase db) =>
      db.mediaItems.createAlias('stash_item__media_item_id__media_item__id');

  $$MediaItemsTableProcessedTableManager get mediaItemId {
    final $_column = $_itemColumn<int>('media_item_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StashItemsTableFilterComposer
    extends Composer<_$AppDatabase, $StashItemsTable> {
  $$StashItemsTableFilterComposer({
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

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dictionaryName => $composableBuilder(
    column: $table.dictionaryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sentence => $composableBuilder(
    column: $table.sentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordStart => $composableBuilder(
    column: $table.wordStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordLength => $composableBuilder(
    column: $table.wordLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaItemsTableFilterComposer get mediaItemId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaItemId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StashItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $StashItemsTable> {
  $$StashItemsTableOrderingComposer({
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

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dictionaryName => $composableBuilder(
    column: $table.dictionaryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitions => $composableBuilder(
    column: $table.definitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentence => $composableBuilder(
    column: $table.sentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordStart => $composableBuilder(
    column: $table.wordStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordLength => $composableBuilder(
    column: $table.wordLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaItemsTableOrderingComposer get mediaItemId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaItemId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StashItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StashItemsTable> {
  $$StashItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get dictionaryName => $composableBuilder(
    column: $table.dictionaryName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get definitions =>
      $composableBuilder(
        column: $table.definitions,
        builder: (column) => column,
      );

  GeneratedColumn<String> get sentence =>
      $composableBuilder(column: $table.sentence, builder: (column) => column);

  GeneratedColumn<int> get wordStart =>
      $composableBuilder(column: $table.wordStart, builder: (column) => column);

  GeneratedColumn<int> get wordLength => $composableBuilder(
    column: $table.wordLength,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  $$MediaItemsTableAnnotationComposer get mediaItemId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaItemId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StashItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StashItemsTable,
          StashItem,
          $$StashItemsTableFilterComposer,
          $$StashItemsTableOrderingComposer,
          $$StashItemsTableAnnotationComposer,
          $$StashItemsTableCreateCompanionBuilder,
          $$StashItemsTableUpdateCompanionBuilder,
          (StashItem, $$StashItemsTableReferences),
          StashItem,
          PrefetchHooks Function({bool mediaItemId})
        > {
  $$StashItemsTableTableManager(_$AppDatabase db, $StashItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StashItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StashItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StashItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> mediaItemId = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String?> dictionaryName = const Value.absent(),
                Value<List<String>> definitions = const Value.absent(),
                Value<String> sentence = const Value.absent(),
                Value<int> wordStart = const Value.absent(),
                Value<int> wordLength = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => StashItemsCompanion(
                id: id,
                mediaItemId: mediaItemId,
                term: term,
                reading: reading,
                dictionaryName: dictionaryName,
                definitions: definitions,
                sentence: sentence,
                wordStart: wordStart,
                wordLength: wordLength,
                position: position,
                dateAdded: dateAdded,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int mediaItemId,
                required String term,
                required String reading,
                Value<String?> dictionaryName = const Value.absent(),
                required List<String> definitions,
                required String sentence,
                required int wordStart,
                required int wordLength,
                required int position,
                required DateTime dateAdded,
              }) => StashItemsCompanion.insert(
                id: id,
                mediaItemId: mediaItemId,
                term: term,
                reading: reading,
                dictionaryName: dictionaryName,
                definitions: definitions,
                sentence: sentence,
                wordStart: wordStart,
                wordLength: wordLength,
                position: position,
                dateAdded: dateAdded,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StashItemsTable, StashItem>(table),
                  $$StashItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaItemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mediaItemId,
                        referencedTable: $$StashItemsTableReferences
                            ._mediaItemIdTable(db),
                        referencedColumn: $$StashItemsTableReferences
                            ._mediaItemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StashItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StashItemsTable,
      StashItem,
      $$StashItemsTableFilterComposer,
      $$StashItemsTableOrderingComposer,
      $$StashItemsTableAnnotationComposer,
      $$StashItemsTableCreateCompanionBuilder,
      $$StashItemsTableUpdateCompanionBuilder,
      (StashItem, $$StashItemsTableReferences),
      StashItem,
      PrefetchHooks Function({bool mediaItemId})
    >;
typedef $$AnkiMappingsTableCreateCompanionBuilder =
    AnkiMappingsCompanion Function({
      Value<int> id,
      required String label,
      required String model,
      required int order,
      required List<String?> exportFieldKeys,
      required List<String> creatorFieldKeys,
      required List<String> creatorCollapsedFieldKeys,
      required List<String> tags,
      required Map<String, Map<int, String>> enhancements,
      Value<bool?> exportMediaTags,
      Value<bool?> useBrTags,
      Value<bool?> prependDictionaryNames,
    });
typedef $$AnkiMappingsTableUpdateCompanionBuilder =
    AnkiMappingsCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<String> model,
      Value<int> order,
      Value<List<String?>> exportFieldKeys,
      Value<List<String>> creatorFieldKeys,
      Value<List<String>> creatorCollapsedFieldKeys,
      Value<List<String>> tags,
      Value<Map<String, Map<int, String>>> enhancements,
      Value<bool?> exportMediaTags,
      Value<bool?> useBrTags,
      Value<bool?> prependDictionaryNames,
    });

class $$AnkiMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $AnkiMappingsTable> {
  $$AnkiMappingsTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String?>, List<String>, String>
  get exportFieldKeys => $composableBuilder(
    column: $table.exportFieldKeys,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get creatorFieldKeys => $composableBuilder(
    column: $table.creatorFieldKeys,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get creatorCollapsedFieldKeys => $composableBuilder(
    column: $table.creatorCollapsedFieldKeys,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<
    Map<String, Map<int, String>>,
    Map<String, Map<int, String>>,
    String
  >
  get enhancements => $composableBuilder(
    column: $table.enhancements,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get exportMediaTags => $composableBuilder(
    column: $table.exportMediaTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useBrTags => $composableBuilder(
    column: $table.useBrTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get prependDictionaryNames => $composableBuilder(
    column: $table.prependDictionaryNames,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnkiMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnkiMappingsTable> {
  $$AnkiMappingsTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exportFieldKeys => $composableBuilder(
    column: $table.exportFieldKeys,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorFieldKeys => $composableBuilder(
    column: $table.creatorFieldKeys,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorCollapsedFieldKeys => $composableBuilder(
    column: $table.creatorCollapsedFieldKeys,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enhancements => $composableBuilder(
    column: $table.enhancements,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get exportMediaTags => $composableBuilder(
    column: $table.exportMediaTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useBrTags => $composableBuilder(
    column: $table.useBrTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get prependDictionaryNames => $composableBuilder(
    column: $table.prependDictionaryNames,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnkiMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnkiMappingsTable> {
  $$AnkiMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String?>, String> get exportFieldKeys =>
      $composableBuilder(
        column: $table.exportFieldKeys,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String> get creatorFieldKeys =>
      $composableBuilder(
        column: $table.creatorFieldKeys,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String>
  get creatorCollapsedFieldKeys => $composableBuilder(
    column: $table.creatorCollapsedFieldKeys,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, Map<int, String>>, String>
  get enhancements => $composableBuilder(
    column: $table.enhancements,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get exportMediaTags => $composableBuilder(
    column: $table.exportMediaTags,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useBrTags =>
      $composableBuilder(column: $table.useBrTags, builder: (column) => column);

  GeneratedColumn<bool> get prependDictionaryNames => $composableBuilder(
    column: $table.prependDictionaryNames,
    builder: (column) => column,
  );
}

class $$AnkiMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnkiMappingsTable,
          AnkiMapping,
          $$AnkiMappingsTableFilterComposer,
          $$AnkiMappingsTableOrderingComposer,
          $$AnkiMappingsTableAnnotationComposer,
          $$AnkiMappingsTableCreateCompanionBuilder,
          $$AnkiMappingsTableUpdateCompanionBuilder,
          (
            AnkiMapping,
            BaseReferences<_$AppDatabase, $AnkiMappingsTable, AnkiMapping>,
          ),
          AnkiMapping,
          PrefetchHooks Function()
        > {
  $$AnkiMappingsTableTableManager(_$AppDatabase db, $AnkiMappingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnkiMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnkiMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnkiMappingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<List<String?>> exportFieldKeys = const Value.absent(),
                Value<List<String>> creatorFieldKeys = const Value.absent(),
                Value<List<String>> creatorCollapsedFieldKeys =
                    const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<Map<String, Map<int, String>>> enhancements =
                    const Value.absent(),
                Value<bool?> exportMediaTags = const Value.absent(),
                Value<bool?> useBrTags = const Value.absent(),
                Value<bool?> prependDictionaryNames = const Value.absent(),
              }) => AnkiMappingsCompanion(
                id: id,
                label: label,
                model: model,
                order: order,
                exportFieldKeys: exportFieldKeys,
                creatorFieldKeys: creatorFieldKeys,
                creatorCollapsedFieldKeys: creatorCollapsedFieldKeys,
                tags: tags,
                enhancements: enhancements,
                exportMediaTags: exportMediaTags,
                useBrTags: useBrTags,
                prependDictionaryNames: prependDictionaryNames,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                required String model,
                required int order,
                required List<String?> exportFieldKeys,
                required List<String> creatorFieldKeys,
                required List<String> creatorCollapsedFieldKeys,
                required List<String> tags,
                required Map<String, Map<int, String>> enhancements,
                Value<bool?> exportMediaTags = const Value.absent(),
                Value<bool?> useBrTags = const Value.absent(),
                Value<bool?> prependDictionaryNames = const Value.absent(),
              }) => AnkiMappingsCompanion.insert(
                id: id,
                label: label,
                model: model,
                order: order,
                exportFieldKeys: exportFieldKeys,
                creatorFieldKeys: creatorFieldKeys,
                creatorCollapsedFieldKeys: creatorCollapsedFieldKeys,
                tags: tags,
                enhancements: enhancements,
                exportMediaTags: exportMediaTags,
                useBrTags: useBrTags,
                prependDictionaryNames: prependDictionaryNames,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AnkiMappingsTable, AnkiMapping>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AnkiMappingsTable,
                    AnkiMapping
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnkiMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnkiMappingsTable,
      AnkiMapping,
      $$AnkiMappingsTableFilterComposer,
      $$AnkiMappingsTableOrderingComposer,
      $$AnkiMappingsTableAnnotationComposer,
      $$AnkiMappingsTableCreateCompanionBuilder,
      $$AnkiMappingsTableUpdateCompanionBuilder,
      (
        AnkiMapping,
        BaseReferences<_$AppDatabase, $AnkiMappingsTable, AnkiMapping>,
      ),
      AnkiMapping,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryItemsTableCreateCompanionBuilder =
    SearchHistoryItemsCompanion Function({
      Value<int> id,
      required String searchTerm,
    });
typedef $$SearchHistoryItemsTableUpdateCompanionBuilder =
    SearchHistoryItemsCompanion Function({
      Value<int> id,
      Value<String> searchTerm,
    });

class $$SearchHistoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoryItemsTable> {
  $$SearchHistoryItemsTableFilterComposer({
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

  ColumnFilters<String> get searchTerm => $composableBuilder(
    column: $table.searchTerm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoryItemsTable> {
  $$SearchHistoryItemsTableOrderingComposer({
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

  ColumnOrderings<String> get searchTerm => $composableBuilder(
    column: $table.searchTerm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoryItemsTable> {
  $$SearchHistoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get searchTerm => $composableBuilder(
    column: $table.searchTerm,
    builder: (column) => column,
  );
}

class $$SearchHistoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryItemsTable,
          SearchHistoryRow,
          $$SearchHistoryItemsTableFilterComposer,
          $$SearchHistoryItemsTableOrderingComposer,
          $$SearchHistoryItemsTableAnnotationComposer,
          $$SearchHistoryItemsTableCreateCompanionBuilder,
          $$SearchHistoryItemsTableUpdateCompanionBuilder,
          (
            SearchHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $SearchHistoryItemsTable,
              SearchHistoryRow
            >,
          ),
          SearchHistoryRow,
          PrefetchHooks Function()
        > {
  $$SearchHistoryItemsTableTableManager(
    _$AppDatabase db,
    $SearchHistoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoryItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> searchTerm = const Value.absent(),
          }) => SearchHistoryItemsCompanion(id: id, searchTerm: searchTerm),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String searchTerm,
              }) => SearchHistoryItemsCompanion.insert(
                id: id,
                searchTerm: searchTerm,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SearchHistoryItemsTable, SearchHistoryRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SearchHistoryItemsTable,
                    SearchHistoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryItemsTable,
      SearchHistoryRow,
      $$SearchHistoryItemsTableFilterComposer,
      $$SearchHistoryItemsTableOrderingComposer,
      $$SearchHistoryItemsTableAnnotationComposer,
      $$SearchHistoryItemsTableCreateCompanionBuilder,
      $$SearchHistoryItemsTableUpdateCompanionBuilder,
      (
        SearchHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $SearchHistoryItemsTable,
          SearchHistoryRow
        >,
      ),
      SearchHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$DictionaryHistoryItemsTableCreateCompanionBuilder =
    DictionaryHistoryItemsCompanion Function({
      Value<int> id,
      required String searchTerm,
      Value<bool> searchWithWildcards,
    });
typedef $$DictionaryHistoryItemsTableUpdateCompanionBuilder =
    DictionaryHistoryItemsCompanion Function({
      Value<int> id,
      Value<String> searchTerm,
      Value<bool> searchWithWildcards,
    });

class $$DictionaryHistoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryHistoryItemsTable> {
  $$DictionaryHistoryItemsTableFilterComposer({
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

  ColumnFilters<String> get searchTerm => $composableBuilder(
    column: $table.searchTerm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get searchWithWildcards => $composableBuilder(
    column: $table.searchWithWildcards,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryHistoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryHistoryItemsTable> {
  $$DictionaryHistoryItemsTableOrderingComposer({
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

  ColumnOrderings<String> get searchTerm => $composableBuilder(
    column: $table.searchTerm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get searchWithWildcards => $composableBuilder(
    column: $table.searchWithWildcards,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryHistoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryHistoryItemsTable> {
  $$DictionaryHistoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get searchTerm => $composableBuilder(
    column: $table.searchTerm,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get searchWithWildcards => $composableBuilder(
    column: $table.searchWithWildcards,
    builder: (column) => column,
  );
}

class $$DictionaryHistoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryHistoryItemsTable,
          DictionaryHistoryRow,
          $$DictionaryHistoryItemsTableFilterComposer,
          $$DictionaryHistoryItemsTableOrderingComposer,
          $$DictionaryHistoryItemsTableAnnotationComposer,
          $$DictionaryHistoryItemsTableCreateCompanionBuilder,
          $$DictionaryHistoryItemsTableUpdateCompanionBuilder,
          (
            DictionaryHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $DictionaryHistoryItemsTable,
              DictionaryHistoryRow
            >,
          ),
          DictionaryHistoryRow,
          PrefetchHooks Function()
        > {
  $$DictionaryHistoryItemsTableTableManager(
    _$AppDatabase db,
    $DictionaryHistoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryHistoryItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DictionaryHistoryItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DictionaryHistoryItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> searchTerm = const Value.absent(),
                Value<bool> searchWithWildcards = const Value.absent(),
              }) => DictionaryHistoryItemsCompanion(
                id: id,
                searchTerm: searchTerm,
                searchWithWildcards: searchWithWildcards,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String searchTerm,
                Value<bool> searchWithWildcards = const Value.absent(),
              }) => DictionaryHistoryItemsCompanion.insert(
                id: id,
                searchTerm: searchTerm,
                searchWithWildcards: searchWithWildcards,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $DictionaryHistoryItemsTable,
                    DictionaryHistoryRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DictionaryHistoryItemsTable,
                    DictionaryHistoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryHistoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryHistoryItemsTable,
      DictionaryHistoryRow,
      $$DictionaryHistoryItemsTableFilterComposer,
      $$DictionaryHistoryItemsTableOrderingComposer,
      $$DictionaryHistoryItemsTableAnnotationComposer,
      $$DictionaryHistoryItemsTableCreateCompanionBuilder,
      $$DictionaryHistoryItemsTableUpdateCompanionBuilder,
      (
        DictionaryHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $DictionaryHistoryItemsTable,
          DictionaryHistoryRow
        >,
      ),
      DictionaryHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$PreferenceEntriesTableCreateCompanionBuilder =
    PreferenceEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferenceEntriesTableUpdateCompanionBuilder =
    PreferenceEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferenceEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferenceEntriesTable> {
  $$PreferenceEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferenceEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferenceEntriesTable> {
  $$PreferenceEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferenceEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferenceEntriesTable> {
  $$PreferenceEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferenceEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferenceEntriesTable,
          PreferenceEntry,
          $$PreferenceEntriesTableFilterComposer,
          $$PreferenceEntriesTableOrderingComposer,
          $$PreferenceEntriesTableAnnotationComposer,
          $$PreferenceEntriesTableCreateCompanionBuilder,
          $$PreferenceEntriesTableUpdateCompanionBuilder,
          (
            PreferenceEntry,
            BaseReferences<
              _$AppDatabase,
              $PreferenceEntriesTable,
              PreferenceEntry
            >,
          ),
          PreferenceEntry,
          PrefetchHooks Function()
        > {
  $$PreferenceEntriesTableTableManager(
    _$AppDatabase db,
    $PreferenceEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferenceEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferenceEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferenceEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferenceEntriesCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferenceEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferenceEntriesTable, PreferenceEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PreferenceEntriesTable,
                    PreferenceEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferenceEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferenceEntriesTable,
      PreferenceEntry,
      $$PreferenceEntriesTableFilterComposer,
      $$PreferenceEntriesTableOrderingComposer,
      $$PreferenceEntriesTableAnnotationComposer,
      $$PreferenceEntriesTableCreateCompanionBuilder,
      $$PreferenceEntriesTableUpdateCompanionBuilder,
      (
        PreferenceEntry,
        BaseReferences<_$AppDatabase, $PreferenceEntriesTable, PreferenceEntry>,
      ),
      PreferenceEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HeadingsTableTableManager get headings =>
      $$HeadingsTableTableManager(_db, _db.headings);
  $$DictionariesTableTableManager get dictionaries =>
      $$DictionariesTableTableManager(_db, _db.dictionaries);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$PitchesTableTableManager get pitches =>
      $$PitchesTableTableManager(_db, _db.pitches);
  $$FrequenciesTableTableManager get frequencies =>
      $$FrequenciesTableTableManager(_db, _db.frequencies);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$HeadingTagsTableTableManager get headingTags =>
      $$HeadingTagsTableTableManager(_db, _db.headingTags);
  $$EntryTagsTableTableManager get entryTags =>
      $$EntryTagsTableTableManager(_db, _db.entryTags);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$StashItemsTableTableManager get stashItems =>
      $$StashItemsTableTableManager(_db, _db.stashItems);
  $$AnkiMappingsTableTableManager get ankiMappings =>
      $$AnkiMappingsTableTableManager(_db, _db.ankiMappings);
  $$SearchHistoryItemsTableTableManager get searchHistoryItems =>
      $$SearchHistoryItemsTableTableManager(_db, _db.searchHistoryItems);
  $$DictionaryHistoryItemsTableTableManager get dictionaryHistoryItems =>
      $$DictionaryHistoryItemsTableTableManager(
        _db,
        _db.dictionaryHistoryItems,
      );
  $$PreferenceEntriesTableTableManager get preferenceEntries =>
      $$PreferenceEntriesTableTableManager(_db, _db.preferenceEntries);
}

class HeadingTagsByHeadingsResult {
  final int ownerId;
  final TagRow tag;
  HeadingTagsByHeadingsResult({required this.ownerId, required this.tag});
}

class EntryTagsByEntriesResult {
  final int ownerId;
  final TagRow tag;
  EntryTagsByEntriesResult({required this.ownerId, required this.tag});
}

class NoReadingFrequenciesResult {
  final String term;
  final FrequencyRow frequency;
  NoReadingFrequenciesResult({required this.term, required this.frequency});
}
