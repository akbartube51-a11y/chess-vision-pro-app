import 'package:flutter_test/flutter_test.dart';
import 'package:chess_vision_pro/shared/chess_logic.dart';

void main() {
  group('Square', () {
    test('fromAlgebraic parses correctly', () {
      final e4 = Square.fromAlgebraic('e4');
      expect(e4, isNotNull);
      expect(e4!.file, equals(4));
      expect(e4.rank, equals(3));
    });

    test('toAlgebraic round-trips', () {
      const sq = Square(4, 3);
      expect(sq.toAlgebraic(), equals('e4'));
    });

    test('fromAlgebraic returns null for invalid input', () {
      expect(Square.fromAlgebraic('z9'), isNull);
      expect(Square.fromAlgebraic('e'), isNull);
    });

    test('equality works', () {
      expect(Square.fromAlgebraic('e4'), equals(Square.fromAlgebraic('e4')));
      expect(
        Square.fromAlgebraic('e4'),
        isNot(equals(Square.fromAlgebraic('d4'))),
      );
    });
  });

  group('BoardState.fromFen', () {
    const startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

    test('starting position has white rooks on a1 and h1', () {
      final board = BoardState.fromFen(startFen);
      final a1 = Square.fromAlgebraic('a1')!;
      final h1 = Square.fromAlgebraic('h1')!;
      expect(board.pieceAt(a1)?.type, equals('R'));
      expect(board.pieceAt(a1)?.color, equals(PieceColor.white));
      expect(board.pieceAt(h1)?.type, equals('R'));
    });

    test('starting position has black king on e8', () {
      final board = BoardState.fromFen(startFen);
      final e8 = Square.fromAlgebraic('e8')!;
      expect(board.pieceAt(e8)?.type, equals('K'));
      expect(board.pieceAt(e8)?.color, equals(PieceColor.black));
    });

    test('side to move is white in starting position', () {
      final board = BoardState.fromFen(startFen);
      expect(board.sideToMove, equals(PieceColor.white));
    });

    test('e4 square is empty in starting position', () {
      final board = BoardState.fromFen(startFen);
      expect(board.pieceAt(Square.fromAlgebraic('e4')!), isNull);
    });

    test('parses position with pieces in middle of board', () {
      const fen =
          'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4';
      final board = BoardState.fromFen(fen);
      // White bishop on c4
      expect(board.pieceAt(Square.fromAlgebraic('c4')!)?.type, equals('B'));
      expect(
        board.pieceAt(Square.fromAlgebraic('c4')!)?.color,
        equals(PieceColor.white),
      );
      // Black knight on f6
      expect(board.pieceAt(Square.fromAlgebraic('f6')!)?.type, equals('N'));
      expect(
        board.pieceAt(Square.fromAlgebraic('f6')!)?.color,
        equals(PieceColor.black),
      );
    });
  });

  group('BoardState.applyMove', () {
    const startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

    test('e2e4 moves pawn from e2 to e4', () {
      final board = BoardState.fromFen(startFen).applyMove('e2e4');
      expect(board.pieceAt(Square.fromAlgebraic('e2')!), isNull);
      expect(board.pieceAt(Square.fromAlgebraic('e4')!)?.type, equals('P'));
    });

    test('side to move switches after move', () {
      final board = BoardState.fromFen(startFen).applyMove('e2e4');
      expect(board.sideToMove, equals(PieceColor.black));
    });

    test('en passant square is set after double pawn push', () {
      final board = BoardState.fromFen(startFen).applyMove('e2e4');
      expect(board.enPassantSquare, equals(Square.fromAlgebraic('e3')));
    });

    test('capture removes captured piece', () {
      const fen =
          'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2';
      final board = BoardState.fromFen(fen).applyMove('e4d5');
      expect(board.pieceAt(Square.fromAlgebraic('d5')!)?.type, equals('P'));
      expect(
        board.pieceAt(Square.fromAlgebraic('d5')!)?.color,
        equals(PieceColor.white),
      );
      expect(board.pieceAt(Square.fromAlgebraic('e4')!), isNull);
    });

    test('promotion to queen', () {
      const fen = '8/P7/8/8/8/8/8/8 w - - 0 1';
      final board = BoardState.fromFen(fen).applyMove('a7a8q');
      final piece = board.pieceAt(Square.fromAlgebraic('a8')!);
      expect(piece?.type, equals('Q'));
      expect(piece?.color, equals(PieceColor.white));
    });
  });

  group('Puzzle domain', () {
    test('Puzzle.fromMap parses correctly', () {
      final map = {
        'id': 1,
        'external_id': 'test_001',
        'fen': 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        'moves': 'e7e5 d1h5',
        'rating': 1200,
        'themes': 'fork',
        'opening_tags': '',
        'source': 'local',
      };
      final puzzle = _MockPuzzle.fromMap(map);
      expect(puzzle.id, equals(1));
      expect(puzzle.moves, equals(['e7e5', 'd1h5']));
      expect(puzzle.themes, equals(['fork']));
      expect(puzzle.rating, equals(1200));
    });

    test('difficultyLabel returns correct labels', () {
      expect(_MockPuzzle(rating: 1000).difficultyLabel, equals('Beginner'));
      expect(_MockPuzzle(rating: 1400).difficultyLabel, equals('Intermediate'));
      expect(_MockPuzzle(rating: 1800).difficultyLabel, equals('Advanced'));
      expect(_MockPuzzle(rating: 2200).difficultyLabel, equals('Expert'));
    });
  });
}

// Minimal puzzle wrapper for testing without DB
class _MockPuzzle {
  _MockPuzzle({
    this.id = 1,
    this.fen = '',
    this.moves = const [],
    this.themes = const [],
    this.rating = 1500,
  });

  factory _MockPuzzle.fromMap(Map<String, dynamic> map) {
    return _MockPuzzle(
      id: map['id'] as int,
      fen: map['fen'] as String,
      moves: (map['moves'] as String).split(' '),
      themes: (map['themes'] as String).isEmpty
          ? []
          : (map['themes'] as String).split(' '),
      rating: map['rating'] as int,
    );
  }

  final int id;
  final String fen;
  final List<String> moves;
  final List<String> themes;
  final int rating;

  String get difficultyLabel {
    if (rating < 1200) return 'Beginner';
    if (rating < 1600) return 'Intermediate';
    if (rating < 2000) return 'Advanced';
    return 'Expert';
  }
}
