package edu.emory.audio_diaries_flutter.core.domain

/** "Q5 of 8", or null when the position is unknown. */
fun questionPosition(number: Int?, count: Int?): String? =
    if (number != null && count != null && number > 0 && count > 0) "Q$number of $count" else null

/** "04:12" (or "1:04:12"): a clock reading, used where a stopped chronometer would be. */
fun clockText(totalSeconds: Int): String {
    val seconds = totalSeconds.coerceAtLeast(0)
    val hours = seconds / 3_600
    return if (hours > 0) {
        "%d:%02d:%02d".format(hours, (seconds % 3_600) / 60, seconds % 60)
    } else {
        "%02d:%02d".format(seconds / 60, seconds % 60)
    }
}

/** "0:48" (or "1:04:12"): a length of time inside a sentence, e.g. "0:48 so far". */
fun durationText(totalSeconds: Int): String {
    val seconds = totalSeconds.coerceAtLeast(0)
    val hours = seconds / 3_600
    val minutes = (seconds % 3_600) / 60
    return if (hours > 0) {
        "%d:%02d:%02d".format(hours, minutes, seconds % 60)
    } else {
        "%d:%02d".format(minutes, seconds % 60)
    }
}
