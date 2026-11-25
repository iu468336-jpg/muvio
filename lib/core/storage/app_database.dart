import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class AddonEntries extends Table {
  TextColumn get id => text()();
  TextColumn get manifestUrl => text()();
  TextColumn get manifestJson => text()();
  BoolColumn get installed => boolean().withDefault(const Constant(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  IntColumn get failureCount => integer().withDefault(const Constant(0))();
  IntColumn get accentColorHex =>
      integer().withDefault(const Constant(0xFFE50914))();
  TextColumn get shortBadge => text().withDefault(const Constant('ADD'))();
  TextColumn get categoryLabel =>
      text().withDefault(const Constant('Films & Séries'))();

  @override
  Set<Column> get primaryKey => {id};
}

class LibraryEntries extends Table {
  TextColumn get mediaId => text()();
  TextColumn get mediaType => text()();
  TextColumn get title => text()();
  TextColumn get poster => text()();
  TextColumn get backdrop => text().nullable()();
  TextColumn get synopsis => text().withDefault(const Constant(''))();
  IntColumn get year => integer().withDefault(const Constant(2024))();
  RealColumn get rating => real().withDefault(const Constant(8))();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {mediaId};
}

class PlaybackEntries extends Table {
  TextColumn get mediaId => text()();
  TextColumn get mediaType => text()();
  TextColumn get title => text()();
  TextColumn get poster => text()();
  TextColumn get backdrop => text().nullable()();
  IntColumn get positionSeconds => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get episodeBadge => text().nullable()();
  TextColumn get lastStreamUrl => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {mediaId};
}

class DownloadEntries extends Table {
  TextColumn get id => text()();
  TextColumn get mediaId => text()();
  TextColumn get title => text()();
  TextColumn get thumbnail => text()();
  TextColumn get quality => text()();
  IntColumn get totalBytes => integer()();
  IntColumn get downloadedBytes => integer()();
  TextColumn get status => text()();
  TextColumn get streamUrl => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SettingEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    AddonEntries,
    LibraryEntries,
    PlaybackEntries,
    DownloadEntries,
    SettingEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'muvio_storage.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
