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
        // True when a call (or other audio interruption) paused the take.
        var interrupted: Bool?
        // True once the take has stopped and is waiting to be saved.
        var ready: Bool?
        // True on the final card once the answer is saved.
        var saved: Bool?
    }

    // "Q3 of 8"; both nil when the question's place isn't known.
    var questionNumber: Int?
    var questionCount: Int?
    // The answer's length limit; nil when the question has none.
    var limit: TimeInterval?
    // Where the recorder stops, which a suggestion is not; nil without one.
    // "One minute left" counts down to this.
    var hardLimit: TimeInterval?
}

/// Bridges the Live Activity's button into the app process. AppDelegate sets
/// [togglePause]; the extension never does, so the intent is a no-op there.
/// It throws when the toggle has to finish with the app in the foreground.
@available(iOS 18.0, *)
enum RecordingIntentBridge {
    static var togglePause: ((ToggleRecordingPauseIntent) async throws -> Void)?
    static var save: (() async -> Void)?
}

/// Saves a stopped take from the Lock Screen or Dynamic Island, as the
/// recording sheet's save button does. Runs in the app through the bridge.
@available(iOS 18.0, *)
struct SaveRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Save recording"
    func perform() async throws -> some IntentResult {
        await RecordingIntentBridge.save?()
        return .result()
    }
}

/// Brings Fabla to the front. After a call iOS won't let a background app
/// take the microphone back, so the take is resumed from the app instead.
@available(iOS 18.0, *)
struct OpenRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open Fabla to resume recording"
    static var openAppWhenRun = true
    func perform() async throws -> some IntentResult { .result() }
}

/// Pause/resume from the Lock Screen or Dynamic Island, without opening Fabla.
/// Compiled into both targets so the system runs `perform` in the app.
///
/// `AudioRecordingIntent` is what lets resume work: once a take is paused the
/// app holds no live audio, and iOS refuses to start the microphone again from
/// the background for anything else, so the resumed half was never captured.
@available(iOS 18.0, *)
///
/// Resuming after a call is the exception: the call took the audio session,
/// and iOS will not let a background app take it back. Then the intent asks
/// to continue in the foreground and resumes from there. That needs
/// `ForegroundContinuableIntent`, which extensions can't use, so AppDelegate
/// adds it and throws the request from the bridge.
struct ToggleRecordingPauseIntent: LiveActivityIntent, AudioRecordingIntent {
    static var title: LocalizedStringResource = "Pause or resume recording"

    func perform() async throws -> some IntentResult {
        try await RecordingIntentBridge.togglePause?(self)
        return .result()
    }
}
