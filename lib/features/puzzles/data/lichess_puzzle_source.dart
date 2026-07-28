import 'dart:convert';

import 'puzzle_source.dart';
import 'puzzle_sync_models.dart';

class LichessPuzzleSource extends PuzzleSource {
  LichessPuzzleSource({PuzzleNetworkClient? client, Uri? defaultUri})
      : _client = client ?? const DefaultPuzzleNetworkClient(),
        _defaultUri = defaultUri ??
            Uri.parse(
              'https://raw.githubusercontent.com/akbartube51-a11y/chess-vision-pro-app/main/test/fixtures/lichess_export_sample.csv',
            );

  final PuzzleNetworkClient _client;
  final Uri _defaultUri;

  @override
  String get attribution =>
      'Source data derived from public Lichess puzzle exports; verify license compatibility before importing mirrors.';

  @override
  Uri get defaultUri => _defaultUri;

  @override
  String get displayName => 'Lichess-compatible CSV';

  @override
  String get licenseId => 'CC0-1.0';

  @override
  String get sourceId => 'lichess_csv';

  @override
  Stream<PuzzleSourceChunk> streamPuzzles({
    required Uri uri,
    String? cursor,
    int batchSize = 250,
  }) async* {
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw PuzzleSourceException(
        'Source responded with status ${response.statusCode}.',
      );
    }

    final skippedRecords = int.tryParse(cursor ?? '') ?? 0;
    var processedRecords = 0;
    final rows = <ImportedPuzzle>[];
    final contentHash = response.etag;
    final datasetVersion = response.lastModified;

    await for (final line in response.bytes
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.trim().isEmpty) continue;
      if (processedRecords == 0 && line.startsWith('PuzzleId,')) {
        continue;
      }
      if (processedRecords < skippedRecords) {
        processedRecords++;
        continue;
      }
      final puzzle = _parseLine(line);
      if (puzzle == null) {
        processedRecords++;
        continue;
      }
      rows.add(puzzle);
      processedRecords++;
      if (rows.length >= batchSize) {
        yield PuzzleSourceChunk(
          puzzles: List<ImportedPuzzle>.unmodifiable(rows),
          nextCursor: '$processedRecords',
          isLastChunk: false,
          datasetVersion: datasetVersion,
          contentHash: contentHash,
        );
        rows.clear();
      }
    }

    if (rows.isNotEmpty) {
      yield PuzzleSourceChunk(
        puzzles: List<ImportedPuzzle>.unmodifiable(rows),
        nextCursor: '$processedRecords',
        isLastChunk: true,
        datasetVersion: datasetVersion,
        contentHash: contentHash,
      );
    }
  }

  ImportedPuzzle? _parseLine(String line) {
    final columns = _parseCsvLine(line);
    if (columns.length < 8) return null;

    final externalId = columns[0].trim();
    final fen = columns[1].trim();
    final moves = columns[2]
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final rating = int.tryParse(columns[3].trim()) ?? 1500;
    final themes = columns[7]
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final openingTags = columns.length > 9
        ? columns[9]
            .trim()
            .split(RegExp(r'\s+'))
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    if (externalId.isEmpty || fen.isEmpty || moves.isEmpty) return null;

    return ImportedPuzzle(
      externalId: externalId,
      fen: fen,
      moves: moves,
      rating: rating,
      themes: themes,
      openingTags: openingTags,
      source: sourceId,
    );
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    values.add(buffer.toString());
    return values;
  }
}
