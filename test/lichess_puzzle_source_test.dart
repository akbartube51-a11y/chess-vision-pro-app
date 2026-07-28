import 'dart:convert';

import 'package:chess_vision_pro/features/puzzles/data/lichess_puzzle_source.dart';
import 'package:chess_vision_pro/features/puzzles/data/puzzle_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('streams lichess-compatible CSV in chunks', () async {
    const csv = 'PuzzleId,FEN,Moves,Rating,RatingDeviation,Popularity,NbPlays,Themes,GameUrl,OpeningTags\n'
        'id1,8/8/8/8/8/8/8/K6k w - - 0 1,a1a2 h1h2,1100,75,0,0,mateIn1,https://example.com,KingEndings\n'
        'id2,8/8/8/8/8/8/8/K6k w - - 0 1,a1b1 h1g1,1400,75,0,0,fork pin,https://example.com,\n';
    final source = LichessPuzzleSource(client: _FakeNetworkClient(csv));

    final chunks = await source
        .streamPuzzles(uri: Uri.parse('https://example.com/export.csv'), batchSize: 1)
        .toList();

    expect(chunks, hasLength(2));
    expect(chunks.first.puzzles.single.externalId, equals('id1'));
    expect(chunks.first.puzzles.single.themes, equals(['mateIn1']));
    expect(chunks.last.puzzles.single.openingTags, isEmpty);
    expect(chunks.last.nextCursor, equals('2'));
  });

  test('resumes from cursor', () async {
    const csv = 'PuzzleId,FEN,Moves,Rating,RatingDeviation,Popularity,NbPlays,Themes,GameUrl,OpeningTags\n'
        'id1,8/8/8/8/8/8/8/K6k w - - 0 1,a1a2 h1h2,1100,75,0,0,mateIn1,https://example.com,KingEndings\n'
        'id2,8/8/8/8/8/8/8/K6k w - - 0 1,a1b1 h1g1,1400,75,0,0,fork pin,https://example.com,\n';
    final source = LichessPuzzleSource(client: _FakeNetworkClient(csv));

    final chunks = await source
        .streamPuzzles(
          uri: Uri.parse('https://example.com/export.csv'),
          cursor: '1',
          batchSize: 10,
        )
        .toList();

    expect(chunks.single.puzzles.single.externalId, equals('id2'));
  });
}

class _FakeNetworkClient implements PuzzleNetworkClient {
  const _FakeNetworkClient(this.csv);

  final String csv;

  @override
  Future<PuzzleNetworkResponse> get(Uri uri) async {
    return PuzzleNetworkResponse(
      statusCode: 200,
      bytes: Stream<List<int>>.value(utf8.encode(csv)),
      etag: 'etag-1',
      lastModified: 'Mon, 01 Jan 2024 00:00:00 GMT',
    );
  }
}
