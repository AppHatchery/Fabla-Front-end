//
//  DiaryTimerActivityLiveActivity.swift
//  DiaryTimerActivity
//
//  The meditation timer Live Activity, built from the Figma "Meditation
//  timer" frame (Fabla Live Activities iOS, node 4336:28200). The Lock Screen
//  uses its "Alternate 1" look. Positions below are that frame's, in points.
//  Fabio's kit pieces (Part, FabioArt, StatusDot…) are shared with
//  DiaryRecordingLiveActivity.swift.
//

import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

@available(iOS 17.0, *)
private extension Color {
    static let timerCard = Color(red: 0x62 / 255, green: 0x6A / 255, blue: 0xD9 / 255) // #626AD9
    static let timerAccent = Color(red: 0x7C / 255, green: 0x83 / 255, blue: 0xF0 / 255) // #7C83F0
    static let pausedTimerCard = Color(red: 0x42 / 255, green: 0x47 / 255, blue: 0x91 / 255) // #424791
    static let timeUpCard = Color(red: 0xD2 / 255, green: 0x6B / 255, blue: 0x00 / 255) // #D26B00
    static let timeUpAccent = Color(red: 0xF5 / 255, green: 0x92 / 255, blue: 0x41 / 255) // #F59241
    static let pausedTimerDot = Color(red: 0xB0 / 255, green: 0xB4 / 255, blue: 0xEC / 255) // #B0B4EC
}

@available(iOS 17.0, *)
private extension Font {
    static func rubik(_ weight: Font.Weight, size: CGFloat) -> Font {
        switch weight {
        case .semibold: return .custom("Rubik-SemiBold", size: size)
        case .medium: return .custom("Rubik-Medium", size: size)
        default: return .custom("Rubik-Regular", size: size)
        }
    }
}

@available(iOS 17.0, *)
private func formatRemaining(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    // No leading zero on minutes, like Text(timerInterval:), so the paused
    // and running numbers don't jump in width between them.
    return String(format: "%d:%02d", total / 60, total % 60)
}

// MARK: - State

@available(iOS 17.0, *)
private extension ActivityViewContext<DiaryTimerActivityAttributes> {
    /// AppDelegate sets `staleDate` to the countdown's `endDate` (nil while
    /// paused), so the system flips `isStale` the instant it reaches zero,
    /// with no app process running.
    var isTimeUp: Bool { isStale }

    var isPaused: Bool { !isTimeUp && state.endDate == nil }

    var label: String {
        if isTimeUp { return "Time's up" }
        return isPaused ? "Meditation paused" : "Meditation timer"
    }

    /// The Lock Screen card: darker while paused, orange once time is up.
    var card: Color {
        if isTimeUp { return .timeUpCard }
        return isPaused ? .pausedTimerCard : .timerCard
    }

    /// The colour on black: the island, Always-On, the rings.
    var accent: Color { isTimeUp ? .timeUpAccent : .timerAccent }

    /// The session's full length, shown once it's done.
    var totalLabel: String { formatRemaining(attributes.totalDuration) }

    var canPause: Bool { attributes.canPause == true && !isTimeUp }

    /// "Q5 of 8", or nil when the question's place isn't known.
    var questionLabel: String? {
        guard let n = attributes.questionNumber, let count = attributes.questionCount else { return nil }
        return "Q\(n) of \(count)"
    }

    /// The span the island ring fills over while running.
    var runInterval: ClosedRange<Date>? {
        guard !isTimeUp, let end = state.endDate else { return nil }
        return end.addingTimeInterval(-attributes.totalDuration)...end
    }

    /// The frozen fill while paused, or full once done.
    var frozenFraction: Double {
        if isTimeUp { return 1 }
        let total = attributes.totalDuration
        guard total > 0 else { return 0 }
        return min(1, max(0, (total - (state.pausedRemaining ?? total)) / total))
    }
}

// MARK: - Fabio

/// Fabio on the Lock Screen: "Alternate 1", in his meditation robe with the
/// singing bowl, in the card's 408x160 frame.
@available(iOS 17.0, *)
private enum TimerLockArt {
    static let size = CGSize(width: 408, height: 160)
    static let parts = parts(paused: false)
    /// Paused: the neutral face, and a wave of the paw.
    static let pausedParts = parts(paused: true)

    private static func parts(paused: Bool) -> [Part] {
        let f = CGRect(x: 303.43, y: 43.29, width: 117.039, height: 128.901)
        var parts = [
            part("TimerLockBody", f, Insets.body),
            part("TimerLockRobe", f, (48.71, 0.81, 0.99, 0.57)),
            paused ? part("TimerPausedLockFace", f, Insets.faceNeutral) : part("TimerLockFace", f, Insets.face),
            part("TimerLockBowl", CGRect(x: 262.67, y: 117.1, width: 59.402, height: 46.115),
                 (4.13, 3.95, 5.08, 3.83)),
        ]
        if paused {
            // The wave paw's 41.122pt box, centred in its 49.795pt rotated slot.
            parts.append(part("TimerPausedLockPawWave", CGRect(x: 292.337, y: 68.457, width: 41.122, height: 41.122),
                              (11.94, 10.2, 9.31, 11.96), rotation: -13.9))
        }
        return parts
    }
}

/// Time up, on the Lock Screen's first design rather than "Alternate 1":
/// Fabio surprised, holding up the table clock.
@available(iOS 17.0, *)
private enum TimeUpLockArt {
    static let size = CGSize(width: 408, height: 160)
    static let parts: [Part] = {
        let f = CGRect(x: 235.27, y: 15.6, width: 234.078, height: 257.802)
        // Each rotated part's own box, centred in the slot Figma rotates it in.
        return [
            part("TimeUpLockBody", f, Insets.body, mirrored: true),
            part("TimeUpLockFace", f, (29.37, 33.88, 54.72, 51.38), mirrored: true),
            part("TimeUpLockPaw", CGRect(x: 227.922, y: 104.492, width: 82.244, height: 82.244),
                 Insets.holdingPaw, rotation: 6),
            part("TimeUpLockClock", CGRect(x: 247.259, y: 73.045, width: 51.814, height: 66.617),
                 (1.85, -1.9, 1.85, 2.38), mirrored: true, rotation: 6),
        ]
    }()
}

/// Fabio whole, for the expanded island's bottom-trailing corner: holding the
/// bowl in both paws.
@available(iOS 17.0, *)
private enum TimerIslandArt {
    static let size = CGSize(width: 73.507, height: 80.957)
    static let parts = parts(paused: false)
    /// Paused: the neutral face, the bowl lowered a little.
    static let pausedParts = parts(paused: true)

    /// Time up: surprised, holding the table clock. The paw starts 3.63pt
    /// left of his frame.
    static let timeUpSize = CGSize(width: 77.99, height: 81.897)
    static let timeUpParts: [Part] = {
        let f = CGRect(x: 3.63, y: 0, width: 74.36, height: 81.897)
        return [
            part("ReadyIslandBody", f, Insets.body, mirrored: true),
            part("TimeUpIslandFace", f, (29.37, 33.88, 54.72, 51.38), mirrored: true),
            part("ReadyIslandPaw", CGRect(x: 1.29, y: 28.24, width: 26.127, height: 26.127),
                 Insets.holdingPaw, rotation: 6),
            part("TimeUpIslandClock", CGRect(x: 7.44, y: 18.25, width: 16.46, height: 21.162),
                 (1.85, -1.9, 1.85, 2.38), mirrored: true, rotation: 6),
        ]
    }()

    private static func parts(paused: Bool) -> [Part] {
        let f = CGRect(origin: .zero, size: size)
        let drop: CGFloat = paused ? 2.93 : 0
        return [
            part("TimerIslandBody", f, Insets.body, mirrored: true),
            part("TimerIslandRobe", f, (48.71, 0.81, 0.99, 0.57), mirrored: true),
            paused
                ? part("TimerPausedIslandFace", f, Insets.faceNeutral, mirrored: true)
                : part("TimerIslandFace", f, Insets.face, mirrored: true),
            part("TimerIslandBowl", CGRect(x: 20.11, y: 32.63 + drop, width: 26.423, height: 20.512),
                 (4.13, 3.95, 5.08, 3.83), mirrored: true),
            part("TimerIslandPawFar", CGRect(x: 30.84, y: 30.49 + drop, width: 25.827, height: 25.827), Insets.holdingPaw),
            part("TimerIslandPawNear", CGRect(x: 13.45, y: 30.49 + drop, width: 25.827, height: 25.827),
                 (22.64, 29.59, 15.11, 7.06)),
        ]
    }
}

/// Fabio's face in a circle, for the compact (18pt) and minimal (20pt) rings.
@available(iOS 17.0, *)
private struct TimerAvatar: View {
    let minimal: Bool
    var paused = false
    var timeUp = false

    var body: some View {
        let d: CGFloat = minimal ? 20 : 18
        let f = minimal
            ? CGRect(x: -26.52, y: -15.65, width: 64.348, height: 70.87)
            : CGRect(x: -23.87, y: -14.09, width: 57.913, height: 63.783)
        let size = minimal ? "Minimal" : "Compact"
        let parts = timeUp
            // Robe off and surprised: the session's over.
            ? [part("Rec\(size)Body", f, Insets.body),
               part("TimeUp\(size)Face", f, (29.37, 33.88, 54.72, 51.38))]
            : [part("Rec\(size)Body", f, Insets.body),
               part("Timer\(size)Robe", f, (48.71, 0.81, 0.99, 0.57)),
               paused
                   ? part("TimerPaused\(size)Face", f, Insets.faceNeutral)
                   : part("Timer\(size)Face", f, Insets.face)]
        FabioArt(parts: parts, size: CGSize(width: d, height: d))
        .background(timeUp ? Color.timeUpCard : Color.timerCard)
        .clipShape(Circle())
    }
}

// MARK: - Shared pieces

/// Pause while running, resume while paused. Hidden for timers without
/// playback controls, and once time is up.
@available(iOS 17.0, *)
private struct TimerPauseButton: View {
    enum Style { case filled(Color, glyph: Color), outlined(Color) }

    let context: ActivityViewContext<DiaryTimerActivityAttributes>
    let style: Style

    var body: some View {
        Button(intent: ToggleTimerPauseIntent()) {
            ZStack {
                switch style {
                case let .filled(fill, _): Circle().fill(fill)
                case let .outlined(stroke): Circle().strokeBorder(stroke, lineWidth: 2)
                }
                if context.isPaused {
                    PlayGlyph().fill(glyphColor)
                } else {
                    HStack(spacing: 6) {
                        Capsule().frame(width: 5, height: 16)
                        Capsule().frame(width: 5, height: 16)
                    }
                    .foregroundStyle(glyphColor)
                }
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(context.isPaused ? "Resume timer" : "Pause timer")
    }

    private var glyphColor: Color {
        switch style {
        case let .filled(_, glyph): return glyph
        case let .outlined(stroke): return stroke
        }
    }
}

/// Time up: a check that brings Fabla back to finish the entry.
@available(iOS 17.0, *)
private struct TimeUpButton: View {
    let fill: Color?
    let glyph: Color

    var body: some View {
        Button(intent: OpenRecordingIntent()) {
            ZStack {
                if let fill {
                    Circle().fill(fill)
                } else {
                    Circle().strokeBorder(glyph, lineWidth: 2)
                }
                CheckGlyph()
                    .stroke(glyph, style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Fabla")
    }
}

/// "Q5 of 8" over a bar that fills as the timer runs: system-driven while
/// running, frozen while paused, full once time is up.
@available(iOS 17.0, *)
private struct QuestionProgress: View {
    let context: ActivityViewContext<DiaryTimerActivityAttributes>
    let ink: Color
    let fill: Color
    let trackOpacity: Double

    @ViewBuilder
    private var bar: some View {
        if let interval = context.runInterval {
            ProgressView(timerInterval: interval, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(fill)
            // Stretch the system bar to the 8pt track, then give it the
            // track's full size before it is masked, as WaveformProgress does.
            .scaleEffect(x: 1, y: 3, anchor: .center)
            .frame(width: 116, height: 8)
        } else {
            GeometryReader { geo in
                fill.frame(width: geo.size.width * context.frozenFraction)
            }
        }
    }

    var body: some View {
        if let label = context.questionLabel {
            VStack(alignment: .leading, spacing: 5) {
                Text(label)
                    .font(.rubik(.medium, size: 13))
                    .foregroundStyle(ink.opacity(0.7))
                    .frame(height: 16)
                ZStack(alignment: .leading) {
                    Capsule().fill(fill.opacity(trackOpacity))
                    bar.mask(Capsule().frame(width: 116, height: 8))
                }
                .frame(width: 116, height: 8)
            }
        }
    }
}

/// Time left, ticking natively while running.
@available(iOS 17.0, *)
private struct RemainingText: View {
    let context: ActivityViewContext<DiaryTimerActivityAttributes>

    var body: some View {
        if context.isTimeUp {
            Text(formatRemaining(0))
        } else if let end = context.state.endDate {
            Text(timerInterval: Date()...end, countsDown: true)
        } else {
            Text(formatRemaining(context.state.pausedRemaining ?? 0))
        }
    }
}

/// The island's ring around Fabio: system-driven while running.
@available(iOS 17.0, *)
private struct TimerRing: View {
    let context: ActivityViewContext<DiaryTimerActivityAttributes>
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(context.accent.opacity(0.35), lineWidth: 2.5)
                .padding(1.25)
            if let interval = context.runInterval {
                ProgressView(timerInterval: interval, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(context.accent)
            } else {
                Circle()
                    .trim(from: 0, to: context.frozenFraction)
                    .stroke(context.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                    .padding(1.25)
            }
            TimerAvatar(minimal: diameter > 26, paused: context.isPaused, timeUp: context.isTimeUp)
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: - Lock Screen

@available(iOS 17.0, *)
private struct TimerLockScreenView: View {
    let context: ActivityViewContext<DiaryTimerActivityAttributes>
    @Environment(\.isLuminanceReduced) private var isAlwaysOn

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                StatusDot(color: isAlwaysOn ? context.accent : (context.isPaused ? .pausedTimerDot : .white))
                Text(context.label)
                    .font(.rubik(.medium, size: 15))
                    .foregroundStyle(.white.opacity(0.7))
                // Time up moves the question up here, as its bar is gone.
                if context.isTimeUp, let q = context.questionLabel {
                    Text("· \(q)")
                        .font(.rubik(.medium, size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer(minLength: 8)
                Text("Fabla")
                    .font(.rubik(.medium, size: 15))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(height: 18)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Group {
                    if context.isTimeUp { Text(context.totalLabel) } else { RemainingText(context: context) }
                }
                    .font(.rubik(.semibold, size: 46))
                    .tracking(-1.5)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(width: 112, height: 55, alignment: .leading)
                Text(context.isTimeUp ? "/ \(context.totalLabel)" : "left")
                    .font(.rubik(.medium, size: 15))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 4)
            .padding(.leading, -1)

            HStack(alignment: .bottom, spacing: 14) {
                if context.isTimeUp {
                    TimeUpButton(fill: isAlwaysOn ? nil : .white,
                                 glyph: isAlwaysOn ? .timeUpAccent : .timeUpCard)
                } else if context.canPause {
                    TimerPauseButton(context: context, style: isAlwaysOn
                                     ? .outlined(.timerAccent)
                                     : .filled(.white, glyph: context.card))
                }
                if !context.isTimeUp {
                QuestionProgress(context: context,
                                 ink: .white,
                                 fill: isAlwaysOn ? .timerAccent : .white,
                                 trackOpacity: isAlwaysOn ? 0.25 : 0.24)
                    .padding(.bottom, 8)
                }
            }
            .frame(height: 40, alignment: .bottomLeading)
            .padding(.top, 7)
        }
        .padding(.leading, 24.5)
        .padding(.trailing, 34)
        .padding(.top, 18.5)
        .padding(.bottom, 17.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .frame(height: 160)
        // A background never sizes its view, so the 408pt art can't widen the
        // card past the Lock Screen's width; it's cropped instead.
        .background(alignment: .bottomTrailing) {
            FabioArt(parts: context.isTimeUp ? TimeUpLockArt.parts
                        : context.isPaused ? TimerLockArt.pausedParts : TimerLockArt.parts,
                     size: TimerLockArt.size)
                .opacity(isAlwaysOn ? 0.5 : 1)
        }
        .background(isAlwaysOn ? Color.black : context.card)
        .clipped()
    }
}

// MARK: - Widget

@available(iOS 17.0, *)
struct DiaryTimerActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DiaryTimerActivityAttributes.self) { context in
            TimerLockScreenView(context: context)
                .activityBackgroundTint(context.card)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Group {
                        if context.isTimeUp { Text(context.totalLabel) } else { RemainingText(context: context) }
                    }
                        .font(.rubik(.semibold, size: 34))
                        .tracking(-1.5)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .frame(width: 96, alignment: .leading)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    FablaMark()
                        .padding(.trailing, 8)
                        .padding(.top, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            StatusDot(color: context.accent)
                            Text(context.label)
                                .font(.rubik(.medium, size: 15))
                                .foregroundStyle(.white.opacity(0.7))
                            if context.isTimeUp, let q = context.questionLabel {
                                Text("· \(q)")
                                    .font(.rubik(.medium, size: 15))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .lineLimit(1)
                        .padding(.trailing, 84)
                        HStack(alignment: .bottom, spacing: 14) {
                            if context.isTimeUp {
                                TimeUpButton(fill: .timeUpAccent, glyph: .white)
                            } else {
                                if context.canPause {
                                    TimerPauseButton(context: context, style: .filled(.timerAccent, glyph: .white))
                                }
                                QuestionProgress(context: context, ink: .white, fill: .timerAccent, trackOpacity: 0.24)
                                    .padding(.bottom, 8)
                            }
                        }
                        .frame(height: 40, alignment: .bottomLeading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // An overlay, so the art's box never adds to the region's
                    // height: the expanded island draws nothing when too tall.
                    .overlay(alignment: .bottomTrailing) {
                        Group {
                            if context.isTimeUp {
                                FabioArt(parts: TimerIslandArt.timeUpParts, size: TimerIslandArt.timeUpSize)
                            } else {
                                FabioArt(parts: context.isPaused ? TimerIslandArt.pausedParts : TimerIslandArt.parts,
                                         size: TimerIslandArt.size)
                            }
                        }
                            .allowsHitTesting(false)
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                RemainingText(context: context)
                    .font(.rubik(.medium, size: 15))
                    .monospacedDigit()
                    .foregroundStyle(context.accent)
                    .frame(maxWidth: 44)
            } compactTrailing: {
                TimerRing(context: context, diameter: 26)
            } minimal: {
                TimerRing(context: context, diameter: 28)
            }
            .keylineTint(context.accent.opacity(0.6))
            .contentMargins(.bottom, 12, for: .expanded)
        }
    }
}
