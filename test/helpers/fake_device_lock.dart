import 'dart:async';

import 'package:kalan/core/lock/app_lock_machine.dart';
import 'package:kalan/features/lock/device_lock_gateway.dart';

/// The phone's authentication, answered by the test. Each [authenticate]
/// takes the next of [answers] (then [DeviceAuthResult.success]), or waits
/// for [complete] when [hold] is set.
class FakeDeviceLock implements DeviceLockGateway {
  FakeDeviceLock({
    this.screenLock = true,
    List<DeviceAuthResult> answers = const [],
    this.hold = false,
  }) : _answers = [...answers];

  bool screenLock;
  bool hold;
  final List<DeviceAuthResult> _answers;
  final List<DeviceAuthTexts> asked = [];
  final List<bool> covers = [];
  Completer<DeviceAuthResult>? _pending;

  int get calls => asked.length;

  void answer(DeviceAuthResult result) => _answers.add(result);

  /// Ends a held dialog.
  void complete(DeviceAuthResult result) {
    final pending = _pending;
    _pending = null;
    pending?.complete(result);
  }

  @override
  bool get supported => true;

  @override
  Future<bool> hasScreenLock() async => screenLock;

  @override
  Future<DeviceAuthResult> authenticate(DeviceAuthTexts texts) {
    asked.add(texts);
    if (!screenLock) return Future.value(DeviceAuthResult.noScreenLock);
    if (hold) return (_pending = Completer<DeviceAuthResult>()).future;
    return Future.value(
      _answers.isEmpty ? DeviceAuthResult.success : _answers.removeAt(0),
    );
  }

  @override
  Future<void> setAppSwitcherCover({required bool on}) async => covers.add(on);
}

/// A clock the test moves by hand. [sleep] moves only the wall clock
/// (a sleeping phone's monotonic clock may stand still); [setBack] moves
/// the wall clock back.
class FakeLockClock implements LockClock {
  DateTime _wall = DateTime(2026, 11, 22, 9);
  Duration _monotonic = Duration.zero;

  void pass(Duration d) {
    _wall = _wall.add(d);
    _monotonic += d;
  }

  void sleep(Duration d) => _wall = _wall.add(d);

  void setBack(Duration d) => _wall = _wall.subtract(d);

  @override
  DateTime wall() => _wall;

  @override
  Duration monotonic() => _monotonic;
}
