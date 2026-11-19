import '../../l10n/generated/app_localizations.dart';

/// What Pro adds today, one line each, in order. The single source for the
/// Pro screen: a Pro feature (32, 35, 36, 43, 44, 45) adds its line here
/// when it ships. Never a "coming soon" line.
List<String> proFeatureLines(AppLocalizations l10n) => [
  l10n.proFeatureUnlimitedPlans,
];
