package edu.emory.audio_diaries_flutter.features.recording.presentation

import android.os.Handler
import android.os.Looper
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingAction
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotificationFactory
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotifications
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingPhase
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter side of the recording notification: lib/services/recording_live_update_service.dart.
 *
 * Dart sends state on phase changes only ("show", "hide"). Elapsed time is ticked here off the
 * wall clock rather than pushed from Dart each second. Notification actions go back to Dart as
 * "pause", "resume", "save" and "recordAgain".
 *
 * [isNightMode] is read on every render, so a theme change shows on the next tick.
 */
class RecordingChannel(
    private val notifications: RecordingNotifications,
    private val isNightMode: () -> Boolean,
) {

    private val handler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null

    private var state: RecordingState? = null

    /** Wall-clock instant the take would have started at, had it never paused. Null unless recording. */
    private var startedAtMillis: Long? = null

    private val tick = object : Runnable {
        override fun run() {
            val current = state ?: return
            val start = startedAtMillis ?: return
            val elapsed = ((System.currentTimeMillis() - start) / MILLIS_PER_SECOND).toInt()
            render(current.copy(elapsedSeconds = elapsed))
            handler.postDelayed(this, TICK_INTERVAL_MS)
        }
    }

    fun attach(messenger: BinaryMessenger) {
        notifications.setActionListener { action ->
            dartMethodFor(action)?.let { methodChannel?.invokeMethod(it, null) }
        }

        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        val newState = call.toRecordingState()
                        if (newState == null) {
                            result.error(
                                "BAD_PHASE",
                                "Unknown phase ${call.argument<String>("phase")}",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        show(newState)
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

    private fun show(newState: RecordingState) {
        handler.removeCallbacks(tick)

        if (newState.phase == RecordingPhase.RECORDING) {
            startedAtMillis = System.currentTimeMillis() - newState.elapsedSeconds * MILLIS_PER_SECOND
            handler.postDelayed(tick, TICK_INTERVAL_MS)
        } else {
            startedAtMillis = null
        }

        render(newState)
    }

    private fun render(current: RecordingState) {
        state = current
        notifications.show(RecordingNotificationFactory.contentFor(current, isNightMode()))
    }

    private fun hide() {
        handler.removeCallbacks(tick)
        startedAtMillis = null
        state = null
        notifications.hide()
    }

    /** Null for [RecordingAction.OPEN], which only opens the app. */
    private fun dartMethodFor(action: RecordingAction) = when (action) {
        RecordingAction.PAUSE -> "pause"
        RecordingAction.RESUME -> "resume"
        RecordingAction.SAVE -> "save"
        RecordingAction.RECORD_AGAIN -> "recordAgain"
        RecordingAction.OPEN -> null
    }

    /** Null when the phase isn't one this build knows. */
    private fun MethodCall.toRecordingState(): RecordingState? {
        val phase = RecordingPhase.fromWireName(argument<String>("phase")) ?: return null
        return RecordingState(
            phase = phase,
            elapsedSeconds = (argument<Int>("elapsedSeconds") ?: 0).coerceAtLeast(0),
            limitSeconds = argument<Int>("limitSeconds") ?: 0,
            title = argument<String>("title") ?: RecordingState.DEFAULT_TITLE,
            questionNumber = argument<Int>("questionNumber"),
            questionCount = argument<Int>("questionCount"),
        )
    }

    private companion object {
        const val CHANNEL_NAME = "edu.emory.audio_diaries_flutter/recording_live_update"
        const val TICK_INTERVAL_MS = 1_000L
        const val MILLIS_PER_SECOND = 1_000L
    }
}
