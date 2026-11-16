package edu.emory.audio_diaries_flutter.core.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class NotificationTextTest {

    @Test fun `question position reads Q n of m`() =
        assertEquals("Q3 of 8", questionPosition(3, 8))

    @Test fun `question position is null when unknown or out of range`() {
        assertNull(questionPosition(null, 8))
        assertNull(questionPosition(3, null))
        assertNull(questionPosition(0, 8))
    }

    @Test fun `clock text pads minutes`() = assertEquals("04:12", clockText(252))

    @Test fun `clock text adds hours past an hour`() = assertEquals("1:04:12", clockText(3852))

    @Test fun `duration text does not pad minutes`() = assertEquals("0:48", durationText(48))

    @Test fun `negative times read as zero`() {
        assertEquals("00:00", clockText(-5))
        assertEquals("0:00", durationText(-5))
    }
}
