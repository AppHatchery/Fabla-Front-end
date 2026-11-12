package edu.emory.audio_diaries_flutter.features.diary.presentation

import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressFactory
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressNotifications
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter side of the diary progress notification:
 * lib/services/diary_progress_notification_service.dart. "show" takes the question the
 * participant is on; "hide" removes it.
 */
class DiaryProgressChannel(private val notifications: DiaryProgressNotifications) {

    private var methodChannel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        val state = DiaryProgressState(
                            questionNumber = call.argument<Int>("questionNumber") ?: 0,
                            questionCount = call.argument<Int>("questionCount") ?: 0,
                        )
                        if (state.isShowable) {
                            notifications.show(DiaryProgressFactory.contentFor(state))
                        } else {
                            notifications.hide()
                        }
                        result.success(null)
                    }

                    "hide" -> {
                        notifications.hide()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    fun detach() {
        notifications.hide()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    private companion object {
        const val CHANNEL_NAME = "edu.emory.audio_diaries_flutter/diary_progress"
    }
}
