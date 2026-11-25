// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AddonEntriesTable extends AddonEntries
    with TableInfo<$AddonEntriesTable, AddonEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AddonEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _manifestUrlMeta =
      const VerificationMeta('manifestUrl');
  @override
  late final GeneratedColumn<String> manifestUrl = GeneratedColumn<String>(
      'manifest_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _manifestJsonMeta =
      const VerificationMeta('manifestJson');
  @override
  late final GeneratedColumn<String> manifestJson = GeneratedColumn<String>(
      'manifest_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _installedMeta =
      const VerificationMeta('installed');
  @override
  late final GeneratedColumn<bool> installed = GeneratedColumn<bool>(
      'installed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("installed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _failureCountMeta =
      const VerificationMeta('failureCount');
  @override
  late final GeneratedColumn<int> failureCount = GeneratedColumn<int>(
      'failure_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _accentColorHexMeta =
      const VerificationMeta('accentColorHex');
  @override
  late final GeneratedColumn<int> accentColorHex = GeneratedColumn<int>(
      'accent_color_hex', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0xFFE50914));
  static const VerificationMeta _shortBadgeMeta =
      const VerificationMeta('shortBadge');
  @override
  late final GeneratedColumn<String> shortBadge = GeneratedColumn<String>(
      'short_badge', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('ADD'));
  static const VerificationMeta _categoryLabelMeta =
      const VerificationMeta('categoryLabel');
  @override
  late final GeneratedColumn<String> categoryLabel = GeneratedColumn<String>(
      'category_label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Films & Séries'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        manifestUrl,
        manifestJson,
        installed,
        enabled,
        failureCount,
        accentColorHex,
        shortBadge,
        categoryLabel
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'addon_entries';
  @override
  VerificationContext validateIntegrity(Insertable<AddonEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('manifest_url')) {
      context.handle(
          _manifestUrlMeta,
          manifestUrl.isAcceptableOrUnknown(
              data['manifest_url']!, _manifestUrlMeta));
    } else if (isInserting) {
      context.missing(_manifestUrlMeta);
    }
    if (data.containsKey('manifest_json')) {
      context.handle(
          _manifestJsonMeta,
          manifestJson.isAcceptableOrUnknown(
              data['manifest_json']!, _manifestJsonMeta));
    } else if (isInserting) {
      context.missing(_manifestJsonMeta);
    }
    if (data.containsKey('installed')) {
      context.handle(_installedMeta,
          installed.isAcceptableOrUnknown(data['installed']!, _installedMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('failure_count')) {
      context.handle(
          _failureCountMeta,
          failureCount.isAcceptableOrUnknown(
              data['failure_count']!, _failureCountMeta));
    }
    if (data.containsKey('accent_color_hex')) {
      context.handle(
          _accentColorHexMeta,
          accentColorHex.isAcceptableOrUnknown(
              data['accent_color_hex']!, _accentColorHexMeta));
    }
    if (data.containsKey('short_badge')) {
      context.handle(
          _shortBadgeMeta,
          shortBadge.isAcceptableOrUnknown(
              data['short_badge']!, _shortBadgeMeta));
    }
    if (data.containsKey('category_label')) {
      context.handle(
          _categoryLabelMeta,
          categoryLabel.isAcceptableOrUnknown(
              data['category_label']!, _categoryLabelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AddonEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AddonEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      manifestUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manifest_url'])!,
      manifestJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manifest_json'])!,
      installed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}installed'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      failureCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}failure_count'])!,
      accentColorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accent_color_hex'])!,
      shortBadge: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}short_badge'])!,
      categoryLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_label'])!,
    );
  }

  @override
  $AddonEntriesTable createAlias(String alias) {
    return $AddonEntriesTable(attachedDatabase, alias);
  }
}

class AddonEntry extends DataClass implements Insertable<AddonEntry> {
  final String id;
  final String manifestUrl;
  final String manifestJson;
  final bool installed;
  final bool enabled;
  final int failureCount;
  final int accentColorHex;
  final String shortBadge;
  final String categoryLabel;
  const AddonEntry(
      {required this.id,
      required this.manifestUrl,
      required this.manifestJson,
      required this.installed,
      required this.enabled,
      required this.failureCount,
      required this.accentColorHex,
      required this.shortBadge,
      required this.categoryLabel});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['manifest_url'] = Variable<String>(manifestUrl);
    map['manifest_json'] = Variable<String>(manifestJson);
    map['installed'] = Variable<bool>(installed);
    map['enabled'] = Variable<bool>(enabled);
    map['failure_count'] = Variable<int>(failureCount);
    map['accent_color_hex'] = Variable<int>(accentColorHex);
    map['short_badge'] = Variable<String>(shortBadge);
    map['category_label'] = Variable<String>(categoryLabel);
    return map;
  }

  AddonEntriesCompanion toCompanion(bool nullToAbsent) {
    return AddonEntriesCompanion(
      id: Value(id),
      manifestUrl: Value(manifestUrl),
      manifestJson: Value(manifestJson),
      installed: Value(installed),
      enabled: Value(enabled),
      failureCount: Value(failureCount),
      accentColorHex: Value(accentColorHex),
      shortBadge: Value(shortBadge),
      categoryLabel: Value(categoryLabel),
    );
  }

  factory AddonEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AddonEntry(
      id: serializer.fromJson<String>(json['id']),
      manifestUrl: serializer.fromJson<String>(json['manifestUrl']),
      manifestJson: serializer.fromJson<String>(json['manifestJson']),
      installed: serializer.fromJson<bool>(json['installed']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      failureCount: serializer.fromJson<int>(json['failureCount']),
      accentColorHex: serializer.fromJson<int>(json['accentColorHex']),
      shortBadge: serializer.fromJson<String>(json['shortBadge']),
      categoryLabel: serializer.fromJson<String>(json['categoryLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'manifestUrl': serializer.toJson<String>(manifestUrl),
      'manifestJson': serializer.toJson<String>(manifestJson),
      'installed': serializer.toJson<bool>(installed),
      'enabled': serializer.toJson<bool>(enabled),
      'failureCount': serializer.toJson<int>(failureCount),
      'accentColorHex': serializer.toJson<int>(accentColorHex),
      'shortBadge': serializer.toJson<String>(shortBadge),
      'categoryLabel': serializer.toJson<String>(categoryLabel),
    };
  }

  AddonEntry copyWith(
          {String? id,
          String? manifestUrl,
          String? manifestJson,
          bool? installed,
          bool? enabled,
          int? failureCount,
          int? accentColorHex,
          String? shortBadge,
          String? categoryLabel}) =>
      AddonEntry(
        id: id ?? this.id,
        manifestUrl: manifestUrl ?? this.manifestUrl,
        manifestJson: manifestJson ?? this.manifestJson,
        installed: installed ?? this.installed,
        enabled: enabled ?? this.enabled,
        failureCount: failureCount ?? this.failureCount,
        accentColorHex: accentColorHex ?? this.accentColorHex,
        shortBadge: shortBadge ?? this.shortBadge,
        categoryLabel: categoryLabel ?? this.categoryLabel,
      );
  AddonEntry copyWithCompanion(AddonEntriesCompanion data) {
    return AddonEntry(
      id: data.id.present ? data.id.value : this.id,
      manifestUrl:
          data.manifestUrl.present ? data.manifestUrl.value : this.manifestUrl,
      manifestJson: data.manifestJson.present
          ? data.manifestJson.value
          : this.manifestJson,
      installed: data.installed.present ? data.installed.value : this.installed,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      failureCount: data.failureCount.present
          ? data.failureCount.value
          : this.failureCount,
      accentColorHex: data.accentColorHex.present
          ? data.accentColorHex.value
          : this.accentColorHex,
      shortBadge:
          data.shortBadge.present ? data.shortBadge.value : this.shortBadge,
      categoryLabel: data.categoryLabel.present
          ? data.categoryLabel.value
          : this.categoryLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AddonEntry(')
          ..write('id: $id, ')
          ..write('manifestUrl: $manifestUrl, ')
          ..write('manifestJson: $manifestJson, ')
          ..write('installed: $installed, ')
          ..write('enabled: $enabled, ')
          ..write('failureCount: $failureCount, ')
          ..write('accentColorHex: $accentColorHex, ')
          ..write('shortBadge: $shortBadge, ')
          ..write('categoryLabel: $categoryLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, manifestUrl, manifestJson, installed,
      enabled, failureCount, accentColorHex, shortBadge, categoryLabel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AddonEntry &&
          other.id == this.id &&
          other.manifestUrl == this.manifestUrl &&
          other.manifestJson == this.manifestJson &&
          other.installed == this.installed &&
          other.enabled == this.enabled &&
          other.failureCount == this.failureCount &&
          other.accentColorHex == this.accentColorHex &&
          other.shortBadge == this.shortBadge &&
          other.categoryLabel == this.categoryLabel);
}

class AddonEntriesCompanion extends UpdateCompanion<AddonEntry> {
  final Value<String> id;
  final Value<String> manifestUrl;
  final Value<String> manifestJson;
  final Value<bool> installed;
  final Value<bool> enabled;
  final Value<int> failureCount;
  final Value<int> accentColorHex;
  final Value<String> shortBadge;
  final Value<String> categoryLabel;
  final Value<int> rowid;
  const AddonEntriesCompanion({
    this.id = const Value.absent(),
    this.manifestUrl = const Value.absent(),
    this.manifestJson = const Value.absent(),
    this.installed = const Value.absent(),
    this.enabled = const Value.absent(),
    this.failureCount = const Value.absent(),
    this.accentColorHex = const Value.absent(),
    this.shortBadge = const Value.absent(),
    this.categoryLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AddonEntriesCompanion.insert({
    required String id,
    required String manifestUrl,
    required String manifestJson,
    this.installed = const Value.absent(),
    this.enabled = const Value.absent(),
    this.failureCount = const Value.absent(),
    this.accentColorHex = const Value.absent(),
    this.shortBadge = const Value.absent(),
    this.categoryLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        manifestUrl = Value(manifestUrl),
        manifestJson = Value(manifestJson);
  static Insertable<AddonEntry> custom({
    Expression<String>? id,
    Expression<String>? manifestUrl,
    Expression<String>? manifestJson,
    Expression<bool>? installed,
    Expression<bool>? enabled,
    Expression<int>? failureCount,
    Expression<int>? accentColorHex,
    Expression<String>? shortBadge,
    Expression<String>? categoryLabel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (manifestUrl != null) 'manifest_url': manifestUrl,
      if (manifestJson != null) 'manifest_json': manifestJson,
      if (installed != null) 'installed': installed,
      if (enabled != null) 'enabled': enabled,
      if (failureCount != null) 'failure_count': failureCount,
      if (accentColorHex != null) 'accent_color_hex': accentColorHex,
      if (shortBadge != null) 'short_badge': shortBadge,
      if (categoryLabel != null) 'category_label': categoryLabel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AddonEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? manifestUrl,
      Value<String>? manifestJson,
      Value<bool>? installed,
      Value<bool>? enabled,
      Value<int>? failureCount,
      Value<int>? accentColorHex,
      Value<String>? shortBadge,
      Value<String>? categoryLabel,
      Value<int>? rowid}) {
    return AddonEntriesCompanion(
      id: id ?? this.id,
      manifestUrl: manifestUrl ?? this.manifestUrl,
      manifestJson: manifestJson ?? this.manifestJson,
      installed: installed ?? this.installed,
      enabled: enabled ?? this.enabled,
      failureCount: failureCount ?? this.failureCount,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      shortBadge: shortBadge ?? this.shortBadge,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (manifestUrl.present) {
      map['manifest_url'] = Variable<String>(manifestUrl.value);
    }
    if (manifestJson.present) {
      map['manifest_json'] = Variable<String>(manifestJson.value);
    }
    if (installed.present) {
      map['installed'] = Variable<bool>(installed.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (failureCount.present) {
      map['failure_count'] = Variable<int>(failureCount.value);
    }
    if (accentColorHex.present) {
      map['accent_color_hex'] = Variable<int>(accentColorHex.value);
    }
    if (shortBadge.present) {
      map['short_badge'] = Variable<String>(shortBadge.value);
    }
    if (categoryLabel.present) {
      map['category_label'] = Variable<String>(categoryLabel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AddonEntriesCompanion(')
          ..write('id: $id, ')
          ..write('manifestUrl: $manifestUrl, ')
          ..write('manifestJson: $manifestJson, ')
          ..write('installed: $installed, ')
          ..write('enabled: $enabled, ')
          ..write('failureCount: $failureCount, ')
          ..write('accentColorHex: $accentColorHex, ')
          ..write('shortBadge: $shortBadge, ')
          ..write('categoryLabel: $categoryLabel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryEntriesTable extends LibraryEntries
    with TableInfo<$LibraryEntriesTable, LibraryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterMeta = const VerificationMeta('poster');
  @override
  late final GeneratedColumn<String> poster = GeneratedColumn<String>(
      'poster', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _backdropMeta =
      const VerificationMeta('backdrop');
  @override
  late final GeneratedColumn<String> backdrop = GeneratedColumn<String>(
      'backdrop', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _synopsisMeta =
      const VerificationMeta('synopsis');
  @override
  late final GeneratedColumn<String> synopsis = GeneratedColumn<String>(
      'synopsis', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2024));
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(8.0));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        mediaId,
        mediaType,
        title,
        poster,
        backdrop,
        synopsis,
        year,
        rating,
        addedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_entries';
  @override
  VerificationContext validateIntegrity(Insertable<LibraryEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster')) {
      context.handle(_posterMeta,
          poster.isAcceptableOrUnknown(data['poster']!, _posterMeta));
    } else if (isInserting) {
      context.missing(_posterMeta);
    }
    if (data.containsKey('backdrop')) {
      context.handle(_backdropMeta,
          backdrop.isAcceptableOrUnknown(data['backdrop']!, _backdropMeta));
    }
    if (data.containsKey('synopsis')) {
      context.handle(_synopsisMeta,
          synopsis.isAcceptableOrUnknown(data['synopsis']!, _synopsisMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  LibraryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryEntry(
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      poster: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster'])!,
      backdrop: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backdrop']),
      synopsis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synopsis'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $LibraryEntriesTable createAlias(String alias) {
    return $LibraryEntriesTable(attachedDatabase, alias);
  }
}

class LibraryEntry extends DataClass implements Insertable<LibraryEntry> {
  final String mediaId;
  final String mediaType;
  final String title;
  final String poster;
  final String? backdrop;
  final String synopsis;
  final int year;
  final double rating;
  final DateTime addedAt;
  const LibraryEntry(
      {required this.mediaId,
      required this.mediaType,
      required this.title,
      required this.poster,
      this.backdrop,
      required this.synopsis,
      required this.year,
      required this.rating,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['media_type'] = Variable<String>(mediaType);
    map['title'] = Variable<String>(title);
    map['poster'] = Variable<String>(poster);
    if (!nullToAbsent || backdrop != null) {
      map['backdrop'] = Variable<String>(backdrop);
    }
    map['synopsis'] = Variable<String>(synopsis);
    map['year'] = Variable<int>(year);
    map['rating'] = Variable<double>(rating);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  LibraryEntriesCompanion toCompanion(bool nullToAbsent) {
    return LibraryEntriesCompanion(
      mediaId: Value(mediaId),
      mediaType: Value(mediaType),
      title: Value(title),
      poster: Value(poster),
      backdrop: backdrop == null && nullToAbsent
          ? const Value.absent()
          : Value(backdrop),
      synopsis: Value(synopsis),
      year: Value(year),
      rating: Value(rating),
      addedAt: Value(addedAt),
    );
  }

  factory LibraryEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryEntry(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      title: serializer.fromJson<String>(json['title']),
      poster: serializer.fromJson<String>(json['poster']),
      backdrop: serializer.fromJson<String?>(json['backdrop']),
      synopsis: serializer.fromJson<String>(json['synopsis']),
      year: serializer.fromJson<int>(json['year']),
      rating: serializer.fromJson<double>(json['rating']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'mediaType': serializer.toJson<String>(mediaType),
      'title': serializer.toJson<String>(title),
      'poster': serializer.toJson<String>(poster),
      'backdrop': serializer.toJson<String?>(backdrop),
      'synopsis': serializer.toJson<String>(synopsis),
      'year': serializer.toJson<int>(year),
      'rating': serializer.toJson<double>(rating),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  LibraryEntry copyWith(
          {String? mediaId,
          String? mediaType,
          String? title,
          String? poster,
          Value<String?> backdrop = const Value.absent(),
          String? synopsis,
          int? year,
          double? rating,
          DateTime? addedAt}) =>
      LibraryEntry(
        mediaId: mediaId ?? this.mediaId,
        mediaType: mediaType ?? this.mediaType,
        title: title ?? this.title,
        poster: poster ?? this.poster,
        backdrop: backdrop.present ? backdrop.value : this.backdrop,
        synopsis: synopsis ?? this.synopsis,
        year: year ?? this.year,
        rating: rating ?? this.rating,
        addedAt: addedAt ?? this.addedAt,
      );
  LibraryEntry copyWithCompanion(LibraryEntriesCompanion data) {
    return LibraryEntry(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      title: data.title.present ? data.title.value : this.title,
      poster: data.poster.present ? data.poster.value : this.poster,
      backdrop: data.backdrop.present ? data.backdrop.value : this.backdrop,
      synopsis: data.synopsis.present ? data.synopsis.value : this.synopsis,
      year: data.year.present ? data.year.value : this.year,
      rating: data.rating.present ? data.rating.value : this.rating,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntry(')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('poster: $poster, ')
          ..write('backdrop: $backdrop, ')
          ..write('synopsis: $synopsis, ')
          ..write('year: $year, ')
          ..write('rating: $rating, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, mediaType, title, poster, backdrop,
      synopsis, year, rating, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryEntry &&
          other.mediaId == this.mediaId &&
          other.mediaType == this.mediaType &&
          other.title == this.title &&
          other.poster == this.poster &&
          other.backdrop == this.backdrop &&
          other.synopsis == this.synopsis &&
          other.year == this.year &&
          other.rating == this.rating &&
          other.addedAt == this.addedAt);
}

class LibraryEntriesCompanion extends UpdateCompanion<LibraryEntry> {
  final Value<String> mediaId;
  final Value<String> mediaType;
  final Value<String> title;
  final Value<String> poster;
  final Value<String?> backdrop;
  final Value<String> synopsis;
  final Value<int> year;
  final Value<double> rating;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const LibraryEntriesCompanion({
    this.mediaId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.title = const Value.absent(),
    this.poster = const Value.absent(),
    this.backdrop = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.year = const Value.absent(),
    this.rating = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryEntriesCompanion.insert({
    required String mediaId,
    required String mediaType,
    required String title,
    required String poster,
    this.backdrop = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.year = const Value.absent(),
    this.rating = const Value.absent(),
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  })  : mediaId = Value(mediaId),
        mediaType = Value(mediaType),
        title = Value(title),
        poster = Value(poster),
        addedAt = Value(addedAt);
  static Insertable<LibraryEntry> custom({
    Expression<String>? mediaId,
    Expression<String>? mediaType,
    Expression<String>? title,
    Expression<String>? poster,
    Expression<String>? backdrop,
    Expression<String>? synopsis,
    Expression<int>? year,
    Expression<double>? rating,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (mediaType != null) 'media_type': mediaType,
      if (title != null) 'title': title,
      if (poster != null) 'poster': poster,
      if (backdrop != null) 'backdrop': backdrop,
      if (synopsis != null) 'synopsis': synopsis,
      if (year != null) 'year': year,
      if (rating != null) 'rating': rating,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryEntriesCompanion copyWith(
      {Value<String>? mediaId,
      Value<String>? mediaType,
      Value<String>? title,
      Value<String>? poster,
      Value<String?>? backdrop,
      Value<String>? synopsis,
      Value<int>? year,
      Value<double>? rating,
      Value<DateTime>? addedAt,
      Value<int>? rowid}) {
    return LibraryEntriesCompanion(
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      poster: poster ?? this.poster,
      backdrop: backdrop ?? this.backdrop,
      synopsis: synopsis ?? this.synopsis,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (poster.present) {
      map['poster'] = Variable<String>(poster.value);
    }
    if (backdrop.present) {
      map['backdrop'] = Variable<String>(backdrop.value);
    }
    if (synopsis.present) {
      map['synopsis'] = Variable<String>(synopsis.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntriesCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('poster: $poster, ')
          ..write('backdrop: $backdrop, ')
          ..write('synopsis: $synopsis, ')
          ..write('year: $year, ')
          ..write('rating: $rating, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackEntriesTable extends PlaybackEntries
    with TableInfo<$PlaybackEntriesTable, PlaybackEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterMeta = const VerificationMeta('poster');
  @override
  late final GeneratedColumn<String> poster = GeneratedColumn<String>(
      'poster', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _backdropMeta =
      const VerificationMeta('backdrop');
  @override
  late final GeneratedColumn<String> backdrop = GeneratedColumn<String>(
      'backdrop', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionSecondsMeta =
      const VerificationMeta('positionSeconds');
  @override
  late final GeneratedColumn<int> positionSeconds = GeneratedColumn<int>(
      'position_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _episodeBadgeMeta =
      const VerificationMeta('episodeBadge');
  @override
  late final GeneratedColumn<String> episodeBadge = GeneratedColumn<String>(
      'episode_badge', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastStreamUrlMeta =
      const VerificationMeta('lastStreamUrl');
  @override
  late final GeneratedColumn<String> lastStreamUrl = GeneratedColumn<String>(
      'last_stream_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        mediaId,
        mediaType,
        title,
        poster,
        backdrop,
        positionSeconds,
        durationSeconds,
        episodeBadge,
        lastStreamUrl,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_entries';
  @override
  VerificationContext validateIntegrity(Insertable<PlaybackEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster')) {
      context.handle(_posterMeta,
          poster.isAcceptableOrUnknown(data['poster']!, _posterMeta));
    } else if (isInserting) {
      context.missing(_posterMeta);
    }
    if (data.containsKey('backdrop')) {
      context.handle(_backdropMeta,
          backdrop.isAcceptableOrUnknown(data['backdrop']!, _backdropMeta));
    }
    if (data.containsKey('position_seconds')) {
      context.handle(
          _positionSecondsMeta,
          positionSeconds.isAcceptableOrUnknown(
              data['position_seconds']!, _positionSecondsMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('episode_badge')) {
      context.handle(
          _episodeBadgeMeta,
          episodeBadge.isAcceptableOrUnknown(
              data['episode_badge']!, _episodeBadgeMeta));
    }
    if (data.containsKey('last_stream_url')) {
      context.handle(
          _lastStreamUrlMeta,
          lastStreamUrl.isAcceptableOrUnknown(
              data['last_stream_url']!, _lastStreamUrlMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  PlaybackEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackEntry(
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      poster: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster'])!,
      backdrop: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backdrop']),
      positionSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position_seconds'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      episodeBadge: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}episode_badge']),
      lastStreamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_stream_url']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PlaybackEntriesTable createAlias(String alias) {
    return $PlaybackEntriesTable(attachedDatabase, alias);
  }
}

class PlaybackEntry extends DataClass implements Insertable<PlaybackEntry> {
  final String mediaId;
  final String mediaType;
  final String title;
  final String poster;
  final String? backdrop;
  final int positionSeconds;
  final int durationSeconds;
  final String? episodeBadge;
  final String? lastStreamUrl;
  final DateTime updatedAt;
  const PlaybackEntry(
      {required this.mediaId,
      required this.mediaType,
      required this.title,
      required this.poster,
      this.backdrop,
      required this.positionSeconds,
      required this.durationSeconds,
      this.episodeBadge,
      this.lastStreamUrl,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['media_type'] = Variable<String>(mediaType);
    map['title'] = Variable<String>(title);
    map['poster'] = Variable<String>(poster);
    if (!nullToAbsent || backdrop != null) {
      map['backdrop'] = Variable<String>(backdrop);
    }
    map['position_seconds'] = Variable<int>(positionSeconds);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || episodeBadge != null) {
      map['episode_badge'] = Variable<String>(episodeBadge);
    }
    if (!nullToAbsent || lastStreamUrl != null) {
      map['last_stream_url'] = Variable<String>(lastStreamUrl);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaybackEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlaybackEntriesCompanion(
      mediaId: Value(mediaId),
      mediaType: Value(mediaType),
      title: Value(title),
      poster: Value(poster),
      backdrop: backdrop == null && nullToAbsent
          ? const Value.absent()
          : Value(backdrop),
      positionSeconds: Value(positionSeconds),
      durationSeconds: Value(durationSeconds),
      episodeBadge: episodeBadge == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeBadge),
      lastStreamUrl: lastStreamUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStreamUrl),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaybackEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackEntry(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      title: serializer.fromJson<String>(json['title']),
      poster: serializer.fromJson<String>(json['poster']),
      backdrop: serializer.fromJson<String?>(json['backdrop']),
      positionSeconds: serializer.fromJson<int>(json['positionSeconds']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      episodeBadge: serializer.fromJson<String?>(json['episodeBadge']),
      lastStreamUrl: serializer.fromJson<String?>(json['lastStreamUrl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'mediaType': serializer.toJson<String>(mediaType),
      'title': serializer.toJson<String>(title),
      'poster': serializer.toJson<String>(poster),
      'backdrop': serializer.toJson<String?>(backdrop),
      'positionSeconds': serializer.toJson<int>(positionSeconds),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'episodeBadge': serializer.toJson<String?>(episodeBadge),
      'lastStreamUrl': serializer.toJson<String?>(lastStreamUrl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaybackEntry copyWith(
          {String? mediaId,
          String? mediaType,
          String? title,
          String? poster,
          Value<String?> backdrop = const Value.absent(),
          int? positionSeconds,
          int? durationSeconds,
          Value<String?> episodeBadge = const Value.absent(),
          Value<String?> lastStreamUrl = const Value.absent(),
          DateTime? updatedAt}) =>
      PlaybackEntry(
        mediaId: mediaId ?? this.mediaId,
        mediaType: mediaType ?? this.mediaType,
        title: title ?? this.title,
        poster: poster ?? this.poster,
        backdrop: backdrop.present ? backdrop.value : this.backdrop,
        positionSeconds: positionSeconds ?? this.positionSeconds,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        episodeBadge:
            episodeBadge.present ? episodeBadge.value : this.episodeBadge,
        lastStreamUrl:
            lastStreamUrl.present ? lastStreamUrl.value : this.lastStreamUrl,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PlaybackEntry copyWithCompanion(PlaybackEntriesCompanion data) {
    return PlaybackEntry(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      title: data.title.present ? data.title.value : this.title,
      poster: data.poster.present ? data.poster.value : this.poster,
      backdrop: data.backdrop.present ? data.backdrop.value : this.backdrop,
      positionSeconds: data.positionSeconds.present
          ? data.positionSeconds.value
          : this.positionSeconds,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      episodeBadge: data.episodeBadge.present
          ? data.episodeBadge.value
          : this.episodeBadge,
      lastStreamUrl: data.lastStreamUrl.present
          ? data.lastStreamUrl.value
          : this.lastStreamUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackEntry(')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('poster: $poster, ')
          ..write('backdrop: $backdrop, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('episodeBadge: $episodeBadge, ')
          ..write('lastStreamUrl: $lastStreamUrl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, mediaType, title, poster, backdrop,
      positionSeconds, durationSeconds, episodeBadge, lastStreamUrl, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackEntry &&
          other.mediaId == this.mediaId &&
          other.mediaType == this.mediaType &&
          other.title == this.title &&
          other.poster == this.poster &&
          other.backdrop == this.backdrop &&
          other.positionSeconds == this.positionSeconds &&
          other.durationSeconds == this.durationSeconds &&
          other.episodeBadge == this.episodeBadge &&
          other.lastStreamUrl == this.lastStreamUrl &&
          other.updatedAt == this.updatedAt);
}

class PlaybackEntriesCompanion extends UpdateCompanion<PlaybackEntry> {
  final Value<String> mediaId;
  final Value<String> mediaType;
  final Value<String> title;
  final Value<String> poster;
  final Value<String?> backdrop;
  final Value<int> positionSeconds;
  final Value<int> durationSeconds;
  final Value<String?> episodeBadge;
  final Value<String?> lastStreamUrl;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlaybackEntriesCompanion({
    this.mediaId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.title = const Value.absent(),
    this.poster = const Value.absent(),
    this.backdrop = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.episodeBadge = const Value.absent(),
    this.lastStreamUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackEntriesCompanion.insert({
    required String mediaId,
    required String mediaType,
    required String title,
    required String poster,
    this.backdrop = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.episodeBadge = const Value.absent(),
    this.lastStreamUrl = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : mediaId = Value(mediaId),
        mediaType = Value(mediaType),
        title = Value(title),
        poster = Value(poster),
        updatedAt = Value(updatedAt);
  static Insertable<PlaybackEntry> custom({
    Expression<String>? mediaId,
    Expression<String>? mediaType,
    Expression<String>? title,
    Expression<String>? poster,
    Expression<String>? backdrop,
    Expression<int>? positionSeconds,
    Expression<int>? durationSeconds,
    Expression<String>? episodeBadge,
    Expression<String>? lastStreamUrl,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (mediaType != null) 'media_type': mediaType,
      if (title != null) 'title': title,
      if (poster != null) 'poster': poster,
      if (backdrop != null) 'backdrop': backdrop,
      if (positionSeconds != null) 'position_seconds': positionSeconds,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (episodeBadge != null) 'episode_badge': episodeBadge,
      if (lastStreamUrl != null) 'last_stream_url': lastStreamUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackEntriesCompanion copyWith(
      {Value<String>? mediaId,
      Value<String>? mediaType,
      Value<String>? title,
      Value<String>? poster,
      Value<String?>? backdrop,
      Value<int>? positionSeconds,
      Value<int>? durationSeconds,
      Value<String?>? episodeBadge,
      Value<String?>? lastStreamUrl,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PlaybackEntriesCompanion(
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      poster: poster ?? this.poster,
      backdrop: backdrop ?? this.backdrop,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      episodeBadge: episodeBadge ?? this.episodeBadge,
      lastStreamUrl: lastStreamUrl ?? this.lastStreamUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (poster.present) {
      map['poster'] = Variable<String>(poster.value);
    }
    if (backdrop.present) {
      map['backdrop'] = Variable<String>(backdrop.value);
    }
    if (positionSeconds.present) {
      map['position_seconds'] = Variable<int>(positionSeconds.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (episodeBadge.present) {
      map['episode_badge'] = Variable<String>(episodeBadge.value);
    }
    if (lastStreamUrl.present) {
      map['last_stream_url'] = Variable<String>(lastStreamUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackEntriesCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('poster: $poster, ')
          ..write('backdrop: $backdrop, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('episodeBadge: $episodeBadge, ')
          ..write('lastStreamUrl: $lastStreamUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadEntriesTable extends DownloadEntries
    with TableInfo<$DownloadEntriesTable, DownloadEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailMeta =
      const VerificationMeta('thumbnail');
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
      'thumbnail', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qualityMeta =
      const VerificationMeta('quality');
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
      'quality', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _downloadedBytesMeta =
      const VerificationMeta('downloadedBytes');
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
      'downloaded_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _streamUrlMeta =
      const VerificationMeta('streamUrl');
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
      'stream_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        mediaId,
        title,
        thumbnail,
        quality,
        totalBytes,
        downloadedBytes,
        status,
        streamUrl,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_entries';
  @override
  VerificationContext validateIntegrity(Insertable<DownloadEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('thumbnail')) {
      context.handle(_thumbnailMeta,
          thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta));
    } else if (isInserting) {
      context.missing(_thumbnailMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(_qualityMeta,
          quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta));
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
          _downloadedBytesMeta,
          downloadedBytes.isAcceptableOrUnknown(
              data['downloaded_bytes']!, _downloadedBytesMeta));
    } else if (isInserting) {
      context.missing(_downloadedBytesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('stream_url')) {
      context.handle(_streamUrlMeta,
          streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta));
    } else if (isInserting) {
      context.missing(_streamUrlMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      thumbnail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail'])!,
      quality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quality'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes'])!,
      downloadedBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}downloaded_bytes'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      streamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_url'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DownloadEntriesTable createAlias(String alias) {
    return $DownloadEntriesTable(attachedDatabase, alias);
  }
}

class DownloadEntry extends DataClass implements Insertable<DownloadEntry> {
  final String id;
  final String mediaId;
  final String title;
  final String thumbnail;
  final String quality;
  final int totalBytes;
  final int downloadedBytes;
  final String status;
  final String streamUrl;
  final DateTime createdAt;
  const DownloadEntry(
      {required this.id,
      required this.mediaId,
      required this.title,
      required this.thumbnail,
      required this.quality,
      required this.totalBytes,
      required this.downloadedBytes,
      required this.status,
      required this.streamUrl,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['media_id'] = Variable<String>(mediaId);
    map['title'] = Variable<String>(title);
    map['thumbnail'] = Variable<String>(thumbnail);
    map['quality'] = Variable<String>(quality);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['status'] = Variable<String>(status);
    map['stream_url'] = Variable<String>(streamUrl);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DownloadEntriesCompanion toCompanion(bool nullToAbsent) {
    return DownloadEntriesCompanion(
      id: Value(id),
      mediaId: Value(mediaId),
      title: Value(title),
      thumbnail: Value(thumbnail),
      quality: Value(quality),
      totalBytes: Value(totalBytes),
      downloadedBytes: Value(downloadedBytes),
      status: Value(status),
      streamUrl: Value(streamUrl),
      createdAt: Value(createdAt),
    );
  }

  factory DownloadEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadEntry(
      id: serializer.fromJson<String>(json['id']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      title: serializer.fromJson<String>(json['title']),
      thumbnail: serializer.fromJson<String>(json['thumbnail']),
      quality: serializer.fromJson<String>(json['quality']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      status: serializer.fromJson<String>(json['status']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mediaId': serializer.toJson<String>(mediaId),
      'title': serializer.toJson<String>(title),
      'thumbnail': serializer.toJson<String>(thumbnail),
      'quality': serializer.toJson<String>(quality),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'status': serializer.toJson<String>(status),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DownloadEntry copyWith(
          {String? id,
          String? mediaId,
          String? title,
          String? thumbnail,
          String? quality,
          int? totalBytes,
          int? downloadedBytes,
          String? status,
          String? streamUrl,
          DateTime? createdAt}) =>
      DownloadEntry(
        id: id ?? this.id,
        mediaId: mediaId ?? this.mediaId,
        title: title ?? this.title,
        thumbnail: thumbnail ?? this.thumbnail,
        quality: quality ?? this.quality,
        totalBytes: totalBytes ?? this.totalBytes,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        status: status ?? this.status,
        streamUrl: streamUrl ?? this.streamUrl,
        createdAt: createdAt ?? this.createdAt,
      );
  DownloadEntry copyWithCompanion(DownloadEntriesCompanion data) {
    return DownloadEntry(
      id: data.id.present ? data.id.value : this.id,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      title: data.title.present ? data.title.value : this.title,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      quality: data.quality.present ? data.quality.value : this.quality,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      status: data.status.present ? data.status.value : this.status,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadEntry(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('title: $title, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('quality: $quality, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('status: $status, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mediaId, title, thumbnail, quality,
      totalBytes, downloadedBytes, status, streamUrl, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadEntry &&
          other.id == this.id &&
          other.mediaId == this.mediaId &&
          other.title == this.title &&
          other.thumbnail == this.thumbnail &&
          other.quality == this.quality &&
          other.totalBytes == this.totalBytes &&
          other.downloadedBytes == this.downloadedBytes &&
          other.status == this.status &&
          other.streamUrl == this.streamUrl &&
          other.createdAt == this.createdAt);
}

class DownloadEntriesCompanion extends UpdateCompanion<DownloadEntry> {
  final Value<String> id;
  final Value<String> mediaId;
  final Value<String> title;
  final Value<String> thumbnail;
  final Value<String> quality;
  final Value<int> totalBytes;
  final Value<int> downloadedBytes;
  final Value<String> status;
  final Value<String> streamUrl;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DownloadEntriesCompanion({
    this.id = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.title = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.quality = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadEntriesCompanion.insert({
    required String id,
    required String mediaId,
    required String title,
    required String thumbnail,
    required String quality,
    required int totalBytes,
    required int downloadedBytes,
    required String status,
    required String streamUrl,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        mediaId = Value(mediaId),
        title = Value(title),
        thumbnail = Value(thumbnail),
        quality = Value(quality),
        totalBytes = Value(totalBytes),
        downloadedBytes = Value(downloadedBytes),
        status = Value(status),
        streamUrl = Value(streamUrl),
        createdAt = Value(createdAt);
  static Insertable<DownloadEntry> custom({
    Expression<String>? id,
    Expression<String>? mediaId,
    Expression<String>? title,
    Expression<String>? thumbnail,
    Expression<String>? quality,
    Expression<int>? totalBytes,
    Expression<int>? downloadedBytes,
    Expression<String>? status,
    Expression<String>? streamUrl,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaId != null) 'media_id': mediaId,
      if (title != null) 'title': title,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (quality != null) 'quality': quality,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (status != null) 'status': status,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? mediaId,
      Value<String>? title,
      Value<String>? thumbnail,
      Value<String>? quality,
      Value<int>? totalBytes,
      Value<int>? downloadedBytes,
      Value<String>? status,
      Value<String>? streamUrl,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DownloadEntriesCompanion(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      quality: quality ?? this.quality,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      streamUrl: streamUrl ?? this.streamUrl,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadEntriesCompanion(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('title: $title, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('quality: $quality, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('status: $status, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingEntriesTable extends SettingEntries
    with TableInfo<$SettingEntriesTable, SettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SettingEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingEntriesTable createAlias(String alias) {
    return $SettingEntriesTable(attachedDatabase, alias);
  }
}

class SettingEntry extends DataClass implements Insertable<SettingEntry> {
  final String key;
  final String value;
  const SettingEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingEntriesCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingEntry(
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

  SettingEntry copyWith({String? key, String? value}) => SettingEntry(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingEntry copyWithCompanion(SettingEntriesCompanion data) {
    return SettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntry(')
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
      (other is SettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingEntriesCompanion extends UpdateCompanion<SettingEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingEntry> custom({
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

  SettingEntriesCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingEntriesCompanion(
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
    return (StringBuffer('SettingEntriesCompanion(')
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
  late final $AddonEntriesTable addonEntries = $AddonEntriesTable(this);
  late final $LibraryEntriesTable libraryEntries = $LibraryEntriesTable(this);
  late final $PlaybackEntriesTable playbackEntries =
      $PlaybackEntriesTable(this);
  late final $DownloadEntriesTable downloadEntries =
      $DownloadEntriesTable(this);
  late final $SettingEntriesTable settingEntries = $SettingEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        addonEntries,
        libraryEntries,
        playbackEntries,
        downloadEntries,
        settingEntries
      ];
}

typedef $$AddonEntriesTableCreateCompanionBuilder = AddonEntriesCompanion
    Function({
  required String id,
  required String manifestUrl,
  required String manifestJson,
  Value<bool> installed,
  Value<bool> enabled,
  Value<int> failureCount,
  Value<int> accentColorHex,
  Value<String> shortBadge,
  Value<String> categoryLabel,
  Value<int> rowid,
});
typedef $$AddonEntriesTableUpdateCompanionBuilder = AddonEntriesCompanion
    Function({
  Value<String> id,
  Value<String> manifestUrl,
  Value<String> manifestJson,
  Value<bool> installed,
  Value<bool> enabled,
  Value<int> failureCount,
  Value<int> accentColorHex,
  Value<String> shortBadge,
  Value<String> categoryLabel,
  Value<int> rowid,
});

class $$AddonEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AddonEntriesTable> {
  $$AddonEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manifestUrl => $composableBuilder(
      column: $table.manifestUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manifestJson => $composableBuilder(
      column: $table.manifestJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get installed => $composableBuilder(
      column: $table.installed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get failureCount => $composableBuilder(
      column: $table.failureCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accentColorHex => $composableBuilder(
      column: $table.accentColorHex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shortBadge => $composableBuilder(
      column: $table.shortBadge, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryLabel => $composableBuilder(
      column: $table.categoryLabel, builder: (column) => ColumnFilters(column));
}

class $$AddonEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AddonEntriesTable> {
  $$AddonEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manifestUrl => $composableBuilder(
      column: $table.manifestUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manifestJson => $composableBuilder(
      column: $table.manifestJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get installed => $composableBuilder(
      column: $table.installed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get failureCount => $composableBuilder(
      column: $table.failureCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accentColorHex => $composableBuilder(
      column: $table.accentColorHex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shortBadge => $composableBuilder(
      column: $table.shortBadge, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryLabel => $composableBuilder(
      column: $table.categoryLabel,
      builder: (column) => ColumnOrderings(column));
}

class $$AddonEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AddonEntriesTable> {
  $$AddonEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get manifestUrl => $composableBuilder(
      column: $table.manifestUrl, builder: (column) => column);

  GeneratedColumn<String> get manifestJson => $composableBuilder(
      column: $table.manifestJson, builder: (column) => column);

  GeneratedColumn<bool> get installed =>
      $composableBuilder(column: $table.installed, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get failureCount => $composableBuilder(
      column: $table.failureCount, builder: (column) => column);

  GeneratedColumn<int> get accentColorHex => $composableBuilder(
      column: $table.accentColorHex, builder: (column) => column);

  GeneratedColumn<String> get shortBadge => $composableBuilder(
      column: $table.shortBadge, builder: (column) => column);

  GeneratedColumn<String> get categoryLabel => $composableBuilder(
      column: $table.categoryLabel, builder: (column) => column);
}

class $$AddonEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AddonEntriesTable,
    AddonEntry,
    $$AddonEntriesTableFilterComposer,
    $$AddonEntriesTableOrderingComposer,
    $$AddonEntriesTableAnnotationComposer,
    $$AddonEntriesTableCreateCompanionBuilder,
    $$AddonEntriesTableUpdateCompanionBuilder,
    (AddonEntry, BaseReferences<_$AppDatabase, $AddonEntriesTable, AddonEntry>),
    AddonEntry,
    PrefetchHooks Function()> {
  $$AddonEntriesTableTableManager(_$AppDatabase db, $AddonEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AddonEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AddonEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AddonEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> manifestUrl = const Value.absent(),
            Value<String> manifestJson = const Value.absent(),
            Value<bool> installed = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<int> failureCount = const Value.absent(),
            Value<int> accentColorHex = const Value.absent(),
            Value<String> shortBadge = const Value.absent(),
            Value<String> categoryLabel = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AddonEntriesCompanion(
            id: id,
            manifestUrl: manifestUrl,
            manifestJson: manifestJson,
            installed: installed,
            enabled: enabled,
            failureCount: failureCount,
            accentColorHex: accentColorHex,
            shortBadge: shortBadge,
            categoryLabel: categoryLabel,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String manifestUrl,
            required String manifestJson,
            Value<bool> installed = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<int> failureCount = const Value.absent(),
            Value<int> accentColorHex = const Value.absent(),
            Value<String> shortBadge = const Value.absent(),
            Value<String> categoryLabel = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AddonEntriesCompanion.insert(
            id: id,
            manifestUrl: manifestUrl,
            manifestJson: manifestJson,
            installed: installed,
            enabled: enabled,
            failureCount: failureCount,
            accentColorHex: accentColorHex,
            shortBadge: shortBadge,
            categoryLabel: categoryLabel,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AddonEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AddonEntriesTable,
    AddonEntry,
    $$AddonEntriesTableFilterComposer,
    $$AddonEntriesTableOrderingComposer,
    $$AddonEntriesTableAnnotationComposer,
    $$AddonEntriesTableCreateCompanionBuilder,
    $$AddonEntriesTableUpdateCompanionBuilder,
    (AddonEntry, BaseReferences<_$AppDatabase, $AddonEntriesTable, AddonEntry>),
    AddonEntry,
    PrefetchHooks Function()>;
typedef $$LibraryEntriesTableCreateCompanionBuilder = LibraryEntriesCompanion
    Function({
  required String mediaId,
  required String mediaType,
  required String title,
  required String poster,
  Value<String?> backdrop,
  Value<String> synopsis,
  Value<int> year,
  Value<double> rating,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$LibraryEntriesTableUpdateCompanionBuilder = LibraryEntriesCompanion
    Function({
  Value<String> mediaId,
  Value<String> mediaType,
  Value<String> title,
  Value<String> poster,
  Value<String?> backdrop,
  Value<String> synopsis,
  Value<int> year,
  Value<double> rating,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$LibraryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get poster => $composableBuilder(
      column: $table.poster, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdrop => $composableBuilder(
      column: $table.backdrop, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get synopsis => $composableBuilder(
      column: $table.synopsis, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));
}

class $$LibraryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get poster => $composableBuilder(
      column: $table.poster, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdrop => $composableBuilder(
      column: $table.backdrop, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get synopsis => $composableBuilder(
      column: $table.synopsis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));
}

class $$LibraryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get poster =>
      $composableBuilder(column: $table.poster, builder: (column) => column);

  GeneratedColumn<String> get backdrop =>
      $composableBuilder(column: $table.backdrop, builder: (column) => column);

  GeneratedColumn<String> get synopsis =>
      $composableBuilder(column: $table.synopsis, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$LibraryEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LibraryEntriesTable,
    LibraryEntry,
    $$LibraryEntriesTableFilterComposer,
    $$LibraryEntriesTableOrderingComposer,
    $$LibraryEntriesTableAnnotationComposer,
    $$LibraryEntriesTableCreateCompanionBuilder,
    $$LibraryEntriesTableUpdateCompanionBuilder,
    (
      LibraryEntry,
      BaseReferences<_$AppDatabase, $LibraryEntriesTable, LibraryEntry>
    ),
    LibraryEntry,
    PrefetchHooks Function()> {
  $$LibraryEntriesTableTableManager(
      _$AppDatabase db, $LibraryEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> mediaId = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> poster = const Value.absent(),
            Value<String?> backdrop = const Value.absent(),
            Value<String> synopsis = const Value.absent(),
            Value<int> year = const Value.absent(),
            Value<double> rating = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LibraryEntriesCompanion(
            mediaId: mediaId,
            mediaType: mediaType,
            title: title,
            poster: poster,
            backdrop: backdrop,
            synopsis: synopsis,
            year: year,
            rating: rating,
            addedAt: addedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String mediaId,
            required String mediaType,
            required String title,
            required String poster,
            Value<String?> backdrop = const Value.absent(),
            Value<String> synopsis = const Value.absent(),
            Value<int> year = const Value.absent(),
            Value<double> rating = const Value.absent(),
            required DateTime addedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LibraryEntriesCompanion.insert(
            mediaId: mediaId,
            mediaType: mediaType,
            title: title,
            poster: poster,
            backdrop: backdrop,
            synopsis: synopsis,
            year: year,
            rating: rating,
            addedAt: addedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LibraryEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LibraryEntriesTable,
    LibraryEntry,
    $$LibraryEntriesTableFilterComposer,
    $$LibraryEntriesTableOrderingComposer,
    $$LibraryEntriesTableAnnotationComposer,
    $$LibraryEntriesTableCreateCompanionBuilder,
    $$LibraryEntriesTableUpdateCompanionBuilder,
    (
      LibraryEntry,
      BaseReferences<_$AppDatabase, $LibraryEntriesTable, LibraryEntry>
    ),
    LibraryEntry,
    PrefetchHooks Function()>;
typedef $$PlaybackEntriesTableCreateCompanionBuilder = PlaybackEntriesCompanion
    Function({
  required String mediaId,
  required String mediaType,
  required String title,
  required String poster,
  Value<String?> backdrop,
  Value<int> positionSeconds,
  Value<int> durationSeconds,
  Value<String?> episodeBadge,
  Value<String?> lastStreamUrl,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PlaybackEntriesTableUpdateCompanionBuilder = PlaybackEntriesCompanion
    Function({
  Value<String> mediaId,
  Value<String> mediaType,
  Value<String> title,
  Value<String> poster,
  Value<String?> backdrop,
  Value<int> positionSeconds,
  Value<int> durationSeconds,
  Value<String?> episodeBadge,
  Value<String?> lastStreamUrl,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PlaybackEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackEntriesTable> {
  $$PlaybackEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get poster => $composableBuilder(
      column: $table.poster, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdrop => $composableBuilder(
      column: $table.backdrop, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get positionSeconds => $composableBuilder(
      column: $table.positionSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get episodeBadge => $composableBuilder(
      column: $table.episodeBadge, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastStreamUrl => $composableBuilder(
      column: $table.lastStreamUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PlaybackEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackEntriesTable> {
  $$PlaybackEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get poster => $composableBuilder(
      column: $table.poster, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdrop => $composableBuilder(
      column: $table.backdrop, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get positionSeconds => $composableBuilder(
      column: $table.positionSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get episodeBadge => $composableBuilder(
      column: $table.episodeBadge,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastStreamUrl => $composableBuilder(
      column: $table.lastStreamUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PlaybackEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackEntriesTable> {
  $$PlaybackEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get poster =>
      $composableBuilder(column: $table.poster, builder: (column) => column);

  GeneratedColumn<String> get backdrop =>
      $composableBuilder(column: $table.backdrop, builder: (column) => column);

  GeneratedColumn<int> get positionSeconds => $composableBuilder(
      column: $table.positionSeconds, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<String> get episodeBadge => $composableBuilder(
      column: $table.episodeBadge, builder: (column) => column);

  GeneratedColumn<String> get lastStreamUrl => $composableBuilder(
      column: $table.lastStreamUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlaybackEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaybackEntriesTable,
    PlaybackEntry,
    $$PlaybackEntriesTableFilterComposer,
    $$PlaybackEntriesTableOrderingComposer,
    $$PlaybackEntriesTableAnnotationComposer,
    $$PlaybackEntriesTableCreateCompanionBuilder,
    $$PlaybackEntriesTableUpdateCompanionBuilder,
    (
      PlaybackEntry,
      BaseReferences<_$AppDatabase, $PlaybackEntriesTable, PlaybackEntry>
    ),
    PlaybackEntry,
    PrefetchHooks Function()> {
  $$PlaybackEntriesTableTableManager(
      _$AppDatabase db, $PlaybackEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> mediaId = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> poster = const Value.absent(),
            Value<String?> backdrop = const Value.absent(),
            Value<int> positionSeconds = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<String?> episodeBadge = const Value.absent(),
            Value<String?> lastStreamUrl = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaybackEntriesCompanion(
            mediaId: mediaId,
            mediaType: mediaType,
            title: title,
            poster: poster,
            backdrop: backdrop,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds,
            episodeBadge: episodeBadge,
            lastStreamUrl: lastStreamUrl,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String mediaId,
            required String mediaType,
            required String title,
            required String poster,
            Value<String?> backdrop = const Value.absent(),
            Value<int> positionSeconds = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<String?> episodeBadge = const Value.absent(),
            Value<String?> lastStreamUrl = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaybackEntriesCompanion.insert(
            mediaId: mediaId,
            mediaType: mediaType,
            title: title,
            poster: poster,
            backdrop: backdrop,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds,
            episodeBadge: episodeBadge,
            lastStreamUrl: lastStreamUrl,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlaybackEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaybackEntriesTable,
    PlaybackEntry,
    $$PlaybackEntriesTableFilterComposer,
    $$PlaybackEntriesTableOrderingComposer,
    $$PlaybackEntriesTableAnnotationComposer,
    $$PlaybackEntriesTableCreateCompanionBuilder,
    $$PlaybackEntriesTableUpdateCompanionBuilder,
    (
      PlaybackEntry,
      BaseReferences<_$AppDatabase, $PlaybackEntriesTable, PlaybackEntry>
    ),
    PlaybackEntry,
    PrefetchHooks Function()>;
typedef $$DownloadEntriesTableCreateCompanionBuilder = DownloadEntriesCompanion
    Function({
  required String id,
  required String mediaId,
  required String title,
  required String thumbnail,
  required String quality,
  required int totalBytes,
  required int downloadedBytes,
  required String status,
  required String streamUrl,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DownloadEntriesTableUpdateCompanionBuilder = DownloadEntriesCompanion
    Function({
  Value<String> id,
  Value<String> mediaId,
  Value<String> title,
  Value<String> thumbnail,
  Value<String> quality,
  Value<int> totalBytes,
  Value<int> downloadedBytes,
  Value<String> status,
  Value<String> streamUrl,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DownloadEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadEntriesTable> {
  $$DownloadEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnail => $composableBuilder(
      column: $table.thumbnail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
      column: $table.downloadedBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get streamUrl => $composableBuilder(
      column: $table.streamUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DownloadEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadEntriesTable> {
  $$DownloadEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnail => $composableBuilder(
      column: $table.thumbnail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
      column: $table.downloadedBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get streamUrl => $composableBuilder(
      column: $table.streamUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DownloadEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadEntriesTable> {
  $$DownloadEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
      column: $table.downloadedBytes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DownloadEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DownloadEntriesTable,
    DownloadEntry,
    $$DownloadEntriesTableFilterComposer,
    $$DownloadEntriesTableOrderingComposer,
    $$DownloadEntriesTableAnnotationComposer,
    $$DownloadEntriesTableCreateCompanionBuilder,
    $$DownloadEntriesTableUpdateCompanionBuilder,
    (
      DownloadEntry,
      BaseReferences<_$AppDatabase, $DownloadEntriesTable, DownloadEntry>
    ),
    DownloadEntry,
    PrefetchHooks Function()> {
  $$DownloadEntriesTableTableManager(
      _$AppDatabase db, $DownloadEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> mediaId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> thumbnail = const Value.absent(),
            Value<String> quality = const Value.absent(),
            Value<int> totalBytes = const Value.absent(),
            Value<int> downloadedBytes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> streamUrl = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadEntriesCompanion(
            id: id,
            mediaId: mediaId,
            title: title,
            thumbnail: thumbnail,
            quality: quality,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
            status: status,
            streamUrl: streamUrl,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String mediaId,
            required String title,
            required String thumbnail,
            required String quality,
            required int totalBytes,
            required int downloadedBytes,
            required String status,
            required String streamUrl,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadEntriesCompanion.insert(
            id: id,
            mediaId: mediaId,
            title: title,
            thumbnail: thumbnail,
            quality: quality,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
            status: status,
            streamUrl: streamUrl,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DownloadEntriesTable,
    DownloadEntry,
    $$DownloadEntriesTableFilterComposer,
    $$DownloadEntriesTableOrderingComposer,
    $$DownloadEntriesTableAnnotationComposer,
    $$DownloadEntriesTableCreateCompanionBuilder,
    $$DownloadEntriesTableUpdateCompanionBuilder,
    (
      DownloadEntry,
      BaseReferences<_$AppDatabase, $DownloadEntriesTable, DownloadEntry>
    ),
    DownloadEntry,
    PrefetchHooks Function()>;
typedef $$SettingEntriesTableCreateCompanionBuilder = SettingEntriesCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingEntriesTableUpdateCompanionBuilder = SettingEntriesCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableAnnotationComposer({
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

class $$SettingEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingEntriesTable,
    SettingEntry,
    $$SettingEntriesTableFilterComposer,
    $$SettingEntriesTableOrderingComposer,
    $$SettingEntriesTableAnnotationComposer,
    $$SettingEntriesTableCreateCompanionBuilder,
    $$SettingEntriesTableUpdateCompanionBuilder,
    (
      SettingEntry,
      BaseReferences<_$AppDatabase, $SettingEntriesTable, SettingEntry>
    ),
    SettingEntry,
    PrefetchHooks Function()> {
  $$SettingEntriesTableTableManager(
      _$AppDatabase db, $SettingEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingEntriesCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingEntriesCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingEntriesTable,
    SettingEntry,
    $$SettingEntriesTableFilterComposer,
    $$SettingEntriesTableOrderingComposer,
    $$SettingEntriesTableAnnotationComposer,
    $$SettingEntriesTableCreateCompanionBuilder,
    $$SettingEntriesTableUpdateCompanionBuilder,
    (
      SettingEntry,
      BaseReferences<_$AppDatabase, $SettingEntriesTable, SettingEntry>
    ),
    SettingEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AddonEntriesTableTableManager get addonEntries =>
      $$AddonEntriesTableTableManager(_db, _db.addonEntries);
  $$LibraryEntriesTableTableManager get libraryEntries =>
      $$LibraryEntriesTableTableManager(_db, _db.libraryEntries);
  $$PlaybackEntriesTableTableManager get playbackEntries =>
      $$PlaybackEntriesTableTableManager(_db, _db.playbackEntries);
  $$DownloadEntriesTableTableManager get downloadEntries =>
      $$DownloadEntriesTableTableManager(_db, _db.downloadEntries);
  $$SettingEntriesTableTableManager get settingEntries =>
      $$SettingEntriesTableTableManager(_db, _db.settingEntries);
}
