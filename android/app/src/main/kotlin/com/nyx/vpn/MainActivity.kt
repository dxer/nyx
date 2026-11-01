package com.nyx.vpn

import android.app.Activity
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nyx.vpn/service"
    private var pendingConfigJson: String? = null
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        const val VPN_REQUEST_CODE = 0x2080
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val config = call.argument<String>("config") ?: ""
                    startVpnServiceWithPermission(config, result)
                }
                "stop" -> {
                    val intent = Intent(this, NyxVpnService::class.java).apply {
                        action = NyxVpnService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                "getInstalledApps" -> {
                    val apps = getInstalledAppsList()
                    result.success(apps)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledAppsList(): List<Map<String, Any>> {
        val pm = packageManager
        val installed = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val appList = mutableListOf<Map<String, Any>>()

        for (app in installed) {
            if (app.packageName == packageName) continue
            val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val name = try {
                pm.getApplicationLabel(app).toString()
            } catch (_: Exception) {
                app.packageName
            }
            appList.add(mapOf(
                "packageName" to app.packageName,
                "appName" to name,
                "isSystemApp" to isSystem
            ))
        }
        return appList.sortedBy { (it["appName"] as String).lowercase() }
    }

    private fun startVpnServiceWithPermission(configJson: String, result: MethodChannel.Result) {
        val vpnIntent = VpnService.prepare(this)
        if (vpnIntent != null) {
            pendingConfigJson = configJson
            pendingResult = result
            startActivityForResult(vpnIntent, VPN_REQUEST_CODE)
        } else {
            launchVpnService(configJson)
            result.success(true)
        }
    }

    private fun launchVpnService(configJson: String) {
        val intent = Intent(this, NyxVpnService::class.java).apply {
            action = NyxVpnService.ACTION_START
            putExtra(NyxVpnService.EXTRA_CONFIG, configJson)
        }
        startService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                pendingConfigJson?.let { launchVpnService(it) }
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingConfigJson = null
            pendingResult = null
        }
    }
}
