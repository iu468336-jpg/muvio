import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/features/addons/addons_screen.dart';
import 'package:muvio/features/detail/media_detail_screen.dart';
import 'package:muvio/features/home/home_screen.dart';
import 'package:muvio/features/library/library_screen.dart';
import 'package:muvio/features/player/player_screen.dart';
import 'package:muvio/features/profile/profile_screen.dart';
import 'package:muvio/features/search/search_screen.dart';
import 'package:muvio/shared/widgets/muvio_bottom_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MuvioBottomShell(
            currentIndex: navigationShell.currentIndex,
            onSelectTab: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SearchScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/addons',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AddonsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: LibraryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/detail/:type/:id',
        pageBuilder: (context, state) {
          final type = state.pathParameters['type'] ?? 'movie';
          final id = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            transitionDuration: AppDurations.normal,
            child: MediaDetailScreen(mediaType: type, mediaId: id),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/player/:type/:id',
        pageBuilder: (context, state) {
          final type = state.pathParameters['type'] ?? 'movie';
          final id = state.pathParameters['id'] ?? '';
          final extraStream =
              state.extra is StreamSource ? state.extra! as StreamSource : null;
          return CustomTransitionPage(
            key: state.pageKey,
            transitionDuration: AppDurations.normal,
            child: PlayerScreen(
              mediaType: type,
              mediaId: id,
              initialStream: extraStream,
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ],
  );
});
