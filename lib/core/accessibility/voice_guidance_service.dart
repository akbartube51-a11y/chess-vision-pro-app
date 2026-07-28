import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/app_preferences.dart';

class VoiceGuidanceService {
  const VoiceGuidanceService();

  Future<void> announce(
    BuildContext context,
    String message, {
    required bool enabled,
  }) async {
    if (!enabled || message.trim().isEmpty) return;
    SemanticsService.announce(message, Directionality.of(context));
  }

  String withVerbosity({
    required String headline,
    String? details,
    required VoiceGuidanceVerbosity verbosity,
  }) {
    if (verbosity == VoiceGuidanceVerbosity.concise ||
        details == null ||
        details.trim().isEmpty) {
      return headline;
    }
    return '$headline. $details';
  }
}
