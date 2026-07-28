enum BoardThemePreset { tournament, forest, midnight }

extension BoardThemePresetX on BoardThemePreset {
  String get storageKey => switch (this) {
        BoardThemePreset.tournament => 'tournament',
        BoardThemePreset.forest => 'forest',
        BoardThemePreset.midnight => 'midnight',
      };

  static BoardThemePreset fromStorage(String? raw) {
    return BoardThemePreset.values.firstWhere(
      (value) => value.storageKey == raw,
      orElse: () => BoardThemePreset.tournament,
    );
  }
}

enum PieceSetStyle { classic, neo, initials }

extension PieceSetStyleX on PieceSetStyle {
  String get storageKey => switch (this) {
        PieceSetStyle.classic => 'classic',
        PieceSetStyle.neo => 'neo',
        PieceSetStyle.initials => 'initials',
      };

  static PieceSetStyle fromStorage(String? raw) {
    return PieceSetStyle.values.firstWhere(
      (value) => value.storageKey == raw,
      orElse: () => PieceSetStyle.classic,
    );
  }
}

enum CoordinateStyle { inside, outside, hidden }

extension CoordinateStyleX on CoordinateStyle {
  String get storageKey => switch (this) {
        CoordinateStyle.inside => 'inside',
        CoordinateStyle.outside => 'outside',
        CoordinateStyle.hidden => 'hidden',
      };

  static CoordinateStyle fromStorage(String? raw) {
    return CoordinateStyle.values.firstWhere(
      (value) => value.storageKey == raw,
      orElse: () => CoordinateStyle.inside,
    );
  }
}

enum VoiceGuidanceVerbosity { concise, detailed }

extension VoiceGuidanceVerbosityX on VoiceGuidanceVerbosity {
  String get storageKey => switch (this) {
        VoiceGuidanceVerbosity.concise => 'concise',
        VoiceGuidanceVerbosity.detailed => 'detailed',
      };

  static VoiceGuidanceVerbosity fromStorage(String? raw) {
    return VoiceGuidanceVerbosity.values.firstWhere(
      (value) => value.storageKey == raw,
      orElse: () => VoiceGuidanceVerbosity.concise,
    );
  }
}
