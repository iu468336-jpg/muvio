import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muvio/app.dart';
import 'package:muvio/core/storage/app_database.dart';
import 'package:muvio/core/theme/app_theme.dart';
import 'package:muvio/data/providers/app_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'End-to-end journey: Accueil -> Recherche -> Détail -> Source -> Lecture -> Retour',
    (tester) async {
      AppTheme.configureFonts();
      final memoryDb = AppDatabase(NativeDatabase.memory());
      addTearDown(memoryDb.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(memoryDb),
          ],
          child: const MuvioApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('MUVIO'), findsWidgets);

      await tester.tap(find.text('Recherche'));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.text("Top 10 aujourd'hui"), findsOneWidget);

      await tester.tap(find.text('Oppenheimer').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.textContaining('Sources disponibles'), findsOneWidget);
    },
  );
}
