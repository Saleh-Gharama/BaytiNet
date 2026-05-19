package com.example.baytinet

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.net.ConnectivityManager
import android.widget.RemoteViews
import java.util.Calendar
import java.util.Locale

class UsageWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_FILTER) {
            val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            val filter = intent.getStringExtra(EXTRA_FILTER) ?: "week"
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putString(KEY_FILTER_PREFIX + appWidgetId, filter).apply()

                val appWidgetManager = AppWidgetManager.getInstance(context)
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    companion object {
        const val ACTION_FILTER = "com.example.baytinet.action.FILTER"
        const val EXTRA_FILTER = "com.example.baytinet.extra.FILTER"
        private const val PREFS_NAME = "widget_prefs"
        private const val KEY_FILTER_PREFIX = "filter_"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val filter = prefs.getString(KEY_FILTER_PREFIX + appWidgetId, "week") ?: "week"

            val views = RemoteViews(context.packageName, R.layout.widget_usage)

            // 1. Setup Click Listeners for Tabs
            setTabClickIntent(context, appWidgetId, "day", R.id.tab_day, views)
            setTabClickIntent(context, appWidgetId, "week", R.id.tab_week, views)
            setTabClickIntent(context, appWidgetId, "month", R.id.tab_month, views)

            // 2. Set Tab Highlights (Selected vs Unselected)
            resetTabStyles(views)
            when (filter) {
                "day" -> {
                    views.setInt(R.id.tab_day, "setBackgroundResource", R.drawable.tab_selected_bg)
                    views.setTextColor(R.id.tab_day, Color.WHITE)
                    views.setTextViewText(R.id.usage_period, "اليوم")
                    views.setTextViewText(R.id.usage_label, "استهلاك اليوم")
                }
                "week" -> {
                    views.setInt(R.id.tab_week, "setBackgroundResource", R.drawable.tab_selected_bg)
                    views.setTextColor(R.id.tab_week, Color.WHITE)
                    views.setTextViewText(R.id.usage_period, "خلال 7 أيام الماضية")
                    views.setTextViewText(R.id.usage_label, "إجمالي الاستهلاك")
                }
                "month" -> {
                    views.setInt(R.id.tab_month, "setBackgroundResource", R.drawable.tab_selected_bg)
                    views.setTextColor(R.id.tab_month, Color.WHITE)
                    views.setTextViewText(R.id.usage_period, "خلال هذا الشهر")
                    views.setTextViewText(R.id.usage_label, "إجمالي الاستهلاك")
                }
            }

            // 3. Fetch Data & Build Chart
            val (totalUsage, points, labels) = fetchDataForFilter(context, filter)
            views.setTextViewText(R.id.usage_value, formatBytes(totalUsage))

            val chartBitmap = generateChartBitmap(points, labels)
            views.setImageViewBitmap(R.id.chart_image, chartBitmap)

            // 4. Launcher Intent (Launch app when clicking logo or usage values)
            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.header_app_name, pendingIntent)
            views.setOnClickPendingIntent(R.id.usage_details, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun setTabClickIntent(context: Context, appWidgetId: Int, filterValue: String, viewId: Int, views: RemoteViews) {
            val intent = Intent(context, UsageWidgetProvider::class.java).apply {
                action = ACTION_FILTER
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra(EXTRA_FILTER, filterValue)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId * 10 + filterValue.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(viewId, pendingIntent)
        }

        private fun resetTabStyles(views: RemoteViews) {
            views.setInt(R.id.tab_day, "setBackgroundResource", 0)
            views.setTextColor(R.id.tab_day, Color.BLACK)
            views.setInt(R.id.tab_week, "setBackgroundResource", 0)
            views.setTextColor(R.id.tab_week, Color.BLACK)
            views.setInt(R.id.tab_month, "setBackgroundResource", 0)
            views.setTextColor(R.id.tab_month, Color.BLACK)
        }

        private fun fetchDataForFilter(context: Context, filter: String): Triple<Long, FloatArray, Array<String>> {
            val now = System.currentTimeMillis()
            val calendar = Calendar.getInstance()
            
            return when (filter) {
                "day" -> {
                    // 6 points representing 4-hour blocks of today
                    val points = FloatArray(6)
                    val labels = arrayOf("12ص", "4ص", "8ص", "12م", "4م", "8م")
                    var grandTotal = 0L

                    calendar.set(Calendar.HOUR_OF_DAY, 0)
                    calendar.set(Calendar.MINUTE, 0)
                    calendar.set(Calendar.SECOND, 0)
                    calendar.set(Calendar.MILLISECOND, 0)
                    val dayStart = calendar.timeInMillis

                    val segmentMs = 4 * 60 * 60 * 1000L
                    for (i in 0..5) {
                        val start = dayStart + i * segmentMs
                        val end = minOf(start + segmentMs, now)
                        val usage = if (start <= now) getUsageForPeriod(context, start, end) else 0L
                        points[i] = usage.toFloat() / (1024 * 1024) // MB
                        grandTotal += usage
                    }
                    Triple(grandTotal, points, labels)
                }
                "week" -> {
                    // Last 7 days
                    val points = FloatArray(7)
                    val arabicDays = arrayOf("أحد", "اثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت")
                    val labels = Array(7) { "" }
                    var grandTotal = 0L

                    // Fill labels and get day bounds
                    for (i in 0..6) {
                        calendar.timeInMillis = now
                        calendar.add(Calendar.DAY_OF_YEAR, - (6 - i))
                        
                        // Set start of that day
                        calendar.set(Calendar.HOUR_OF_DAY, 0)
                        calendar.set(Calendar.MINUTE, 0)
                        calendar.set(Calendar.SECOND, 0)
                        calendar.set(Calendar.MILLISECOND, 0)
                        val start = calendar.timeInMillis
                        
                        // Set end of that day
                        calendar.set(Calendar.HOUR_OF_DAY, 23)
                        calendar.set(Calendar.MINUTE, 59)
                        calendar.set(Calendar.SECOND, 59)
                        calendar.set(Calendar.MILLISECOND, 999)
                        val end = minOf(calendar.timeInMillis, now)

                        val usage = getUsageForPeriod(context, start, end)
                        points[i] = usage.toFloat() / (1024 * 1024) // MB
                        grandTotal += usage
                        
                        val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
                        // DAY_OF_WEEK SUNDAY is 1, SATURDAY is 7. Map to arabicDays
                        labels[i] = arabicDays[dayOfWeek - 1]
                    }
                    Triple(grandTotal, points, labels)
                }
                "month" -> {
                    // Last 30 days chunked into 6 segments of 5 days
                    val points = FloatArray(6)
                    val labels = Array(6) { "" }
                    var grandTotal = 0L

                    for (i in 0..5) {
                        calendar.timeInMillis = now
                        calendar.add(Calendar.DAY_OF_YEAR, - (25 - i * 5))
                        
                        val startDay = calendar.get(Calendar.DAY_OF_MONTH)
                        val month = calendar.get(Calendar.MONTH) + 1
                        labels[i] = "$startDay/$month"

                        calendar.set(Calendar.HOUR_OF_DAY, 0)
                        calendar.set(Calendar.MINUTE, 0)
                        calendar.set(Calendar.SECOND, 0)
                        val start = calendar.timeInMillis

                        calendar.add(Calendar.DAY_OF_YEAR, 5)
                        val end = minOf(calendar.timeInMillis, now)

                        val usage = getUsageForPeriod(context, start, end)
                        points[i] = usage.toFloat() / (1024 * 1024) // MB
                        grandTotal += usage
                    }
                    Triple(grandTotal, points, labels)
                }
                else -> Triple(0L, FloatArray(7), emptyArray())
            }
        }

        private fun getUsageForPeriod(context: Context, startTime: Long, endTime: Long): Long {
            val networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as android.app.usage.NetworkStatsManager
            var totalUsage = 0L
            try {
                val networkStats = networkStatsManager.querySummary(
                    ConnectivityManager.TYPE_WIFI,
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
            return totalUsage
        }

        private fun generateChartBitmap(points: FloatArray, labels: Array<String>): Bitmap {
            val width = 450
            val height = 220
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            if (points.isEmpty()) return bitmap

            // Find Min/Max for scaling
            var maxVal = points.maxOrNull() ?: 1f
            if (maxVal == 0f) maxVal = 1f
            val minVal = 0f

            val paddingLeft = 30f
            val paddingRight = 30f
            val paddingTop = 40f
            val paddingBottom = 40f

            val chartWidth = width - paddingLeft - paddingRight
            val chartHeight = height - paddingTop - paddingBottom

            val numPoints = points.size
            val xCoords = FloatArray(numPoints)
            val yCoords = FloatArray(numPoints)

            for (i in 0 until numPoints) {
                xCoords[i] = paddingLeft + i * (chartWidth / (numPoints - 1))
                val ratio = (points[i] - minVal) / (maxVal - minVal)
                yCoords[i] = paddingTop + chartHeight - (ratio * chartHeight)
            }

            // Draw Curve Path
            val path = Path()
            path.moveTo(xCoords[0], yCoords[0])
            for (i in 0 until numPoints - 1) {
                val x1 = xCoords[i]
                val y1 = yCoords[i]
                val x2 = xCoords[i + 1]
                val y2 = yCoords[i + 1]
                val cx1 = x1 + (x2 - x1) / 2
                val cy1 = y1
                val cx2 = x1 + (x2 - x1) / 2
                val cy2 = y2
                path.cubicTo(cx1, cy1, cx2, cy2, x2, y2)
            }

            // Fill Path (Gradient below curve)
            val fillPath = Path(path)
            fillPath.lineTo(xCoords[numPoints - 1], paddingTop + chartHeight)
            fillPath.lineTo(xCoords[0], paddingTop + chartHeight)
            fillPath.close()

            val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                shader = LinearGradient(
                    0f, paddingTop, 0f, paddingTop + chartHeight,
                    Color.parseColor("#4C5600"), Color.TRANSPARENT,
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawPath(fillPath, fillPaint)

            // Draw Stroke (Beautiful dark forest green)
            val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 6f
                color = Color.parseColor("#1B3300")
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            }
            canvas.drawPath(path, strokePaint)

            // Find Peak Index & Draw Highlight Ring
            var maxIndex = 0
            for (i in points.indices) {
                if (points[i] > points[maxIndex]) {
                    maxIndex = i
                }
            }
            val peakX = xCoords[maxIndex]
            val peakY = yCoords[maxIndex]

            // Outer ring
            val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 3f
                color = Color.parseColor("#1B3300")
            }
            canvas.drawCircle(peakX, peakY, 14f, ringPaint)

            // Inner solid dot
            val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                color = Color.parseColor("#1B3300")
            }
            canvas.drawCircle(peakX, peakY, 6f, dotPaint)

            // Draw labels
            val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#444444")
                textSize = 20f
                typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }

            for (i in labels.indices) {
                canvas.drawText(labels[i], xCoords[i], height - 10f, textPaint)
            }

            return bitmap
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
            return String.format(Locale.US, "%.2f %s", bytes / Math.pow(1024.0, exp.toDouble()), suffix)
        }
    }
}
