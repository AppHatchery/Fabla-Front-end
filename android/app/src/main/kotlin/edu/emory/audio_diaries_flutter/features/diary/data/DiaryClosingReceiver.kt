package edu.emory.audio_diaries_flutter.features.diary.data

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import edu.emory.audio_diaries_flutter.core.notification.isNightMode
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressFactory

/**
 * Posts "Diary closes soon" when its alarm fires, and re-arms the alarms after a reboot. Declared
 * in the manifest, so it runs with no Flutter engine, or no app process, at all.
 */
class DiaryClosingReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val reminders = AndroidDiaryClosingReminders(context)

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> reminders.rearmAll()

            ACTION_CLOSING_SOON -> {
                val diaryId = intent.getIntExtra(EXTRA_DIARY_ID, -1)
                val reminder = reminders.load(diaryId) ?: return
                reminders.forget(diaryId)

                // A late alarm (Doze, an inexact fallback) after the close has nothing to say.
                if (!reminder.progress.isShowable || System.currentTimeMillis() >= reminder.closesAtMillis) return

                AndroidDiaryProgressNotifications(context).apply {
                    start()
                    show(
                        DiaryProgressFactory.closingSoonContent(
                            reminder.progress,
                            reminder.closesAtMillis,
                            context.isNightMode(),
                        )
                    )
                }
            }
        }
    }

    companion object {
        const val ACTION_CLOSING_SOON = "edu.emory.audio_diaries_flutter.diary.CLOSING_SOON"
        const val EXTRA_DIARY_ID = "diaryId"
    }
}
