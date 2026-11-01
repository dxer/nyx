package com.nyx.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import org.json.JSONObject

class NyxVpnService : VpnService() {
    companion object {
        const val TAG = "NyxVpnService"
        const val ACTION_START = "com.nyx.vpn.START"
        const val ACTION_STOP = "com.nyx.vpn.STOP"
        const val EXTRA_CONFIG = "extra_config_json"
        const val NOTIFICATION_CHANNEL_ID = "nyx_vpn_channel"
        const val NOTIFICATION_ID = 2080

        @Volatile
        var isRunning = false
    }

    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val configJson = intent.getStringExtra(EXTRA_CONFIG) ?: ""
                startVpn(configJson)
            }
            ACTION_STOP -> {
                stopVpn()
            }
        }
        return START_NOT_STICKY
    }

    private fun startVpn(configJson: String) {
        try {
            startForeground(NOTIFICATION_ID, buildNotification("Nyx Active", "Secured via sing-box"))

            val builder = Builder()
                .setSession("Nyx")
                .setMtu(1500)
                .addAddress("172.19.0.1", 30)
                .addDnsServer("1.1.1.1")
                .addRoute("0.0.0.0", 0)

            // Apply Per-App routing on Android VpnService layer if present in JSON
            applyPerAppVpn(builder, configJson)

            vpnInterface = builder.establish()
            isRunning = true

            val fd = vpnInterface?.fd ?: return
            Log.i(TAG, "VPN TUN interface established fd=$fd")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to establish VPN", e)
            stopVpn()
        }
    }

    private fun applyPerAppVpn(builder: Builder, configJson: String) {
        if (configJson.isBlank()) return
        try {
            val root = JSONObject(configJson)
            val route = root.optJSONObject("route") ?: return
            val rules = route.optJSONArray("rules") ?: return

            for (i in 0 until rules.length()) {
                val rule = rules.optJSONObject(i) ?: continue
                val packages = rule.optJSONArray("package_name") ?: continue
                val outbound = rule.optString("outbound")

                for (j in 0 until packages.length()) {
                    val pkg = packages.optString(j)
                    if (pkg.isBlank()) continue
                    try {
                        if (outbound == "direct") {
                            // Blocklist bypass
                            builder.addDisallowedApplication(pkg)
                        } else {
                            // Allowlist proxy
                            builder.addAllowedApplication(pkg)
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Unable to assign app package $pkg to VPN", e)
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to parse per-app routing rules from config", e)
        }
    }

    private fun stopVpn() {
        try {
            isRunning = false
            vpnInterface?.close()
            vpnInterface = null
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            Log.i(TAG, "VPN service stopped cleanly")
        } catch (e: Exception) {
            Log.e(TAG, "Error during VPN stop", e)
        }
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Nyx Tunnel",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows real-time status of the active VPN connection"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(title: String, content: String): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        return builder
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()
    }
}
