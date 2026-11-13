package app.kalan.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Re-plans payment reminders after a reboot or a clock or time zone change,
 * so "09:00" stays 09:00 local time without opening the app.
 *
 * Starts a headless Flutter engine on the Dart entry point
 * `rescheduleRemindersInBackground` (lib/main.dart), which opens the local
 * database, rebuilds the reminders and reports "done". No network.
 */
class ReminderRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        val pending = goAsync()
        val main = Handler(Looper.getMainLooper())
        main.post {
            var engine: FlutterEngine? = null
            var finished = false
            fun finish() {
                if (finished) return
                finished = true
                engine?.destroy()
                pending.finish()
            }
            // Broadcast receivers get about 10 seconds.
            main.postDelayed({ finish() }, 9_000)
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(app)
                loader.ensureInitializationCompleteAsync(app, null, main) {
                    val e = FlutterEngine(app)
                    engine = e
                    MethodChannel(e.dartExecutor.binaryMessenger, "kalan/background")
                        .setMethodCallHandler { call, result ->
                            if (call.method == "done") {
                                result.success(null)
                                main.post { finish() }
                            } else {
                                result.notImplemented()
                            }
                        }
                    e.dartExecutor.executeDartEntrypoint(
                        DartExecutor.DartEntrypoint(
                            loader.findAppBundlePath(),
                            "rescheduleRemindersInBackground",
                        ),
                    )
                }
            } catch (error: Throwable) {
                finish()
            }
        }
    }
}
