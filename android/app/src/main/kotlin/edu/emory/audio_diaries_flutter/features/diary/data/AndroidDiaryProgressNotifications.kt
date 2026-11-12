package edu.emory.audio_diaries_flutter.features.diary.data

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import edu.emory.audio_diaries_flutter.MainActivity
import edu.emory.audio_diaries_flutter.R
import edu.emory.audio_diaries_flutter.core.notification.applyProgressBar
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressContent
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressFactory
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressNotifications

/**
 * Posts the "Diary in progress" notification. A regular, dismissible notification rather than a
 * Live Update: nothing is running while the participant is away, it's a reminder to come back.
 * It alerts (the channel's default sound) so the reminder is noticed. Continue and a tap both
 * reopen the app, which is still on the diary.
 */
class AndroidDiaryProgressNotifications(private val context: Context) : DiaryProgressNotifications {

    private val notificationManager = NotificationManagerCompat.from(context)

    private val largeIcon by lazy {
        BitmapFactory.decodeResource(context.resources, R.drawable.diary_in_progress_large_icon)
    }

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

    @SuppressLint("MissingPermission")
    override fun show(content: DiaryProgressContent) {
        if (!notificationManager.areNotificationsEnabled()) return

        val openApp = openAppIntent()
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_fabla)
            .setLargeIcon(largeIcon)
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
            .addAction(0, content.actionLabel, openApp)

        builder.applyProgressBar(context, content.progress)

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    override fun hide() {
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        context,
        NOTIFICATION_ID,
        Intent(context, MainActivity::class.java)
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
    }
}
