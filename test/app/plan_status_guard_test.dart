import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The plan status rule (19) is applied once, where a plan's payment list
/// is built (`PlanWithPayments.payments`). Plan-level screens show every
/// payment, so they read `allPayments`; reading `payments` there would
/// hide held payments or crash on a plan with none that count.
void main() {
  test('plan-level code reads allPayments, never the filtered payments', () {
    const files = [
      'lib/app/format.dart',
      'lib/features/plans/plans_screen.dart',
      'lib/features/plans/plan_detail_screen.dart',
      'lib/features/plans/plan_edit_screen.dart',
      'lib/features/plans/pay_later_form.dart',
      'lib/features/plans/refund_actions.dart',
      'lib/features/plans/adjust_amount_screen.dart',
    ];
    final pattern = RegExp(r'\b(plan|p|widget\.plan)\.payments\b');
    final offenders = [
      for (final path in files)
        if (pattern.hasMatch(File(path).readAsStringSync())) path,
    ];
    expect(offenders, isEmpty);
  });

  test('the status rule is applied in one place in lib/', () {
    final users = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path == 'lib/core/engine/plan_status.dart') continue;
      if (entity.readAsStringSync().contains('countsInTotals(')) {
        users.add(path);
      }
    }
    // The model builds the list; a notification still on screen is
    // checked against the same rule before marking a payment.
    expect(users..sort(), [
      'lib/data/models.dart',
      'lib/features/reminders/reminder_actions.dart',
    ]);
  });
}
