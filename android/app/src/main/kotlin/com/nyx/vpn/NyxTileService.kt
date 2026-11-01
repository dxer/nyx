package com.nyx.vpn

import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class NyxTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    override fun onClick() {
        super.onClick()
        val tile = qsTile ?: return

        if (NyxVpnService.isRunning) {
            val stopIntent = Intent(this, NyxVpnService::class.java).apply {
                action = NyxVpnService.ACTION_STOP
            }
            startService(stopIntent)
            tile.state = Tile.STATE_INACTIVE
            tile.label = "Nyx (Off)"
            tile.updateTile()
        } else {
            // Bring up main app to connect
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            if (launchIntent != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startActivityAndCollapse(launchIntent)
                } else {
                    @Suppress("DEPRECATION")
                    startActivityAndCollapse(launchIntent)
                }
            }
        }
    }

    private fun updateTileState() {
        val tile = qsTile ?: return
        val active = NyxVpnService.isRunning
        tile.state = if (active) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = if (active) "Nyx (Active)" else "Nyx VPN"
        tile.updateTile()
    }
}
