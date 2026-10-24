import SwiftUI

struct JattenGameView: View {
    var spelers: [Player]

    @State private var huidigeRonde: Int = 1
    @State private var startSpelerIndex: Int = 0
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?
    @State private var showZesDezelfdeAlert: Bool = false
    @State private var geselecteerdeWinnaarIndex: Int?
    @State private var showHandmatigAfrondenSheet: Bool = false

    var huidigeStarterIndex: Int {
        guard !spelers.isEmpty else { return 0 }
        return (startSpelerIndex + (huidigeRonde - 1)) % spelers.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    HStack(spacing: 10) {
                        if UIImage(named: "Jatten") != nil {
                            Image("Jatten")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 38, height: 38)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                .shadow(color: .purple.opacity(0.3), radius: 3, x: 0, y: 1)
                        } else {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.purple)
                        }
                        Text("Jatten")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Text("Ronde \(huidigeRonde) • Eerste met 6 dezelfde wint!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)

                // Wie mag beginnen (Startspeler kaart)
                HStack(spacing: 10) {
                    Image(systemName: "dice.fill")
                        .font(.title2)
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aan de beurt om te jatten:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(spelers[safe: huidigeStarterIndex]?.name ?? "Speler 1")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    if huidigeRonde == 1 {
                        Button(action: {
                            withAnimation {
                                startSpelerIndex = Int.random(in: 0..<max(1, spelers.count))
                            }
                        }) {
                            Label("Willekeurig", systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.12))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                        }
                    } else {
                        Text("Om de beurt")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Spelers lijst
                VStack(spacing: 12) {
                    ForEach(spelers.indices, id: \.self) { index in
                        HStack {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(index == huidigeStarterIndex ? Color.purple.opacity(0.2) : Color.gray.opacity(0.12))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: index == huidigeStarterIndex ? "hand.raised.fill" : "person.fill")
                                        .foregroundColor(index == huidigeStarterIndex ? .purple : .gray)
                                        .font(.system(size: 20))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(spelers[index].name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    if index == huidigeStarterIndex {
                                        Text("Aan de beurt")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.purple)
                                    } else {
                                        Text("Wacht op beurt")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            Spacer()

                            // Knop 6 dezelfde! Direct winnen
                            Button(action: {
                                geselecteerdeWinnaarIndex = index
                                showZesDezelfdeAlert = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "crown.fill")
                                    Text("6 dezelfde!")
                                        .fontWeight(.bold)
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                                .shadow(color: Color.purple.opacity(0.35), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(index == huidigeStarterIndex ? Color.purple.opacity(0.4) : Color.clear, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 20)

                // Knoppen onderin: Volgende beurt & Afronden
                VStack(spacing: 10) {
                    Button(action: {
                        withAnimation {
                            huidigeRonde += 1
                        }
                    }) {
                        Label("Volgende Beurt", systemImage: "arrow.right.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .cornerRadius(12)
                            .shadow(color: Color.purple.opacity(0.3), radius: 4, x: 0, y: 2)
                    }

                    Button(action: {
                        showHandmatigAfrondenSheet = true
                    }) {
                        Text("Spel Afronden")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .alert("6 dezelfde!", isPresented: $showZesDezelfdeAlert) {
            Button("Ja, winnaar!") {
                if let winIndex = geselecteerdeWinnaarIndex, winIndex < spelers.count {
                    spelerWintMetZesDezelfde(index: winIndex)
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            if let winIndex = geselecteerdeWinnaarIndex, winIndex < spelers.count {
                Text("Heeft \(spelers[winIndex].name) 6 kaarten van dezelfde waarde verzameld? Dan wint \(spelers[winIndex].name) direct!")
            } else {
                Text("Heeft deze speler 6 dezelfde?")
            }
        }
        .confirmationDialog("Kies de winnaar", isPresented: $showHandmatigAfrondenSheet, titleVisibility: .visible) {
            ForEach(spelers.indices, id: \.self) { index in
                Button("\(spelers[index].name) (Winnaar)") {
                    spelerWintMetZesDezelfde(index: index)
                }
            }
            Button("Annuleren", role: .cancel) {}
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            if let winnaar = winnaar {
                let winIndex = spelers.firstIndex(where: { $0.id == winnaar.id }) ?? 0
                let scores = spelers.indices.map { $0 == winIndex ? 6 : 0 }
                WinnaarView(
                    gameName: "Jatten",
                    winnaar: winnaar,
                    sortedSpelers: spelers,
                    sortedScores: scores,
                    isLowestScoreWins: false
                )
            }
        }
    }

    private func spelerWintMetZesDezelfde(index: Int) {
        winnaar = spelers[index]
        showWinnaarView = true
    }
}

#Preview {
    JattenGameView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")])
}
