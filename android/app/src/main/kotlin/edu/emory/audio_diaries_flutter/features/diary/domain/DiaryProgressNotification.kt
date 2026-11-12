package edu.emory.audio_diaries_flutter.features.diary.domain

import edu.emory.audio_diaries_flutter.core.domain.ProgressBar
import edu.emory.audio_diaries_flutter.core.domain.Segment
import edu.emory.audio_diaries_flutter.core.domain.halfAlpha
import edu.emory.audio_diaries_flutter.core.domain.questionPosition
import edu.emory.audio_diaries_flutter.core.domain.splitSegment

/**
 * A diary left part-way through: the participant is on [questionNumber] (1-based), and
 * [currentAnswered] says whether that question already has its answer saved.
 */
data class DiaryProgressState(
    val questionNumber: Int,
    val questionCount: Int,
    val currentAnswered: Boolean = false,
) {
    /** Whether the position makes sense; anything else is not shown. */
    val isShowable get() = questionCount > 0 && questionNumber in 1..questionCount

    /** The current question is done and another one follows it. */
    val nextQuestionWaiting get() = currentAnswered && questionNumber < questionCount
}

/** The image beside the text. */
enum class DiaryArt { IN_PROGRESS, NEXT_QUESTION }

/**
 * The notification's action. [ANSWER] also moves the diary on to the waiting question, so Dart
 * hears about it; [CONTINUE] only reopens the app.
 */
enum class DiaryAction(val label: String) {
    CONTINUE("Continue"),
    ANSWER("Answer"),
}

/** Everything the diary progress notification shows, independent of how Android draws it. */
data class DiaryProgressContent(
    val title: String,
    val text: String?,
    val art: DiaryArt,
    val progress: ProgressBar,
    val action: DiaryAction,
)

/** Posts and removes the diary progress notification. Implemented by the Android layer. */
interface DiaryProgressNotifications {
    fun show(content: DiaryProgressContent)
    fun hide()

    /** Called when the notification opens the app for [DiaryAction.ANSWER]. */
    fun setAnswerListener(listener: (() -> Unit)?)
}

/**
 * Maps a [DiaryProgressState] to what the notification shows, with one bar per question:
 *
 * - Diary in progress: "Q3 of 8", Q1–Q2 filled, the ghost at Q3, Continue.
 * - Next question waiting (Q3 answered): "Q4 of 8", Q1–Q3 filled, the ghost at Q4, Answer.
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
        val waiting = state.nextQuestionWaiting
        // The question the notification points at, and how many before it are done.
        val shownQuestion = if (waiting) state.questionNumber + 1 else state.questionNumber
        val answered = shownQuestion - 1

        return DiaryProgressContent(
            title = if (waiting) "Next question waiting" else "Diary in progress",
            text = questionPosition(shownQuestion, state.questionCount),
            art = if (waiting) DiaryArt.NEXT_QUESTION else DiaryArt.IN_PROGRESS,
            progress = ProgressBar(
                max = state.questionCount,
                progress = answered,
                segments = segmentsFor(answered, state.questionCount),
            ),
            action = if (waiting) DiaryAction.ANSWER else DiaryAction.CONTINUE,
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
