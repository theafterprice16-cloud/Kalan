import 'package:home_widget/home_widget.dart';

/// The iOS App Group the app and its widget extension share (Roadmap 31).
/// The one Dart copy; the same text is in both entitlements files and in
/// the extension (test/app/platform_setup_test.dart compares them). It
/// follows the temporary bundle id (Decision 1): change all of them
/// together once the id is final.
const widgetAppGroupId = 'group.app.kalan.mobile';

/// The key the snapshot JSON is stored under, read by the native widgets.
const widgetSnapshotKey = 'kalan.widget.snapshot';

/// The iOS widget kind and the Android provider class.
const widgetIosKind = 'KalanWidget';
const widgetAndroidProvider = 'app.kalan.mobile.KalanWidgetProvider';

/// Hands the widget's text to the storage it shares with the native
/// widget and asks the system to redraw it. No network.
abstract interface class WidgetGateway {
  bool get supported;

  Future<void> publish(String snapshotJson);

  /// A tap on the widget while Kalan is running (a cold start from the
  /// widget opens home anyway).
  Stream<void> get taps;
}

/// Web, desktop and tests: no home screen widget.
class NoopWidgetGateway implements WidgetGateway {
  const NoopWidgetGateway();

  @override
  bool get supported => false;

  @override
  Future<void> publish(String snapshotJson) async {}

  @override
  Stream<void> get taps => const Stream.empty();
}

/// iOS (App Group user defaults, WidgetKit reload) and Android (the
/// plugin's shared preferences, an update broadcast to the provider),
/// through home_widget.
class HomeWidgetGateway implements WidgetGateway {
  const HomeWidgetGateway();

  /// Provided on phones only (main()); the background isolate that runs
  /// notification buttons exists only there too.
  @override
  bool get supported => true;

  @override
  Future<void> publish(String snapshotJson) async {
    await HomeWidget.saveWidgetData<String>(
      widgetSnapshotKey,
      snapshotJson,
      appGroupId: widgetAppGroupId,
    );
    await HomeWidget.updateWidget(
      iOSName: widgetIosKind,
      qualifiedAndroidName: widgetAndroidProvider,
    );
  }

  @override
  Stream<void> get taps => HomeWidget.widgetClicked;
}
