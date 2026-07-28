import 'dart:convert';
import 'dart:io';

import 'package:chess_vision_pro/features/puzzles/data/lichess_puzzle_source.dart';

Future<void> main(List<String> args) async {
  final options = {
    for (final arg in args.where((value) => value.startsWith('--')))
      arg.split('=').first.replaceFirst('--', ''): arg.contains('=')
          ? arg.substring(arg.indexOf('=') + 1)
          : 'true',
  };
  final outputPath = options['output'];
  final uri =
      Uri.tryParse(options['url'] ?? '') ?? LichessPuzzleSource().defaultUri;
  final batchSize = int.tryParse(options['batch-size'] ?? '') ?? 250;

  if (uri == null) {
    stderr.writeln('No source URL configured.');
    exitCode = 64;
    return;
  }

  final sink = outputPath == null
      ? stdout
      : (File(outputPath)..createSync(recursive: true)).openWrite();
  final source = LichessPuzzleSource(defaultUri: uri);

  await for (final chunk in source.streamPuzzles(
    uri: uri,
    batchSize: batchSize,
  )) {
    for (final puzzle in chunk.puzzles) {
      sink.writeln(jsonEncode(puzzle.toDatabaseMap()));
    }
  }

  if (sink is IOSink) {
    await sink.flush();
    if (!identical(sink, stdout)) {
      await sink.close();
    }
  }
}
