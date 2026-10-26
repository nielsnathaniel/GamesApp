import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var vx: CGFloat
    var vy: CGFloat
    var rotation: Double
    var rotationSpeed: Double
    var isCircle: Bool
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var opacity: Double = 1.0

    private let colors: [Color] = [
        Color(red: 1.00, green: 0.84, blue: 0.00), // Goud
        Color(red: 1.00, green: 0.35, blue: 0.20), // Koraal
        Color(red: 0.20, green: 0.70, blue: 1.00), // Blauw
        Color(red: 0.20, green: 0.85, blue: 0.45), // Groen
        Color(red: 0.85, green: 0.25, blue: 0.85), // Magenta
        Color(red: 1.00, green: 0.60, blue: 0.00), // Oranje
        Color(red: 0.90, green: 0.90, blue: 0.95)  // Zilver folie
    ]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    for particle in particles {
                        let rect = CGRect(
                            x: particle.x - particle.size / 2,
                            y: particle.y - particle.size / 2,
                            width: particle.size,
                            height: particle.isCircle ? particle.size : particle.size * 1.6
                        )

                        var pContext = context
                        pContext.translateBy(x: particle.x, y: particle.y)
                        pContext.rotate(by: Angle(degrees: particle.rotation))
                        pContext.translateBy(x: -particle.x, y: -particle.y)

                        if particle.isCircle {
                            pContext.fill(Circle().path(in: rect), with: .color(particle.color))
                        } else {
                            pContext.fill(RoundedRectangle(cornerRadius: 2).path(in: rect), with: .color(particle.color))
                        }
                    }
                }
                .onChange(of: timeline.date) { _, _ in
                    updateParticles(in: geo.size)
                }
            }
            .opacity(opacity)
            .onAppear {
                spawnParticles(in: geo.size)
                // Fade out na 4 seconden
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
                    withAnimation(.easeOut(duration: 1.2)) {
                        opacity = 0.0
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func spawnParticles(in size: CGSize) {
        var newParticles: [ConfettiParticle] = []
        let width = size.width > 0 ? size.width : 400
        for _ in 0..<65 {
            let p = ConfettiParticle(
                x: CGFloat.random(in: 20...(width - 20)),
                y: CGFloat.random(in: -80...0),
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement() ?? .yellow,
                vx: CGFloat.random(in: -1.2...1.2),
                vy: CGFloat.random(in: 2.5...5.8),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -8...8),
                isCircle: Bool.random()
            )
            newParticles.append(p)
        }
        self.particles = newParticles
    }

    private func updateParticles(in size: CGSize) {
        let height = size.height > 0 ? size.height : 800
        for i in particles.indices {
            particles[i].y += particles[i].vy
            particles[i].x += particles[i].vx + sin(particles[i].y * 0.03) * 0.8
            particles[i].rotation += particles[i].rotationSpeed

            // Reset bovenaan zolang we niet faden
            if particles[i].y > height + 20 && opacity > 0.5 {
                particles[i].y = -20
                particles[i].x = CGFloat.random(in: 20...(size.width > 0 ? size.width : 400))
            }
        }
    }
}
