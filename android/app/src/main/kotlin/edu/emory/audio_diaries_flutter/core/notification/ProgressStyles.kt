package edu.emory.audio_diaries_flutter.core.notification

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.graphics.ColorUtils
import androidx.core.graphics.drawable.IconCompat
import edu.emory.audio_diaries_flutter.R
import edu.emory.audio_diaries_flutter.core.domain.ProgressBar

/** Whether the device is in dark theme, which changes the notification surface color. */
fun Context.isNightMode(): Boolean =
    (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
        Configuration.UI_MODE_NIGHT_YES

/**
 * Adds [bar] to [builder]: as a ProgressStyle with the Fabla ghost riding it on API 36+, or as a
 * plain determinate bar below that.
 */
fun NotificationCompat.Builder.applyProgressBar(context: Context, bar: ProgressBar) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.BAKLAVA) {
        setProgress(bar.max, bar.progress, false)
        return
    }

    setStyle(
        NotificationCompat.ProgressStyle()
            .setProgress(bar.progress)
            .setProgressTrackerIcon(IconCompat.createWithResource(context, R.drawable.ic_progress_ghost))
            // Segments carry the exact design colors; the platform fade would override them.
            .setStyledByProgress(false)
            .setProgressSegments(
                bar.segments.map {
                    NotificationCompat.ProgressStyle.Segment(it.length)
                        .setColor(opaqueOverBackground(context, it.color))
                }
            )
    )
}

/** Asks for Live Update promotion where it exists (API 36+). */
fun NotificationCompat.Builder.requestLiveUpdate() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) setRequestPromotedOngoing(true)
}

/**
 * Flattens a translucent design color onto the notification surface. ProgressStyle drops segment
 * alpha and would draw the color fully opaque. Opaque colors pass through unchanged.
 */
private fun opaqueOverBackground(context: Context, color: Int): Int {
    val background = if (context.isNightMode()) DARK_BACKGROUND else LIGHT_BACKGROUND
    return ColorUtils.compositeColors(color, background)
}

/** Notification surface colors: the design's light background, and Material 3's dark one. */
private const val LIGHT_BACKGROUND = 0xFFECE6F0.toInt()
private const val DARK_BACKGROUND = 0xFF2B2930.toInt()
