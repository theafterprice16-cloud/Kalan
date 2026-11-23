/// App lock (Roadmap 27): when Kalan locks itself. Plain Dart, no
/// Flutter: the app feeds it lifecycle events and authentication results,
/// tests feed it a fake clock.
library;

/// "Lock again": how long Kalan may stay in the background before it
/// asks again. Stored by [name].
enum RelockDelay {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5));

  const RelockDelay(this.duration);

  final Duration duration;

  /// The default (product owner's decision, Roadmap 27).
  static const standard = RelockDelay.oneMinute;

  /// The stored [name]; unknown or missing reads as [standard].
  static RelockDelay parse(String? name) => RelockDelay.values.firstWhere(
    (d) => d.name == name,
    orElse: () => standard,
  );
}

/// Time for the machine. [wall] is the phone's clock; [monotonic] only
/// runs forward but may stop while the phone sleeps. Kalan locks when
/// either says the delay has passed, so neither moving the clock back nor
/// a sleeping phone keeps it open.
abstract interface class LockClock {
  DateTime wall();
  Duration monotonic();
}

/// The real clock.
class SystemLockClock implements LockClock {
  SystemLockClock() : _watch = Stopwatch()..start();

  final Stopwatch _watch;

  @override
  DateTime wall() => DateTime.now();

  @override
  Duration monotonic() => _watch.elapsed;
}

/// The lock's rules:
/// - a cold start is locked when the lock is on;
/// - going to the background records the moment; coming back after the
///   chosen delay or longer locks ("Immediately": every time);
/// - while the phone's own authentication is on screen, background and
///   foreground events are not a new lock (the dialog may cover Kalan);
/// - only a successful authentication unlocks;
/// - with the lock off nothing ever locks.
class AppLockMachine {
  AppLockMachine({
    required this._clock,
    bool enabled = false,
    this.delay = RelockDelay.standard,
  }) : _enabled = enabled,
       _locked = enabled;

  final LockClock _clock;
  bool _enabled;
  bool _locked;
  bool _authenticating = false;
  bool _hiddenDuringAuth = false;
  bool _hiddenWhileLocked = false;
  DateTime? _hiddenWall;
  Duration? _hiddenMonotonic;

  bool get enabled => _enabled;

  /// "Lock again"; a change applies from the next return.
  RelockDelay delay;
  bool get locked => _locked;
  bool get authenticating => _authenticating;

  /// Turned on after a successful authentication: open now.
  void enable(RelockDelay delay) {
    _enabled = true;
    this.delay = delay;
    _locked = false;
    _clearHidden();
  }

  /// Turned off (by the user, or because the phone has no screen lock any
  /// more): open, and nothing locks again.
  void disable() {
    _enabled = false;
    _locked = false;
    _clearHidden();
  }

  /// The phone's authentication dialog is about to show.
  void beginAuth() => _authenticating = true;

  /// The dialog closed; [success] opens Kalan.
  void endAuth({required bool success}) {
    _authenticating = false;
    if (success) {
      _locked = false;
      _clearHidden();
    }
  }

  /// Kalan left the screen (home, another app, phone locked).
  void hidden() {
    if (_authenticating) {
      _hiddenDuringAuth = true;
      // Left while the dialog was open (the Home button): if the dialog
      // ends before Kalan is back, coming back asks again.
      if (_locked) _hiddenWhileLocked = true;
      return;
    }
    if (!_enabled) return;
    if (_locked) {
      _hiddenWhileLocked = true;
      return;
    }
    if (_hiddenWall != null) return;
    _hiddenWall = _clock.wall();
    _hiddenMonotonic = _clock.monotonic();
  }

  /// Kalan is back on screen. Returns true when it should ask for the
  /// phone's authentication now: it has just locked, or it was locked and
  /// comes back from the background. Never after the authentication
  /// dialog itself, so a cancelled dialog does not open again by itself.
  bool shown() {
    if (_authenticating) {
      // Hidden by the authentication dialog itself (Android's passcode
      // screen): not a new lock, and the dialog is still answering.
      _hiddenDuringAuth = false;
      _hiddenWhileLocked = false;
      return false;
    }
    if (_hiddenDuringAuth) {
      // The dialog ended while Kalan was away: still locked, ask once.
      _hiddenDuringAuth = false;
      final again = _locked && _hiddenWhileLocked;
      _clearHidden();
      return again;
    }
    final wallAt = _hiddenWall;
    final monotonicAt = _hiddenMonotonic;
    final wasHiddenWhileLocked = _hiddenWhileLocked;
    _clearHidden();
    if (!_enabled) return false;
    if (_locked) return wasHiddenWhileLocked;
    if (wallAt == null || monotonicAt == null) return false;
    final wall = _clock.wall().difference(wallAt);
    final monotonic = _clock.monotonic() - monotonicAt;
    final limit = delay.duration;
    if (wall.isNegative || wall >= limit || monotonic >= limit) {
      _locked = true;
      return true;
    }
    return false;
  }

  void _clearHidden() {
    _hiddenWhileLocked = false;
    _hiddenWall = null;
    _hiddenMonotonic = null;
  }
}
