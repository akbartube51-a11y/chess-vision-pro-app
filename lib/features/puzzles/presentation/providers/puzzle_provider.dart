import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/chess_engine_service.dart';
import '../../data/puzzle_repository.dart';
import '../../domain/puzzle.dart';
import '../../domain/puzzle_progress.dart';
import '../../../../shared/chess_logic.dart';

enum PuzzleSolveState { idle, playing, correct, wrong, solved }

class PuzzleProvider extends ChangeNotifier {
  PuzzleProvider(
    this._repo, {
    required ChessEngineService engineService,
    this.loadOpponentMoveDelay = const Duration(milliseconds: 500),
    this.replyOpponentMoveDelay = const Duration(milliseconds: 600),
    this.engineTimeout = const Duration(seconds: 2),
  }) : _engineService = engineService;

  final PuzzleRepository _repo;
  final ChessEngineService _engineService;
  final Duration loadOpponentMoveDelay;
  final Duration replyOpponentMoveDelay;
  final Duration engineTimeout;

  List<Puzzle> _puzzles = [];
  List<Puzzle> get puzzles => _puzzles;

  Puzzle? _currentPuzzle;
  Puzzle? get currentPuzzle => _currentPuzzle;

  BoardState? _boardState;
  BoardState? get boardState => _boardState;

  PuzzleSolveState _solveState = PuzzleSolveState.idle;
  PuzzleSolveState get solveState => _solveState;

  Square? _selectedSquare;
  Square? get selectedSquare => _selectedSquare;

  Square? _lastMoveFrom;
  Square? get lastMoveFrom => _lastMoveFrom;

  Square? _lastMoveTo;
  Square? get lastMoveTo => _lastMoveTo;

  bool _flipped = false;
  bool get flipped => _flipped;

  /// Index into the puzzle's move list: moves[0] is the opponent's first move.
  /// The player starts making moves from index 1.
  int _moveIndex = 0;

  int _solvedCount = 0;
  int get solvedCount => _solvedCount;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  bool _loading = false;
  bool get loading => _loading;

  bool _hintLoading = false;
  bool get hintLoading => _hintLoading;

  ChessEngineAnalysis? _latestHint;
  ChessEngineAnalysis? get latestHint => _latestHint;

  String? _hintError;
  String? get hintError => _hintError;

  Future<void> loadPuzzles() async {
    _loading = true;
    notifyListeners();
    _puzzles = await _repo.fetchPuzzles();
    _solvedCount = await _repo.countSolved();
    _totalCount = await _repo.countTotal();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadPuzzle(int id) async {
    _loading = true;
    notifyListeners();

    _currentPuzzle = await _repo.fetchPuzzleById(id);
    if (_currentPuzzle == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    _boardState = BoardState.fromFen(_currentPuzzle!.fen);
    _solveState = PuzzleSolveState.idle;
    _selectedSquare = null;
    _lastMoveFrom = null;
    _lastMoveTo = null;
    _moveIndex = 0;
    _latestHint = null;
    _hintError = null;
    _hintLoading = false;

    // Determine if board should be flipped
    _flipped = _boardState!.sideToMove == PieceColor.black;

    _loading = false;
    notifyListeners();

    // Auto-play opponent's first move after short delay
    await Future<void>.delayed(loadOpponentMoveDelay);
    _playOpponentMove();
  }

  void _playOpponentMove() {
    final puzzle = _currentPuzzle;
    if (puzzle == null || _boardState == null) return;
    if (_moveIndex >= puzzle.moves.length) return;

    final move = puzzle.moves[_moveIndex];
    _applyMove(move);
    _moveIndex++;
    _solveState = PuzzleSolveState.playing;
    notifyListeners();
  }

  void onSquareTap(Square sq) {
    if (_solveState == PuzzleSolveState.idle) return;
    if (_solveState == PuzzleSolveState.solved) return;
    if (_boardState == null || _currentPuzzle == null) return;

    final piece = _boardState!.pieceAt(sq);
    final playerColor = _flipped ? PieceColor.black : PieceColor.white;

    if (_selectedSquare == null) {
      // Select a piece belonging to the player
      if (piece != null && piece.color == playerColor) {
        _selectedSquare = sq;
        notifyListeners();
      }
      return;
    }

    // Deselect if tapping same square
    if (_selectedSquare == sq) {
      _selectedSquare = null;
      notifyListeners();
      return;
    }

    // Re-select another own piece
    if (piece != null && piece.color == playerColor) {
      _selectedSquare = sq;
      notifyListeners();
      return;
    }

    // Attempt move
    final from = _selectedSquare!;
    final uci = '${from.toAlgebraic()}${sq.toAlgebraic()}';
    _selectedSquare = null;
    _tryPlayerMove(uci, sq);
  }

  void _tryPlayerMove(String uci, Square to) {
    final puzzle = _currentPuzzle;
    if (puzzle == null || _boardState == null) return;
    if (_moveIndex >= puzzle.moves.length) return;

    final expected = puzzle.moves[_moveIndex];
    // Accept promotion moves even if promotion piece differs (auto-queen)
    final uciBase = uci.length >= 4 ? uci.substring(0, 4) : uci;
    final expectedBase =
        expected.length >= 4 ? expected.substring(0, 4) : expected;

    if (uciBase == expectedBase) {
      _applyMove(expected); // apply with correct promotion if any
      _moveIndex++;
      _solveState = PuzzleSolveState.correct;
      notifyListeners();

      // Check if puzzle is fully solved
      if (_moveIndex >= puzzle.moves.length) {
        _solveState = PuzzleSolveState.solved;
        _markSolved();
        notifyListeners();
        return;
      }

      // Play engine response after delay
      Future<void>.delayed(replyOpponentMoveDelay).then((_) {
        _playOpponentMove();
      });
    } else {
      _solveState = PuzzleSolveState.wrong;
      notifyListeners();
      // Reset to playing after brief feedback
      Future<void>.delayed(const Duration(milliseconds: 800)).then((_) {
        _solveState = PuzzleSolveState.playing;
        notifyListeners();
      });
    }
  }

  void _applyMove(String uci) {
    if (_boardState == null) return;
    final from = Square.fromAlgebraic(uci.substring(0, 2));
    final to = Square.fromAlgebraic(uci.substring(2, 4));
    if (from == null || to == null) return;
    _lastMoveFrom = from;
    _lastMoveTo = to;
    _boardState = _boardState!.applyMove(uci);
  }

  Future<void> requestHint() async {
    final puzzle = _currentPuzzle;
    if (puzzle == null) return;

    _hintLoading = true;
    _hintError = null;
    notifyListeners();

    final movesSoFar = puzzle.moves.take(_moveIndex).toList(growable: false);

    try {
      final analysis = await _engineService.analyzePosition(
        fen: puzzle.fen,
        moves: movesSoFar,
        multipv: 3,
        timeout: engineTimeout,
      );
      _latestHint = analysis;
      _hintError = null;
    } on ChessEngineException catch (e) {
      _latestHint = null;
      _hintError = e.userMessage;
    } catch (_) {
      _latestHint = null;
      _hintError = const ChessEngineException(
        ChessEngineErrorType.unknown,
        'Unexpected hint failure.',
      ).userMessage;
    } finally {
      _hintLoading = false;
      notifyListeners();
    }
  }

  Future<void> _markSolved() async {
    final puzzle = _currentPuzzle;
    if (puzzle == null) return;
    final existing = await _repo.fetchProgress(puzzle.id);
    final progress = (existing ?? PuzzleProgress(puzzleId: puzzle.id)).copyWith(
      solved: true,
      attempts: (existing?.attempts ?? 0) + 1,
      lastAttempted: DateTime.now(),
    );
    await _repo.saveProgress(progress);
    _solvedCount = await _repo.countSolved();
    notifyListeners();
  }

  Future<void> markAttempt(int puzzleId) async {
    final existing = await _repo.fetchProgress(puzzleId);
    final progress = (existing ?? PuzzleProgress(puzzleId: puzzleId)).copyWith(
      attempts: (existing?.attempts ?? 0) + 1,
      lastAttempted: DateTime.now(),
    );
    await _repo.saveProgress(progress);
  }

  void flipBoard() {
    _flipped = !_flipped;
    notifyListeners();
  }

  void resetPuzzle() {
    if (_currentPuzzle == null) return;
    loadPuzzle(_currentPuzzle!.id);
  }
}
