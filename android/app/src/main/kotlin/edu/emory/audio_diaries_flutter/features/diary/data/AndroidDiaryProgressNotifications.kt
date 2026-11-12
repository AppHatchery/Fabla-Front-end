package edu.emory.audio_diaries_flutter.features.diary.data

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import edu.emory.audio_diaries_flutter.MainActivity
import edu.emory.audio_diaries_flutter.R
import edu.emory.audio_diaries_flutter.core.notification.applyProgressBar
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryAction
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryArt
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressContent
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressFactory
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressNotifications

/**
 * Posts the "Diary in progress" notification. A regular, dismissible notification rather than a
 * Live Update: nothing is running while the participant is away, it's a reminder to come back.
 * It alerts (the channel's default sound) so the reminder is noticed.
 *
 * Continue (and a tap on "Diary in progress") reopens the app, which is still on the diary. Answer
 * (and a tap on "Next question waiting") reopens it through MainActivity, which hands the intent
 * to [handleLaunchIntent] so the diary moves on to the waiting question.
 */
class AndroidDiaryProgressNotifications(private val context: Context) : DiaryProgressNotifications {

    private val notificationManager = NotificationManagerCompat.from(context)

    private val largeIcons = mutableMapOf<DiaryArt, Bitmap>()

    private var answerListener: (() -> Unit)? = null

    /** Creates the channel. Call once, before [show]. */
    fun start() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        notificationManager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Reminds you of a diary you left part-way through."
                setShowBadge(false)
            }
        )
    }

    override fun setAnswerListener(listener: (() -> Unit)?) {
        answerListener = listener
    }

    /** Routes the Answer action, which arrives as an activity intent. Returns whether it was ours. */
    fun handleLaunchIntent(intent: Intent?): Boolean {
        if (intent?.action != ACTION_ANSWER) return false
        answerListener?.invoke()
        return true
    }

    @SuppressLint("MissingPermission")
    override fun show(content: DiaryProgressContent) {
        if (!notificationManager.areNotificationsEnabled()) return

        val openApp = openAppIntent(
            action = if (content.action == DiaryAction.ANSWER) ACTION_ANSWER else null,
        )
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_fabla)
            .setLargeIcon(largeIconFor(content.art))
            .setContentTitle(content.title)
            .setContentText(content.text)
            .setContentIntent(openApp)
            .setColor(DiaryProgressFactory.FILLED_COLOR)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setLocalOnly(true)
            .setShowWhen(false)
            .addAction(0, content.action.label, openApp)

        builder.applyProgressBar(context, content.progress)

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    override fun hide() {
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun largeIconFor(art: DiaryArt): Bitmap = largeIcons.getOrPut(art) {
        BitmapFactory.decodeResource(
            context.resources,
            when (art) {
                DiaryArt.IN_PROGRESS -> R.drawable.diary_in_progress_large_icon
                DiaryArt.NEXT_QUESTION -> R.drawable.diary_next_question_large_icon
            },
        )
    }

    private fun openAppIntent(action: String?): PendingIntent = PendingIntent.getActivity(
        context,
        NOTIFICATION_ID,
        Intent(context, MainActivity::class.java)
            .setAction(action)
            .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private companion object {
        /**
         * IMPORTANCE_DEFAULT: alerts with sound. A channel's importance is fixed once created, so
         * this id must change if the importance ever does.
         */
        const val CHANNEL_ID = "diary_in_progress_alerts"
        const val CHANNEL_NAME = "Diary in progress"
        const val NOTIFICATION_ID = 4203

        const val ACTION_ANSWER = "edu.emory.audio_diaries_flutter.diary.ANSWER"
    }
}
