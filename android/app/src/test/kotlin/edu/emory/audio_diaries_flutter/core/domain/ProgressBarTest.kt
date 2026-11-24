package edu.emory.audio_diaries_flutter.core.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class ProgressBarTest {

    @Test fun `splits at progress into filled then unfilled`() =
        assertEquals(listOf(Segment(3, 1), Segment(7, 2)), splitSegment(0, 10, 3, 1, 2))

    @Test fun `drops an empty filled part`() =
        assertEquals(listOf(Segment(10, 2)), splitSegment(0, 10, 0, 1, 2))

    @Test fun `drops an empty unfilled part`() =
        assertEquals(listOf(Segment(10, 1)), splitSegment(0, 10, 10, 1, 2))

    @Test fun `progress outside the stretch is clamped`() {
        assertEquals(listOf(Segment(5, 2)), splitSegment(5, 10, 2, 1, 2))
        assertEquals(listOf(Segment(5, 1)), splitSegment(5, 10, 99, 1, 2))
    }

    @Test fun `half alpha keeps the color`() =
        assertEquals(0x80626AD9.toInt(), halfAlpha(0xFF626AD9.toInt()))
}
