import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/services/chess_engine_service.dart';
import '../../../../shared/chess_logic.dart';
import '../../data/puzzle_repository.dart';
import '../../data/puzzle_source.dart';
import '../../data/puzzle_sync_models.dart';
import '../../data/puzzle_sync_service.dart';
import '../../domain/puzzle.dart';
import '../../domain/puzzle_progress.dart';
import '../../domain/training_mode.dart';

enum PuzzleSolveState { idle, playing, correct, wrong, solved }

class PuzzleProvider extends ChangeNotifier {
  PuzzleProvider(
    this._repo, {
    required ChessEngineService engineService,
    PuzzleSyncService? syncService,
    PuzzleSource? defaultSource,
    this.loadOpponentMoveDelay = const Duration(milliseconds: 500),
    this.replyOpponentMoveDelay = const Duration(milliseconds: 600),
    this.engineTimeout = const Duration(seconds: 2),
    bool boardAutoFlipEnabled = true,
  })  : _engineService = engineService,
        _syncService = syncService,
        _defaultSource = defaultSource,
        _boardAutoFlipEnabled = boardAutoFlipEnabled;

  final PuzzleRepository _repo;
  final ChessEngineService _engineService;
  final PuzzleSyncService? _syncService;
  final PuzzleSource? _defaultSource;
  final Duration loadOpponentMoveDelay;
  final Duration replyOpponentMoveDelay;
  final Duration engineTimeout;
  static const int _pageSize = 40;

  bool _boardAutoFlipEnabled;

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

  int _moveIndex = 0;

  int _solvedCount = 0;
  int get solvedCount => _solvedCount;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  bool _loading = false;
  bool get loading => _loading;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _hintLoading = false;
  bool get hintLoading => _hintLoading;

  ChessEngineAnalysis? _latestHint;
  ChessEngineAnalysis? get latestHint => _latestHint;

  String? _hintError;
  String? get hintError => _hintError;

  TrainingMode _trainingMode = TrainingMode.classic;
  TrainingMode get trainingMode => _trainingMode;

  List<String> _availableThemes = [];
  List<String> get availableThemes => _availableThemes;

  String? _selectedTheme;
  String? get selectedTheme => _selectedTheme;

  int _streakCount = 0;
  int get streakCount => _streakCount;

  DateTime? _timedRoundStartedAt;
  final Duration _timedRoundDuration = const Duration(minutes: 3);

  int get timedSecondsRemaining {
    if (_timedRoundStartedAt == null) return _timedRoundDuration.inSeconds;
    final elapsed = DateTime.now().difference(_timedRoundStartedAt!);
    return math.max(0, (_timedRoundDuration - elapsed).inSeconds);
  }

  bool get timedOut =>
      _trainingMode == TrainingMode.timed && timedSecondsRemaining <= 0;

  bool _syncLoading = false;
  bool get syncLoading => _syncLoading;

  PuzzleSyncState? _syncState;
  PuzzleSyncState? get syncState => _syncState;

  PuzzleSyncReport? _lastSyncReport;
  PuzzleSyncReport? get lastSyncReport => _lastSyncReport;

  String? _syncError;
  String? get syncError => _syncError;

  int _offset = 0;

  void updateBoardAutoFlipEnabled(bool value) {
    if (_boardAutoFlipEnabled == value) return;
    _boardAutoFlipEnabled = value;
    if (!_boardAutoFlipEnabled) {
      _flipped = false;
    }
    notifyListeners();
  }

  Future<void> loadPuzzles({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _hasMore = true;
      _puzzles = [];
    }
    if (!_hasMore && !refresh) return;

    if (_puzzles.isEmpty) {
      _loading = true;
    } else {
      _loadingMore = true;
    }
    notifyListeners();

    final next = await _fetchPuzzlePage(offset: _offset, limit: _pageSize);
    if (refresh) {
      _puzzles = next;
    } else {
      _puzzles = [..._puzzles, ...next];
    }
    _offset = refresh ? next.length : _offset + next.length;
    _hasMore = next.length == _pageSize;
    _solvedCount = await _repo.countSolved();
    _totalCount = await _repo.countTotal();
    _availableThemes = await _repo.fetchAvailableThemes();
    if (_defaultSource != null) {
      final source = _defaultSource;
      _syncState =
          source == null ? null : await _repo.fetchSyncState(source.sourceId);
    }
    _loading = false;
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> loadMorePuzzles() => loadPuzzles();

  Future<List<Puzzle>> _fetchPuzzlePage({
    required int offset,
    required int limit,
  }) {
    switch (_trainingMode) {
      case TrainingMode.classic:
      case TrainingMode.timed:
      case TrainingMode.streak:
        return _repo.fetchPuzzles(limit: limit, offset: offset);
      case TrainingMode.theme:
        return _repo.fetchPuzzles(
          limit: limit,
          offset: offset,
          themeFilter: _selectedTheme,
        );
      case TrainingMode.review:
        return _repo.fetchReviewQueue(limit: limit, offset: offset);
    }
  }

  Future<void> configureTrainingMode(TrainingMode mode, {String? theme}) async {
    _trainingMode = mode;
    _selectedTheme =
        mode == TrainingMode.theme ? theme ?? _selectedTheme : null;
    if (mode == TrainingMode.timed) {
      _timedRoundStartedAt = DateTime.now();
    } else {
      _timedRoundStartedAt = null;
    }
    if (mode != TrainingMode.streak) {
      _streakCount = 0;
    }
    await loadPuzzles(refresh: true);
  }

  Future<void> setThemeFilter(String? theme) async {
    _selectedTheme = theme;
    if (_trainingMode != TrainingMode.theme) {
      _trainingMode = TrainingMode.theme;
    }
    await loadPuzzles(refresh: true);
  }

  Future<PuzzleSyncReport?> syncFromSourceUrl(String? sourceUrl) async {
    if (_syncService == null || _defaultSource == null) {
      _syncError = 'Sync service unavailable.';
      notifyListeners();
      return null;
    }
    final uri = (sourceUrl != null && sourceUrl.trim().isNotEmpty)
        ? Uri.tryParse(sourceUrl.trim())
        : _defaultSource.defaultUri;
    if (uri == null) {
      _syncError = 'No source URL configured.';
      notifyListeners();
      return null;
    }

    _syncLoading = true;
    _syncError = null;
    notifyListeners();

    try {
      final report = await _syncService.syncSource(_defaultSource, uri: uri);
      _lastSyncReport = report;
      _syncState = await _repo.fetchSyncState(_defaultSource.sourceId);
      await loadPuzzles(refresh: true);
      return report;
    } catch (error) {
      _syncError = error.toString();
      _syncState = await _repo.fetchSyncState(_defaultSource.sourceId);
      notifyListeners();
      return null;
    } finally {
      _syncLoading = false;
      notifyListeners();
    }
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
    _flipped =
        _boardAutoFlipEnabled && _boardState!.sideToMove == PieceColor.black;

    _loading = false;
    notifyListeners();

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
    if (_solveState == PuzzleSolveState.idle ||
        _solveState == PuzzleSolveState.solved ||
        _boardState == null ||
        _currentPuzzle == null) {
      return;
    }
    if (timedOut) {
      _solveState = PuzzleSolveState.wrong;
      notifyListeners();
      return;
    }

    final piece = _boardState!.pieceAt(sq);
    final playerColor = _flipped ? PieceColor.black : PieceColor.white;

    if (_selectedSquare == null) {
      if (piece != null && piece.color == playerColor) {
        _selectedSquare = sq;
        notifyListeners();
      }
      return;
    }

    if (_selectedSquare == sq) {
      _selectedSquare = null;
      notifyListeners();
      return;
    }

    if (piece != null && piece.color == playerColor) {
      _selectedSquare = sq;
      notifyListeners();
      return;
    }

    final from = _selectedSquare!;
    final uci = '${from.toAlgebraic()}${sq.toAlgebraic()}';
    _selectedSquare = null;
    _tryPlayerMove(uci);
  }

  void _tryPlayerMove(String uci) {
    final puzzle = _currentPuzzle;
    if (puzzle == null || _boardState == null) return;
    if (_moveIndex >= puzzle.moves.length) return;

    final expected = puzzle.moves[_moveIndex];
    final uciBase = uci.length >= 4 ? uci.substring(0, 4) : uci;
    final expectedBase =
        expected.length >= 4 ? expected.substring(0, 4) : expected;

    if (uciBase == expectedBase) {
      _applyMove(expected);
      _moveIndex++;
      _solveState = PuzzleSolveState.correct;
      if (_trainingMode == TrainingMode.streak) {
        _streakCount++;
      }
      notifyListeners();

      if (_moveIndex >= puzzle.moves.length) {
        _solveState = PuzzleSolveState.solved;
        unawaited(_markSolved());
        notifyListeners();
        return;
      }

      Future<void>.delayed(replyOpponentMoveDelay).then((_) {
        _playOpponentMove();
      });
    } else {
      _solveState = PuzzleSolveState.wrong;
      if (_trainingMode == TrainingMode.streak) {
        _streakCount = 0;
      }
      unawaited(markAttempt(puzzle.id));
      notifyListeners();
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
    unawaited(loadPuzzle(_currentPuzzle!.id));
  }
}
