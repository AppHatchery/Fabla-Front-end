//
//  DiaryProgressLiveActivity.swift
//  DiaryTimerActivity
//
//  "Diary in progress": a diary the participant left part-way, built from
//  the Figma frame (Fabla Live Activities iOS, node 4336:27755). The Lock
//  Screen uses its "Alternate 1" look. Positions below are that frame's, in
//  points. Fabio's kit pieces (Part, FabioArt, StatusDot…) are shared with
//  DiaryRecordingLiveActivity.swift.
//

import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

@available(iOS 17.0, *)
private extension Color {
    static let diaryCard = Color(red: 0xA4 / 255, green: 0x49 / 255, blue: 0xFF / 255) // #A449FF
    static let closingCard = Color(red: 0xFE / 255, green: 0xB9 / 255, blue: 0x54 / 255) // #FEB954
    static let closingInk = Color(red: 0x24 / 255, green: 0x24 / 255, blue: 0x24 / 255) // #242424
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
private extension ActivityViewContext<DiaryProgressActivityAttributes> {
    var question: Int { state.questionNumber }
    var count: Int { attributes.questionCount }
    /// The last 15 minutes before the diary closes. AppDelegate makes the
    /// activity go stale then, so this flips with no app running.
    var isClosingSoon: Bool { isStale && attributes.closesAt != nil }
    var isWaiting: Bool { !isClosingSoon && state.waiting == true }
    var label: String {
        if isClosingSoon { return "Diary closes soon" }
        return isWaiting ? "Next question waiting" : "Diary in progress"
    }

    /// The card, and the colour on black.
    var card: Color { isClosingSoon ? .closingCard : .diaryCard }
    /// Text on the card: dark on the orange one.
    var ink: Color { isClosingSoon ? .closingInk : .white }

    /// The questions before this one, for the island ring.
    var doneFraction: Double {
        guard count > 0 else { return 0 }
        return min(1, max(0, Double(question - 1) / Double(count)))
    }
}

// MARK: - Fabio

/// Fabio on the Lock Screen: "Alternate 1", in his safari helmet, waving.
@available(iOS 17.0, *)
private enum DiaryLockArt {
    static let size = CGSize(width: 408, height: 160)
    static let parts: [Part] = {
        let f = CGRect(x: 266.94, y: 41.93, width: 163.31, height: 179.862)
        return [
            // The wave paw's 57.379pt box, centred in its 69.555pt rotated slot.
            part("DiaryLockPawWave", CGRect(x: 254.458, y: 79.238, width: 57.379, height: 57.379),
                 (11.94, 10.2, 9.31, 11.96), rotation: -14),
            part("RecV2Body", f, Insets.body, mirrored: true),
            part("DiaryLockFace", f, (33.9, 35.46, 55.34, 52.99), mirrored: true),
            part("DiaryLockHelmet", f, (1.47, 18.92, 67.18, 5.41), mirrored: true),
        ]
    }()
}

/// Diary closes soon: concerned, in the coach's cap, holding the table clock.
@available(iOS 17.0, *)
private enum ClosingLockArt {
    static let parts: [Part] = {
        let f = CGRect(x: 266.94, y: 41.93, width: 163.31, height: 179.862)
        // Each rotated part's own box, centred in the slot Figma rotates it in.
        return [
            part("RecV2Body", f, Insets.body, mirrored: true),
            part("ClosingLockFace", f, Insets.faceConcerned, mirrored: true),
            part("OneMinV2Cap", f, (7.98, 20.1, 64.97, 17.02), mirrored: true),
            part("OneMinV2Paw", CGRect(x: 246.301, y: 120.011, width: 57.379, height: 57.379),
                 Insets.holdingPaw, rotation: 6),
            part("ClosingLockClock", CGRect(x: 258.429, y: 93.53, width: 39.393, height: 50.648),
                 (1.85, -1.9, 1.85, 2.38), mirrored: true, rotation: 6),
        ]
    }()
}

/// Next question waiting: the conductor, holding out the ticket.
@available(iOS 17.0, *)
private enum NextLockArt {
    static let parts: [Part] = {
        let f = CGRect(x: 266.94, y: 41.93, width: 163.31, height: 179.862)
        // Each rotated part's own box, centred in the slot Figma rotates it in.
        return [
            part("RecV2Body", f, Insets.body, mirrored: true),
            part("NextLockJacket", f, (48.71, 0.81, 0.99, 0.57), mirrored: true),
            part("NextLockFace", f, (33.9, 35.46, 55.34, 52.99), mirrored: true),
            part("NextLockCap", f, (9.73, 28.04, 67.05, 16.34), mirrored: true),
            part("OneMinV2Paw", CGRect(x: 244.931, y: 108.801, width: 57.379, height: 57.379),
                 Insets.holdingPaw, rotation: 6),
            part("NextLockTicket", CGRect(x: 249.063, y: 101.184, width: 53.407, height: 31.559),
                 (7.69, 2.27, 2.31, 4.55), rotation: 6),
        ]
    }()
}

/// Fabio whole, for the expanded island's corner: in his glasses, waving.
/// The wave paw starts 5.5pt left of his frame.
@available(iOS 17.0, *)
private enum DiaryIslandArt {
    static let size = CGSize(width: 79.86, height: 81.897)
    static let parts: [Part] = {
        let f = CGRect(x: 5.5, y: 0, width: 74.36, height: 81.897)
        return [
            part("DiaryIslandPawWave", CGRect(x: 2.772, y: 10.582, width: 26.127, height: 26.127),
                 (11.94, 10.2, 9.31, 11.96), rotation: -14),
            part("ReadyIslandBody", f, Insets.body, mirrored: true),
            part("ReadyIslandFace", f, Insets.faceTalking, mirrored: true),
            part("DiaryIslandGlasses", f, (0, 0, 0, 0), mirrored: true),
        ]
    }()

    /// Diary closes soon: Fabio holding up the "15 MIN" cue card.
    static let closingSize = CGSize(width: 74.36, height: 81.897)
    static let closingParts: [Part] = {
        let f = CGRect(origin: .zero, size: closingSize)
        var card = part("ClosingIslandCard", CGRect(x: 4.753, y: 19.117, width: 21.705, height: 16.882),
                        Insets.cueCard, rotation: 4)
        card.caption = .init(text: "15 MIN", origin: CGPoint(x: 2.81, y: 5.98), size: 4.823)
        return [
            part("ReadyIslandBody", f, Insets.body, mirrored: true),
            part("ReadyIslandFace", f, Insets.faceTalking, mirrored: true),
            part("ReadyIslandPaw", CGRect(x: 1.84, y: 24.52, width: 26.127, height: 26.127),
                 Insets.holdingPaw, rotation: 4),
            card,
        ]
    }()

    /// Next question waiting: Fabio asking, with a "?" speech bubble. The
    /// bubble starts 0.77pt left of his frame.
    static let nextSize = CGSize(width: 75.13, height: 81.897)
    static let nextParts: [Part] = {
        let f = CGRect(x: 0.77, y: 0, width: 74.36, height: 81.897)
        var bubble = part("NextIslandBubble", CGRect(x: 0.423, y: 18.75, width: 23.953, height: 12.935),
                          (3.7, 2, -2.59, 2), rotation: -4)
        bubble.caption = .init(text: "?", origin: CGPoint(x: 10.54, y: 2.43), size: 4.791)
        return [
            part("ReadyIslandBody", f, Insets.body, mirrored: true),
            part("ReadyIslandFace", f, Insets.faceTalking, mirrored: true),
            bubble,
        ]
    }()
}

/// Fabio's face in his glasses, for the compact (18pt) and minimal (20pt)
/// rings.
@available(iOS 17.0, *)
private struct DiaryAvatar: View {
    let minimal: Bool
    var waiting = false
    var closing = false

    var body: some View {
        let d: CGFloat = minimal ? 20 : 18
        let f = minimal
            ? CGRect(x: -26.52, y: -15.65, width: 64.348, height: 70.87)
            : CGRect(x: -23.87, y: -14.09, width: 57.913, height: 63.783)
        let size = minimal ? "Minimal" : "Compact"
        var parts = [
            part("Rec\(size)Body", f, Insets.body),
            part("OneMin\(size)Face", f, Insets.faceTalking),
        ]
        // Glasses off while the next question waits, or the diary closes.
        if !waiting && !closing { parts.append(part("Diary\(size)Glasses", f, (0, 0, 0, 0))) }
        return FabioArt(parts: parts, size: CGSize(width: d, height: d))
        .background(closing ? Color.closingCard : Color.diaryCard)
        .clipShape(Circle())
    }
}

// MARK: - Shared pieces

/// The Figma arrow in the 40pt open button.
@available(iOS 17.0, *)
private struct ArrowGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 40
        var p = Path()
        p.move(to: CGPoint(x: 13.5 * s, y: 20 * s))
        p.addLine(to: CGPoint(x: 26 * s, y: 20 * s))
        p.move(to: CGPoint(x: 21 * s, y: 14.5 * s))
        p.addLine(to: CGPoint(x: 26.5 * s, y: 20 * s))
        p.addLine(to: CGPoint(x: 21 * s, y: 25.5 * s))
        return p
    }
}

/// Brings Fabla back to the open diary.
@available(iOS 17.0, *)
private struct OpenButton: View {
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
                ArrowGlyph()
                    .stroke(glyph, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue diary")
    }
}

/// One segment per question: answered ones solid, the open one half, the
/// rest faint. 116pt across with 4pt gaps, as in the frame.
@available(iOS 17.0, *)
private struct QuestionSegments: View {
    let context: ActivityViewContext<DiaryProgressActivityAttributes>
    let ink: Color

    var body: some View {
        let count = max(1, context.count)
        let width = max(2, (116 - 4 * CGFloat(count - 1)) / CGFloat(count))
        HStack(spacing: 4) {
            ForEach(1...count, id: \.self) { n in
                Capsule()
                    .fill(ink.opacity(opacity(for: n)))
                    .frame(width: width, height: 8)
            }
        }
        .frame(width: 116, height: 8, alignment: .leading)
    }

    private func opacity(for n: Int) -> Double {
        if n < context.question { return 1 }
        return n == context.question ? 0.55 : 0.24
    }
}

@available(iOS 17.0, *)
private struct DiaryRing: View {
    let context: ActivityViewContext<DiaryProgressActivityAttributes>
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(context.card.opacity(0.35), lineWidth: 2.5)
                .padding(1.25)
            Circle()
                .trim(from: 0, to: context.doneFraction)
                .stroke(context.card, style: StrokeStyle(lineWidth: 2.5, lineCap: .butt))
                .rotationEffect(.degrees(-90))
                .padding(1.25)
            DiaryAvatar(minimal: diameter > 26, waiting: context.isWaiting, closing: context.isClosingSoon)
        }
        .frame(width: diameter, height: diameter)
    }
}

/// The time until the diary closes, counting down natively; "0:00" once
/// it has.
@available(iOS 17.0, *)
private struct ClosesInText: View {
    let context: ActivityViewContext<DiaryProgressActivityAttributes>

    var body: some View {
        if let closesAt = context.attributes.closesAt, closesAt > Date() {
            Text(timerInterval: Date()...closesAt, countsDown: true)
        } else {
            Text("0:00")
        }
    }
}

/// "Q6 of 8" over the segments, for the closing-soon layout, where the big
/// number is the countdown instead.
@available(iOS 17.0, *)
private struct LabelledSegments: View {
    let context: ActivityViewContext<DiaryProgressActivityAttributes>
    let ink: Color
    let text: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Q\(context.question) of \(context.count)")
                .font(.rubik(.medium, size: 13))
                .foregroundStyle(text.opacity(0.7))
                .frame(height: 16)
            QuestionSegments(context: context, ink: ink)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Lock Screen

@available(iOS 17.0, *)
private struct DiaryLockScreenView: View {
    let context: ActivityViewContext<DiaryProgressActivityAttributes>
    @Environment(\.isLuminanceReduced) private var isAlwaysOn

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                StatusDot(color: isAlwaysOn ? context.card : ink)
                Text(context.label)
                    .font(.rubik(.medium, size: 15))
                    .foregroundStyle(ink.opacity(0.7))
                Spacer(minLength: 8)
                Text("Fabla")
                    .font(.rubik(.medium, size: 15))
                    .foregroundStyle(ink.opacity(0.7))
            }
            .frame(height: 18)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Group {
                    if closing {
                        ClosesInText(context: context)
                            .monospacedDigit()
                            .frame(width: 128, alignment: .leading)
                    } else {
                        Text("Q\(context.question)")
                    }
                }
                .font(.rubik(.semibold, size: 46))
                .tracking(-1.5)
                .foregroundStyle(ink)
                .frame(height: 55)
                Text(closing ? "left" : "of \(context.count)")
                    .font(.rubik(.medium, size: 15))
                    .foregroundStyle(ink.opacity(0.5))
            }
            .padding(.top, 4)
            .padding(.leading, -1)

            HStack(alignment: closing ? .bottom : .center, spacing: 14) {
                OpenButton(fill: isAlwaysOn ? nil : (closing ? .closingInk : .white),
                           glyph: context.card)
                if closing {
                    LabelledSegments(context: context, ink: isAlwaysOn ? context.card : ink, text: ink)
                } else {
                    QuestionSegments(context: context, ink: isAlwaysOn ? context.card : ink)
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
            FabioArt(parts: closing ? ClosingLockArt.parts
                        : context.isWaiting ? NextLockArt.parts : DiaryLockArt.parts,
                     size: DiaryLockArt.size)
                .opacity(isAlwaysOn ? 0.5 : 1)
        }
        .background(isAlwaysOn ? Color.black : context.card)
        .clipped()
    }

    private var closing: Bool { context.isClosingSoon }
    private var ink: Color { isAlwaysOn ? .white : context.ink }
}

// MARK: - Widget

@available(iOS 17.0, *)
struct DiaryProgressLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DiaryProgressActivityAttributes.self) { context in
            DiaryLockScreenView(context: context)
                .activityBackgroundTint(context.card)
                .activitySystemActionForegroundColor(context.ink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Group {
                        if context.isClosingSoon {
                            ClosesInText(context: context)
                                .monospacedDigit()
                                .frame(width: 96, alignment: .leading)
                        } else {
                            Text("Q\(context.question)")
                        }
                    }
                    .font(.rubik(.semibold, size: 34))
                    .tracking(-1.5)
                    .foregroundStyle(.white)
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
                            StatusDot(color: context.card)
                            Text(context.label)
                                .font(.rubik(.medium, size: 15))
                                .foregroundStyle(.white.opacity(0.7))
                            if !context.isClosingSoon {
                                Text("· \(context.count) questions")
                                    .font(.rubik(.medium, size: 15))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.trailing, 84)
                        HStack(alignment: context.isClosingSoon ? .bottom : .center, spacing: 14) {
                            OpenButton(fill: context.card, glyph: .white)
                            if context.isClosingSoon {
                                LabelledSegments(context: context, ink: context.card, text: .white)
                            } else {
                                QuestionSegments(context: context, ink: context.card)
                            }
                        }
                        .frame(height: 40, alignment: .bottomLeading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // An overlay, so the art's box never adds to the region's
                    // height: the expanded island draws nothing when too tall.
                    .overlay(alignment: .bottomTrailing) {
                        Group {
                            if context.isClosingSoon {
                                FabioArt(parts: DiaryIslandArt.closingParts, size: DiaryIslandArt.closingSize)
                            } else if context.isWaiting {
                                FabioArt(parts: DiaryIslandArt.nextParts, size: DiaryIslandArt.nextSize)
                            } else {
                                FabioArt(parts: DiaryIslandArt.parts, size: DiaryIslandArt.size)
                            }
                        }
                            .allowsHitTesting(false)
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                Group {
                    if context.isClosingSoon {
                        ClosesInText(context: context)
                    } else {
                        Text("\(context.question)/\(context.count)")
                    }
                }
                .font(.rubik(.medium, size: 15))
                .monospacedDigit()
                .foregroundStyle(context.card)
                .frame(maxWidth: 44)
            } compactTrailing: {
                DiaryRing(context: context, diameter: 26)
            } minimal: {
                DiaryRing(context: context, diameter: 28)
            }
            .keylineTint(context.card.opacity(0.6))
            .contentMargins(.bottom, 12, for: .expanded)
        }
    }
}
