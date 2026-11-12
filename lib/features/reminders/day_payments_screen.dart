import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../core/date/local_date.dart';
import '../../core/design/widgets.dart';
import '../../core/routing/routes.dart';
import '../home/home_view.dart';
import '../home/payment_tile.dart';

/// "Payments of the day": where a reminder tap lands (/day/2026-11-12).
class DayPaymentsScreen extends ConsumerWidget {
  const DayPaymentsScreen({required this.dateText, super.key});

  final String dateText;

  static LocalDate? parse(String text) {
    final parts = text.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return null;
    final (y, m, d) = (parts[0]!, parts[1]!, parts[2]!);
    if (m < 1 || m > 12 || d < 1 || d > LocalDate.daysInMonth(y, m)) {
      return null;
    }
    return LocalDate(y, m, d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final date = parse(dateText);
    // Opened from a notification there may be nothing to pop back to.
    final back = context.canPop()
        ? null
        : IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const BackButtonIcon(),
            onPressed: () => context.go(Routes.home),
          );
    if (date == null) {
      return Scaffold(
        appBar: AppBar(leading: back),
        body: Center(child: EmptyState(l10n.dayPaymentsEmpty)),
      );
    }
    final entries = ref.watch(dayEntriesProvider(date));
    final total = entries?.fold(0, (sum, e) => sum + e.amountMinor) ?? 0;
    return Scaffold(
      appBar: AppBar(
        leading: back,
        title: Text(l10n.dayPaymentsTitle(context.longDate(date))),
      ),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? Center(child: EmptyState(l10n.dayPaymentsEmpty))
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    l10n.planTotal(ref.money(context, total)),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final e in entries) PaymentTile(entry: e),
              ],
            ),
    );
  }
}
