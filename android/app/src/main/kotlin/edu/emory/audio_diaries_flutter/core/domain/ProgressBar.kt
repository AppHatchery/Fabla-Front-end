package edu.emory.audio_diaries_flutter.core.domain

/** One colored stretch of a notification progress bar, [length] units long. */
data class Segment(val length: Int, val color: Int)

/**
 * A determinate progress bar: [progress] of [max], drawn as [segments] in order.
 *
 * Colors may be translucent, as the design gives them (e.g. #626AD980). The notification layer
 * flattens them, since Android's ProgressStyle draws segment colors fully opaque.
 */
data class ProgressBar(val max: Int, val progress: Int, val segments: List<Segment>)

/**
 * Splits [start, end) at [progress] into a filled and an unfilled segment, dropping either when
 * empty. The bars are drawn this way, not with the platform's own "after progress" fade, because
 * that fade can't be set to the design colors.
 */
fun splitSegment(
    start: Int,
    end: Int,
    progress: Int,
    filledColor: Int,
    unfilledColor: Int,
): List<Segment> {
    val split = progress.coerceIn(start, end)
    return buildList {
        if (split > start) add(Segment(split - start, filledColor))
        if (end > split) add(Segment(end - split, unfilledColor))
    }
}

/** [color] at 50% alpha, the design's "unfilled" treatment. */
fun halfAlpha(color: Int): Int = (color and 0x00FFFFFF) or 0x80000000.toInt()
