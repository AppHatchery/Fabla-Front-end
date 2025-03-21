package edu.emory.audio_diaries_flutter

import android.app.Activity
import android.content.Context
import android.os.PowerManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * This class is used to interact with the battery optimization settings on the device
 * It provides methods to check if the app is ignoring battery optimizations and to request the user to ignore battery optimizations
 */
class BatteryService(private val packageName: String) {
    private var methodChannel: MethodChannel? = null
    private lateinit var powerManager: PowerManager

    /**
     * This method is called when the activity is created
     * It sets up the method channel and the power manager
     * It also sets the method call handler for the method channel
     * The method call handler is a lambda that is called when a method is called from the flutter side
     * It then checks the method name and calls the appropriate method
     */
    fun setup(context: Context, messenger: BinaryMessenger, activity: Activity) {

        powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager

        methodChannel = MethodChannel(messenger, BATTERY_METHOD_CHANNEL_NAME)
        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "isBatteryOptimizationDisabled" -> {
                    result.success(powerManager.isIgnoringBatteryOptimizations(context.packageName))
                }
                else -> {
                    result.notImplemented()
                }
            }

        }
    }

    /**
     * This method is called when the activity is destroyed
     * It sets the method call handler to null
     */
    fun terminate(){
        methodChannel!!.setMethodCallHandler(null)
    }
}