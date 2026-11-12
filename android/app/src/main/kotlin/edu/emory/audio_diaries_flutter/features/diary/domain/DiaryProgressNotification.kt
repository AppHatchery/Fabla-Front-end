package edu.emory.audio_diaries_flutter.features.diary.domain

import edu.emory.audio_diaries_flutter.core.domain.ProgressBar
import edu.emory.audio_diaries_flutter.core.domain.Segment
import edu.emory.audio_diaries_flutter.core.domain.halfAlpha
import edu.emory.audio_diaries_flutter.core.domain.questionPosition
import edu.emory.audio_diaries_flutter.core.domain.splitSegment

/** A diary left part-way through: the participant is on [questionNumber] (1-based). */
data class DiaryProgressState(val questionNumber: Int, val questionCount: Int) {
    /** Whether the position makes sense; anything else is not shown. */
    val isShowable get() = questionCount > 0 && questionNumber in 1..questionCount
}

/** Everything the diary progress notification shows, independent of how Android draws it. */
data class DiaryProgressContent(
    val title: String,
    val text: String?,
    val progress: ProgressBar,
    val actionLabel: String,
)

/** Posts and removes the diary progress notification. Implemented by the Android layer. */
interface DiaryProgressNotifications {
    fun show(content: DiaryProgressContent)
    fun hide()
}

/**
 * "Diary in progress", "Q3 of 8", and a bar with one part per question: the questions before the
 * current one are filled, and the ghost sits at the current one. Continue reopens the diary.
 */
object DiaryProgressFactory {

    const val FILLED_COLOR = 0xFFA449FF.toInt()
    val UNFILLED_COLOR = halfAlpha(FILLED_COLOR)

    /**
     * Android's ProgressStyle draws at most this many segments (MAX_PROGRESS_SEGMENT_LIMIT); past
     * it, everything is merged into one bar in a default color. Longer diaries get a single
     * filled/unfilled bar instead, which keeps the colors and the ghost's position.
     */
    const val MAX_SEGMENTS = 10

    fun contentFor(state: DiaryProgressState): DiaryProgressContent {
        val answered = state.questionNumber - 1

        return DiaryProgressContent(
            title = "Diary in progress",
            text = questionPosition(state.questionNumber, state.questionCount),
            progress = ProgressBar(
                max = state.questionCount,
                progress = answered,
                segments = segmentsFor(answered, state.questionCount),
            ),
            actionLabel = "Continue",
        )
    }

    /** O(n) in the question count, which is capped at [MAX_SEGMENTS] for the per-question bar. */
    private fun segmentsFor(answered: Int, count: Int): List<Segment> =
        if (count <= MAX_SEGMENTS) {
            List(count) { index -> Segment(1, if (index < answered) FILLED_COLOR else UNFILLED_COLOR) }
        } else {
            splitSegment(0, count, answered, FILLED_COLOR, UNFILLED_COLOR)
        }
}
