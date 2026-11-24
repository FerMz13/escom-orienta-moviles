// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProcessedSchedulesTable extends ProcessedSchedules
    with TableInfo<$ProcessedSchedulesTable, ProcessedScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessedSchedulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _loadedAtMeta = const VerificationMeta(
    'loadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loadedAt = GeneratedColumn<DateTime>(
    'loaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicationStatusMeta = const VerificationMeta(
    'publicationStatus',
  );
  @override
  late final GeneratedColumn<String> publicationStatus =
      GeneratedColumn<String>(
        'publication_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceFileNameMeta = const VerificationMeta(
    'sourceFileName',
  );
  @override
  late final GeneratedColumn<String> sourceFileName = GeneratedColumn<String>(
    'source_file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalClassesMeta = const VerificationMeta(
    'totalClasses',
  );
  @override
  late final GeneratedColumn<int> totalClasses = GeneratedColumn<int>(
    'total_classes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loadedAt,
    publicationStatus,
    sourceFileName,
    totalClasses,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'processed_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessedScheduleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('loaded_at')) {
      context.handle(
        _loadedAtMeta,
        loadedAt.isAcceptableOrUnknown(data['loaded_at']!, _loadedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loadedAtMeta);
    }
    if (data.containsKey('publication_status')) {
      context.handle(
        _publicationStatusMeta,
        publicationStatus.isAcceptableOrUnknown(
          data['publication_status']!,
          _publicationStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicationStatusMeta);
    }
    if (data.containsKey('source_file_name')) {
      context.handle(
        _sourceFileNameMeta,
        sourceFileName.isAcceptableOrUnknown(
          data['source_file_name']!,
          _sourceFileNameMeta,
        ),
      );
    }
    if (data.containsKey('total_classes')) {
      context.handle(
        _totalClassesMeta,
        totalClasses.isAcceptableOrUnknown(
          data['total_classes']!,
          _totalClassesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessedScheduleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessedScheduleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      loadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}loaded_at'],
      )!,
      publicationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication_status'],
      )!,
      sourceFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_file_name'],
      ),
      totalClasses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_classes'],
      )!,
    );
  }

  @override
  $ProcessedSchedulesTable createAlias(String alias) {
    return $ProcessedSchedulesTable(attachedDatabase, alias);
  }
}

class ProcessedScheduleRow extends DataClass
    implements Insertable<ProcessedScheduleRow> {
  final int id;
  final DateTime loadedAt;
  final String publicationStatus;
  final String? sourceFileName;
  final int totalClasses;
  const ProcessedScheduleRow({
    required this.id,
    required this.loadedAt,
    required this.publicationStatus,
    this.sourceFileName,
    required this.totalClasses,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['loaded_at'] = Variable<DateTime>(loadedAt);
    map['publication_status'] = Variable<String>(publicationStatus);
    if (!nullToAbsent || sourceFileName != null) {
      map['source_file_name'] = Variable<String>(sourceFileName);
    }
    map['total_classes'] = Variable<int>(totalClasses);
    return map;
  }

  ProcessedSchedulesCompanion toCompanion(bool nullToAbsent) {
    return ProcessedSchedulesCompanion(
      id: Value(id),
      loadedAt: Value(loadedAt),
      publicationStatus: Value(publicationStatus),
      sourceFileName: sourceFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceFileName),
      totalClasses: Value(totalClasses),
    );
  }

  factory ProcessedScheduleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessedScheduleRow(
      id: serializer.fromJson<int>(json['id']),
      loadedAt: serializer.fromJson<DateTime>(json['loadedAt']),
      publicationStatus: serializer.fromJson<String>(json['publicationStatus']),
      sourceFileName: serializer.fromJson<String?>(json['sourceFileName']),
      totalClasses: serializer.fromJson<int>(json['totalClasses']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'loadedAt': serializer.toJson<DateTime>(loadedAt),
      'publicationStatus': serializer.toJson<String>(publicationStatus),
      'sourceFileName': serializer.toJson<String?>(sourceFileName),
      'totalClasses': serializer.toJson<int>(totalClasses),
    };
  }

  ProcessedScheduleRow copyWith({
    int? id,
    DateTime? loadedAt,
    String? publicationStatus,
    Value<String?> sourceFileName = const Value.absent(),
    int? totalClasses,
  }) => ProcessedScheduleRow(
    id: id ?? this.id,
    loadedAt: loadedAt ?? this.loadedAt,
    publicationStatus: publicationStatus ?? this.publicationStatus,
    sourceFileName: sourceFileName.present
        ? sourceFileName.value
        : this.sourceFileName,
    totalClasses: totalClasses ?? this.totalClasses,
  );
  ProcessedScheduleRow copyWithCompanion(ProcessedSchedulesCompanion data) {
    return ProcessedScheduleRow(
      id: data.id.present ? data.id.value : this.id,
      loadedAt: data.loadedAt.present ? data.loadedAt.value : this.loadedAt,
      publicationStatus: data.publicationStatus.present
          ? data.publicationStatus.value
          : this.publicationStatus,
      sourceFileName: data.sourceFileName.present
          ? data.sourceFileName.value
          : this.sourceFileName,
      totalClasses: data.totalClasses.present
          ? data.totalClasses.value
          : this.totalClasses,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessedScheduleRow(')
          ..write('id: $id, ')
          ..write('loadedAt: $loadedAt, ')
          ..write('publicationStatus: $publicationStatus, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('totalClasses: $totalClasses')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    loadedAt,
    publicationStatus,
    sourceFileName,
    totalClasses,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessedScheduleRow &&
          other.id == this.id &&
          other.loadedAt == this.loadedAt &&
          other.publicationStatus == this.publicationStatus &&
          other.sourceFileName == this.sourceFileName &&
          other.totalClasses == this.totalClasses);
}

class ProcessedSchedulesCompanion
    extends UpdateCompanion<ProcessedScheduleRow> {
  final Value<int> id;
  final Value<DateTime> loadedAt;
  final Value<String> publicationStatus;
  final Value<String?> sourceFileName;
  final Value<int> totalClasses;
  const ProcessedSchedulesCompanion({
    this.id = const Value.absent(),
    this.loadedAt = const Value.absent(),
    this.publicationStatus = const Value.absent(),
    this.sourceFileName = const Value.absent(),
    this.totalClasses = const Value.absent(),
  });
  ProcessedSchedulesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime loadedAt,
    required String publicationStatus,
    this.sourceFileName = const Value.absent(),
    this.totalClasses = const Value.absent(),
  }) : loadedAt = Value(loadedAt),
       publicationStatus = Value(publicationStatus);
  static Insertable<ProcessedScheduleRow> custom({
    Expression<int>? id,
    Expression<DateTime>? loadedAt,
    Expression<String>? publicationStatus,
    Expression<String>? sourceFileName,
    Expression<int>? totalClasses,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loadedAt != null) 'loaded_at': loadedAt,
      if (publicationStatus != null) 'publication_status': publicationStatus,
      if (sourceFileName != null) 'source_file_name': sourceFileName,
      if (totalClasses != null) 'total_classes': totalClasses,
    });
  }

  ProcessedSchedulesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? loadedAt,
    Value<String>? publicationStatus,
    Value<String?>? sourceFileName,
    Value<int>? totalClasses,
  }) {
    return ProcessedSchedulesCompanion(
      id: id ?? this.id,
      loadedAt: loadedAt ?? this.loadedAt,
      publicationStatus: publicationStatus ?? this.publicationStatus,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      totalClasses: totalClasses ?? this.totalClasses,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (loadedAt.present) {
      map['loaded_at'] = Variable<DateTime>(loadedAt.value);
    }
    if (publicationStatus.present) {
      map['publication_status'] = Variable<String>(publicationStatus.value);
    }
    if (sourceFileName.present) {
      map['source_file_name'] = Variable<String>(sourceFileName.value);
    }
    if (totalClasses.present) {
      map['total_classes'] = Variable<int>(totalClasses.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessedSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('loadedAt: $loadedAt, ')
          ..write('publicationStatus: $publicationStatus, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('totalClasses: $totalClasses')
          ..write(')'))
        .toString();
  }
}

class $ClassSessionsTable extends ClassSessions
    with TableInfo<$ClassSessionsTable, ClassSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<int> scheduleId = GeneratedColumn<int>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES processed_schedules (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _subjectNameMeta = const VerificationMeta(
    'subjectName',
  );
  @override
  late final GeneratedColumn<String> subjectName = GeneratedColumn<String>(
    'subject_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teacherNameMeta = const VerificationMeta(
    'teacherName',
  );
  @override
  late final GeneratedColumn<String> teacherName = GeneratedColumn<String>(
    'teacher_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    check: () => ComparableExpr(dayOfWeek).isBetweenValues(1, 7),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 4,
      maxTextLength: 8,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 4,
      maxTextLength: 8,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classroomNameMeta = const VerificationMeta(
    'classroomName',
  );
  @override
  late final GeneratedColumn<String> classroomName = GeneratedColumn<String>(
    'classroom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _classroomStatusMeta = const VerificationMeta(
    'classroomStatus',
  );
  @override
  late final GeneratedColumn<String> classroomStatus = GeneratedColumn<String>(
    'classroom_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scheduleId,
    subjectName,
    groupName,
    teacherName,
    dayOfWeek,
    startTime,
    endTime,
    classroomName,
    classroomStatus,
    rawText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('subject_name')) {
      context.handle(
        _subjectNameMeta,
        subjectName.isAcceptableOrUnknown(
          data['subject_name']!,
          _subjectNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectNameMeta);
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('teacher_name')) {
      context.handle(
        _teacherNameMeta,
        teacherName.isAcceptableOrUnknown(
          data['teacher_name']!,
          _teacherNameMeta,
        ),
      );
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('classroom_name')) {
      context.handle(
        _classroomNameMeta,
        classroomName.isAcceptableOrUnknown(
          data['classroom_name']!,
          _classroomNameMeta,
        ),
      );
    }
    if (data.containsKey('classroom_status')) {
      context.handle(
        _classroomStatusMeta,
        classroomStatus.isAcceptableOrUnknown(
          data['classroom_status']!,
          _classroomStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classroomStatusMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_id'],
      )!,
      subjectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_name'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      teacherName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_name'],
      ),
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      classroomName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom_name'],
      ),
      classroomStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom_status'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      ),
    );
  }

  @override
  $ClassSessionsTable createAlias(String alias) {
    return $ClassSessionsTable(attachedDatabase, alias);
  }
}

class ClassSessionRow extends DataClass implements Insertable<ClassSessionRow> {
  final int id;
  final int scheduleId;
  final String subjectName;
  final String? groupName;
  final String? teacherName;

  /// 1 = lunes … 6 = sábado.
  final int dayOfWeek;

  /// `HH:mm`
  final String startTime;

  /// `HH:mm`
  final String endTime;
  final String? classroomName;
  final String classroomStatus;
  final String? rawText;
  const ClassSessionRow({
    required this.id,
    required this.scheduleId,
    required this.subjectName,
    this.groupName,
    this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classroomName,
    required this.classroomStatus,
    this.rawText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['schedule_id'] = Variable<int>(scheduleId);
    map['subject_name'] = Variable<String>(subjectName);
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    if (!nullToAbsent || teacherName != null) {
      map['teacher_name'] = Variable<String>(teacherName);
    }
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    if (!nullToAbsent || classroomName != null) {
      map['classroom_name'] = Variable<String>(classroomName);
    }
    map['classroom_status'] = Variable<String>(classroomStatus);
    if (!nullToAbsent || rawText != null) {
      map['raw_text'] = Variable<String>(rawText);
    }
    return map;
  }

  ClassSessionsCompanion toCompanion(bool nullToAbsent) {
    return ClassSessionsCompanion(
      id: Value(id),
      scheduleId: Value(scheduleId),
      subjectName: Value(subjectName),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      teacherName: teacherName == null && nullToAbsent
          ? const Value.absent()
          : Value(teacherName),
      dayOfWeek: Value(dayOfWeek),
      startTime: Value(startTime),
      endTime: Value(endTime),
      classroomName: classroomName == null && nullToAbsent
          ? const Value.absent()
          : Value(classroomName),
      classroomStatus: Value(classroomStatus),
      rawText: rawText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawText),
    );
  }

  factory ClassSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassSessionRow(
      id: serializer.fromJson<int>(json['id']),
      scheduleId: serializer.fromJson<int>(json['scheduleId']),
      subjectName: serializer.fromJson<String>(json['subjectName']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      teacherName: serializer.fromJson<String?>(json['teacherName']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      classroomName: serializer.fromJson<String?>(json['classroomName']),
      classroomStatus: serializer.fromJson<String>(json['classroomStatus']),
      rawText: serializer.fromJson<String?>(json['rawText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scheduleId': serializer.toJson<int>(scheduleId),
      'subjectName': serializer.toJson<String>(subjectName),
      'groupName': serializer.toJson<String?>(groupName),
      'teacherName': serializer.toJson<String?>(teacherName),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'classroomName': serializer.toJson<String?>(classroomName),
      'classroomStatus': serializer.toJson<String>(classroomStatus),
      'rawText': serializer.toJson<String?>(rawText),
    };
  }

  ClassSessionRow copyWith({
    int? id,
    int? scheduleId,
    String? subjectName,
    Value<String?> groupName = const Value.absent(),
    Value<String?> teacherName = const Value.absent(),
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    Value<String?> classroomName = const Value.absent(),
    String? classroomStatus,
    Value<String?> rawText = const Value.absent(),
  }) => ClassSessionRow(
    id: id ?? this.id,
    scheduleId: scheduleId ?? this.scheduleId,
    subjectName: subjectName ?? this.subjectName,
    groupName: groupName.present ? groupName.value : this.groupName,
    teacherName: teacherName.present ? teacherName.value : this.teacherName,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    classroomName: classroomName.present
        ? classroomName.value
        : this.classroomName,
    classroomStatus: classroomStatus ?? this.classroomStatus,
    rawText: rawText.present ? rawText.value : this.rawText,
  );
  ClassSessionRow copyWithCompanion(ClassSessionsCompanion data) {
    return ClassSessionRow(
      id: data.id.present ? data.id.value : this.id,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      subjectName: data.subjectName.present
          ? data.subjectName.value
          : this.subjectName,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      teacherName: data.teacherName.present
          ? data.teacherName.value
          : this.teacherName,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      classroomName: data.classroomName.present
          ? data.classroomName.value
          : this.classroomName,
      classroomStatus: data.classroomStatus.present
          ? data.classroomStatus.value
          : this.classroomStatus,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassSessionRow(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('subjectName: $subjectName, ')
          ..write('groupName: $groupName, ')
          ..write('teacherName: $teacherName, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('classroomName: $classroomName, ')
          ..write('classroomStatus: $classroomStatus, ')
          ..write('rawText: $rawText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scheduleId,
    subjectName,
    groupName,
    teacherName,
    dayOfWeek,
    startTime,
    endTime,
    classroomName,
    classroomStatus,
    rawText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassSessionRow &&
          other.id == this.id &&
          other.scheduleId == this.scheduleId &&
          other.subjectName == this.subjectName &&
          other.groupName == this.groupName &&
          other.teacherName == this.teacherName &&
          other.dayOfWeek == this.dayOfWeek &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.classroomName == this.classroomName &&
          other.classroomStatus == this.classroomStatus &&
          other.rawText == this.rawText);
}

class ClassSessionsCompanion extends UpdateCompanion<ClassSessionRow> {
  final Value<int> id;
  final Value<int> scheduleId;
  final Value<String> subjectName;
  final Value<String?> groupName;
  final Value<String?> teacherName;
  final Value<int> dayOfWeek;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String?> classroomName;
  final Value<String> classroomStatus;
  final Value<String?> rawText;
  const ClassSessionsCompanion({
    this.id = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.subjectName = const Value.absent(),
    this.groupName = const Value.absent(),
    this.teacherName = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.classroomName = const Value.absent(),
    this.classroomStatus = const Value.absent(),
    this.rawText = const Value.absent(),
  });
  ClassSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int scheduleId,
    required String subjectName,
    this.groupName = const Value.absent(),
    this.teacherName = const Value.absent(),
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    this.classroomName = const Value.absent(),
    required String classroomStatus,
    this.rawText = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       subjectName = Value(subjectName),
       dayOfWeek = Value(dayOfWeek),
       startTime = Value(startTime),
       endTime = Value(endTime),
       classroomStatus = Value(classroomStatus);
  static Insertable<ClassSessionRow> custom({
    Expression<int>? id,
    Expression<int>? scheduleId,
    Expression<String>? subjectName,
    Expression<String>? groupName,
    Expression<String>? teacherName,
    Expression<int>? dayOfWeek,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? classroomName,
    Expression<String>? classroomStatus,
    Expression<String>? rawText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (subjectName != null) 'subject_name': subjectName,
      if (groupName != null) 'group_name': groupName,
      if (teacherName != null) 'teacher_name': teacherName,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (classroomName != null) 'classroom_name': classroomName,
      if (classroomStatus != null) 'classroom_status': classroomStatus,
      if (rawText != null) 'raw_text': rawText,
    });
  }

  ClassSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? scheduleId,
    Value<String>? subjectName,
    Value<String?>? groupName,
    Value<String?>? teacherName,
    Value<int>? dayOfWeek,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<String?>? classroomName,
    Value<String>? classroomStatus,
    Value<String?>? rawText,
  }) {
    return ClassSessionsCompanion(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      subjectName: subjectName ?? this.subjectName,
      groupName: groupName ?? this.groupName,
      teacherName: teacherName ?? this.teacherName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classroomName: classroomName ?? this.classroomName,
      classroomStatus: classroomStatus ?? this.classroomStatus,
      rawText: rawText ?? this.rawText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<int>(scheduleId.value);
    }
    if (subjectName.present) {
      map['subject_name'] = Variable<String>(subjectName.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (teacherName.present) {
      map['teacher_name'] = Variable<String>(teacherName.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (classroomName.present) {
      map['classroom_name'] = Variable<String>(classroomName.value);
    }
    if (classroomStatus.present) {
      map['classroom_status'] = Variable<String>(classroomStatus.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassSessionsCompanion(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('subjectName: $subjectName, ')
          ..write('groupName: $groupName, ')
          ..write('teacherName: $teacherName, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('classroomName: $classroomName, ')
          ..write('classroomStatus: $classroomStatus, ')
          ..write('rawText: $rawText')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTableTable extends LocalSettingsTable
    with TableInfo<$LocalSettingsTableTable, LocalSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userAliasMeta = const VerificationMeta(
    'userAlias',
  );
  @override
  late final GeneratedColumn<String> userAlias = GeneratedColumn<String>(
    'user_alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Alumno'),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SYSTEM'),
  );
  static const VerificationMeta _schedulePaletteModeMeta =
      const VerificationMeta('schedulePaletteMode');
  @override
  late final GeneratedColumn<String> schedulePaletteMode =
      GeneratedColumn<String>(
        'schedule_palette_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('INSTITUTIONAL'),
      );
  static const VerificationMeta _customScheduleColorsMeta =
      const VerificationMeta('customScheduleColors');
  @override
  late final GeneratedColumn<String> customScheduleColors =
      GeneratedColumn<String>(
        'custom_schedule_colors',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _classNotificationMinutesMeta =
      const VerificationMeta('classNotificationMinutes');
  @override
  late final GeneratedColumn<int> classNotificationMinutes =
      GeneratedColumn<int>(
        'class_notification_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(10),
      );
  static const VerificationMeta _enableStartClassNotificationMeta =
      const VerificationMeta('enableStartClassNotification');
  @override
  late final GeneratedColumn<bool> enableStartClassNotification =
      GeneratedColumn<bool>(
        'enable_start_class_notification',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_start_class_notification" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _notificationScopeMeta = const VerificationMeta(
    'notificationScope',
  );
  @override
  late final GeneratedColumn<String> notificationScope =
      GeneratedColumn<String>(
        'notification_scope',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('ALL_SUBJECTS'),
      );
  static const VerificationMeta _notificationSubjectsMeta =
      const VerificationMeta('notificationSubjects');
  @override
  late final GeneratedColumn<String> notificationSubjects =
      GeneratedColumn<String>(
        'notification_subjects',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _interfaceLanguageMeta = const VerificationMeta(
    'interfaceLanguage',
  );
  @override
  late final GeneratedColumn<String> interfaceLanguage =
      GeneratedColumn<String>(
        'interface_language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('es'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userAlias,
    themeMode,
    schedulePaletteMode,
    customScheduleColors,
    classNotificationMinutes,
    enableStartClassNotification,
    notificationScope,
    notificationSubjects,
    interfaceLanguage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_alias')) {
      context.handle(
        _userAliasMeta,
        userAlias.isAcceptableOrUnknown(data['user_alias']!, _userAliasMeta),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('schedule_palette_mode')) {
      context.handle(
        _schedulePaletteModeMeta,
        schedulePaletteMode.isAcceptableOrUnknown(
          data['schedule_palette_mode']!,
          _schedulePaletteModeMeta,
        ),
      );
    }
    if (data.containsKey('custom_schedule_colors')) {
      context.handle(
        _customScheduleColorsMeta,
        customScheduleColors.isAcceptableOrUnknown(
          data['custom_schedule_colors']!,
          _customScheduleColorsMeta,
        ),
      );
    }
    if (data.containsKey('class_notification_minutes')) {
      context.handle(
        _classNotificationMinutesMeta,
        classNotificationMinutes.isAcceptableOrUnknown(
          data['class_notification_minutes']!,
          _classNotificationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('enable_start_class_notification')) {
      context.handle(
        _enableStartClassNotificationMeta,
        enableStartClassNotification.isAcceptableOrUnknown(
          data['enable_start_class_notification']!,
          _enableStartClassNotificationMeta,
        ),
      );
    }
    if (data.containsKey('notification_scope')) {
      context.handle(
        _notificationScopeMeta,
        notificationScope.isAcceptableOrUnknown(
          data['notification_scope']!,
          _notificationScopeMeta,
        ),
      );
    }
    if (data.containsKey('notification_subjects')) {
      context.handle(
        _notificationSubjectsMeta,
        notificationSubjects.isAcceptableOrUnknown(
          data['notification_subjects']!,
          _notificationSubjectsMeta,
        ),
      );
    }
    if (data.containsKey('interface_language')) {
      context.handle(
        _interfaceLanguageMeta,
        interfaceLanguage.isAcceptableOrUnknown(
          data['interface_language']!,
          _interfaceLanguageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userAlias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_alias'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      schedulePaletteMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_palette_mode'],
      )!,
      customScheduleColors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_schedule_colors'],
      )!,
      classNotificationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_notification_minutes'],
      )!,
      enableStartClassNotification: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enable_start_class_notification'],
      )!,
      notificationScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_scope'],
      )!,
      notificationSubjects: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_subjects'],
      )!,
      interfaceLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interface_language'],
      )!,
    );
  }

  @override
  $LocalSettingsTableTable createAlias(String alias) {
    return $LocalSettingsTableTable(attachedDatabase, alias);
  }
}

class LocalSettingsRow extends DataClass
    implements Insertable<LocalSettingsRow> {
  final int id;
  final String userAlias;
  final String themeMode;
  final String schedulePaletteMode;
  final String customScheduleColors;
  final int classNotificationMinutes;
  final bool enableStartClassNotification;
  final String notificationScope;
  final String notificationSubjects;
  final String interfaceLanguage;
  const LocalSettingsRow({
    required this.id,
    required this.userAlias,
    required this.themeMode,
    required this.schedulePaletteMode,
    required this.customScheduleColors,
    required this.classNotificationMinutes,
    required this.enableStartClassNotification,
    required this.notificationScope,
    required this.notificationSubjects,
    required this.interfaceLanguage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_alias'] = Variable<String>(userAlias);
    map['theme_mode'] = Variable<String>(themeMode);
    map['schedule_palette_mode'] = Variable<String>(schedulePaletteMode);
    map['custom_schedule_colors'] = Variable<String>(customScheduleColors);
    map['class_notification_minutes'] = Variable<int>(classNotificationMinutes);
    map['enable_start_class_notification'] = Variable<bool>(
      enableStartClassNotification,
    );
    map['notification_scope'] = Variable<String>(notificationScope);
    map['notification_subjects'] = Variable<String>(notificationSubjects);
    map['interface_language'] = Variable<String>(interfaceLanguage);
    return map;
  }

  LocalSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsTableCompanion(
      id: Value(id),
      userAlias: Value(userAlias),
      themeMode: Value(themeMode),
      schedulePaletteMode: Value(schedulePaletteMode),
      customScheduleColors: Value(customScheduleColors),
      classNotificationMinutes: Value(classNotificationMinutes),
      enableStartClassNotification: Value(enableStartClassNotification),
      notificationScope: Value(notificationScope),
      notificationSubjects: Value(notificationSubjects),
      interfaceLanguage: Value(interfaceLanguage),
    );
  }

  factory LocalSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      userAlias: serializer.fromJson<String>(json['userAlias']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      schedulePaletteMode: serializer.fromJson<String>(
        json['schedulePaletteMode'],
      ),
      customScheduleColors: serializer.fromJson<String>(
        json['customScheduleColors'],
      ),
      classNotificationMinutes: serializer.fromJson<int>(
        json['classNotificationMinutes'],
      ),
      enableStartClassNotification: serializer.fromJson<bool>(
        json['enableStartClassNotification'],
      ),
      notificationScope: serializer.fromJson<String>(json['notificationScope']),
      notificationSubjects: serializer.fromJson<String>(
        json['notificationSubjects'],
      ),
      interfaceLanguage: serializer.fromJson<String>(json['interfaceLanguage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userAlias': serializer.toJson<String>(userAlias),
      'themeMode': serializer.toJson<String>(themeMode),
      'schedulePaletteMode': serializer.toJson<String>(schedulePaletteMode),
      'customScheduleColors': serializer.toJson<String>(customScheduleColors),
      'classNotificationMinutes': serializer.toJson<int>(
        classNotificationMinutes,
      ),
      'enableStartClassNotification': serializer.toJson<bool>(
        enableStartClassNotification,
      ),
      'notificationScope': serializer.toJson<String>(notificationScope),
      'notificationSubjects': serializer.toJson<String>(notificationSubjects),
      'interfaceLanguage': serializer.toJson<String>(interfaceLanguage),
    };
  }

  LocalSettingsRow copyWith({
    int? id,
    String? userAlias,
    String? themeMode,
    String? schedulePaletteMode,
    String? customScheduleColors,
    int? classNotificationMinutes,
    bool? enableStartClassNotification,
    String? notificationScope,
    String? notificationSubjects,
    String? interfaceLanguage,
  }) => LocalSettingsRow(
    id: id ?? this.id,
    userAlias: userAlias ?? this.userAlias,
    themeMode: themeMode ?? this.themeMode,
    schedulePaletteMode: schedulePaletteMode ?? this.schedulePaletteMode,
    customScheduleColors: customScheduleColors ?? this.customScheduleColors,
    classNotificationMinutes:
        classNotificationMinutes ?? this.classNotificationMinutes,
    enableStartClassNotification:
        enableStartClassNotification ?? this.enableStartClassNotification,
    notificationScope: notificationScope ?? this.notificationScope,
    notificationSubjects: notificationSubjects ?? this.notificationSubjects,
    interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
  );
  LocalSettingsRow copyWithCompanion(LocalSettingsTableCompanion data) {
    return LocalSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      userAlias: data.userAlias.present ? data.userAlias.value : this.userAlias,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      schedulePaletteMode: data.schedulePaletteMode.present
          ? data.schedulePaletteMode.value
          : this.schedulePaletteMode,
      customScheduleColors: data.customScheduleColors.present
          ? data.customScheduleColors.value
          : this.customScheduleColors,
      classNotificationMinutes: data.classNotificationMinutes.present
          ? data.classNotificationMinutes.value
          : this.classNotificationMinutes,
      enableStartClassNotification: data.enableStartClassNotification.present
          ? data.enableStartClassNotification.value
          : this.enableStartClassNotification,
      notificationScope: data.notificationScope.present
          ? data.notificationScope.value
          : this.notificationScope,
      notificationSubjects: data.notificationSubjects.present
          ? data.notificationSubjects.value
          : this.notificationSubjects,
      interfaceLanguage: data.interfaceLanguage.present
          ? data.interfaceLanguage.value
          : this.interfaceLanguage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsRow(')
          ..write('id: $id, ')
          ..write('userAlias: $userAlias, ')
          ..write('themeMode: $themeMode, ')
          ..write('schedulePaletteMode: $schedulePaletteMode, ')
          ..write('customScheduleColors: $customScheduleColors, ')
          ..write('classNotificationMinutes: $classNotificationMinutes, ')
          ..write(
            'enableStartClassNotification: $enableStartClassNotification, ',
          )
          ..write('notificationScope: $notificationScope, ')
          ..write('notificationSubjects: $notificationSubjects, ')
          ..write('interfaceLanguage: $interfaceLanguage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userAlias,
    themeMode,
    schedulePaletteMode,
    customScheduleColors,
    classNotificationMinutes,
    enableStartClassNotification,
    notificationScope,
    notificationSubjects,
    interfaceLanguage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSettingsRow &&
          other.id == this.id &&
          other.userAlias == this.userAlias &&
          other.themeMode == this.themeMode &&
          other.schedulePaletteMode == this.schedulePaletteMode &&
          other.customScheduleColors == this.customScheduleColors &&
          other.classNotificationMinutes == this.classNotificationMinutes &&
          other.enableStartClassNotification ==
              this.enableStartClassNotification &&
          other.notificationScope == this.notificationScope &&
          other.notificationSubjects == this.notificationSubjects &&
          other.interfaceLanguage == this.interfaceLanguage);
}

class LocalSettingsTableCompanion extends UpdateCompanion<LocalSettingsRow> {
  final Value<int> id;
  final Value<String> userAlias;
  final Value<String> themeMode;
  final Value<String> schedulePaletteMode;
  final Value<String> customScheduleColors;
  final Value<int> classNotificationMinutes;
  final Value<bool> enableStartClassNotification;
  final Value<String> notificationScope;
  final Value<String> notificationSubjects;
  final Value<String> interfaceLanguage;
  const LocalSettingsTableCompanion({
    this.id = const Value.absent(),
    this.userAlias = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.schedulePaletteMode = const Value.absent(),
    this.customScheduleColors = const Value.absent(),
    this.classNotificationMinutes = const Value.absent(),
    this.enableStartClassNotification = const Value.absent(),
    this.notificationScope = const Value.absent(),
    this.notificationSubjects = const Value.absent(),
    this.interfaceLanguage = const Value.absent(),
  });
  LocalSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.userAlias = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.schedulePaletteMode = const Value.absent(),
    this.customScheduleColors = const Value.absent(),
    this.classNotificationMinutes = const Value.absent(),
    this.enableStartClassNotification = const Value.absent(),
    this.notificationScope = const Value.absent(),
    this.notificationSubjects = const Value.absent(),
    this.interfaceLanguage = const Value.absent(),
  });
  static Insertable<LocalSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? userAlias,
    Expression<String>? themeMode,
    Expression<String>? schedulePaletteMode,
    Expression<String>? customScheduleColors,
    Expression<int>? classNotificationMinutes,
    Expression<bool>? enableStartClassNotification,
    Expression<String>? notificationScope,
    Expression<String>? notificationSubjects,
    Expression<String>? interfaceLanguage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userAlias != null) 'user_alias': userAlias,
      if (themeMode != null) 'theme_mode': themeMode,
      if (schedulePaletteMode != null)
        'schedule_palette_mode': schedulePaletteMode,
      if (customScheduleColors != null)
        'custom_schedule_colors': customScheduleColors,
      if (classNotificationMinutes != null)
        'class_notification_minutes': classNotificationMinutes,
      if (enableStartClassNotification != null)
        'enable_start_class_notification': enableStartClassNotification,
      if (notificationScope != null) 'notification_scope': notificationScope,
      if (notificationSubjects != null)
        'notification_subjects': notificationSubjects,
      if (interfaceLanguage != null) 'interface_language': interfaceLanguage,
    });
  }

  LocalSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? userAlias,
    Value<String>? themeMode,
    Value<String>? schedulePaletteMode,
    Value<String>? customScheduleColors,
    Value<int>? classNotificationMinutes,
    Value<bool>? enableStartClassNotification,
    Value<String>? notificationScope,
    Value<String>? notificationSubjects,
    Value<String>? interfaceLanguage,
  }) {
    return LocalSettingsTableCompanion(
      id: id ?? this.id,
      userAlias: userAlias ?? this.userAlias,
      themeMode: themeMode ?? this.themeMode,
      schedulePaletteMode: schedulePaletteMode ?? this.schedulePaletteMode,
      customScheduleColors: customScheduleColors ?? this.customScheduleColors,
      classNotificationMinutes:
          classNotificationMinutes ?? this.classNotificationMinutes,
      enableStartClassNotification:
          enableStartClassNotification ?? this.enableStartClassNotification,
      notificationScope: notificationScope ?? this.notificationScope,
      notificationSubjects: notificationSubjects ?? this.notificationSubjects,
      interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userAlias.present) {
      map['user_alias'] = Variable<String>(userAlias.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (schedulePaletteMode.present) {
      map['schedule_palette_mode'] = Variable<String>(
        schedulePaletteMode.value,
      );
    }
    if (customScheduleColors.present) {
      map['custom_schedule_colors'] = Variable<String>(
        customScheduleColors.value,
      );
    }
    if (classNotificationMinutes.present) {
      map['class_notification_minutes'] = Variable<int>(
        classNotificationMinutes.value,
      );
    }
    if (enableStartClassNotification.present) {
      map['enable_start_class_notification'] = Variable<bool>(
        enableStartClassNotification.value,
      );
    }
    if (notificationScope.present) {
      map['notification_scope'] = Variable<String>(notificationScope.value);
    }
    if (notificationSubjects.present) {
      map['notification_subjects'] = Variable<String>(
        notificationSubjects.value,
      );
    }
    if (interfaceLanguage.present) {
      map['interface_language'] = Variable<String>(interfaceLanguage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('userAlias: $userAlias, ')
          ..write('themeMode: $themeMode, ')
          ..write('schedulePaletteMode: $schedulePaletteMode, ')
          ..write('customScheduleColors: $customScheduleColors, ')
          ..write('classNotificationMinutes: $classNotificationMinutes, ')
          ..write(
            'enableStartClassNotification: $enableStartClassNotification, ',
          )
          ..write('notificationScope: $notificationScope, ')
          ..write('notificationSubjects: $notificationSubjects, ')
          ..write('interfaceLanguage: $interfaceLanguage')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProcessedSchedulesTable processedSchedules =
      $ProcessedSchedulesTable(this);
  late final $ClassSessionsTable classSessions = $ClassSessionsTable(this);
  late final $LocalSettingsTableTable localSettingsTable =
      $LocalSettingsTableTable(this);
  late final Index idxClassSessionsScheduleId = Index(
    'idx_class_sessions_schedule_id',
    'CREATE INDEX idx_class_sessions_schedule_id ON class_sessions (schedule_id)',
  );
  late final Index idxClassSessionsDayOfWeek = Index(
    'idx_class_sessions_day_of_week',
    'CREATE INDEX idx_class_sessions_day_of_week ON class_sessions (day_of_week)',
  );
  late final ScheduleDao scheduleDao = ScheduleDao(this as AppDatabase);
  late final LocalSettingsDao localSettingsDao = LocalSettingsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    processedSchedules,
    classSessions,
    localSettingsTable,
    idxClassSessionsScheduleId,
    idxClassSessionsDayOfWeek,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'processed_schedules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('class_sessions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProcessedSchedulesTableCreateCompanionBuilder =
    ProcessedSchedulesCompanion Function({
      Value<int> id,
      required DateTime loadedAt,
      required String publicationStatus,
      Value<String?> sourceFileName,
      Value<int> totalClasses,
    });
typedef $$ProcessedSchedulesTableUpdateCompanionBuilder =
    ProcessedSchedulesCompanion Function({
      Value<int> id,
      Value<DateTime> loadedAt,
      Value<String> publicationStatus,
      Value<String?> sourceFileName,
      Value<int> totalClasses,
    });

final class $$ProcessedSchedulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProcessedSchedulesTable,
          ProcessedScheduleRow
        > {
  $$ProcessedSchedulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ClassSessionsTable, List<ClassSessionRow>>
  _classSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.classSessions,
    aliasName: 'processed_schedules__id__class_sessions__schedule_id',
  );

  $$ClassSessionsTableProcessedTableManager get classSessionsRefs {
    final manager = $$ClassSessionsTableTableManager(
      $_db,
      $_db.classSessions,
    ).filter((f) => f.scheduleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_classSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProcessedSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $ProcessedSchedulesTable> {
  $$ProcessedSchedulesTableFilterComposer({
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

  ColumnFilters<DateTime> get loadedAt => $composableBuilder(
    column: $table.loadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicationStatus => $composableBuilder(
    column: $table.publicationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFileName => $composableBuilder(
    column: $table.sourceFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalClasses => $composableBuilder(
    column: $table.totalClasses,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> classSessionsRefs(
    Expression<bool> Function($$ClassSessionsTableFilterComposer f) f,
  ) {
    final $$ClassSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classSessions,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSessionsTableFilterComposer(
            $db: $db,
            $table: $db.classSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProcessedSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProcessedSchedulesTable> {
  $$ProcessedSchedulesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get loadedAt => $composableBuilder(
    column: $table.loadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicationStatus => $composableBuilder(
    column: $table.publicationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFileName => $composableBuilder(
    column: $table.sourceFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalClasses => $composableBuilder(
    column: $table.totalClasses,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProcessedSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProcessedSchedulesTable> {
  $$ProcessedSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get loadedAt =>
      $composableBuilder(column: $table.loadedAt, builder: (column) => column);

  GeneratedColumn<String> get publicationStatus => $composableBuilder(
    column: $table.publicationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceFileName => $composableBuilder(
    column: $table.sourceFileName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalClasses => $composableBuilder(
    column: $table.totalClasses,
    builder: (column) => column,
  );

  Expression<T> classSessionsRefs<T extends Object>(
    Expression<T> Function($$ClassSessionsTableAnnotationComposer a) f,
  ) {
    final $$ClassSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classSessions,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.classSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProcessedSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProcessedSchedulesTable,
          ProcessedScheduleRow,
          $$ProcessedSchedulesTableFilterComposer,
          $$ProcessedSchedulesTableOrderingComposer,
          $$ProcessedSchedulesTableAnnotationComposer,
          $$ProcessedSchedulesTableCreateCompanionBuilder,
          $$ProcessedSchedulesTableUpdateCompanionBuilder,
          (ProcessedScheduleRow, $$ProcessedSchedulesTableReferences),
          ProcessedScheduleRow,
          PrefetchHooks Function({bool classSessionsRefs})
        > {
  $$ProcessedSchedulesTableTableManager(
    _$AppDatabase db,
    $ProcessedSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessedSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessedSchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessedSchedulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> loadedAt = const Value.absent(),
                Value<String> publicationStatus = const Value.absent(),
                Value<String?> sourceFileName = const Value.absent(),
                Value<int> totalClasses = const Value.absent(),
              }) => ProcessedSchedulesCompanion(
                id: id,
                loadedAt: loadedAt,
                publicationStatus: publicationStatus,
                sourceFileName: sourceFileName,
                totalClasses: totalClasses,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime loadedAt,
                required String publicationStatus,
                Value<String?> sourceFileName = const Value.absent(),
                Value<int> totalClasses = const Value.absent(),
              }) => ProcessedSchedulesCompanion.insert(
                id: id,
                loadedAt: loadedAt,
                publicationStatus: publicationStatus,
                sourceFileName: sourceFileName,
                totalClasses: totalClasses,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProcessedSchedulesTable, ProcessedScheduleRow>(
                    table,
                  ),
                  $$ProcessedSchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({classSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (classSessionsRefs) db.classSessions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (classSessionsRefs)
                    await $_getPrefetchedDataByColumns<
                      ProcessedScheduleRow,
                      $ProcessedSchedulesTable,
                      ClassSessionRow,
                      $ClassSessionsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ProcessedSchedulesTableReferences
                          ._classSessionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProcessedSchedulesTableReferences(
                            db,
                            table,
                            p0,
                          ).classSessionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'schedule_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProcessedSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProcessedSchedulesTable,
      ProcessedScheduleRow,
      $$ProcessedSchedulesTableFilterComposer,
      $$ProcessedSchedulesTableOrderingComposer,
      $$ProcessedSchedulesTableAnnotationComposer,
      $$ProcessedSchedulesTableCreateCompanionBuilder,
      $$ProcessedSchedulesTableUpdateCompanionBuilder,
      (ProcessedScheduleRow, $$ProcessedSchedulesTableReferences),
      ProcessedScheduleRow,
      PrefetchHooks Function({bool classSessionsRefs})
    >;
typedef $$ClassSessionsTableCreateCompanionBuilder =
    ClassSessionsCompanion Function({
      Value<int> id,
      required int scheduleId,
      required String subjectName,
      Value<String?> groupName,
      Value<String?> teacherName,
      required int dayOfWeek,
      required String startTime,
      required String endTime,
      Value<String?> classroomName,
      required String classroomStatus,
      Value<String?> rawText,
    });
typedef $$ClassSessionsTableUpdateCompanionBuilder =
    ClassSessionsCompanion Function({
      Value<int> id,
      Value<int> scheduleId,
      Value<String> subjectName,
      Value<String?> groupName,
      Value<String?> teacherName,
      Value<int> dayOfWeek,
      Value<String> startTime,
      Value<String> endTime,
      Value<String?> classroomName,
      Value<String> classroomStatus,
      Value<String?> rawText,
    });

final class $$ClassSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ClassSessionsTable, ClassSessionRow> {
  $$ClassSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProcessedSchedulesTable _scheduleIdTable(_$AppDatabase db) => db
      .processedSchedules
      .createAlias('class_sessions__schedule_id__processed_schedules__id');

  $$ProcessedSchedulesTableProcessedTableManager get scheduleId {
    final $_column = $_itemColumn<int>('schedule_id')!;

    final manager = $$ProcessedSchedulesTableTableManager(
      $_db,
      $_db.processedSchedules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClassSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ClassSessionsTable> {
  $$ClassSessionsTableFilterComposer({
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

  ColumnFilters<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacherName => $composableBuilder(
    column: $table.teacherName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classroomName => $composableBuilder(
    column: $table.classroomName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classroomStatus => $composableBuilder(
    column: $table.classroomStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  $$ProcessedSchedulesTableFilterComposer get scheduleId {
    final $$ProcessedSchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.processedSchedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessedSchedulesTableFilterComposer(
            $db: $db,
            $table: $db.processedSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassSessionsTable> {
  $$ClassSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacherName => $composableBuilder(
    column: $table.teacherName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classroomName => $composableBuilder(
    column: $table.classroomName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classroomStatus => $composableBuilder(
    column: $table.classroomStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProcessedSchedulesTableOrderingComposer get scheduleId {
    final $$ProcessedSchedulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.processedSchedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessedSchedulesTableOrderingComposer(
            $db: $db,
            $table: $db.processedSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassSessionsTable> {
  $$ClassSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get teacherName => $composableBuilder(
    column: $table.teacherName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get classroomName => $composableBuilder(
    column: $table.classroomName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get classroomStatus => $composableBuilder(
    column: $table.classroomStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  $$ProcessedSchedulesTableAnnotationComposer get scheduleId {
    final $$ProcessedSchedulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.scheduleId,
          referencedTable: $db.processedSchedules,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProcessedSchedulesTableAnnotationComposer(
                $db: $db,
                $table: $db.processedSchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ClassSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassSessionsTable,
          ClassSessionRow,
          $$ClassSessionsTableFilterComposer,
          $$ClassSessionsTableOrderingComposer,
          $$ClassSessionsTableAnnotationComposer,
          $$ClassSessionsTableCreateCompanionBuilder,
          $$ClassSessionsTableUpdateCompanionBuilder,
          (ClassSessionRow, $$ClassSessionsTableReferences),
          ClassSessionRow,
          PrefetchHooks Function({bool scheduleId})
        > {
  $$ClassSessionsTableTableManager(_$AppDatabase db, $ClassSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scheduleId = const Value.absent(),
                Value<String> subjectName = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<String?> teacherName = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<String?> classroomName = const Value.absent(),
                Value<String> classroomStatus = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
              }) => ClassSessionsCompanion(
                id: id,
                scheduleId: scheduleId,
                subjectName: subjectName,
                groupName: groupName,
                teacherName: teacherName,
                dayOfWeek: dayOfWeek,
                startTime: startTime,
                endTime: endTime,
                classroomName: classroomName,
                classroomStatus: classroomStatus,
                rawText: rawText,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scheduleId,
                required String subjectName,
                Value<String?> groupName = const Value.absent(),
                Value<String?> teacherName = const Value.absent(),
                required int dayOfWeek,
                required String startTime,
                required String endTime,
                Value<String?> classroomName = const Value.absent(),
                required String classroomStatus,
                Value<String?> rawText = const Value.absent(),
              }) => ClassSessionsCompanion.insert(
                id: id,
                scheduleId: scheduleId,
                subjectName: subjectName,
                groupName: groupName,
                teacherName: teacherName,
                dayOfWeek: dayOfWeek,
                startTime: startTime,
                endTime: endTime,
                classroomName: classroomName,
                classroomStatus: classroomStatus,
                rawText: rawText,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClassSessionsTable, ClassSessionRow>(table),
                  $$ClassSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scheduleId = false}) {
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
                    if (scheduleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.scheduleId,
                        referencedTable: $$ClassSessionsTableReferences
                            ._scheduleIdTable(db),
                        referencedColumn: $$ClassSessionsTableReferences
                            ._scheduleIdTable(db)
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

typedef $$ClassSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassSessionsTable,
      ClassSessionRow,
      $$ClassSessionsTableFilterComposer,
      $$ClassSessionsTableOrderingComposer,
      $$ClassSessionsTableAnnotationComposer,
      $$ClassSessionsTableCreateCompanionBuilder,
      $$ClassSessionsTableUpdateCompanionBuilder,
      (ClassSessionRow, $$ClassSessionsTableReferences),
      ClassSessionRow,
      PrefetchHooks Function({bool scheduleId})
    >;
typedef $$LocalSettingsTableTableCreateCompanionBuilder =
    LocalSettingsTableCompanion Function({
      Value<int> id,
      Value<String> userAlias,
      Value<String> themeMode,
      Value<String> schedulePaletteMode,
      Value<String> customScheduleColors,
      Value<int> classNotificationMinutes,
      Value<bool> enableStartClassNotification,
      Value<String> notificationScope,
      Value<String> notificationSubjects,
      Value<String> interfaceLanguage,
    });
typedef $$LocalSettingsTableTableUpdateCompanionBuilder =
    LocalSettingsTableCompanion Function({
      Value<int> id,
      Value<String> userAlias,
      Value<String> themeMode,
      Value<String> schedulePaletteMode,
      Value<String> customScheduleColors,
      Value<int> classNotificationMinutes,
      Value<bool> enableStartClassNotification,
      Value<String> notificationScope,
      Value<String> notificationSubjects,
      Value<String> interfaceLanguage,
    });

class $$LocalSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTableTable> {
  $$LocalSettingsTableTableFilterComposer({
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

  ColumnFilters<String> get userAlias => $composableBuilder(
    column: $table.userAlias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schedulePaletteMode => $composableBuilder(
    column: $table.schedulePaletteMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customScheduleColors => $composableBuilder(
    column: $table.customScheduleColors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get classNotificationMinutes => $composableBuilder(
    column: $table.classNotificationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enableStartClassNotification => $composableBuilder(
    column: $table.enableStartClassNotification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationScope => $composableBuilder(
    column: $table.notificationScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationSubjects => $composableBuilder(
    column: $table.notificationSubjects,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interfaceLanguage => $composableBuilder(
    column: $table.interfaceLanguage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTableTable> {
  $$LocalSettingsTableTableOrderingComposer({
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

  ColumnOrderings<String> get userAlias => $composableBuilder(
    column: $table.userAlias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schedulePaletteMode => $composableBuilder(
    column: $table.schedulePaletteMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customScheduleColors => $composableBuilder(
    column: $table.customScheduleColors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get classNotificationMinutes => $composableBuilder(
    column: $table.classNotificationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enableStartClassNotification => $composableBuilder(
    column: $table.enableStartClassNotification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationScope => $composableBuilder(
    column: $table.notificationScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationSubjects => $composableBuilder(
    column: $table.notificationSubjects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interfaceLanguage => $composableBuilder(
    column: $table.interfaceLanguage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTableTable> {
  $$LocalSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userAlias =>
      $composableBuilder(column: $table.userAlias, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get schedulePaletteMode => $composableBuilder(
    column: $table.schedulePaletteMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customScheduleColors => $composableBuilder(
    column: $table.customScheduleColors,
    builder: (column) => column,
  );

  GeneratedColumn<int> get classNotificationMinutes => $composableBuilder(
    column: $table.classNotificationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enableStartClassNotification => $composableBuilder(
    column: $table.enableStartClassNotification,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notificationScope => $composableBuilder(
    column: $table.notificationScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notificationSubjects => $composableBuilder(
    column: $table.notificationSubjects,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interfaceLanguage => $composableBuilder(
    column: $table.interfaceLanguage,
    builder: (column) => column,
  );
}

class $$LocalSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTableTable,
          LocalSettingsRow,
          $$LocalSettingsTableTableFilterComposer,
          $$LocalSettingsTableTableOrderingComposer,
          $$LocalSettingsTableTableAnnotationComposer,
          $$LocalSettingsTableTableCreateCompanionBuilder,
          $$LocalSettingsTableTableUpdateCompanionBuilder,
          (
            LocalSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $LocalSettingsTableTable,
              LocalSettingsRow
            >,
          ),
          LocalSettingsRow,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableTableManager(
    _$AppDatabase db,
    $LocalSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userAlias = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> schedulePaletteMode = const Value.absent(),
                Value<String> customScheduleColors = const Value.absent(),
                Value<int> classNotificationMinutes = const Value.absent(),
                Value<bool> enableStartClassNotification = const Value.absent(),
                Value<String> notificationScope = const Value.absent(),
                Value<String> notificationSubjects = const Value.absent(),
                Value<String> interfaceLanguage = const Value.absent(),
              }) => LocalSettingsTableCompanion(
                id: id,
                userAlias: userAlias,
                themeMode: themeMode,
                schedulePaletteMode: schedulePaletteMode,
                customScheduleColors: customScheduleColors,
                classNotificationMinutes: classNotificationMinutes,
                enableStartClassNotification: enableStartClassNotification,
                notificationScope: notificationScope,
                notificationSubjects: notificationSubjects,
                interfaceLanguage: interfaceLanguage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userAlias = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> schedulePaletteMode = const Value.absent(),
                Value<String> customScheduleColors = const Value.absent(),
                Value<int> classNotificationMinutes = const Value.absent(),
                Value<bool> enableStartClassNotification = const Value.absent(),
                Value<String> notificationScope = const Value.absent(),
                Value<String> notificationSubjects = const Value.absent(),
                Value<String> interfaceLanguage = const Value.absent(),
              }) => LocalSettingsTableCompanion.insert(
                id: id,
                userAlias: userAlias,
                themeMode: themeMode,
                schedulePaletteMode: schedulePaletteMode,
                customScheduleColors: customScheduleColors,
                classNotificationMinutes: classNotificationMinutes,
                enableStartClassNotification: enableStartClassNotification,
                notificationScope: notificationScope,
                notificationSubjects: notificationSubjects,
                interfaceLanguage: interfaceLanguage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTableTable, LocalSettingsRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSettingsTableTable,
                    LocalSettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTableTable,
      LocalSettingsRow,
      $$LocalSettingsTableTableFilterComposer,
      $$LocalSettingsTableTableOrderingComposer,
      $$LocalSettingsTableTableAnnotationComposer,
      $$LocalSettingsTableTableCreateCompanionBuilder,
      $$LocalSettingsTableTableUpdateCompanionBuilder,
      (
        LocalSettingsRow,
        BaseReferences<
          _$AppDatabase,
          $LocalSettingsTableTable,
          LocalSettingsRow
        >,
      ),
      LocalSettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProcessedSchedulesTableTableManager get processedSchedules =>
      $$ProcessedSchedulesTableTableManager(_db, _db.processedSchedules);
  $$ClassSessionsTableTableManager get classSessions =>
      $$ClassSessionsTableTableManager(_db, _db.classSessions);
  $$LocalSettingsTableTableTableManager get localSettingsTable =>
      $$LocalSettingsTableTableTableManager(_db, _db.localSettingsTable);
}
