import 'package:home_widget/home_widget.dart';

/// The iOS App Group the app and its widget extension share (Roadmap 31).
/// The one Dart copy; the same text is in both entitlements files and in
/// the extension (test/app/widget_platform_test.dart compares them). It
/// follows the temporary bundle id (Decision 1): change all of them
/// together once the id is final.
const widgetAppGroupId = 'group.app.kalan.mobile';

/// The key the snapshot JSON is stored under, read by the native widgets.
const widgetSnapshotKey = 'kalan.widget.snapshot';

/// The iOS widget kind and the Android provider class.
const widgetIosKind = 'KalanWidget';
const widgetAndroidProvider = 'app.kalan.mobile.KalanWidgetProvider';

/// Where a tap on a widget leads.
enum WidgetTap {
  /// Home (the home screen widget; the Lock Screen widget with Pro).
  home,

  /// The Pro screen (the Lock Screen widget without Pro, Roadmap 32).
  pro,
}

/// The path the Lock Screen widget's Pro note opens:
/// `kalan://widget/pro?homeWidget` (ios/KalanWidget/KalanWidget.swift).
const widgetProPath = '/pro';

/// What a widget link asks for; anything else, an empty link (Android)
/// included, opens home.
WidgetTap widgetTapOf(Uri? uri) =>
    uri?.path == widgetProPath ? WidgetTap.pro : WidgetTap.home;

/// Hands the widget's text to the storage it shares with the native
/// widget and asks the system to redraw it. No network.
abstract interface class WidgetGateway {
  bool get supported;

  Future<void> publish(String snapshotJson);

  /// A tap on a widget while Kalan is running.
  Stream<WidgetTap> get taps;

  /// The tap that started Kalan, if a widget did (null: something else).
  Future<WidgetTap?> launchTap();
}

/// Web, desktop and tests: no home screen widget.
class NoopWidgetGateway implements WidgetGateway {
  const NoopWidgetGateway();

  @override
  bool get supported => false;

  @override
  Future<void> publish(String snapshotJson) async {}

  @override
  Stream<WidgetTap> get taps => const Stream.empty();

  @override
  Future<WidgetTap?> launchTap() async => null;
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
  Stream<WidgetTap> get taps => HomeWidget.widgetClicked.map(widgetTapOf);

  @override
  Future<WidgetTap?> launchTap() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      return uri == null ? null : widgetTapOf(uri);
    } on Object {
      return null;
    }
  }
}
