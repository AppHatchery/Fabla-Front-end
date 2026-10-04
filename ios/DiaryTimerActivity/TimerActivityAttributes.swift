//
//  TimerActivityAttributes.swift
//  Shared between Runner and DiaryTimerActivityExtension.
//

import ActivityKit
import Foundation

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
