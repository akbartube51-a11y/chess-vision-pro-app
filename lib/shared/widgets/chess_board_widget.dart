import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../chess_logic.dart';

class ChessBoardWidget extends StatelessWidget {
  const ChessBoardWidget({
    super.key,
    required this.boardState,
    this.selectedSquare,
    this.lastMoveFrom,
    this.lastMoveTo,
    this.onSquareTap,
    this.flipped = false,
  });

  final BoardState boardState;
  final Square? selectedSquare;
  final Square? lastMoveFrom;
  final Square? lastMoveTo;
  final void Function(Square)? onSquareTap;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    final boardTheme = Theme.of(context).extension<ChessBoardTheme>()!;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final squareSize = constraints.maxWidth / 8;
          return Stack(
            children: [
              // Board squares
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemCount: 64,
                itemBuilder: (context, index) {
                  final displayRank = index ~/ 8;
                  final displayFile = index % 8;
                  final rank = flipped ? displayRank : 7 - displayRank;
                  final file = flipped ? 7 - displayFile : displayFile;
                  final sq = Square(file, rank);
                  final isLight = (file + rank) % 2 != 0;
                  final isSelected = sq == selectedSquare;
                  final isLastMove = sq == lastMoveFrom || sq == lastMoveTo;

                  Color squareColor;
                  if (isSelected) {
                    squareColor = boardTheme.highlight;
                  } else if (isLastMove) {
                    squareColor = boardTheme.lastMoveHighlight;
                  } else {
                    squareColor =
                        isLight ? boardTheme.lightSquare : boardTheme.darkSquare;
                  }

                  return GestureDetector(
                    onTap: () => onSquareTap?.call(sq),
                    child: Container(
                      color: squareColor,
                      child: _buildPiece(
                          boardState.pieceAtIndex(file, rank), squareSize),
                    ),
                  );
                },
              ),
              // File labels (a-h)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: List.generate(8, (i) {
                    final file = flipped ? 7 - i : i;
                    return SizedBox(
                      width: squareSize,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 2, bottom: 1),
                          child: Text(
                            String.fromCharCode('a'.codeUnitAt(0) + file),
                            style: TextStyle(
                              fontSize: 10,
                              color: (file + 0) % 2 != 0
                                  ? Theme.of(context)
                                      .extension<ChessBoardTheme>()!
                                      .darkSquare
                                  : Theme.of(context)
                                      .extension<ChessBoardTheme>()!
                                      .lightSquare,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Rank labels (1-8)
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: Column(
                  children: List.generate(8, (i) {
                    final rank = flipped ? i : 7 - i;
                    return SizedBox(
                      height: squareSize,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2, top: 1),
                          child: Text(
                            '${rank + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color: (0 + rank) % 2 != 0
                                  ? Theme.of(context)
                                      .extension<ChessBoardTheme>()!
                                      .darkSquare
                                  : Theme.of(context)
                                      .extension<ChessBoardTheme>()!
                                      .lightSquare,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPiece(Piece? piece, double squareSize) {
    if (piece == null) return const SizedBox.shrink();
    return Center(
      child: Text(
        piece.symbol,
        style: TextStyle(
          fontSize: squareSize * 0.75,
          shadows: const [
            Shadow(
              color: Colors.black45,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
