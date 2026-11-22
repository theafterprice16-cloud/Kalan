import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../core/design/choice_dialog.dart';
import '../../core/design/kalan_dialog.dart';
import '../../core/templates/provider_templates.dart' show foldName;
import 'holiday_providers.dart';

/// The holiday country's name in the app language; "None" for '' or a
/// country not chosen yet (Roadmap 26).
String holidayCountryLabel(BuildContext context, String? code) =>
    code == null || code.isEmpty
    ? context.l10n.holidayCountryNone
    : context.l10n.holidayCountryName(code);

/// The holiday country choices: "None", then the countries of the shipped
/// list by name in the app language (decision 5: only countries with
/// data).
List<(String, String)> holidayCountryOptions(
  BuildContext context,
  Iterable<String> codes,
) {
  final named = [
    for (final code in codes) (code, context.l10n.holidayCountryName(code)),
  ]..sort((a, b) => foldName(a.$2).compareTo(foldName(b.$2)));
  return [('', context.l10n.holidayCountryNone), ...named];
}

/// The Settings row's dialog: picks the holiday country and moves the
/// stored card dates in one step ([HolidayRepository.sync]).
Future<void> pickHolidayCountry(BuildContext context, WidgetRef ref) async {
  final countries = ref.read(holidayCountriesProvider);
  if (countries == null) return;
  final l10n = context.l10n;
  final current = ref.read(settingsProvider).value?.holidayCountry ?? '';
  final picked = await showKalanDialog<Choice<String>>(
    context: context,
    builder: (dialogContext) => ChoiceDialog<String>(
      title: l10n.settingsHolidayCountry,
      note: l10n.holidayCountryNote,
      selected: current,
      options: holidayCountryOptions(context, [
        for (final c in countries) c.country,
      ]),
    ),
  );
  if (picked == null || picked.value == current) return;
  await ref
      .read(holidayRepositoryProvider)
      .sync(
        countries: countries,
        region: ref.read(deviceRegionProvider),
        choose: picked.value,
      );
}
