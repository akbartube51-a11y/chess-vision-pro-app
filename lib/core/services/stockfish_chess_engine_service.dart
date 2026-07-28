import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'chess_engine_service.dart';

typedef ProcessStarter =
    Future<Process> Function(String executable, List<String> arguments);

class StockfishChessEngineService extends ChessEngineService {
  StockfishChessEngineService({
    this.executable = 'stockfish',
    ProcessStarter? processStarter,
  }) : _processStarter = processStarter ?? _defaultProcessStarter;

  final String executable;
  final ProcessStarter _processStarter;

  static Future<Process> _defaultProcessStarter(
    String executable,
    List<String> arguments,
  ) {
    return Process.start(executable, arguments);
  }

  @override
  Future<ChessEngineAnalysis> analyzePosition({
    required String fen,
    List<String> moves = const [],
    int multipv = 1,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final safeMultiPv = multipv < 1 ? 1 : multipv;

    Process process;
    try {
      process = await _processStarter(executable, const []).timeout(timeout);
    } on ProcessException catch (e) {
      throw ChessEngineException(
        ChessEngineErrorType.unavailable,
        'Unable to start Stockfish executable: $executable',
        cause: e,
      );
    } on TimeoutException catch (e) {
      throw ChessEngineException(
        ChessEngineErrorType.timeout,
        'Timed out launching engine process.',
        cause: e,
      );
    } catch (e) {
      throw ChessEngineException(
        ChessEngineErrorType.unknown,
        'Failed to launch engine process.',
        cause: e,
      );
    }

    final bestByPv = <int, String>{};
    ChessEvaluation? evaluation;
    String? bestMove;
    final completer = Completer<void>();

    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.startsWith('info ')) {
            final pv = _parseIntAfterToken(line, 'multipv') ?? 1;
            final pvMove = _parseFirstPvMove(line);
            if (pvMove != null) {
              bestByPv[pv] = pvMove;
            }
            if (pv == 1) {
              evaluation = _parseScore(line) ?? evaluation;
            }
            return;
          }

          if (!line.startsWith('bestmove ')) return;
          final parts = line.split(' ');
          if (parts.length >= 2 && parts[1] != '(none)') {
            bestMove = parts[1];
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        });

    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((_) {});

    try {
      process.stdin.writeln('uci');
      process.stdin.writeln('isready');
      process.stdin.writeln('ucinewgame');
      process.stdin.writeln('setoption name MultiPV value $safeMultiPv');
      final moveSuffix = moves.isEmpty ? '' : ' moves ${moves.join(' ')}';
      process.stdin.writeln('position fen $fen$moveSuffix');
      process.stdin.writeln('go movetime ${timeout.inMilliseconds}');
      await process.stdin.flush();

      await completer.future.timeout(timeout);

      final resolvedBestMove = bestMove ?? bestByPv[1];
      if (resolvedBestMove == null || resolvedBestMove.length < 4) {
        throw const ChessEngineException(
          ChessEngineErrorType.invalidResponse,
          'Best move was missing from engine output.',
        );
      }

      final candidates = <String>[];
      final keys = bestByPv.keys.toList()..sort();
      for (final key in keys) {
        final move = bestByPv[key];
        if (move == null || candidates.contains(move)) continue;
        candidates.add(move);
      }
      if (!candidates.contains(resolvedBestMove)) {
        candidates.insert(0, resolvedBestMove);
      }

      return ChessEngineAnalysis(
        bestMove: resolvedBestMove,
        candidateMoves: candidates,
        evaluation: evaluation,
      );
    } on TimeoutException catch (e) {
      throw ChessEngineException(
        ChessEngineErrorType.timeout,
        'Timed out waiting for Stockfish analysis output.',
        cause: e,
      );
    } on ChessEngineException {
      rethrow;
    } catch (e) {
      throw ChessEngineException(
        ChessEngineErrorType.unknown,
        'Unexpected Stockfish analysis error.',
        cause: e,
      );
    } finally {
      try {
        process.stdin.writeln('quit');
        await process.stdin.flush();
      } catch (_) {}
      await stdoutSub.cancel();
      await stderrSub.cancel();
      process.kill();
    }
  }

  static int? _parseIntAfterToken(String line, String token) {
    final parts = line.split(' ');
    final index = parts.indexOf(token);
    if (index == -1 || index + 1 >= parts.length) return null;
    return int.tryParse(parts[index + 1]);
  }

  static String? _parseFirstPvMove(String line) {
    final parts = line.split(' ');
    final index = parts.indexOf('pv');
    if (index == -1 || index + 1 >= parts.length) return null;
    return parts[index + 1];
  }

  static ChessEvaluation? _parseScore(String line) {
    final parts = line.split(' ');
    final scoreIndex = parts.indexOf('score');
    if (scoreIndex == -1 || scoreIndex + 2 >= parts.length) return null;
    final scoreType = parts[scoreIndex + 1];
    final rawValue = int.tryParse(parts[scoreIndex + 2]);
    if (rawValue == null) return null;
    if (scoreType == 'cp') {
      return ChessEvaluation(centipawns: rawValue);
    }
    if (scoreType == 'mate') {
      return ChessEvaluation(mateIn: rawValue);
    }
    return null;
  }
}
