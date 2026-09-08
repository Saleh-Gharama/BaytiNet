package com.example.baytinet

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.baytinet/usage"
    private val EVENT_CHANNEL = "com.example.baytinet/network_events"
    private var networkEventSink: EventChannel.EventSink? = null
    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                networkEventSink = events
                registerWifiCallback()
                // Emit initial status
                networkEventSink?.success(getCurrentSsid())
            }

            override fun onCancel(arguments: Any?) {
                networkEventSink = null
                unregisterWifiCallback()
            }
        })
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWifiUsage" -> {
                    val startTime = call.argument<Long>("startTime") ?: 0L
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                    // Run in background thread to avoid ANR
                    Thread {
                        val usage = getWifiDataUsage(startTime, endTime)
                        runOnUiThread {
                            result.success(usage)
                        }
                    }.start()
                }
                "getSsid" -> {
                    result.success(getCurrentSsid())
                }
                "hasUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    requestUsageStatsPermission()
                    result.success(null)
                }
                "startForegroundService" -> {
                    val intent = Intent(this, DataUsageService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        if (!hasUsageStatsPermission()) {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            startActivity(intent)
        }
    }

    private fun getCurrentSsid(): String {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            return "إذن الموقع مطلوب"
        }
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val info = wifiManager.connectionInfo
        if (info != null) {
            val ssid = info.ssid
            if (ssid != null && ssid != "<unknown ssid>") {
                return ssid.replace("\"", "")
            }
        }
        return "شبكة غير معروفة"
    }

    private fun getWifiDataUsage(startTime: Long, endTime: Long): Long {
        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        var totalUsage = 0L
        try {
            val networkStats = networkStatsManager.querySummary(
                ConnectivityManager.TYPE_WIFI,
                null,
                startTime,
                endTime
            )
            val bucket = NetworkStats.Bucket()
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

    private fun registerWifiCallback() {
        if (connectivityManager == null) {
            connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        }
        if (networkCallback == null) {
            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    runOnUiThread {
                        networkEventSink?.success(getCurrentSsid())
                    }
                }

                override fun onLost(network: Network) {
                    runOnUiThread {
                        networkEventSink?.success("DISCONNECTED")
                    }
                }

                override fun onCapabilitiesChanged(network: Network, networkCapabilities: NetworkCapabilities) {
                    runOnUiThread {
                        networkEventSink?.success(getCurrentSsid())
                    }
                }
            }
            try {
                val request = NetworkRequest.Builder()
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .build()
                connectivityManager?.registerNetworkCallback(request, networkCallback!!)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun unregisterWifiCallback() {
        try {
            networkCallback?.let {
                connectivityManager?.unregisterNetworkCallback(it)
                networkCallback = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        unregisterWifiCallback()
        super.onDestroy()
    }
}

