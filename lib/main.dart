import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muvio/app.dart';
import 'package:muvio/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.configureFonts();

  // Cap decoded image LRU memory cache to 64 MB for optimal 32-bit mobile stability
  PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 180;

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: MuvioApp(),
    ),
  );
}
