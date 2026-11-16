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
import edu.emory.audio_diaries_flutter.core.notification.requestLiveUpdate
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryArt
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressContent
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressFactory
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressNotifications

/**
 * Posts the diary notification. It alerts (the channel's default sound) so the reminder is noticed.
 *
 * "Diary in progress" and "Next question waiting" are regular, dismissible notifications: nothing
 * is running while the participant is away. "Diary closes soon" counts down to the close, so it's
 * an ongoing Live Update with the countdown in the status chip, and removes itself at the close.
 *
 * Every action reopens the app. One that advances (Answer, or Continue on a waiting question)
 * goes through MainActivity, which hands it to [handleLaunchIntent] so the diary moves on.
 *
 * Also used by [DiaryClosingReceiver], with no Flutter engine running.
 */
class AndroidDiaryProgressNotifications(private val context: Context) : DiaryProgressNotifications {

    private val notificationManager = NotificationManagerCompat.from(context)

    private val largeIcons = mutableMapOf<DiaryArt, Bitmap>()

    private var answerListener: (() -> Unit)? = null

    /** Creates the channel. Call before [show]; repeat calls are harmless. */
    fun start() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        notificationManager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Reminds you of a diary you left part-way through, and when it's " +
                    "about to close."
                setShowBadge(false)
            }
        )
    }

    override fun setAnswerListener(listener: (() -> Unit)?) {
        answerListener = listener
    }

    /** Routes an advancing action, which arrives as an activity intent. Returns whether it was ours. */
    fun handleLaunchIntent(intent: Intent?): Boolean {
        if (intent?.action != ACTION_ANSWER) return false
        answerListener?.invoke()
        return true
    }

    @SuppressLint("MissingPermission")
    override fun show(content: DiaryProgressContent) {
        if (!notificationManager.areNotificationsEnabled()) return

        val openApp = openAppIntent(action = if (content.action.advances) ACTION_ANSWER else null)
        val countdownTo = content.countdownToMillis

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
            .setOngoing(content.isLiveUpdate)
            .setAutoCancel(!content.isLiveUpdate)
            .setOnlyAlertOnce(true)
            .setLocalOnly(true)
            .setShowWhen(countdownTo != null)
            .setUsesChronometer(countdownTo != null)
            .setChronometerCountDown(countdownTo != null)
            .addAction(0, content.action.label, openApp)

        if (countdownTo != null) {
            // The chronometer, and the status chip, count down to the close natively.
            builder.setWhen(countdownTo)
            builder.requestLiveUpdate()
            // Gone once the diary closes: there's nothing left to continue.
            builder.setTimeoutAfter((countdownTo - System.currentTimeMillis()).coerceAtLeast(1))
        }

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
                DiaryArt.CLOSES_SOON -> R.drawable.diary_closes_soon_large_icon
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

        /** Shared by all three titles, so a newer one replaces the last. */
        const val NOTIFICATION_ID = 4203

        const val ACTION_ANSWER = "edu.emory.audio_diaries_flutter.diary.ANSWER"
    }
}
