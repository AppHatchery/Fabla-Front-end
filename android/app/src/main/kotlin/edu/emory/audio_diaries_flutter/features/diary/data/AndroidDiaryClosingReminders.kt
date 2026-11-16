package edu.emory.audio_diaries_flutter.features.diary.data

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.content.edit
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryClosingReminder
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryClosingReminders
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressState

/**
 * Arms "Diary closes soon" with AlarmManager, so it fires whether or not Fabla is running.
 *
 * Each reminder is also kept in SharedPreferences: the alarm carries only the diary id, the
 * receiver reads the latest progress from here, and [rearmAll] restores alarms after a reboot,
 * which clears them.
 *
 * Exact when the app may schedule exact alarms (it declares USE_EXACT_ALARM), so the reminder
 * lands at 15 minutes, not some minutes later; inexact otherwise.
 */
class AndroidDiaryClosingReminders(private val context: Context) : DiaryClosingReminders {

    private val alarmManager = context.getSystemService(AlarmManager::class.java)
    private val store = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)

    override fun schedule(reminder: DiaryClosingReminder) {
        store.edit { putString(reminder.diaryId.toString(), encode(reminder)) }
        arm(reminder)
    }

    override fun cancel(diaryId: Int) {
        store.edit { remove(diaryId.toString()) }
        alarmManager.cancel(alarmIntent(diaryId))
    }

    /** The stored reminder for [diaryId], if it hasn't been cancelled or used. */
    fun load(diaryId: Int): DiaryClosingReminder? =
        store.getString(diaryId.toString(), null)?.let(::decode)

    /** Forgets [diaryId]'s reminder once it has fired. */
    fun forget(diaryId: Int) = store.edit { remove(diaryId.toString()) }

    /** Re-arms every stored reminder still ahead, and drops the rest. After a reboot. */
    fun rearmAll() {
        val now = System.currentTimeMillis()
        store.all.keys.mapNotNull { key -> key.toIntOrNull()?.let(::load) }.forEach { reminder ->
            if (reminder.closesAtMillis <= now) forget(reminder.diaryId) else arm(reminder)
        }
    }

    /** A time already passed arms nothing; leaving the diary covers that stretch itself. */
    private fun arm(reminder: DiaryClosingReminder) {
        val at = reminder.remindAtMillis
        if (at <= System.currentTimeMillis()) return

        val intent = alarmIntent(reminder.diaryId)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
        if (exact) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        } else {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        }
    }

    private fun alarmIntent(diaryId: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        diaryId,
        Intent(context, DiaryClosingReceiver::class.java)
            .setAction(DiaryClosingReceiver.ACTION_CLOSING_SOON)
            .putExtra(DiaryClosingReceiver.EXTRA_DIARY_ID, diaryId),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** "diaryId|closesAt|question|count|answered": five fields, no JSON needed. */
    private fun encode(reminder: DiaryClosingReminder) = listOf(
        reminder.diaryId,
        reminder.closesAtMillis,
        reminder.progress.questionNumber,
        reminder.progress.questionCount,
        reminder.progress.currentAnswered,
    ).joinToString("|")

    private fun decode(raw: String): DiaryClosingReminder? {
        val parts = raw.split("|")
        if (parts.size != 5) return null
        return DiaryClosingReminder(
            diaryId = parts[0].toIntOrNull() ?: return null,
            closesAtMillis = parts[1].toLongOrNull() ?: return null,
            progress = DiaryProgressState(
                questionNumber = parts[2].toIntOrNull() ?: return null,
                questionCount = parts[3].toIntOrNull() ?: return null,
                currentAnswered = parts[4].toBooleanStrictOrNull() ?: return null,
            ),
        )
    }

    private companion object {
        const val STORE_NAME = "diary_closing_reminders"
    }
}
