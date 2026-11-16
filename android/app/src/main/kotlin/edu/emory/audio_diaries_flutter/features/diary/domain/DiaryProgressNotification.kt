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

    /** The question the notification points at: the waiting one, or the current one. */
    val shownQuestion get() = if (nextQuestionWaiting) questionNumber + 1 else questionNumber
}

/**
 * A started, unfinished diary that closes at [closesAtMillis] (wall clock). "Diary closes soon"
 * fires [DiaryProgressFactory.CLOSING_WINDOW_MILLIS] before then.
 */
data class DiaryClosingReminder(
    val diaryId: Int,
    val closesAtMillis: Long,
    val progress: DiaryProgressState,
) {
    val remindAtMillis get() = closesAtMillis - DiaryProgressFactory.CLOSING_WINDOW_MILLIS

    /** Inside the last stretch before closing, when "Diary closes soon" is the one to show. */
    fun isClosingSoon(nowMillis: Long) = nowMillis in remindAtMillis until closesAtMillis
}

/** The image beside the text. */
enum class DiaryArt { IN_PROGRESS, NEXT_QUESTION, CLOSES_SOON }

/**
 * The notification's action. One that [advances] also moves the diary on to the waiting
 * question, so Dart hears about it; the others only reopen the app.
 */
enum class DiaryAction(val label: String, val advances: Boolean) {
    CONTINUE("Continue", advances = false),
    ANSWER("Answer", advances = true),
    CONTINUE_TO_NEXT("Continue", advances = true),
}

/** Everything the diary notification shows, independent of how Android draws it. */
data class DiaryProgressContent(
    val title: String,
    val text: String?,
    val art: DiaryArt,
    val progress: ProgressBar,
    val action: DiaryAction,
    /** Wall-clock close time for a countdown in the header and status chip; null for none. */
    val countdownToMillis: Long? = null,
) {
    /** A countdown is time-sensitive and ongoing, so it's promoted to a Live Update. */
    val isLiveUpdate get() = countdownToMillis != null
}

/** Posts and removes the diary notification. Implemented by the Android layer. */
interface DiaryProgressNotifications {
    fun show(content: DiaryProgressContent)
    fun hide()

    /** Called when the notification opens the app with an action that [DiaryAction.advances]. */
    fun setAnswerListener(listener: (() -> Unit)?)
}

/** Arms and disarms the "Diary closes soon" alarm per diary. Implemented by the Android layer. */
interface DiaryClosingReminders {
    /** Arms (or re-arms with fresh progress) [reminder]'s alarm. A past time arms nothing. */
    fun schedule(reminder: DiaryClosingReminder)

    fun cancel(diaryId: Int)
}

/**
 * Maps a diary's state to what the notification shows, with one bar per question:
 *
 * - Diary in progress: "Q3 of 8", Q1–Q2 filled, the ghost at Q3, Continue.
 * - Next question waiting (Q3 answered): "Q4 of 8", Q1–Q3 filled, the ghost at Q4, Answer.
 * - Diary closes soon (the last 15 minutes): the same position in amber, counting down to the
 *   close in the header and status chip, Continue.
 */
object DiaryProgressFactory {

    const val FILLED_COLOR = 0xFFA449FF.toInt()
    val UNFILLED_COLOR = halfAlpha(FILLED_COLOR)

    /** "Closes soon" amber; brighter on the dark notification surface, per the design. */
    const val CLOSING_COLOR_LIGHT = 0xFFB5790E.toInt()
    const val CLOSING_COLOR_DARK = 0xFFFEB954.toInt()

    const val CLOSING_WINDOW_MILLIS = 15 * 60 * 1_000L

    /**
     * Android's ProgressStyle draws at most this many segments (MAX_PROGRESS_SEGMENT_LIMIT); past
     * it, everything is merged into one bar in a default color. Longer diaries get a single
     * filled/unfilled bar instead, which keeps the colors and the ghost's position.
     */
    const val MAX_SEGMENTS = 10

    /** "Diary in progress" or "Next question waiting". */
    fun contentFor(state: DiaryProgressState): DiaryProgressContent {
        val waiting = state.nextQuestionWaiting
        return DiaryProgressContent(
            title = if (waiting) "Next question waiting" else "Diary in progress",
            text = questionPosition(state.shownQuestion, state.questionCount),
            art = if (waiting) DiaryArt.NEXT_QUESTION else DiaryArt.IN_PROGRESS,
            progress = progressFor(state, FILLED_COLOR),
            action = if (waiting) DiaryAction.ANSWER else DiaryAction.CONTINUE,
        )
    }

    /** "Diary closes soon", counting down to [closesAtMillis]. */
    fun closingSoonContent(
        state: DiaryProgressState,
        closesAtMillis: Long,
        isNightMode: Boolean,
    ): DiaryProgressContent = DiaryProgressContent(
        title = "Diary closes soon",
        text = questionPosition(state.shownQuestion, state.questionCount),
        art = DiaryArt.CLOSES_SOON,
        progress = progressFor(state, if (isNightMode) CLOSING_COLOR_DARK else CLOSING_COLOR_LIGHT),
        action = if (state.nextQuestionWaiting) DiaryAction.CONTINUE_TO_NEXT else DiaryAction.CONTINUE,
        countdownToMillis = closesAtMillis,
    )

    /**
     * The questions before the shown one are filled. O(n) in the question count, which is capped
     * at [MAX_SEGMENTS] for the per-question bar.
     */
    private fun progressFor(state: DiaryProgressState, color: Int): ProgressBar {
        val answered = state.shownQuestion - 1
        val count = state.questionCount
        val unfilled = halfAlpha(color)

        val segments = if (count <= MAX_SEGMENTS) {
            List(count) { index -> Segment(1, if (index < answered) color else unfilled) }
        } else {
            splitSegment(0, count, answered, color, unfilled)
        }

        return ProgressBar(max = count, progress = answered, segments = segments)
    }
}
