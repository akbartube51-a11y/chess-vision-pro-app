import 'package:go_router/go_router.dart';

import '../../features/analysis/analysis_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/puzzles/presentation/puzzle_list_screen.dart';
import '../../features/puzzles/presentation/puzzle_screen.dart';
import '../../features/settings/privacy_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/puzzles',
        builder: (context, state) => const PuzzleListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return PuzzleScreen(puzzleId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/analysis',
        builder: (context, state) => const AnalysisScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
    ],
  );
}
