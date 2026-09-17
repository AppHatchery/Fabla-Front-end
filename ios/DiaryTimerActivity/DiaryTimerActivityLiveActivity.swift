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
    // No leading zero on minutes — matches Text(timerInterval:)'s own m:ss
    // style, so the paused and running numbers are the same width and don't
    // jump when switching between them.
    return String(format: "%d:%02d", total / 60, total % 60)
}

@available(iOS 16.1, *)
private func sessionLengthLabel(_ seconds: TimeInterval) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return secs == 0 ? "\(mins) min session" : "\(mins)m \(secs)s session"
}

// MARK: - Shared pieces

/// Rounded-square "thumbnail" badge standing in for a photo — same rounding
/// language as the app icon — holding a status glyph (timer/pause/checkmark).
@available(iOS 16.1, *)
private struct StatusBadge: View {
    let context: ActivityViewContext<DiaryTimerActivityAttributes>
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous).fill(.white)
            // AppMark is the real app-icon mark (cropped from the App Store icon,
            // background removed) — a constant "brand" badge, same idea as the
            // reference's photo thumbnail that doesn't change either. State
            // (running/paused/done) reads from the ring + text next to it, not
            // from the badge itself — except completion, which swaps in the
            // app's own check_circle mark for a satisfying "done" moment.
            Image(context.isTimeUp ? "CompleteMark" : "AppMark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(size * (context.isTimeUp ? 0.04 : 0.16))
        }
        .frame(width: size, height: size)
    }
}

/// The right-side "big number" readout (optionally paired with a slim ring),
/// ticking natively while running (system-driven, no app process required).
@available(iOS 16.1, *)
private struct CountdownReadout: View {
    let context: ActivityViewContext<DiaryTimerActivityAttributes>
    var numberSize: CGFloat = 30
    var ringSize: CGFloat = 24
    var showCaption = true
    var showRing = true
    // White on the Lock Screen's blue gradient (for contrast), the app's own
    // brand blue everywhere else (the Dynamic Island's black canvas).
    var accentColor: Color = .diaryBrand

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 1) {
                // `Text(timerInterval:)` has a confirmed, currently-unresolved
                // SwiftUI/WidgetKit bug: it ignores trailing alignment and always
                // renders its digits anchored to the leading edge of whatever box
                // it's given (see https://developer.apple.com/forums/thread/758531 —
                // an Apple DTS engineer confirms there's no fix). The best-known
                // mitigation (per https://developer.apple.com/forums/thread/723316)
                // is multilineTextAlignment + lineLimit + minimumScaleFactor paired
                // with a frame tuned close to the actual rendered width — not a
                // guarantee, but it gets close for our mm:ss range.
                numberText
                    .frame(width: numberSize * 2.2, alignment: .trailing)
                if showCaption {
                    Text(context.isTimeUp ? "session done" : (context.state.endDate == nil ? "paused" : "remaining"))
                        .font(.rubik(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            if showRing {
                ring
            }
        }
    }

    @ViewBuilder
    private var numberText: some View {
        if context.isTimeUp {
            Text("Done")
                .font(.rubik(.semibold, size: numberSize * 0.7))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        } else if let endDate = context.state.endDate {
            Text(timerInterval: Date()...endDate, countsDown: true)
                .font(.rubik(.medium, size: numberSize))
                .monospacedDigit()
                .foregroundStyle(accentColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        } else {
            Text(formatRemaining(context.state.pausedRemaining ?? 0))
                .font(.rubik(.medium, size: numberSize))
                .monospacedDigit()
                .foregroundStyle(accentColor.opacity(0.7))
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    @ViewBuilder
    private var ring: some View {
        if context.isTimeUp {
            Image("CompleteMark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: ringSize, height: ringSize)
        } else if let endDate = context.state.endDate {
            ProgressView(timerInterval: Date()...endDate, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(accentColor)
            .frame(width: ringSize, height: ringSize)
        } else {
            Circle()
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 2)
                .frame(width: ringSize, height: ringSize)
        }
    }
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

            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    StatusBadge(context: context)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.isTimeUp ? "Time's Up!" : context.attributes.title)
                            .font(.rubik(.semibold, size: 17))
                            .foregroundStyle(.white)
                        Text(subtitle)
                            .font(.rubik(.regular, size: 13))
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    Spacer(minLength: 8)

                    CountdownReadout(context: context, showRing: false, accentColor: .white)
                }

                TimerProgressBar(context: context, tint: .white)
                    .frame(height: 4)
            }
            .padding(16)
        }
    }

    private var subtitle: String {
        if context.isTimeUp { return "Tap to return to your diary" }
        if context.state.endDate == nil { return "Paused" }
        return sessionLengthLabel(context.attributes.totalDuration)
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
            .tint(Color.diaryBrand)
        } else {
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(Color.diaryBrand)
        }
    }
}

/// Native ticking bar while running (system-driven, no app process needed —
/// same mechanism as `Text(timerInterval:)`); a plain static fill while paused.
/// Shared by the Lock Screen (white tint, for contrast on the blue gradient)
/// and the Dynamic Island (brand blue, on its black canvas).
@available(iOS 16.1, *)
private struct TimerProgressBar: View {
    let context: ActivityViewContext<DiaryTimerActivityAttributes>
    var tint: Color = .diaryBrand

    var body: some View {
        if let endDate = context.state.endDate {
            let start = endDate.addingTimeInterval(-context.attributes.totalDuration)
            ProgressView(timerInterval: start...endDate, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(tint)
        } else {
            let total = context.attributes.totalDuration
            let remaining = context.state.pausedRemaining ?? total
            let fraction = total > 0 ? max(0, min(1, (total - remaining) / total)) : 0
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.22))
                    Capsule().fill(tint).frame(width: geo.size.width * fraction)
                }
            }
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
                    StatusBadge(context: context)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // The title, session length and countdown all sit on one row here
                    // (rather than split across .leading/.trailing either side of the
                    // TrueDepth camera) because that row has too little width beside
                    // the camera for the title + session-length text, which otherwise
                    // clips silently. Below the camera there's the full island width
                    // to lay all three out on a single line.
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(context.isTimeUp ? "Time's Up!" : context.attributes.title)
                                    .font(.rubik(.semibold, size: 16))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(context.isTimeUp ? "Tap to return" : sessionLengthLabel(context.attributes.totalDuration))
                                    .font(.rubik(.regular, size: 12))
                                    .foregroundStyle(.white.opacity(0.55))
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            CountdownReadout(context: context, numberSize: 26, showRing: false)
                        }
                        TimerProgressBar(context: context)
                            .frame(height: 4)
                    }
                    .padding(.vertical, 8)
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
