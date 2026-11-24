package app.kalan.mobile

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.util.Calendar

/**
 * Kalan's home screen widget (Roadmap 31), small (about 2x2) and medium
 * (about 4x2), resizable.
 *
 * Shows only text the app wrote (lib/core/widget/widget_snapshot.dart):
 * one record per day for today and the next 7 days, every amount and
 * date already formatted, amounts already masked where they must be.
 * This class calculates and formats nothing: it picks the record whose
 * year, month and day are the phone's today and lays its strings out; no
 * record for today means the app has not run for over a week, and the
 * prebuilt "Open Kalan for the latest." shows instead (no amount).
 *
 * Redrawn when the app writes (home_widget's update broadcast), when the
 * phone's date, clock, time zone or language changes, after a reboot or
 * an update, and once after each local midnight (an inexact alarm that
 * waits for the phone to wake; no exact-alarm permission). No Dart runs.
 */
class KalanWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) {
        val snapshot = readSnapshot(context)
        for (id in ids) {
            manager.updateAppWidget(id, viewsFor(context, manager, id, snapshot))
        }
        scheduleMidnight(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        options: Bundle,
    ) {
        // Resized: before Android 12 the size is picked here.
        manager.updateAppWidget(id, viewsFor(context, manager, id, readSnapshot(context)))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_MIDNIGHT,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> updateAll(context)
        }
    }

    override fun onDisabled(context: Context) {
        // The last widget is gone: no more midnight alarm.
        alarmManager(context)?.cancel(midnightIntent(context))
    }

    companion object {
        private const val SNAPSHOT_KEY = "kalan.widget.snapshot"
        private const val SNAPSHOT_VERSION = 1
        private const val ACTION_MIDNIGHT = "app.kalan.mobile.WIDGET_MIDNIGHT"

        /** At least this wide (dp) for the medium layout. */
        private const val MEDIUM_MIN_WIDTH_DP = 250

        /**
         * At least this tall (dp) for three payment rows on the medium
         * layout; lower, two rows show, never a cut one.
         */
        private const val THREE_ROWS_MIN_HEIGHT_DP = 140

        private fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, KalanWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            val snapshot = readSnapshot(context)
            for (id in ids) {
                manager.updateAppWidget(id, viewsFor(context, manager, id, snapshot))
            }
            scheduleMidnight(context)
        }

        private fun readSnapshot(context: Context): JSONObject? = try {
            HomeWidgetPlugin.getData(context).getString(SNAPSHOT_KEY, null)
                ?.let { JSONObject(it) }
                ?.takeIf { it.optInt("v") == SNAPSHOT_VERSION }
        } catch (e: Exception) {
            null
        }

        /** The record for the phone's today; null when there is none. */
        private fun todayRecord(snapshot: JSONObject?): JSONObject? {
            val days = snapshot?.optJSONArray("days") ?: return null
            val now = Calendar.getInstance()
            val y = now.get(Calendar.YEAR)
            val m = now.get(Calendar.MONTH) + 1
            val d = now.get(Calendar.DAY_OF_MONTH)
            for (i in 0 until days.length()) {
                val day = days.optJSONObject(i) ?: continue
                if (day.optInt("y") == y && day.optInt("m") == m && day.optInt("d") == d) {
                    return day
                }
            }
            return null
        }

        private fun viewsFor(
            context: Context,
            manager: AppWidgetManager,
            id: Int,
            snapshot: JSONObject?,
        ): RemoteViews {
            val today = todayRecord(snapshot)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // The launcher picks the layout that fits each size: the
                // medium one with as many rows as fit, never a cut row.
                return RemoteViews(
                    mapOf(
                        SizeF(110f, 110f) to
                            build(context, R.layout.kalan_widget_small, snapshot, today, rows = 0),
                        SizeF(MEDIUM_MIN_WIDTH_DP.toFloat(), 110f) to
                            build(context, R.layout.kalan_widget_medium, snapshot, today, rows = 2),
                        SizeF(MEDIUM_MIN_WIDTH_DP.toFloat(), THREE_ROWS_MIN_HEIGHT_DP.toFloat()) to
                            build(context, R.layout.kalan_widget_medium, snapshot, today, rows = 3),
                    ),
                )
            }
            // Portrait: the smallest width and the largest height.
            val options = manager.getAppWidgetOptions(id)
            val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
            if (width < MEDIUM_MIN_WIDTH_DP) {
                return build(context, R.layout.kalan_widget_small, snapshot, today, rows = 0)
            }
            return build(
                context,
                R.layout.kalan_widget_medium,
                snapshot,
                today,
                rows = if (height >= THREE_ROWS_MIN_HEIGHT_DP) 3 else 2,
            )
        }

        private fun build(
            context: Context,
            layout: Int,
            snapshot: JSONObject?,
            today: JSONObject?,
            rows: Int,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, layout)
            views.setOnClickPendingIntent(
                android.R.id.background,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            // The app's language, not the phone's: Arabic mirrors (24).
            views.setInt(
                android.R.id.background,
                "setLayoutDirection",
                if (snapshot?.optBoolean("rtl") == true) {
                    View.LAYOUT_DIRECTION_RTL
                } else {
                    View.LAYOUT_DIRECTION_LTR
                },
            )

            // Setup and "no payments yet" hold on any date; otherwise the
            // record for today, or the stale text when there is none.
            val mode = snapshot?.optString("mode")
            val message = if (snapshot == null) {
                // Nothing written yet (the app has not run since the
                // widget was added): blank until it does.
                ""
            } else {
                when {
                    mode == "setup" || mode == "noPayments" -> snapshot.optString("message")
                    today == null -> snapshot.optString("stale")
                    else -> null
                }
            }
            if (message != null) {
                views.setViewVisibility(R.id.widget_content, View.GONE)
                views.setViewVisibility(R.id.widget_message, View.VISIBLE)
                views.setTextViewText(R.id.widget_message, message)
                views.setContentDescription(android.R.id.background, message)
                return views
            }
            val day = today!!
            views.setViewVisibility(R.id.widget_message, View.GONE)
            views.setViewVisibility(R.id.widget_content, View.VISIBLE)
            views.setContentDescription(android.R.id.background, day.optString("spoken"))
            views.setTextViewText(R.id.widget_title, day.optString("title"))
            views.setTextViewText(R.id.widget_until, day.optString("until"))
            // One number view per colour, so the colours come from the
            // layout's resources and follow light and dark mode.
            val number = when (day.optString("state")) {
                "left" -> R.id.widget_number_left
                "negative" -> R.id.widget_number_negative
                else -> R.id.widget_number_plain
            }
            for (view in NUMBER_VIEWS) {
                views.setViewVisibility(view, if (view == number) View.VISIBLE else View.GONE)
            }
            // The small size gets the short form of a very long number
            // (chosen by the app, see widgetSmallNumberMax).
            views.setTextViewText(
                number,
                day.optString(if (rows > 0) "number" else "numberSmall"),
            )

            if (rows > 0) {
                val list = day.optJSONArray("rows")
                val count = minOf(list?.length() ?: 0, rows)
                for ((i, row) in ROWS.withIndex()) {
                    val item = if (i < count) list?.optJSONObject(i) else null
                    if (item == null) {
                        views.setViewVisibility(row.row, View.GONE)
                        continue
                    }
                    views.setViewVisibility(row.row, View.VISIBLE)
                    views.setTextViewText(row.name, item.optString("name"))
                    views.setTextViewText(row.date, item.optString("date"))
                    views.setTextViewText(row.amount, item.optString("amount"))
                }
                val empty = day.optString("message")
                views.setViewVisibility(
                    R.id.widget_rows_empty,
                    if (count == 0 && empty.isNotEmpty()) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.widget_rows_empty, empty)
            }
            return views
        }

        private class Row(val row: Int, val name: Int, val date: Int, val amount: Int)

        private val NUMBER_VIEWS = intArrayOf(
            R.id.widget_number_left,
            R.id.widget_number_negative,
            R.id.widget_number_plain,
        )

        private val ROWS = listOf(
            Row(R.id.widget_row_1, R.id.widget_row_1_name, R.id.widget_row_1_date, R.id.widget_row_1_amount),
            Row(R.id.widget_row_2, R.id.widget_row_2_name, R.id.widget_row_2_date, R.id.widget_row_2_amount),
            Row(R.id.widget_row_3, R.id.widget_row_3_name, R.id.widget_row_3_date, R.id.widget_row_3_amount),
        )

        private fun alarmManager(context: Context): AlarmManager? =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

        private fun midnightIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, KalanWidgetProvider::class.java).setAction(ACTION_MIDNIGHT),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        /**
         * Once just after the next local midnight, to switch to that day's
         * record. Inexact and not waking the phone: delivered when it next
         * wakes, which is when anyone can look at the widget.
         */
        private fun scheduleMidnight(context: Context) {
            val next = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 5)
                set(Calendar.MILLISECOND, 0)
            }
            alarmManager(context)?.set(AlarmManager.RTC, next.timeInMillis, midnightIntent(context))
        }
    }
}
