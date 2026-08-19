package edu.emory.audio_diaries_flutter

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Posts the diary timer as an Android Live Update (promoted ongoing notification) so the
 * countdown stays visible on the lock screen, in the shade and in the status bar chip once
 * the app is backgrounded.
 *
 * The countdown text is rendered by the platform chronometer off a wall-clock end time, so it
 * stays correct even when the Dart isolate is throttled. Only the progress bar needs ticking,
 * which is done here rather than from Dart for the same reason.
 *
 * Live Updates require API 36. Below that the same notification is posted as a plain ongoing
 * notification with a determinate progress bar.
 */
class TimerLiveUpdate(private val context: Context) {

    private val notificationManager = NotificationManagerCompat.from(context)
    private val handler = Handler(Looper.getMainLooper())

    private var methodChannel: MethodChannel? = null

    /** Wall-clock instant the countdown hits zero. Null while paused or idle. */
    private var endAtMillis: Long? = null
    private var totalSeconds: Int = 0
    private var title: String = DEFAULT_TITLE

    private val tick = object : Runnable {
        override fun run() {
            val remaining = remainingSeconds() ?: return
            if (remaining <= 0) {
                hide()
                return
            }
            post(remaining, isPaused = false)
            handler.postDelayed(this, TICK_INTERVAL_MS)
        }
    }

    fun setup(messenger: BinaryMessenger) {
        createChannel()

        methodChannel = MethodChannel(messenger, TIMER_LIVE_UPDATE_CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        title = call.argument<String>("title") ?: DEFAULT_TITLE
                        totalSeconds = call.argument<Int>("totalSeconds") ?: 0
                        show(
                            remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0,
                            isPaused = call.argument<Boolean>("isPaused") ?: false,
                        )
                        result.success(null)
                    }

                    "hide" -> {
                        hide()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    fun terminate() {
        hide()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    /** Posts or refreshes the notification. Idempotent — Dart pushes whole state, not deltas. */
    private fun show(remainingSeconds: Int, isPaused: Boolean) {
        handler.removeCallbacks(tick)

        if (totalSeconds <= 0 || remainingSeconds <= 0) {
            hide()
            return
        }

        if (isPaused) {
            endAtMillis = null
        } else {
            endAtMillis = System.currentTimeMillis() + remainingSeconds * MILLIS_PER_SECOND
            handler.postDelayed(tick, TICK_INTERVAL_MS)
        }

        post(remainingSeconds, isPaused)
    }

    private fun hide() {
        handler.removeCallbacks(tick)
        endAtMillis = null
        notificationManager.cancel(TIMER_NOTIFICATION_ID)
    }

    private fun remainingSeconds(): Int? {
        val end = endAtMillis ?: return null
        return ((end - System.currentTimeMillis()) / MILLIS_PER_SECOND).toInt()
    }

    @SuppressLint("MissingPermission")
    private fun post(remainingSeconds: Int, isPaused: Boolean) {
        if (!notificationManager.areNotificationsEnabled()) return

        val elapsedSeconds = (totalSeconds - remainingSeconds).coerceIn(0, totalSeconds)

        val builder = NotificationCompat.Builder(context, TIMER_NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_timer)
            .setContentTitle(title)
            .setContentText(if (isPaused) PAUSED_TEXT else sessionLabel())
            .setContentIntent(contentIntent())
            .setColor(ACCENT_COLOR)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setLocalOnly(true)
            .setShowWhen(!isPaused)
            .setUsesChronometer(!isPaused)
            .setChronometerCountDown(!isPaused)

        // Chronometer counts down to this instant natively — no Dart tick required.
        if (!isPaused) {
            builder.setWhen(System.currentTimeMillis() + remainingSeconds * MILLIS_PER_SECOND)
        }

        applyProgress(builder, elapsedSeconds)

        notificationManager.notify(TIMER_NOTIFICATION_ID, builder.build())
    }

    private fun applyProgress(builder: NotificationCompat.Builder, elapsedSeconds: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            builder
                .setRequestPromotedOngoing(true)
                .setStyle(
                    NotificationCompat.ProgressStyle()
                        .setProgress(elapsedSeconds)
                        .setProgressSegments(
                            listOf(
                                NotificationCompat.ProgressStyle.Segment(totalSeconds)
                                    .setColor(ACCENT_COLOR)
                            )
                        )
                )
        } else {
            builder.setProgress(totalSeconds, elapsedSeconds, false)
        }
    }

    /** Mirrors the iOS subtitle, e.g. "0m 59s session". */
    private fun sessionLabel(): String {
        val minutes = totalSeconds / SECONDS_PER_MINUTE
        val seconds = totalSeconds % SECONDS_PER_MINUTE
        return "${minutes}m ${seconds}s session"
    }

    private fun contentIntent(): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

        return PendingIntent.getActivity(
            context,
            TIMER_NOTIFICATION_ID,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** IMPORTANCE_LOW: silent, but Live Updates are disqualified by IMPORTANCE_MIN. */
    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            TIMER_NOTIFICATION_CHANNEL_ID,
            TIMER_NOTIFICATION_CHANNEL_NAME,
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
        const val DEFAULT_TITLE = "Diary Timer"
        const val PAUSED_TEXT = "Paused"
        const val TICK_INTERVAL_MS = 1_000L
        const val MILLIS_PER_SECOND = 1_000L
        const val SECONDS_PER_MINUTE = 60
        const val ACCENT_COLOR = 0xFF4186F5.toInt()
    }
}
