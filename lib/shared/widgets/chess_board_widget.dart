import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../chess_logic.dart';

class ChessBoardWidget extends StatefulWidget {
  const ChessBoardWidget({
    super.key,
    required this.boardState,
    this.selectedSquare,
    this.lastMoveFrom,
    this.lastMoveTo,
    this.onSquareTap,
    this.flipped = false,
    this.pieceStyle = PieceSetStyle.classic,
    this.coordinateStyle = CoordinateStyle.inside,
    this.boardLabel,
    this.keyboardHelpText,
  });

  final BoardState boardState;
  final Square? selectedSquare;
  final Square? lastMoveFrom;
  final Square? lastMoveTo;
  final void Function(Square)? onSquareTap;
  final bool flipped;
  final PieceSetStyle pieceStyle;
  final CoordinateStyle coordinateStyle;
  final String? boardLabel;
  final String? keyboardHelpText;

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  Square _focusedSquare = const Square(0, 0);

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onSquareTap?.call(_focusedSquare);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveFocus(widget.flipped ? 1 : -1, 0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveFocus(widget.flipped ? -1 : 1, 0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveFocus(0, widget.flipped ? -1 : 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveFocus(0, widget.flipped ? 1 : -1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveFocus(int fileDelta, int rankDelta) {
    setState(() {
      _focusedSquare = Square(
        (_focusedSquare.file + fileDelta).clamp(0, 7),
        (_focusedSquare.rank + rankDelta).clamp(0, 7),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final boardTheme = Theme.of(context).extension<ChessBoardTheme>()!;
    final outsideCoordinates =
        widget.coordinateStyle == CoordinateStyle.outside;
    final showCoordinates = widget.coordinateStyle != CoordinateStyle.hidden;
    const outsidePadding = 18.0;

    return Semantics(
      label: widget.boardLabel,
      hint: widget.keyboardHelpText,
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inset = outsideCoordinates ? outsidePadding : 0.0;
            final boardSize = constraints.maxWidth - (inset * 2);
            final squareSize = boardSize / 8;

            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: boardTheme.borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Focus(
                autofocus: true,
                onKeyEvent: _handleKey,
                child: Stack(
                  children: [
                    Positioned(
                      left: inset,
                      top: inset,
                      right: inset,
                      bottom: inset,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                            ),
                        itemCount: 64,
                        itemBuilder: (context, index) {
                          final displayRank = index ~/ 8;
                          final displayFile = index % 8;
                          final rank = widget.flipped
                              ? displayRank
                              : 7 - displayRank;
                          final file = widget.flipped
                              ? 7 - displayFile
                              : displayFile;
                          final square = Square(file, rank);
                          final isLight = (file + rank) % 2 != 0;
                          final isSelected = square == widget.selectedSquare;
                          final isLastMove =
                              square == widget.lastMoveFrom ||
                              square == widget.lastMoveTo;
                          final isFocused = square == _focusedSquare;
                          final piece = widget.boardState.pieceAtIndex(
                            file,
                            rank,
                          );

                          final squareColor = isSelected
                              ? boardTheme.highlight
                              : isLastMove
                              ? boardTheme.lastMoveHighlight
                              : isLight
                              ? boardTheme.lightSquare
                              : boardTheme.darkSquare;

                          return Semantics(
                            button: true,
                            selected: isSelected,
                            focused: isFocused,
                            label: _squareLabel(square, piece, isLight),
                            child: InkWell(
                              onTap: () {
                                setState(() => _focusedSquare = square);
                                widget.onSquareTap?.call(square);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                decoration: BoxDecoration(
                                  color: squareColor,
                                  border: isFocused
                                      ? Border.all(
                                          color: boardTheme.focusRing,
                                          width: 3,
                                        )
                                      : null,
                                ),
                                child: _buildPiece(piece, squareSize),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (showCoordinates)
                      ..._buildFileLabels(
                        context,
                        squareSize,
                        inset,
                        outsideCoordinates,
                      ),
                    if (showCoordinates)
                      ..._buildRankLabels(
                        context,
                        squareSize,
                        inset,
                        outsideCoordinates,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildFileLabels(
    BuildContext context,
    double squareSize,
    double inset,
    bool outsideCoordinates,
  ) {
    final labels = List.generate(8, (index) {
      final file = widget.flipped ? 7 - index : index;
      return SizedBox(
        width: squareSize,
        child: Align(
          alignment: outsideCoordinates
              ? Alignment.center
              : Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(
              right: outsideCoordinates ? 0 : 2,
              bottom: outsideCoordinates ? 0 : 1,
            ),
            child: Text(
              String.fromCharCode('a'.codeUnitAt(0) + file),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(
                  context,
                ).extension<ChessBoardTheme>()!.borderColor,
              ),
            ),
          ),
        ),
      );
    });

    return [
      Positioned(
        left: inset,
        right: inset,
        bottom: outsideCoordinates ? 0 : inset,
        child: Row(children: labels),
      ),
    ];
  }

  List<Widget> _buildRankLabels(
    BuildContext context,
    double squareSize,
    double inset,
    bool outsideCoordinates,
  ) {
    final labels = List.generate(8, (index) {
      final rank = widget.flipped ? index : 7 - index;
      return SizedBox(
        height: squareSize,
        child: Align(
          alignment: outsideCoordinates ? Alignment.center : Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(
              left: outsideCoordinates ? 0 : 2,
              top: outsideCoordinates ? 0 : 1,
            ),
            child: Text(
              '${rank + 1}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(
                  context,
                ).extension<ChessBoardTheme>()!.borderColor,
              ),
            ),
          ),
        ),
      );
    });

    return [
      Positioned(
        left: outsideCoordinates ? 0 : inset,
        top: inset,
        bottom: inset,
        child: Column(children: labels),
      ),
    ];
  }

  String _squareLabel(Square square, Piece? piece, bool isLight) {
    final base =
        'Square ${square.toAlgebraic()}, ${isLight ? 'light' : 'dark'} square';
    if (piece == null) return base;
    return '$base, ${piece.color == PieceColor.white ? 'white' : 'black'} ${_pieceName(piece.type)}';
  }

  String _pieceName(String type) {
    return switch (type.toUpperCase()) {
      'K' => 'king',
      'Q' => 'queen',
      'R' => 'rook',
      'B' => 'bishop',
      'N' => 'knight',
      _ => 'pawn',
    };
  }

  Widget _buildPiece(Piece? piece, double squareSize) {
    if (piece == null) return const SizedBox.shrink();
    if (widget.pieceStyle == PieceSetStyle.initials) {
      return Center(
        child: Container(
          width: squareSize * 0.68,
          height: squareSize * 0.68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: piece.color == PieceColor.white
                ? Colors.white
                : const Color(0xFF111827),
            border: Border.all(color: Colors.black54),
          ),
          alignment: Alignment.center,
          child: Text(
            piece.type,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: piece.color == PieceColor.white
                  ? Colors.black
                  : Colors.white,
              fontSize: squareSize * 0.32,
            ),
          ),
        ),
      );
    }

    final symbol = widget.pieceStyle == PieceSetStyle.classic
        ? piece.symbol
        : _neoSymbol(piece);
    final fillColor = piece.color == PieceColor.white
        ? Colors.white
        : const Color(0xFF111827);
    final strokeColor = piece.color == PieceColor.white
        ? Colors.black87
        : Colors.white70;

    if (widget.pieceStyle == PieceSetStyle.neo) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: squareSize * 0.72,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.2
                  ..color = strokeColor,
              ),
            ),
            Text(
              symbol,
              style: TextStyle(fontSize: squareSize * 0.72, color: fillColor),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: squareSize * 0.75,
          shadows: const [
            Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
    );
  }

  String _neoSymbol(Piece piece) {
    if (piece.color == PieceColor.white) {
      return switch (piece.type) {
        'K' => '♔',
        'Q' => '♕',
        'R' => '♖',
        'B' => '♗',
        'N' => '♘',
        _ => '♙',
      };
    }
    return switch (piece.type) {
      'K' => '♚',
      'Q' => '♛',
      'R' => '♜',
      'B' => '♝',
      'N' => '♞',
      _ => '♟',
    };
  }
}
