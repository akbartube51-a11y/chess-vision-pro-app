import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/services/chess_engine_service.dart';
import 'core/services/database_service.dart';
import 'core/services/stockfish_chess_engine_service.dart';
import 'core/theme/app_theme.dart';
import 'features/puzzles/data/lichess_puzzle_source.dart';
import 'features/puzzles/data/puzzle_repository.dart';
import 'features/puzzles/data/puzzle_sync_service.dart';
import 'features/puzzles/presentation/providers/puzzle_provider.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  await db.init();
  final puzzleRepo = PuzzleRepository(db);
  await puzzleRepo.seedSamplePuzzles();
  const engineExecutable = String.fromEnvironment(
    'STOCKFISH_EXECUTABLE',
    defaultValue: 'stockfish',
  );
  final ChessEngineService engineService = StockfishChessEngineService(
    executable: engineExecutable,
  );
  final defaultSource = LichessPuzzleSource();
  final puzzleSyncService = PuzzleSyncService(puzzleRepo);

  runApp(
    MultiProvider(
      providers: [
        Provider<ChessEngineService>.value(value: engineService),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, PuzzleProvider>(
          create: (_) => PuzzleProvider(
            puzzleRepo,
            engineService: engineService,
            syncService: puzzleSyncService,
            defaultSource: defaultSource,
          ),
          update: (_, settings, provider) {
            provider?.updateBoardAutoFlipEnabled(settings.boardFlipEnabled);
            return provider!;
          },
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
      theme: AppTheme.lightTheme(
        boardThemePreset: settings.boardThemePreset,
      ),
      darkTheme: AppTheme.darkTheme(
        boardThemePreset: settings.boardThemePreset,
      ),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
