import SwiftUI

struct CrockinoleSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    enum CrokinoleMode: String, CaseIterable, Identifiable {
        case eenTegenEen = "1 vs 1"
        case tweeTegenTwee = "2 vs 2 (Teams)"

        var id: String { rawValue }
    }

    @State private var mode: CrokinoleMode = .eenTegenEen

    // 1 vs 1
    @State private var spelerWit: String = ""
    @State private var spelerZwart: String = ""

    // 2 vs 2 Teams
    @State private var teamWitNaam: String = ""
    @State private var spelerWit1: String = ""
    @State private var spelerWit2: String = ""

    @State private var teamZwartNaam: String = ""
    @State private var spelerZwart1: String = ""
    @State private var spelerZwart2: String = ""

    @State private var puntenMethode: String = "Alles"
    @State private var showNewPlayerAlert: Bool = false
    @State private var newPlayerNameInput: String = ""

    // Berekende teamnamen
    private var effectiveTeamWitNaam: String {
        let trimmed = teamWitNaam.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let p1 = spelerWit1.trimmingCharacters(in: .whitespacesAndNewlines)
        let p2 = spelerWit2.trimmingCharacters(in: .whitespacesAndNewlines)
        if !p1.isEmpty && !p2.isEmpty { return "\(p1) & \(p2)" }
        return "Team Wit"
    }

    private var effectiveTeamZwartNaam: String {
        let trimmed = teamZwartNaam.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let p1 = spelerZwart1.trimmingCharacters(in: .whitespacesAndNewlines)
        let p2 = spelerZwart2.trimmingCharacters(in: .whitespacesAndNewlines)
        if !p1.isEmpty && !p2.isEmpty { return "\(p1) & \(p2)" }
        return "Team Zwart"
    }

    private var kanStarten: Bool {
        if mode == .eenTegenEen {
            let w = spelerWit.trimmingCharacters(in: .whitespacesAndNewlines)
            let z = spelerZwart.trimmingCharacters(in: .whitespacesAndNewlines)
            return !w.isEmpty && !z.isEmpty && w.caseInsensitiveCompare(z) != .orderedSame
        } else {
            let w1 = spelerWit1.trimmingCharacters(in: .whitespacesAndNewlines)
            let w2 = spelerWit2.trimmingCharacters(in: .whitespacesAndNewlines)
            let z1 = spelerZwart1.trimmingCharacters(in: .whitespacesAndNewlines)
            let z2 = spelerZwart2.trimmingCharacters(in: .whitespacesAndNewlines)

            let all = [w1, w2, z1, z2]
            let nonEmpty = all.filter { !$0.isEmpty }
            let unique = Set(nonEmpty.map { $0.lowercased() })
            return nonEmpty.count == 4 && unique.count == 4
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Crokinole")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Kies 1 tegen 1 of stel 2 teams samen")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 4)

                // 1. Spelmodus Selector
                Picker("Spelmodus", selection: $mode) {
                    ForEach(CrokinoleMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // 2. Snelle Speler Toevoegen & Bestaande spelers badge bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Beschikbare Spelers")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            newPlayerNameInput = ""
                            showNewPlayerAlert = true
                        }) {
                            Label("Nieuwe Speler", systemImage: "plus.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    if scoreManager.savedPlayerNames.isEmpty {
                        Text("Nog geen opgeslagen spelers. Typ direct een naam hieronder.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(scoreManager.savedPlayerNames, id: \.self) { name in
                                    playerQuickChip(name)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // 3. Speler / Team Invoer
                if mode == .eenTegenEen {
                    eenTegenEenInvoer
                } else {
                    tweeTegenTweeInvoer
                }

                // 4. Invoermethode
                VStack(alignment: .leading, spacing: 6) {
                    Text("Invoermethode")
                        .font(.headline)

                    Picker("Invoermethode", selection: $puntenMethode) {
                        Text("Alles (Directe set-invoer)").tag("Alles")
                        Text("Berekend (Schijf voor schijf)").tag("Berekend")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)

                Spacer(minLength: 16)

                // 5. Start Spel Knop
                NavigationLink(destination: destinationGameView) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        Text(mode == .eenTegenEen ? "Start 1 vs 1 Wedstrijd" : "Start Team Wedstrijd")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(kanStarten ? Color.green : Color.gray.opacity(0.4))
                    .cornerRadius(12)
                    .shadow(color: kanStarten ? Color.green.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                }
                .disabled(!kanStarten)
                .simultaneousGesture(TapGesture().onEnded {
                    slaSpelersOp()
                })
                .padding(.horizontal)

                if !kanStarten {
                    Text(mode == .eenTegenEen ? "Vul 2 verschillende spelersnamen in om te beginnen." : "Vul 4 verschillende spelersnamen in voor de 2 teams.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            scoreManager.refresh()
        }
        .alert("Nieuwe Speler Toevoegen", isPresented: $showNewPlayerAlert) {
            TextField("Naam van de speler", text: $newPlayerNameInput)
            Button("Toevoegen") {
                let trimmed = newPlayerNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    scoreManager.savePlayerName(trimmed)
                }
            }
            Button("Annuleer", role: .cancel) {}
        }
    }

    // MARK: - 1 vs 1 Invoer

    private var eenTegenEenInvoer: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    Text("Speler Wit")
                        .font(.headline)
                }

                PlayerNameInputField(
                    placeholder: "Naam Speler Wit",
                    text: $spelerWit,
                    suggestions: scoreManager.savedPlayerNames,
                    submitLabel: .next
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 16, height: 16)
                    Text("Speler Zwart")
                        .font(.headline)
                }

                PlayerNameInputField(
                    placeholder: "Naam Speler Zwart",
                    text: $spelerZwart,
                    suggestions: scoreManager.savedPlayerNames,
                    submitLabel: .done
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - 2 vs 2 Teams Invoer

    private var tweeTegenTweeInvoer: some View {
        VStack(spacing: 16) {
            // Team Wit Kaart
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))

                    Text("Team Wit")
                        .font(.headline)

                    Spacer()

                    Text(effectiveTeamWitNaam)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                TextField("Teamnaam (optioneel, bv. The Shooters)", text: $teamWitNaam)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speler 1 (Wit)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        PlayerNameInputField(
                            placeholder: "Naam Speler 1",
                            text: $spelerWit1,
                            suggestions: scoreManager.savedPlayerNames,
                            submitLabel: .next
                        )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speler 2 (Wit)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        PlayerNameInputField(
                            placeholder: "Naam Speler 2",
                            text: $spelerWit2,
                            suggestions: scoreManager.savedPlayerNames,
                            submitLabel: .next
                        )
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)

            // Team Zwart Kaart
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 20, height: 20)

                    Text("Team Zwart")
                        .font(.headline)

                    Spacer()

                    Text(effectiveTeamZwartNaam)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }

                TextField("Teamnaam (optioneel, bv. De Bullseyes)", text: $teamZwartNaam)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speler 1 (Zwart)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        PlayerNameInputField(
                            placeholder: "Naam Speler 1",
                            text: $spelerZwart1,
                            suggestions: scoreManager.savedPlayerNames,
                            submitLabel: .next
                        )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speler 2 (Zwart)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        PlayerNameInputField(
                            placeholder: "Naam Speler 2",
                            text: $spelerZwart2,
                            suggestions: scoreManager.savedPlayerNames,
                            submitLabel: .done
                        )
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func playerQuickChip(_ name: String) -> some View {
        Menu {
            if mode == .eenTegenEen {
                Button("Zet bij Wit") { spelerWit = name }
                Button("Zet bij Zwart") { spelerZwart = name }
            } else {
                Button("Team Wit - Speler 1") { spelerWit1 = name }
                Button("Team Wit - Speler 2") { spelerWit2 = name }
                Button("Team Zwart - Speler 1") { spelerZwart1 = name }
                Button("Team Zwart - Speler 2") { spelerZwart2 = name }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.12))
            .foregroundColor(.blue)
            .cornerRadius(16)
        }
    }

    private func slaSpelersOp() {
        if mode == .eenTegenEen {
            let names = [spelerWit, spelerZwart].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            scoreManager.savePlayerNames(names)
        } else {
            let names = [spelerWit1, spelerWit2, spelerZwart1, spelerZwart2].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            scoreManager.savePlayerNames(names)
        }
    }

    private var destinationGameView: some View {
        if mode == .eenTegenEen {
            let w = spelerWit.trimmingCharacters(in: .whitespacesAndNewlines)
            let z = spelerZwart.trimmingCharacters(in: .whitespacesAndNewlines)
            return CrockinoleGameView(
                isTeamMode: false,
                teamWitNaam: w.isEmpty ? "Wit" : w,
                teamWitSpelers: [w.isEmpty ? "Wit" : w],
                teamZwartNaam: z.isEmpty ? "Zwart" : z,
                teamZwartSpelers: [z.isEmpty ? "Zwart" : z],
                puntenMethode: puntenMethode
            )
        } else {
            return CrockinoleGameView(
                isTeamMode: true,
                teamWitNaam: effectiveTeamWitNaam,
                teamWitSpelers: [spelerWit1, spelerWit2],
                teamZwartNaam: effectiveTeamZwartNaam,
                teamZwartSpelers: [spelerZwart1, spelerZwart2],
                puntenMethode: puntenMethode
            )
        }
    }
}

#Preview {
    NavigationStack {
        CrockinoleSetupView()
    }
}
