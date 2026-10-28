//
//  DiaryRecordingLiveActivity.swift
//  DiaryTimerActivity
//
//  The diary recording Live Activity, built from the Figma "Recording" frame
//  (Fabla Live Activities iOS, node 4336:27413). Positions below are that
//  frame's, in points.
//

import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

@available(iOS 17.0, *)
private extension Color {
    static let recordingCard = Color(red: 0x01 / 255, green: 0x6B / 255, blue: 0xEF / 255) // #016BEF
    static let recordingBrand = Color(red: 0x43 / 255, green: 0x96 / 255, blue: 0xFE / 255) // #4396FE
    static let recordingDot = Color(red: 0xF8 / 255, green: 0x34 / 255, blue: 0x48 / 255) // #F83448
    static let pausedCard = Color(red: 0x01 / 255, green: 0x47 / 255, blue: 0xA0 / 255) // #0147A0
    static let pausedDot = Color(red: 0x8E / 255, green: 0xC0 / 255, blue: 0xFE / 255) // #8EC0FE
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
private func formatElapsed(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    return String(format: "%d:%02d", total / 60, total % 60)
}

// MARK: - State

@available(iOS 17.0, *)
private extension ActivityViewContext<DiaryRecordingActivityAttributes> {
    var isPaused: Bool { state.startDate == nil }

    /// "Q3 of 8", or nil when the question's place isn't known.
    var questionLabel: String? {
        guard let n = attributes.questionNumber, let count = attributes.questionCount else { return nil }
        return "Q\(n) of \(count)"
    }

    var limitLabel: String? { attributes.limit.flatMap { $0 > 0 ? formatElapsed($0) : nil } }

    /// The span the waveform and ring fill over. Without a limit there is
    /// nothing to fill toward, so callers show them full.
    var fillInterval: ClosedRange<Date>? {
        guard let start = state.startDate, let limit = attributes.limit, limit > 0 else { return nil }
        return start...start.addingTimeInterval(limit)
    }

    /// The frozen fill while paused.
    var pausedFraction: Double {
        guard let limit = attributes.limit, limit > 0 else { return 1 }
        return min(1, (state.pausedElapsed ?? 0) / limit)
    }
}

// MARK: - Fabio

/// One Fabio kit part: an SVG laid into its part frame, inset by the
/// percentages the Figma instance gives (top, right, bottom, left).
///
/// [mirrored] flips the part across its frame, as the paused frames' Figma
/// instances do, and [rotation] turns it about its own centre.
@available(iOS 17.0, *)
private struct Part {
    let image: String
    let frame: CGRect
    let inset: (t: CGFloat, r: CGFloat, b: CGFloat, l: CGFloat)
    var mirrored = false
    var rotation: Double = 0

    var rect: CGRect {
        let r = CGRect(x: frame.minX + frame.width * inset.l / 100,
                       y: frame.minY + frame.height * inset.t / 100,
                       width: frame.width * (100 - inset.l - inset.r) / 100,
                       height: frame.height * (100 - inset.t - inset.b) / 100)
        guard mirrored else { return r }
        return CGRect(x: frame.minX + frame.maxX - r.maxX, y: r.minY, width: r.width, height: r.height)
    }
}

@available(iOS 17.0, *)
private struct FabioArt: View {
    let parts: [Part]
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(parts.indices, id: \.self) { i in
                let rect = parts[i].rect
                Image(parts[i].image)
                    .resizable()
                    .frame(width: rect.width, height: rect.height)
                    .scaleEffect(x: parts[i].mirrored ? -1 : 1, y: 1)
                    .rotationEffect(.degrees(parts[i].rotation))
                    .offset(x: rect.minX, y: rect.minY)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
    }
}

@available(iOS 17.0, *)
private enum Insets {
    static let headsetFar: (CGFloat, CGFloat, CGFloat, CGFloat) = (8.62, 29.93, 65.95, 15.61)
    static let body: (CGFloat, CGFloat, CGFloat, CGFloat) = (13.5, 1.92, 1.98, 1.72)
    static let face: (CGFloat, CGFloat, CGFloat, CGFloat) = (35.2, 34.38, 56.67, 51.88)
    static let headsetNearBoom: (CGFloat, CGFloat, CGFloat, CGFloat) = (19.8, 47.59, 50.41, 7.92)
    static let headsetNear: (CGFloat, CGFloat, CGFloat, CGFloat) = (19.8, 73.83, 54.87, 7.92)
    static let faceNeutral: (CGFloat, CGFloat, CGFloat, CGFloat) = (33.9, 35.46, 56.35, 52.99)
}

@available(iOS 17.0, *)
private func part(_ image: String, _ frame: CGRect, _ inset: (CGFloat, CGFloat, CGFloat, CGFloat),
                  mirrored: Bool = false, rotation: Double = 0) -> Part {
    Part(image: image, frame: frame, inset: (inset.0, inset.1, inset.2, inset.3),
         mirrored: mirrored, rotation: rotation)
}

/// Fabio on the Lock Screen: the Figma frame's "Alternate 1" look, laid out
/// in the card's 408x160 frame and anchored to its bottom-trailing corner.
@available(iOS 17.0, *)
private enum LockArt {
    static let size = CGSize(width: 408, height: 160)

    /// Paused: the same look turned to face the take, holding the kept tape.
    static let pausedParts: [Part] = {
        let f = CGRect(x: 266.94, y: 41.93, width: 163.31, height: 179.862)
        let tape = CGRect(x: 281.56, y: 117.46, width: 63.448, height: 43.145)
        return [
            part("RecV2HeadsetFar", f, Insets.headsetFar, mirrored: true),
            part("RecV2Body", f, Insets.body, mirrored: true),
            part("PausedV2KnitSweater", f, (48.44, 0.81, 0.99, 0.57), mirrored: true),
            part("PausedV2Face", f, Insets.faceNeutral, mirrored: true),
            part("PausedV2HeadsetNear", f, Insets.headsetNear, mirrored: true),
            part("PausedV2KeptTape", tape, (2.94, -1.2, -2.94, 2), mirrored: true),
            part("PausedV2PawFar", CGRect(x: 315.05, y: 117.96, width: 57.379, height: 57.379), (22.64, 7.06, 15.11, 29.59)),
            part("PausedV2PawNear", CGRect(x: 254.14, y: 117.96, width: 57.379, height: 57.379), (22.64, 29.59, 15.11, 7.06)),
        ]
    }()

    static let parts: [Part] = {
        let f = CGRect(x: 266.94, y: 41.93, width: 163.31, height: 179.862)
        return [
            part("RecV2HeadsetFar", f, Insets.headsetFar),
            part("RecV2Body", f, Insets.body),
            part("RecV2Cardigan", f, (48.55, 0.81, 0.99, 0.57)),
            part("RecV2BowTie", f, (48.42, 29.52, 43.14, 48.44)),
            part("RecV2Face", f, Insets.face),
            part("RecV2HeadsetNearBoom", f, Insets.headsetNearBoom),
        ]
    }()
}

/// Fabio whole, for the expanded island's bottom-trailing corner.
@available(iOS 17.0, *)
private enum IslandArt {
    // Just Fabio's own frame, so the art can sit in the island's corner.
    static let size = CGSize(width: 70.306, height: 77.431)
    static let parts: [Part] = {
        let f = CGRect(origin: .zero, size: size)
        return [
            part("RecIslandHeadsetFar", f, Insets.headsetFar),
            part("RecIslandBody", f, Insets.body),
            part("RecIslandFace", f, Insets.face),
            part("RecIslandHeadsetNearBoom", f, Insets.headsetNearBoom),
        ]
    }()

    /// Paused: Fabio turned around, waving. The wave paw pokes 4.34pt past
    /// his frame on the left, so this canvas is that much wider.
    static let pausedSize = CGSize(width: 74.646, height: 77.431)
    static let pausedParts: [Part] = {
        let f = CGRect(x: 4.34, y: 0, width: 70.306, height: 77.431)
        // The wave paw's 24.702pt box, centred in its 29.944pt rotated slot.
        let paw = CGRect(x: 2.621, y: 12.791, width: 24.702, height: 24.702)
        return [
            part("RecIslandHeadsetFar", f, Insets.headsetFar, mirrored: true),
            part("PausedIslandPawWave", paw, (11.94, 10.2, 9.31, 11.96), rotation: -14),
            part("RecIslandBody", f, Insets.body, mirrored: true),
            part("PausedIslandFace", f, Insets.faceNeutral, mirrored: true),
            part("PausedIslandHeadsetNear", f, Insets.headsetNear, mirrored: true),
        ]
    }()
}

/// Fabio's face in a blue circle, for the compact (18pt) and minimal (20pt)
/// island rings.
@available(iOS 17.0, *)
private struct FabioAvatar: View {
    let minimal: Bool
    let isPaused: Bool

    var body: some View {
        let d: CGFloat = minimal ? 20 : 18
        let prefix = minimal ? "RecMinimal" : "RecCompact"
        let f = minimal
            ? CGRect(x: -26.52, y: -15.65, width: 64.348, height: 70.87)
            : CGRect(x: -23.87, y: -14.09, width: 57.913, height: 63.783)
        let face = isPaused
            ? part(minimal ? "PausedMinimalFace" : "PausedCompactFace", f, Insets.faceNeutral)
            : part("\(prefix)Face", f, Insets.face)
        FabioArt(parts: [
            part("\(prefix)HeadsetFar", f, Insets.headsetFar),
            part("\(prefix)Body", f, Insets.body),
            face,
            part("\(prefix)HeadsetNear", f, Insets.headsetNear),
        ], size: CGSize(width: d, height: d))
        .background(isPaused ? Color.pausedCard : Color.recordingCard)
        .clipShape(Circle())
    }
}

// MARK: - Shared pieces

/// The status dot: a 2pt ring around an 8pt dot, 16pt overall. Red while
/// recording, blue while paused.
@available(iOS 17.0, *)
private struct StatusDot: View {
    var color: Color = .recordingDot

    var body: some View {
        ZStack {
            Circle().stroke(color, lineWidth: 2).frame(width: 14, height: 14)
            Circle().fill(color).frame(width: 8, height: 8)
        }
        .frame(width: 16, height: 16)
    }
}

/// The Figma resume glyph: a rounded play triangle in the 40pt button.
@available(iOS 17.0, *)
private struct PlayGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 40
        var p = Path()
        p.move(to: CGPoint(x: 15.5 * s, y: 11.8 * s))
        p.addCurve(to: CGPoint(x: 14 * s, y: 12.8 * s),
                   control1: CGPoint(x: 14.5 * s, y: 11.2667 * s), control2: CGPoint(x: 14 * s, y: 11.6 * s))
        p.addLine(to: CGPoint(x: 14 * s, y: 27.2 * s))
        p.addCurve(to: CGPoint(x: 15.5 * s, y: 28.2 * s),
                   control1: CGPoint(x: 14 * s, y: 28.4 * s), control2: CGPoint(x: 14.5 * s, y: 28.7333 * s))
        p.addLine(to: CGPoint(x: 28.2 * s, y: 21.1 * s))
        p.addCurve(to: CGPoint(x: 28.2 * s, y: 18.9 * s),
                   control1: CGPoint(x: 29.1333 * s, y: 20.3667 * s), control2: CGPoint(x: 29.1333 * s, y: 19.6333 * s))
        p.closeSubpath()
        return p
    }
}

/// The one button: pause while recording, resume while paused.
@available(iOS 17.0, *)
private struct PauseButton: View {
    enum Style { case filled(Color, glyph: Color), outlined(Color) }

    let isPaused: Bool
    let style: Style

    var body: some View {
        Button(intent: ToggleRecordingPauseIntent()) {
            ZStack {
                switch style {
                case let .filled(fill, _):
                    Circle().fill(fill)
                case let .outlined(stroke):
                    Circle().strokeBorder(stroke, lineWidth: 2)
                }
                glyph
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPaused ? "Resume recording" : "Pause recording")
    }

    private var glyphColor: Color {
        switch style {
        case let .filled(_, glyph): return glyph
        case let .outlined(stroke): return stroke
        }
    }

    @ViewBuilder
    private var glyph: some View {
        if isPaused {
            PlayGlyph().fill(glyphColor)
        } else {
            HStack(spacing: 6) {
                Capsule().frame(width: 5, height: 16)
                Capsule().frame(width: 5, height: 16)
            }
            .foregroundStyle(glyphColor)
        }
    }
}

/// Twelve 3pt bars that fill left to right over the take's limit. The fill is
/// a system-driven `ProgressView(timerInterval:)` masked to the bars, so it
/// keeps sweeping with no app process running.
@available(iOS 17.0, *)
private struct WaveformProgress: View {
    let context: ActivityViewContext<DiaryRecordingActivityAttributes>
    let filled: Color
    let unfilled: Color

    private static let heights: [CGFloat] = [8, 14, 22, 12, 18, 26, 16, 10, 20, 14, 8, 12]

    var body: some View {
        ZStack {
            bars.foregroundStyle(unfilled)
            fill.mask(bars)
        }
        .frame(width: 69, height: 26)
    }

    private var bars: some View {
        HStack(spacing: 3) {
            ForEach(Self.heights.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 10).frame(width: 3, height: Self.heights[i])
            }
        }
    }

    @ViewBuilder
    private var fill: some View {
        if let interval = context.fillInterval {
            ProgressView(timerInterval: interval, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(filled)
            // Stretch the bar to the waveform's height so the mask covers it.
            .scaleEffect(x: 1, y: 26 / 4, anchor: .center)
        } else {
            GeometryReader { geo in
                filled.frame(width: geo.size.width * context.pausedFraction)
            }
        }
    }
}

/// The island's ring around Fabio: system-driven while recording, frozen
/// while paused.
@available(iOS 17.0, *)
private struct RingProgress: View {
    let context: ActivityViewContext<DiaryRecordingActivityAttributes>
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.recordingBrand.opacity(0.35), lineWidth: 2.5)
                .padding(1.25)
            if let interval = context.fillInterval {
                ProgressView(timerInterval: interval, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(.recordingBrand)
            } else {
                Circle()
                    .trim(from: 0, to: context.pausedFraction)
                    .stroke(Color.recordingBrand, style: StrokeStyle(lineWidth: 2.5, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                    .padding(1.25)
            }
            FabioAvatar(minimal: diameter > 26, isPaused: context.isPaused)
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Elapsed time, ticking natively while recording.
@available(iOS 17.0, *)
private struct ElapsedText: View {
    let context: ActivityViewContext<DiaryRecordingActivityAttributes>

    var body: some View {
        if let start = context.state.startDate {
            // Upper bound far enough out that it never stops the count first.
            let limit = context.attributes.limit.flatMap { $0 > 0 ? $0 : nil } ?? 24 * 3600
            Text(timerInterval: start...start.addingTimeInterval(limit), countsDown: false)
        } else {
            Text(formatElapsed(context.state.pausedElapsed ?? 0))
        }
    }
}

@available(iOS 17.0, *)
private struct StatusLabel: View {
    let context: ActivityViewContext<DiaryRecordingActivityAttributes>

    var body: some View {
        Text(context.isPaused ? "Paused" : "Recording")
            .font(.rubik(.medium, size: 15))
            .foregroundStyle(.white.opacity(0.7))
    }
}

@available(iOS 17.0, *)
private struct DetailLabel: View {
    let text: String

    var body: some View {
        Text("· \(text)")
            .font(.rubik(.medium, size: 15))
            .foregroundStyle(.white.opacity(0.5))
    }
}

// MARK: - Lock Screen

@available(iOS 17.0, *)
private struct RecordingLockScreenView: View {
    let context: ActivityViewContext<DiaryRecordingActivityAttributes>
    @Environment(\.isLuminanceReduced) private var isAlwaysOn

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    StatusDot(color: context.isPaused ? (isAlwaysOn ? .recordingBrand : .pausedDot) : .recordingDot)
                    StatusLabel(context: context)
                    if let q = context.questionLabel { DetailLabel(text: q) }
                    Spacer(minLength: 8)
                    Text("Fabla")
                        .font(.rubik(.medium, size: 15))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(height: 18)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    ElapsedText(context: context)
                        .font(.rubik(.semibold, size: 46))
                        .tracking(-1.5)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .frame(width: 112, height: 55, alignment: .leading)
                    if let limit = context.limitLabel {
                        Text("/ \(limit)")
                            .font(.rubik(.medium, size: 15))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.top, 4)
                .padding(.leading, -1)

                HStack(spacing: 14) {
                    PauseButton(isPaused: context.isPaused,
                                style: isAlwaysOn ? .outlined(.recordingBrand) : .filled(.white, glyph: cardColor))
                    // Nothing is filling while paused, so the paused frame drops it.
                    if !context.isPaused {
                        WaveformProgress(context: context,
                                         filled: isAlwaysOn ? .recordingBrand : .white,
                                         unfilled: (isAlwaysOn ? Color.recordingBrand : .white).opacity(0.35))
                    }
                }
                .padding(.top, 7)
            }
            .padding(.leading, 24.5)
            .padding(.trailing, 34)
            .padding(.top, 18.5)
            .padding(.bottom, 17.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .frame(height: 160)
        // Backgrounds never size their view, so the 408pt art can't widen
        // the card past the Lock Screen's width; it's cropped instead.
        .background(alignment: .bottomTrailing) {
            FabioArt(parts: context.isPaused ? LockArt.pausedParts : LockArt.parts, size: LockArt.size)
                .opacity(isAlwaysOn ? 0.5 : 1)
        }
        .background(isAlwaysOn ? Color.black : cardColor)
        .clipped()
    }

    private var cardColor: Color { context.isPaused ? .pausedCard : .recordingCard }
}

// MARK: - Dynamic Island

@available(iOS 17.0, *)
private struct FablaMark: View {
    var body: some View {
        // The app's own mark, as the meditation timer's activity uses it.
        Image("AppMark")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
    }
}

@available(iOS 17.0, *)
struct DiaryRecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DiaryRecordingActivityAttributes.self) { context in
            RecordingLockScreenView(context: context)
                .activityBackgroundTint(.recordingCard)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ElapsedText(context: context)
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
                                StatusDot(color: context.isPaused ? .recordingBrand : .recordingDot)
                                StatusLabel(context: context)
                                if let q = context.questionLabel { DetailLabel(text: q) }
                                if let limit = context.limitLabel { DetailLabel(text: "up to \(limit)") }
                            }
                            HStack(spacing: 14) {
                                PauseButton(isPaused: context.isPaused,
                                            style: .filled(.recordingBrand, glyph: .white))
                                if !context.isPaused {
                                    WaveformProgress(context: context,
                                                     filled: .recordingBrand,
                                                     unfilled: .recordingBrand.opacity(0.35))
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // An overlay, so the art's 104pt box never adds to the
                    // region's height: the expanded island caps out at 160pt
                    // and draws nothing at all when its content is taller.
                    .overlay(alignment: .bottomTrailing) {
                        Group {
                            if context.isPaused {
                                FabioArt(parts: IslandArt.pausedParts, size: IslandArt.pausedSize)
                            } else {
                                FabioArt(parts: IslandArt.parts, size: IslandArt.size)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                ElapsedText(context: context)
                    .font(.rubik(.medium, size: 15))
                    .monospacedDigit()
                    .foregroundStyle(Color.recordingBrand)
                    .frame(maxWidth: 44)
            } compactTrailing: {
                RingProgress(context: context, diameter: 26)
            } minimal: {
                RingProgress(context: context, diameter: 28)
            }
            .keylineTint(Color.recordingBrand.opacity(0.6))
            // Less than the default bottom margin, or the pause row is cut off.
            .contentMargins(.bottom, 12, for: .expanded)
        }
    }
}
