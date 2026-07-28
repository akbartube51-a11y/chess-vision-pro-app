import 'dart:io';

import 'package:chess_vision_pro/core/services/chess_engine_service.dart';
import 'package:chess_vision_pro/core/services/stockfish_chess_engine_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  group('StockfishChessEngineService', () {
    test('throws unavailable when executable is missing', () async {
      final service = StockfishChessEngineService(
        executable: '/definitely/not/a/real/stockfish',
      );

      expect(
        () => service.analyzePosition(fen: startFen),
        throwsA(
          isA<ChessEngineException>().having(
            (e) => e.type,
            'type',
            ChessEngineErrorType.unavailable,
          ),
        ),
      );
    });

    test('parses best move, multipv candidates and evaluation', () async {
      final scriptFile = await _createFakeEngineScript();
      final service = StockfishChessEngineService(
        executable: scriptFile.path,
      );

      final analysis = await service.analyzePosition(
        fen: startFen,
        multipv: 2,
        timeout: const Duration(seconds: 2),
      );

      expect(analysis.bestMove, equals('e2e4'));
      expect(analysis.candidateMoves, containsAllInOrder(['e2e4', 'd2d4']));
      expect(analysis.evaluation?.centipawns, equals(23));
    });
  });
}

Future<File> _createFakeEngineScript() async {
  final dir = await Directory.systemTemp.createTemp('fake_stockfish_');
  final file = File('${dir.path}/fake_stockfish.sh');
  await file.writeAsString('''
#!/usr/bin/env bash
while IFS= read -r line; do
  if [[ "\$line" == "uci" ]]; then
    echo "uciok"
  fi
  if [[ "\$line" == "isready" ]]; then
    echo "readyok"
  fi
  if [[ "\$line" == go* ]]; then
    echo "info depth 12 multipv 1 score cp 23 pv e2e4 e7e5"
    echo "info depth 12 multipv 2 score cp 15 pv d2d4 d7d5"
    echo "bestmove e2e4 ponder e7e5"
    exit 0
  fi
done
''');
  await Process.run('chmod', ['+x', file.path]);
  return file;
}
