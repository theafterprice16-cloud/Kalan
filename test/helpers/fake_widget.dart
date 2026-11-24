import 'dart:async';

import 'package:kalan/features/home_widget/widget_gateway.dart';

/// The home screen widget's storage (31), recorded by the test.
class FakeWidgetGateway implements WidgetGateway {
  final published = <String>[];
  final tapController = StreamController<void>.broadcast();

  @override
  bool get supported => true;

  @override
  Future<void> publish(String snapshotJson) async =>
      published.add(snapshotJson);

  @override
  Stream<void> get taps => tapController.stream;

  /// A tap on the widget while the app runs.
  void tap() => tapController.add(null);
}
