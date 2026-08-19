//
//  DiaryTimerActivityLiveActivity.swift
//  DiaryTimerActivity
//

import ActivityKit
import WidgetKit
import SwiftUI

// Mirrors lib/theme/custom_colors.dart / the in-app timer sheet's gradient.
@available(iOS 16.1, *)
private extension Color {
    static let diaryBrand = Color(red: 0x43 / 255, green: 0x96 / 255, blue: 0xFE / 255) // productNormal #4396FE
    static let diaryGradientTop = Color(red: 0x41 / 255, green: 0x86 / 255, blue: 0xF5 / 255) // #4186F5
    static let diaryGradientBottom = Color(red: 0x62 / 255, green: 0x6A / 255, blue: 0xD9 / 255) // #626AD9
}

@available(iOS 16.1, *)
private extension Font {
    static func rubik(_ weight: Font.Weight, size: CGFloat) -> Font {
        switch weight {
        case .semibold: return .custom("Rubik-SemiBold", size: size)
        case .medium: return .custom("Rubik-Medium", size: size)
        default: return .custom("Rubik-Regular", size: size)
        }
    }
}

@available(iOS 16.1, *)
private extension ActivityViewContext<DiaryTimerActivityAttributes> {
    /// AppDelegate sets `staleDate` to the countdown's `endDate` (and to nil while
    /// paused), so the system itself flips `isStale` true the instant the countdown
    /// reaches zero — no app process needs to be running for this to happen. Plain
    /// `Date()` comparisons in a view body would NOT refresh on their own; `isStale`
    /// (like `Text(timerInterval:)`) is one of the few properties WidgetKit re-renders
    /// on a system-driven schedule.
    var isTimeUp: Bool { isStale }
}

@available(iOS 16.1, *)
private func formatRemaining(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    return String(format: "%02d:%02d", total / 60, total % 60)
}

// MARK: - Lock Screen / Banner

@available(iOS 16.1, *)
private struct LockScreenView: View {
    let context: ActivityViewContext<DiaryTimerActivityAttributes>

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.diaryGradientTop, .diaryGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(spacing: 14) {
                badge

                if context.isTimeUp {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Time's Up!")
                            .font(.rubik(.semibold, size: 22))
                            .foregroundStyle(.white)
                        Text("Tap to return to your diary")
                            .font(.rubik(.regular, size: 13))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.attributes.title)
                            .font(.rubik(.regular, size: 13))
                            .foregroundStyle(.white.opacity(0.8))
                        countdown
                            .font(.rubik(.medium, size: 32))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var badge: some View {
        ZStack {
            Circle().fill(.white)
            if context.isTimeUp {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.diaryBrand)
            } else if let endDate = context.state.endDate {
                ProgressView(timerInterval: Date()...endDate, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(.diaryBrand)
                .padding(6)
            } else {
                Image(systemName: "pause.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.diaryBrand)
            }
        }
        .frame(width: 44, height: 44)
    }

    @ViewBuilder
    private var countdown: some View {
        if let endDate = context.state.endDate {
            Text(timerInterval: Date()...endDate, countsDown: true)
        } else {
            Text(formatRemaining(context.state.pausedRemaining ?? 0))
        }
    }
}

// MARK: - Dynamic Island

@available(iOS 16.1, *)
private struct DynamicIslandLeadingIcon: View {
    let context: ActivityViewContext<DiaryTimerActivityAttributes>

    var body: some View {
        if context.isTimeUp {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.diaryBrand)
        } else if let endDate = context.state.endDate {
            ProgressView(timerInterval: Date()...endDate, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(.diaryBrand)
        } else {
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(Color.diaryBrand)
        }
    }
}

@available(iOS 16.1, *)
struct DiaryTimerActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DiaryTimerActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DynamicIslandLeadingIcon(context: context)
                        .frame(width: 28, height: 28)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.isTimeUp {
                        Text("Done")
                            .font(.rubik(.semibold, size: 16))
                            .foregroundStyle(Color.diaryBrand)
                    } else if let endDate = context.state.endDate {
                        Text(timerInterval: Date()...endDate, countsDown: true)
                            .font(.rubik(.medium, size: 16))
                            .monospacedDigit()
                    } else {
                        Text(formatRemaining(context.state.pausedRemaining ?? 0))
                            .font(.rubik(.medium, size: 16))
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.isTimeUp ? "Time's Up! Tap to return to your diary" : context.attributes.title)
                        .font(.rubik(.regular, size: 12))
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                DynamicIslandLeadingIcon(context: context)
            } compactTrailing: {
                if context.isTimeUp {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.diaryBrand)
                } else if let endDate = context.state.endDate {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 42)
                } else {
                    Text(formatRemaining(context.state.pausedRemaining ?? 0))
                        .monospacedDigit()
                        .frame(width: 42)
                }
            } minimal: {
                DynamicIslandLeadingIcon(context: context)
            }
            .keylineTint(.diaryBrand)
        }
    }
}
