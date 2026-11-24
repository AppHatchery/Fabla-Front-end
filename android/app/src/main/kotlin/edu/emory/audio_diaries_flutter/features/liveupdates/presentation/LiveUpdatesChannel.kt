package edu.emory.audio_diaries_flutter.features.liveupdates.presentation

import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import edu.emory.audio_diaries_flutter.features.diary.data.AndroidDiaryProgressNotifications
import edu.emory.audio_diaries_flutter.features.recording.data.AndroidRecordingNotifications
import edu.emory.audio_diaries_flutter.features.timer.data.AndroidTimerNotifications
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Answers how the app's progress notifications reach the user ("status") and opens the system
 * page that turns them into Live Updates ("openLiveUpdateSettings").
 *
 * Reads and opens system settings only, so it has no domain or data layer of its own.
 */
class LiveUpdatesChannel(private val context: Context) {

    private var methodChannel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger) {
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(status(notificationManager))
                    "openLiveUpdateSettings" ->
                        open(liveUpdateSettingsIntent(), result)

                    "openNotificationSettings" ->
                        open(notificationSettingsIntent(notificationManager), result)

                    else -> result.notImplemented()
                }
            }
        }
    }

    fun detach() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    /**
     * "notificationsOff" when the app's notifications or any progress channel are blocked,
     * "plain" (posted but not promoted), "liveUpdates", or "unsupported" when there is no Live
     * Updates setting to send the user to: before API 36, or a device without that screen.
     */
    private fun status(notificationManager: NotificationManager): String = when {
        !notificationManager.areNotificationsEnabled() -> "notificationsOff"
        blockedProgressChannel(notificationManager) != null -> "notificationsOff"
        Build.VERSION.SDK_INT < Build.VERSION_CODES.BAKLAVA -> "unsupported"
        notificationManager.canPostPromotedNotifications() -> "liveUpdates"
        !canOpenLiveUpdateSettings() -> "unsupported"
        else -> "plain"
    }

    /**
     * The first progress channel the user turned off while the app's notifications stay on, or
     * null. A channel not yet created (that feature hasn't run) isn't blocked. Channels arrived
     * in API 26.
     */
    private fun blockedProgressChannel(notificationManager: NotificationManager): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        return PROGRESS_CHANNEL_IDS.firstOrNull {
            notificationManager.getNotificationChannel(it)?.importance ==
                NotificationManager.IMPORTANCE_NONE
        }
    }

    /**
     * Where the user turns notifications back on: the blocked category's own page when only a
     * category is off, the app's notification page when all are (or before API 26, its app
     * info page, as notification settings had no page of their own).
     */
    private fun notificationSettingsIntent(notificationManager: NotificationManager): Intent {
        val blocked = if (notificationManager.areNotificationsEnabled()) {
            blockedProgressChannel(notificationManager)
        } else {
            null
        }
        val intent = when {
            blocked != null ->
                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                    .putExtra(Settings.EXTRA_CHANNEL_ID, blocked)

            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ->
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)

            else ->
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    .setData(Uri.fromParts("package", context.packageName, null))
        }
        // Started from the application context, outside any task.
        return intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }

    private fun open(intent: Intent, result: MethodChannel.Result) {
        try {
            context.startActivity(intent)
            result.success(null)
        } catch (e: ActivityNotFoundException) {
            result.error("NO_SETTINGS_SCREEN", e.message, null)
        }
    }

    private fun canOpenLiveUpdateSettings(): Boolean =
        liveUpdateSettingsIntent().resolveActivity(context.packageManager) != null

    /** The app's Live Updates switch (API 36+). */
    private fun liveUpdateSettingsIntent(): Intent =
        Intent(Settings.ACTION_APP_NOTIFICATION_PROMOTION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            // Started from the application context, outside any task.
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

    private companion object {
        const val CHANNEL_NAME = "edu.emory.audio_diaries_flutter/live_updates"

        /** The channels that carry recording, timer and diary progress. */
        val PROGRESS_CHANNEL_IDS = listOf(
            AndroidRecordingNotifications.CHANNEL_ID,
            AndroidTimerNotifications.CHANNEL_ID,
            AndroidDiaryProgressNotifications.CHANNEL_ID,
        )
    }
}
