import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/utils/app_logger.dart';

/// Shared cache store so settings can inspect and purge HTTP cache on demand.
final dioCacheStoreProvider = Provider<MemCacheStore>((ref) {
  final store = MemCacheStore(
    maxSize:
        30 * 1024 * 1024, // 30 MB JSON response cache (>= 5 * maxEntrySize)
    maxEntrySize: 5 * 1024 * 1024, // Max 5 MB per response per spec
  );
  ref.onDispose(store.clean);
  return store;
});

/// Configured Dio client enforcing 10s timeouts, 5 MB max payload,
/// smart retries, and 5-minute catalog cache.
final dioClientProvider = Provider<Dio>((ref) {
  final cacheStore = ref.watch(dioCacheStoreProvider);

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'Muvio/1.0.0 (Android; OpenSource)',
      },
    ),
  );

  final cacheOptions = CacheOptions(
    store: cacheStore,
    maxStale: AppDurations.catalogCacheTtl,
    hitCacheOnErrorExcept: const [401, 403],
  );

  dio.interceptors.addAll([
    DioCacheInterceptor(options: cacheOptions),
    RetryInterceptor(
      dio: dio,
      logPrint: (msg) => AppLogger.info('DioRetry', msg),
      retries: 2,
      retryDelays: const [
        Duration(milliseconds: 400),
        Duration(milliseconds: 900),
      ],
    ),
    InterceptorsWrapper(
      onResponse: (response, handler) {
        final contentLengthHeader =
            response.headers.value(Headers.contentLengthHeader);
        if (contentLengthHeader != null) {
          final bytes = int.tryParse(contentLengthHeader) ?? 0;
          if (bytes > 5 * 1024 * 1024) {
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                error: 'Réponse supérieure à la limite de 5 Mo.',
              ),
            );
          }
        }
        handler.next(response);
      },
    ),
  ]);

  ref.onDispose(dio.close);
  return dio;
});
