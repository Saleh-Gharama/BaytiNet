package com.example.baytinet

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.graphics.*
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.net.ConnectivityManager
import java.util.*

class DataUsageWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val usage = getDailyUsage(context)
            val usageStr = formatBytes(usage)

            val views = RemoteViews(context.packageName, R.layout.data_usage_widget_layout)
            views.setTextViewText(R.id.widget_usage_text, usageStr)

            // Generate mini chart
            val chartBitmap = drawMiniChart(context)
            views.setImageViewBitmap(R.id.widget_chart, chartBitmap)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getDailyUsage(context: Context): Long {
            val networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            var totalUsage = 0L
            try {
                val networkStats = networkStatsManager.querySummary(ConnectivityManager.TYPE_WIFI, null, startTime, endTime)
                val bucket = NetworkStats.Bucket()
                while (networkStats.hasNextBucket()) {
                    networkStats.getNextBucket(bucket)
                    totalUsage += bucket.rxBytes + bucket.txBytes
                }
                networkStats.close()
            } catch (e: Exception) {}
            return totalUsage
        }

        private fun drawMiniChart(context: Context): Bitmap {
            val width = 200
            val height = 100
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val paint = Paint()

            paint.color = Color.parseColor("#2196F3")
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 5f
            paint.isAntiAlias = true

            val path = Path()
            path.moveTo(0f, height.toFloat())

            // Mocking some points for the widget chart based on real daily distribution if possible
            // For now, let's draw a nice wave-like line
            val points = 10
            val step = width / (points - 1)
            val random = Random()
            for (i in 1 until points) {
                val x = (i * step).toFloat()
                val y = (height - random.nextInt(height / 2) - 20).toFloat()
                path.lineTo(x, y)
            }

            canvas.drawPath(path, paint)

            // Fill below
            paint.style = Paint.Style.FILL
            paint.alpha = 40
            path.lineTo(width.toFloat(), height.toFloat())
            path.lineTo(0f, height.toFloat())
            canvas.drawPath(path, paint)

            return bitmap
        }

        private fun formatBytes(bytes: Long): String {
            if (bytes < 1024) return "$bytes B"
            val exp = (Math.log(bytes.toDouble()) / Math.log(1024.0)).toInt()
            val pre = "KMGTPE"[exp - 1]
            return String.format("%.2f %sB", bytes / Math.pow(1024.0, exp.toDouble()), pre)
        }
    }
}
