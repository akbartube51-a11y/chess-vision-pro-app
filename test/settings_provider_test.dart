import 'package:chess_vision_pro/core/theme/app_preferences.dart';
import 'package:chess_vision_pro/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads persisted settings', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'board_theme_preset': 'midnight',
      'piece_set_style': 'initials',
      'coordinate_style': 'outside',
      'voice_guidance_enabled': false,
      'voice_guidance_verbosity': 'detailed',
      'locale_code': 'es',
      'puzzle_source_url': 'https://example.com/data.csv',
    });

    final provider = SettingsProvider();
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.boardThemePreset, BoardThemePreset.midnight);
    expect(provider.pieceSetStyle, PieceSetStyle.initials);
    expect(provider.coordinateStyle, CoordinateStyle.outside);
    expect(provider.voiceGuidanceEnabled, isFalse);
    expect(provider.voiceGuidanceVerbosity, VoiceGuidanceVerbosity.detailed);
    expect(provider.localeCode, 'es');
    expect(provider.puzzleSourceUrl, 'https://example.com/data.csv');
  });

  test('persists source URL updates', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = SettingsProvider();
    await Future<void>.delayed(const Duration(milliseconds: 1));

    await provider.setPuzzleSourceUrl(' https://example.com/feed.csv ');

    expect(provider.puzzleSourceUrl, 'https://example.com/feed.csv');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('puzzle_source_url'),
      'https://example.com/feed.csv',
    );
  });
}
