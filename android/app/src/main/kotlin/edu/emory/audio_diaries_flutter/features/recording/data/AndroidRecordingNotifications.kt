package edu.emory.audio_diaries_flutter.features.recording.data

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import edu.emory.audio_diaries_flutter.MainActivity
import edu.emory.audio_diaries_flutter.R
import edu.emory.audio_diaries_flutter.core.notification.applyProgressBar
import edu.emory.audio_diaries_flutter.core.notification.requestLiveUpdate
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingAction
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingArt
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotificationContent
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotificationFactory
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotifications

/**
 * Posts the recording notification. The in-progress phases are Live Updates; see
 * [edu.emory.audio_diaries_flutter.features.timer.data.AndroidTimerNotifications] for how
 * SystemUI's promoted template differs from the design.
 *
 * While capturing, the notification takes over the microphone foreground service's own
 * notification by posting on its id, so the participant sees one notification, not two. Other
 * phases have no service, and stopping the service removes that id asynchronously, so they live
 * on [IDLE_NOTIFICATION_ID] where that removal can't take them down.
 *
 * Pause and Save are broadcasts and work from the shade. Resume and Record again open the app
 * first: Android won't start a microphone foreground service for an app in the background, so
 * starting capture from the shade would record silence.
 */
class AndroidRecordingNotifications(private val context: Context) : RecordingNotifications {

    private val notificationManager = NotificationManagerCompat.from(context)

    /** Decoded once each: the notification is re-posted every second while recording. */
    private val largeIcons = mutableMapOf<RecordingArt, Bitmap>()

    private var actionListener: ((RecordingAction) -> Unit)? = null

    private val actionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ACTION_PAUSE -> actionListener?.invoke(RecordingAction.PAUSE)
                ACTION_SAVE -> actionListener?.invoke(RecordingAction.SAVE)
            }
        }
    }
    private var receiverRegistered = false

    /** Creates the channels and starts listening for actions. Call once, before [show]. */
    fun start() {
        createChannels()
        if (receiverRegistered) return
        // Not exported: only our own PendingIntents (sent as this app) can reach it.
        ContextCompat.registerReceiver(
            context,
            actionReceiver,
            IntentFilter().apply {
                addAction(ACTION_PAUSE)
                addAction(ACTION_SAVE)
            },
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

    override fun setActionListener(listener: ((RecordingAction) -> Unit)?) {
        actionListener = listener
    }

    /**
     * Routes the actions that arrive as activity intents (Resume, Record again), which MainActivity
     * receives. Returns whether the intent was one of ours.
     */
    fun handleLaunchIntent(intent: Intent?): Boolean {
        val action = when (intent?.action) {
            ACTION_RESUME -> RecordingAction.RESUME
            ACTION_RECORD_AGAIN -> RecordingAction.RECORD_AGAIN
            else -> return false
        }
        actionListener?.invoke(action)
        return true
    }

    @SuppressLint("MissingPermission")
    override fun show(content: RecordingNotificationContent) {
        if (!notificationManager.areNotificationsEnabled()) return

        val chronometer = content.chronometerSeconds
        val builder = NotificationCompat.Builder(
            context,
            if (content.alerts) ALERT_CHANNEL_ID else CHANNEL_ID,
        )
            .setSmallIcon(R.drawable.ic_notification_fabla)
            .setLargeIcon(largeIconFor(content.art))
            .setContentTitle(content.title)
            .setContentText(content.text)
            .setContentIntent(openAppIntent(action = null))
            .setColor(RecordingNotificationFactory.FILLED_COLOR)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(content.isLiveUpdate)
            .setAutoCancel(!content.isLiveUpdate)
            .setSilent(!content.alerts)
            .setOnlyAlertOnce(true)
            .setLocalOnly(true)
            .setShowWhen(chronometer != null)
            .setUsesChronometer(chronometer != null)

        // The chronometer counts up from this instant natively, and the status chip shows it.
        if (chronometer != null) {
            builder.setWhen(System.currentTimeMillis() - chronometer * MILLIS_PER_SECOND)
        }
        content.chipText?.let { builder.setShortCriticalText(it) }

        if (content.isLiveUpdate) builder.requestLiveUpdate()
        content.progress?.let { builder.applyProgressBar(context, it) }

        content.action?.let { builder.addAction(0, it.label, intentFor(it)) }

        val id = if (content.isCapturing) FOREGROUND_NOTIFICATION_ID else IDLE_NOTIFICATION_ID
        val staleId = if (content.isCapturing) IDLE_NOTIFICATION_ID else FOREGROUND_NOTIFICATION_ID
        notificationManager.cancel(staleId)
        notificationManager.notify(id, builder.build())
    }

    override fun hide() {
        notificationManager.cancel(FOREGROUND_NOTIFICATION_ID)
        notificationManager.cancel(IDLE_NOTIFICATION_ID)
    }

    private fun largeIconFor(art: RecordingArt): Bitmap = largeIcons.getOrPut(art) {
        BitmapFactory.decodeResource(context.resources, drawableFor(art))
    }

    private fun drawableFor(art: RecordingArt) = when (art) {
        RecordingArt.RECORDING -> R.drawable.recording_large_icon
        RecordingArt.PAUSED -> R.drawable.recording_paused_large_icon
        RecordingArt.PAUSED_BY_CALL -> R.drawable.recording_call_large_icon
        RecordingArt.READY_TO_SAVE -> R.drawable.recording_ready_large_icon
        RecordingArt.COULD_NOT_RESUME -> R.drawable.recording_could_not_resume_large_icon
        RecordingArt.SAVED -> R.drawable.recording_saved_large_icon
        RecordingArt.STOPPED -> R.drawable.recording_stopped_large_icon
    }

    private fun intentFor(action: RecordingAction): PendingIntent = when (action) {
        RecordingAction.PAUSE -> broadcastIntent(ACTION_PAUSE)
        RecordingAction.SAVE -> broadcastIntent(ACTION_SAVE)
        RecordingAction.RESUME -> openAppIntent(ACTION_RESUME)
        RecordingAction.OPEN -> openAppIntent(action = null)
        RecordingAction.RECORD_AGAIN -> openAppIntent(ACTION_RECORD_AGAIN)
    }

    private fun broadcastIntent(action: String): PendingIntent = PendingIntent.getBroadcast(
        context,
        if (action == ACTION_PAUSE) FOREGROUND_NOTIFICATION_ID else IDLE_NOTIFICATION_ID,
        Intent(action).setPackage(context.packageName),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** Brings the app forward; with [action] set, MainActivity hands it to [handleLaunchIntent]. */
    private fun openAppIntent(action: String?): PendingIntent = PendingIntent.getActivity(
        context,
        if (action == null) FOREGROUND_NOTIFICATION_ID else IDLE_NOTIFICATION_ID,
        Intent(context, MainActivity::class.java)
            .setAction(action)
            .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /**
     * The silent channel is normally already created by the foreground service plugin; this covers
     * a take whose service never came up. Re-creating an existing channel leaves the participant's
     * settings alone.
     */
    private fun createChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        notificationManager.createNotificationChannel(
            NotificationChannel(
                ALERT_CHANNEL_ID,
                ALERT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Tells you when a diary recording couldn't resume or stopped " +
                    "with nothing recorded."
                setShowBadge(false)
            }
        )

        notificationManager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shown while a diary answer is being recorded, so recording " +
                    "continues if you leave the app."
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
        )
    }

    private companion object {
        /**
         * Same channel the recording foreground service (flutter_foreground_task, see
         * lib/services/recording_foreground_service.dart) posts on, so taking over its
         * notification keeps the participant's channel settings.
         */
        const val CHANNEL_ID = "diary_recording"
        const val CHANNEL_NAME = "Diary recording"

        /** Problems the participant should hear about with the app closed. IMPORTANCE_DEFAULT. */
        const val ALERT_CHANNEL_ID = "diary_recording_alerts"
        const val ALERT_CHANNEL_NAME = "Diary recording problems"

        /**
         * The recording foreground service's notification id (`_notificationId` in
         * recording_foreground_service.dart). Must stay in sync with the Dart side.
         */
        const val FOREGROUND_NOTIFICATION_ID = 8291

        /** Phases with no foreground service: see the class doc. */
        const val IDLE_NOTIFICATION_ID = 4202

        const val ACTION_PAUSE = "edu.emory.audio_diaries_flutter.recording.PAUSE"
        const val ACTION_RESUME = "edu.emory.audio_diaries_flutter.recording.RESUME"
        const val ACTION_SAVE = "edu.emory.audio_diaries_flutter.recording.SAVE"
        const val ACTION_RECORD_AGAIN = "edu.emory.audio_diaries_flutter.recording.RECORD_AGAIN"
        const val MILLIS_PER_SECOND = 1_000L
    }
}
