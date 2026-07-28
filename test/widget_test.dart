import 'package:chess_vision_pro/core/theme/app_preferences.dart';
import 'package:chess_vision_pro/core/theme/app_theme.dart';
import 'package:chess_vision_pro/shared/chess_logic.dart';
import 'package:chess_vision_pro/shared/widgets/chess_board_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme(boardThemePreset: BoardThemePreset.tournament),
      darkTheme: AppTheme.darkTheme(
        boardThemePreset: BoardThemePreset.tournament,
      ),
      home: Scaffold(body: child),
    );
  }

  group('ChessBoardWidget', () {
    testWidgets('renders 64 squares', (tester) async {
      final board = BoardState.fromFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );

      await tester.pumpWidget(
        buildTestWidget(ChessBoardWidget(boardState: board)),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('renders chess piece symbols', (tester) async {
      final board = BoardState.fromFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );

      await tester.pumpWidget(
        buildTestWidget(
          SizedBox(
            width: 400,
            height: 400,
            child: ChessBoardWidget(boardState: board),
          ),
        ),
      );

      expect(find.text('♔'), findsOneWidget);
      expect(find.text('♚'), findsOneWidget);
    });

    testWidgets('exposes semantic square labels', (tester) async {
      final semantics = SemanticsTester(tester);
      final board = BoardState.fromFen('8/8/8/8/8/8/8/R3K2R w KQ - 0 1');

      await tester.pumpWidget(
        buildTestWidget(
          SizedBox(
            width: 400,
            height: 400,
            child: ChessBoardWidget(
              boardState: board,
              boardLabel: 'Puzzle board',
              keyboardHelpText: 'Arrow keys and enter',
            ),
          ),
        ),
      );

      expect(
        semantics,
        includesNodeWith(label: 'Square e1, dark square, white king'),
      );
      semantics.dispose();
    });
  });
}
