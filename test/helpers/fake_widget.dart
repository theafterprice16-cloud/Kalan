import 'dart:async';

import 'package:kalan/features/home_widget/widget_gateway.dart';

/// The home screen widget's storage (31), recorded by the test.
class FakeWidgetGateway implements WidgetGateway {
  FakeWidgetGateway({this.launchedBy});

  final published = <String>[];
  final tapController = StreamController<WidgetTap>.broadcast();

  /// The widget tap that started the app, if any.
  final WidgetTap? launchedBy;

  @override
  bool get supported => true;

  @override
  Future<void> publish(String snapshotJson) async =>
      published.add(snapshotJson);

  @override
  Stream<WidgetTap> get taps => tapController.stream;

  @override
  Future<WidgetTap?> launchTap() async => launchedBy;

  /// A tap on a widget while the app runs: home, or the Lock Screen
  /// widget's Pro note (32).
  void tap([WidgetTap to = WidgetTap.home]) => tapController.add(to);
}
