class ChessEvaluation {
  const ChessEvaluation({this.centipawns, this.mateIn});

  final int? centipawns;
  final int? mateIn;

  String get label {
    if (mateIn != null) {
      return 'Mate in ${mateIn!.abs()}';
    }
    if (centipawns == null) return 'N/A';
    final pawns = centipawns! / 100.0;
    final sign = pawns >= 0 ? '+' : '';
    return '$sign${pawns.toStringAsFixed(2)}';
  }
}

class ChessEngineAnalysis {
  const ChessEngineAnalysis({
    required this.bestMove,
    this.candidateMoves = const [],
    this.evaluation,
  });

  final String bestMove;
  final List<String> candidateMoves;
  final ChessEvaluation? evaluation;
}

enum ChessEngineErrorType { unavailable, timeout, invalidResponse, unknown }

class ChessEngineException implements Exception {
  const ChessEngineException(this.type, this.message, {this.cause});

  final ChessEngineErrorType type;
  final String message;
  final Object? cause;

  String get userMessage {
    switch (type) {
      case ChessEngineErrorType.unavailable:
        return 'Engine is unavailable on this device right now.';
      case ChessEngineErrorType.timeout:
        return 'Engine took too long to respond. Please try again.';
      case ChessEngineErrorType.invalidResponse:
        return 'Engine returned an invalid analysis response.';
      case ChessEngineErrorType.unknown:
        return 'Could not complete engine analysis. Please try again.';
    }
  }

  @override
  String toString() => 'ChessEngineException(type: $type, message: $message)';
}

abstract class ChessEngineService {
  Future<ChessEngineAnalysis> analyzePosition({
    required String fen,
    List<String> moves = const [],
    int multipv = 1,
    Duration timeout = const Duration(seconds: 2),
  });

  Future<String> bestMove({
    required String fen,
    List<String> moves = const [],
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final analysis = await analyzePosition(
      fen: fen,
      moves: moves,
      multipv: 1,
      timeout: timeout,
    );
    return analysis.bestMove;
  }
}
