import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/services/database_service.dart';
import 'core/theme/app_theme.dart';
import 'features/puzzles/data/puzzle_repository.dart';
import 'features/puzzles/presentation/providers/puzzle_provider.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  await db.init();
  final puzzleRepo = PuzzleRepository(db);
  await puzzleRepo.seedSamplePuzzles();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => PuzzleProvider(puzzleRepo),
        ),
      ],
      child: const ChessVisionProApp(),
    ),
  );
}

class ChessVisionProApp extends StatelessWidget {
  const ChessVisionProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp.router(
      title: 'Chess Vision Pro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
