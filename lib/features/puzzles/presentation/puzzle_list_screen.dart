import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/puzzle_provider.dart';
import '../domain/puzzle.dart';

class PuzzleListScreen extends StatefulWidget {
  const PuzzleListScreen({super.key});

  @override
  State<PuzzleListScreen> createState() => _PuzzleListScreenState();
}

class _PuzzleListScreenState extends State<PuzzleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PuzzleProvider>().loadPuzzles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzles'),
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
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.puzzles.isEmpty
              ? const Center(child: Text('No puzzles available.'))
              : ListView.builder(
                  itemCount: provider.puzzles.length,
                  itemBuilder: (context, index) {
                    final puzzle = provider.puzzles[index];
                    return _PuzzleListTile(puzzle: puzzle);
                  },
                ),
    );
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
              : 'Tactics Puzzle',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(puzzle.difficultyLabel),
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
