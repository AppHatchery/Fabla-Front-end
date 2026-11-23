package edu.emory.audio_diaries_flutter.features.timer.domain

import edu.emory.audio_diaries_flutter.core.domain.ProgressBar
import edu.emory.audio_diaries_flutter.core.domain.questionPosition
import edu.emory.audio_diaries_flutter.core.domain.clockText
import edu.emory.audio_diaries_flutter.core.domain.splitSegment

/** The timer as Dart last described it, with [remainingSeconds] kept current by the ticker. */
data class TimerState(
    val totalSeconds: Int,
    val remainingSeconds: Int,
    val isPaused: Boolean,
    val title: String = DEFAULT_TITLE,
    val questionNumber: Int? = null,
    val questionCount: Int? = null,
    val playbackControls: Boolean = false,
) {
    /** Whether there is a countdown worth showing. */
    val isShowable get() = totalSeconds > 0 && remainingSeconds > 0

    companion object {
        const val DEFAULT_TITLE = "Meditation timer"
    }
}

/** The notification's one action, which pauses or resumes depending on the state. */
enum class TimerAction(val label: String) {
    PAUSE("Pause"),
    RESUME("Resume"),
}

/** Everything the timer notification shows, independent of how Android draws it. */
data class TimerNotificationContent(
    val title: String,
    val text: String?,
    /** Header text standing in for the chronometer while paused, e.g. "04:12". */
    val subText: String?,
    /** Status chip text; null lets the chip show the countdown. */
    val chipText: String?,
    /** Seconds until the header chronometer hits zero; null while paused. */
    val countdownSeconds: Int?,
    val progress: ProgressBar,
    /** Null for a timer without playback controls: it can't be paused in-app either. */
    val action: TimerAction?,
)

/** Posts and removes the timer notification. Implemented by the Android notification layer. */
interface TimerNotifications {
    fun show(content: TimerNotificationContent)
    fun hide()

    /** Called when the notification's [TimerAction] is tapped. */
    fun setActionListener(listener: (() -> Unit)?)
}

/** Maps a [TimerState] to what the notification shows. */
object TimerNotificationFactory {

    /** Elapsed part of the progress bar. */
    const val ELAPSED_COLOR = 0xFF626AD9.toInt()

    /** Remaining part: the accent at 50% alpha (#626AD980). */
    const val REMAINING_COLOR = 0x80626AD9.toInt()

    const val PAUSED_TEXT = "Paused"

    fun contentFor(state: TimerState): TimerNotificationContent {
        val elapsed = (state.totalSeconds - state.remainingSeconds).coerceIn(0, state.totalSeconds)
        val position = questionPosition(state.questionNumber, state.questionCount)

        return TimerNotificationContent(
            title = state.title,
            text = when {
                !state.isPaused -> position
                position == null -> PAUSED_TEXT
                else -> "$position • $PAUSED_TEXT"
            },
            subText = if (state.isPaused) clockText(state.remainingSeconds) else null,
            chipText = if (state.isPaused) PAUSED_TEXT else null,
            countdownSeconds = if (state.isPaused) null else state.remainingSeconds,
            progress = ProgressBar(
                max = state.totalSeconds,
                progress = elapsed,
                segments = splitSegment(
                    start = 0,
                    end = state.totalSeconds,
                    progress = elapsed,
                    filledColor = ELAPSED_COLOR,
                    unfilledColor = REMAINING_COLOR,
                ),
            ),
            action = when {
                !state.playbackControls -> null
                state.isPaused -> TimerAction.RESUME
                else -> TimerAction.PAUSE
            },
        )
    }
}
