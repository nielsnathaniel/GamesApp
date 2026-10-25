import SwiftUI
import UIKit

// MARK: - Touch Point Data Model
struct ActiveTouchPoint: Identifiable {
    let id: ObjectIdentifier
    var location: CGPoint
    var color: Color
    var touchIndex: Int
}

// MARK: - StartspelerKiezerView (SwiftUI Wrapper)
struct StartspelerKiezerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var touchPoints: [ActiveTouchPoint] = []
    @State private var winningTouchId: ObjectIdentifier? = nil
    @State private var countdownProgress: CGFloat = 0.0
    @State private var isCountingDown: Bool = false
    @State private var isFinished: Bool = false

    private let vibrantColors: [Color] = [
        Color(red: 0.18, green: 0.80, blue: 0.44), // Emerald
        Color(red: 0.20, green: 0.60, blue: 1.00), // Sky Blue
        Color(red: 1.00, green: 0.40, blue: 0.20), // Coral Orange
        Color(red: 0.70, green: 0.30, blue: 0.95), // Purple
        Color(red: 1.00, green: 0.80, blue: 0.10), // Sun Yellow
        Color(red: 0.10, green: 0.90, blue: 0.90), // Cyan
        Color(red: 1.00, green: 0.25, blue: 0.55), // Hot Pink
        Color(red: 0.55, green: 0.90, blue: 0.25)  // Lime
    ]

    var body: some View {
        ZStack {
            // Donkere moderne achtergrond voor maximaal contrast met de gloeiende ringen
            Color(red: 0.08, green: 0.09, blue: 0.13)
                .ignoresSafeArea()

            // Interactieve Multi-Touch Surface
            MultiTouchSurfaceRepresentable(
                touchPoints: $touchPoints,
                winningTouchId: winningTouchId,
                isFinished: isFinished,
                palette: vibrantColors,
                onTouchesChanged: handleTouchesChanged
            )
            .ignoresSafeArea()

            // Render Touch Visuals
            ForEach(touchPoints) { touch in
                TouchIndicatorView(
                    touch: touch,
                    isWinner: winningTouchId == touch.id,
                    isOtherWinnerChosen: isFinished && winningTouchId != touch.id,
                    countdownProgress: countdownProgress,
                    isCountingDown: isCountingDown
                )
                .position(touch.location)
            }

            // Instructie tekst of Winnaar Boodschap
            VStack {
                // Bovenbalk met Sluit-knop
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.yellow)
                            Text("Wie begint er?")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Text("Chwazi startspeler kiezer")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Button(action: {
                        HapticManager.shared.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Centrale instructie status
                VStack(spacing: 8) {
                    if isFinished {
                        VStack(spacing: 6) {
                            Text("🎉")
                                .font(.system(size: 54))
                            Text("JIJ BEGINT!")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow.opacity(0.6), radius: 10)
                            Text("Laat alle vingers los om opnieuw te kiezen")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(18)
                        .transition(.scale.combined(with: .opacity))
                    } else if isCountingDown {
                        VStack(spacing: 4) {
                            Text("Vingers stilhouden...")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("De startspeler wordt gekozen")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.45))
                        .cornerRadius(14)
                    } else if touchPoints.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "hand.raised.fingers.spread.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Plaats allemaal een vinger op het scherm")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Minimaal 2 vingers nodig")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(16)
                    } else if touchPoints.count == 1 {
                        Text("Nog minimaal 1 vinger erbij...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(12)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .statusBarHidden(true)
    }

    // MARK: - Touch Management & Countdown
    @State private var countdownTimer: Timer? = nil

    private func handleTouchesChanged() {
        if isFinished {
            // Als alles is losgelaten na afloop, reset naar begin
            if touchPoints.isEmpty {
                withAnimation(.spring()) {
                    isFinished = false
                    winningTouchId = nil
                    countdownProgress = 0.0
                    isCountingDown = false
                }
            }
            return
        }

        // Als er minder dan 2 vingers zijn, breek aftellen af
        if touchPoints.count < 2 {
            cancelCountdown()
            return
        }

        // Als aftellen nog niet loopt, start countdown
        if !isCountingDown {
            startCountdown()
        }
    }

    private func startCountdown() {
        cancelCountdown()
        isCountingDown = true
        countdownProgress = 0.0
        HapticManager.shared.light()

        let totalDuration: TimeInterval = 2.4
        let stepInterval: TimeInterval = 0.05
        let totalSteps = totalDuration / stepInterval
        var stepCount: Double = 0

        countdownTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            stepCount += 1
            countdownProgress = CGFloat(stepCount / totalSteps)

            // Tikjes naarmate de timer vordert
            if Int(stepCount) % 8 == 0 {
                HapticManager.shared.selection()
            }

            if stepCount >= totalSteps {
                timer.invalidate()
                finishSelection()
            }
        }
    }

    private func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountingDown = false
        countdownProgress = 0.0
    }

    private func finishSelection() {
        cancelCountdown()
        guard touchPoints.count >= 2 else { return }

        // Kies willekeurig 1 vinger
        if let winner = touchPoints.randomElement() {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                winningTouchId = winner.id
                isFinished = true
            }
            HapticManager.shared.celebration()
        }
    }
}

// MARK: - Touch Indicator View (Per Vinger)
struct TouchIndicatorView: View {
    let touch: ActiveTouchPoint
    let isWinner: Bool
    let isOtherWinnerChosen: Bool
    let countdownProgress: CGFloat
    let isCountingDown: Bool

    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            if isOtherWinnerChosen {
                // Uitdovende vinger
                Circle()
                    .stroke(touch.color.opacity(0.15), lineWidth: 2)
                    .frame(width: 80, height: 80)
            } else if isWinner {
                // Winnaar effect: gouden & kleurige stralende ring
                Circle()
                    .stroke(Color.yellow, lineWidth: 6)
                    .frame(width: 140, height: 140)
                    .shadow(color: .yellow, radius: 18)

                Circle()
                    .stroke(touch.color, lineWidth: 4)
                    .frame(width: 110, height: 110)
                    .shadow(color: touch.color.opacity(0.8), radius: 12)

                Circle()
                    .fill(Color.yellow.opacity(0.35))
                    .frame(width: 85, height: 85)

                Text("👑")
                    .font(.system(size: 32))
            } else {
                // Basis vinger cirkel
                Circle()
                    .fill(touch.color.opacity(0.25))
                    .frame(width: 85, height: 85)

                // Subtiele pulserende binnenring
                Circle()
                    .stroke(touch.color, lineWidth: 3)
                    .frame(width: 85, height: 85)
                    .shadow(color: touch.color.opacity(0.8), radius: 8)

                // Aftellende voortgangsring
                if isCountingDown {
                    Circle()
                        .trim(from: 0, to: countdownProgress)
                        .stroke(
                            touch.color,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 105, height: 105)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.05), value: countdownProgress)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - MultiTouch Surface Representable (UIKit)
struct MultiTouchSurfaceRepresentable: UIViewRepresentable {
    @Binding var touchPoints: [ActiveTouchPoint]
    var winningTouchId: ObjectIdentifier?
    var isFinished: Bool
    let palette: [Color]
    var onTouchesChanged: () -> Void

    func makeUIView(context: Context) -> MultiTouchTrackingView {
        let view = MultiTouchTrackingView()
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MultiTouchTrackingView, context: Context) {
        context.coordinator.palette = palette
        context.coordinator.isFinished = isFinished
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: MultiTouchTrackingDelegate {
        var parent: MultiTouchSurfaceRepresentable
        var palette: [Color]
        var isFinished: Bool = false
        private var touchColorMap: [ObjectIdentifier: Color] = [:]

        init(parent: MultiTouchSurfaceRepresentable) {
            self.parent = parent
            self.palette = parent.palette
        }

        func touchesUpdated(activeTouches: Set<UITouch>, in view: UIView) {
            guard !isFinished else {
                if activeTouches.isEmpty {
                    touchColorMap.removeAll()
                    parent.touchPoints = []
                    parent.onTouchesChanged()
                }
                return
            }

            var updatedPoints: [ActiveTouchPoint] = []
            var currentIds = Set<ObjectIdentifier>()

            for (index, touch) in activeTouches.enumerated() {
                let id = ObjectIdentifier(touch)
                currentIds.insert(id)
                let loc = touch.location(in: view)

                let color: Color
                if let existing = touchColorMap[id] {
                    color = existing
                } else {
                    let nextColor = palette[touchColorMap.count % palette.count]
                    touchColorMap[id] = nextColor
                    color = nextColor
                }

                updatedPoints.append(ActiveTouchPoint(
                    id: id,
                    location: loc,
                    color: color,
                    touchIndex: index
                ))
            }

            // Ruim verdwenen touches op
            touchColorMap = touchColorMap.filter { currentIds.contains($0.key) }

            DispatchQueue.main.async {
                self.parent.touchPoints = updatedPoints
                self.parent.onTouchesChanged()
            }
        }
    }
}

// MARK: - MultiTouch Tracking UIView
protocol MultiTouchTrackingDelegate: AnyObject {
    func touchesUpdated(activeTouches: Set<UITouch>, in view: UIView)
}

final class MultiTouchTrackingView: UIView {
    weak var delegate: MultiTouchTrackingDelegate?
    private var activeTouches: Set<UITouch> = []

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        activeTouches.formUnion(touches)
        delegate?.touchesUpdated(activeTouches: activeTouches, in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        delegate?.touchesUpdated(activeTouches: activeTouches, in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        activeTouches.subtract(touches)
        delegate?.touchesUpdated(activeTouches: activeTouches, in: self)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        activeTouches.subtract(touches)
        delegate?.touchesUpdated(activeTouches: activeTouches, in: self)
    }
}
