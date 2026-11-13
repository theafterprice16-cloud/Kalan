import Flutter
import UIKit
import UserNotifications
// Needed for FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets reminders show while Kalan is in the foreground too.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // The "Paid" action runs in a background isolate; it needs the plugins.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // "Open phone settings" from Settings > Reminders.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KalanSystem")
    else { return }
    let channel = FlutterMethodChannel(
      name: "kalan/system",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "openNotificationSettings" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let target: String
      if #available(iOS 16.0, *) {
        target = UIApplication.openNotificationSettingsURLString
      } else {
        target = UIApplication.openSettingsURLString
      }
      if let url = URL(string: target) {
        UIApplication.shared.open(url)
      }
      result(nil)
    }
  }
}
