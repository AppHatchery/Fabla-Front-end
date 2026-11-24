package edu.emory.audio_diaries_flutter.features.recording.domain

import edu.emory.audio_diaries_flutter.core.domain.halfAlpha
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotificationFactory.CALL_COLOR_DARK
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotificationFactory.CALL_COLOR_LIGHT
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotificationFactory.FILLED_COLOR
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotificationFactory.LAST_FILLED_COLOR
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotificationFactory.LAST_UNFILLED_COLOR
import edu.emory.audio_diaries_flutter.features.recording.domain.RecordingNotificationFactory.PAUSED_FILLED_COLOR
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RecordingNotificationFactoryTest {

    private fun state(phase: RecordingPhase, elapsed: Int = 48, limit: Int = 300) = RecordingState(
        phase = phase,
        elapsedSeconds = elapsed,
        limitSeconds = limit,
        questionNumber = 3,
        questionCount = 8,
    )

    private fun content(phase: RecordingPhase, elapsed: Int = 48, limit: Int = 300, night: Boolean = false) =
        RecordingNotificationFactory.contentFor(state(phase, elapsed, limit), night)

    @Test fun `every phase round-trips its wire name`() {
        RecordingPhase.entries.forEach {
            assertEquals(it, RecordingPhase.fromWireName(it.wireName))
        }
        assertNull(RecordingPhase.fromWireName("nope"))
    }

    @Test fun `each phase has its title, text and action`() {
        val expected = mapOf(
            RecordingPhase.RECORDING to Triple("Recording", "Q3 of 8 · up to 5:00", RecordingAction.PAUSE),
            RecordingPhase.PAUSED to Triple("Paused", "0:48 so far · Q3 of 8", RecordingAction.RESUME),
            RecordingPhase.PAUSED_BY_CALL to Triple("Paused by a call", "0:48 so far · Q3 of 8", RecordingAction.RESUME),
            RecordingPhase.READY_TO_SAVE to Triple("Ready to save", "0:48 recorded · Q3 of 8", RecordingAction.SAVE),
            RecordingPhase.COULD_NOT_RESUME to Triple("Could not resume", "0:48 kept · Q3 of 8", RecordingAction.OPEN),
            RecordingPhase.SAVED to Triple("Saved", "0:48 kept · Q3 of 8", null),
            RecordingPhase.RECORDING_STOPPED to Triple("Recording stopped", "Nothing kept · Q3 of 8", RecordingAction.RECORD_AGAIN),
        )

        expected.forEach { (phase, triple) ->
            val content = content(phase)
            assertEquals(phase.name, triple.first, content.title)
            assertEquals(phase.name, triple.second, content.text)
            assertEquals(phase.name, triple.third, content.action)
        }
    }

    @Test fun `only recording captures and runs the chronometer`() {
        val recording = content(RecordingPhase.RECORDING)
        assertTrue(recording.isCapturing)
        assertEquals(48, recording.chronometerSeconds)

        val paused = content(RecordingPhase.PAUSED)
        assertFalse(paused.isCapturing)
        assertNull(paused.chronometerSeconds)
    }

    @Test fun `paused phases put Paused in the chip`() {
        assertEquals("Paused", content(RecordingPhase.PAUSED).chipText)
        assertEquals("Paused", content(RecordingPhase.PAUSED_BY_CALL).chipText)
        assertNull(content(RecordingPhase.RECORDING).chipText)
        assertNull(content(RecordingPhase.COULD_NOT_RESUME).chipText)
    }

    @Test fun `only in-progress phases are live updates with a bar`() {
        RecordingPhase.entries.forEach {
            val content = content(it)
            assertEquals(it.name, it.isLiveUpdate, content.isLiveUpdate)
            assertEquals(it.name, it.isLiveUpdate, content.progress != null)
        }
    }

    @Test fun `only problems alert`() {
        val alerting = RecordingPhase.entries.filter { content(it).alerts }
        assertEquals(listOf(RecordingPhase.COULD_NOT_RESUME, RecordingPhase.RECORDING_STOPPED), alerting)
    }

    @Test fun `no limit means no bar and no up-to text`() {
        val content = content(RecordingPhase.RECORDING, limit = 0)
        assertNull(content.progress)
        assertEquals("Q3 of 8", content.text)
    }

    @Test fun `recording bar is four quarters with an orange last one`() {
        // 300s split into 75s quarters; 48s in, so the first quarter is part filled.
        val segments = content(RecordingPhase.RECORDING).progress!!.segments

        assertEquals(48, segments[0].length)
        assertEquals(FILLED_COLOR, segments[0].color)
        assertEquals(halfAlpha(FILLED_COLOR), segments[1].color)
        assertEquals(LAST_UNFILLED_COLOR, segments.last().color)
        assertEquals(300, segments.sumOf { it.length })
    }

    @Test fun `a full recording bar ends orange`() {
        val segments = content(RecordingPhase.RECORDING, elapsed = 300).progress!!.segments
        assertEquals(LAST_FILLED_COLOR, segments.last().color)
    }

    @Test fun `paused uses the darker blue`() {
        val segments = content(RecordingPhase.PAUSED).progress!!.segments
        assertEquals(PAUSED_FILLED_COLOR, segments[0].color)
    }

    @Test fun `paused by a call is all orange, brighter in dark mode`() {
        val light = content(RecordingPhase.PAUSED_BY_CALL, elapsed = 300).progress!!.segments
        assertTrue(light.all { it.color == CALL_COLOR_LIGHT })

        val dark = content(RecordingPhase.PAUSED_BY_CALL, elapsed = 300, night = true).progress!!.segments
        assertTrue(dark.all { it.color == CALL_COLOR_DARK })

        val unfilled = content(RecordingPhase.PAUSED_BY_CALL, elapsed = 0).progress!!.segments
        assertTrue(unfilled.all { it.color == halfAlpha(CALL_COLOR_LIGHT) })
    }

    @Test fun `elapsed past the limit is clamped`() {
        assertNotNull(content(RecordingPhase.RECORDING, elapsed = 999).progress)
        assertEquals(300, content(RecordingPhase.RECORDING, elapsed = 999).progress!!.progress)
    }
}
