import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muvio/core/router/app_router.dart';
import 'package:muvio/core/theme/app_theme.dart';
import 'package:muvio/data/models/app_settings.dart';
import 'package:muvio/data/providers/app_providers.dart';
import 'package:muvio/l10n/app_localizations.dart';

/// Root Muvio application widget bound to Riverpod settings, l10n, and GoRouter.
class MuvioApp extends ConsumerWidget {
  const MuvioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsControllerProvider).valueOrNull ??
        const AppSettings();

    return MaterialApp.router(
      title: 'Muvio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(pureAmoled: settings.pureAmoledBlack),
      locale: Locale(settings.localeCode),
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
