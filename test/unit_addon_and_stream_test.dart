import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/utils/formatters.dart';
import 'package:muvio/core/utils/url_validator.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/models/seed_catalog.dart';
import 'package:muvio/data/providers/stremio_addon_client.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio mockDio;
  late StremioAddonClient client;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com/manifest.json'));
  });

  setUp(() {
    mockDio = _MockDio();
    client = StremioAddonClient(mockDio);
  });

  group('UrlSecurityValidator', () {
    test('rejects insecure HTTP, file://, javascript:, and private IPs', () {
      expect(
        UrlSecurityValidator.validateAddonUrl(
                'http://example.com/manifest.json')
            .isFailure,
        isTrue,
      );
      expect(
        UrlSecurityValidator.validateAddonUrl('file:///etc/passwd').isFailure,
        isTrue,
      );
      expect(
        UrlSecurityValidator.validateAddonUrl('javascript:alert(1)').isFailure,
        isTrue,
      );
      expect(
        UrlSecurityValidator.validateAddonUrl(
          'https://192.168.1.10/manifest.json',
        ).isFailure,
        isTrue,
      );
      expect(
        UrlSecurityValidator.validateAddonUrl(
          'https://127.0.0.1/manifest.json',
        ).isFailure,
        isTrue,
      );
    });

    test('converts stremio://, bare domains, and /configure to https manifest.json',
        () {
      final res = UrlSecurityValidator.validateAddonUrl(
        'stremio://torrentio.strem.fun',
      );
      expect(res.isSuccess, isTrue);
      expect(
        res.valueOrNull.toString(),
        'https://torrentio.strem.fun/manifest.json',
      );

      final resBare = UrlSecurityValidator.validateAddonUrl(
        'torrentio.strem.fun/configure',
      );
      expect(resBare.isSuccess, isTrue);
      expect(
        resBare.valueOrNull.toString(),
        'https://torrentio.strem.fun/manifest.json',
      );
    });
  });

  group('AddonManifest parser & StremioAddonClient', () {
    test('parses valid Stremio manifest JSON cleanly', () async {
      when(() => mockDio.getUri<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: 'https://v3-cinemeta.strem.io/manifest.json',
          ),
          statusCode: 200,
          data: {
            'id': 'com.linvo.cinemeta',
            'version': '3.0.12',
            'name': 'Cinemeta',
            'description': 'Official metadata addon',
            'resources': [
              'catalog',
              {
                'name': 'meta',
                'types': ['movie']
              },
            ],
            'types': ['movie', 'series'],
            'catalogs': [
              {
                'type': 'movie',
                'id': 'top',
                'name': 'Popular',
                'extra': [
                  {'name': 'search'},
                ],
              },
            ],
            'idPrefixes': ['tt'],
          },
        ),
      );

      final result = await client.fetchManifest(
        'https://v3-cinemeta.strem.io/manifest.json',
      );

      expect(result.isSuccess, isTrue);
      final manifest = result.valueOrNull!;
      expect(manifest.id, 'com.linvo.cinemeta');
      expect(manifest.supportsResource('catalog'), isTrue);
      expect(manifest.supportsResource('meta'), isTrue);
      expect(manifest.catalogs.first.searchSupported, isTrue);
    });

    test('returns ParseFailure without crashing on malformed JSON', () async {
      when(() => mockDio.getUri<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: 'https://bad.addon/manifest.json'),
          statusCode: 200,
          data: '<<<NOT_JSON>>>',
        ),
      );

      final result =
          await client.fetchManifest('https://bad.addon/manifest.json');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('circuit breaker marks addon offline after 3 consecutive failures',
        () async {
      final addon = SeedCatalogData.defaultProposedAddons().first.copyWith(
            failureCount: 3,
          );
      expect(addon.isOffline, isTrue);

      final res = await client.fetchCatalog(
        addon: addon,
        type: 'movie',
        catalogId: 'top',
      );
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<AddonOfflineFailure>());
    });
  });

  group('StreamDeduplicator & WatchProgressItem', () {
    test('deduplicates identical infoHashes and ranks 4K HDR above 1080p SDR',
        () {
      const s1080 = StreamSource(
        id: '1',
        addonId: 'a',
        addonName: 'Comet',
        title: '1080p',
        quality: '1080p',
        hdrMode: 'SDR',
        url: 'magnet:?xt=urn:btih:abc123',
        infoHash: 'abc123',
        seeders: 50,
      );
      const s4k = StreamSource(
        id: '2',
        addonId: 'b',
        addonName: 'Torrentio',
        title: '4K HDR',
        quality: '4K',
        hdrMode: 'HDR',
        url: 'magnet:?xt=urn:btih:abc123',
        infoHash: 'abc123',
        seeders: 300,
      );
      const sOther = StreamSource(
        id: '3',
        addonId: 'c',
        addonName: 'MediaFusion',
        title: '1080p',
        quality: '1080p',
        hdrMode: 'SDR',
        url: 'https://cdn.example.com/video.mp4',
        seeders: 120,
      );

      final ranked =
          StreamDeduplicator.deduplicateAndRank([s1080, s4k, sOther]);
      expect(ranked.length, 2);
      expect(ranked.first.addonName, 'Torrentio');
      expect(ranked.first.quality, '4K');
    });

    test('calculates watch progress fraction and clock formatting accurately',
        () {
      final progress = WatchProgressItem(
        media: SeedCatalogData.heroItems.first,
        positionSeconds: 5076, // 01:24:36
        durationSeconds: 10140, // 02:49:00
        updatedAt: DateTime(2026),
      );
      expect(progress.progressFraction, closeTo(0.5005, 0.01));
      expect(
        Formatters.formatDurationClock(
          Duration(seconds: progress.positionSeconds),
        ),
        '01:24:36',
      );
      expect(
        Formatters.formatDurationClock(
          Duration(seconds: progress.durationSeconds),
        ),
        '02:49:00',
      );
    });
  });
}
