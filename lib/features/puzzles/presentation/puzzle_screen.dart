import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/chess_engine_service.dart';
import 'providers/puzzle_provider.dart';
import '../domain/puzzle.dart';
import '../../../shared/widgets/chess_board_widget.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.puzzleId});

  final int puzzleId;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
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
    final puzzle = provider.currentPuzzle;
    final board = provider.boardState;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/puzzles')),
        title: puzzle == null
            ? const Text('Puzzle')
            : Text('Puzzle #${puzzle.id}  ·  ${puzzle.rating}'),
        actions: [
          IconButton(
            icon: provider.hintLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.tips_and_updates_outlined),
            tooltip: 'Get hint',
            onPressed: provider.hintLoading
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await provider.requestHint();
                    if (!context.mounted) return;
                    final hint = provider.latestHint;
                    final message = provider.hintError ??
                        (hint == null
                            ? 'No hint available right now.'
                            : 'Hint: ${hint.bestMove}'
                                '${hint.evaluation != null ? ' (${hint.evaluation!.label})' : ''}');
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(message)));
                  },
          ),
          IconButton(
            icon: const Icon(Icons.flip),
            tooltip: 'Flip board',
            onPressed: provider.flipBoard,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset puzzle',
            onPressed: provider.resetPuzzle,
          ),
        ],
      ),
      body: provider.loading || board == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _StatusBanner(state: provider.solveState),
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
                      label: const Text('Next Puzzle'),
                      onPressed: () => context.go('/puzzles'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.analysis});

  final ChessEngineAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final candidates = analysis.candidateMoves.take(3).join(' · ');
    final evalText = analysis.evaluation != null
        ? 'Eval ${analysis.evaluation!.label}'
        : 'Eval N/A';
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Hint ${analysis.bestMove}  ·  $evalText  ·  Top: $candidates',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final PuzzleSolveState state;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (state) {
      PuzzleSolveState.idle => (
          'Loading...',
          Colors.grey,
          Icons.hourglass_empty
        ),
      PuzzleSolveState.playing => (
          'Your turn!',
          Theme.of(context).colorScheme.primaryContainer,
          Icons.lightbulb_outline
        ),
      PuzzleSolveState.correct => (
          'Correct! Keep going...',
          Colors.green.shade100,
          Icons.check
        ),
      PuzzleSolveState.wrong => (
          'Wrong move — try again!',
          Colors.red.shade100,
          Icons.close
        ),
      PuzzleSolveState.solved => (
          'Puzzle solved! 🎉',
          Colors.green.shade200,
          Icons.star
        ),
    };

    return Container(
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
    );
  }
}

class _PuzzleInfoCard extends StatelessWidget {
  const _PuzzleInfoCard({required this.puzzle});

  final Puzzle puzzle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Themes',
              style: Theme.of(context).textTheme.labelLarge,
            ),
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
                if (puzzle.themes.isEmpty) const Chip(label: Text('tactics')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
