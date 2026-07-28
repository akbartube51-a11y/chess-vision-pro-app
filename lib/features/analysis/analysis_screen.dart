import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/accessibility/voice_guidance_service.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/services/chess_engine_service.dart';
import '../../shared/chess_logic.dart';
import '../../shared/widgets/chess_board_widget.dart';
import '../settings/providers/settings_provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  static const String _startFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  final VoiceGuidanceService _voiceGuidanceService = const VoiceGuidanceService();
  late BoardState _boardState;
  Square? _selectedSquare;
  Square? _lastMoveFrom;
  Square? _lastMoveTo;
  bool _flipped = false;

  final List<BoardState> _history = [];
  final List<String> _moveHistory = [];
  bool _analysisLoading = false;
  String? _analysisResult;

  @override
  void initState() {
    super.initState();
    _boardState = BoardState.fromFen(_startFen);
  }

  void _onSquareTap(Square sq) {
    final piece = _boardState.pieceAt(sq);

    if (_selectedSquare == null) {
      if (piece != null && piece.color == _boardState.sideToMove) {
        setState(() => _selectedSquare = sq);
      }
      return;
    }

    if (_selectedSquare == sq) {
      setState(() => _selectedSquare = null);
      return;
    }

    if (piece != null && piece.color == _boardState.sideToMove) {
      setState(() => _selectedSquare = sq);
      return;
    }

    final from = _selectedSquare!;
    final uci = '${from.toAlgebraic()}${sq.toAlgebraic()}';
    _history.add(_boardState);
    setState(() {
      _lastMoveFrom = from;
      _lastMoveTo = sq;
      _boardState = _boardState.applyMove(uci);
      _moveHistory.add(uci);
      _selectedSquare = null;
    });
  }

  void _undoMove() {
    if (_history.isEmpty) return;
    setState(() {
      _boardState = _history.removeLast();
      if (_moveHistory.isNotEmpty) _moveHistory.removeLast();
      _selectedSquare = null;
      _lastMoveFrom = null;
      _lastMoveTo = null;
    });
  }

  void _resetBoard() {
    setState(() {
      _boardState = BoardState.fromFen(_startFen);
      _history.clear();
      _moveHistory.clear();
      _selectedSquare = null;
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _analysisResult = null;
    });
  }

  Future<void> _runQuickAnalysis() async {
    if (_analysisLoading) return;
    final settings = context.read<SettingsProvider>();
    final l10n = context.l10n;
    setState(() {
      _analysisLoading = true;
      _analysisResult = null;
    });

    try {
      final service = context.read<ChessEngineService>();
      final analysis = await service.analyzePosition(
        fen: _startFen,
        moves: _moveHistory,
        multipv: 3,
        timeout: const Duration(seconds: 2),
      );
      if (!mounted) return;
      final evalText =
          analysis.evaluation != null ? l10n.hintEvalSuffix(analysis.evaluation!.label) : '';
      final result = l10n.bestMoveResult(analysis.bestMove, evalText);
      setState(() {
        _analysisResult = result;
      });
      await _voiceGuidanceService.announce(
        context,
        _voiceGuidanceService.withVerbosity(
          headline: result,
          details: analysis.candidateMoves.join(', '),
          verbosity: settings.voiceGuidanceVerbosity,
        ),
        enabled: settings.voiceGuidanceEnabled,
      );
    } on ChessEngineException catch (e) {
      if (!mounted) return;
      setState(() {
        _analysisResult = e.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _analysisResult = l10n.couldNotAnalyze;
      });
    } finally {
      if (mounted) {
        setState(() => _analysisLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sideLabel = _boardState.sideToMove == PieceColor.white
        ? context.l10n.whiteToMove
        : context.l10n.blackToMove;
    final l10n = context.l10n;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: Text(l10n.analysisBoard),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip),
            tooltip: l10n.flipBoard,
            onPressed: () => setState(() => _flipped = !_flipped),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: l10n.undo,
            onPressed: _history.isNotEmpty ? _undoMove : null,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: l10n.reset,
            onPressed: _resetBoard,
          ),
          IconButton(
            icon: _analysisLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.analytics_outlined),
            tooltip: l10n.quickAnalysis,
            onPressed: _analysisLoading ? null : _runQuickAnalysis,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              sideLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ChessBoardWidget(
                  boardState: _boardState,
                  selectedSquare: _selectedSquare,
                  lastMoveFrom: _lastMoveFrom,
                  lastMoveTo: _lastMoveTo,
                  onSquareTap: _onSquareTap,
                  flipped: _flipped,
                  pieceStyle: settings.pieceSetStyle,
                  coordinateStyle: settings.coordinateStyle,
                  boardLabel: l10n.analysisBoard,
                  keyboardHelpText: l10n.boardFocusHelp,
                ),
              ),
            ),
          ),
          if (_analysisResult != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _analysisResult!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          _MoveHistoryPanel(moves: _moveHistory),
        ],
      ),
    );
  }
}

class _MoveHistoryPanel extends StatelessWidget {
  const _MoveHistoryPanel({required this.moves});

  final List<String> moves;

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          context.l10n.moveHistoryEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    final pairs = <String>[];
    for (var i = 0; i < moves.length; i += 2) {
      final white = moves[i];
      final black = i + 1 < moves.length ? moves[i + 1] : '';
      pairs.add('${i ~/ 2 + 1}. $white  $black');
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        children: pairs
            .map(
              (pair) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Chip(label: Text(pair)),
              ),
            )
            .toList(),
      ),
    );
  }
}
