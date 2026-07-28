import 'package:chess_vision_pro/core/services/chess_engine_service.dart';
import 'package:chess_vision_pro/core/services/database_service.dart';
import 'package:chess_vision_pro/features/puzzles/data/puzzle_repository.dart';
import 'package:chess_vision_pro/features/puzzles/domain/puzzle.dart';
import 'package:chess_vision_pro/features/puzzles/domain/puzzle_progress.dart';
import 'package:chess_vision_pro/features/puzzles/presentation/providers/puzzle_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const puzzleFen = '8/8/8/8/8/8/8/R3K2R b KQ - 0 1';
  const puzzle = Puzzle(
    id: 1,
    fen: puzzleFen,
    moves: ['e8g8', 'e1g1'],
    rating: 1300,
  );

  group('PuzzleProvider engine hint', () {
    test('stores hint analysis when engine returns a move', () async {
      final engine = _FakeEngineService(
        analysis: const ChessEngineAnalysis(
          bestMove: 'e1g1',
          candidateMoves: ['e1g1', 'e1e2'],
          evaluation: ChessEvaluation(centipawns: 42),
        ),
      );
      final repo = _FakePuzzleRepository(puzzle);
      final provider = PuzzleProvider(
        repo,
        engineService: engine,
        loadOpponentMoveDelay: Duration.zero,
        replyOpponentMoveDelay: Duration.zero,
      );

      await provider.loadPuzzle(1);
      await provider.requestHint();

      expect(engine.lastFen, equals(puzzleFen));
      expect(engine.lastMoves, equals(['e8g8']));
      expect(provider.hintError, isNull);
      expect(provider.latestHint?.bestMove, equals('e1g1'));
    });

    test('stores user-friendly error when engine is unavailable', () async {
      final engine = _FakeEngineService(
        exception: const ChessEngineException(
          ChessEngineErrorType.unavailable,
          'missing',
        ),
      );
      final repo = _FakePuzzleRepository(puzzle);
      final provider = PuzzleProvider(
        repo,
        engineService: engine,
        loadOpponentMoveDelay: Duration.zero,
        replyOpponentMoveDelay: Duration.zero,
      );

      await provider.loadPuzzle(1);
      await provider.requestHint();

      expect(provider.latestHint, isNull);
      expect(provider.hintError, contains('unavailable'));
    });
  });
}

class _FakeEngineService extends ChessEngineService {
  _FakeEngineService({this.analysis, this.exception});

  final ChessEngineAnalysis? analysis;
  final ChessEngineException? exception;

  String? lastFen;
  List<String>? lastMoves;

  @override
  Future<ChessEngineAnalysis> analyzePosition({
    required String fen,
    List<String> moves = const [],
    int multipv = 1,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    lastFen = fen;
    lastMoves = moves;
    if (exception != null) throw exception!;
    return analysis ??
        const ChessEngineAnalysis(bestMove: 'e2e4', candidateMoves: ['e2e4']);
  }
}

class _FakePuzzleRepository extends PuzzleRepository {
  _FakePuzzleRepository(this._puzzle) : super(DatabaseService());

  final Puzzle _puzzle;

  @override
  Future<Puzzle?> fetchPuzzleById(int id) async => _puzzle;

  @override
  Future<PuzzleProgress?> fetchProgress(int puzzleId) async => null;

  @override
  Future<void> saveProgress(PuzzleProgress progress) async {}

  @override
  Future<int> countSolved() async => 0;

  @override
  Future<int> countTotal() async => 1;
}
