/// Minimal chess board state for puzzle display and solving.
/// Handles FEN parsing and UCI move application without full legal move validation.
library;

class Square {
  const Square(this.file, this.rank);

  final int file; // 0 = a, 7 = h
  final int rank; // 0 = rank 1, 7 = rank 8

  static Square? fromAlgebraic(String s) {
    if (s.length != 2) return null;
    final file = s.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = s.codeUnitAt(1) - '1'.codeUnitAt(0);
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return null;
    return Square(file, rank);
  }

  String toAlgebraic() =>
      String.fromCharCode('a'.codeUnitAt(0) + file) + (rank + 1).toString();

  int get index => rank * 8 + file;

  @override
  bool operator ==(Object other) =>
      other is Square && file == other.file && rank == other.rank;

  @override
  int get hashCode => index;

  @override
  String toString() => toAlgebraic();
}

enum PieceColor { white, black }

class Piece {
  const Piece(this.type, this.color);

  final String type; // K Q R B N P (uppercase = white convention in FEN)
  final PieceColor color;

  String get symbol {
    final symbols = {
      'K': '♔',
      'Q': '♕',
      'R': '♖',
      'B': '♗',
      'N': '♘',
      'P': '♙',
    };
    if (color == PieceColor.white) {
      return symbols[type.toUpperCase()] ?? type;
    }
    final blackSymbols = {
      'K': '♚',
      'Q': '♛',
      'R': '♜',
      'B': '♝',
      'N': '♞',
      'P': '♟',
    };
    return blackSymbols[type.toUpperCase()] ?? type;
  }
}

class BoardState {
  BoardState._({
    required this.pieces,
    required this.sideToMove,
    required this.castlingRights,
    required this.enPassantSquare,
    required this.halfMoveClock,
    required this.fullMoveNumber,
  });

  // pieces[rank][file] = Piece? (rank 0 = rank 1)
  final List<List<Piece?>> pieces;
  final PieceColor sideToMove;
  final String castlingRights;
  final Square? enPassantSquare;
  final int halfMoveClock;
  final int fullMoveNumber;

  Piece? pieceAt(Square sq) => pieces[sq.rank][sq.file];
  Piece? pieceAtIndex(int file, int rank) => pieces[rank][file];

  factory BoardState.fromFen(String fen) {
    final parts = fen.split(' ');
    final boardPart = parts[0];
    final sideToMove = parts.length > 1 && parts[1] == 'b'
        ? PieceColor.black
        : PieceColor.white;
    final castling = parts.length > 2 ? parts[2] : 'KQkq';
    final epStr = parts.length > 3 ? parts[3] : '-';
    final halfMove = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
    final fullMove = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;

    final board = List.generate(8, (_) => List<Piece?>.filled(8, null));

    final ranks = boardPart.split('/');
    for (var r = 0; r < 8; r++) {
      final rankStr = ranks[7 - r]; // FEN rank 8 = index 7
      var file = 0;
      for (final ch in rankStr.split('')) {
        final num = int.tryParse(ch);
        if (num != null) {
          file += num;
        } else {
          final color =
              ch == ch.toUpperCase() ? PieceColor.white : PieceColor.black;
          board[r][file] = Piece(ch.toUpperCase(), color);
          file++;
        }
      }
    }

    return BoardState._(
      pieces: board,
      sideToMove: sideToMove,
      castlingRights: castling,
      enPassantSquare: epStr == '-' ? null : Square.fromAlgebraic(epStr),
      halfMoveClock: halfMove,
      fullMoveNumber: fullMove,
    );
  }

  /// Apply a UCI move (e.g. "e2e4" or "e7e8q") and return the new board state.
  BoardState applyMove(String uci) {
    final from = Square.fromAlgebraic(uci.substring(0, 2));
    final to = Square.fromAlgebraic(uci.substring(2, 4));
    final promotion = uci.length == 5 ? uci[4].toUpperCase() : null;

    if (from == null || to == null) return this;

    final newBoard = List.generate(8, (r) => List<Piece?>.from(pieces[r]));

    final movingPiece = newBoard[from.rank][from.file];
    if (movingPiece == null) return this;

    // En passant capture
    String newCastling = castlingRights;
    Square? newEp;

    if (movingPiece.type == 'P' && to == enPassantSquare) {
      final captureRank =
          movingPiece.color == PieceColor.white ? to.rank - 1 : to.rank + 1;
      newBoard[captureRank][to.file] = null;
    }

    // Castling: move rook as well
    if (movingPiece.type == 'K') {
      if (from.file == 4) {
        if (to.file == 6) {
          // King-side
          newBoard[from.rank][5] = newBoard[from.rank][7];
          newBoard[from.rank][7] = null;
        } else if (to.file == 2) {
          // Queen-side
          newBoard[from.rank][3] = newBoard[from.rank][0];
          newBoard[from.rank][0] = null;
        }
      }
      // Remove castling rights for this side
      if (movingPiece.color == PieceColor.white) {
        newCastling = newCastling.replaceAll('K', '').replaceAll('Q', '');
      } else {
        newCastling = newCastling.replaceAll('k', '').replaceAll('q', '');
      }
    }

    // Update en passant square
    if (movingPiece.type == 'P' && (to.rank - from.rank).abs() == 2) {
      final epRank = (from.rank + to.rank) ~/ 2;
      newEp = Square(from.file, epRank);
    }

    // Promotion
    final finalPiece =
        (movingPiece.type == 'P' && (to.rank == 0 || to.rank == 7))
            ? Piece(promotion ?? 'Q', movingPiece.color)
            : movingPiece;

    newBoard[to.rank][to.file] = finalPiece;
    newBoard[from.rank][from.file] = null;

    final newHalf =
        (movingPiece.type == 'P' || newBoard[to.rank][to.file] != null)
            ? 0
            : halfMoveClock + 1;
    final newFull =
        sideToMove == PieceColor.black ? fullMoveNumber + 1 : fullMoveNumber;

    return BoardState._(
      pieces: newBoard,
      sideToMove:
          sideToMove == PieceColor.white ? PieceColor.black : PieceColor.white,
      castlingRights: newCastling.isEmpty ? '-' : newCastling,
      enPassantSquare: newEp,
      halfMoveClock: newHalf,
      fullMoveNumber: newFull,
    );
  }
}
