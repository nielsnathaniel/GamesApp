import SwiftUI

/// Een overzichtelijk, direct scherm om tijdens het spel de score per speler
/// handmatig aan te passen (direct getal intypen en/of snelle +/- knoppen gebruiken).
struct PuntenWijzigenSheet: View {
    let spelers: [String]
    let huidigeScores: [Int]
    var titel: String = "Punten Wijzigen"
    var subtitel: String = "Pas de stand direct aan door een getal in te typen of de knoppen te gebruiken."
    var isLowestScoreWins: Bool = false
    var onOpslaan: ([Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var aangepasteScores: [Int]
    @State private var scoreTeksten: [String]
    @FocusState private var focusedField: Int?

    init(
        spelers: [String],
        huidigeScores: [Int],
        titel: String = "Punten Wijzigen",
        subtitel: String = "Pas de stand direct aan door een getal in te typen of de knoppen te gebruiken.",
        isLowestScoreWins: Bool = false,
        onOpslaan: @escaping ([Int]) -> Void
    ) {
        self.spelers = spelers
        self.huidigeScores = huidigeScores
        self.titel = titel
        self.subtitel = subtitel
        self.isLowestScoreWins = isLowestScoreWins
        self.onOpslaan = onOpslaan
        _aangepasteScores = State(initialValue: huidigeScores)
        _scoreTeksten = State(initialValue: huidigeScores.map { String($0) })
    }

    // Convenience initializer voor Player modellen
    init(
        players: [Player],
        huidigeScores: [Int],
        titel: String = "Punten Wijzigen",
        subtitel: String = "Pas de stand direct aan door een getal in te typen of de knoppen te gebruiken.",
        isLowestScoreWins: Bool = false,
        onOpslaan: @escaping ([Int]) -> Void
    ) {
        self.init(
            spelers: players.map { $0.name },
            huidigeScores: huidigeScores,
            titel: titel,
            subtitel: subtitel,
            isLowestScoreWins: isLowestScoreWins,
            onOpslaan: onOpslaan
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                // Info banner
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Directe score-aanpassing")
                                .font(.headline)
                            Text(subtitel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Spelers lijst
                Section("Spelers & Scores") {
                    ForEach(spelers.indices, id: \.self) { idx in
                        VStack(alignment: .leading, spacing: 10) {
                            // Regel 1: Avatar + Spelernaam + Verschil
                            HStack(spacing: 12) {
                                PlayerAvatarView(name: spelers[idx], size: 38)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(spelers[idx])
                                        .font(.headline)
                                    let oud = huidigeScores[safe: idx] ?? 0
                                    let nieuw = aangepasteScores[safe: idx] ?? oud
                                    let diff = nieuw - oud
                                    HStack(spacing: 6) {
                                        Text("Oud: \(oud)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if diff != 0 {
                                            Text(diff > 0 ? "(+\(diff))" : "(\(diff))")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(diffColor(diff: diff))
                                        }
                                    }
                                }
                                Spacer()
                            }

                            // Regel 2: Direct intypen van de score
                            HStack(spacing: 12) {
                                Text("Nieuwe score:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                TextField("0", text: Binding(
                                    get: { scoreTeksten[safe: idx] ?? "0" },
                                    set: { newText in
                                        if idx < scoreTeksten.count {
                                            scoreTeksten[idx] = newText
                                            if let val = Int(newText) {
                                                if idx < aangepasteScores.count {
                                                    aangepasteScores[idx] = val
                                                }
                                            }
                                        }
                                    }
                                ))
                                .focused($focusedField, equals: idx)
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .frame(width: 100, height: 42)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange.opacity(0.6), lineWidth: 1.5)
                                )
                            }

                            // Regel 3: Snelle +/- stelknoppen
                            HStack(spacing: 8) {
                                Spacer()
                                quickStepButton(idx: idx, delta: -10, label: "-10")
                                quickStepButton(idx: idx, delta: -1, label: "-1")
                                quickStepButton(idx: idx, delta: +1, label: "+1")
                                quickStepButton(idx: idx, delta: +10, label: "+10")
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                // Reset optie
                Section {
                    Button(action: resetToOriginal) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Herstel naar originele waarden")
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(titel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Opslaan") {
                        opslaanEnSluiten()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Klaar") {
                        focusedField = nil
                    }
                }
            }
        }
    }

    private func diffColor(diff: Int) -> Color {
        if isLowestScoreWins {
            // Minder punten is beter (bijv. Beverbende / Balzakken)
            return diff < 0 ? .green : .red
        } else {
            // Meer punten is beter (standaard bordspellen)
            return diff > 0 ? .green : .red
        }
    }

    private func quickStepButton(idx: Int, delta: Int, label: String) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            let current = Int(scoreTeksten[safe: idx] ?? "") ?? (aangepasteScores[safe: idx] ?? 0)
            let updated = current + delta
            if idx < aangepasteScores.count {
                aangepasteScores[idx] = updated
            }
            if idx < scoreTeksten.count {
                scoreTeksten[idx] = String(updated)
            }
        }) {
            Text(label)
                .font(.footnote)
                .fontWeight(.bold)
                .frame(minWidth: 44, minHeight: 32)
                .background(Color(UIColor.tertiarySystemFill))
                .foregroundColor(.primary)
                .cornerRadius(8)
        }
        .buttonStyle(.borderless)
    }

    private func resetToOriginal() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        aangepasteScores = huidigeScores
        scoreTeksten = huidigeScores.map { String($0) }
    }

    private func opslaanEnSluiten() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        var finalScores: [Int] = []
        for i in spelers.indices {
            let parsed = Int(scoreTeksten[safe: i] ?? "") ?? (aangepasteScores[safe: i] ?? (huidigeScores[safe: i] ?? 0))
            finalScores.append(parsed)
        }
        onOpslaan(finalScores)
        dismiss()
    }
}
