package edu.emory.audio_diaries_flutter.features.battery.presentation

import android.content.Context
import android.os.PowerManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Answers whether battery optimization is off for the app ("isBatteryOptimizationDisabled").
 *
 * One read of a system service, so it has no domain or data layer of its own.
 */
class BatteryChannel(private val context: Context) {

    private var methodChannel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager

        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBatteryOptimizationDisabled" ->
                        result.success(powerManager.isIgnoringBatteryOptimizations(context.packageName))

                    else -> result.notImplemented()
                }
            }
        }
    }

    fun detach() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    private companion object {
        const val CHANNEL_NAME = "edu.emory.audio_diaries_flutter/battery"
    }
}
