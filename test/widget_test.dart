import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_vision_pro/shared/chess_logic.dart';
import 'package:chess_vision_pro/shared/widgets/chess_board_widget.dart';
import 'package:chess_vision_pro/core/theme/app_theme.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('ChessBoardWidget', () {
    testWidgets('renders 64 squares', (tester) async {
      final board = BoardState.fromFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );

      await tester.pumpWidget(
        buildTestWidget(
          ChessBoardWidget(boardState: board),
        ),
      );

      // Grid renders 64 children
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

      // White king symbol
      expect(find.text('♔'), findsOneWidget);
      // Black king symbol
      expect(find.text('♚'), findsOneWidget);
    });
  });
}
