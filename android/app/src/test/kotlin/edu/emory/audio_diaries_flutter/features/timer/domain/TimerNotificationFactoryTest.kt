package edu.emory.audio_diaries_flutter.features.timer.domain

import edu.emory.audio_diaries_flutter.core.domain.Segment
import edu.emory.audio_diaries_flutter.features.timer.domain.TimerNotificationFactory.ELAPSED_COLOR
import edu.emory.audio_diaries_flutter.features.timer.domain.TimerNotificationFactory.REMAINING_COLOR
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class TimerNotificationFactoryTest {

    private val running = TimerState(
        totalSeconds = 300,
        remainingSeconds = 252,
        isPaused = false,
        questionNumber = 5,
        questionCount = 8,
        playbackControls = true,
    )

    @Test fun `running shows the position and counts down`() {
        val content = TimerNotificationFactory.contentFor(running)

        assertEquals("Meditation timer", content.title)
        assertEquals("Q5 of 8", content.text)
        assertEquals(252, content.countdownSeconds)
        assertNull(content.subText)
        assertNull(content.chipText)
        assertEquals(TimerAction.PAUSE, content.action)
    }

    @Test fun `the bar is elapsed then remaining`() {
        val bar = TimerNotificationFactory.contentFor(running).progress

        assertEquals(300, bar.max)
        assertEquals(48, bar.progress)
        assertEquals(listOf(Segment(48, ELAPSED_COLOR), Segment(252, REMAINING_COLOR)), bar.segments)
    }

    @Test fun `paused freezes the time in the header and says Paused`() {
        val content = TimerNotificationFactory.contentFor(running.copy(isPaused = true))

        assertEquals("Q5 of 8 • Paused", content.text)
        assertEquals("04:12", content.subText)
        assertEquals("Paused", content.chipText)
        assertNull(content.countdownSeconds)
        assertEquals(TimerAction.RESUME, content.action)
    }

    @Test fun `paused without a position just says Paused`() {
        val content = TimerNotificationFactory.contentFor(
            running.copy(isPaused = true, questionNumber = null),
        )
        assertEquals("Paused", content.text)
    }

    @Test fun `no playback controls means no action`() =
        assertNull(TimerNotificationFactory.contentFor(running.copy(playbackControls = false)).action)

    @Test fun `nothing left is not showable`() {
        assertEquals(false, running.copy(remainingSeconds = 0).isShowable)
        assertEquals(false, running.copy(totalSeconds = 0).isShowable)
    }
}
