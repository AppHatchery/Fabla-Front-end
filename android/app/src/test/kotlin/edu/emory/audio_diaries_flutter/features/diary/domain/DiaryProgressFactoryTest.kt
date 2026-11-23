package edu.emory.audio_diaries_flutter.features.diary.domain

import edu.emory.audio_diaries_flutter.core.domain.Segment
import edu.emory.audio_diaries_flutter.core.domain.halfAlpha
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressFactory.FILLED_COLOR
import edu.emory.audio_diaries_flutter.features.diary.domain.DiaryProgressFactory.UNFILLED_COLOR
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DiaryProgressFactoryTest {

    @Test fun `title, position and action match the design`() {
        val content = DiaryProgressFactory.contentFor(DiaryProgressState(3, 8))

        assertEquals("Diary in progress", content.title)
        assertEquals("Q3 of 8", content.text)
        assertEquals(DiaryAction.CONTINUE, content.action)
        assertEquals("Continue", content.action.label)
        assertEquals(DiaryArt.IN_PROGRESS, content.art)
    }

    @Test fun `one bar per question, filled up to the current one`() {
        val bar = DiaryProgressFactory.contentFor(DiaryProgressState(3, 8)).progress

        assertEquals(8, bar.max)
        assertEquals(2, bar.progress)
        assertEquals(8, bar.segments.size)
        assertEquals(List(2) { Segment(1, FILLED_COLOR) } + List(6) { Segment(1, UNFILLED_COLOR) }, bar.segments)
    }

    @Test fun `unfilled is the fill at half alpha`() =
        assertEquals(0x80A449FF.toInt(), UNFILLED_COLOR)

    @Test fun `the first question has nothing filled`() {
        val bar = DiaryProgressFactory.contentFor(DiaryProgressState(1, 4)).progress
        assertTrue(bar.segments.all { it.color == UNFILLED_COLOR })
    }

    @Test fun `exactly the segment limit still gets one bar per question`() {
        val bar = DiaryProgressFactory.contentFor(DiaryProgressState(4, 10)).progress
        assertEquals(10, bar.segments.size)
    }

    @Test fun `past the segment limit, one filled and one unfilled bar`() {
        val bar = DiaryProgressFactory.contentFor(DiaryProgressState(4, 12)).progress
        assertEquals(listOf(Segment(3, FILLED_COLOR), Segment(9, UNFILLED_COLOR)), bar.segments)
    }

    @Test fun `an answered question points at the next one`() {
        val content = DiaryProgressFactory.contentFor(DiaryProgressState(3, 8, currentAnswered = true))

        assertEquals("Next question waiting", content.title)
        assertEquals("Q4 of 8", content.text)
        assertEquals(DiaryAction.ANSWER, content.action)
        assertEquals("Answer", content.action.label)
        assertEquals(DiaryArt.NEXT_QUESTION, content.art)
        assertEquals(3, content.progress.progress)
        assertEquals(
            List(3) { Segment(1, FILLED_COLOR) } + List(5) { Segment(1, UNFILLED_COLOR) },
            content.progress.segments,
        )
    }

    @Test fun `an answered last question has nothing waiting`() {
        val content = DiaryProgressFactory.contentFor(DiaryProgressState(8, 8, currentAnswered = true))

        assertEquals("Diary in progress", content.title)
        assertEquals("Q8 of 8", content.text)
        assertEquals(DiaryAction.CONTINUE, content.action)
    }

    @Test fun `out-of-range positions are not shown`() {
        assertFalse(DiaryProgressState(0, 8).isShowable)
        assertFalse(DiaryProgressState(9, 8).isShowable)
        assertFalse(DiaryProgressState(1, 0).isShowable)
        assertTrue(DiaryProgressState(8, 8).isShowable)
    }

    @Test fun `closes soon keeps the position and counts down in amber`() {
        val closesAt = 1_700_000_000_000L
        val content = DiaryProgressFactory.closingSoonContent(
            DiaryProgressState(6, 8), closesAt, isNightMode = false,
        )

        assertEquals("Diary closes soon", content.title)
        assertEquals("Q6 of 8", content.text)
        assertEquals(DiaryArt.CLOSES_SOON, content.art)
        assertEquals(DiaryAction.CONTINUE, content.action)
        assertEquals(closesAt, content.countdownToMillis)
        assertTrue(content.isLiveUpdate)

        val amber = DiaryProgressFactory.CLOSING_COLOR_LIGHT
        assertEquals(
            List(5) { Segment(1, amber) } + List(3) { Segment(1, halfAlpha(amber)) },
            content.progress.segments,
        )
    }

    @Test fun `closes soon is brighter amber in dark mode`() {
        val content = DiaryProgressFactory.closingSoonContent(
            DiaryProgressState(2, 4), 0L, isNightMode = true,
        )
        assertEquals(DiaryProgressFactory.CLOSING_COLOR_DARK, content.progress.segments.first().color)
    }

    @Test fun `closes soon on an answered question continues to the next`() {
        val content = DiaryProgressFactory.closingSoonContent(
            DiaryProgressState(3, 8, currentAnswered = true), 0L, isNightMode = false,
        )
        assertEquals("Q4 of 8", content.text)
        assertEquals("Continue", content.action.label)
        assertTrue(content.action.advances)
    }

    @Test fun `the other titles have no countdown`() {
        assertFalse(DiaryProgressFactory.contentFor(DiaryProgressState(3, 8)).isLiveUpdate)
    }

    @Test fun `the reminder fires 15 minutes before the close and lasts until it`() {
        val closesAt = 10_000_000L
        val reminder = DiaryClosingReminder(1, closesAt, DiaryProgressState(1, 2))

        assertEquals(closesAt - 15 * 60_000L, reminder.remindAtMillis)
        assertFalse(reminder.isClosingSoon(reminder.remindAtMillis - 1))
        assertTrue(reminder.isClosingSoon(reminder.remindAtMillis))
        assertTrue(reminder.isClosingSoon(closesAt - 1))
        assertFalse(reminder.isClosingSoon(closesAt))
    }
}
