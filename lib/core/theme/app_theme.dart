import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primaryColor = Color(0xFF1A6B3A);
  static const Color _boardLight = Color(0xFFF0D9B5);
  static const Color _boardDark = Color(0xFFB58863);
  static const Color _highlightColor = Color(0xFFAFF650);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
        ),
        extensions: const [
          ChessBoardTheme(
            lightSquare: _boardLight,
            darkSquare: _boardDark,
            highlight: _highlightColor,
            lastMoveHighlight: Color(0xCCF6F669),
          ),
        ],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
        ),
        extensions: const [
          ChessBoardTheme(
            lightSquare: Color(0xFFCDD16F),
            darkSquare: Color(0xFF739552),
            highlight: Color(0xFFAFF650),
            lastMoveHighlight: Color(0xCCF6F669),
          ),
        ],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      );
}

@immutable
class ChessBoardTheme extends ThemeExtension<ChessBoardTheme> {
  const ChessBoardTheme({
    required this.lightSquare,
    required this.darkSquare,
    required this.highlight,
    required this.lastMoveHighlight,
  });

  final Color lightSquare;
  final Color darkSquare;
  final Color highlight;
  final Color lastMoveHighlight;

  @override
  ChessBoardTheme copyWith({
    Color? lightSquare,
    Color? darkSquare,
    Color? highlight,
    Color? lastMoveHighlight,
  }) {
    return ChessBoardTheme(
      lightSquare: lightSquare ?? this.lightSquare,
      darkSquare: darkSquare ?? this.darkSquare,
      highlight: highlight ?? this.highlight,
      lastMoveHighlight: lastMoveHighlight ?? this.lastMoveHighlight,
    );
  }

  @override
  ChessBoardTheme lerp(ChessBoardTheme? other, double t) {
    if (other is! ChessBoardTheme) return this;
    return ChessBoardTheme(
      lightSquare: Color.lerp(lightSquare, other.lightSquare, t)!,
      darkSquare: Color.lerp(darkSquare, other.darkSquare, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      lastMoveHighlight:
          Color.lerp(lastMoveHighlight, other.lastMoveHighlight, t)!,
    );
  }
}
