package edu.emory.audio_diaries_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private lateinit var batteryService: BatteryService

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        batteryService = BatteryService(packageName)

        batteryService.setup(this, flutterEngine.dartExecutor.binaryMessenger, this)
    }

    override fun onDestroy() {
        super.onDestroy()
        batteryService.terminate()
    }
}
