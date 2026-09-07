package edu.emory.audio_diaries_flutter

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

    private lateinit var batteryService: BatteryService
    private lateinit var timerLiveUpdate: TimerLiveUpdate

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        batteryService = BatteryService(packageName)
        batteryService.setup(this, messenger, this)

        timerLiveUpdate = TimerLiveUpdate(applicationContext)
        timerLiveUpdate.setup(messenger)
    }

    override fun onDestroy() {
        super.onDestroy()
        batteryService.terminate()
        timerLiveUpdate.terminate()
    }
}
