package com.mangagame.manga_platformer

import android.os.Build
import android.os.Bundle
import android.view.Display
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    private fun enableHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val currentDisplay = display ?: return
            val supportedModes = currentDisplay.supportedModes
            var maxRate = 60f
            var targetMode: Display.Mode? = null
            for (mode in supportedModes) {
                if (mode.refreshRate > maxRate) {
                    maxRate = mode.refreshRate
                    targetMode = mode
                }
            }
            if (targetMode != null) {
                val layoutParams = window.attributes
                layoutParams.preferredDisplayModeId = targetMode.modeId
                window.attributes = layoutParams
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val windowManager = windowManager
            @Suppress("DEPRECATION")
            val defaultDisplay = windowManager.defaultDisplay ?: return
            @Suppress("DEPRECATION")
            val modes = defaultDisplay.supportedModes
            var maxRate = 60f
            var targetModeId = 0
            for (m in modes) {
                if (m.refreshRate > maxRate) {
                    maxRate = m.refreshRate
                    targetModeId = m.modeId
                }
            }
            if (targetModeId != 0) {
                val layoutParams = window.attributes
                layoutParams.preferredDisplayModeId = targetModeId
                window.attributes = layoutParams
            }
        }
    }
}
