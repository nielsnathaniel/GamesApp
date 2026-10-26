import SwiftUI

/// Een herbruikbare sectie voor opgeslagen spelers met horizontale chips.
/// De gebruiker kan op een opgeslagen speler klikken om deze direct toe te wijzen
/// aan een speler-slot (Speler 1, Speler 2, etc.), of een nieuwe speler toe te voegen.
struct SavedPlayersQuickChipsView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @Binding var spelers: [String]
    var aantalSpelers: Int
    var tintColor: Color = .blue

    @State private var showNewPlayerAlert: Bool = false
    @State private var newPlayerNameInput: String = ""

    private func isPlayerAssigned(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return false }
        for i in 0..<min(aantalSpelers, spelers.count) {
            if spelers[i].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed {
                return true
            }
        }
        return false
    }

    private func playerAssignedIndex(_ name: String) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        for i in 0..<min(aantalSpelers, spelers.count) {
            if spelers[i].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed {
                return i
            }
        }
        return nil
    }

    private func firstEmptyIndex() -> Int? {
        for i in 0..<min(aantalSpelers, spelers.count) {
            if spelers[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return i
            }
        }
        return nil
    }

    private func assignPlayer(_ name: String, toIndex index: Int) {
        guard index < spelers.count else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Als de speler al in een ander slot stond, maak dat slot leeg (geen dubbelen)
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for i in 0..<min(aantalSpelers, spelers.count) {
            if i != index && spelers[i].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed {
                spelers[i] = ""
            }
        }

        spelers[index] = name
    }

    private func removePlayer(_ name: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for i in 0..<min(aantalSpelers, spelers.count) {
            if spelers[i].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed {
                spelers[i] = ""
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Opgeslagen Spelers")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Button(action: {
                    newPlayerNameInput = ""
                    showNewPlayerAlert = true
                }) {
                    Label("Nieuwe Speler", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(tintColor)
                }
            }

            if scoreManager.savedPlayerNames.isEmpty {
                Text("Nog geen opgeslagen spelers. Typ direct een naam hieronder of voeg toe met '+'.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(scoreManager.savedPlayerNames, id: \.self) { name in
                            playerChip(name)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal)
        .alert("Nieuwe Speler Toevoegen", isPresented: $showNewPlayerAlert) {
            TextField("Naam van de speler", text: $newPlayerNameInput)
            Button("Toevoegen") {
                let trimmed = newPlayerNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    scoreManager.savePlayerName(trimmed)
                    if let empty = firstEmptyIndex() {
                        assignPlayer(trimmed, toIndex: empty)
                    }
                    newPlayerNameInput = ""
                }
            }
            Button("Annuleer", role: .cancel) {}
        }
    }

    private func playerChip(_ name: String) -> some View {
        let assigned = isPlayerAssigned(name)

        return Menu {
            if let emptyIdx = firstEmptyIndex(), !assigned {
                Button {
                    assignPlayer(name, toIndex: emptyIdx)
                } label: {
                    Label("Zet als Speler \(emptyIdx + 1)", systemImage: "person.badge.plus")
                }
                Divider()
            }

            ForEach(0..<min(aantalSpelers, spelers.count), id: \.self) { idx in
                let current = spelers[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                Button {
                    assignPlayer(name, toIndex: idx)
                } label: {
                    if current.isEmpty {
                        Label("Zet als Speler \(idx + 1) (vrij)", systemImage: "person")
                    } else if current.lowercased() == name.lowercased() {
                        Label("Speler \(idx + 1) (huidig)", systemImage: "checkmark")
                    } else {
                        Label("Zet als Speler \(idx + 1) (vervang \(current))", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }

            if assigned {
                Divider()
                Button(role: .destructive) {
                    removePlayer(name)
                } label: {
                    Label("Verwijder uit spel", systemImage: "trash")
                }
            }
        } label: {
            HStack(spacing: 5) {
                if assigned {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                } else {
                    PlayerAvatarView(name: name, size: 18, showBorder: false)
                }
                Text(name)
                    .font(.caption)
                    .fontWeight(assigned ? .bold : .medium)

                let count = scoreManager.playerPlayCount(for: name)
                if count > 0 {
                    Text("\(count)x")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(assigned ? Color.white.opacity(0.25) : tintColor.opacity(0.18))
                        .foregroundColor(assigned ? .white : tintColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(assigned ? tintColor : tintColor.opacity(0.12))
            .foregroundColor(assigned ? .white : tintColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(assigned ? Color.clear : tintColor.opacity(0.3), lineWidth: 1)
            )
        } primaryAction: {
            if assigned {
                removePlayer(name)
            } else if let empty = firstEmptyIndex() {
                assignPlayer(name, toIndex: empty)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var spelers: [String] = ["Niels", ""]
        var body: some View {
            VStack(spacing: 20) {
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: 3,
                    tintColor: .orange
                )
                ForEach(0..<3, id: \.self) { i in
                    Text("Speler \(i+1): \(spelers[safe: i] ?? "")")
                }
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
