package edu.emory.audio_diaries_flutter

import android.content.Intent
import edu.emory.audio_diaries_flutter.core.notification.isNightMode
import edu.emory.audio_diaries_flutter.features.battery.presentation.BatteryChannel
import edu.emory.audio_diaries_flutter.features.diary.data.AndroidDiaryProgressNotifications
import edu.emory.audio_diaries_flutter.features.diary.presentation.DiaryProgressChannel
import edu.emory.audio_diaries_flutter.features.recording.data.AndroidRecordingNotifications
import edu.emory.audio_diaries_flutter.features.recording.presentation.RecordingChannel
import edu.emory.audio_diaries_flutter.features.timer.data.AndroidTimerNotifications
import edu.emory.audio_diaries_flutter.features.timer.presentation.TimerChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Wires each feature's Flutter channel to its Android implementation. The only place that knows
 * every concrete class.
 */
class MainActivity : FlutterFragmentActivity() {

    private var batteryChannel: BatteryChannel? = null

    private var timerNotifications: AndroidTimerNotifications? = null
    private var timerChannel: TimerChannel? = null

    private var recordingNotifications: AndroidRecordingNotifications? = null
    private var recordingChannel: RecordingChannel? = null

    private var diaryProgressNotifications: AndroidDiaryProgressNotifications? = null
    private var diaryProgressChannel: DiaryProgressChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val appContext = applicationContext

        batteryChannel = BatteryChannel(appContext).also { it.attach(messenger) }

        val timer = AndroidTimerNotifications(appContext).also { it.start() }
        timerNotifications = timer
        timerChannel = TimerChannel(timer).also { it.attach(messenger) }

        val recording = AndroidRecordingNotifications(appContext).also { it.start() }
        recordingNotifications = recording
        recordingChannel = RecordingChannel(recording, isNightMode = { appContext.isNightMode() })
            .also { it.attach(messenger) }

        val diaryProgress = AndroidDiaryProgressNotifications(appContext).also { it.start() }
        diaryProgressNotifications = diaryProgress
        diaryProgressChannel = DiaryProgressChannel(diaryProgress).also { it.attach(messenger) }
    }

    /**
     * Notification actions that reopen the app arrive here (singleTop): the recording's Resume and
     * Record again, and the diary's Answer.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (recordingNotifications?.handleLaunchIntent(intent) == true) return
        diaryProgressNotifications?.handleLaunchIntent(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        batteryChannel?.detach()
        timerChannel?.detach()
        timerNotifications?.stop()
        recordingChannel?.detach()
        recordingNotifications?.stop()
        diaryProgressChannel?.detach()
    }
}
