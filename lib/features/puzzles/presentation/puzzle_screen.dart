import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/accessibility/voice_guidance_service.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/services/chess_engine_service.dart';
import '../../../shared/widgets/chess_board_widget.dart';
import '../../settings/providers/settings_provider.dart';
import '../domain/puzzle.dart';
import '../domain/training_mode.dart';
import 'providers/puzzle_provider.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.puzzleId});

  final int puzzleId;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final VoiceGuidanceService _voiceGuidanceService =
      const VoiceGuidanceService();
  String? _lastAnnouncementKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PuzzleProvider>().loadPuzzle(widget.puzzleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzleProvider>();
    final settings = context.watch<SettingsProvider>();
    final puzzle = provider.currentPuzzle;
    final board = provider.boardState;
    final l10n = context.l10n;

    _announceStatusIfNeeded(context, provider, settings);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/puzzles')),
        title: puzzle == null
            ? Text(l10n.puzzleTitle)
            : Text(l10n.puzzleNumberTitle(puzzle.id, puzzle.rating)),
        actions: [
          IconButton(
            icon: provider.hintLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.tips_and_updates_outlined),
            tooltip: l10n.getHint,
            onPressed: provider.hintLoading
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await provider.requestHint();
                    if (!context.mounted) return;
                    final hint = provider.latestHint;
                    final message =
                        provider.hintError ??
                        (hint == null
                            ? l10n.hintUnavailable
                            : l10n.hintMessage(
                                hint.bestMove,
                                hint.evaluation == null
                                    ? ''
                                    : l10n.hintEvalSuffix(
                                        hint.evaluation!.label,
                                      ),
                              ));
                    await _voiceGuidanceService.announce(
                      context,
                      _voiceGuidanceService.withVerbosity(
                        headline: message,
                        details: provider.latestHint?.candidateMoves.join(', '),
                        verbosity: settings.voiceGuidanceVerbosity,
                      ),
                      enabled: settings.voiceGuidanceEnabled,
                    );
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(message)));
                  },
          ),
          IconButton(
            icon: const Icon(Icons.flip),
            tooltip: l10n.flipBoard,
            onPressed: provider.flipBoard,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.resetPuzzle,
            onPressed: provider.resetPuzzle,
          ),
        ],
      ),
      body: provider.loading || board == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _StatusBanner(state: provider.solveState),
                if (provider.trainingMode == TrainingMode.timed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      provider.timedOut
                          ? l10n.timedExpired
                          : l10n.remainingSeconds(
                              provider.timedSecondsRemaining,
                            ),
                    ),
                  ),
                if (provider.trainingMode == TrainingMode.streak)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(l10n.currentStreak(provider.streakCount)),
                  ),
                if (provider.latestHint != null)
                  _HintBanner(analysis: provider.latestHint!),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ChessBoardWidget(
                        boardState: board,
                        selectedSquare: provider.selectedSquare,
                        lastMoveFrom: provider.lastMoveFrom,
                        lastMoveTo: provider.lastMoveTo,
                        onSquareTap: provider.onSquareTap,
                        flipped: provider.flipped,
                        pieceStyle: settings.pieceSetStyle,
                        coordinateStyle: settings.coordinateStyle,
                        boardLabel: l10n.puzzleTitle,
                        keyboardHelpText: l10n.boardFocusHelp,
                      ),
                    ),
                  ),
                ),
                if (puzzle != null) _PuzzleInfoCard(puzzle: puzzle),
                if (provider.solveState == PuzzleSolveState.solved)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(l10n.nextPuzzle),
                      onPressed: () => context.go('/puzzles'),
                    ),
                  ),
              ],
            ),
    );
  }

  void _announceStatusIfNeeded(
    BuildContext context,
    PuzzleProvider provider,
    SettingsProvider settings,
  ) {
    final key = '${provider.currentPuzzle?.id}-${provider.solveState.name}';
    if (_lastAnnouncementKey == key) return;
    _lastAnnouncementKey = key;
    final message = switch (provider.solveState) {
      PuzzleSolveState.idle => context.l10n.statusLoading,
      PuzzleSolveState.playing => context.l10n.statusYourTurn,
      PuzzleSolveState.correct => context.l10n.statusCorrect,
      PuzzleSolveState.wrong => context.l10n.statusWrong,
      PuzzleSolveState.solved => context.l10n.statusSolved,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _voiceGuidanceService.announce(
        context,
        _voiceGuidanceService.withVerbosity(
          headline: message,
          details: provider.currentPuzzle?.themes.join(', '),
          verbosity: settings.voiceGuidanceVerbosity,
        ),
        enabled: settings.voiceGuidanceEnabled,
      );
    });
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.analysis});

  final ChessEngineAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final candidates = analysis.candidateMoves.take(3).join(' · ');
    final evalText = analysis.evaluation?.label ?? 'N/A';
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          l10n.hintBanner(analysis.bestMove, evalText, candidates),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final PuzzleSolveState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color, icon) = switch (state) {
      PuzzleSolveState.idle => (
        l10n.statusLoading,
        Colors.grey,
        Icons.hourglass_empty,
      ),
      PuzzleSolveState.playing => (
        l10n.statusYourTurn,
        Theme.of(context).colorScheme.primaryContainer,
        Icons.lightbulb_outline,
      ),
      PuzzleSolveState.correct => (
        l10n.statusCorrect,
        Colors.green.shade100,
        Icons.check,
      ),
      PuzzleSolveState.wrong => (
        l10n.statusWrong,
        Colors.red.shade100,
        Icons.close,
      ),
      PuzzleSolveState.solved => (
        l10n.statusSolved,
        Colors.green.shade200,
        Icons.star,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _PuzzleInfoCard extends StatelessWidget {
  const _PuzzleInfoCard({required this.puzzle});

  final Puzzle puzzle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.themes, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                for (final theme in puzzle.themes)
                  Chip(
                    label: Text(theme),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                if (puzzle.themes.isEmpty)
                  Chip(label: Text(l10n.tacticsPuzzle)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
