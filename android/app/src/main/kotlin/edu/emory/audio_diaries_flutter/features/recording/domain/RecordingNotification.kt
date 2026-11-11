package edu.emory.audio_diaries_flutter.features.recording.domain

import edu.emory.audio_diaries_flutter.core.domain.ProgressBar
import edu.emory.audio_diaries_flutter.core.domain.durationText
import edu.emory.audio_diaries_flutter.core.domain.halfAlpha
import edu.emory.audio_diaries_flutter.core.domain.questionPosition
import edu.emory.audio_diaries_flutter.core.domain.splitSegment

/** Where a take is, as sent from Dart by [wireName] (RecordingLiveUpdatePhase in Dart). */
enum class RecordingPhase(val wireName: String) {
    RECORDING("recording"),
    PAUSED("paused"),
    PAUSED_BY_CALL("pausedByCall"),
    READY_TO_SAVE("readyToSave"),
    COULD_NOT_RESUME("couldNotResume"),
    SAVED("saved"),
    RECORDING_STOPPED("recordingStopped");

    val isPaused get() = this == PAUSED || this == PAUSED_BY_CALL

    /** In progress, so ongoing and promoted. The rest can be swiped away. */
    val isLiveUpdate get() = this == RECORDING || isPaused

    /** Problems worth an alert rather than a silent update. */
    val alerts get() = this == COULD_NOT_RESUME || this == RECORDING_STOPPED

    companion object {
        fun fromWireName(name: String?): RecordingPhase? = entries.firstOrNull { it.wireName == name }
    }
}

/** The take as Dart last described it, with [elapsedSeconds] kept current by the ticker. */
data class RecordingState(
    val phase: RecordingPhase,
    val elapsedSeconds: Int,
    /** The answer's length; 0 means none, and then there is no bar. */
    val limitSeconds: Int = 0,
    val title: String = DEFAULT_TITLE,
    val questionNumber: Int? = null,
    val questionCount: Int? = null,
) {
    companion object {
        const val DEFAULT_TITLE = "Recording"
    }
}

/** The image beside each phase's text. */
enum class RecordingArt { RECORDING, PAUSED, PAUSED_BY_CALL, READY_TO_SAVE, COULD_NOT_RESUME, SAVED, STOPPED }

/** A notification action. Only [OPEN] has no counterpart in Dart: it just opens the app. */
enum class RecordingAction(val label: String) {
    PAUSE("Pause"),
    RESUME("Resume"),
    SAVE("Save"),
    OPEN("Open"),
    RECORD_AGAIN("Record again"),
}

/** Everything the recording notification shows, independent of how Android draws it. */
data class RecordingNotificationContent(
    val title: String,
    val text: String?,
    val art: RecordingArt,
    /** Status chip text; null lets the chip show the running time. */
    val chipText: String?,
    /** Seconds already recorded, for the header chronometer; null when not capturing. */
    val chronometerSeconds: Int?,
    /** Capturing: shares the microphone foreground service's notification. */
    val isCapturing: Boolean,
    val isLiveUpdate: Boolean,
    val alerts: Boolean,
    val progress: ProgressBar?,
    val action: RecordingAction?,
)

/** Posts and removes the recording notification. Implemented by the Android notification layer. */
interface RecordingNotifications {
    fun show(content: RecordingNotificationContent)
    fun hide()

    /** Called when a notification action other than [RecordingAction.OPEN] is tapped. */
    fun setActionListener(listener: ((RecordingAction) -> Unit)?)
}

/**
 * Maps a [RecordingState] to what the notification shows:
 *
 * - Recording: "Q3 of 8 · up to 5:00", a four-part blue bar whose last quarter is orange, Pause.
 * - Paused: "0:48 so far · Q3 of 8", a darker blue bar, chip "Paused", Resume.
 * - Paused by a call: as Paused, with an all-orange bar.
 * - Ready to save: "1:24 recorded · Q3 of 8", Save.
 * - Could not resume: "2:40 kept · Q3 of 8", Open. Alerts.
 * - Saved: "1:24 kept · Q3 of 8", no action.
 * - Recording stopped: "Nothing kept · Q3 of 8", Record again. Alerts.
 */
object RecordingNotificationFactory {

    const val FILLED_COLOR = 0xFF016BEF.toInt()
    const val PAUSED_FILLED_COLOR = 0xFF0147A0.toInt()
    const val LAST_FILLED_COLOR = 0xFFCB6C00.toInt()
    const val LAST_UNFILLED_COLOR = 0x80FEB954.toInt()

    /** The call orange is brighter on the dark notification surface, per the design. */
    const val CALL_COLOR_LIGHT = 0xFFCB6C00.toInt()
    const val CALL_COLOR_DARK = 0xFFFE9600.toInt()

    private const val SEGMENT_COUNT = 4
    private const val PAUSED_TITLE = "Paused"

    fun contentFor(state: RecordingState, isNightMode: Boolean): RecordingNotificationContent {
        val phase = state.phase
        val isRecording = phase == RecordingPhase.RECORDING

        return RecordingNotificationContent(
            title = titleFor(state),
            text = textFor(state),
            art = artFor(phase),
            chipText = if (phase.isPaused) PAUSED_TITLE else null,
            chronometerSeconds = if (isRecording) state.elapsedSeconds else null,
            isCapturing = isRecording,
            isLiveUpdate = phase.isLiveUpdate,
            alerts = phase.alerts,
            // No limit means no bar: there is nothing to fill toward.
            progress = if (phase.isLiveUpdate && state.limitSeconds > 0) {
                progressFor(state, isNightMode)
            } else {
                null
            },
            action = actionFor(phase),
        )
    }

    private fun titleFor(state: RecordingState) = when (state.phase) {
        RecordingPhase.RECORDING -> state.title
        RecordingPhase.PAUSED -> PAUSED_TITLE
        RecordingPhase.PAUSED_BY_CALL -> "Paused by a call"
        RecordingPhase.READY_TO_SAVE -> "Ready to save"
        RecordingPhase.COULD_NOT_RESUME -> "Could not resume"
        RecordingPhase.SAVED -> "Saved"
        RecordingPhase.RECORDING_STOPPED -> "Recording stopped"
    }

    private fun textFor(state: RecordingState): String? {
        val position = questionPosition(state.questionNumber, state.questionCount)
        val elapsed = durationText(state.elapsedSeconds)
        val parts = when (state.phase) {
            RecordingPhase.RECORDING -> listOfNotNull(
                position,
                if (state.limitSeconds > 0) "up to ${durationText(state.limitSeconds)}" else null,
            )
            RecordingPhase.PAUSED, RecordingPhase.PAUSED_BY_CALL ->
                listOfNotNull("$elapsed so far", position)
            RecordingPhase.READY_TO_SAVE -> listOfNotNull("$elapsed recorded", position)
            RecordingPhase.COULD_NOT_RESUME, RecordingPhase.SAVED ->
                listOfNotNull("$elapsed kept", position)
            RecordingPhase.RECORDING_STOPPED -> listOfNotNull("Nothing kept", position)
        }
        return parts.joinToString(" · ").ifEmpty { null }
    }

    private fun artFor(phase: RecordingPhase) = when (phase) {
        RecordingPhase.RECORDING -> RecordingArt.RECORDING
        RecordingPhase.PAUSED -> RecordingArt.PAUSED
        RecordingPhase.PAUSED_BY_CALL -> RecordingArt.PAUSED_BY_CALL
        RecordingPhase.READY_TO_SAVE -> RecordingArt.READY_TO_SAVE
        RecordingPhase.COULD_NOT_RESUME -> RecordingArt.COULD_NOT_RESUME
        RecordingPhase.SAVED -> RecordingArt.SAVED
        RecordingPhase.RECORDING_STOPPED -> RecordingArt.STOPPED
    }

    private fun actionFor(phase: RecordingPhase) = when (phase) {
        RecordingPhase.RECORDING -> RecordingAction.PAUSE
        RecordingPhase.PAUSED, RecordingPhase.PAUSED_BY_CALL -> RecordingAction.RESUME
        RecordingPhase.READY_TO_SAVE -> RecordingAction.SAVE
        RecordingPhase.COULD_NOT_RESUME -> RecordingAction.OPEN
        RecordingPhase.SAVED -> null
        RecordingPhase.RECORDING_STOPPED -> RecordingAction.RECORD_AGAIN
    }

    /**
     * Four equal parts. The last is the orange "almost out of time" stretch, except when paused by
     * a call, where the whole bar is orange.
     */
    private fun progressFor(state: RecordingState, isNightMode: Boolean): ProgressBar {
        val limit = state.limitSeconds
        val progress = state.elapsedSeconds.coerceIn(0, limit)
        val byCall = state.phase == RecordingPhase.PAUSED_BY_CALL

        val (filled, last) = when {
            byCall -> (if (isNightMode) CALL_COLOR_DARK else CALL_COLOR_LIGHT).let { it to it }
            state.phase == RecordingPhase.PAUSED -> PAUSED_FILLED_COLOR to LAST_FILLED_COLOR
            else -> FILLED_COLOR to LAST_FILLED_COLOR
        }

        val segments = (0 until SEGMENT_COUNT).flatMap { index ->
            val isLast = index == SEGMENT_COUNT - 1
            val filledColor = if (isLast) last else filled
            splitSegment(
                start = limit * index / SEGMENT_COUNT,
                end = limit * (index + 1) / SEGMENT_COUNT,
                progress = progress,
                filledColor = filledColor,
                unfilledColor = if (isLast && !byCall) LAST_UNFILLED_COLOR else halfAlpha(filledColor),
            )
        }

        return ProgressBar(max = limit, progress = progress, segments = segments)
    }
}
