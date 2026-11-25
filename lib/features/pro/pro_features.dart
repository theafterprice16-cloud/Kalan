import '../../l10n/generated/app_localizations.dart';

/// What Pro adds today, one line each, in order. The single source for the
/// Pro screen: a Pro feature (32, 35, 36, 43, 44, 45) adds its line here
/// when it ships. Never a "coming soon" line, and never a line for what
/// this phone cannot use: the Lock Screen widget (32) is iPhone only
/// ([lockScreenWidget]).
List<String> proFeatureLines(
  AppLocalizations l10n, {
  required bool lockScreenWidget,
}) => [
  l10n.proFeatureUnlimitedPlans,
  if (lockScreenWidget) l10n.proFeatureLockScreenWidget,
];
