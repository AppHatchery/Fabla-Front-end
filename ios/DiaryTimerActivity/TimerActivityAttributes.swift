//
//  TimerActivityAttributes.swift
//  Shared between Runner and DiaryTimerActivityExtension.
//

import ActivityKit
import Foundation
import AppIntents

@available(iOS 16.1, *)
struct DiaryTimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Live-ticking countdown target; nil while paused.
        var endDate: Date?
        // Frozen remaining time to display while paused.
        var pausedRemaining: TimeInterval?
    }

    var title: String
    // Fixed for the activity's lifetime — used by the expanded (long-press)
    // Dynamic Island view to render session length and overall progress.
    var totalDuration: TimeInterval
}

/// The diary recording Live Activity: one take of one audio answer.
@available(iOS 16.1, *)
struct DiaryRecordingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // When elapsed time would read 0:00 if the take had never paused, so
        // `Text(timerInterval:)` counts up on its own; nil while paused.
        var startDate: Date?
        // Frozen elapsed time to display while paused.
        var pausedElapsed: TimeInterval?
    }

    // "Q3 of 8"; both nil when the question's place isn't known.
    var questionNumber: Int?
    var questionCount: Int?
    // The answer's length limit; nil when the question has none.
    var limit: TimeInterval?
}

/// Bridges the Live Activity's button into the app process. AppDelegate sets
/// [togglePause]; the extension never does, so the intent is a no-op there.
@available(iOS 17.0, *)
enum RecordingIntentBridge {
    static var togglePause: (() async -> Void)?
}

/// Pause/resume from the Lock Screen or Dynamic Island, without opening Fabla.
/// Compiled into both targets so the system runs `perform` in the app.
///
/// `AudioRecordingIntent` is what lets resume work: once a take is paused the
/// app holds no live audio, and iOS refuses to start the microphone again from
/// the background for anything else, so the resumed half was never captured.
@available(iOS 18.0, *)
struct ToggleRecordingPauseIntent: LiveActivityIntent, AudioRecordingIntent {
    static var title: LocalizedStringResource = "Pause or resume recording"

    func perform() async throws -> some IntentResult {
        await RecordingIntentBridge.togglePause?()
        return .result()
    }
}
