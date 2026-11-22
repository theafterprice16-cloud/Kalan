// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SourcesTable extends Sources with TableInfo<$SourcesTable, SourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SourceKind>($SourcesTable.$converterkind);
  static const VerificationMeta _statementDayMeta = const VerificationMeta(
    'statementDay',
  );
  @override
  late final GeneratedColumn<int> statementDay = GeneratedColumn<int>(
    'statement_day',
    aliasedName,
    true,
    check: () =>
        statementDay.isNull() |
        ComparableExpr(statementDay).isBetweenValues(1, 31),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    check: () =>
        dueDay.isNull() | ComparableExpr(dueDay).isBetweenValues(1, 31),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftDueToBusinessDayMeta =
      const VerificationMeta('shiftDueToBusinessDay');
  @override
  late final GeneratedColumn<bool> shiftDueToBusinessDay =
      GeneratedColumn<bool>(
        'shift_due_to_business_day',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("shift_due_to_business_day" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _shiftDueForHolidaysMeta =
      const VerificationMeta('shiftDueForHolidays');
  @override
  late final GeneratedColumn<bool> shiftDueForHolidays = GeneratedColumn<bool>(
    'shift_due_for_holidays',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shift_due_for_holidays" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _statementReminderEnabledMeta =
      const VerificationMeta('statementReminderEnabled');
  @override
  late final GeneratedColumn<bool> statementReminderEnabled =
      GeneratedColumn<bool>(
        'statement_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("statement_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _statementReminderDaysMeta =
      const VerificationMeta('statementReminderDays');
  @override
  late final GeneratedColumn<int> statementReminderDays = GeneratedColumn<int>(
    'statement_reminder_days',
    aliasedName,
    false,
    check: () => statementReminderDays.isIn(const [1, 2]),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    statementDay,
    dueDay,
    shiftDueToBusinessDay,
    shiftDueForHolidays,
    createdAt,
    statementReminderEnabled,
    statementReminderDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceRow> instance, {
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
    if (data.containsKey('statement_day')) {
      context.handle(
        _statementDayMeta,
        statementDay.isAcceptableOrUnknown(
          data['statement_day']!,
          _statementDayMeta,
        ),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('shift_due_to_business_day')) {
      context.handle(
        _shiftDueToBusinessDayMeta,
        shiftDueToBusinessDay.isAcceptableOrUnknown(
          data['shift_due_to_business_day']!,
          _shiftDueToBusinessDayMeta,
        ),
      );
    }
    if (data.containsKey('shift_due_for_holidays')) {
      context.handle(
        _shiftDueForHolidaysMeta,
        shiftDueForHolidays.isAcceptableOrUnknown(
          data['shift_due_for_holidays']!,
          _shiftDueForHolidaysMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('statement_reminder_enabled')) {
      context.handle(
        _statementReminderEnabledMeta,
        statementReminderEnabled.isAcceptableOrUnknown(
          data['statement_reminder_enabled']!,
          _statementReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('statement_reminder_days')) {
      context.handle(
        _statementReminderDaysMeta,
        statementReminderDays.isAcceptableOrUnknown(
          data['statement_reminder_days']!,
          _statementReminderDaysMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $SourcesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      statementDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statement_day'],
      ),
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      shiftDueToBusinessDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shift_due_to_business_day'],
      )!,
      shiftDueForHolidays: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shift_due_for_holidays'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      statementReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}statement_reminder_enabled'],
      )!,
      statementReminderDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statement_reminder_days'],
      )!,
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourceKind, String, String> $converterkind =
      const EnumNameConverter<SourceKind>(SourceKind.values);
}

class SourceRow extends DataClass implements Insertable<SourceRow> {
  final int id;
  final String name;
  final SourceKind kind;
  final int? statementDay;
  final int? dueDay;
  final bool shiftDueToBusinessDay;

  /// "Move for public holidays" (schema v19, Roadmap 26): on by default,
  /// existing cards included. The holidays are the holiday country's
  /// ([AppSettings.holidayCountry]).
  final bool shiftDueForHolidays;
  final DateTime createdAt;

  /// Statement closing reminder (schema v13): off by default, only for
  /// cards with a statement day.
  final bool statementReminderEnabled;

  /// How many days before the statement date it comes: 1 or 2.
  final int statementReminderDays;
  const SourceRow({
    required this.id,
    required this.name,
    required this.kind,
    this.statementDay,
    this.dueDay,
    required this.shiftDueToBusinessDay,
    required this.shiftDueForHolidays,
    required this.createdAt,
    required this.statementReminderEnabled,
    required this.statementReminderDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>($SourcesTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || statementDay != null) {
      map['statement_day'] = Variable<int>(statementDay);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    map['shift_due_to_business_day'] = Variable<bool>(shiftDueToBusinessDay);
    map['shift_due_for_holidays'] = Variable<bool>(shiftDueForHolidays);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['statement_reminder_enabled'] = Variable<bool>(
      statementReminderEnabled,
    );
    map['statement_reminder_days'] = Variable<int>(statementReminderDays);
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      statementDay: statementDay == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDay),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      shiftDueToBusinessDay: Value(shiftDueToBusinessDay),
      shiftDueForHolidays: Value(shiftDueForHolidays),
      createdAt: Value(createdAt),
      statementReminderEnabled: Value(statementReminderEnabled),
      statementReminderDays: Value(statementReminderDays),
    );
  }

  factory SourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $SourcesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      statementDay: serializer.fromJson<int?>(json['statementDay']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      shiftDueToBusinessDay: serializer.fromJson<bool>(
        json['shiftDueToBusinessDay'],
      ),
      shiftDueForHolidays: serializer.fromJson<bool>(
        json['shiftDueForHolidays'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      statementReminderEnabled: serializer.fromJson<bool>(
        json['statementReminderEnabled'],
      ),
      statementReminderDays: serializer.fromJson<int>(
        json['statementReminderDays'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(
        $SourcesTable.$converterkind.toJson(kind),
      ),
      'statementDay': serializer.toJson<int?>(statementDay),
      'dueDay': serializer.toJson<int?>(dueDay),
      'shiftDueToBusinessDay': serializer.toJson<bool>(shiftDueToBusinessDay),
      'shiftDueForHolidays': serializer.toJson<bool>(shiftDueForHolidays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'statementReminderEnabled': serializer.toJson<bool>(
        statementReminderEnabled,
      ),
      'statementReminderDays': serializer.toJson<int>(statementReminderDays),
    };
  }

  SourceRow copyWith({
    int? id,
    String? name,
    SourceKind? kind,
    Value<int?> statementDay = const Value.absent(),
    Value<int?> dueDay = const Value.absent(),
    bool? shiftDueToBusinessDay,
    bool? shiftDueForHolidays,
    DateTime? createdAt,
    bool? statementReminderEnabled,
    int? statementReminderDays,
  }) => SourceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    statementDay: statementDay.present ? statementDay.value : this.statementDay,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    shiftDueToBusinessDay: shiftDueToBusinessDay ?? this.shiftDueToBusinessDay,
    shiftDueForHolidays: shiftDueForHolidays ?? this.shiftDueForHolidays,
    createdAt: createdAt ?? this.createdAt,
    statementReminderEnabled:
        statementReminderEnabled ?? this.statementReminderEnabled,
    statementReminderDays: statementReminderDays ?? this.statementReminderDays,
  );
  SourceRow copyWithCompanion(SourcesCompanion data) {
    return SourceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      statementDay: data.statementDay.present
          ? data.statementDay.value
          : this.statementDay,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      shiftDueToBusinessDay: data.shiftDueToBusinessDay.present
          ? data.shiftDueToBusinessDay.value
          : this.shiftDueToBusinessDay,
      shiftDueForHolidays: data.shiftDueForHolidays.present
          ? data.shiftDueForHolidays.value
          : this.shiftDueForHolidays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      statementReminderEnabled: data.statementReminderEnabled.present
          ? data.statementReminderEnabled.value
          : this.statementReminderEnabled,
      statementReminderDays: data.statementReminderDays.present
          ? data.statementReminderDays.value
          : this.statementReminderDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('shiftDueToBusinessDay: $shiftDueToBusinessDay, ')
          ..write('shiftDueForHolidays: $shiftDueForHolidays, ')
          ..write('createdAt: $createdAt, ')
          ..write('statementReminderEnabled: $statementReminderEnabled, ')
          ..write('statementReminderDays: $statementReminderDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    statementDay,
    dueDay,
    shiftDueToBusinessDay,
    shiftDueForHolidays,
    createdAt,
    statementReminderEnabled,
    statementReminderDays,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.statementDay == this.statementDay &&
          other.dueDay == this.dueDay &&
          other.shiftDueToBusinessDay == this.shiftDueToBusinessDay &&
          other.shiftDueForHolidays == this.shiftDueForHolidays &&
          other.createdAt == this.createdAt &&
          other.statementReminderEnabled == this.statementReminderEnabled &&
          other.statementReminderDays == this.statementReminderDays);
}

class SourcesCompanion extends UpdateCompanion<SourceRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<SourceKind> kind;
  final Value<int?> statementDay;
  final Value<int?> dueDay;
  final Value<bool> shiftDueToBusinessDay;
  final Value<bool> shiftDueForHolidays;
  final Value<DateTime> createdAt;
  final Value<bool> statementReminderEnabled;
  final Value<int> statementReminderDays;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.shiftDueToBusinessDay = const Value.absent(),
    this.shiftDueForHolidays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.statementReminderEnabled = const Value.absent(),
    this.statementReminderDays = const Value.absent(),
  });
  SourcesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required SourceKind kind,
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.shiftDueToBusinessDay = const Value.absent(),
    this.shiftDueForHolidays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.statementReminderEnabled = const Value.absent(),
    this.statementReminderDays = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind);
  static Insertable<SourceRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? statementDay,
    Expression<int>? dueDay,
    Expression<bool>? shiftDueToBusinessDay,
    Expression<bool>? shiftDueForHolidays,
    Expression<DateTime>? createdAt,
    Expression<bool>? statementReminderEnabled,
    Expression<int>? statementReminderDays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (statementDay != null) 'statement_day': statementDay,
      if (dueDay != null) 'due_day': dueDay,
      if (shiftDueToBusinessDay != null)
        'shift_due_to_business_day': shiftDueToBusinessDay,
      if (shiftDueForHolidays != null)
        'shift_due_for_holidays': shiftDueForHolidays,
      if (createdAt != null) 'created_at': createdAt,
      if (statementReminderEnabled != null)
        'statement_reminder_enabled': statementReminderEnabled,
      if (statementReminderDays != null)
        'statement_reminder_days': statementReminderDays,
    });
  }

  SourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<SourceKind>? kind,
    Value<int?>? statementDay,
    Value<int?>? dueDay,
    Value<bool>? shiftDueToBusinessDay,
    Value<bool>? shiftDueForHolidays,
    Value<DateTime>? createdAt,
    Value<bool>? statementReminderEnabled,
    Value<int>? statementReminderDays,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      shiftDueToBusinessDay:
          shiftDueToBusinessDay ?? this.shiftDueToBusinessDay,
      shiftDueForHolidays: shiftDueForHolidays ?? this.shiftDueForHolidays,
      createdAt: createdAt ?? this.createdAt,
      statementReminderEnabled:
          statementReminderEnabled ?? this.statementReminderEnabled,
      statementReminderDays:
          statementReminderDays ?? this.statementReminderDays,
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
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SourcesTable.$converterkind.toSql(kind.value),
      );
    }
    if (statementDay.present) {
      map['statement_day'] = Variable<int>(statementDay.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (shiftDueToBusinessDay.present) {
      map['shift_due_to_business_day'] = Variable<bool>(
        shiftDueToBusinessDay.value,
      );
    }
    if (shiftDueForHolidays.present) {
      map['shift_due_for_holidays'] = Variable<bool>(shiftDueForHolidays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (statementReminderEnabled.present) {
      map['statement_reminder_enabled'] = Variable<bool>(
        statementReminderEnabled.value,
      );
    }
    if (statementReminderDays.present) {
      map['statement_reminder_days'] = Variable<int>(
        statementReminderDays.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('shiftDueToBusinessDay: $shiftDueToBusinessDay, ')
          ..write('shiftDueForHolidays: $shiftDueForHolidays, ')
          ..write('createdAt: $createdAt, ')
          ..write('statementReminderEnabled: $statementReminderEnabled, ')
          ..write('statementReminderDays: $statementReminderDays')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, PlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 80),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlanKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PlanKind>($PlansTable.$converterkind);
  static const VerificationMeta _installmentCountMeta = const VerificationMeta(
    'installmentCount',
  );
  @override
  late final GeneratedColumn<int> installmentCount = GeneratedColumn<int>(
    'installment_count',
    aliasedName,
    false,
    check: () => ComparableExpr(installmentCount).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseDayMeta = const VerificationMeta(
    'purchaseDay',
  );
  @override
  late final GeneratedColumn<int> purchaseDay = GeneratedColumn<int>(
    'purchase_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deferMonthsMeta = const VerificationMeta(
    'deferMonths',
  );
  @override
  late final GeneratedColumn<int> deferMonths = GeneratedColumn<int>(
    'defer_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCashAdvanceMeta = const VerificationMeta(
    'isCashAdvance',
  );
  @override
  late final GeneratedColumn<bool> isCashAdvance = GeneratedColumn<bool>(
    'is_cash_advance',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cash_advance" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlanOrigin, String> origin =
      GeneratedColumn<String>(
        'origin',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PlanOrigin>($PlansTable.$converterorigin);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _remindersEnabledMeta = const VerificationMeta(
    'remindersEnabled',
  );
  @override
  late final GeneratedColumn<bool> remindersEnabled = GeneratedColumn<bool>(
    'reminders_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminders_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reminderLeadDaysMeta = const VerificationMeta(
    'reminderLeadDays',
  );
  @override
  late final GeneratedColumn<int> reminderLeadDays = GeneratedColumn<int>(
    'reminder_lead_days',
    aliasedName,
    true,
    check: () =>
        reminderLeadDays.isNull() |
        reminderLeadDays.isIn(const [1, 2, 3, 5, 7]),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderRepeat?, int> repeatMode =
      GeneratedColumn<int>(
        'repeat_mode',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<ReminderRepeat?>($PlansTable.$converterrepeatModen);
  @override
  late final GeneratedColumnWithTypeConverter<PayLaterRuleKind?, String>
  payLaterRule = GeneratedColumn<String>(
    'pay_later_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<PayLaterRuleKind?>($PlansTable.$converterpayLaterRulen);
  static const VerificationMeta _payLaterValueMeta = const VerificationMeta(
    'payLaterValue',
  );
  @override
  late final GeneratedColumn<int> payLaterValue = GeneratedColumn<int>(
    'pay_later_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    true,
    check: () =>
        intervalDays.isNull() |
        ComparableExpr(intervalDays).isBetweenValues(1, 365),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PaymentMethod?, String>
  paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<PaymentMethod?>($PlansTable.$converterpaymentMethodn);
  static const VerificationMeta _chargeSourceIdMeta = const VerificationMeta(
    'chargeSourceId',
  );
  @override
  late final GeneratedColumn<int> chargeSourceId = GeneratedColumn<int>(
    'charge_source_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlanStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('open'),
      ).withConverter<PlanStatus>($PlansTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<CloseReason?, String>
  closeReason = GeneratedColumn<String>(
    'close_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<CloseReason?>($PlansTable.$convertercloseReasonn);
  static const VerificationMeta _heldSinceDayMeta = const VerificationMeta(
    'heldSinceDay',
  );
  @override
  late final GeneratedColumn<int> heldSinceDay = GeneratedColumn<int>(
    'held_since_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _holdCheckDayMeta = const VerificationMeta(
    'holdCheckDay',
  );
  @override
  late final GeneratedColumn<int> holdCheckDay = GeneratedColumn<int>(
    'hold_check_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reopenedDayMeta = const VerificationMeta(
    'reopenedDay',
  );
  @override
  late final GeneratedColumn<int> reopenedDay = GeneratedColumn<int>(
    'reopened_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedDayMeta = const VerificationMeta(
    'closedDay',
  );
  @override
  late final GeneratedColumn<int> closedDay = GeneratedColumn<int>(
    'closed_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installmentFeeMinorMeta =
      const VerificationMeta('installmentFeeMinor');
  @override
  late final GeneratedColumn<int> installmentFeeMinor = GeneratedColumn<int>(
    'installment_fee_minor',
    aliasedName,
    true,
    check: () =>
        installmentFeeMinor.isNull() |
        ComparableExpr(installmentFeeMinor).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<InstallmentFeeScope, String>
  installmentFeeScope =
      GeneratedColumn<String>(
        'installment_fee_scope',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('everyPayment'),
      ).withConverter<InstallmentFeeScope>(
        $PlansTable.$converterinstallmentFeeScope,
      );
  static const VerificationMeta _productPriceMinorMeta = const VerificationMeta(
    'productPriceMinor',
  );
  @override
  late final GeneratedColumn<int> productPriceMinor = GeneratedColumn<int>(
    'product_price_minor',
    aliasedName,
    true,
    check: () =>
        productPriceMinor.isNull() |
        ComparableExpr(productPriceMinor).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    title,
    kind,
    installmentCount,
    purchaseDay,
    deferMonths,
    isCashAdvance,
    origin,
    createdAt,
    remindersEnabled,
    reminderLeadDays,
    repeatMode,
    payLaterRule,
    payLaterValue,
    intervalDays,
    paymentMethod,
    chargeSourceId,
    status,
    closeReason,
    heldSinceDay,
    holdCheckDay,
    reopenedDay,
    closedDay,
    installmentFeeMinor,
    installmentFeeScope,
    productPriceMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('installment_count')) {
      context.handle(
        _installmentCountMeta,
        installmentCount.isAcceptableOrUnknown(
          data['installment_count']!,
          _installmentCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installmentCountMeta);
    }
    if (data.containsKey('purchase_day')) {
      context.handle(
        _purchaseDayMeta,
        purchaseDay.isAcceptableOrUnknown(
          data['purchase_day']!,
          _purchaseDayMeta,
        ),
      );
    }
    if (data.containsKey('defer_months')) {
      context.handle(
        _deferMonthsMeta,
        deferMonths.isAcceptableOrUnknown(
          data['defer_months']!,
          _deferMonthsMeta,
        ),
      );
    }
    if (data.containsKey('is_cash_advance')) {
      context.handle(
        _isCashAdvanceMeta,
        isCashAdvance.isAcceptableOrUnknown(
          data['is_cash_advance']!,
          _isCashAdvanceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('reminders_enabled')) {
      context.handle(
        _remindersEnabledMeta,
        remindersEnabled.isAcceptableOrUnknown(
          data['reminders_enabled']!,
          _remindersEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_lead_days')) {
      context.handle(
        _reminderLeadDaysMeta,
        reminderLeadDays.isAcceptableOrUnknown(
          data['reminder_lead_days']!,
          _reminderLeadDaysMeta,
        ),
      );
    }
    if (data.containsKey('pay_later_value')) {
      context.handle(
        _payLaterValueMeta,
        payLaterValue.isAcceptableOrUnknown(
          data['pay_later_value']!,
          _payLaterValueMeta,
        ),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('charge_source_id')) {
      context.handle(
        _chargeSourceIdMeta,
        chargeSourceId.isAcceptableOrUnknown(
          data['charge_source_id']!,
          _chargeSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('held_since_day')) {
      context.handle(
        _heldSinceDayMeta,
        heldSinceDay.isAcceptableOrUnknown(
          data['held_since_day']!,
          _heldSinceDayMeta,
        ),
      );
    }
    if (data.containsKey('hold_check_day')) {
      context.handle(
        _holdCheckDayMeta,
        holdCheckDay.isAcceptableOrUnknown(
          data['hold_check_day']!,
          _holdCheckDayMeta,
        ),
      );
    }
    if (data.containsKey('reopened_day')) {
      context.handle(
        _reopenedDayMeta,
        reopenedDay.isAcceptableOrUnknown(
          data['reopened_day']!,
          _reopenedDayMeta,
        ),
      );
    }
    if (data.containsKey('closed_day')) {
      context.handle(
        _closedDayMeta,
        closedDay.isAcceptableOrUnknown(data['closed_day']!, _closedDayMeta),
      );
    }
    if (data.containsKey('installment_fee_minor')) {
      context.handle(
        _installmentFeeMinorMeta,
        installmentFeeMinor.isAcceptableOrUnknown(
          data['installment_fee_minor']!,
          _installmentFeeMinorMeta,
        ),
      );
    }
    if (data.containsKey('product_price_minor')) {
      context.handle(
        _productPriceMinorMeta,
        productPriceMinor.isAcceptableOrUnknown(
          data['product_price_minor']!,
          _productPriceMinorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      kind: $PlansTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      installmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_count'],
      )!,
      purchaseDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_day'],
      ),
      deferMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}defer_months'],
      )!,
      isCashAdvance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cash_advance'],
      )!,
      origin: $PlansTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      remindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminders_enabled'],
      )!,
      reminderLeadDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_lead_days'],
      ),
      repeatMode: $PlansTable.$converterrepeatModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}repeat_mode'],
        ),
      ),
      payLaterRule: $PlansTable.$converterpayLaterRulen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pay_later_rule'],
        ),
      ),
      payLaterValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pay_later_value'],
      ),
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      ),
      paymentMethod: $PlansTable.$converterpaymentMethodn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}payment_method'],
        ),
      ),
      chargeSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}charge_source_id'],
      ),
      status: $PlansTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      closeReason: $PlansTable.$convertercloseReasonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}close_reason'],
        ),
      ),
      heldSinceDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}held_since_day'],
      ),
      holdCheckDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hold_check_day'],
      ),
      reopenedDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reopened_day'],
      ),
      closedDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closed_day'],
      ),
      installmentFeeMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_fee_minor'],
      ),
      installmentFeeScope: $PlansTable.$converterinstallmentFeeScope.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}installment_fee_scope'],
        )!,
      ),
      productPriceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_price_minor'],
      ),
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PlanKind, String, String> $converterkind =
      const EnumNameConverter<PlanKind>(PlanKind.values);
  static JsonTypeConverter2<PlanOrigin, String, String> $converterorigin =
      const EnumNameConverter<PlanOrigin>(PlanOrigin.values);
  static JsonTypeConverter2<ReminderRepeat, int, int> $converterrepeatMode =
      const EnumIndexConverter<ReminderRepeat>(ReminderRepeat.values);
  static JsonTypeConverter2<ReminderRepeat?, int?, int?> $converterrepeatModen =
      JsonTypeConverter2.asNullable($converterrepeatMode);
  static JsonTypeConverter2<PayLaterRuleKind, String, String>
  $converterpayLaterRule = const EnumNameConverter<PayLaterRuleKind>(
    PayLaterRuleKind.values,
  );
  static JsonTypeConverter2<PayLaterRuleKind?, String?, String?>
  $converterpayLaterRulen = JsonTypeConverter2.asNullable(
    $converterpayLaterRule,
  );
  static JsonTypeConverter2<PaymentMethod, String, String>
  $converterpaymentMethod = const EnumNameConverter<PaymentMethod>(
    PaymentMethod.values,
  );
  static JsonTypeConverter2<PaymentMethod?, String?, String?>
  $converterpaymentMethodn = JsonTypeConverter2.asNullable(
    $converterpaymentMethod,
  );
  static JsonTypeConverter2<PlanStatus, String, String> $converterstatus =
      const EnumNameConverter<PlanStatus>(PlanStatus.values);
  static JsonTypeConverter2<CloseReason, String, String> $convertercloseReason =
      const EnumNameConverter<CloseReason>(CloseReason.values);
  static JsonTypeConverter2<CloseReason?, String?, String?>
  $convertercloseReasonn = JsonTypeConverter2.asNullable($convertercloseReason);
  static JsonTypeConverter2<InstallmentFeeScope, String, String>
  $converterinstallmentFeeScope = const EnumNameConverter<InstallmentFeeScope>(
    InstallmentFeeScope.values,
  );
}

class PlanRow extends DataClass implements Insertable<PlanRow> {
  final int id;

  /// Optional only for "Pay later" plans (schema v8).
  final int? sourceId;
  final String? title;
  final PlanKind kind;
  final int installmentCount;
  final int? purchaseDay;
  final int deferMonths;
  final bool isCashAdvance;
  final PlanOrigin origin;
  final DateTime createdAt;

  /// Reminder choice (schema v2, v3): off when false; otherwise the
  /// global "days before" ([reminderLeadDays] null) or its own.
  final bool remindersEnabled;
  final int? reminderLeadDays;

  /// Repeat reminders (schema v7): null follows the global setting.
  final ReminderRepeat? repeatMode;

  /// "Pay later" (schema v8): the due date rule, so the date follows a
  /// changed purchase date ([purchaseDay]). Null for other kinds.
  final PayLaterRuleKind? payLaterRule;
  final int? payLaterValue;

  /// "Monthly installments" and "Pay in 4" (schema v9): every N days
  /// (1-365); null is the same day each month. Unused by other kinds.
  final int? intervalDays;

  /// How the payments are paid (schema v11): null is "not set" and keeps
  /// the reminders exactly as before.
  final PaymentMethod? paymentMethod;

  /// Where an automatic payment is taken from (schema v11): any source or
  /// card. Null is "not chosen"; a card plan then means its own card
  /// (`PlanWithPayments.chargeSource`). Deleting the source clears it.
  final int? chargeSourceId;

  /// Open, on hold or closed (schema v14, 19). Every existing plan is
  /// open: a plan whose payments are all paid is in the archive as before.
  final PlanStatus status;

  /// Why a closed plan was closed: return or cancellation. Null for every
  /// other plan, finished (all paid) plans included.
  final CloseReason? closeReason;

  /// The day the plan was put on hold (epoch day). Kept after "Reopen",
  /// with [reopenedDay], to count payments whose date passed meanwhile.
  final int? heldSinceDay;

  /// Where the 30 days before "Still waiting on the return?" start: the
  /// hold day, or the day "Keep on hold" was last chosen.
  final int? holdCheckDay;

  /// The day a plan on hold was reopened; null while on hold or never held.
  final int? reopenedDay;

  /// The day a plan was closed; null for every other plan. Closing cannot
  /// be undone.
  final int? closedDay;

  /// The plan's fee per payment as typed (schema v17, 22): never computed.
  /// Empty for no fee; never on card installments. Each payment keeps the
  /// fee it took in [Payments.installmentFeeMinor], so a paid one keeps its own.
  final int? installmentFeeMinor;

  /// Which payments take the fee: every payment unless "first payment
  /// only" is chosen. Always every payment for "Pay later".
  final InstallmentFeeScope installmentFeeScope;

  /// The product's cash price as typed (schema v18, 23): what the user
  /// would have paid up front. Display only, never part of any total,
  /// period or reminder. Empty when not entered; only on monthly, card and
  /// manual plans (`canHaveProductPrice`).
  final int? productPriceMinor;
  const PlanRow({
    required this.id,
    this.sourceId,
    this.title,
    required this.kind,
    required this.installmentCount,
    this.purchaseDay,
    required this.deferMonths,
    required this.isCashAdvance,
    required this.origin,
    required this.createdAt,
    required this.remindersEnabled,
    this.reminderLeadDays,
    this.repeatMode,
    this.payLaterRule,
    this.payLaterValue,
    this.intervalDays,
    this.paymentMethod,
    this.chargeSourceId,
    required this.status,
    this.closeReason,
    this.heldSinceDay,
    this.holdCheckDay,
    this.reopenedDay,
    this.closedDay,
    this.installmentFeeMinor,
    required this.installmentFeeScope,
    this.productPriceMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<int>(sourceId);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    {
      map['kind'] = Variable<String>($PlansTable.$converterkind.toSql(kind));
    }
    map['installment_count'] = Variable<int>(installmentCount);
    if (!nullToAbsent || purchaseDay != null) {
      map['purchase_day'] = Variable<int>(purchaseDay);
    }
    map['defer_months'] = Variable<int>(deferMonths);
    map['is_cash_advance'] = Variable<bool>(isCashAdvance);
    {
      map['origin'] = Variable<String>(
        $PlansTable.$converterorigin.toSql(origin),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['reminders_enabled'] = Variable<bool>(remindersEnabled);
    if (!nullToAbsent || reminderLeadDays != null) {
      map['reminder_lead_days'] = Variable<int>(reminderLeadDays);
    }
    if (!nullToAbsent || repeatMode != null) {
      map['repeat_mode'] = Variable<int>(
        $PlansTable.$converterrepeatModen.toSql(repeatMode),
      );
    }
    if (!nullToAbsent || payLaterRule != null) {
      map['pay_later_rule'] = Variable<String>(
        $PlansTable.$converterpayLaterRulen.toSql(payLaterRule),
      );
    }
    if (!nullToAbsent || payLaterValue != null) {
      map['pay_later_value'] = Variable<int>(payLaterValue);
    }
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(
        $PlansTable.$converterpaymentMethodn.toSql(paymentMethod),
      );
    }
    if (!nullToAbsent || chargeSourceId != null) {
      map['charge_source_id'] = Variable<int>(chargeSourceId);
    }
    {
      map['status'] = Variable<String>(
        $PlansTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || closeReason != null) {
      map['close_reason'] = Variable<String>(
        $PlansTable.$convertercloseReasonn.toSql(closeReason),
      );
    }
    if (!nullToAbsent || heldSinceDay != null) {
      map['held_since_day'] = Variable<int>(heldSinceDay);
    }
    if (!nullToAbsent || holdCheckDay != null) {
      map['hold_check_day'] = Variable<int>(holdCheckDay);
    }
    if (!nullToAbsent || reopenedDay != null) {
      map['reopened_day'] = Variable<int>(reopenedDay);
    }
    if (!nullToAbsent || closedDay != null) {
      map['closed_day'] = Variable<int>(closedDay);
    }
    if (!nullToAbsent || installmentFeeMinor != null) {
      map['installment_fee_minor'] = Variable<int>(installmentFeeMinor);
    }
    {
      map['installment_fee_scope'] = Variable<String>(
        $PlansTable.$converterinstallmentFeeScope.toSql(installmentFeeScope),
      );
    }
    if (!nullToAbsent || productPriceMinor != null) {
      map['product_price_minor'] = Variable<int>(productPriceMinor);
    }
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      kind: Value(kind),
      installmentCount: Value(installmentCount),
      purchaseDay: purchaseDay == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDay),
      deferMonths: Value(deferMonths),
      isCashAdvance: Value(isCashAdvance),
      origin: Value(origin),
      createdAt: Value(createdAt),
      remindersEnabled: Value(remindersEnabled),
      reminderLeadDays: reminderLeadDays == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderLeadDays),
      repeatMode: repeatMode == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatMode),
      payLaterRule: payLaterRule == null && nullToAbsent
          ? const Value.absent()
          : Value(payLaterRule),
      payLaterValue: payLaterValue == null && nullToAbsent
          ? const Value.absent()
          : Value(payLaterValue),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      chargeSourceId: chargeSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(chargeSourceId),
      status: Value(status),
      closeReason: closeReason == null && nullToAbsent
          ? const Value.absent()
          : Value(closeReason),
      heldSinceDay: heldSinceDay == null && nullToAbsent
          ? const Value.absent()
          : Value(heldSinceDay),
      holdCheckDay: holdCheckDay == null && nullToAbsent
          ? const Value.absent()
          : Value(holdCheckDay),
      reopenedDay: reopenedDay == null && nullToAbsent
          ? const Value.absent()
          : Value(reopenedDay),
      closedDay: closedDay == null && nullToAbsent
          ? const Value.absent()
          : Value(closedDay),
      installmentFeeMinor: installmentFeeMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(installmentFeeMinor),
      installmentFeeScope: Value(installmentFeeScope),
      productPriceMinor: productPriceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(productPriceMinor),
    );
  }

  factory PlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRow(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<int?>(json['sourceId']),
      title: serializer.fromJson<String?>(json['title']),
      kind: $PlansTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      installmentCount: serializer.fromJson<int>(json['installmentCount']),
      purchaseDay: serializer.fromJson<int?>(json['purchaseDay']),
      deferMonths: serializer.fromJson<int>(json['deferMonths']),
      isCashAdvance: serializer.fromJson<bool>(json['isCashAdvance']),
      origin: $PlansTable.$converterorigin.fromJson(
        serializer.fromJson<String>(json['origin']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      remindersEnabled: serializer.fromJson<bool>(json['remindersEnabled']),
      reminderLeadDays: serializer.fromJson<int?>(json['reminderLeadDays']),
      repeatMode: $PlansTable.$converterrepeatModen.fromJson(
        serializer.fromJson<int?>(json['repeatMode']),
      ),
      payLaterRule: $PlansTable.$converterpayLaterRulen.fromJson(
        serializer.fromJson<String?>(json['payLaterRule']),
      ),
      payLaterValue: serializer.fromJson<int?>(json['payLaterValue']),
      intervalDays: serializer.fromJson<int?>(json['intervalDays']),
      paymentMethod: $PlansTable.$converterpaymentMethodn.fromJson(
        serializer.fromJson<String?>(json['paymentMethod']),
      ),
      chargeSourceId: serializer.fromJson<int?>(json['chargeSourceId']),
      status: $PlansTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      closeReason: $PlansTable.$convertercloseReasonn.fromJson(
        serializer.fromJson<String?>(json['closeReason']),
      ),
      heldSinceDay: serializer.fromJson<int?>(json['heldSinceDay']),
      holdCheckDay: serializer.fromJson<int?>(json['holdCheckDay']),
      reopenedDay: serializer.fromJson<int?>(json['reopenedDay']),
      closedDay: serializer.fromJson<int?>(json['closedDay']),
      installmentFeeMinor: serializer.fromJson<int?>(
        json['installmentFeeMinor'],
      ),
      installmentFeeScope: $PlansTable.$converterinstallmentFeeScope.fromJson(
        serializer.fromJson<String>(json['installmentFeeScope']),
      ),
      productPriceMinor: serializer.fromJson<int?>(json['productPriceMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<int?>(sourceId),
      'title': serializer.toJson<String?>(title),
      'kind': serializer.toJson<String>(
        $PlansTable.$converterkind.toJson(kind),
      ),
      'installmentCount': serializer.toJson<int>(installmentCount),
      'purchaseDay': serializer.toJson<int?>(purchaseDay),
      'deferMonths': serializer.toJson<int>(deferMonths),
      'isCashAdvance': serializer.toJson<bool>(isCashAdvance),
      'origin': serializer.toJson<String>(
        $PlansTable.$converterorigin.toJson(origin),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'remindersEnabled': serializer.toJson<bool>(remindersEnabled),
      'reminderLeadDays': serializer.toJson<int?>(reminderLeadDays),
      'repeatMode': serializer.toJson<int?>(
        $PlansTable.$converterrepeatModen.toJson(repeatMode),
      ),
      'payLaterRule': serializer.toJson<String?>(
        $PlansTable.$converterpayLaterRulen.toJson(payLaterRule),
      ),
      'payLaterValue': serializer.toJson<int?>(payLaterValue),
      'intervalDays': serializer.toJson<int?>(intervalDays),
      'paymentMethod': serializer.toJson<String?>(
        $PlansTable.$converterpaymentMethodn.toJson(paymentMethod),
      ),
      'chargeSourceId': serializer.toJson<int?>(chargeSourceId),
      'status': serializer.toJson<String>(
        $PlansTable.$converterstatus.toJson(status),
      ),
      'closeReason': serializer.toJson<String?>(
        $PlansTable.$convertercloseReasonn.toJson(closeReason),
      ),
      'heldSinceDay': serializer.toJson<int?>(heldSinceDay),
      'holdCheckDay': serializer.toJson<int?>(holdCheckDay),
      'reopenedDay': serializer.toJson<int?>(reopenedDay),
      'closedDay': serializer.toJson<int?>(closedDay),
      'installmentFeeMinor': serializer.toJson<int?>(installmentFeeMinor),
      'installmentFeeScope': serializer.toJson<String>(
        $PlansTable.$converterinstallmentFeeScope.toJson(installmentFeeScope),
      ),
      'productPriceMinor': serializer.toJson<int?>(productPriceMinor),
    };
  }

  PlanRow copyWith({
    int? id,
    Value<int?> sourceId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    PlanKind? kind,
    int? installmentCount,
    Value<int?> purchaseDay = const Value.absent(),
    int? deferMonths,
    bool? isCashAdvance,
    PlanOrigin? origin,
    DateTime? createdAt,
    bool? remindersEnabled,
    Value<int?> reminderLeadDays = const Value.absent(),
    Value<ReminderRepeat?> repeatMode = const Value.absent(),
    Value<PayLaterRuleKind?> payLaterRule = const Value.absent(),
    Value<int?> payLaterValue = const Value.absent(),
    Value<int?> intervalDays = const Value.absent(),
    Value<PaymentMethod?> paymentMethod = const Value.absent(),
    Value<int?> chargeSourceId = const Value.absent(),
    PlanStatus? status,
    Value<CloseReason?> closeReason = const Value.absent(),
    Value<int?> heldSinceDay = const Value.absent(),
    Value<int?> holdCheckDay = const Value.absent(),
    Value<int?> reopenedDay = const Value.absent(),
    Value<int?> closedDay = const Value.absent(),
    Value<int?> installmentFeeMinor = const Value.absent(),
    InstallmentFeeScope? installmentFeeScope,
    Value<int?> productPriceMinor = const Value.absent(),
  }) => PlanRow(
    id: id ?? this.id,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    title: title.present ? title.value : this.title,
    kind: kind ?? this.kind,
    installmentCount: installmentCount ?? this.installmentCount,
    purchaseDay: purchaseDay.present ? purchaseDay.value : this.purchaseDay,
    deferMonths: deferMonths ?? this.deferMonths,
    isCashAdvance: isCashAdvance ?? this.isCashAdvance,
    origin: origin ?? this.origin,
    createdAt: createdAt ?? this.createdAt,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderLeadDays: reminderLeadDays.present
        ? reminderLeadDays.value
        : this.reminderLeadDays,
    repeatMode: repeatMode.present ? repeatMode.value : this.repeatMode,
    payLaterRule: payLaterRule.present ? payLaterRule.value : this.payLaterRule,
    payLaterValue: payLaterValue.present
        ? payLaterValue.value
        : this.payLaterValue,
    intervalDays: intervalDays.present ? intervalDays.value : this.intervalDays,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    chargeSourceId: chargeSourceId.present
        ? chargeSourceId.value
        : this.chargeSourceId,
    status: status ?? this.status,
    closeReason: closeReason.present ? closeReason.value : this.closeReason,
    heldSinceDay: heldSinceDay.present ? heldSinceDay.value : this.heldSinceDay,
    holdCheckDay: holdCheckDay.present ? holdCheckDay.value : this.holdCheckDay,
    reopenedDay: reopenedDay.present ? reopenedDay.value : this.reopenedDay,
    closedDay: closedDay.present ? closedDay.value : this.closedDay,
    installmentFeeMinor: installmentFeeMinor.present
        ? installmentFeeMinor.value
        : this.installmentFeeMinor,
    installmentFeeScope: installmentFeeScope ?? this.installmentFeeScope,
    productPriceMinor: productPriceMinor.present
        ? productPriceMinor.value
        : this.productPriceMinor,
  );
  PlanRow copyWithCompanion(PlansCompanion data) {
    return PlanRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      installmentCount: data.installmentCount.present
          ? data.installmentCount.value
          : this.installmentCount,
      purchaseDay: data.purchaseDay.present
          ? data.purchaseDay.value
          : this.purchaseDay,
      deferMonths: data.deferMonths.present
          ? data.deferMonths.value
          : this.deferMonths,
      isCashAdvance: data.isCashAdvance.present
          ? data.isCashAdvance.value
          : this.isCashAdvance,
      origin: data.origin.present ? data.origin.value : this.origin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      remindersEnabled: data.remindersEnabled.present
          ? data.remindersEnabled.value
          : this.remindersEnabled,
      reminderLeadDays: data.reminderLeadDays.present
          ? data.reminderLeadDays.value
          : this.reminderLeadDays,
      repeatMode: data.repeatMode.present
          ? data.repeatMode.value
          : this.repeatMode,
      payLaterRule: data.payLaterRule.present
          ? data.payLaterRule.value
          : this.payLaterRule,
      payLaterValue: data.payLaterValue.present
          ? data.payLaterValue.value
          : this.payLaterValue,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      chargeSourceId: data.chargeSourceId.present
          ? data.chargeSourceId.value
          : this.chargeSourceId,
      status: data.status.present ? data.status.value : this.status,
      closeReason: data.closeReason.present
          ? data.closeReason.value
          : this.closeReason,
      heldSinceDay: data.heldSinceDay.present
          ? data.heldSinceDay.value
          : this.heldSinceDay,
      holdCheckDay: data.holdCheckDay.present
          ? data.holdCheckDay.value
          : this.holdCheckDay,
      reopenedDay: data.reopenedDay.present
          ? data.reopenedDay.value
          : this.reopenedDay,
      closedDay: data.closedDay.present ? data.closedDay.value : this.closedDay,
      installmentFeeMinor: data.installmentFeeMinor.present
          ? data.installmentFeeMinor.value
          : this.installmentFeeMinor,
      installmentFeeScope: data.installmentFeeScope.present
          ? data.installmentFeeScope.value
          : this.installmentFeeScope,
      productPriceMinor: data.productPriceMinor.present
          ? data.productPriceMinor.value
          : this.productPriceMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('purchaseDay: $purchaseDay, ')
          ..write('deferMonths: $deferMonths, ')
          ..write('isCashAdvance: $isCashAdvance, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('reminderLeadDays: $reminderLeadDays, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('payLaterRule: $payLaterRule, ')
          ..write('payLaterValue: $payLaterValue, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('chargeSourceId: $chargeSourceId, ')
          ..write('status: $status, ')
          ..write('closeReason: $closeReason, ')
          ..write('heldSinceDay: $heldSinceDay, ')
          ..write('holdCheckDay: $holdCheckDay, ')
          ..write('reopenedDay: $reopenedDay, ')
          ..write('closedDay: $closedDay, ')
          ..write('installmentFeeMinor: $installmentFeeMinor, ')
          ..write('installmentFeeScope: $installmentFeeScope, ')
          ..write('productPriceMinor: $productPriceMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sourceId,
    title,
    kind,
    installmentCount,
    purchaseDay,
    deferMonths,
    isCashAdvance,
    origin,
    createdAt,
    remindersEnabled,
    reminderLeadDays,
    repeatMode,
    payLaterRule,
    payLaterValue,
    intervalDays,
    paymentMethod,
    chargeSourceId,
    status,
    closeReason,
    heldSinceDay,
    holdCheckDay,
    reopenedDay,
    closedDay,
    installmentFeeMinor,
    installmentFeeScope,
    productPriceMinor,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.installmentCount == this.installmentCount &&
          other.purchaseDay == this.purchaseDay &&
          other.deferMonths == this.deferMonths &&
          other.isCashAdvance == this.isCashAdvance &&
          other.origin == this.origin &&
          other.createdAt == this.createdAt &&
          other.remindersEnabled == this.remindersEnabled &&
          other.reminderLeadDays == this.reminderLeadDays &&
          other.repeatMode == this.repeatMode &&
          other.payLaterRule == this.payLaterRule &&
          other.payLaterValue == this.payLaterValue &&
          other.intervalDays == this.intervalDays &&
          other.paymentMethod == this.paymentMethod &&
          other.chargeSourceId == this.chargeSourceId &&
          other.status == this.status &&
          other.closeReason == this.closeReason &&
          other.heldSinceDay == this.heldSinceDay &&
          other.holdCheckDay == this.holdCheckDay &&
          other.reopenedDay == this.reopenedDay &&
          other.closedDay == this.closedDay &&
          other.installmentFeeMinor == this.installmentFeeMinor &&
          other.installmentFeeScope == this.installmentFeeScope &&
          other.productPriceMinor == this.productPriceMinor);
}

class PlansCompanion extends UpdateCompanion<PlanRow> {
  final Value<int> id;
  final Value<int?> sourceId;
  final Value<String?> title;
  final Value<PlanKind> kind;
  final Value<int> installmentCount;
  final Value<int?> purchaseDay;
  final Value<int> deferMonths;
  final Value<bool> isCashAdvance;
  final Value<PlanOrigin> origin;
  final Value<DateTime> createdAt;
  final Value<bool> remindersEnabled;
  final Value<int?> reminderLeadDays;
  final Value<ReminderRepeat?> repeatMode;
  final Value<PayLaterRuleKind?> payLaterRule;
  final Value<int?> payLaterValue;
  final Value<int?> intervalDays;
  final Value<PaymentMethod?> paymentMethod;
  final Value<int?> chargeSourceId;
  final Value<PlanStatus> status;
  final Value<CloseReason?> closeReason;
  final Value<int?> heldSinceDay;
  final Value<int?> holdCheckDay;
  final Value<int?> reopenedDay;
  final Value<int?> closedDay;
  final Value<int?> installmentFeeMinor;
  final Value<InstallmentFeeScope> installmentFeeScope;
  final Value<int?> productPriceMinor;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.installmentCount = const Value.absent(),
    this.purchaseDay = const Value.absent(),
    this.deferMonths = const Value.absent(),
    this.isCashAdvance = const Value.absent(),
    this.origin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.reminderLeadDays = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.payLaterRule = const Value.absent(),
    this.payLaterValue = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.chargeSourceId = const Value.absent(),
    this.status = const Value.absent(),
    this.closeReason = const Value.absent(),
    this.heldSinceDay = const Value.absent(),
    this.holdCheckDay = const Value.absent(),
    this.reopenedDay = const Value.absent(),
    this.closedDay = const Value.absent(),
    this.installmentFeeMinor = const Value.absent(),
    this.installmentFeeScope = const Value.absent(),
    this.productPriceMinor = const Value.absent(),
  });
  PlansCompanion.insert({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.title = const Value.absent(),
    required PlanKind kind,
    required int installmentCount,
    this.purchaseDay = const Value.absent(),
    this.deferMonths = const Value.absent(),
    this.isCashAdvance = const Value.absent(),
    required PlanOrigin origin,
    this.createdAt = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.reminderLeadDays = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.payLaterRule = const Value.absent(),
    this.payLaterValue = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.chargeSourceId = const Value.absent(),
    this.status = const Value.absent(),
    this.closeReason = const Value.absent(),
    this.heldSinceDay = const Value.absent(),
    this.holdCheckDay = const Value.absent(),
    this.reopenedDay = const Value.absent(),
    this.closedDay = const Value.absent(),
    this.installmentFeeMinor = const Value.absent(),
    this.installmentFeeScope = const Value.absent(),
    this.productPriceMinor = const Value.absent(),
  }) : kind = Value(kind),
       installmentCount = Value(installmentCount),
       origin = Value(origin);
  static Insertable<PlanRow> custom({
    Expression<int>? id,
    Expression<int>? sourceId,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<int>? installmentCount,
    Expression<int>? purchaseDay,
    Expression<int>? deferMonths,
    Expression<bool>? isCashAdvance,
    Expression<String>? origin,
    Expression<DateTime>? createdAt,
    Expression<bool>? remindersEnabled,
    Expression<int>? reminderLeadDays,
    Expression<int>? repeatMode,
    Expression<String>? payLaterRule,
    Expression<int>? payLaterValue,
    Expression<int>? intervalDays,
    Expression<String>? paymentMethod,
    Expression<int>? chargeSourceId,
    Expression<String>? status,
    Expression<String>? closeReason,
    Expression<int>? heldSinceDay,
    Expression<int>? holdCheckDay,
    Expression<int>? reopenedDay,
    Expression<int>? closedDay,
    Expression<int>? installmentFeeMinor,
    Expression<String>? installmentFeeScope,
    Expression<int>? productPriceMinor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (installmentCount != null) 'installment_count': installmentCount,
      if (purchaseDay != null) 'purchase_day': purchaseDay,
      if (deferMonths != null) 'defer_months': deferMonths,
      if (isCashAdvance != null) 'is_cash_advance': isCashAdvance,
      if (origin != null) 'origin': origin,
      if (createdAt != null) 'created_at': createdAt,
      if (remindersEnabled != null) 'reminders_enabled': remindersEnabled,
      if (reminderLeadDays != null) 'reminder_lead_days': reminderLeadDays,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (payLaterRule != null) 'pay_later_rule': payLaterRule,
      if (payLaterValue != null) 'pay_later_value': payLaterValue,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (chargeSourceId != null) 'charge_source_id': chargeSourceId,
      if (status != null) 'status': status,
      if (closeReason != null) 'close_reason': closeReason,
      if (heldSinceDay != null) 'held_since_day': heldSinceDay,
      if (holdCheckDay != null) 'hold_check_day': holdCheckDay,
      if (reopenedDay != null) 'reopened_day': reopenedDay,
      if (closedDay != null) 'closed_day': closedDay,
      if (installmentFeeMinor != null)
        'installment_fee_minor': installmentFeeMinor,
      if (installmentFeeScope != null)
        'installment_fee_scope': installmentFeeScope,
      if (productPriceMinor != null) 'product_price_minor': productPriceMinor,
    });
  }

  PlansCompanion copyWith({
    Value<int>? id,
    Value<int?>? sourceId,
    Value<String?>? title,
    Value<PlanKind>? kind,
    Value<int>? installmentCount,
    Value<int?>? purchaseDay,
    Value<int>? deferMonths,
    Value<bool>? isCashAdvance,
    Value<PlanOrigin>? origin,
    Value<DateTime>? createdAt,
    Value<bool>? remindersEnabled,
    Value<int?>? reminderLeadDays,
    Value<ReminderRepeat?>? repeatMode,
    Value<PayLaterRuleKind?>? payLaterRule,
    Value<int?>? payLaterValue,
    Value<int?>? intervalDays,
    Value<PaymentMethod?>? paymentMethod,
    Value<int?>? chargeSourceId,
    Value<PlanStatus>? status,
    Value<CloseReason?>? closeReason,
    Value<int?>? heldSinceDay,
    Value<int?>? holdCheckDay,
    Value<int?>? reopenedDay,
    Value<int?>? closedDay,
    Value<int?>? installmentFeeMinor,
    Value<InstallmentFeeScope>? installmentFeeScope,
    Value<int?>? productPriceMinor,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      installmentCount: installmentCount ?? this.installmentCount,
      purchaseDay: purchaseDay ?? this.purchaseDay,
      deferMonths: deferMonths ?? this.deferMonths,
      isCashAdvance: isCashAdvance ?? this.isCashAdvance,
      origin: origin ?? this.origin,
      createdAt: createdAt ?? this.createdAt,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
      repeatMode: repeatMode ?? this.repeatMode,
      payLaterRule: payLaterRule ?? this.payLaterRule,
      payLaterValue: payLaterValue ?? this.payLaterValue,
      intervalDays: intervalDays ?? this.intervalDays,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      chargeSourceId: chargeSourceId ?? this.chargeSourceId,
      status: status ?? this.status,
      closeReason: closeReason ?? this.closeReason,
      heldSinceDay: heldSinceDay ?? this.heldSinceDay,
      holdCheckDay: holdCheckDay ?? this.holdCheckDay,
      reopenedDay: reopenedDay ?? this.reopenedDay,
      closedDay: closedDay ?? this.closedDay,
      installmentFeeMinor: installmentFeeMinor ?? this.installmentFeeMinor,
      installmentFeeScope: installmentFeeScope ?? this.installmentFeeScope,
      productPriceMinor: productPriceMinor ?? this.productPriceMinor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PlansTable.$converterkind.toSql(kind.value),
      );
    }
    if (installmentCount.present) {
      map['installment_count'] = Variable<int>(installmentCount.value);
    }
    if (purchaseDay.present) {
      map['purchase_day'] = Variable<int>(purchaseDay.value);
    }
    if (deferMonths.present) {
      map['defer_months'] = Variable<int>(deferMonths.value);
    }
    if (isCashAdvance.present) {
      map['is_cash_advance'] = Variable<bool>(isCashAdvance.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        $PlansTable.$converterorigin.toSql(origin.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (remindersEnabled.present) {
      map['reminders_enabled'] = Variable<bool>(remindersEnabled.value);
    }
    if (reminderLeadDays.present) {
      map['reminder_lead_days'] = Variable<int>(reminderLeadDays.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<int>(
        $PlansTable.$converterrepeatModen.toSql(repeatMode.value),
      );
    }
    if (payLaterRule.present) {
      map['pay_later_rule'] = Variable<String>(
        $PlansTable.$converterpayLaterRulen.toSql(payLaterRule.value),
      );
    }
    if (payLaterValue.present) {
      map['pay_later_value'] = Variable<int>(payLaterValue.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(
        $PlansTable.$converterpaymentMethodn.toSql(paymentMethod.value),
      );
    }
    if (chargeSourceId.present) {
      map['charge_source_id'] = Variable<int>(chargeSourceId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PlansTable.$converterstatus.toSql(status.value),
      );
    }
    if (closeReason.present) {
      map['close_reason'] = Variable<String>(
        $PlansTable.$convertercloseReasonn.toSql(closeReason.value),
      );
    }
    if (heldSinceDay.present) {
      map['held_since_day'] = Variable<int>(heldSinceDay.value);
    }
    if (holdCheckDay.present) {
      map['hold_check_day'] = Variable<int>(holdCheckDay.value);
    }
    if (reopenedDay.present) {
      map['reopened_day'] = Variable<int>(reopenedDay.value);
    }
    if (closedDay.present) {
      map['closed_day'] = Variable<int>(closedDay.value);
    }
    if (installmentFeeMinor.present) {
      map['installment_fee_minor'] = Variable<int>(installmentFeeMinor.value);
    }
    if (installmentFeeScope.present) {
      map['installment_fee_scope'] = Variable<String>(
        $PlansTable.$converterinstallmentFeeScope.toSql(
          installmentFeeScope.value,
        ),
      );
    }
    if (productPriceMinor.present) {
      map['product_price_minor'] = Variable<int>(productPriceMinor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('purchaseDay: $purchaseDay, ')
          ..write('deferMonths: $deferMonths, ')
          ..write('isCashAdvance: $isCashAdvance, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('reminderLeadDays: $reminderLeadDays, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('payLaterRule: $payLaterRule, ')
          ..write('payLaterValue: $payLaterValue, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('chargeSourceId: $chargeSourceId, ')
          ..write('status: $status, ')
          ..write('closeReason: $closeReason, ')
          ..write('heldSinceDay: $heldSinceDay, ')
          ..write('holdCheckDay: $holdCheckDay, ')
          ..write('reopenedDay: $reopenedDay, ')
          ..write('closedDay: $closedDay, ')
          ..write('installmentFeeMinor: $installmentFeeMinor, ')
          ..write('installmentFeeScope: $installmentFeeScope, ')
          ..write('productPriceMinor: $productPriceMinor')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments
    with TableInfo<$PaymentsTable, PaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    check: () => ComparableExpr(amountMinor).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEditedMeta = const VerificationMeta(
    'isEdited',
  );
  @override
  late final GeneratedColumn<bool> isEdited = GeneratedColumn<bool>(
    'is_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _paidBeforeKalanMeta = const VerificationMeta(
    'paidBeforeKalan',
  );
  @override
  late final GeneratedColumn<bool> paidBeforeKalan = GeneratedColumn<bool>(
    'paid_before_kalan',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paid_before_kalan" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _paidOnDayMeta = const VerificationMeta(
    'paidOnDay',
  );
  @override
  late final GeneratedColumn<int> paidOnDay = GeneratedColumn<int>(
    'paid_on_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalDayMeta = const VerificationMeta(
    'originalDay',
  );
  @override
  late final GeneratedColumn<int> originalDay = GeneratedColumn<int>(
    'original_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extraFeeMinorMeta = const VerificationMeta(
    'extraFeeMinor',
  );
  @override
  late final GeneratedColumn<int> extraFeeMinor = GeneratedColumn<int>(
    'extra_fee_minor',
    aliasedName,
    true,
    check: () =>
        extraFeeMinor.isNull() |
        ComparableExpr(extraFeeMinor).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extraFeeNoteMeta = const VerificationMeta(
    'extraFeeNote',
  );
  @override
  late final GeneratedColumn<String> extraFeeNote = GeneratedColumn<String>(
    'extra_fee_note',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 80),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installmentFeeMinorMeta =
      const VerificationMeta('installmentFeeMinor');
  @override
  late final GeneratedColumn<int> installmentFeeMinor = GeneratedColumn<int>(
    'installment_fee_minor',
    aliasedName,
    true,
    check: () =>
        installmentFeeMinor.isNull() |
        ComparableExpr(installmentFeeMinor).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    seq,
    dueDay,
    amountMinor,
    paidAt,
    isEdited,
    paidBeforeKalan,
    paidOnDay,
    originalDay,
    extraFeeMinor,
    extraFeeNote,
    installmentFeeMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDayMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    }
    if (data.containsKey('is_edited')) {
      context.handle(
        _isEditedMeta,
        isEdited.isAcceptableOrUnknown(data['is_edited']!, _isEditedMeta),
      );
    }
    if (data.containsKey('paid_before_kalan')) {
      context.handle(
        _paidBeforeKalanMeta,
        paidBeforeKalan.isAcceptableOrUnknown(
          data['paid_before_kalan']!,
          _paidBeforeKalanMeta,
        ),
      );
    }
    if (data.containsKey('paid_on_day')) {
      context.handle(
        _paidOnDayMeta,
        paidOnDay.isAcceptableOrUnknown(data['paid_on_day']!, _paidOnDayMeta),
      );
    }
    if (data.containsKey('original_day')) {
      context.handle(
        _originalDayMeta,
        originalDay.isAcceptableOrUnknown(
          data['original_day']!,
          _originalDayMeta,
        ),
      );
    }
    if (data.containsKey('extra_fee_minor')) {
      context.handle(
        _extraFeeMinorMeta,
        extraFeeMinor.isAcceptableOrUnknown(
          data['extra_fee_minor']!,
          _extraFeeMinorMeta,
        ),
      );
    }
    if (data.containsKey('extra_fee_note')) {
      context.handle(
        _extraFeeNoteMeta,
        extraFeeNote.isAcceptableOrUnknown(
          data['extra_fee_note']!,
          _extraFeeNoteMeta,
        ),
      );
    }
    if (data.containsKey('installment_fee_minor')) {
      context.handle(
        _installmentFeeMinorMeta,
        installmentFeeMinor.isAcceptableOrUnknown(
          data['installment_fee_minor']!,
          _installmentFeeMinorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {planId, seq},
  ];
  @override
  PaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      ),
      isEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_edited'],
      )!,
      paidBeforeKalan: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paid_before_kalan'],
      )!,
      paidOnDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_on_day'],
      ),
      originalDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_day'],
      ),
      extraFeeMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extra_fee_minor'],
      ),
      extraFeeNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_fee_note'],
      ),
      installmentFeeMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_fee_minor'],
      ),
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class PaymentRow extends DataClass implements Insertable<PaymentRow> {
  final int id;
  final int planId;
  final int seq;
  final int dueDay;
  final int amountMinor;
  final DateTime? paidAt;
  final bool isEdited;

  /// Paid before the plan was added to Kalan (schema v4): stored as paid,
  /// never overdue, never listed one by one or reminded.
  final bool paidBeforeKalan;

  /// The day it was paid, as chosen in the past-due list (schema v5):
  /// "today" or "on the due date". Empty for every other "paid", which
  /// keeps counting on its due date ([countingDate]).
  final int? paidOnDay;

  /// The date the payment had before its date was first changed with
  /// "Change date" (schema v15, 20). Written once, never overwritten;
  /// cleared when the payment goes back to it. Empty for every other
  /// payment.
  final int? originalDay;

  /// A one-off extra fee the provider added, as typed by the user (schema
  /// v16, 21): never computed. Follows the payment's paid state and counts
  /// with it ([spokenForAmount]); never part of the plan's total. Empty
  /// for every payment without one.
  final int? extraFeeMinor;

  /// The extra fee's optional short note (21).
  final String? extraFeeNote;

  /// The plan's fee per payment this payment took (schema v17, 22),
  /// written when the plan's fee is set: unpaid payments follow the plan,
  /// paid ones keep theirs. Part of the installment shown and of "spoken
  /// for" ([spokenForAmount]); never part of [amountMinor] or the plan's
  /// total. Empty for every payment without one.
  final int? installmentFeeMinor;
  const PaymentRow({
    required this.id,
    required this.planId,
    required this.seq,
    required this.dueDay,
    required this.amountMinor,
    this.paidAt,
    required this.isEdited,
    required this.paidBeforeKalan,
    this.paidOnDay,
    this.originalDay,
    this.extraFeeMinor,
    this.extraFeeNote,
    this.installmentFeeMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['seq'] = Variable<int>(seq);
    map['due_day'] = Variable<int>(dueDay);
    map['amount_minor'] = Variable<int>(amountMinor);
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    map['is_edited'] = Variable<bool>(isEdited);
    map['paid_before_kalan'] = Variable<bool>(paidBeforeKalan);
    if (!nullToAbsent || paidOnDay != null) {
      map['paid_on_day'] = Variable<int>(paidOnDay);
    }
    if (!nullToAbsent || originalDay != null) {
      map['original_day'] = Variable<int>(originalDay);
    }
    if (!nullToAbsent || extraFeeMinor != null) {
      map['extra_fee_minor'] = Variable<int>(extraFeeMinor);
    }
    if (!nullToAbsent || extraFeeNote != null) {
      map['extra_fee_note'] = Variable<String>(extraFeeNote);
    }
    if (!nullToAbsent || installmentFeeMinor != null) {
      map['installment_fee_minor'] = Variable<int>(installmentFeeMinor);
    }
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      planId: Value(planId),
      seq: Value(seq),
      dueDay: Value(dueDay),
      amountMinor: Value(amountMinor),
      paidAt: paidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAt),
      isEdited: Value(isEdited),
      paidBeforeKalan: Value(paidBeforeKalan),
      paidOnDay: paidOnDay == null && nullToAbsent
          ? const Value.absent()
          : Value(paidOnDay),
      originalDay: originalDay == null && nullToAbsent
          ? const Value.absent()
          : Value(originalDay),
      extraFeeMinor: extraFeeMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(extraFeeMinor),
      extraFeeNote: extraFeeNote == null && nullToAbsent
          ? const Value.absent()
          : Value(extraFeeNote),
      installmentFeeMinor: installmentFeeMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(installmentFeeMinor),
    );
  }

  factory PaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentRow(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      seq: serializer.fromJson<int>(json['seq']),
      dueDay: serializer.fromJson<int>(json['dueDay']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      isEdited: serializer.fromJson<bool>(json['isEdited']),
      paidBeforeKalan: serializer.fromJson<bool>(json['paidBeforeKalan']),
      paidOnDay: serializer.fromJson<int?>(json['paidOnDay']),
      originalDay: serializer.fromJson<int?>(json['originalDay']),
      extraFeeMinor: serializer.fromJson<int?>(json['extraFeeMinor']),
      extraFeeNote: serializer.fromJson<String?>(json['extraFeeNote']),
      installmentFeeMinor: serializer.fromJson<int?>(
        json['installmentFeeMinor'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'seq': serializer.toJson<int>(seq),
      'dueDay': serializer.toJson<int>(dueDay),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'isEdited': serializer.toJson<bool>(isEdited),
      'paidBeforeKalan': serializer.toJson<bool>(paidBeforeKalan),
      'paidOnDay': serializer.toJson<int?>(paidOnDay),
      'originalDay': serializer.toJson<int?>(originalDay),
      'extraFeeMinor': serializer.toJson<int?>(extraFeeMinor),
      'extraFeeNote': serializer.toJson<String?>(extraFeeNote),
      'installmentFeeMinor': serializer.toJson<int?>(installmentFeeMinor),
    };
  }

  PaymentRow copyWith({
    int? id,
    int? planId,
    int? seq,
    int? dueDay,
    int? amountMinor,
    Value<DateTime?> paidAt = const Value.absent(),
    bool? isEdited,
    bool? paidBeforeKalan,
    Value<int?> paidOnDay = const Value.absent(),
    Value<int?> originalDay = const Value.absent(),
    Value<int?> extraFeeMinor = const Value.absent(),
    Value<String?> extraFeeNote = const Value.absent(),
    Value<int?> installmentFeeMinor = const Value.absent(),
  }) => PaymentRow(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    seq: seq ?? this.seq,
    dueDay: dueDay ?? this.dueDay,
    amountMinor: amountMinor ?? this.amountMinor,
    paidAt: paidAt.present ? paidAt.value : this.paidAt,
    isEdited: isEdited ?? this.isEdited,
    paidBeforeKalan: paidBeforeKalan ?? this.paidBeforeKalan,
    paidOnDay: paidOnDay.present ? paidOnDay.value : this.paidOnDay,
    originalDay: originalDay.present ? originalDay.value : this.originalDay,
    extraFeeMinor: extraFeeMinor.present
        ? extraFeeMinor.value
        : this.extraFeeMinor,
    extraFeeNote: extraFeeNote.present ? extraFeeNote.value : this.extraFeeNote,
    installmentFeeMinor: installmentFeeMinor.present
        ? installmentFeeMinor.value
        : this.installmentFeeMinor,
  );
  PaymentRow copyWithCompanion(PaymentsCompanion data) {
    return PaymentRow(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      seq: data.seq.present ? data.seq.value : this.seq,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      isEdited: data.isEdited.present ? data.isEdited.value : this.isEdited,
      paidBeforeKalan: data.paidBeforeKalan.present
          ? data.paidBeforeKalan.value
          : this.paidBeforeKalan,
      paidOnDay: data.paidOnDay.present ? data.paidOnDay.value : this.paidOnDay,
      originalDay: data.originalDay.present
          ? data.originalDay.value
          : this.originalDay,
      extraFeeMinor: data.extraFeeMinor.present
          ? data.extraFeeMinor.value
          : this.extraFeeMinor,
      extraFeeNote: data.extraFeeNote.present
          ? data.extraFeeNote.value
          : this.extraFeeNote,
      installmentFeeMinor: data.installmentFeeMinor.present
          ? data.installmentFeeMinor.value
          : this.installmentFeeMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentRow(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('seq: $seq, ')
          ..write('dueDay: $dueDay, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('paidAt: $paidAt, ')
          ..write('isEdited: $isEdited, ')
          ..write('paidBeforeKalan: $paidBeforeKalan, ')
          ..write('paidOnDay: $paidOnDay, ')
          ..write('originalDay: $originalDay, ')
          ..write('extraFeeMinor: $extraFeeMinor, ')
          ..write('extraFeeNote: $extraFeeNote, ')
          ..write('installmentFeeMinor: $installmentFeeMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    seq,
    dueDay,
    amountMinor,
    paidAt,
    isEdited,
    paidBeforeKalan,
    paidOnDay,
    originalDay,
    extraFeeMinor,
    extraFeeNote,
    installmentFeeMinor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentRow &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.seq == this.seq &&
          other.dueDay == this.dueDay &&
          other.amountMinor == this.amountMinor &&
          other.paidAt == this.paidAt &&
          other.isEdited == this.isEdited &&
          other.paidBeforeKalan == this.paidBeforeKalan &&
          other.paidOnDay == this.paidOnDay &&
          other.originalDay == this.originalDay &&
          other.extraFeeMinor == this.extraFeeMinor &&
          other.extraFeeNote == this.extraFeeNote &&
          other.installmentFeeMinor == this.installmentFeeMinor);
}

class PaymentsCompanion extends UpdateCompanion<PaymentRow> {
  final Value<int> id;
  final Value<int> planId;
  final Value<int> seq;
  final Value<int> dueDay;
  final Value<int> amountMinor;
  final Value<DateTime?> paidAt;
  final Value<bool> isEdited;
  final Value<bool> paidBeforeKalan;
  final Value<int?> paidOnDay;
  final Value<int?> originalDay;
  final Value<int?> extraFeeMinor;
  final Value<String?> extraFeeNote;
  final Value<int?> installmentFeeMinor;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.seq = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.paidBeforeKalan = const Value.absent(),
    this.paidOnDay = const Value.absent(),
    this.originalDay = const Value.absent(),
    this.extraFeeMinor = const Value.absent(),
    this.extraFeeNote = const Value.absent(),
    this.installmentFeeMinor = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required int seq,
    required int dueDay,
    required int amountMinor,
    this.paidAt = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.paidBeforeKalan = const Value.absent(),
    this.paidOnDay = const Value.absent(),
    this.originalDay = const Value.absent(),
    this.extraFeeMinor = const Value.absent(),
    this.extraFeeNote = const Value.absent(),
    this.installmentFeeMinor = const Value.absent(),
  }) : planId = Value(planId),
       seq = Value(seq),
       dueDay = Value(dueDay),
       amountMinor = Value(amountMinor);
  static Insertable<PaymentRow> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<int>? seq,
    Expression<int>? dueDay,
    Expression<int>? amountMinor,
    Expression<DateTime>? paidAt,
    Expression<bool>? isEdited,
    Expression<bool>? paidBeforeKalan,
    Expression<int>? paidOnDay,
    Expression<int>? originalDay,
    Expression<int>? extraFeeMinor,
    Expression<String>? extraFeeNote,
    Expression<int>? installmentFeeMinor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (seq != null) 'seq': seq,
      if (dueDay != null) 'due_day': dueDay,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (paidAt != null) 'paid_at': paidAt,
      if (isEdited != null) 'is_edited': isEdited,
      if (paidBeforeKalan != null) 'paid_before_kalan': paidBeforeKalan,
      if (paidOnDay != null) 'paid_on_day': paidOnDay,
      if (originalDay != null) 'original_day': originalDay,
      if (extraFeeMinor != null) 'extra_fee_minor': extraFeeMinor,
      if (extraFeeNote != null) 'extra_fee_note': extraFeeNote,
      if (installmentFeeMinor != null)
        'installment_fee_minor': installmentFeeMinor,
    });
  }

  PaymentsCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<int>? seq,
    Value<int>? dueDay,
    Value<int>? amountMinor,
    Value<DateTime?>? paidAt,
    Value<bool>? isEdited,
    Value<bool>? paidBeforeKalan,
    Value<int?>? paidOnDay,
    Value<int?>? originalDay,
    Value<int?>? extraFeeMinor,
    Value<String?>? extraFeeNote,
    Value<int?>? installmentFeeMinor,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      seq: seq ?? this.seq,
      dueDay: dueDay ?? this.dueDay,
      amountMinor: amountMinor ?? this.amountMinor,
      paidAt: paidAt ?? this.paidAt,
      isEdited: isEdited ?? this.isEdited,
      paidBeforeKalan: paidBeforeKalan ?? this.paidBeforeKalan,
      paidOnDay: paidOnDay ?? this.paidOnDay,
      originalDay: originalDay ?? this.originalDay,
      extraFeeMinor: extraFeeMinor ?? this.extraFeeMinor,
      extraFeeNote: extraFeeNote ?? this.extraFeeNote,
      installmentFeeMinor: installmentFeeMinor ?? this.installmentFeeMinor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (isEdited.present) {
      map['is_edited'] = Variable<bool>(isEdited.value);
    }
    if (paidBeforeKalan.present) {
      map['paid_before_kalan'] = Variable<bool>(paidBeforeKalan.value);
    }
    if (paidOnDay.present) {
      map['paid_on_day'] = Variable<int>(paidOnDay.value);
    }
    if (originalDay.present) {
      map['original_day'] = Variable<int>(originalDay.value);
    }
    if (extraFeeMinor.present) {
      map['extra_fee_minor'] = Variable<int>(extraFeeMinor.value);
    }
    if (extraFeeNote.present) {
      map['extra_fee_note'] = Variable<String>(extraFeeNote.value);
    }
    if (installmentFeeMinor.present) {
      map['installment_fee_minor'] = Variable<int>(installmentFeeMinor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('seq: $seq, ')
          ..write('dueDay: $dueDay, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('paidAt: $paidAt, ')
          ..write('isEdited: $isEdited, ')
          ..write('paidBeforeKalan: $paidBeforeKalan, ')
          ..write('paidOnDay: $paidOnDay, ')
          ..write('originalDay: $originalDay, ')
          ..write('extraFeeMinor: $extraFeeMinor, ')
          ..write('extraFeeNote: $extraFeeNote, ')
          ..write('installmentFeeMinor: $installmentFeeMinor')
          ..write(')'))
        .toString();
  }
}

class $RecurringPaymentsTable extends RecurringPayments
    with TableInfo<$RecurringPaymentsTable, RecurringPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringPaymentsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    check: () => ComparableExpr(amountMinor).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Recurrence, String> recurrence =
      GeneratedColumn<String>(
        'recurrence',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Recurrence>($RecurringPaymentsTable.$converterrecurrence);
  static const VerificationMeta _startDayMeta = const VerificationMeta(
    'startDay',
  );
  @override
  late final GeneratedColumn<int> startDay = GeneratedColumn<int>(
    'start_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDayMeta = const VerificationMeta('endDay');
  @override
  late final GeneratedColumn<int> endDay = GeneratedColumn<int>(
    'end_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _remindersEnabledMeta = const VerificationMeta(
    'remindersEnabled',
  );
  @override
  late final GeneratedColumn<bool> remindersEnabled = GeneratedColumn<bool>(
    'reminders_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminders_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reminderLeadDaysMeta = const VerificationMeta(
    'reminderLeadDays',
  );
  @override
  late final GeneratedColumn<int> reminderLeadDays = GeneratedColumn<int>(
    'reminder_lead_days',
    aliasedName,
    true,
    check: () =>
        reminderLeadDays.isNull() |
        reminderLeadDays.isIn(const [1, 2, 3, 5, 7]),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderRepeat?, int> repeatMode =
      GeneratedColumn<int>(
        'repeat_mode',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<ReminderRepeat?>(
        $RecurringPaymentsTable.$converterrepeatModen,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amountMinor,
    recurrence,
    startDay,
    endDay,
    createdAt,
    remindersEnabled,
    reminderLeadDays,
    repeatMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringPaymentRow> instance, {
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
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('start_day')) {
      context.handle(
        _startDayMeta,
        startDay.isAcceptableOrUnknown(data['start_day']!, _startDayMeta),
      );
    } else if (isInserting) {
      context.missing(_startDayMeta);
    }
    if (data.containsKey('end_day')) {
      context.handle(
        _endDayMeta,
        endDay.isAcceptableOrUnknown(data['end_day']!, _endDayMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('reminders_enabled')) {
      context.handle(
        _remindersEnabledMeta,
        remindersEnabled.isAcceptableOrUnknown(
          data['reminders_enabled']!,
          _remindersEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_lead_days')) {
      context.handle(
        _reminderLeadDaysMeta,
        reminderLeadDays.isAcceptableOrUnknown(
          data['reminder_lead_days']!,
          _reminderLeadDaysMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringPaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      recurrence: $RecurringPaymentsTable.$converterrecurrence.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recurrence'],
        )!,
      ),
      startDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_day'],
      )!,
      endDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_day'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      remindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminders_enabled'],
      )!,
      reminderLeadDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_lead_days'],
      ),
      repeatMode: $RecurringPaymentsTable.$converterrepeatModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}repeat_mode'],
        ),
      ),
    );
  }

  @override
  $RecurringPaymentsTable createAlias(String alias) {
    return $RecurringPaymentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Recurrence, String, String> $converterrecurrence =
      const EnumNameConverter<Recurrence>(Recurrence.values);
  static JsonTypeConverter2<ReminderRepeat, int, int> $converterrepeatMode =
      const EnumIndexConverter<ReminderRepeat>(ReminderRepeat.values);
  static JsonTypeConverter2<ReminderRepeat?, int?, int?> $converterrepeatModen =
      JsonTypeConverter2.asNullable($converterrepeatMode);
}

class RecurringPaymentRow extends DataClass
    implements Insertable<RecurringPaymentRow> {
  final int id;
  final String name;
  final int amountMinor;
  final Recurrence recurrence;
  final int startDay;
  final int? endDay;
  final DateTime createdAt;

  /// Reminder choice, as on [Plans] (schema v2, v3).
  final bool remindersEnabled;
  final int? reminderLeadDays;

  /// Repeat reminders, as on [Plans] (schema v7).
  final ReminderRepeat? repeatMode;
  const RecurringPaymentRow({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.recurrence,
    required this.startDay,
    this.endDay,
    required this.createdAt,
    required this.remindersEnabled,
    this.reminderLeadDays,
    this.repeatMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount_minor'] = Variable<int>(amountMinor);
    {
      map['recurrence'] = Variable<String>(
        $RecurringPaymentsTable.$converterrecurrence.toSql(recurrence),
      );
    }
    map['start_day'] = Variable<int>(startDay);
    if (!nullToAbsent || endDay != null) {
      map['end_day'] = Variable<int>(endDay);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['reminders_enabled'] = Variable<bool>(remindersEnabled);
    if (!nullToAbsent || reminderLeadDays != null) {
      map['reminder_lead_days'] = Variable<int>(reminderLeadDays);
    }
    if (!nullToAbsent || repeatMode != null) {
      map['repeat_mode'] = Variable<int>(
        $RecurringPaymentsTable.$converterrepeatModen.toSql(repeatMode),
      );
    }
    return map;
  }

  RecurringPaymentsCompanion toCompanion(bool nullToAbsent) {
    return RecurringPaymentsCompanion(
      id: Value(id),
      name: Value(name),
      amountMinor: Value(amountMinor),
      recurrence: Value(recurrence),
      startDay: Value(startDay),
      endDay: endDay == null && nullToAbsent
          ? const Value.absent()
          : Value(endDay),
      createdAt: Value(createdAt),
      remindersEnabled: Value(remindersEnabled),
      reminderLeadDays: reminderLeadDays == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderLeadDays),
      repeatMode: repeatMode == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatMode),
    );
  }

  factory RecurringPaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringPaymentRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      recurrence: $RecurringPaymentsTable.$converterrecurrence.fromJson(
        serializer.fromJson<String>(json['recurrence']),
      ),
      startDay: serializer.fromJson<int>(json['startDay']),
      endDay: serializer.fromJson<int?>(json['endDay']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      remindersEnabled: serializer.fromJson<bool>(json['remindersEnabled']),
      reminderLeadDays: serializer.fromJson<int?>(json['reminderLeadDays']),
      repeatMode: $RecurringPaymentsTable.$converterrepeatModen.fromJson(
        serializer.fromJson<int?>(json['repeatMode']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'recurrence': serializer.toJson<String>(
        $RecurringPaymentsTable.$converterrecurrence.toJson(recurrence),
      ),
      'startDay': serializer.toJson<int>(startDay),
      'endDay': serializer.toJson<int?>(endDay),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'remindersEnabled': serializer.toJson<bool>(remindersEnabled),
      'reminderLeadDays': serializer.toJson<int?>(reminderLeadDays),
      'repeatMode': serializer.toJson<int?>(
        $RecurringPaymentsTable.$converterrepeatModen.toJson(repeatMode),
      ),
    };
  }

  RecurringPaymentRow copyWith({
    int? id,
    String? name,
    int? amountMinor,
    Recurrence? recurrence,
    int? startDay,
    Value<int?> endDay = const Value.absent(),
    DateTime? createdAt,
    bool? remindersEnabled,
    Value<int?> reminderLeadDays = const Value.absent(),
    Value<ReminderRepeat?> repeatMode = const Value.absent(),
  }) => RecurringPaymentRow(
    id: id ?? this.id,
    name: name ?? this.name,
    amountMinor: amountMinor ?? this.amountMinor,
    recurrence: recurrence ?? this.recurrence,
    startDay: startDay ?? this.startDay,
    endDay: endDay.present ? endDay.value : this.endDay,
    createdAt: createdAt ?? this.createdAt,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderLeadDays: reminderLeadDays.present
        ? reminderLeadDays.value
        : this.reminderLeadDays,
    repeatMode: repeatMode.present ? repeatMode.value : this.repeatMode,
  );
  RecurringPaymentRow copyWithCompanion(RecurringPaymentsCompanion data) {
    return RecurringPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      startDay: data.startDay.present ? data.startDay.value : this.startDay,
      endDay: data.endDay.present ? data.endDay.value : this.endDay,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      remindersEnabled: data.remindersEnabled.present
          ? data.remindersEnabled.value
          : this.remindersEnabled,
      reminderLeadDays: data.reminderLeadDays.present
          ? data.reminderLeadDays.value
          : this.reminderLeadDays,
      repeatMode: data.repeatMode.present
          ? data.repeatMode.value
          : this.repeatMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringPaymentRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('recurrence: $recurrence, ')
          ..write('startDay: $startDay, ')
          ..write('endDay: $endDay, ')
          ..write('createdAt: $createdAt, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('reminderLeadDays: $reminderLeadDays, ')
          ..write('repeatMode: $repeatMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amountMinor,
    recurrence,
    startDay,
    endDay,
    createdAt,
    remindersEnabled,
    reminderLeadDays,
    repeatMode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringPaymentRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amountMinor == this.amountMinor &&
          other.recurrence == this.recurrence &&
          other.startDay == this.startDay &&
          other.endDay == this.endDay &&
          other.createdAt == this.createdAt &&
          other.remindersEnabled == this.remindersEnabled &&
          other.reminderLeadDays == this.reminderLeadDays &&
          other.repeatMode == this.repeatMode);
}

class RecurringPaymentsCompanion extends UpdateCompanion<RecurringPaymentRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> amountMinor;
  final Value<Recurrence> recurrence;
  final Value<int> startDay;
  final Value<int?> endDay;
  final Value<DateTime> createdAt;
  final Value<bool> remindersEnabled;
  final Value<int?> reminderLeadDays;
  final Value<ReminderRepeat?> repeatMode;
  const RecurringPaymentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.startDay = const Value.absent(),
    this.endDay = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.reminderLeadDays = const Value.absent(),
    this.repeatMode = const Value.absent(),
  });
  RecurringPaymentsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int amountMinor,
    required Recurrence recurrence,
    required int startDay,
    this.endDay = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.reminderLeadDays = const Value.absent(),
    this.repeatMode = const Value.absent(),
  }) : name = Value(name),
       amountMinor = Value(amountMinor),
       recurrence = Value(recurrence),
       startDay = Value(startDay);
  static Insertable<RecurringPaymentRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? amountMinor,
    Expression<String>? recurrence,
    Expression<int>? startDay,
    Expression<int>? endDay,
    Expression<DateTime>? createdAt,
    Expression<bool>? remindersEnabled,
    Expression<int>? reminderLeadDays,
    Expression<int>? repeatMode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (recurrence != null) 'recurrence': recurrence,
      if (startDay != null) 'start_day': startDay,
      if (endDay != null) 'end_day': endDay,
      if (createdAt != null) 'created_at': createdAt,
      if (remindersEnabled != null) 'reminders_enabled': remindersEnabled,
      if (reminderLeadDays != null) 'reminder_lead_days': reminderLeadDays,
      if (repeatMode != null) 'repeat_mode': repeatMode,
    });
  }

  RecurringPaymentsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? amountMinor,
    Value<Recurrence>? recurrence,
    Value<int>? startDay,
    Value<int?>? endDay,
    Value<DateTime>? createdAt,
    Value<bool>? remindersEnabled,
    Value<int?>? reminderLeadDays,
    Value<ReminderRepeat?>? repeatMode,
  }) {
    return RecurringPaymentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amountMinor: amountMinor ?? this.amountMinor,
      recurrence: recurrence ?? this.recurrence,
      startDay: startDay ?? this.startDay,
      endDay: endDay ?? this.endDay,
      createdAt: createdAt ?? this.createdAt,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
      repeatMode: repeatMode ?? this.repeatMode,
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
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(
        $RecurringPaymentsTable.$converterrecurrence.toSql(recurrence.value),
      );
    }
    if (startDay.present) {
      map['start_day'] = Variable<int>(startDay.value);
    }
    if (endDay.present) {
      map['end_day'] = Variable<int>(endDay.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (remindersEnabled.present) {
      map['reminders_enabled'] = Variable<bool>(remindersEnabled.value);
    }
    if (reminderLeadDays.present) {
      map['reminder_lead_days'] = Variable<int>(reminderLeadDays.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<int>(
        $RecurringPaymentsTable.$converterrepeatModen.toSql(repeatMode.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('recurrence: $recurrence, ')
          ..write('startDay: $startDay, ')
          ..write('endDay: $endDay, ')
          ..write('createdAt: $createdAt, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('reminderLeadDays: $reminderLeadDays, ')
          ..write('repeatMode: $repeatMode')
          ..write(')'))
        .toString();
  }
}

class $RecurringMarksTable extends RecurringMarks
    with TableInfo<$RecurringMarksTable, RecurringMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recurringIdMeta = const VerificationMeta(
    'recurringId',
  );
  @override
  late final GeneratedColumn<int> recurringId = GeneratedColumn<int>(
    'recurring_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recurring_payments (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _occurrenceDayMeta = const VerificationMeta(
    'occurrenceDay',
  );
  @override
  late final GeneratedColumn<int> occurrenceDay = GeneratedColumn<int>(
    'occurrence_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [recurringId, occurrenceDay, paidAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringMarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recurring_id')) {
      context.handle(
        _recurringIdMeta,
        recurringId.isAcceptableOrUnknown(
          data['recurring_id']!,
          _recurringIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recurringIdMeta);
    }
    if (data.containsKey('occurrence_day')) {
      context.handle(
        _occurrenceDayMeta,
        occurrenceDay.isAcceptableOrUnknown(
          data['occurrence_day']!,
          _occurrenceDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDayMeta);
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recurringId, occurrenceDay};
  @override
  RecurringMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringMarkRow(
      recurringId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurring_id'],
      )!,
      occurrenceDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence_day'],
      )!,
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      )!,
    );
  }

  @override
  $RecurringMarksTable createAlias(String alias) {
    return $RecurringMarksTable(attachedDatabase, alias);
  }
}

class RecurringMarkRow extends DataClass
    implements Insertable<RecurringMarkRow> {
  final int recurringId;
  final int occurrenceDay;
  final DateTime paidAt;
  const RecurringMarkRow({
    required this.recurringId,
    required this.occurrenceDay,
    required this.paidAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recurring_id'] = Variable<int>(recurringId);
    map['occurrence_day'] = Variable<int>(occurrenceDay);
    map['paid_at'] = Variable<DateTime>(paidAt);
    return map;
  }

  RecurringMarksCompanion toCompanion(bool nullToAbsent) {
    return RecurringMarksCompanion(
      recurringId: Value(recurringId),
      occurrenceDay: Value(occurrenceDay),
      paidAt: Value(paidAt),
    );
  }

  factory RecurringMarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringMarkRow(
      recurringId: serializer.fromJson<int>(json['recurringId']),
      occurrenceDay: serializer.fromJson<int>(json['occurrenceDay']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recurringId': serializer.toJson<int>(recurringId),
      'occurrenceDay': serializer.toJson<int>(occurrenceDay),
      'paidAt': serializer.toJson<DateTime>(paidAt),
    };
  }

  RecurringMarkRow copyWith({
    int? recurringId,
    int? occurrenceDay,
    DateTime? paidAt,
  }) => RecurringMarkRow(
    recurringId: recurringId ?? this.recurringId,
    occurrenceDay: occurrenceDay ?? this.occurrenceDay,
    paidAt: paidAt ?? this.paidAt,
  );
  RecurringMarkRow copyWithCompanion(RecurringMarksCompanion data) {
    return RecurringMarkRow(
      recurringId: data.recurringId.present
          ? data.recurringId.value
          : this.recurringId,
      occurrenceDay: data.occurrenceDay.present
          ? data.occurrenceDay.value
          : this.occurrenceDay,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringMarkRow(')
          ..write('recurringId: $recurringId, ')
          ..write('occurrenceDay: $occurrenceDay, ')
          ..write('paidAt: $paidAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recurringId, occurrenceDay, paidAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringMarkRow &&
          other.recurringId == this.recurringId &&
          other.occurrenceDay == this.occurrenceDay &&
          other.paidAt == this.paidAt);
}

class RecurringMarksCompanion extends UpdateCompanion<RecurringMarkRow> {
  final Value<int> recurringId;
  final Value<int> occurrenceDay;
  final Value<DateTime> paidAt;
  final Value<int> rowid;
  const RecurringMarksCompanion({
    this.recurringId = const Value.absent(),
    this.occurrenceDay = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringMarksCompanion.insert({
    required int recurringId,
    required int occurrenceDay,
    required DateTime paidAt,
    this.rowid = const Value.absent(),
  }) : recurringId = Value(recurringId),
       occurrenceDay = Value(occurrenceDay),
       paidAt = Value(paidAt);
  static Insertable<RecurringMarkRow> custom({
    Expression<int>? recurringId,
    Expression<int>? occurrenceDay,
    Expression<DateTime>? paidAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recurringId != null) 'recurring_id': recurringId,
      if (occurrenceDay != null) 'occurrence_day': occurrenceDay,
      if (paidAt != null) 'paid_at': paidAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringMarksCompanion copyWith({
    Value<int>? recurringId,
    Value<int>? occurrenceDay,
    Value<DateTime>? paidAt,
    Value<int>? rowid,
  }) {
    return RecurringMarksCompanion(
      recurringId: recurringId ?? this.recurringId,
      occurrenceDay: occurrenceDay ?? this.occurrenceDay,
      paidAt: paidAt ?? this.paidAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recurringId.present) {
      map['recurring_id'] = Variable<int>(recurringId.value);
    }
    if (occurrenceDay.present) {
      map['occurrence_day'] = Variable<int>(occurrenceDay.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringMarksCompanion(')
          ..write('recurringId: $recurringId, ')
          ..write('occurrenceDay: $occurrenceDay, ')
          ..write('paidAt: $paidAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeCodeMeta = const VerificationMeta(
    'localeCode',
  );
  @override
  late final GeneratedColumn<String> localeCode = GeneratedColumn<String>(
    'locale_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PayFrequency, String>
  payFrequency = GeneratedColumn<String>(
    'pay_frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PayFrequency>($AppSettingsTable.$converterpayFrequency);
  static const VerificationMeta _payDayMeta = const VerificationMeta('payDay');
  @override
  late final GeneratedColumn<int> payDay = GeneratedColumn<int>(
    'pay_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payAnchorDayMeta = const VerificationMeta(
    'payAnchorDay',
  );
  @override
  late final GeneratedColumn<int> payAnchorDay = GeneratedColumn<int>(
    'pay_anchor_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _netIncomeMinorMeta = const VerificationMeta(
    'netIncomeMinor',
  );
  @override
  late final GeneratedColumn<int> netIncomeMinor = GeneratedColumn<int>(
    'net_income_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tightThresholdMinorMeta =
      const VerificationMeta('tightThresholdMinor');
  @override
  late final GeneratedColumn<int> tightThresholdMinor = GeneratedColumn<int>(
    'tight_threshold_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _debugProMeta = const VerificationMeta(
    'debugPro',
  );
  @override
  late final GeneratedColumn<bool> debugPro = GeneratedColumn<bool>(
    'debug_pro',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("debug_pro" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remindersEnabledMeta = const VerificationMeta(
    'remindersEnabled',
  );
  @override
  late final GeneratedColumn<bool> remindersEnabled = GeneratedColumn<bool>(
    'reminders_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminders_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reminderLeadDaysMeta = const VerificationMeta(
    'reminderLeadDays',
  );
  @override
  late final GeneratedColumn<int> reminderLeadDays = GeneratedColumn<int>(
    'reminder_lead_days',
    aliasedName,
    false,
    check: () => reminderLeadDays.isIn(const [1, 2, 3, 5, 7]),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    false,
    check: () => ComparableExpr(reminderMinute).isBetweenValues(0, 1439),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(540),
  );
  static const VerificationMeta _hideAmountsInNotificationsMeta =
      const VerificationMeta('hideAmountsInNotifications');
  @override
  late final GeneratedColumn<bool> hideAmountsInNotifications =
      GeneratedColumn<bool>(
        'hide_amounts_in_notifications',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("hide_amounts_in_notifications" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _reminderPromptShownMeta =
      const VerificationMeta('reminderPromptShown');
  @override
  late final GeneratedColumn<bool> reminderPromptShown = GeneratedColumn<bool>(
    'reminder_prompt_shown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_prompt_shown" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderRepeat, int> repeatMode =
      GeneratedColumn<int>(
        'repeat_mode',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<ReminderRepeat>($AppSettingsTable.$converterrepeatMode);
  @override
  late final GeneratedColumnWithTypeConverter<PayLaterRuleKind?, String>
  lastPayLaterRule =
      GeneratedColumn<String>(
        'last_pay_later_rule',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<PayLaterRuleKind?>(
        $AppSettingsTable.$converterlastPayLaterRulen,
      );
  static const VerificationMeta _lastPayLaterValueMeta = const VerificationMeta(
    'lastPayLaterValue',
  );
  @override
  late final GeneratedColumn<int> lastPayLaterValue = GeneratedColumn<int>(
    'last_pay_later_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AmountEntry?, String>
  lastAmountEntry = GeneratedColumn<String>(
    'last_amount_entry',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<AmountEntry?>($AppSettingsTable.$converterlastAmountEntryn);
  static const VerificationMeta _paydaySummaryEnabledMeta =
      const VerificationMeta('paydaySummaryEnabled');
  @override
  late final GeneratedColumn<bool> paydaySummaryEnabled = GeneratedColumn<bool>(
    'payday_summary_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("payday_summary_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _holidayCountryMeta = const VerificationMeta(
    'holidayCountry',
  );
  @override
  late final GeneratedColumn<String> holidayCountry = GeneratedColumn<String>(
    'holiday_country',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 2,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appliedHolidaysMeta = const VerificationMeta(
    'appliedHolidays',
  );
  @override
  late final GeneratedColumn<String> appliedHolidays = GeneratedColumn<String>(
    'applied_holidays',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currencyCode,
    localeCode,
    payFrequency,
    payDay,
    payAnchorDay,
    netIncomeMinor,
    tightThresholdMinor,
    debugPro,
    remindersEnabled,
    reminderLeadDays,
    reminderMinute,
    hideAmountsInNotifications,
    reminderPromptShown,
    repeatMode,
    lastPayLaterRule,
    lastPayLaterValue,
    lastAmountEntry,
    paydaySummaryEnabled,
    holidayCountry,
    appliedHolidays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('locale_code')) {
      context.handle(
        _localeCodeMeta,
        localeCode.isAcceptableOrUnknown(data['locale_code']!, _localeCodeMeta),
      );
    }
    if (data.containsKey('pay_day')) {
      context.handle(
        _payDayMeta,
        payDay.isAcceptableOrUnknown(data['pay_day']!, _payDayMeta),
      );
    }
    if (data.containsKey('pay_anchor_day')) {
      context.handle(
        _payAnchorDayMeta,
        payAnchorDay.isAcceptableOrUnknown(
          data['pay_anchor_day']!,
          _payAnchorDayMeta,
        ),
      );
    }
    if (data.containsKey('net_income_minor')) {
      context.handle(
        _netIncomeMinorMeta,
        netIncomeMinor.isAcceptableOrUnknown(
          data['net_income_minor']!,
          _netIncomeMinorMeta,
        ),
      );
    }
    if (data.containsKey('tight_threshold_minor')) {
      context.handle(
        _tightThresholdMinorMeta,
        tightThresholdMinor.isAcceptableOrUnknown(
          data['tight_threshold_minor']!,
          _tightThresholdMinorMeta,
        ),
      );
    }
    if (data.containsKey('debug_pro')) {
      context.handle(
        _debugProMeta,
        debugPro.isAcceptableOrUnknown(data['debug_pro']!, _debugProMeta),
      );
    }
    if (data.containsKey('reminders_enabled')) {
      context.handle(
        _remindersEnabledMeta,
        remindersEnabled.isAcceptableOrUnknown(
          data['reminders_enabled']!,
          _remindersEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_lead_days')) {
      context.handle(
        _reminderLeadDaysMeta,
        reminderLeadDays.isAcceptableOrUnknown(
          data['reminder_lead_days']!,
          _reminderLeadDaysMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('hide_amounts_in_notifications')) {
      context.handle(
        _hideAmountsInNotificationsMeta,
        hideAmountsInNotifications.isAcceptableOrUnknown(
          data['hide_amounts_in_notifications']!,
          _hideAmountsInNotificationsMeta,
        ),
      );
    }
    if (data.containsKey('reminder_prompt_shown')) {
      context.handle(
        _reminderPromptShownMeta,
        reminderPromptShown.isAcceptableOrUnknown(
          data['reminder_prompt_shown']!,
          _reminderPromptShownMeta,
        ),
      );
    }
    if (data.containsKey('last_pay_later_value')) {
      context.handle(
        _lastPayLaterValueMeta,
        lastPayLaterValue.isAcceptableOrUnknown(
          data['last_pay_later_value']!,
          _lastPayLaterValueMeta,
        ),
      );
    }
    if (data.containsKey('payday_summary_enabled')) {
      context.handle(
        _paydaySummaryEnabledMeta,
        paydaySummaryEnabled.isAcceptableOrUnknown(
          data['payday_summary_enabled']!,
          _paydaySummaryEnabledMeta,
        ),
      );
    }
    if (data.containsKey('holiday_country')) {
      context.handle(
        _holidayCountryMeta,
        holidayCountry.isAcceptableOrUnknown(
          data['holiday_country']!,
          _holidayCountryMeta,
        ),
      );
    }
    if (data.containsKey('applied_holidays')) {
      context.handle(
        _appliedHolidaysMeta,
        appliedHolidays.isAcceptableOrUnknown(
          data['applied_holidays']!,
          _appliedHolidaysMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      localeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_code'],
      ),
      payFrequency: $AppSettingsTable.$converterpayFrequency.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pay_frequency'],
        )!,
      ),
      payDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pay_day'],
      ),
      payAnchorDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pay_anchor_day'],
      ),
      netIncomeMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}net_income_minor'],
      ),
      tightThresholdMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tight_threshold_minor'],
      ),
      debugPro: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}debug_pro'],
      )!,
      remindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminders_enabled'],
      )!,
      reminderLeadDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_lead_days'],
      )!,
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      )!,
      hideAmountsInNotifications: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hide_amounts_in_notifications'],
      )!,
      reminderPromptShown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_prompt_shown'],
      )!,
      repeatMode: $AppSettingsTable.$converterrepeatMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}repeat_mode'],
        )!,
      ),
      lastPayLaterRule: $AppSettingsTable.$converterlastPayLaterRulen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_pay_later_rule'],
        ),
      ),
      lastPayLaterValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_pay_later_value'],
      ),
      lastAmountEntry: $AppSettingsTable.$converterlastAmountEntryn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_amount_entry'],
        ),
      ),
      paydaySummaryEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}payday_summary_enabled'],
      )!,
      holidayCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}holiday_country'],
      ),
      appliedHolidays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}applied_holidays'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PayFrequency, String, String>
  $converterpayFrequency = const EnumNameConverter<PayFrequency>(
    PayFrequency.values,
  );
  static JsonTypeConverter2<ReminderRepeat, int, int> $converterrepeatMode =
      const EnumIndexConverter<ReminderRepeat>(ReminderRepeat.values);
  static JsonTypeConverter2<PayLaterRuleKind, String, String>
  $converterlastPayLaterRule = const EnumNameConverter<PayLaterRuleKind>(
    PayLaterRuleKind.values,
  );
  static JsonTypeConverter2<PayLaterRuleKind?, String?, String?>
  $converterlastPayLaterRulen = JsonTypeConverter2.asNullable(
    $converterlastPayLaterRule,
  );
  static JsonTypeConverter2<AmountEntry, String, String>
  $converterlastAmountEntry = const EnumNameConverter<AmountEntry>(
    AmountEntry.values,
  );
  static JsonTypeConverter2<AmountEntry?, String?, String?>
  $converterlastAmountEntryn = JsonTypeConverter2.asNullable(
    $converterlastAmountEntry,
  );
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String currencyCode;
  final String? localeCode;
  final PayFrequency payFrequency;

  /// Monthly: day of month 1-31.
  final int? payDay;

  /// Weekly and biweekly: a known payday (epoch day).
  final int? payAnchorDay;

  /// One paycheck, minor units. Optional.
  final int? netIncomeMinor;
  final int? tightThresholdMinor;

  /// Honoured only in debug builds.
  final bool debugPro;
  final bool remindersEnabled;

  /// Global "days before" (1, 2, 3, 5 or 7).
  final int reminderLeadDays;

  /// Local time, minutes after midnight.
  final int reminderMinute;

  /// Privacy: hide amounts in notifications ("show amount" off).
  final bool hideAmountsInNotifications;

  /// The permission sheet was shown (never asked again).
  final bool reminderPromptShown;

  /// Repeat reminders (schema v7): off for everyone until chosen.
  final ReminderRepeat repeatMode;

  /// The "Pay later" rule used last (schema v8), offered next time. A
  /// picked date is never stored here. Null until first used: 30 days.
  final PayLaterRuleKind? lastPayLaterRule;
  final int? lastPayLaterValue;

  /// The amount typed last when adding a plan with several payments
  /// (schema v10): the total or one installment. Null until a plan is
  /// saved: the total, as before.
  final AmountEntry? lastAmountEntry;

  /// Payday summary notification (schema v12): on for everyone until
  /// turned off, existing users included.
  final bool paydaySummaryEnabled;

  /// Holiday country (schema v19, Roadmap 26), one for every card: ISO
  /// 3166-1 alpha-2, '' for "None", null until Kalan suggests one (the
  /// device region, else the currency's country) on first start.
  final String? holidayCountry;

  /// The weekend and holidays the stored card dates were computed with
  /// (`CountryHolidays.toSnapshot`); null: "None". Compared with the
  /// shipped file on every start, so a new list or another country moves
  /// the dates once.
  final String? appliedHolidays;
  const SettingsRow({
    required this.id,
    required this.currencyCode,
    this.localeCode,
    required this.payFrequency,
    this.payDay,
    this.payAnchorDay,
    this.netIncomeMinor,
    this.tightThresholdMinor,
    required this.debugPro,
    required this.remindersEnabled,
    required this.reminderLeadDays,
    required this.reminderMinute,
    required this.hideAmountsInNotifications,
    required this.reminderPromptShown,
    required this.repeatMode,
    this.lastPayLaterRule,
    this.lastPayLaterValue,
    this.lastAmountEntry,
    required this.paydaySummaryEnabled,
    this.holidayCountry,
    this.appliedHolidays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || localeCode != null) {
      map['locale_code'] = Variable<String>(localeCode);
    }
    {
      map['pay_frequency'] = Variable<String>(
        $AppSettingsTable.$converterpayFrequency.toSql(payFrequency),
      );
    }
    if (!nullToAbsent || payDay != null) {
      map['pay_day'] = Variable<int>(payDay);
    }
    if (!nullToAbsent || payAnchorDay != null) {
      map['pay_anchor_day'] = Variable<int>(payAnchorDay);
    }
    if (!nullToAbsent || netIncomeMinor != null) {
      map['net_income_minor'] = Variable<int>(netIncomeMinor);
    }
    if (!nullToAbsent || tightThresholdMinor != null) {
      map['tight_threshold_minor'] = Variable<int>(tightThresholdMinor);
    }
    map['debug_pro'] = Variable<bool>(debugPro);
    map['reminders_enabled'] = Variable<bool>(remindersEnabled);
    map['reminder_lead_days'] = Variable<int>(reminderLeadDays);
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['hide_amounts_in_notifications'] = Variable<bool>(
      hideAmountsInNotifications,
    );
    map['reminder_prompt_shown'] = Variable<bool>(reminderPromptShown);
    {
      map['repeat_mode'] = Variable<int>(
        $AppSettingsTable.$converterrepeatMode.toSql(repeatMode),
      );
    }
    if (!nullToAbsent || lastPayLaterRule != null) {
      map['last_pay_later_rule'] = Variable<String>(
        $AppSettingsTable.$converterlastPayLaterRulen.toSql(lastPayLaterRule),
      );
    }
    if (!nullToAbsent || lastPayLaterValue != null) {
      map['last_pay_later_value'] = Variable<int>(lastPayLaterValue);
    }
    if (!nullToAbsent || lastAmountEntry != null) {
      map['last_amount_entry'] = Variable<String>(
        $AppSettingsTable.$converterlastAmountEntryn.toSql(lastAmountEntry),
      );
    }
    map['payday_summary_enabled'] = Variable<bool>(paydaySummaryEnabled);
    if (!nullToAbsent || holidayCountry != null) {
      map['holiday_country'] = Variable<String>(holidayCountry);
    }
    if (!nullToAbsent || appliedHolidays != null) {
      map['applied_holidays'] = Variable<String>(appliedHolidays);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      currencyCode: Value(currencyCode),
      localeCode: localeCode == null && nullToAbsent
          ? const Value.absent()
          : Value(localeCode),
      payFrequency: Value(payFrequency),
      payDay: payDay == null && nullToAbsent
          ? const Value.absent()
          : Value(payDay),
      payAnchorDay: payAnchorDay == null && nullToAbsent
          ? const Value.absent()
          : Value(payAnchorDay),
      netIncomeMinor: netIncomeMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(netIncomeMinor),
      tightThresholdMinor: tightThresholdMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(tightThresholdMinor),
      debugPro: Value(debugPro),
      remindersEnabled: Value(remindersEnabled),
      reminderLeadDays: Value(reminderLeadDays),
      reminderMinute: Value(reminderMinute),
      hideAmountsInNotifications: Value(hideAmountsInNotifications),
      reminderPromptShown: Value(reminderPromptShown),
      repeatMode: Value(repeatMode),
      lastPayLaterRule: lastPayLaterRule == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPayLaterRule),
      lastPayLaterValue: lastPayLaterValue == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPayLaterValue),
      lastAmountEntry: lastAmountEntry == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAmountEntry),
      paydaySummaryEnabled: Value(paydaySummaryEnabled),
      holidayCountry: holidayCountry == null && nullToAbsent
          ? const Value.absent()
          : Value(holidayCountry),
      appliedHolidays: appliedHolidays == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedHolidays),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      localeCode: serializer.fromJson<String?>(json['localeCode']),
      payFrequency: $AppSettingsTable.$converterpayFrequency.fromJson(
        serializer.fromJson<String>(json['payFrequency']),
      ),
      payDay: serializer.fromJson<int?>(json['payDay']),
      payAnchorDay: serializer.fromJson<int?>(json['payAnchorDay']),
      netIncomeMinor: serializer.fromJson<int?>(json['netIncomeMinor']),
      tightThresholdMinor: serializer.fromJson<int?>(
        json['tightThresholdMinor'],
      ),
      debugPro: serializer.fromJson<bool>(json['debugPro']),
      remindersEnabled: serializer.fromJson<bool>(json['remindersEnabled']),
      reminderLeadDays: serializer.fromJson<int>(json['reminderLeadDays']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      hideAmountsInNotifications: serializer.fromJson<bool>(
        json['hideAmountsInNotifications'],
      ),
      reminderPromptShown: serializer.fromJson<bool>(
        json['reminderPromptShown'],
      ),
      repeatMode: $AppSettingsTable.$converterrepeatMode.fromJson(
        serializer.fromJson<int>(json['repeatMode']),
      ),
      lastPayLaterRule: $AppSettingsTable.$converterlastPayLaterRulen.fromJson(
        serializer.fromJson<String?>(json['lastPayLaterRule']),
      ),
      lastPayLaterValue: serializer.fromJson<int?>(json['lastPayLaterValue']),
      lastAmountEntry: $AppSettingsTable.$converterlastAmountEntryn.fromJson(
        serializer.fromJson<String?>(json['lastAmountEntry']),
      ),
      paydaySummaryEnabled: serializer.fromJson<bool>(
        json['paydaySummaryEnabled'],
      ),
      holidayCountry: serializer.fromJson<String?>(json['holidayCountry']),
      appliedHolidays: serializer.fromJson<String?>(json['appliedHolidays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'localeCode': serializer.toJson<String?>(localeCode),
      'payFrequency': serializer.toJson<String>(
        $AppSettingsTable.$converterpayFrequency.toJson(payFrequency),
      ),
      'payDay': serializer.toJson<int?>(payDay),
      'payAnchorDay': serializer.toJson<int?>(payAnchorDay),
      'netIncomeMinor': serializer.toJson<int?>(netIncomeMinor),
      'tightThresholdMinor': serializer.toJson<int?>(tightThresholdMinor),
      'debugPro': serializer.toJson<bool>(debugPro),
      'remindersEnabled': serializer.toJson<bool>(remindersEnabled),
      'reminderLeadDays': serializer.toJson<int>(reminderLeadDays),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'hideAmountsInNotifications': serializer.toJson<bool>(
        hideAmountsInNotifications,
      ),
      'reminderPromptShown': serializer.toJson<bool>(reminderPromptShown),
      'repeatMode': serializer.toJson<int>(
        $AppSettingsTable.$converterrepeatMode.toJson(repeatMode),
      ),
      'lastPayLaterRule': serializer.toJson<String?>(
        $AppSettingsTable.$converterlastPayLaterRulen.toJson(lastPayLaterRule),
      ),
      'lastPayLaterValue': serializer.toJson<int?>(lastPayLaterValue),
      'lastAmountEntry': serializer.toJson<String?>(
        $AppSettingsTable.$converterlastAmountEntryn.toJson(lastAmountEntry),
      ),
      'paydaySummaryEnabled': serializer.toJson<bool>(paydaySummaryEnabled),
      'holidayCountry': serializer.toJson<String?>(holidayCountry),
      'appliedHolidays': serializer.toJson<String?>(appliedHolidays),
    };
  }

  SettingsRow copyWith({
    int? id,
    String? currencyCode,
    Value<String?> localeCode = const Value.absent(),
    PayFrequency? payFrequency,
    Value<int?> payDay = const Value.absent(),
    Value<int?> payAnchorDay = const Value.absent(),
    Value<int?> netIncomeMinor = const Value.absent(),
    Value<int?> tightThresholdMinor = const Value.absent(),
    bool? debugPro,
    bool? remindersEnabled,
    int? reminderLeadDays,
    int? reminderMinute,
    bool? hideAmountsInNotifications,
    bool? reminderPromptShown,
    ReminderRepeat? repeatMode,
    Value<PayLaterRuleKind?> lastPayLaterRule = const Value.absent(),
    Value<int?> lastPayLaterValue = const Value.absent(),
    Value<AmountEntry?> lastAmountEntry = const Value.absent(),
    bool? paydaySummaryEnabled,
    Value<String?> holidayCountry = const Value.absent(),
    Value<String?> appliedHolidays = const Value.absent(),
  }) => SettingsRow(
    id: id ?? this.id,
    currencyCode: currencyCode ?? this.currencyCode,
    localeCode: localeCode.present ? localeCode.value : this.localeCode,
    payFrequency: payFrequency ?? this.payFrequency,
    payDay: payDay.present ? payDay.value : this.payDay,
    payAnchorDay: payAnchorDay.present ? payAnchorDay.value : this.payAnchorDay,
    netIncomeMinor: netIncomeMinor.present
        ? netIncomeMinor.value
        : this.netIncomeMinor,
    tightThresholdMinor: tightThresholdMinor.present
        ? tightThresholdMinor.value
        : this.tightThresholdMinor,
    debugPro: debugPro ?? this.debugPro,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    hideAmountsInNotifications:
        hideAmountsInNotifications ?? this.hideAmountsInNotifications,
    reminderPromptShown: reminderPromptShown ?? this.reminderPromptShown,
    repeatMode: repeatMode ?? this.repeatMode,
    lastPayLaterRule: lastPayLaterRule.present
        ? lastPayLaterRule.value
        : this.lastPayLaterRule,
    lastPayLaterValue: lastPayLaterValue.present
        ? lastPayLaterValue.value
        : this.lastPayLaterValue,
    lastAmountEntry: lastAmountEntry.present
        ? lastAmountEntry.value
        : this.lastAmountEntry,
    paydaySummaryEnabled: paydaySummaryEnabled ?? this.paydaySummaryEnabled,
    holidayCountry: holidayCountry.present
        ? holidayCountry.value
        : this.holidayCountry,
    appliedHolidays: appliedHolidays.present
        ? appliedHolidays.value
        : this.appliedHolidays,
  );
  SettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      localeCode: data.localeCode.present
          ? data.localeCode.value
          : this.localeCode,
      payFrequency: data.payFrequency.present
          ? data.payFrequency.value
          : this.payFrequency,
      payDay: data.payDay.present ? data.payDay.value : this.payDay,
      payAnchorDay: data.payAnchorDay.present
          ? data.payAnchorDay.value
          : this.payAnchorDay,
      netIncomeMinor: data.netIncomeMinor.present
          ? data.netIncomeMinor.value
          : this.netIncomeMinor,
      tightThresholdMinor: data.tightThresholdMinor.present
          ? data.tightThresholdMinor.value
          : this.tightThresholdMinor,
      debugPro: data.debugPro.present ? data.debugPro.value : this.debugPro,
      remindersEnabled: data.remindersEnabled.present
          ? data.remindersEnabled.value
          : this.remindersEnabled,
      reminderLeadDays: data.reminderLeadDays.present
          ? data.reminderLeadDays.value
          : this.reminderLeadDays,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      hideAmountsInNotifications: data.hideAmountsInNotifications.present
          ? data.hideAmountsInNotifications.value
          : this.hideAmountsInNotifications,
      reminderPromptShown: data.reminderPromptShown.present
          ? data.reminderPromptShown.value
          : this.reminderPromptShown,
      repeatMode: data.repeatMode.present
          ? data.repeatMode.value
          : this.repeatMode,
      lastPayLaterRule: data.lastPayLaterRule.present
          ? data.lastPayLaterRule.value
          : this.lastPayLaterRule,
      lastPayLaterValue: data.lastPayLaterValue.present
          ? data.lastPayLaterValue.value
          : this.lastPayLaterValue,
      lastAmountEntry: data.lastAmountEntry.present
          ? data.lastAmountEntry.value
          : this.lastAmountEntry,
      paydaySummaryEnabled: data.paydaySummaryEnabled.present
          ? data.paydaySummaryEnabled.value
          : this.paydaySummaryEnabled,
      holidayCountry: data.holidayCountry.present
          ? data.holidayCountry.value
          : this.holidayCountry,
      appliedHolidays: data.appliedHolidays.present
          ? data.appliedHolidays.value
          : this.appliedHolidays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('localeCode: $localeCode, ')
          ..write('payFrequency: $payFrequency, ')
          ..write('payDay: $payDay, ')
          ..write('payAnchorDay: $payAnchorDay, ')
          ..write('netIncomeMinor: $netIncomeMinor, ')
          ..write('tightThresholdMinor: $tightThresholdMinor, ')
          ..write('debugPro: $debugPro, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('reminderLeadDays: $reminderLeadDays, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('hideAmountsInNotifications: $hideAmountsInNotifications, ')
          ..write('reminderPromptShown: $reminderPromptShown, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('lastPayLaterRule: $lastPayLaterRule, ')
          ..write('lastPayLaterValue: $lastPayLaterValue, ')
          ..write('lastAmountEntry: $lastAmountEntry, ')
          ..write('paydaySummaryEnabled: $paydaySummaryEnabled, ')
          ..write('holidayCountry: $holidayCountry, ')
          ..write('appliedHolidays: $appliedHolidays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    currencyCode,
    localeCode,
    payFrequency,
    payDay,
    payAnchorDay,
    netIncomeMinor,
    tightThresholdMinor,
    debugPro,
    remindersEnabled,
    reminderLeadDays,
    reminderMinute,
    hideAmountsInNotifications,
    reminderPromptShown,
    repeatMode,
    lastPayLaterRule,
    lastPayLaterValue,
    lastAmountEntry,
    paydaySummaryEnabled,
    holidayCountry,
    appliedHolidays,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.currencyCode == this.currencyCode &&
          other.localeCode == this.localeCode &&
          other.payFrequency == this.payFrequency &&
          other.payDay == this.payDay &&
          other.payAnchorDay == this.payAnchorDay &&
          other.netIncomeMinor == this.netIncomeMinor &&
          other.tightThresholdMinor == this.tightThresholdMinor &&
          other.debugPro == this.debugPro &&
          other.remindersEnabled == this.remindersEnabled &&
          other.reminderLeadDays == this.reminderLeadDays &&
          other.reminderMinute == this.reminderMinute &&
          other.hideAmountsInNotifications == this.hideAmountsInNotifications &&
          other.reminderPromptShown == this.reminderPromptShown &&
          other.repeatMode == this.repeatMode &&
          other.lastPayLaterRule == this.lastPayLaterRule &&
          other.lastPayLaterValue == this.lastPayLaterValue &&
          other.lastAmountEntry == this.lastAmountEntry &&
          other.paydaySummaryEnabled == this.paydaySummaryEnabled &&
          other.holidayCountry == this.holidayCountry &&
          other.appliedHolidays == this.appliedHolidays);
}

class AppSettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> currencyCode;
  final Value<String?> localeCode;
  final Value<PayFrequency> payFrequency;
  final Value<int?> payDay;
  final Value<int?> payAnchorDay;
  final Value<int?> netIncomeMinor;
  final Value<int?> tightThresholdMinor;
  final Value<bool> debugPro;
  final Value<bool> remindersEnabled;
  final Value<int> reminderLeadDays;
  final Value<int> reminderMinute;
  final Value<bool> hideAmountsInNotifications;
  final Value<bool> reminderPromptShown;
  final Value<ReminderRepeat> repeatMode;
  final Value<PayLaterRuleKind?> lastPayLaterRule;
  final Value<int?> lastPayLaterValue;
  final Value<AmountEntry?> lastAmountEntry;
  final Value<bool> paydaySummaryEnabled;
  final Value<String?> holidayCountry;
  final Value<String?> appliedHolidays;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.localeCode = const Value.absent(),
    this.payFrequency = const Value.absent(),
    this.payDay = const Value.absent(),
    this.payAnchorDay = const Value.absent(),
    this.netIncomeMinor = const Value.absent(),
    this.tightThresholdMinor = const Value.absent(),
    this.debugPro = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.reminderLeadDays = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.hideAmountsInNotifications = const Value.absent(),
    this.reminderPromptShown = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.lastPayLaterRule = const Value.absent(),
    this.lastPayLaterValue = const Value.absent(),
    this.lastAmountEntry = const Value.absent(),
    this.paydaySummaryEnabled = const Value.absent(),
    this.holidayCountry = const Value.absent(),
    this.appliedHolidays = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String currencyCode,
    this.localeCode = const Value.absent(),
    required PayFrequency payFrequency,
    this.payDay = const Value.absent(),
    this.payAnchorDay = const Value.absent(),
    this.netIncomeMinor = const Value.absent(),
    this.tightThresholdMinor = const Value.absent(),
    this.debugPro = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.reminderLeadDays = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.hideAmountsInNotifications = const Value.absent(),
    this.reminderPromptShown = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.lastPayLaterRule = const Value.absent(),
    this.lastPayLaterValue = const Value.absent(),
    this.lastAmountEntry = const Value.absent(),
    this.paydaySummaryEnabled = const Value.absent(),
    this.holidayCountry = const Value.absent(),
    this.appliedHolidays = const Value.absent(),
  }) : currencyCode = Value(currencyCode),
       payFrequency = Value(payFrequency);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? currencyCode,
    Expression<String>? localeCode,
    Expression<String>? payFrequency,
    Expression<int>? payDay,
    Expression<int>? payAnchorDay,
    Expression<int>? netIncomeMinor,
    Expression<int>? tightThresholdMinor,
    Expression<bool>? debugPro,
    Expression<bool>? remindersEnabled,
    Expression<int>? reminderLeadDays,
    Expression<int>? reminderMinute,
    Expression<bool>? hideAmountsInNotifications,
    Expression<bool>? reminderPromptShown,
    Expression<int>? repeatMode,
    Expression<String>? lastPayLaterRule,
    Expression<int>? lastPayLaterValue,
    Expression<String>? lastAmountEntry,
    Expression<bool>? paydaySummaryEnabled,
    Expression<String>? holidayCountry,
    Expression<String>? appliedHolidays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (localeCode != null) 'locale_code': localeCode,
      if (payFrequency != null) 'pay_frequency': payFrequency,
      if (payDay != null) 'pay_day': payDay,
      if (payAnchorDay != null) 'pay_anchor_day': payAnchorDay,
      if (netIncomeMinor != null) 'net_income_minor': netIncomeMinor,
      if (tightThresholdMinor != null)
        'tight_threshold_minor': tightThresholdMinor,
      if (debugPro != null) 'debug_pro': debugPro,
      if (remindersEnabled != null) 'reminders_enabled': remindersEnabled,
      if (reminderLeadDays != null) 'reminder_lead_days': reminderLeadDays,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (hideAmountsInNotifications != null)
        'hide_amounts_in_notifications': hideAmountsInNotifications,
      if (reminderPromptShown != null)
        'reminder_prompt_shown': reminderPromptShown,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (lastPayLaterRule != null) 'last_pay_later_rule': lastPayLaterRule,
      if (lastPayLaterValue != null) 'last_pay_later_value': lastPayLaterValue,
      if (lastAmountEntry != null) 'last_amount_entry': lastAmountEntry,
      if (paydaySummaryEnabled != null)
        'payday_summary_enabled': paydaySummaryEnabled,
      if (holidayCountry != null) 'holiday_country': holidayCountry,
      if (appliedHolidays != null) 'applied_holidays': appliedHolidays,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? currencyCode,
    Value<String?>? localeCode,
    Value<PayFrequency>? payFrequency,
    Value<int?>? payDay,
    Value<int?>? payAnchorDay,
    Value<int?>? netIncomeMinor,
    Value<int?>? tightThresholdMinor,
    Value<bool>? debugPro,
    Value<bool>? remindersEnabled,
    Value<int>? reminderLeadDays,
    Value<int>? reminderMinute,
    Value<bool>? hideAmountsInNotifications,
    Value<bool>? reminderPromptShown,
    Value<ReminderRepeat>? repeatMode,
    Value<PayLaterRuleKind?>? lastPayLaterRule,
    Value<int?>? lastPayLaterValue,
    Value<AmountEntry?>? lastAmountEntry,
    Value<bool>? paydaySummaryEnabled,
    Value<String?>? holidayCountry,
    Value<String?>? appliedHolidays,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      localeCode: localeCode ?? this.localeCode,
      payFrequency: payFrequency ?? this.payFrequency,
      payDay: payDay ?? this.payDay,
      payAnchorDay: payAnchorDay ?? this.payAnchorDay,
      netIncomeMinor: netIncomeMinor ?? this.netIncomeMinor,
      tightThresholdMinor: tightThresholdMinor ?? this.tightThresholdMinor,
      debugPro: debugPro ?? this.debugPro,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      hideAmountsInNotifications:
          hideAmountsInNotifications ?? this.hideAmountsInNotifications,
      reminderPromptShown: reminderPromptShown ?? this.reminderPromptShown,
      repeatMode: repeatMode ?? this.repeatMode,
      lastPayLaterRule: lastPayLaterRule ?? this.lastPayLaterRule,
      lastPayLaterValue: lastPayLaterValue ?? this.lastPayLaterValue,
      lastAmountEntry: lastAmountEntry ?? this.lastAmountEntry,
      paydaySummaryEnabled: paydaySummaryEnabled ?? this.paydaySummaryEnabled,
      holidayCountry: holidayCountry ?? this.holidayCountry,
      appliedHolidays: appliedHolidays ?? this.appliedHolidays,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (localeCode.present) {
      map['locale_code'] = Variable<String>(localeCode.value);
    }
    if (payFrequency.present) {
      map['pay_frequency'] = Variable<String>(
        $AppSettingsTable.$converterpayFrequency.toSql(payFrequency.value),
      );
    }
    if (payDay.present) {
      map['pay_day'] = Variable<int>(payDay.value);
    }
    if (payAnchorDay.present) {
      map['pay_anchor_day'] = Variable<int>(payAnchorDay.value);
    }
    if (netIncomeMinor.present) {
      map['net_income_minor'] = Variable<int>(netIncomeMinor.value);
    }
    if (tightThresholdMinor.present) {
      map['tight_threshold_minor'] = Variable<int>(tightThresholdMinor.value);
    }
    if (debugPro.present) {
      map['debug_pro'] = Variable<bool>(debugPro.value);
    }
    if (remindersEnabled.present) {
      map['reminders_enabled'] = Variable<bool>(remindersEnabled.value);
    }
    if (reminderLeadDays.present) {
      map['reminder_lead_days'] = Variable<int>(reminderLeadDays.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (hideAmountsInNotifications.present) {
      map['hide_amounts_in_notifications'] = Variable<bool>(
        hideAmountsInNotifications.value,
      );
    }
    if (reminderPromptShown.present) {
      map['reminder_prompt_shown'] = Variable<bool>(reminderPromptShown.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<int>(
        $AppSettingsTable.$converterrepeatMode.toSql(repeatMode.value),
      );
    }
    if (lastPayLaterRule.present) {
      map['last_pay_later_rule'] = Variable<String>(
        $AppSettingsTable.$converterlastPayLaterRulen.toSql(
          lastPayLaterRule.value,
        ),
      );
    }
    if (lastPayLaterValue.present) {
      map['last_pay_later_value'] = Variable<int>(lastPayLaterValue.value);
    }
    if (lastAmountEntry.present) {
      map['last_amount_entry'] = Variable<String>(
        $AppSettingsTable.$converterlastAmountEntryn.toSql(
          lastAmountEntry.value,
        ),
      );
    }
    if (paydaySummaryEnabled.present) {
      map['payday_summary_enabled'] = Variable<bool>(
        paydaySummaryEnabled.value,
      );
    }
    if (holidayCountry.present) {
      map['holiday_country'] = Variable<String>(holidayCountry.value);
    }
    if (appliedHolidays.present) {
      map['applied_holidays'] = Variable<String>(appliedHolidays.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('localeCode: $localeCode, ')
          ..write('payFrequency: $payFrequency, ')
          ..write('payDay: $payDay, ')
          ..write('payAnchorDay: $payAnchorDay, ')
          ..write('netIncomeMinor: $netIncomeMinor, ')
          ..write('tightThresholdMinor: $tightThresholdMinor, ')
          ..write('debugPro: $debugPro, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('reminderLeadDays: $reminderLeadDays, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('hideAmountsInNotifications: $hideAmountsInNotifications, ')
          ..write('reminderPromptShown: $reminderPromptShown, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('lastPayLaterRule: $lastPayLaterRule, ')
          ..write('lastPayLaterValue: $lastPayLaterValue, ')
          ..write('lastAmountEntry: $lastAmountEntry, ')
          ..write('paydaySummaryEnabled: $paydaySummaryEnabled, ')
          ..write('holidayCountry: $holidayCountry, ')
          ..write('appliedHolidays: $appliedHolidays')
          ..write(')'))
        .toString();
  }
}

class $ReminderSnoozesTable extends ReminderSnoozes
    with TableInfo<$ReminderSnoozesTable, ReminderSnoozeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderSnoozesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(const [0, 1, 2]),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fireDayMeta = const VerificationMeta(
    'fireDay',
  );
  @override
  late final GeneratedColumn<int> fireDay = GeneratedColumn<int>(
    'fire_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteOfDayMeta = const VerificationMeta(
    'minuteOfDay',
  );
  @override
  late final GeneratedColumn<int> minuteOfDay = GeneratedColumn<int>(
    'minute_of_day',
    aliasedName,
    false,
    check: () => ComparableExpr(minuteOfDay).isBetweenValues(0, 1439),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refsMeta = const VerificationMeta('refs');
  @override
  late final GeneratedColumn<String> refs = GeneratedColumn<String>(
    'refs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skipsDayMeta = const VerificationMeta(
    'skipsDay',
  );
  @override
  late final GeneratedColumn<bool> skipsDay = GeneratedColumn<bool>(
    'skips_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("skips_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    fireDay,
    minuteOfDay,
    refs,
    skipsDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_snoozes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderSnoozeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('fire_day')) {
      context.handle(
        _fireDayMeta,
        fireDay.isAcceptableOrUnknown(data['fire_day']!, _fireDayMeta),
      );
    } else if (isInserting) {
      context.missing(_fireDayMeta);
    }
    if (data.containsKey('minute_of_day')) {
      context.handle(
        _minuteOfDayMeta,
        minuteOfDay.isAcceptableOrUnknown(
          data['minute_of_day']!,
          _minuteOfDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minuteOfDayMeta);
    }
    if (data.containsKey('refs')) {
      context.handle(
        _refsMeta,
        refs.isAcceptableOrUnknown(data['refs']!, _refsMeta),
      );
    } else if (isInserting) {
      context.missing(_refsMeta);
    }
    if (data.containsKey('skips_day')) {
      context.handle(
        _skipsDayMeta,
        skipsDay.isAcceptableOrUnknown(data['skips_day']!, _skipsDayMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {kind, fireDay, minuteOfDay, refs},
  ];
  @override
  ReminderSnoozeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderSnoozeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
      fireDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fire_day'],
      )!,
      minuteOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute_of_day'],
      )!,
      refs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refs'],
      )!,
      skipsDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}skips_day'],
      )!,
    );
  }

  @override
  $ReminderSnoozesTable createAlias(String alias) {
    return $ReminderSnoozesTable(attachedDatabase, alias);
  }
}

class ReminderSnoozeRow extends DataClass
    implements Insertable<ReminderSnoozeRow> {
  final int id;

  /// The kind of the notification it came from: 0 ahead, 1 on the day,
  /// 2 overdue (schema v7).
  final int kind;

  /// Local day and time it fires (epoch day, minutes after midnight).
  final int fireDay;
  final int minuteOfDay;

  /// The payments in it, as comma-separated keys ("p12,r3.20406").
  final String refs;

  /// "Remind tomorrow" with repeat reminders (schema v7): skips the rest
  /// of the day before [fireDay] instead of adding a reminder.
  final bool skipsDay;
  const ReminderSnoozeRow({
    required this.id,
    required this.kind,
    required this.fireDay,
    required this.minuteOfDay,
    required this.refs,
    required this.skipsDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<int>(kind);
    map['fire_day'] = Variable<int>(fireDay);
    map['minute_of_day'] = Variable<int>(minuteOfDay);
    map['refs'] = Variable<String>(refs);
    map['skips_day'] = Variable<bool>(skipsDay);
    return map;
  }

  ReminderSnoozesCompanion toCompanion(bool nullToAbsent) {
    return ReminderSnoozesCompanion(
      id: Value(id),
      kind: Value(kind),
      fireDay: Value(fireDay),
      minuteOfDay: Value(minuteOfDay),
      refs: Value(refs),
      skipsDay: Value(skipsDay),
    );
  }

  factory ReminderSnoozeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderSnoozeRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<int>(json['kind']),
      fireDay: serializer.fromJson<int>(json['fireDay']),
      minuteOfDay: serializer.fromJson<int>(json['minuteOfDay']),
      refs: serializer.fromJson<String>(json['refs']),
      skipsDay: serializer.fromJson<bool>(json['skipsDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<int>(kind),
      'fireDay': serializer.toJson<int>(fireDay),
      'minuteOfDay': serializer.toJson<int>(minuteOfDay),
      'refs': serializer.toJson<String>(refs),
      'skipsDay': serializer.toJson<bool>(skipsDay),
    };
  }

  ReminderSnoozeRow copyWith({
    int? id,
    int? kind,
    int? fireDay,
    int? minuteOfDay,
    String? refs,
    bool? skipsDay,
  }) => ReminderSnoozeRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    fireDay: fireDay ?? this.fireDay,
    minuteOfDay: minuteOfDay ?? this.minuteOfDay,
    refs: refs ?? this.refs,
    skipsDay: skipsDay ?? this.skipsDay,
  );
  ReminderSnoozeRow copyWithCompanion(ReminderSnoozesCompanion data) {
    return ReminderSnoozeRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      fireDay: data.fireDay.present ? data.fireDay.value : this.fireDay,
      minuteOfDay: data.minuteOfDay.present
          ? data.minuteOfDay.value
          : this.minuteOfDay,
      refs: data.refs.present ? data.refs.value : this.refs,
      skipsDay: data.skipsDay.present ? data.skipsDay.value : this.skipsDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderSnoozeRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('fireDay: $fireDay, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('refs: $refs, ')
          ..write('skipsDay: $skipsDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, fireDay, minuteOfDay, refs, skipsDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderSnoozeRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.fireDay == this.fireDay &&
          other.minuteOfDay == this.minuteOfDay &&
          other.refs == this.refs &&
          other.skipsDay == this.skipsDay);
}

class ReminderSnoozesCompanion extends UpdateCompanion<ReminderSnoozeRow> {
  final Value<int> id;
  final Value<int> kind;
  final Value<int> fireDay;
  final Value<int> minuteOfDay;
  final Value<String> refs;
  final Value<bool> skipsDay;
  const ReminderSnoozesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.fireDay = const Value.absent(),
    this.minuteOfDay = const Value.absent(),
    this.refs = const Value.absent(),
    this.skipsDay = const Value.absent(),
  });
  ReminderSnoozesCompanion.insert({
    this.id = const Value.absent(),
    required int kind,
    required int fireDay,
    required int minuteOfDay,
    required String refs,
    this.skipsDay = const Value.absent(),
  }) : kind = Value(kind),
       fireDay = Value(fireDay),
       minuteOfDay = Value(minuteOfDay),
       refs = Value(refs);
  static Insertable<ReminderSnoozeRow> custom({
    Expression<int>? id,
    Expression<int>? kind,
    Expression<int>? fireDay,
    Expression<int>? minuteOfDay,
    Expression<String>? refs,
    Expression<bool>? skipsDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (fireDay != null) 'fire_day': fireDay,
      if (minuteOfDay != null) 'minute_of_day': minuteOfDay,
      if (refs != null) 'refs': refs,
      if (skipsDay != null) 'skips_day': skipsDay,
    });
  }

  ReminderSnoozesCompanion copyWith({
    Value<int>? id,
    Value<int>? kind,
    Value<int>? fireDay,
    Value<int>? minuteOfDay,
    Value<String>? refs,
    Value<bool>? skipsDay,
  }) {
    return ReminderSnoozesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      fireDay: fireDay ?? this.fireDay,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      refs: refs ?? this.refs,
      skipsDay: skipsDay ?? this.skipsDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (fireDay.present) {
      map['fire_day'] = Variable<int>(fireDay.value);
    }
    if (minuteOfDay.present) {
      map['minute_of_day'] = Variable<int>(minuteOfDay.value);
    }
    if (refs.present) {
      map['refs'] = Variable<String>(refs.value);
    }
    if (skipsDay.present) {
      map['skips_day'] = Variable<bool>(skipsDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderSnoozesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('fireDay: $fireDay, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('refs: $refs, ')
          ..write('skipsDay: $skipsDay')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $RecurringPaymentsTable recurringPayments =
      $RecurringPaymentsTable(this);
  late final $RecurringMarksTable recurringMarks = $RecurringMarksTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ReminderSnoozesTable reminderSnoozes = $ReminderSnoozesTable(
    this,
  );
  late final Index paymentsDueDay = Index(
    'payments_due_day',
    'CREATE INDEX payments_due_day ON payments (due_day)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    plans,
    payments,
    recurringPayments,
    recurringMarks,
    appSettings,
    reminderSnoozes,
    paymentsDueDay,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plans', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recurring_payments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recurring_marks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SourcesTableCreateCompanionBuilder = SourcesCompanion Function({
  Value<int> id,
  required String name,
  required SourceKind kind,
  Value<int?> statementDay,
  Value<int?> dueDay,
  Value<bool> shiftDueToBusinessDay,
  Value<bool> shiftDueForHolidays,
  Value<DateTime> createdAt,
  Value<bool> statementReminderEnabled,
  Value<int> statementReminderDays,
});
typedef $$SourcesTableUpdateCompanionBuilder = SourcesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<SourceKind> kind,
  Value<int?> statementDay,
  Value<int?> dueDay,
  Value<bool> shiftDueToBusinessDay,
  Value<bool> shiftDueForHolidays,
  Value<DateTime> createdAt,
  Value<bool> statementReminderEnabled,
  Value<int> statementReminderDays,
});

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SourceKind, SourceKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shiftDueToBusinessDay => $composableBuilder(
    column: $table.shiftDueToBusinessDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shiftDueForHolidays => $composableBuilder(
    column: $table.shiftDueForHolidays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get statementReminderEnabled => $composableBuilder(
    column: $table.statementReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statementReminderDays => $composableBuilder(
    column: $table.statementReminderDays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shiftDueToBusinessDay => $composableBuilder(
    column: $table.shiftDueToBusinessDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shiftDueForHolidays => $composableBuilder(
    column: $table.shiftDueForHolidays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get statementReminderEnabled => $composableBuilder(
    column: $table.statementReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statementReminderDays => $composableBuilder(
    column: $table.statementReminderDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<SourceKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get statementDay => $composableBuilder(
    column: $table.statementDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<bool> get shiftDueToBusinessDay => $composableBuilder(
    column: $table.shiftDueToBusinessDay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get shiftDueForHolidays => $composableBuilder(
    column: $table.shiftDueForHolidays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get statementReminderEnabled => $composableBuilder(
    column: $table.statementReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statementReminderDays => $composableBuilder(
    column: $table.statementReminderDays,
    builder: (column) => column,
  );
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcesTable,
          SourceRow,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (SourceRow, BaseReferences<_$AppDatabase, $SourcesTable, SourceRow>),
          SourceRow,
          PrefetchHooks Function()
        > {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<SourceKind> kind = const Value.absent(),
                Value<int?> statementDay = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<bool> shiftDueToBusinessDay = const Value.absent(),
                Value<bool> shiftDueForHolidays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> statementReminderEnabled = const Value.absent(),
                Value<int> statementReminderDays = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                name: name,
                kind: kind,
                statementDay: statementDay,
                dueDay: dueDay,
                shiftDueToBusinessDay: shiftDueToBusinessDay,
                shiftDueForHolidays: shiftDueForHolidays,
                createdAt: createdAt,
                statementReminderEnabled: statementReminderEnabled,
                statementReminderDays: statementReminderDays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required SourceKind kind,
                Value<int?> statementDay = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<bool> shiftDueToBusinessDay = const Value.absent(),
                Value<bool> shiftDueForHolidays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> statementReminderEnabled = const Value.absent(),
                Value<int> statementReminderDays = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                statementDay: statementDay,
                dueDay: dueDay,
                shiftDueToBusinessDay: shiftDueToBusinessDay,
                shiftDueForHolidays: shiftDueForHolidays,
                createdAt: createdAt,
                statementReminderEnabled: statementReminderEnabled,
                statementReminderDays: statementReminderDays,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourcesTable, SourceRow>(table),
                  BaseReferences<_$AppDatabase, $SourcesTable, SourceRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcesTable,
      SourceRow,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (SourceRow, BaseReferences<_$AppDatabase, $SourcesTable, SourceRow>),
      SourceRow,
      PrefetchHooks Function()
    >;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  Value<int?> sourceId,
  Value<String?> title,
  required PlanKind kind,
  required int installmentCount,
  Value<int?> purchaseDay,
  Value<int> deferMonths,
  Value<bool> isCashAdvance,
  required PlanOrigin origin,
  Value<DateTime> createdAt,
  Value<bool> remindersEnabled,
  Value<int?> reminderLeadDays,
  Value<ReminderRepeat?> repeatMode,
  Value<PayLaterRuleKind?> payLaterRule,
  Value<int?> payLaterValue,
  Value<int?> intervalDays,
  Value<PaymentMethod?> paymentMethod,
  Value<int?> chargeSourceId,
  Value<PlanStatus> status,
  Value<CloseReason?> closeReason,
  Value<int?> heldSinceDay,
  Value<int?> holdCheckDay,
  Value<int?> reopenedDay,
  Value<int?> closedDay,
  Value<int?> installmentFeeMinor,
  Value<InstallmentFeeScope> installmentFeeScope,
  Value<int?> productPriceMinor,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  Value<int?> sourceId,
  Value<String?> title,
  Value<PlanKind> kind,
  Value<int> installmentCount,
  Value<int?> purchaseDay,
  Value<int> deferMonths,
  Value<bool> isCashAdvance,
  Value<PlanOrigin> origin,
  Value<DateTime> createdAt,
  Value<bool> remindersEnabled,
  Value<int?> reminderLeadDays,
  Value<ReminderRepeat?> repeatMode,
  Value<PayLaterRuleKind?> payLaterRule,
  Value<int?> payLaterValue,
  Value<int?> intervalDays,
  Value<PaymentMethod?> paymentMethod,
  Value<int?> chargeSourceId,
  Value<PlanStatus> status,
  Value<CloseReason?> closeReason,
  Value<int?> heldSinceDay,
  Value<int?> holdCheckDay,
  Value<int?> reopenedDay,
  Value<int?> closedDay,
  Value<int?> installmentFeeMinor,
  Value<InstallmentFeeScope> installmentFeeScope,
  Value<int?> productPriceMinor,
});

final class $$PlansTableReferences
    extends BaseReferences<_$AppDatabase, $PlansTable, PlanRow> {
  $$PlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias('plans__source_id__sources__id');

  $$SourcesTableProcessedTableManager? get sourceId {
    final $_column = $_itemColumn<int>('source_id');
    if ($_column == null) return null;
    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SourcesTable _chargeSourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias('plans__charge_source_id__sources__id');

  $$SourcesTableProcessedTableManager? get chargeSourceId {
    final $_column = $_itemColumn<int>('charge_source_id');
    if ($_column == null) return null;
    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chargeSourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PaymentsTable, List<PaymentRow>>
  _paymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.payments,
    aliasName: 'plans__id__payments__plan_id',
  );

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager(
      $_db,
      $_db.payments,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlanKind, PlanKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchaseDay => $composableBuilder(
    column: $table.purchaseDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deferMonths => $composableBuilder(
    column: $table.deferMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCashAdvance => $composableBuilder(
    column: $table.isCashAdvance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlanOrigin, PlanOrigin, String> get origin =>
      $composableBuilder(
        column: $table.origin,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderLeadDays => $composableBuilder(
    column: $table.reminderLeadDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderRepeat?, ReminderRepeat, int>
  get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PayLaterRuleKind?, PayLaterRuleKind, String>
  get payLaterRule => $composableBuilder(
    column: $table.payLaterRule,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get payLaterValue => $composableBuilder(
    column: $table.payLaterValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PaymentMethod?, PaymentMethod, String>
  get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PlanStatus, PlanStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<CloseReason?, CloseReason, String>
  get closeReason => $composableBuilder(
    column: $table.closeReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get heldSinceDay => $composableBuilder(
    column: $table.heldSinceDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get holdCheckDay => $composableBuilder(
    column: $table.holdCheckDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reopenedDay => $composableBuilder(
    column: $table.reopenedDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closedDay => $composableBuilder(
    column: $table.closedDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentFeeMinor => $composableBuilder(
    column: $table.installmentFeeMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    InstallmentFeeScope,
    InstallmentFeeScope,
    String
  >
  get installmentFeeScope => $composableBuilder(
    column: $table.installmentFeeScope,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get productPriceMinor => $composableBuilder(
    column: $table.productPriceMinor,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SourcesTableFilterComposer get chargeSourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chargeSourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> paymentsRefs(
    Expression<bool> Function($$PaymentsTableFilterComposer f) f,
  ) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableFilterComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchaseDay => $composableBuilder(
    column: $table.purchaseDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deferMonths => $composableBuilder(
    column: $table.deferMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCashAdvance => $composableBuilder(
    column: $table.isCashAdvance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderLeadDays => $composableBuilder(
    column: $table.reminderLeadDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payLaterRule => $composableBuilder(
    column: $table.payLaterRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payLaterValue => $composableBuilder(
    column: $table.payLaterValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closeReason => $composableBuilder(
    column: $table.closeReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heldSinceDay => $composableBuilder(
    column: $table.heldSinceDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get holdCheckDay => $composableBuilder(
    column: $table.holdCheckDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reopenedDay => $composableBuilder(
    column: $table.reopenedDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closedDay => $composableBuilder(
    column: $table.closedDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentFeeMinor => $composableBuilder(
    column: $table.installmentFeeMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installmentFeeScope => $composableBuilder(
    column: $table.installmentFeeScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productPriceMinor => $composableBuilder(
    column: $table.productPriceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SourcesTableOrderingComposer get chargeSourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chargeSourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlanKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchaseDay => $composableBuilder(
    column: $table.purchaseDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deferMonths => $composableBuilder(
    column: $table.deferMonths,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCashAdvance => $composableBuilder(
    column: $table.isCashAdvance,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PlanOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderLeadDays => $composableBuilder(
    column: $table.reminderLeadDays,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReminderRepeat?, int> get repeatMode =>
      $composableBuilder(
        column: $table.repeatMode,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<PayLaterRuleKind?, String>
  get payLaterRule => $composableBuilder(
    column: $table.payLaterRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get payLaterValue => $composableBuilder(
    column: $table.payLaterValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PaymentMethod?, String> get paymentMethod =>
      $composableBuilder(
        column: $table.paymentMethod,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<PlanStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CloseReason?, String> get closeReason =>
      $composableBuilder(
        column: $table.closeReason,
        builder: (column) => column,
      );

  GeneratedColumn<int> get heldSinceDay => $composableBuilder(
    column: $table.heldSinceDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get holdCheckDay => $composableBuilder(
    column: $table.holdCheckDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reopenedDay => $composableBuilder(
    column: $table.reopenedDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closedDay =>
      $composableBuilder(column: $table.closedDay, builder: (column) => column);

  GeneratedColumn<int> get installmentFeeMinor => $composableBuilder(
    column: $table.installmentFeeMinor,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<InstallmentFeeScope, String>
  get installmentFeeScope => $composableBuilder(
    column: $table.installmentFeeScope,
    builder: (column) => column,
  );

  GeneratedColumn<int> get productPriceMinor => $composableBuilder(
    column: $table.productPriceMinor,
    builder: (column) => column,
  );

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SourcesTableAnnotationComposer get chargeSourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chargeSourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> paymentsRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlansTable,
          PlanRow,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (PlanRow, $$PlansTableReferences),
          PlanRow,
          PrefetchHooks Function({
            bool sourceId,
            bool chargeSourceId,
            bool paymentsRefs,
          })
        > {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sourceId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<PlanKind> kind = const Value.absent(),
                Value<int> installmentCount = const Value.absent(),
                Value<int?> purchaseDay = const Value.absent(),
                Value<int> deferMonths = const Value.absent(),
                Value<bool> isCashAdvance = const Value.absent(),
                Value<PlanOrigin> origin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<int?> reminderLeadDays = const Value.absent(),
                Value<ReminderRepeat?> repeatMode = const Value.absent(),
                Value<PayLaterRuleKind?> payLaterRule = const Value.absent(),
                Value<int?> payLaterValue = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<PaymentMethod?> paymentMethod = const Value.absent(),
                Value<int?> chargeSourceId = const Value.absent(),
                Value<PlanStatus> status = const Value.absent(),
                Value<CloseReason?> closeReason = const Value.absent(),
                Value<int?> heldSinceDay = const Value.absent(),
                Value<int?> holdCheckDay = const Value.absent(),
                Value<int?> reopenedDay = const Value.absent(),
                Value<int?> closedDay = const Value.absent(),
                Value<int?> installmentFeeMinor = const Value.absent(),
                Value<InstallmentFeeScope> installmentFeeScope =
                    const Value.absent(),
                Value<int?> productPriceMinor = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                sourceId: sourceId,
                title: title,
                kind: kind,
                installmentCount: installmentCount,
                purchaseDay: purchaseDay,
                deferMonths: deferMonths,
                isCashAdvance: isCashAdvance,
                origin: origin,
                createdAt: createdAt,
                remindersEnabled: remindersEnabled,
                reminderLeadDays: reminderLeadDays,
                repeatMode: repeatMode,
                payLaterRule: payLaterRule,
                payLaterValue: payLaterValue,
                intervalDays: intervalDays,
                paymentMethod: paymentMethod,
                chargeSourceId: chargeSourceId,
                status: status,
                closeReason: closeReason,
                heldSinceDay: heldSinceDay,
                holdCheckDay: holdCheckDay,
                reopenedDay: reopenedDay,
                closedDay: closedDay,
                installmentFeeMinor: installmentFeeMinor,
                installmentFeeScope: installmentFeeScope,
                productPriceMinor: productPriceMinor,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sourceId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required PlanKind kind,
                required int installmentCount,
                Value<int?> purchaseDay = const Value.absent(),
                Value<int> deferMonths = const Value.absent(),
                Value<bool> isCashAdvance = const Value.absent(),
                required PlanOrigin origin,
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<int?> reminderLeadDays = const Value.absent(),
                Value<ReminderRepeat?> repeatMode = const Value.absent(),
                Value<PayLaterRuleKind?> payLaterRule = const Value.absent(),
                Value<int?> payLaterValue = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<PaymentMethod?> paymentMethod = const Value.absent(),
                Value<int?> chargeSourceId = const Value.absent(),
                Value<PlanStatus> status = const Value.absent(),
                Value<CloseReason?> closeReason = const Value.absent(),
                Value<int?> heldSinceDay = const Value.absent(),
                Value<int?> holdCheckDay = const Value.absent(),
                Value<int?> reopenedDay = const Value.absent(),
                Value<int?> closedDay = const Value.absent(),
                Value<int?> installmentFeeMinor = const Value.absent(),
                Value<InstallmentFeeScope> installmentFeeScope =
                    const Value.absent(),
                Value<int?> productPriceMinor = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                sourceId: sourceId,
                title: title,
                kind: kind,
                installmentCount: installmentCount,
                purchaseDay: purchaseDay,
                deferMonths: deferMonths,
                isCashAdvance: isCashAdvance,
                origin: origin,
                createdAt: createdAt,
                remindersEnabled: remindersEnabled,
                reminderLeadDays: reminderLeadDays,
                repeatMode: repeatMode,
                payLaterRule: payLaterRule,
                payLaterValue: payLaterValue,
                intervalDays: intervalDays,
                paymentMethod: paymentMethod,
                chargeSourceId: chargeSourceId,
                status: status,
                closeReason: closeReason,
                heldSinceDay: heldSinceDay,
                holdCheckDay: holdCheckDay,
                reopenedDay: reopenedDay,
                closedDay: closedDay,
                installmentFeeMinor: installmentFeeMinor,
                installmentFeeScope: installmentFeeScope,
                productPriceMinor: productPriceMinor,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlansTable, PlanRow>(table),
                  $$PlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourceId = false,
                chargeSourceId = false,
                paymentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (paymentsRefs) db.payments],
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
                        if (sourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceId,
                            referencedTable: $$PlansTableReferences
                                ._sourceIdTable(db),
                            referencedColumn: $$PlansTableReferences
                                ._sourceIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (chargeSourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.chargeSourceId,
                            referencedTable: $$PlansTableReferences
                                ._chargeSourceIdTable(db),
                            referencedColumn: $$PlansTableReferences
                                ._chargeSourceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (paymentsRefs)
                        await $_getPrefetchedDataByColumns<
                          PlanRow,
                          $PlansTable,
                          PaymentRow,
                          $PaymentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$PlansTableReferences
                              ._paymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlansTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'plan_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlansTable,
      PlanRow,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (PlanRow, $$PlansTableReferences),
      PlanRow,
      PrefetchHooks Function({
        bool sourceId,
        bool chargeSourceId,
        bool paymentsRefs,
      })
    >;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  required int planId,
  required int seq,
  required int dueDay,
  required int amountMinor,
  Value<DateTime?> paidAt,
  Value<bool> isEdited,
  Value<bool> paidBeforeKalan,
  Value<int?> paidOnDay,
  Value<int?> originalDay,
  Value<int?> extraFeeMinor,
  Value<String?> extraFeeNote,
  Value<int?> installmentFeeMinor,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  Value<int> planId,
  Value<int> seq,
  Value<int> dueDay,
  Value<int> amountMinor,
  Value<DateTime?> paidAt,
  Value<bool> isEdited,
  Value<bool> paidBeforeKalan,
  Value<int?> paidOnDay,
  Value<int?> originalDay,
  Value<int?> extraFeeMinor,
  Value<String?> extraFeeNote,
  Value<int?> installmentFeeMinor,
});

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlansTable _planIdTable(_$AppDatabase db) =>
      db.plans.createAlias('payments__plan_id__plans__id');

  $$PlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$PlansTableTableManager(
      $_db,
      $_db.plans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
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

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEdited => $composableBuilder(
    column: $table.isEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paidBeforeKalan => $composableBuilder(
    column: $table.paidBeforeKalan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidOnDay => $composableBuilder(
    column: $table.paidOnDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalDay => $composableBuilder(
    column: $table.originalDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extraFeeMinor => $composableBuilder(
    column: $table.extraFeeMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraFeeNote => $composableBuilder(
    column: $table.extraFeeNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentFeeMinor => $composableBuilder(
    column: $table.installmentFeeMinor,
    builder: (column) => ColumnFilters(column),
  );

  $$PlansTableFilterComposer get planId {
    final $$PlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableFilterComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
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

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEdited => $composableBuilder(
    column: $table.isEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paidBeforeKalan => $composableBuilder(
    column: $table.paidBeforeKalan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidOnDay => $composableBuilder(
    column: $table.paidOnDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalDay => $composableBuilder(
    column: $table.originalDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extraFeeMinor => $composableBuilder(
    column: $table.extraFeeMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraFeeNote => $composableBuilder(
    column: $table.extraFeeNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentFeeMinor => $composableBuilder(
    column: $table.installmentFeeMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlansTableOrderingComposer get planId {
    final $$PlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableOrderingComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<bool> get isEdited =>
      $composableBuilder(column: $table.isEdited, builder: (column) => column);

  GeneratedColumn<bool> get paidBeforeKalan => $composableBuilder(
    column: $table.paidBeforeKalan,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidOnDay =>
      $composableBuilder(column: $table.paidOnDay, builder: (column) => column);

  GeneratedColumn<int> get originalDay => $composableBuilder(
    column: $table.originalDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extraFeeMinor => $composableBuilder(
    column: $table.extraFeeMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extraFeeNote => $composableBuilder(
    column: $table.extraFeeNote,
    builder: (column) => column,
  );

  GeneratedColumn<int> get installmentFeeMinor => $composableBuilder(
    column: $table.installmentFeeMinor,
    builder: (column) => column,
  );

  $$PlansTableAnnotationComposer get planId {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableAnnotationComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          PaymentRow,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (PaymentRow, $$PaymentsTableReferences),
          PaymentRow,
          PrefetchHooks Function({bool planId})
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> dueDay = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
                Value<bool> isEdited = const Value.absent(),
                Value<bool> paidBeforeKalan = const Value.absent(),
                Value<int?> paidOnDay = const Value.absent(),
                Value<int?> originalDay = const Value.absent(),
                Value<int?> extraFeeMinor = const Value.absent(),
                Value<String?> extraFeeNote = const Value.absent(),
                Value<int?> installmentFeeMinor = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                planId: planId,
                seq: seq,
                dueDay: dueDay,
                amountMinor: amountMinor,
                paidAt: paidAt,
                isEdited: isEdited,
                paidBeforeKalan: paidBeforeKalan,
                paidOnDay: paidOnDay,
                originalDay: originalDay,
                extraFeeMinor: extraFeeMinor,
                extraFeeNote: extraFeeNote,
                installmentFeeMinor: installmentFeeMinor,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required int seq,
                required int dueDay,
                required int amountMinor,
                Value<DateTime?> paidAt = const Value.absent(),
                Value<bool> isEdited = const Value.absent(),
                Value<bool> paidBeforeKalan = const Value.absent(),
                Value<int?> paidOnDay = const Value.absent(),
                Value<int?> originalDay = const Value.absent(),
                Value<int?> extraFeeMinor = const Value.absent(),
                Value<String?> extraFeeNote = const Value.absent(),
                Value<int?> installmentFeeMinor = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                planId: planId,
                seq: seq,
                dueDay: dueDay,
                amountMinor: amountMinor,
                paidAt: paidAt,
                isEdited: isEdited,
                paidBeforeKalan: paidBeforeKalan,
                paidOnDay: paidOnDay,
                originalDay: originalDay,
                extraFeeMinor: extraFeeMinor,
                extraFeeNote: extraFeeNote,
                installmentFeeMinor: installmentFeeMinor,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PaymentsTable, PaymentRow>(table),
                  $$PaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
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
                    if (planId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planId,
                        referencedTable: $$PaymentsTableReferences._planIdTable(
                          db,
                        ),
                        referencedColumn: $$PaymentsTableReferences
                            ._planIdTable(db)
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

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      PaymentRow,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (PaymentRow, $$PaymentsTableReferences),
      PaymentRow,
      PrefetchHooks Function({bool planId})
    >;
typedef $$RecurringPaymentsTableCreateCompanionBuilder =
    RecurringPaymentsCompanion Function({
      Value<int> id,
      required String name,
      required int amountMinor,
      required Recurrence recurrence,
      required int startDay,
      Value<int?> endDay,
      Value<DateTime> createdAt,
      Value<bool> remindersEnabled,
      Value<int?> reminderLeadDays,
      Value<ReminderRepeat?> repeatMode,
    });
typedef $$RecurringPaymentsTableUpdateCompanionBuilder =
    RecurringPaymentsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> amountMinor,
      Value<Recurrence> recurrence,
      Value<int> startDay,
      Value<int?> endDay,
      Value<DateTime> createdAt,
      Value<bool> remindersEnabled,
      Value<int?> reminderLeadDays,
      Value<ReminderRepeat?> repeatMode,
    });

final class $$RecurringPaymentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecurringPaymentsTable,
          RecurringPaymentRow
        > {
  $$RecurringPaymentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$RecurringMarksTable, List<RecurringMarkRow>>
  _recurringMarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recurringMarks,
    aliasName: 'recurring_payments__id__recurring_marks__recurring_id',
  );

  $$RecurringMarksTableProcessedTableManager get recurringMarksRefs {
    final manager = $$RecurringMarksTableTableManager(
      $_db,
      $_db.recurringMarks,
    ).filter((f) => f.recurringId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recurringMarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecurringPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringPaymentsTable> {
  $$RecurringPaymentsTableFilterComposer({
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

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Recurrence, Recurrence, String>
  get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endDay => $composableBuilder(
    column: $table.endDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderLeadDays => $composableBuilder(
    column: $table.reminderLeadDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderRepeat?, ReminderRepeat, int>
  get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  Expression<bool> recurringMarksRefs(
    Expression<bool> Function($$RecurringMarksTableFilterComposer f) f,
  ) {
    final $$RecurringMarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringMarks,
      getReferencedColumn: (t) => t.recurringId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringMarksTableFilterComposer(
            $db: $db,
            $table: $db.recurringMarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringPaymentsTable> {
  $$RecurringPaymentsTableOrderingComposer({
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

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDay => $composableBuilder(
    column: $table.endDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderLeadDays => $composableBuilder(
    column: $table.reminderLeadDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringPaymentsTable> {
  $$RecurringPaymentsTableAnnotationComposer({
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

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Recurrence, String> get recurrence =>
      $composableBuilder(
        column: $table.recurrence,
        builder: (column) => column,
      );

  GeneratedColumn<int> get startDay =>
      $composableBuilder(column: $table.startDay, builder: (column) => column);

  GeneratedColumn<int> get endDay =>
      $composableBuilder(column: $table.endDay, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderLeadDays => $composableBuilder(
    column: $table.reminderLeadDays,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReminderRepeat?, int> get repeatMode =>
      $composableBuilder(
        column: $table.repeatMode,
        builder: (column) => column,
      );

  Expression<T> recurringMarksRefs<T extends Object>(
    Expression<T> Function($$RecurringMarksTableAnnotationComposer a) f,
  ) {
    final $$RecurringMarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurringMarks,
      getReferencedColumn: (t) => t.recurringId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringMarksTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringMarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringPaymentsTable,
          RecurringPaymentRow,
          $$RecurringPaymentsTableFilterComposer,
          $$RecurringPaymentsTableOrderingComposer,
          $$RecurringPaymentsTableAnnotationComposer,
          $$RecurringPaymentsTableCreateCompanionBuilder,
          $$RecurringPaymentsTableUpdateCompanionBuilder,
          (RecurringPaymentRow, $$RecurringPaymentsTableReferences),
          RecurringPaymentRow,
          PrefetchHooks Function({bool recurringMarksRefs})
        > {
  $$RecurringPaymentsTableTableManager(
    _$AppDatabase db,
    $RecurringPaymentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringPaymentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<Recurrence> recurrence = const Value.absent(),
                Value<int> startDay = const Value.absent(),
                Value<int?> endDay = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<int?> reminderLeadDays = const Value.absent(),
                Value<ReminderRepeat?> repeatMode = const Value.absent(),
              }) => RecurringPaymentsCompanion(
                id: id,
                name: name,
                amountMinor: amountMinor,
                recurrence: recurrence,
                startDay: startDay,
                endDay: endDay,
                createdAt: createdAt,
                remindersEnabled: remindersEnabled,
                reminderLeadDays: reminderLeadDays,
                repeatMode: repeatMode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int amountMinor,
                required Recurrence recurrence,
                required int startDay,
                Value<int?> endDay = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<int?> reminderLeadDays = const Value.absent(),
                Value<ReminderRepeat?> repeatMode = const Value.absent(),
              }) => RecurringPaymentsCompanion.insert(
                id: id,
                name: name,
                amountMinor: amountMinor,
                recurrence: recurrence,
                startDay: startDay,
                endDay: endDay,
                createdAt: createdAt,
                remindersEnabled: remindersEnabled,
                reminderLeadDays: reminderLeadDays,
                repeatMode: repeatMode,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringPaymentsTable, RecurringPaymentRow>(
                    table,
                  ),
                  $$RecurringPaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recurringMarksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recurringMarksRefs) db.recurringMarks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recurringMarksRefs)
                    await $_getPrefetchedDataByColumns<
                      RecurringPaymentRow,
                      $RecurringPaymentsTable,
                      RecurringMarkRow,
                      $RecurringMarksTable
                    >(
                      currentTable: table,
                      referencedTable: $$RecurringPaymentsTableReferences
                          ._recurringMarksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecurringPaymentsTableReferences(
                            db,
                            table,
                            p0,
                          ).recurringMarksRefs,
                      currentColumn: 'id',
                      referencedColumn: 'recurring_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecurringPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringPaymentsTable,
      RecurringPaymentRow,
      $$RecurringPaymentsTableFilterComposer,
      $$RecurringPaymentsTableOrderingComposer,
      $$RecurringPaymentsTableAnnotationComposer,
      $$RecurringPaymentsTableCreateCompanionBuilder,
      $$RecurringPaymentsTableUpdateCompanionBuilder,
      (RecurringPaymentRow, $$RecurringPaymentsTableReferences),
      RecurringPaymentRow,
      PrefetchHooks Function({bool recurringMarksRefs})
    >;
typedef $$RecurringMarksTableCreateCompanionBuilder =
    RecurringMarksCompanion Function({
      required int recurringId,
      required int occurrenceDay,
      required DateTime paidAt,
      Value<int> rowid,
    });
typedef $$RecurringMarksTableUpdateCompanionBuilder =
    RecurringMarksCompanion Function({
      Value<int> recurringId,
      Value<int> occurrenceDay,
      Value<DateTime> paidAt,
      Value<int> rowid,
    });

final class $$RecurringMarksTableReferences
    extends
        BaseReferences<_$AppDatabase, $RecurringMarksTable, RecurringMarkRow> {
  $$RecurringMarksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecurringPaymentsTable _recurringIdTable(_$AppDatabase db) => db
      .recurringPayments
      .createAlias('recurring_marks__recurring_id__recurring_payments__id');

  $$RecurringPaymentsTableProcessedTableManager get recurringId {
    final $_column = $_itemColumn<int>('recurring_id')!;

    final manager = $$RecurringPaymentsTableTableManager(
      $_db,
      $_db.recurringPayments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurringIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecurringMarksTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringMarksTable> {
  $$RecurringMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get occurrenceDay => $composableBuilder(
    column: $table.occurrenceDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RecurringPaymentsTableFilterComposer get recurringId {
    final $$RecurringPaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringId,
      referencedTable: $db.recurringPayments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringPaymentsTableFilterComposer(
            $db: $db,
            $table: $db.recurringPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringMarksTable> {
  $$RecurringMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get occurrenceDay => $composableBuilder(
    column: $table.occurrenceDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecurringPaymentsTableOrderingComposer get recurringId {
    final $$RecurringPaymentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringId,
      referencedTable: $db.recurringPayments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringPaymentsTableOrderingComposer(
            $db: $db,
            $table: $db.recurringPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurringMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringMarksTable> {
  $$RecurringMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get occurrenceDay => $composableBuilder(
    column: $table.occurrenceDay,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  $$RecurringPaymentsTableAnnotationComposer get recurringId {
    final $$RecurringPaymentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.recurringId,
          referencedTable: $db.recurringPayments,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecurringPaymentsTableAnnotationComposer(
                $db: $db,
                $table: $db.recurringPayments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$RecurringMarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringMarksTable,
          RecurringMarkRow,
          $$RecurringMarksTableFilterComposer,
          $$RecurringMarksTableOrderingComposer,
          $$RecurringMarksTableAnnotationComposer,
          $$RecurringMarksTableCreateCompanionBuilder,
          $$RecurringMarksTableUpdateCompanionBuilder,
          (RecurringMarkRow, $$RecurringMarksTableReferences),
          RecurringMarkRow,
          PrefetchHooks Function({bool recurringId})
        > {
  $$RecurringMarksTableTableManager(
    _$AppDatabase db,
    $RecurringMarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> recurringId = const Value.absent(),
                Value<int> occurrenceDay = const Value.absent(),
                Value<DateTime> paidAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringMarksCompanion(
                recurringId: recurringId,
                occurrenceDay: occurrenceDay,
                paidAt: paidAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int recurringId,
                required int occurrenceDay,
                required DateTime paidAt,
                Value<int> rowid = const Value.absent(),
              }) => RecurringMarksCompanion.insert(
                recurringId: recurringId,
                occurrenceDay: occurrenceDay,
                paidAt: paidAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringMarksTable, RecurringMarkRow>(table),
                  $$RecurringMarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recurringId = false}) {
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
                    if (recurringId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.recurringId,
                        referencedTable: $$RecurringMarksTableReferences
                            ._recurringIdTable(db),
                        referencedColumn: $$RecurringMarksTableReferences
                            ._recurringIdTable(db)
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

typedef $$RecurringMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringMarksTable,
      RecurringMarkRow,
      $$RecurringMarksTableFilterComposer,
      $$RecurringMarksTableOrderingComposer,
      $$RecurringMarksTableAnnotationComposer,
      $$RecurringMarksTableCreateCompanionBuilder,
      $$RecurringMarksTableUpdateCompanionBuilder,
      (RecurringMarkRow, $$RecurringMarksTableReferences),
      RecurringMarkRow,
      PrefetchHooks Function({bool recurringId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String currencyCode,
      Value<String?> localeCode,
      required PayFrequency payFrequency,
      Value<int?> payDay,
      Value<int?> payAnchorDay,
      Value<int?> netIncomeMinor,
      Value<int?> tightThresholdMinor,
      Value<bool> debugPro,
      Value<bool> remindersEnabled,
      Value<int> reminderLeadDays,
      Value<int> reminderMinute,
      Value<bool> hideAmountsInNotifications,
      Value<bool> reminderPromptShown,
      Value<ReminderRepeat> repeatMode,
      Value<PayLaterRuleKind?> lastPayLaterRule,
      Value<int?> lastPayLaterValue,
      Value<AmountEntry?> lastAmountEntry,
      Value<bool> paydaySummaryEnabled,
      Value<String?> holidayCountry,
      Value<String?> appliedHolidays,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> currencyCode,
      Value<String?> localeCode,
      Value<PayFrequency> payFrequency,
      Value<int?> payDay,
      Value<int?> payAnchorDay,
      Value<int?> netIncomeMinor,
      Value<int?> tightThresholdMinor,
      Value<bool> debugPro,
      Value<bool> remindersEnabled,
      Value<int> reminderLeadDays,
      Value<int> reminderMinute,
      Value<bool> hideAmountsInNotifications,
      Value<bool> reminderPromptShown,
      Value<ReminderRepeat> repeatMode,
      Value<PayLaterRuleKind?> lastPayLaterRule,
      Value<int?> lastPayLaterValue,
      Value<AmountEntry?> lastAmountEntry,
      Value<bool> paydaySummaryEnabled,
      Value<String?> holidayCountry,
      Value<String?> appliedHolidays,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PayFrequency, PayFrequency, String>
  get payFrequency => $composableBuilder(
    column: $table.payFrequency,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get payDay => $composableBuilder(
    column: $table.payDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payAnchorDay => $composableBuilder(
    column: $table.payAnchorDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get netIncomeMinor => $composableBuilder(
    column: $table.netIncomeMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tightThresholdMinor => $composableBuilder(
    column: $table.tightThresholdMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get debugPro => $composableBuilder(
    column: $table.debugPro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderLeadDays => $composableBuilder(
    column: $table.reminderLeadDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hideAmountsInNotifications => $composableBuilder(
    column: $table.hideAmountsInNotifications,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderPromptShown => $composableBuilder(
    column: $table.reminderPromptShown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderRepeat, ReminderRepeat, int>
  get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PayLaterRuleKind?, PayLaterRuleKind, String>
  get lastPayLaterRule => $composableBuilder(
    column: $table.lastPayLaterRule,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get lastPayLaterValue => $composableBuilder(
    column: $table.lastPayLaterValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AmountEntry?, AmountEntry, String>
  get lastAmountEntry => $composableBuilder(
    column: $table.lastAmountEntry,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get paydaySummaryEnabled => $composableBuilder(
    column: $table.paydaySummaryEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get holidayCountry => $composableBuilder(
    column: $table.holidayCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appliedHolidays => $composableBuilder(
    column: $table.appliedHolidays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payFrequency => $composableBuilder(
    column: $table.payFrequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payDay => $composableBuilder(
    column: $table.payDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payAnchorDay => $composableBuilder(
    column: $table.payAnchorDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get netIncomeMinor => $composableBuilder(
    column: $table.netIncomeMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tightThresholdMinor => $composableBuilder(
    column: $table.tightThresholdMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get debugPro => $composableBuilder(
    column: $table.debugPro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderLeadDays => $composableBuilder(
    column: $table.reminderLeadDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hideAmountsInNotifications => $composableBuilder(
    column: $table.hideAmountsInNotifications,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderPromptShown => $composableBuilder(
    column: $table.reminderPromptShown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastPayLaterRule => $composableBuilder(
    column: $table.lastPayLaterRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPayLaterValue => $composableBuilder(
    column: $table.lastPayLaterValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAmountEntry => $composableBuilder(
    column: $table.lastAmountEntry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paydaySummaryEnabled => $composableBuilder(
    column: $table.paydaySummaryEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get holidayCountry => $composableBuilder(
    column: $table.holidayCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appliedHolidays => $composableBuilder(
    column: $table.appliedHolidays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PayFrequency, String> get payFrequency =>
      $composableBuilder(
        column: $table.payFrequency,
        builder: (column) => column,
      );

  GeneratedColumn<int> get payDay =>
      $composableBuilder(column: $table.payDay, builder: (column) => column);

  GeneratedColumn<int> get payAnchorDay => $composableBuilder(
    column: $table.payAnchorDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get netIncomeMinor => $composableBuilder(
    column: $table.netIncomeMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tightThresholdMinor => $composableBuilder(
    column: $table.tightThresholdMinor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get debugPro =>
      $composableBuilder(column: $table.debugPro, builder: (column) => column);

  GeneratedColumn<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderLeadDays => $composableBuilder(
    column: $table.reminderLeadDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hideAmountsInNotifications => $composableBuilder(
    column: $table.hideAmountsInNotifications,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderPromptShown => $composableBuilder(
    column: $table.reminderPromptShown,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReminderRepeat, int> get repeatMode =>
      $composableBuilder(
        column: $table.repeatMode,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<PayLaterRuleKind?, String>
  get lastPayLaterRule => $composableBuilder(
    column: $table.lastPayLaterRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPayLaterValue => $composableBuilder(
    column: $table.lastPayLaterValue,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AmountEntry?, String> get lastAmountEntry =>
      $composableBuilder(
        column: $table.lastAmountEntry,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get paydaySummaryEnabled => $composableBuilder(
    column: $table.paydaySummaryEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get holidayCountry => $composableBuilder(
    column: $table.holidayCountry,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appliedHolidays => $composableBuilder(
    column: $table.appliedHolidays,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          SettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String?> localeCode = const Value.absent(),
                Value<PayFrequency> payFrequency = const Value.absent(),
                Value<int?> payDay = const Value.absent(),
                Value<int?> payAnchorDay = const Value.absent(),
                Value<int?> netIncomeMinor = const Value.absent(),
                Value<int?> tightThresholdMinor = const Value.absent(),
                Value<bool> debugPro = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<int> reminderLeadDays = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> hideAmountsInNotifications = const Value.absent(),
                Value<bool> reminderPromptShown = const Value.absent(),
                Value<ReminderRepeat> repeatMode = const Value.absent(),
                Value<PayLaterRuleKind?> lastPayLaterRule =
                    const Value.absent(),
                Value<int?> lastPayLaterValue = const Value.absent(),
                Value<AmountEntry?> lastAmountEntry = const Value.absent(),
                Value<bool> paydaySummaryEnabled = const Value.absent(),
                Value<String?> holidayCountry = const Value.absent(),
                Value<String?> appliedHolidays = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                currencyCode: currencyCode,
                localeCode: localeCode,
                payFrequency: payFrequency,
                payDay: payDay,
                payAnchorDay: payAnchorDay,
                netIncomeMinor: netIncomeMinor,
                tightThresholdMinor: tightThresholdMinor,
                debugPro: debugPro,
                remindersEnabled: remindersEnabled,
                reminderLeadDays: reminderLeadDays,
                reminderMinute: reminderMinute,
                hideAmountsInNotifications: hideAmountsInNotifications,
                reminderPromptShown: reminderPromptShown,
                repeatMode: repeatMode,
                lastPayLaterRule: lastPayLaterRule,
                lastPayLaterValue: lastPayLaterValue,
                lastAmountEntry: lastAmountEntry,
                paydaySummaryEnabled: paydaySummaryEnabled,
                holidayCountry: holidayCountry,
                appliedHolidays: appliedHolidays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String currencyCode,
                Value<String?> localeCode = const Value.absent(),
                required PayFrequency payFrequency,
                Value<int?> payDay = const Value.absent(),
                Value<int?> payAnchorDay = const Value.absent(),
                Value<int?> netIncomeMinor = const Value.absent(),
                Value<int?> tightThresholdMinor = const Value.absent(),
                Value<bool> debugPro = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<int> reminderLeadDays = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> hideAmountsInNotifications = const Value.absent(),
                Value<bool> reminderPromptShown = const Value.absent(),
                Value<ReminderRepeat> repeatMode = const Value.absent(),
                Value<PayLaterRuleKind?> lastPayLaterRule =
                    const Value.absent(),
                Value<int?> lastPayLaterValue = const Value.absent(),
                Value<AmountEntry?> lastAmountEntry = const Value.absent(),
                Value<bool> paydaySummaryEnabled = const Value.absent(),
                Value<String?> holidayCountry = const Value.absent(),
                Value<String?> appliedHolidays = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                currencyCode: currencyCode,
                localeCode: localeCode,
                payFrequency: payFrequency,
                payDay: payDay,
                payAnchorDay: payAnchorDay,
                netIncomeMinor: netIncomeMinor,
                tightThresholdMinor: tightThresholdMinor,
                debugPro: debugPro,
                remindersEnabled: remindersEnabled,
                reminderLeadDays: reminderLeadDays,
                reminderMinute: reminderMinute,
                hideAmountsInNotifications: hideAmountsInNotifications,
                reminderPromptShown: reminderPromptShown,
                repeatMode: repeatMode,
                lastPayLaterRule: lastPayLaterRule,
                lastPayLaterValue: lastPayLaterValue,
                lastAmountEntry: lastAmountEntry,
                paydaySummaryEnabled: paydaySummaryEnabled,
                holidayCountry: holidayCountry,
                appliedHolidays: appliedHolidays,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, SettingsRow>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, SettingsRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      SettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$ReminderSnoozesTableCreateCompanionBuilder =
    ReminderSnoozesCompanion Function({
      Value<int> id,
      required int kind,
      required int fireDay,
      required int minuteOfDay,
      required String refs,
      Value<bool> skipsDay,
    });
typedef $$ReminderSnoozesTableUpdateCompanionBuilder =
    ReminderSnoozesCompanion Function({
      Value<int> id,
      Value<int> kind,
      Value<int> fireDay,
      Value<int> minuteOfDay,
      Value<String> refs,
      Value<bool> skipsDay,
    });

class $$ReminderSnoozesTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderSnoozesTable> {
  $$ReminderSnoozesTableFilterComposer({
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

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fireDay => $composableBuilder(
    column: $table.fireDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refs => $composableBuilder(
    column: $table.refs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get skipsDay => $composableBuilder(
    column: $table.skipsDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReminderSnoozesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderSnoozesTable> {
  $$ReminderSnoozesTableOrderingComposer({
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

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fireDay => $composableBuilder(
    column: $table.fireDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refs => $composableBuilder(
    column: $table.refs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get skipsDay => $composableBuilder(
    column: $table.skipsDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderSnoozesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderSnoozesTable> {
  $$ReminderSnoozesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get fireDay =>
      $composableBuilder(column: $table.fireDay, builder: (column) => column);

  GeneratedColumn<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refs =>
      $composableBuilder(column: $table.refs, builder: (column) => column);

  GeneratedColumn<bool> get skipsDay =>
      $composableBuilder(column: $table.skipsDay, builder: (column) => column);
}

class $$ReminderSnoozesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReminderSnoozesTable,
          ReminderSnoozeRow,
          $$ReminderSnoozesTableFilterComposer,
          $$ReminderSnoozesTableOrderingComposer,
          $$ReminderSnoozesTableAnnotationComposer,
          $$ReminderSnoozesTableCreateCompanionBuilder,
          $$ReminderSnoozesTableUpdateCompanionBuilder,
          (
            ReminderSnoozeRow,
            BaseReferences<
              _$AppDatabase,
              $ReminderSnoozesTable,
              ReminderSnoozeRow
            >,
          ),
          ReminderSnoozeRow,
          PrefetchHooks Function()
        > {
  $$ReminderSnoozesTableTableManager(
    _$AppDatabase db,
    $ReminderSnoozesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderSnoozesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderSnoozesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderSnoozesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<int> fireDay = const Value.absent(),
                Value<int> minuteOfDay = const Value.absent(),
                Value<String> refs = const Value.absent(),
                Value<bool> skipsDay = const Value.absent(),
              }) => ReminderSnoozesCompanion(
                id: id,
                kind: kind,
                fireDay: fireDay,
                minuteOfDay: minuteOfDay,
                refs: refs,
                skipsDay: skipsDay,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int kind,
                required int fireDay,
                required int minuteOfDay,
                required String refs,
                Value<bool> skipsDay = const Value.absent(),
              }) => ReminderSnoozesCompanion.insert(
                id: id,
                kind: kind,
                fireDay: fireDay,
                minuteOfDay: minuteOfDay,
                refs: refs,
                skipsDay: skipsDay,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderSnoozesTable, ReminderSnoozeRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReminderSnoozesTable,
                    ReminderSnoozeRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderSnoozesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReminderSnoozesTable,
      ReminderSnoozeRow,
      $$ReminderSnoozesTableFilterComposer,
      $$ReminderSnoozesTableOrderingComposer,
      $$ReminderSnoozesTableAnnotationComposer,
      $$ReminderSnoozesTableCreateCompanionBuilder,
      $$ReminderSnoozesTableUpdateCompanionBuilder,
      (
        ReminderSnoozeRow,
        BaseReferences<_$AppDatabase, $ReminderSnoozesTable, ReminderSnoozeRow>,
      ),
      ReminderSnoozeRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$RecurringPaymentsTableTableManager get recurringPayments =>
      $$RecurringPaymentsTableTableManager(_db, _db.recurringPayments);
  $$RecurringMarksTableTableManager get recurringMarks =>
      $$RecurringMarksTableTableManager(_db, _db.recurringMarks);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ReminderSnoozesTableTableManager get reminderSnoozes =>
      $$ReminderSnoozesTableTableManager(_db, _db.reminderSnoozes);
}
