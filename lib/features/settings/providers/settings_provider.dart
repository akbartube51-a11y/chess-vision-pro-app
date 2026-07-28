import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _load();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _boardFlipEnabled = true;
  bool get boardFlipEnabled => _boardFlipEnabled;

  BoardThemePreset _boardThemePreset = BoardThemePreset.tournament;
  BoardThemePreset get boardThemePreset => _boardThemePreset;

  PieceSetStyle _pieceSetStyle = PieceSetStyle.classic;
  PieceSetStyle get pieceSetStyle => _pieceSetStyle;

  CoordinateStyle _coordinateStyle = CoordinateStyle.inside;
  CoordinateStyle get coordinateStyle => _coordinateStyle;

  bool _voiceGuidanceEnabled = true;
  bool get voiceGuidanceEnabled => _voiceGuidanceEnabled;

  VoiceGuidanceVerbosity _voiceGuidanceVerbosity =
      VoiceGuidanceVerbosity.concise;
  VoiceGuidanceVerbosity get voiceGuidanceVerbosity => _voiceGuidanceVerbosity;

  String? _localeCode;
  String? get localeCode => _localeCode;
  Locale? get locale => _localeCode == null ? null : Locale(_localeCode!);

  String? _puzzleSourceUrl;
  String? get puzzleSourceUrl => _puzzleSourceUrl;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'system';
    _themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _boardFlipEnabled = prefs.getBool('board_flip_enabled') ?? true;
    _boardThemePreset = BoardThemePresetX.fromStorage(
      prefs.getString('board_theme_preset'),
    );
    _pieceSetStyle = PieceSetStyleX.fromStorage(
      prefs.getString('piece_set_style'),
    );
    _coordinateStyle = CoordinateStyleX.fromStorage(
      prefs.getString('coordinate_style'),
    );
    _voiceGuidanceEnabled = prefs.getBool('voice_guidance_enabled') ?? true;
    _voiceGuidanceVerbosity = VoiceGuidanceVerbosityX.fromStorage(
      prefs.getString('voice_guidance_verbosity'),
    );
    _localeCode = prefs.getString('locale_code');
    _puzzleSourceUrl = prefs.getString('puzzle_source_url');
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme_mode',
        switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          _ => 'system',
        });
  }

  Future<void> setBoardFlipEnabled(bool value) async {
    _boardFlipEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('board_flip_enabled', value);
  }

  Future<void> setBoardThemePreset(BoardThemePreset value) async {
    _boardThemePreset = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('board_theme_preset', value.storageKey);
  }

  Future<void> setPieceSetStyle(PieceSetStyle value) async {
    _pieceSetStyle = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('piece_set_style', value.storageKey);
  }

  Future<void> setCoordinateStyle(CoordinateStyle value) async {
    _coordinateStyle = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coordinate_style', value.storageKey);
  }

  Future<void> setVoiceGuidanceEnabled(bool value) async {
    _voiceGuidanceEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_guidance_enabled', value);
  }

  Future<void> setVoiceGuidanceVerbosity(VoiceGuidanceVerbosity value) async {
    _voiceGuidanceVerbosity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice_guidance_verbosity', value.storageKey);
  }

  Future<void> setLocaleCode(String? value) async {
    _localeCode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove('locale_code');
      return;
    }
    await prefs.setString('locale_code', value);
  }

  Future<void> setPuzzleSourceUrl(String? value) async {
    _puzzleSourceUrl = value?.trim().isEmpty ?? true ? null : value?.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_puzzleSourceUrl == null) {
      await prefs.remove('puzzle_source_url');
      return;
    }
    await prefs.setString('puzzle_source_url', _puzzleSourceUrl!);
  }
}
