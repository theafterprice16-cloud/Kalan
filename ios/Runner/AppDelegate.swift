import Flutter
import UIKit
import UserNotifications
// FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// App lock (27): hides Kalan in the app switcher while the lock is on.
  let appSwitcherCover = AppSwitcherCover()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets reminders show while Kalan is in the foreground too.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Reminder buttons ("Paid", "Remind tonight") run in a background
    // engine without opening the app; it needs the plugins (database,
    // time zone, notifications) too.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // "Open phone settings" from Settings > Reminders; the app lock's
    // app switcher cover (27).
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KalanSystem")
    else { return }
    let cover = appSwitcherCover
    registrar.addSceneDelegate(cover)
    let channel = FlutterMethodChannel(
      name: "kalan/system",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "setAppSwitcherCover" {
        cover.enabled = (call.arguments as? Bool) ?? false
        result(nil)
        return
      }
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

/// App lock (27): while the lock is on, the launch screen (the ground and
/// the mark, light or dark) covers Kalan before iOS takes the app switcher
/// snapshot, and goes away when Kalan is active again. Kalan's own Flutter
/// cover handles the moment Kalan only loses focus. Screenshots stay
/// allowed. Registered as a scene delegate, so Flutter's own scene
/// handling is untouched.
final class AppSwitcherCover: NSObject, FlutterSceneLifeCycleDelegate {
  var enabled = false
  private var cover: UIView?

  func sceneDidEnterBackground(_ scene: UIScene) {
    guard enabled, cover == nil, let windowScene = scene as? UIWindowScene,
      let window = windowScene.windows.first(where: { $0.isKeyWindow })
        ?? windowScene.windows.first,
      let view = UIStoryboard(name: "LaunchScreen", bundle: nil)
        .instantiateInitialViewController()?.view
    else { return }
    view.frame = window.bounds
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(view)
    cover = view
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    cover?.removeFromSuperview()
    cover = nil
  }
}
