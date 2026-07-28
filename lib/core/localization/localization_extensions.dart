import 'package:flutter/widgets.dart';
import 'package:chess_vision_pro/l10n/generated/app_localizations.dart';

extension LocalizationBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
