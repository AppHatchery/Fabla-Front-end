package edu.emory.audio_diaries_flutter.features.timer.presentation

import android.os.Handler
import android.os.Looper
import edu.emory.audio_diaries_flutter.features.timer.domain.TimerNotificationFactory
import edu.emory.audio_diaries_flutter.features.timer.domain.TimerNotifications
import edu.emory.audio_diaries_flutter.features.timer.domain.TimerState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter side of the timer notification: lib/services/timer_live_update_service.dart.
 *
 * Dart pushes whole state on transitions ("show", "hide"). The countdown text is rendered by the
 * platform chronometer off a wall-clock end time, so it stays right while the Dart isolate is
 * throttled; only the progress bar needs ticking, done here for the same reason.
 *
 * Tapping Pause/Resume is sent back as "togglePause"; Dart owns the timer and pushes the result.
 */
class TimerChannel(private val notifications: TimerNotifications) {

    private val handler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null

    private var state: TimerState? = null

    /** Wall-clock instant the countdown hits zero. Null while paused or idle. */
    private var endAtMillis: Long? = null

    private val tick = object : Runnable {
        override fun run() {
            val current = state ?: return
            val end = endAtMillis ?: return
            val remaining = ((end - System.currentTimeMillis()) / MILLIS_PER_SECOND).toInt()
            if (remaining <= 0) {
                hide()
                return
            }
            render(current.copy(remainingSeconds = remaining))
            handler.postDelayed(this, TICK_INTERVAL_MS)
        }
    }

    fun attach(messenger: BinaryMessenger) {
        notifications.setActionListener { methodChannel?.invokeMethod("togglePause", null) }

        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        show(call.toTimerState())
                        result.success(null)
                    }

                    "hide" -> {
                        hide()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    fun detach() {
        hide()
        notifications.setActionListener(null)
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    /** Idempotent: Dart pushes whole state, not deltas. */
    private fun show(newState: TimerState) {
        handler.removeCallbacks(tick)

        if (!newState.isShowable) {
            hide()
            return
        }

        if (newState.isPaused) {
            endAtMillis = null
        } else {
            endAtMillis = System.currentTimeMillis() + newState.remainingSeconds * MILLIS_PER_SECOND
            handler.postDelayed(tick, TICK_INTERVAL_MS)
        }

        render(newState)
    }

    private fun render(current: TimerState) {
        state = current
        notifications.show(TimerNotificationFactory.contentFor(current))
    }

    private fun hide() {
        handler.removeCallbacks(tick)
        endAtMillis = null
        state = null
        notifications.hide()
    }

    private fun MethodCall.toTimerState() = TimerState(
        totalSeconds = argument<Int>("totalSeconds") ?: 0,
        remainingSeconds = argument<Int>("remainingSeconds") ?: 0,
        isPaused = argument<Boolean>("isPaused") ?: false,
        title = argument<String>("title") ?: TimerState.DEFAULT_TITLE,
        questionNumber = argument<Int>("questionNumber"),
        questionCount = argument<Int>("questionCount"),
        playbackControls = argument<Boolean>("playbackControls") ?: false,
    )

    private companion object {
        const val CHANNEL_NAME = "edu.emory.audio_diaries_flutter/timer_live_update"
        const val TICK_INTERVAL_MS = 1_000L
        const val MILLIS_PER_SECOND = 1_000L
    }
}
