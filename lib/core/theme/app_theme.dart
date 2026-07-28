import 'package:flutter/material.dart';

import 'app_preferences.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme({required BoardThemePreset boardThemePreset}) {
    return _buildTheme(
      brightness: Brightness.light,
      boardThemePreset: boardThemePreset,
    );
  }

  static ThemeData darkTheme({required BoardThemePreset boardThemePreset}) {
    return _buildTheme(
      brightness: Brightness.dark,
      boardThemePreset: boardThemePreset,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required BoardThemePreset boardThemePreset,
  }) {
    final palette = _paletteFor(boardThemePreset, brightness);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF111827)
          : const Color(0xFFF6F8FB),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: brightness == Brightness.dark ? 0 : 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: colorScheme.surface,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
      ),
      extensions: [
        ChessBoardTheme(
          lightSquare: palette.lightSquare,
          darkSquare: palette.darkSquare,
          highlight: palette.highlight,
          lastMoveHighlight: palette.lastMoveHighlight,
          borderColor: palette.borderColor,
          focusRing: palette.focusRing,
        ),
      ],
    );
  }

  static _BoardPalette _paletteFor(
    BoardThemePreset preset,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    return switch (preset) {
      BoardThemePreset.tournament => _BoardPalette(
          seedColor: const Color(0xFF1A6B3A),
          lightSquare:
              isDark ? const Color(0xFFDDD7C1) : const Color(0xFFF0D9B5),
          darkSquare:
              isDark ? const Color(0xFF8B6F47) : const Color(0xFFB58863),
          highlight: const Color(0xFFAFF650),
          lastMoveHighlight: const Color(0xCCF6F669),
          borderColor:
              isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          focusRing: const Color(0xFF2563EB),
        ),
      BoardThemePreset.forest => _BoardPalette(
          seedColor: const Color(0xFF285943),
          lightSquare:
              isDark ? const Color(0xFFCCD8C4) : const Color(0xFFE9F0E3),
          darkSquare:
              isDark ? const Color(0xFF557A5B) : const Color(0xFF769656),
          highlight: const Color(0xFFF4D35E),
          lastMoveHighlight: const Color(0xCCFFE082),
          borderColor:
              isDark ? const Color(0xFF334155) : const Color(0xFFB8C5B1),
          focusRing: const Color(0xFF0EA5E9),
        ),
      BoardThemePreset.midnight => _BoardPalette(
          seedColor: const Color(0xFF3B82F6),
          lightSquare:
              isDark ? const Color(0xFFBFC8D6) : const Color(0xFFDDE5F2),
          darkSquare:
              isDark ? const Color(0xFF4B5B7A) : const Color(0xFF6C7A9A),
          highlight: const Color(0xFFFB7185),
          lastMoveHighlight: const Color(0xCCFDA4AF),
          borderColor:
              isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          focusRing: const Color(0xFFF59E0B),
        ),
    };
  }
}

class _BoardPalette {
  const _BoardPalette({
    required this.seedColor,
    required this.lightSquare,
    required this.darkSquare,
    required this.highlight,
    required this.lastMoveHighlight,
    required this.borderColor,
    required this.focusRing,
  });

  final Color seedColor;
  final Color lightSquare;
  final Color darkSquare;
  final Color highlight;
  final Color lastMoveHighlight;
  final Color borderColor;
  final Color focusRing;
}

@immutable
class ChessBoardTheme extends ThemeExtension<ChessBoardTheme> {
  const ChessBoardTheme({
    required this.lightSquare,
    required this.darkSquare,
    required this.highlight,
    required this.lastMoveHighlight,
    required this.borderColor,
    required this.focusRing,
  });

  final Color lightSquare;
  final Color darkSquare;
  final Color highlight;
  final Color lastMoveHighlight;
  final Color borderColor;
  final Color focusRing;

  @override
  ChessBoardTheme copyWith({
    Color? lightSquare,
    Color? darkSquare,
    Color? highlight,
    Color? lastMoveHighlight,
    Color? borderColor,
    Color? focusRing,
  }) {
    return ChessBoardTheme(
      lightSquare: lightSquare ?? this.lightSquare,
      darkSquare: darkSquare ?? this.darkSquare,
      highlight: highlight ?? this.highlight,
      lastMoveHighlight: lastMoveHighlight ?? this.lastMoveHighlight,
      borderColor: borderColor ?? this.borderColor,
      focusRing: focusRing ?? this.focusRing,
    );
  }

  @override
  ChessBoardTheme lerp(ChessBoardTheme? other, double t) {
    if (other is! ChessBoardTheme) return this;
    return ChessBoardTheme(
      lightSquare: Color.lerp(lightSquare, other.lightSquare, t)!,
      darkSquare: Color.lerp(darkSquare, other.darkSquare, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      lastMoveHighlight: Color.lerp(
        lastMoveHighlight,
        other.lastMoveHighlight,
        t,
      )!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
    );
  }
}
