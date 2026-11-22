import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/lock/app_lock_machine.dart';

import '../../helpers/fake_device_lock.dart';

void main() {
  late FakeLockClock clock;

  AppLockMachine machine({
    bool enabled = true,
    RelockDelay delay = RelockDelay.oneMinute,
  }) {
    final m = AppLockMachine(clock: clock, enabled: enabled, delay: delay);
    // Start open, as after the first successful authentication.
    if (enabled) {
      m
        ..beginAuth()
        ..endAuth(success: true);
    }
    return m;
  }

  /// Background for [away], then back: did it lock?
  bool away(AppLockMachine m, Duration away) {
    m.hidden();
    clock.pass(away);
    return m.shown();
  }

  setUp(() => clock = FakeLockClock());

  test('the lock code is plain Dart', () {
    for (final f in Directory('lib/core/lock').listSync()) {
      final source = (f as File).readAsStringSync();
      expect(
        source,
        isNot(contains("import 'package:flutter")),
        reason: f.path,
      );
    }
  });

  test('a cold start is locked when the lock is on, open when off', () {
    expect(AppLockMachine(clock: clock, enabled: true).locked, isTrue);
    expect(AppLockMachine(clock: clock).locked, isFalse);
  });

  test('only a successful authentication unlocks', () {
    final m = AppLockMachine(clock: clock, enabled: true);
    m
      ..beginAuth()
      ..endAuth(success: false);
    expect(m.locked, isTrue);
    m
      ..beginAuth()
      ..endAuth(success: true);
    expect(m.locked, isFalse);
  });

  test('1 minute: 40 seconds stays open, 3 minutes locks (Example 3)', () {
    final m = machine();
    expect(away(m, const Duration(seconds: 40)), isFalse);
    expect(m.locked, isFalse);
    expect(away(m, const Duration(minutes: 3)), isTrue);
    expect(m.locked, isTrue);
  });

  group('both sides of each delay', () {
    for (final (delay, under, atLeast) in [
      (
        RelockDelay.oneMinute,
        const Duration(seconds: 59),
        const Duration(minutes: 1),
      ),
      (
        RelockDelay.fiveMinutes,
        const Duration(minutes: 4, seconds: 59),
        const Duration(minutes: 5),
      ),
    ]) {
      test(delay.name, () {
        final m = machine(delay: delay);
        expect(away(m, under), isFalse);
        expect(m.locked, isFalse);
        expect(away(m, atLeast), isTrue, reason: 'equal locks');
        expect(m.locked, isTrue);
      });
    }

    test('immediately locks on every return', () {
      final m = machine(delay: RelockDelay.immediately);
      expect(away(m, Duration.zero), isTrue);
      m
        ..beginAuth()
        ..endAuth(success: true);
      expect(away(m, const Duration(milliseconds: 10)), isTrue);
    });
  });

  test('time adds up from the first hide, not the last', () {
    final m = machine();
    m.hidden();
    clock.pass(const Duration(seconds: 50));
    m.hidden();
    clock.pass(const Duration(seconds: 20));
    expect(m.shown(), isTrue);
  });

  test('a sleeping phone still locks (wall clock)', () {
    final m = machine();
    m.hidden();
    clock.sleep(const Duration(minutes: 10));
    expect(m.shown(), isTrue);
  });

  test('a clock moved back locks instead of staying open', () {
    final m = machine(delay: RelockDelay.fiveMinutes);
    m.hidden();
    clock.setBack(const Duration(hours: 1));
    expect(m.shown(), isTrue);
  });

  test('the authentication dialog is not a new lock', () {
    final m = machine(delay: RelockDelay.immediately);
    // The dialog sends Kalan to the background and back.
    m
      ..beginAuth()
      ..hidden();
    clock.pass(const Duration(minutes: 10));
    expect(m.shown(), isFalse);
    m.endAuth(success: true);
    expect(m.locked, isFalse);
    // The result may arrive while Kalan is still hidden.
    m
      ..beginAuth()
      ..hidden()
      ..endAuth(success: true);
    expect(m.shown(), isFalse);
    expect(m.locked, isFalse);
    // A real trip to the background afterwards still locks.
    expect(away(m, Duration.zero), isTrue);
  });

  test('a cancelled dialog does not ask again by itself', () {
    final m = AppLockMachine(clock: clock, enabled: true);
    m
      ..beginAuth()
      ..hidden()
      ..endAuth(success: false);
    expect(m.shown(), isFalse);
    expect(m.locked, isTrue);
  });

  test('back to a locked Kalan from the background asks again', () {
    final m = AppLockMachine(clock: clock, enabled: true);
    expect(away(m, const Duration(seconds: 5)), isTrue);
    expect(m.locked, isTrue);
  });

  test('a short look away (no hide) never locks', () {
    final m = machine(delay: RelockDelay.immediately);
    expect(m.shown(), isFalse);
    expect(m.locked, isFalse);
  });

  test('with the lock off nothing locks', () {
    final m = machine(enabled: false, delay: RelockDelay.immediately);
    expect(away(m, const Duration(hours: 1)), isFalse);
    expect(m.locked, isFalse);
  });

  test('turning off opens and stops locking; turning on opens', () {
    final m = AppLockMachine(clock: clock, enabled: true)..disable();
    expect(m.locked, isFalse);
    expect(away(m, const Duration(hours: 1)), isFalse);
    m.enable(RelockDelay.immediately);
    expect(m.locked, isFalse);
    expect(away(m, Duration.zero), isTrue);
  });

  test('a stored delay reads back; unknown is 1 minute', () {
    for (final d in RelockDelay.values) {
      expect(RelockDelay.parse(d.name), d);
    }
    expect(RelockDelay.parse(null), RelockDelay.oneMinute);
    expect(RelockDelay.parse('later'), RelockDelay.oneMinute);
  });
}
