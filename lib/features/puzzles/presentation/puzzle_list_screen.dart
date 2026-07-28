import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/localization_extensions.dart';
import '../domain/puzzle.dart';
import '../domain/training_mode.dart';
import 'providers/puzzle_provider.dart';

class PuzzleListScreen extends StatefulWidget {
  const PuzzleListScreen({super.key});

  @override
  State<PuzzleListScreen> createState() => _PuzzleListScreenState();
}

class _PuzzleListScreenState extends State<PuzzleListScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PuzzleProvider>().loadPuzzles(refresh: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final provider = context.read<PuzzleProvider>();
    if (_scrollController.position.extentAfter < 400 &&
        !provider.loadingMore &&
        provider.hasMore) {
      provider.loadMorePuzzles();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzleProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.puzzles),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                '${provider.solvedCount}/${provider.totalCount}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              avatar: const Icon(Icons.check_circle, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _TrainingModePanel(provider: provider),
          if (provider.trainingMode == TrainingMode.theme &&
              provider.availableThemes.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: provider.availableThemes
                    .map(
                      (theme) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(theme),
                          selected: provider.selectedTheme == theme,
                          onSelected: (_) => provider.setThemeFilter(theme),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (provider.trainingMode == TrainingMode.timed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l10n.timedSession} · ${l10n.remainingSeconds(provider.timedSecondsRemaining)}',
                ),
              ),
            ),
          if (provider.trainingMode == TrainingMode.streak)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.currentStreak(provider.streakCount)),
              ),
            ),
          Expanded(
            child: provider.loading && provider.puzzles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.puzzles.isEmpty
                ? Center(child: Text(l10n.noPuzzlesAvailable))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        provider.puzzles.length +
                        (provider.loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= provider.puzzles.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _PuzzleListTile(puzzle: provider.puzzles[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrainingModePanel extends StatelessWidget {
  const _TrainingModePanel({required this.provider});

  final PuzzleProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.trainingModes,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TrainingMode.values
                .map(
                  (mode) => ChoiceChip(
                    label: Text(_modeLabel(context, mode)),
                    selected: provider.trainingMode == mode,
                    onSelected: (_) => provider.configureTrainingMode(mode),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _modeLabel(BuildContext context, TrainingMode mode) {
    final l10n = context.l10n;
    return switch (mode) {
      TrainingMode.classic => l10n.trainingModeClassic,
      TrainingMode.timed => l10n.trainingModeTimed,
      TrainingMode.streak => l10n.trainingModeStreak,
      TrainingMode.theme => l10n.trainingModeTheme,
      TrainingMode.review => l10n.trainingModeReview,
    };
  }
}

class _PuzzleListTile extends StatelessWidget {
  const _PuzzleListTile({required this.puzzle});

  final Puzzle puzzle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _ratingColor(puzzle.rating, colorScheme),
          child: Text(
            '${puzzle.rating}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          puzzle.themes.isNotEmpty
              ? puzzle.themes.map(_capitalize).join(' · ')
              : context.l10n.tacticsPuzzle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(_difficultyLabel(context, puzzle.rating)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/puzzles/${puzzle.id}'),
      ),
    );
  }

  Color _ratingColor(int rating, ColorScheme cs) {
    if (rating < 1200) return Colors.green;
    if (rating < 1600) return Colors.orange;
    if (rating < 2000) return Colors.deepOrange;
    return Colors.red;
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  String _difficultyLabel(BuildContext context, int rating) {
    final l10n = context.l10n;
    if (rating < 1200) return l10n.difficultyBeginner;
    if (rating < 1600) return l10n.difficultyIntermediate;
    if (rating < 2000) return l10n.difficultyAdvanced;
    return l10n.difficultyExpert;
  }
}
