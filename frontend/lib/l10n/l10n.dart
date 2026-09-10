import 'package:flutter/widgets.dart';
import 'package:heart_feedback/l10n/app_localizations.dart';

export 'package:heart_feedback/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
