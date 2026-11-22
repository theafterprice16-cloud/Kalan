// Flags provider templates (Roadmap 25) whose check date is more than six
// months old, as GitHub Actions warnings: the CI stays green. Run:
//   dart run tool/check_provider_templates.dart [--today=YYYY-MM-DD]
// An unreadable file fails (the schema test fails too). Before a release,
// re-check every template on its source links (docs/YAYIN_KONTROL.md).
import 'dart:io';

import 'package:kalan/core/date/local_date.dart';
import 'package:kalan/core/templates/provider_templates.dart';

void main(List<String> args) {
  final now = DateTime.now();
  var today = LocalDate(now.year, now.month, now.day);
  for (final arg in args) {
    if (arg.startsWith('--today=')) {
      today = parseCheckedDate(arg.substring('--today='.length), '--today');
    }
  }
  final List<ProviderTemplate> templates;
  try {
    templates = parseProviderTemplates(
      File(providerTemplatesAsset).readAsStringSync(),
    );
  } on ProviderTemplateFormatException catch (e) {
    stdout.writeln('::error file=$providerTemplatesAsset::${e.message}');
    exitCode = 1;
    return;
  }
  final warnings = staleTemplateWarnings(templates, today);
  for (final w in warnings) {
    stdout.writeln('::warning file=$providerTemplatesAsset::$w');
  }
  stdout.writeln(
    '${templates.length} templates, ${warnings.length} older than '
    '$staleAfterMonths months.',
  );
}
