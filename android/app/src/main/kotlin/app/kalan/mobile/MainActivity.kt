package app.kalan.mobile

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: the app lock (local_auth) shows the system's
// own face, fingerprint or passcode dialog, which needs a fragment host.
class MainActivity : FlutterFragmentActivity() {
    companion object {
        /** App lock on: Kalan's screen is left out of the recents screenshot. */
        @Volatile
        private var appSwitcherCover = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Re-applied to a new activity; Dart sends the state again at start.
        applyAppSwitcherCover()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kalan/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(null)
                    }
                    "setAppSwitcherCover" -> {
                        appSwitcherCover = call.arguments == true
                        applyAppSwitcherCover()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Android 13+: no screenshot of Kalan in recent apps while the app
     * lock is on. Screenshots by the user stay allowed (no secure flag).
     * Older versions rely on the Flutter cover drawn when Kalan pauses.
     */
    private fun applyAppSwitcherCover() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setRecentsScreenshotEnabled(!appSwitcherCover)
        }
    }

    /** Opens Kalan's notification settings ("Open phone settings"). */
    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(android.net.Uri.fromParts("package", packageName, null))
        }
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }
}
