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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    statementDay,
    dueDay,
    shiftDueToBusinessDay,
    createdAt,
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
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
  final DateTime createdAt;
  const SourceRow({
    required this.id,
    required this.name,
    required this.kind,
    this.statementDay,
    this.dueDay,
    required this.shiftDueToBusinessDay,
    required this.createdAt,
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
    map['created_at'] = Variable<DateTime>(createdAt);
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
      createdAt: Value(createdAt),
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
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
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
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SourceRow copyWith({
    int? id,
    String? name,
    SourceKind? kind,
    Value<int?> statementDay = const Value.absent(),
    Value<int?> dueDay = const Value.absent(),
    bool? shiftDueToBusinessDay,
    DateTime? createdAt,
  }) => SourceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    statementDay: statementDay.present ? statementDay.value : this.statementDay,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    shiftDueToBusinessDay: shiftDueToBusinessDay ?? this.shiftDueToBusinessDay,
    createdAt: createdAt ?? this.createdAt,
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
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
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
          ..write('createdAt: $createdAt')
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
    createdAt,
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
          other.createdAt == this.createdAt);
}

class SourcesCompanion extends UpdateCompanion<SourceRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<SourceKind> kind;
  final Value<int?> statementDay;
  final Value<int?> dueDay;
  final Value<bool> shiftDueToBusinessDay;
  final Value<DateTime> createdAt;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.shiftDueToBusinessDay = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SourcesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required SourceKind kind,
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.shiftDueToBusinessDay = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind);
  static Insertable<SourceRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? statementDay,
    Expression<int>? dueDay,
    Expression<bool>? shiftDueToBusinessDay,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (statementDay != null) 'statement_day': statementDay,
      if (dueDay != null) 'due_day': dueDay,
      if (shiftDueToBusinessDay != null)
        'shift_due_to_business_day': shiftDueToBusinessDay,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<SourceKind>? kind,
    Value<int?>? statementDay,
    Value<int?>? dueDay,
    Value<bool>? shiftDueToBusinessDay,
    Value<DateTime>? createdAt,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      shiftDueToBusinessDay:
          shiftDueToBusinessDay ?? this.shiftDueToBusinessDay,
      createdAt: createdAt ?? this.createdAt,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
          ..write('createdAt: $createdAt')
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
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
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
      )!,
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
}

class PlanRow extends DataClass implements Insertable<PlanRow> {
  final int id;
  final int sourceId;
  final String? title;
  final PlanKind kind;
  final int installmentCount;
  final int? purchaseDay;
  final int deferMonths;
  final bool isCashAdvance;
  final PlanOrigin origin;
  final DateTime createdAt;

  /// "Reminders for this plan" (schema v2).
  final bool remindersEnabled;
  const PlanRow({
    required this.id,
    required this.sourceId,
    this.title,
    required this.kind,
    required this.installmentCount,
    this.purchaseDay,
    required this.deferMonths,
    required this.isCashAdvance,
    required this.origin,
    required this.createdAt,
    required this.remindersEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<int>(sourceId);
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
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
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
    );
  }

  factory PlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRow(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<int>(sourceId),
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
    };
  }

  PlanRow copyWith({
    int? id,
    int? sourceId,
    Value<String?> title = const Value.absent(),
    PlanKind? kind,
    int? installmentCount,
    Value<int?> purchaseDay = const Value.absent(),
    int? deferMonths,
    bool? isCashAdvance,
    PlanOrigin? origin,
    DateTime? createdAt,
    bool? remindersEnabled,
  }) => PlanRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    title: title.present ? title.value : this.title,
    kind: kind ?? this.kind,
    installmentCount: installmentCount ?? this.installmentCount,
    purchaseDay: purchaseDay.present ? purchaseDay.value : this.purchaseDay,
    deferMonths: deferMonths ?? this.deferMonths,
    isCashAdvance: isCashAdvance ?? this.isCashAdvance,
    origin: origin ?? this.origin,
    createdAt: createdAt ?? this.createdAt,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
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
          ..write('remindersEnabled: $remindersEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  );
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
          other.remindersEnabled == this.remindersEnabled);
}

class PlansCompanion extends UpdateCompanion<PlanRow> {
  final Value<int> id;
  final Value<int> sourceId;
  final Value<String?> title;
  final Value<PlanKind> kind;
  final Value<int> installmentCount;
  final Value<int?> purchaseDay;
  final Value<int> deferMonths;
  final Value<bool> isCashAdvance;
  final Value<PlanOrigin> origin;
  final Value<DateTime> createdAt;
  final Value<bool> remindersEnabled;
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
  });
  PlansCompanion.insert({
    this.id = const Value.absent(),
    required int sourceId,
    this.title = const Value.absent(),
    required PlanKind kind,
    required int installmentCount,
    this.purchaseDay = const Value.absent(),
    this.deferMonths = const Value.absent(),
    this.isCashAdvance = const Value.absent(),
    required PlanOrigin origin,
    this.createdAt = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
  }) : sourceId = Value(sourceId),
       kind = Value(kind),
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
    });
  }

  PlansCompanion copyWith({
    Value<int>? id,
    Value<int>? sourceId,
    Value<String?>? title,
    Value<PlanKind>? kind,
    Value<int>? installmentCount,
    Value<int?>? purchaseDay,
    Value<int>? deferMonths,
    Value<bool>? isCashAdvance,
    Value<PlanOrigin>? origin,
    Value<DateTime>? createdAt,
    Value<bool>? remindersEnabled,
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
          ..write('remindersEnabled: $remindersEnabled')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    seq,
    dueDay,
    amountMinor,
    paidAt,
    isEdited,
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
  const PaymentRow({
    required this.id,
    required this.planId,
    required this.seq,
    required this.dueDay,
    required this.amountMinor,
    this.paidAt,
    required this.isEdited,
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
  }) => PaymentRow(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    seq: seq ?? this.seq,
    dueDay: dueDay ?? this.dueDay,
    amountMinor: amountMinor ?? this.amountMinor,
    paidAt: paidAt.present ? paidAt.value : this.paidAt,
    isEdited: isEdited ?? this.isEdited,
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
          ..write('isEdited: $isEdited')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, planId, seq, dueDay, amountMinor, paidAt, isEdited);
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
          other.isEdited == this.isEdited);
}

class PaymentsCompanion extends UpdateCompanion<PaymentRow> {
  final Value<int> id;
  final Value<int> planId;
  final Value<int> seq;
  final Value<int> dueDay;
  final Value<int> amountMinor;
  final Value<DateTime?> paidAt;
  final Value<bool> isEdited;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.seq = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.isEdited = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required int seq,
    required int dueDay,
    required int amountMinor,
    this.paidAt = const Value.absent(),
    this.isEdited = const Value.absent(),
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
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (seq != null) 'seq': seq,
      if (dueDay != null) 'due_day': dueDay,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (paidAt != null) 'paid_at': paidAt,
      if (isEdited != null) 'is_edited': isEdited,
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
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      seq: seq ?? this.seq,
      dueDay: dueDay ?? this.dueDay,
      amountMinor: amountMinor ?? this.amountMinor,
      paidAt: paidAt ?? this.paidAt,
      isEdited: isEdited ?? this.isEdited,
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
          ..write('isEdited: $isEdited')
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
    );
  }

  @override
  $RecurringPaymentsTable createAlias(String alias) {
    return $RecurringPaymentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Recurrence, String, String> $converterrecurrence =
      const EnumNameConverter<Recurrence>(Recurrence.values);
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

  /// "Reminders for this payment" (schema v2).
  final bool remindersEnabled;
  const RecurringPaymentRow({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.recurrence,
    required this.startDay,
    this.endDay,
    required this.createdAt,
    required this.remindersEnabled,
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
  }) => RecurringPaymentRow(
    id: id ?? this.id,
    name: name ?? this.name,
    amountMinor: amountMinor ?? this.amountMinor,
    recurrence: recurrence ?? this.recurrence,
    startDay: startDay ?? this.startDay,
    endDay: endDay.present ? endDay.value : this.endDay,
    createdAt: createdAt ?? this.createdAt,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
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
          ..write('remindersEnabled: $remindersEnabled')
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
          other.remindersEnabled == this.remindersEnabled);
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
  const RecurringPaymentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.startDay = const Value.absent(),
    this.endDay = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
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
          ..write('remindersEnabled: $remindersEnabled')
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
  static const VerificationMeta _remindDays7Meta = const VerificationMeta(
    'remindDays7',
  );
  @override
  late final GeneratedColumn<bool> remindDays7 = GeneratedColumn<bool>(
    'remind_days7',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remind_days7" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remindDays3Meta = const VerificationMeta(
    'remindDays3',
  );
  @override
  late final GeneratedColumn<bool> remindDays3 = GeneratedColumn<bool>(
    'remind_days3',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remind_days3" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _remindDays1Meta = const VerificationMeta(
    'remindDays1',
  );
  @override
  late final GeneratedColumn<bool> remindDays1 = GeneratedColumn<bool>(
    'remind_days1',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remind_days1" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remindSameDayMeta = const VerificationMeta(
    'remindSameDay',
  );
  @override
  late final GeneratedColumn<bool> remindSameDay = GeneratedColumn<bool>(
    'remind_same_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remind_same_day" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    remindDays7,
    remindDays3,
    remindDays1,
    remindSameDay,
    reminderMinute,
    hideAmountsInNotifications,
    reminderPromptShown,
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
    if (data.containsKey('remind_days7')) {
      context.handle(
        _remindDays7Meta,
        remindDays7.isAcceptableOrUnknown(
          data['remind_days7']!,
          _remindDays7Meta,
        ),
      );
    }
    if (data.containsKey('remind_days3')) {
      context.handle(
        _remindDays3Meta,
        remindDays3.isAcceptableOrUnknown(
          data['remind_days3']!,
          _remindDays3Meta,
        ),
      );
    }
    if (data.containsKey('remind_days1')) {
      context.handle(
        _remindDays1Meta,
        remindDays1.isAcceptableOrUnknown(
          data['remind_days1']!,
          _remindDays1Meta,
        ),
      );
    }
    if (data.containsKey('remind_same_day')) {
      context.handle(
        _remindSameDayMeta,
        remindSameDay.isAcceptableOrUnknown(
          data['remind_same_day']!,
          _remindSameDayMeta,
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
      remindDays7: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remind_days7'],
      )!,
      remindDays3: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remind_days3'],
      )!,
      remindDays1: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remind_days1'],
      )!,
      remindSameDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remind_same_day'],
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
  final bool remindDays7;
  final bool remindDays3;
  final bool remindDays1;
  final bool remindSameDay;

  /// Local time, minutes after midnight.
  final int reminderMinute;

  /// Privacy: hide amounts in notifications.
  final bool hideAmountsInNotifications;

  /// The in-app reminder prompt was answered (never asked again).
  final bool reminderPromptShown;
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
    required this.remindDays7,
    required this.remindDays3,
    required this.remindDays1,
    required this.remindSameDay,
    required this.reminderMinute,
    required this.hideAmountsInNotifications,
    required this.reminderPromptShown,
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
    map['remind_days7'] = Variable<bool>(remindDays7);
    map['remind_days3'] = Variable<bool>(remindDays3);
    map['remind_days1'] = Variable<bool>(remindDays1);
    map['remind_same_day'] = Variable<bool>(remindSameDay);
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['hide_amounts_in_notifications'] = Variable<bool>(
      hideAmountsInNotifications,
    );
    map['reminder_prompt_shown'] = Variable<bool>(reminderPromptShown);
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
      remindDays7: Value(remindDays7),
      remindDays3: Value(remindDays3),
      remindDays1: Value(remindDays1),
      remindSameDay: Value(remindSameDay),
      reminderMinute: Value(reminderMinute),
      hideAmountsInNotifications: Value(hideAmountsInNotifications),
      reminderPromptShown: Value(reminderPromptShown),
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
      remindDays7: serializer.fromJson<bool>(json['remindDays7']),
      remindDays3: serializer.fromJson<bool>(json['remindDays3']),
      remindDays1: serializer.fromJson<bool>(json['remindDays1']),
      remindSameDay: serializer.fromJson<bool>(json['remindSameDay']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      hideAmountsInNotifications: serializer.fromJson<bool>(
        json['hideAmountsInNotifications'],
      ),
      reminderPromptShown: serializer.fromJson<bool>(
        json['reminderPromptShown'],
      ),
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
      'remindDays7': serializer.toJson<bool>(remindDays7),
      'remindDays3': serializer.toJson<bool>(remindDays3),
      'remindDays1': serializer.toJson<bool>(remindDays1),
      'remindSameDay': serializer.toJson<bool>(remindSameDay),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'hideAmountsInNotifications': serializer.toJson<bool>(
        hideAmountsInNotifications,
      ),
      'reminderPromptShown': serializer.toJson<bool>(reminderPromptShown),
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
    bool? remindDays7,
    bool? remindDays3,
    bool? remindDays1,
    bool? remindSameDay,
    int? reminderMinute,
    bool? hideAmountsInNotifications,
    bool? reminderPromptShown,
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
    remindDays7: remindDays7 ?? this.remindDays7,
    remindDays3: remindDays3 ?? this.remindDays3,
    remindDays1: remindDays1 ?? this.remindDays1,
    remindSameDay: remindSameDay ?? this.remindSameDay,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    hideAmountsInNotifications:
        hideAmountsInNotifications ?? this.hideAmountsInNotifications,
    reminderPromptShown: reminderPromptShown ?? this.reminderPromptShown,
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
      remindDays7: data.remindDays7.present
          ? data.remindDays7.value
          : this.remindDays7,
      remindDays3: data.remindDays3.present
          ? data.remindDays3.value
          : this.remindDays3,
      remindDays1: data.remindDays1.present
          ? data.remindDays1.value
          : this.remindDays1,
      remindSameDay: data.remindSameDay.present
          ? data.remindSameDay.value
          : this.remindSameDay,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      hideAmountsInNotifications: data.hideAmountsInNotifications.present
          ? data.hideAmountsInNotifications.value
          : this.hideAmountsInNotifications,
      reminderPromptShown: data.reminderPromptShown.present
          ? data.reminderPromptShown.value
          : this.reminderPromptShown,
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
          ..write('remindDays7: $remindDays7, ')
          ..write('remindDays3: $remindDays3, ')
          ..write('remindDays1: $remindDays1, ')
          ..write('remindSameDay: $remindSameDay, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('hideAmountsInNotifications: $hideAmountsInNotifications, ')
          ..write('reminderPromptShown: $reminderPromptShown')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
    remindDays7,
    remindDays3,
    remindDays1,
    remindSameDay,
    reminderMinute,
    hideAmountsInNotifications,
    reminderPromptShown,
  );
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
          other.remindDays7 == this.remindDays7 &&
          other.remindDays3 == this.remindDays3 &&
          other.remindDays1 == this.remindDays1 &&
          other.remindSameDay == this.remindSameDay &&
          other.reminderMinute == this.reminderMinute &&
          other.hideAmountsInNotifications == this.hideAmountsInNotifications &&
          other.reminderPromptShown == this.reminderPromptShown);
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
  final Value<bool> remindDays7;
  final Value<bool> remindDays3;
  final Value<bool> remindDays1;
  final Value<bool> remindSameDay;
  final Value<int> reminderMinute;
  final Value<bool> hideAmountsInNotifications;
  final Value<bool> reminderPromptShown;
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
    this.remindDays7 = const Value.absent(),
    this.remindDays3 = const Value.absent(),
    this.remindDays1 = const Value.absent(),
    this.remindSameDay = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.hideAmountsInNotifications = const Value.absent(),
    this.reminderPromptShown = const Value.absent(),
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
    this.remindDays7 = const Value.absent(),
    this.remindDays3 = const Value.absent(),
    this.remindDays1 = const Value.absent(),
    this.remindSameDay = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.hideAmountsInNotifications = const Value.absent(),
    this.reminderPromptShown = const Value.absent(),
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
    Expression<bool>? remindDays7,
    Expression<bool>? remindDays3,
    Expression<bool>? remindDays1,
    Expression<bool>? remindSameDay,
    Expression<int>? reminderMinute,
    Expression<bool>? hideAmountsInNotifications,
    Expression<bool>? reminderPromptShown,
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
      if (remindDays7 != null) 'remind_days7': remindDays7,
      if (remindDays3 != null) 'remind_days3': remindDays3,
      if (remindDays1 != null) 'remind_days1': remindDays1,
      if (remindSameDay != null) 'remind_same_day': remindSameDay,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (hideAmountsInNotifications != null)
        'hide_amounts_in_notifications': hideAmountsInNotifications,
      if (reminderPromptShown != null)
        'reminder_prompt_shown': reminderPromptShown,
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
    Value<bool>? remindDays7,
    Value<bool>? remindDays3,
    Value<bool>? remindDays1,
    Value<bool>? remindSameDay,
    Value<int>? reminderMinute,
    Value<bool>? hideAmountsInNotifications,
    Value<bool>? reminderPromptShown,
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
      remindDays7: remindDays7 ?? this.remindDays7,
      remindDays3: remindDays3 ?? this.remindDays3,
      remindDays1: remindDays1 ?? this.remindDays1,
      remindSameDay: remindSameDay ?? this.remindSameDay,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      hideAmountsInNotifications:
          hideAmountsInNotifications ?? this.hideAmountsInNotifications,
      reminderPromptShown: reminderPromptShown ?? this.reminderPromptShown,
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
    if (remindDays7.present) {
      map['remind_days7'] = Variable<bool>(remindDays7.value);
    }
    if (remindDays3.present) {
      map['remind_days3'] = Variable<bool>(remindDays3.value);
    }
    if (remindDays1.present) {
      map['remind_days1'] = Variable<bool>(remindDays1.value);
    }
    if (remindSameDay.present) {
      map['remind_same_day'] = Variable<bool>(remindSameDay.value);
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
          ..write('remindDays7: $remindDays7, ')
          ..write('remindDays3: $remindDays3, ')
          ..write('remindDays1: $remindDays1, ')
          ..write('remindSameDay: $remindSameDay, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('hideAmountsInNotifications: $hideAmountsInNotifications, ')
          ..write('reminderPromptShown: $reminderPromptShown')
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
    paymentsDueDay,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
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
  Value<DateTime> createdAt,
});
typedef $$SourcesTableUpdateCompanionBuilder = SourcesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<SourceKind> kind,
  Value<int?> statementDay,
  Value<int?> dueDay,
  Value<bool> shiftDueToBusinessDay,
  Value<DateTime> createdAt,
});

final class $$SourcesTableReferences
    extends BaseReferences<_$AppDatabase, $SourcesTable, SourceRow> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlansTable, List<PlanRow>> _plansRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.plans,
    aliasName: 'sources__id__plans__source_id',
  );

  $$PlansTableProcessedTableManager get plansRefs {
    final manager = $$PlansTableTableManager(
      $_db,
      $_db.plans,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_plansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> plansRefs(
    Expression<bool> Function($$PlansTableFilterComposer f) f,
  ) {
    final $$PlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.sourceId,
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
    return f(composer);
  }
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> plansRefs<T extends Object>(
    Expression<T> Function($$PlansTableAnnotationComposer a) f,
  ) {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.sourceId,
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
    return f(composer);
  }
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
          (SourceRow, $$SourcesTableReferences),
          SourceRow,
          PrefetchHooks Function({bool plansRefs})
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
                Value<DateTime> createdAt = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                name: name,
                kind: kind,
                statementDay: statementDay,
                dueDay: dueDay,
                shiftDueToBusinessDay: shiftDueToBusinessDay,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required SourceKind kind,
                Value<int?> statementDay = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<bool> shiftDueToBusinessDay = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                statementDay: statementDay,
                dueDay: dueDay,
                shiftDueToBusinessDay: shiftDueToBusinessDay,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourcesTable, SourceRow>(table),
                  $$SourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plansRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (plansRefs) db.plans],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (plansRefs)
                    await $_getPrefetchedDataByColumns<
                      SourceRow,
                      $SourcesTable,
                      PlanRow,
                      $PlansTable
                    >(
                      currentTable: table,
                      referencedTable: $$SourcesTableReferences._plansRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$SourcesTableReferences(db, table, p0).plansRefs,
                      currentColumn: 'id',
                      referencedColumn: 'source_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (SourceRow, $$SourcesTableReferences),
      SourceRow,
      PrefetchHooks Function({bool plansRefs})
    >;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  required int sourceId,
  Value<String?> title,
  required PlanKind kind,
  required int installmentCount,
  Value<int?> purchaseDay,
  Value<int> deferMonths,
  Value<bool> isCashAdvance,
  required PlanOrigin origin,
  Value<DateTime> createdAt,
  Value<bool> remindersEnabled,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<int> id,
  Value<int> sourceId,
  Value<String?> title,
  Value<PlanKind> kind,
  Value<int> installmentCount,
  Value<int?> purchaseDay,
  Value<int> deferMonths,
  Value<bool> isCashAdvance,
  Value<PlanOrigin> origin,
  Value<DateTime> createdAt,
  Value<bool> remindersEnabled,
});

final class $$PlansTableReferences
    extends BaseReferences<_$AppDatabase, $PlansTable, PlanRow> {
  $$PlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias('plans__source_id__sources__id');

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

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
          PrefetchHooks Function({bool sourceId, bool paymentsRefs})
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
                Value<int> sourceId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<PlanKind> kind = const Value.absent(),
                Value<int> installmentCount = const Value.absent(),
                Value<int?> purchaseDay = const Value.absent(),
                Value<int> deferMonths = const Value.absent(),
                Value<bool> isCashAdvance = const Value.absent(),
                Value<PlanOrigin> origin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
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
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sourceId,
                Value<String?> title = const Value.absent(),
                required PlanKind kind,
                required int installmentCount,
                Value<int?> purchaseDay = const Value.absent(),
                Value<int> deferMonths = const Value.absent(),
                Value<bool> isCashAdvance = const Value.absent(),
                required PlanOrigin origin,
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
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
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlansTable, PlanRow>(table),
                  $$PlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false, paymentsRefs = false}) {
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
                        referencedTable: $$PlansTableReferences._sourceIdTable(
                          db,
                        ),
                        referencedColumn: $$PlansTableReferences
                            ._sourceIdTable(db)
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
                          $$PlansTableReferences(db, table, p0).paymentsRefs,
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
      PrefetchHooks Function({bool sourceId, bool paymentsRefs})
    >;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  required int planId,
  required int seq,
  required int dueDay,
  required int amountMinor,
  Value<DateTime?> paidAt,
  Value<bool> isEdited,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  Value<int> planId,
  Value<int> seq,
  Value<int> dueDay,
  Value<int> amountMinor,
  Value<DateTime?> paidAt,
  Value<bool> isEdited,
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
              }) => PaymentsCompanion(
                id: id,
                planId: planId,
                seq: seq,
                dueDay: dueDay,
                amountMinor: amountMinor,
                paidAt: paidAt,
                isEdited: isEdited,
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
              }) => PaymentsCompanion.insert(
                id: id,
                planId: planId,
                seq: seq,
                dueDay: dueDay,
                amountMinor: amountMinor,
                paidAt: paidAt,
                isEdited: isEdited,
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
              }) => RecurringPaymentsCompanion(
                id: id,
                name: name,
                amountMinor: amountMinor,
                recurrence: recurrence,
                startDay: startDay,
                endDay: endDay,
                createdAt: createdAt,
                remindersEnabled: remindersEnabled,
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
              }) => RecurringPaymentsCompanion.insert(
                id: id,
                name: name,
                amountMinor: amountMinor,
                recurrence: recurrence,
                startDay: startDay,
                endDay: endDay,
                createdAt: createdAt,
                remindersEnabled: remindersEnabled,
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
      Value<bool> remindDays7,
      Value<bool> remindDays3,
      Value<bool> remindDays1,
      Value<bool> remindSameDay,
      Value<int> reminderMinute,
      Value<bool> hideAmountsInNotifications,
      Value<bool> reminderPromptShown,
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
      Value<bool> remindDays7,
      Value<bool> remindDays3,
      Value<bool> remindDays1,
      Value<bool> remindSameDay,
      Value<int> reminderMinute,
      Value<bool> hideAmountsInNotifications,
      Value<bool> reminderPromptShown,
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

  ColumnFilters<bool> get remindDays7 => $composableBuilder(
    column: $table.remindDays7,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindDays3 => $composableBuilder(
    column: $table.remindDays3,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindDays1 => $composableBuilder(
    column: $table.remindDays1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindSameDay => $composableBuilder(
    column: $table.remindSameDay,
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

  ColumnOrderings<bool> get remindDays7 => $composableBuilder(
    column: $table.remindDays7,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindDays3 => $composableBuilder(
    column: $table.remindDays3,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindDays1 => $composableBuilder(
    column: $table.remindDays1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindSameDay => $composableBuilder(
    column: $table.remindSameDay,
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

  GeneratedColumn<bool> get remindDays7 => $composableBuilder(
    column: $table.remindDays7,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remindDays3 => $composableBuilder(
    column: $table.remindDays3,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remindDays1 => $composableBuilder(
    column: $table.remindDays1,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remindSameDay => $composableBuilder(
    column: $table.remindSameDay,
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
                Value<bool> remindDays7 = const Value.absent(),
                Value<bool> remindDays3 = const Value.absent(),
                Value<bool> remindDays1 = const Value.absent(),
                Value<bool> remindSameDay = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> hideAmountsInNotifications = const Value.absent(),
                Value<bool> reminderPromptShown = const Value.absent(),
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
                remindDays7: remindDays7,
                remindDays3: remindDays3,
                remindDays1: remindDays1,
                remindSameDay: remindSameDay,
                reminderMinute: reminderMinute,
                hideAmountsInNotifications: hideAmountsInNotifications,
                reminderPromptShown: reminderPromptShown,
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
                Value<bool> remindDays7 = const Value.absent(),
                Value<bool> remindDays3 = const Value.absent(),
                Value<bool> remindDays1 = const Value.absent(),
                Value<bool> remindSameDay = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<bool> hideAmountsInNotifications = const Value.absent(),
                Value<bool> reminderPromptShown = const Value.absent(),
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
                remindDays7: remindDays7,
                remindDays3: remindDays3,
                remindDays1: remindDays1,
                remindSameDay: remindSameDay,
                reminderMinute: reminderMinute,
                hideAmountsInNotifications: hideAmountsInNotifications,
                reminderPromptShown: reminderPromptShown,
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
}
