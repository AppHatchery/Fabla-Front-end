package edu.emory.audio_diaries_flutter.features.timer.data

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import edu.emory.audio_diaries_flutter.MainActivity
import edu.emory.audio_diaries_flutter.R
import edu.emory.audio_diaries_flutter.core.notification.applyProgressBar
import edu.emory.audio_diaries_flutter.core.notification.requestLiveUpdate
import edu.emory.audio_diaries_flutter.features.timer.domain.TimerNotificationContent
import edu.emory.audio_diaries_flutter.features.timer.domain.TimerNotifications
import edu.emory.audio_diaries_flutter.features.timer.domain.TimerNotificationFactory

/**
 * Posts the diary timer as an Android Live Update (promoted ongoing notification), so the
 * countdown stays visible on the lock screen, in the shade and in the status bar chip.
 *
 * SystemUI draws promoted notifications with its own template: no "Fabla • 04:12" header row and
 * full-width outlined action buttons. Apps can't restyle that.
 *
 * Live Updates and ProgressStyle need API 36. Below that the same notification is posted as a
 * plain ongoing notification with a determinate progress bar (no ghost tracker).
 */
class AndroidTimerNotifications(private val context: Context) : TimerNotifications {

    private val notificationManager = NotificationManagerCompat.from(context)

    private val largeIcon by lazy {
        BitmapFactory.decodeResource(context.resources, R.drawable.meditation_timer_large_icon)
    }

    private var actionListener: (() -> Unit)? = null

    private val actionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_TOGGLE_PAUSE) actionListener?.invoke()
        }
    }
    private var receiverRegistered = false

    /** Creates the channel and starts listening for the action. Call once, before [show]. */
    fun start() {
        createChannel()
        if (receiverRegistered) return
        // Not exported: only our own PendingIntent (sent as this app) can reach it.
        ContextCompat.registerReceiver(
            context,
            actionReceiver,
            IntentFilter(ACTION_TOGGLE_PAUSE),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        receiverRegistered = true
    }

    fun stop() {
        hide()
        if (!receiverRegistered) return
        context.unregisterReceiver(actionReceiver)
        receiverRegistered = false
    }

    override fun setActionListener(listener: (() -> Unit)?) {
        actionListener = listener
    }

    @SuppressLint("MissingPermission")
    override fun show(content: TimerNotificationContent) {
        if (!notificationManager.areNotificationsEnabled()) return

        val countdown = content.countdownSeconds
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_fabla)
            .setLargeIcon(largeIcon)
            .setContentTitle(content.title)
            .setContentText(content.text)
            .setSubText(content.subText)
            .setContentIntent(openAppIntent())
            .setColor(TimerNotificationFactory.ELAPSED_COLOR)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setLocalOnly(true)
            .setShowWhen(countdown != null)
            .setUsesChronometer(countdown != null)
            .setChronometerCountDown(countdown != null)

        // The chronometer counts down to this instant natively, so the text needs no ticking.
        if (countdown != null) {
            builder.setWhen(System.currentTimeMillis() + countdown * MILLIS_PER_SECOND)
        }
        content.chipText?.let { builder.setShortCriticalText(it) }

        builder.requestLiveUpdate()
        builder.applyProgressBar(context, content.progress)

        content.action?.let { builder.addAction(0, it.label, togglePauseIntent()) }

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    override fun hide() {
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun togglePauseIntent(): PendingIntent = PendingIntent.getBroadcast(
        context,
        NOTIFICATION_ID,
        Intent(ACTION_TOGGLE_PAUSE).setPackage(context.packageName),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        context,
        NOTIFICATION_ID,
        Intent(context, MainActivity::class.java)
            .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** IMPORTANCE_LOW: silent, but Live Updates are disqualified by IMPORTANCE_MIN. */
    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows the remaining time for an in-progress diary timer."
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }

        notificationManager.createNotificationChannel(channel)
    }

    private companion object {
        const val CHANNEL_ID = "diary_timer_live_update"
        const val CHANNEL_NAME = "Diary Timer"

        /** Stable id so every update replaces the same notification instead of stacking. */
        const val NOTIFICATION_ID = 4201

        const val ACTION_TOGGLE_PAUSE = "edu.emory.audio_diaries_flutter.timer.TOGGLE_PAUSE"
        const val MILLIS_PER_SECOND = 1_000L
    }
}
