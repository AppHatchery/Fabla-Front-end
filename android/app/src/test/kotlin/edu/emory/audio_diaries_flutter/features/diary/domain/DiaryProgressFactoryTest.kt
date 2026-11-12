package edu.emory.audio_diaries_flutter.features.diary.domain

import edu.emory.audio_diaries_flutter.core.domain.Segment
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
        assertEquals("Continue", content.actionLabel)
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

    @Test fun `out-of-range positions are not shown`() {
        assertFalse(DiaryProgressState(0, 8).isShowable)
        assertFalse(DiaryProgressState(9, 8).isShowable)
        assertFalse(DiaryProgressState(1, 0).isShowable)
        assertTrue(DiaryProgressState(8, 8).isShowable)
    }
}
