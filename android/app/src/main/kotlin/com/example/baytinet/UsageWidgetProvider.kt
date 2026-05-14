package com.example.baytinet

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class UsageWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update immediately on addition
        for (appWidgetId in appWidgetIds) {
            val usage = getQuickDailyUsage(context)
            updateAppWidget(context, appWidgetManager, appWidgetId, usage)
        }
    }

    private fun getQuickDailyUsage(context: Context): String {
        val networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as android.app.usage.NetworkStatsManager
        val calendar = java.util.Calendar.getInstance()
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        var totalUsage = 0L
        try {
            val networkStats = networkStatsManager.querySummary(
                android.net.ConnectivityManager.TYPE_WIFI,
                null,
                startTime,
                endTime
            )
            val bucket = android.app.usage.NetworkStats.Bucket()
            while (networkStats.hasNextBucket()) {
                networkStats.getNextBucket(bucket)
                totalUsage += bucket.rxBytes + bucket.txBytes
            }
            networkStats.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        // Use the same formatting logic as DataUsageService
        return formatBytes(totalUsage)
    }

    private fun formatBytes(bytes: Long): String {
        if (bytes < 1024) return "$bytes ب"
        val exp = (Math.log(bytes.toDouble()) / Math.log(1024.0)).toInt()
        val pre = "KMGTPE"[exp - 1]
        val suffix = when (pre) {
            'K' -> "ك.ب"
            'M' -> "م.ب"
            'G' -> "ج.ب"
            'T' -> "ت.ب"
            else -> "$pre.ب"
        }
        return String.format(java.util.Locale.US, "%.1f %s", bytes / Math.pow(1024.0, exp.toDouble()), suffix)
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            usageText: String
        ) {
            // Construct the RemoteViews object
            val views = RemoteViews(context.packageName, R.layout.widget_usage)
            views.setTextViewText(R.id.usage_value, usageText)

            // Intent to launch the app when clicked
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.icon_container, pendingIntent)
            views.setOnClickPendingIntent(R.id.app_name, pendingIntent)
            views.setOnClickPendingIntent(R.id.usage_value, pendingIntent)

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
