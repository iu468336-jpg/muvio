import 'package:drift/drift.dart';
import 'package:muvio/core/storage/app_database.dart';
import 'package:muvio/data/models/app_settings.dart';

/// Persists user playback, subtitle, theme, and language settings in Drift.
class SettingsRepository {
  const SettingsRepository(this._db);

  final AppDatabase _db;

  Future<AppSettings> loadSettings() async {
    final rows = await _db.select(_db.settingEntries).get();
    if (rows.isEmpty) return const AppSettings();

    final map = <String, String>{
      for (final r in rows) r.key: r.value,
    };

    return AppSettings(
      localeCode: map['localeCode'] ?? 'fr',
      defaultQuality: DefaultVideoQuality.values.firstWhere(
        (q) => q.name == map['defaultQuality'],
        orElse: () => DefaultVideoQuality.uhd4k,
      ),
      preferredAudioLang: map['preferredAudioLang'] ?? 'fr',
      preferredSubtitleLang: map['preferredSubtitleLang'] ?? 'fr',
      subtitleFontSize: double.tryParse(map['subtitleFontSize'] ?? '18') ?? 18,
      pureAmoledBlack: map['pureAmoledBlack'] == 'true',
      decoderMode: VideoDecoderMode.values.firstWhere(
        (d) => d.name == map['decoderMode'],
        orElse: () => VideoDecoderMode.hardware,
      ),
      autoRotatePlayer: map['autoRotatePlayer'] != 'false',
      useSdCardStorage: map['useSdCardStorage'] == 'true',
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final pairs = <String, String>{
      'localeCode': settings.localeCode,
      'defaultQuality': settings.defaultQuality.name,
      'preferredAudioLang': settings.preferredAudioLang,
      'preferredSubtitleLang': settings.preferredSubtitleLang,
      'subtitleFontSize': settings.subtitleFontSize.toStringAsFixed(1),
      'pureAmoledBlack': settings.pureAmoledBlack.toString(),
      'decoderMode': settings.decoderMode.name,
      'autoRotatePlayer': settings.autoRotatePlayer.toString(),
      'useSdCardStorage': settings.useSdCardStorage.toString(),
    };

    await _db.batch((batch) {
      for (final entry in pairs.entries) {
        batch.insert(
          _db.settingEntries,
          SettingEntriesCompanion.insert(key: entry.key, value: entry.value),
          onConflict: DoUpdate(
            (_) => SettingEntriesCompanion.insert(
              key: entry.key,
              value: entry.value,
            ),
          ),
        );
      }
    });
  }
}
