import 'dart:async';

/// Runs [_task] after [debounce] of quiet, at most one run at a time, in
/// the background (nothing waits for it): a burst of requests runs it
/// once, a request during a run runs it once more afterwards. A failed
/// run (the database closing, the platform busy) must not break the app;
/// the next request tries again. Behind [ReminderSync] and [WidgetSync].
class DebouncedTask {
  DebouncedTask(this._task, {required this.debounce});

  final Future<void> Function() _task;
  final Duration debounce;
  Timer? _timer;
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;
  Completer<void>? _idle;

  /// Completes when no run is waiting or running.
  Future<void> get idle => _idle?.future ?? Future.value();

  void request() {
    if (_disposed) return;
    _idle ??= Completer<void>();
    _timer?.cancel();
    _timer = Timer(debounce, _start);
  }

  void _start() {
    _timer = null;
    if (_running != null) {
      _again = true;
      return;
    }
    _running = _run();
  }

  Future<void> _run() async {
    do {
      _again = false;
      try {
        await _task();
      } on Object {
        if (_disposed) break;
      }
    } while (_again && !_disposed);
    _running = null;
    if (_timer == null) _finish();
  }

  void _finish() {
    final idle = _idle;
    _idle = null;
    if (idle != null && !idle.isCompleted) idle.complete();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _finish();
  }
}
