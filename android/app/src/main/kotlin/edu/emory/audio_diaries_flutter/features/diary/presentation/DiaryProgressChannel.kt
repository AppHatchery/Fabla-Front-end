package edu.emory.audio_diaries_flutter.features.diary.presentation

import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryClosingReminder
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryClosingReminders
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressFactory
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressNotifications
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter side of the diary notification: lib/services/diary_progress_notification_service.dart.
 *
 * - "show": the diary as the participant left it. Inside the last 15 minutes before
 *   `closesAtMillis` that's "Diary closes soon"; otherwise "Diary in progress" or "Next question
 *   waiting".
 * - "hide": removes it.
 * - "scheduleClosingReminder" / "cancelClosingReminder": arm or disarm the alarm that posts
 *   "Diary closes soon" with the app closed.
 *
 * An advancing action is sent back as "answerNext".
 */
class DiaryProgressChannel(
    private val notifications: DiaryProgressNotifications,
    private val closingReminders: DiaryClosingReminders,
    private val isNightMode: () -> Boolean,
) {

    private var methodChannel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger) {
        notifications.setAnswerListener { methodChannel?.invokeMethod("answerNext", null) }

        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        show(call.toProgressState(), call.argument<Number>("closesAtMillis")?.toLong())
                        result.success(null)
                    }

                    "hide" -> {
                        notifications.hide()
                        result.success(null)
                    }

                    "scheduleClosingReminder" -> {
                        val diaryId = call.argument<Int>("diaryId")
                        val closesAt = call.argument<Number>("closesAtMillis")?.toLong()
                        val progress = call.toProgressState()
                        if (diaryId != null && closesAt != null && progress.isShowable) {
                            closingReminders.schedule(DiaryClosingReminder(diaryId, closesAt, progress))
                        }
                        result.success(null)
                    }

                    "cancelClosingReminder" -> {
                        call.argument<Int>("diaryId")?.let(closingReminders::cancel)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    fun detach() {
        notifications.hide()
        notifications.setAnswerListener(null)
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    private fun show(state: DiaryProgressState, closesAtMillis: Long?) {
        if (!state.isShowable) {
            notifications.hide()
            return
        }

        val closingSoon = closesAtMillis != null &&
            DiaryClosingReminder(0, closesAtMillis, state).isClosingSoon(System.currentTimeMillis())

        notifications.show(
            if (closingSoon) {
                DiaryProgressFactory.closingSoonContent(state, closesAtMillis!!, isNightMode())
            } else {
                DiaryProgressFactory.contentFor(state)
            }
        )
    }

    private fun MethodCall.toProgressState() = DiaryProgressState(
        questionNumber = argument<Int>("questionNumber") ?: 0,
        questionCount = argument<Int>("questionCount") ?: 0,
        currentAnswered = argument<Boolean>("currentAnswered") ?: false,
    )

    private companion object {
        const val CHANNEL_NAME = "edu.emory.audio_diaries_flutter/diary_progress"
    }
}
