import SwiftUI

struct RuleDisputeItem: Identifiable {
    let id = UUID()
    let game: String
    let question: String
    let verdict: String
    let verdictType: VerdictType
    let explanation: String

    enum VerdictType {
        case allowed
        case forbidden
        case rule

        var color: Color {
            switch self {
            case .allowed: return .green
            case .forbidden: return .red
            case .rule: return .blue
            }
        }

        var icon: String {
            switch self {
            case .allowed: return "checkmark.seal.fill"
            case .forbidden: return "xmark.seal.fill"
            case .rule: return "scale.3d"
            }
        }

        var label: String {
            switch self {
            case .allowed: return "TOEGESTAAN"
            case .forbidden: return "VERBODEN"
            case .rule: return "OFFICIËLE REGEL"
            }
        }
    }
}

struct GameRulesKnowledgeView: View {
    @State private var searchText: String = ""
    @State private var selectedGameFilter: String = "Alle"
    @State private var showDisputesOnly: Bool = false

    private let gameFilters = [
        "Alle", "Beverbende", "Balzakken", "Regenwormen", "Love Letter",
        "Ticket to Ride", "30 Seconds", "Cranium", "Qwixx", "Duizenden", "Pig Hole", "Jatten"
    ]

    private let disputes: [RuleDisputeItem] = [
        // Beverbende
        RuleDisputeItem(
            game: "Beverbende",
            question: "Wat gebeurt er bij een gelijke stand aan het einde?",
            verdict: "Kijk naar de laatste ronde",
            verdictType: .rule,
            explanation: "Als twee of meer spelers na de gekozen rondes hetzelfde aantal punten hebben, wint de speler met de minste punten in de allerlaatste ronde. Is dat ook gelijk, dan delen ze de overwinning!"
        ),
        RuleDisputeItem(
            game: "Beverbende",
            question: "Mag je een Ruilkaart gebruiken tussen twee eigen kaarten?",
            verdict: "Nee, verboden",
            verdictType: .forbidden,
            explanation: "Met een Ruilkaart moet je verplicht één van jouw eigen gedekte kaarten ruilen met één gedekte kaart van een tegenstander. Je mag niet twee eigen kaarten met elkaar ruilen."
        ),
        RuleDisputeItem(
            game: "Beverbende",
            question: "Mag je de bovenste kaart van de aflegstapel pakken?",
            verdict: "Ja, mits actieve speler hem nog niet dekt",
            verdictType: .allowed,
            explanation: "In je beurt mag je kiezen: de blinde trekstapel pakken OF de openliggende bovenste kaart van de aflegstapel. Kies je de aflegstapel, dan moet je deze direct ruilen met een van je eigen kaarten."
        ),

        // Balzakken
        RuleDisputeItem(
            game: "Balzakken",
            question: "Wat gebeurt er als je BALZAK roept maar iemand heeft evenveel punten?",
            verdict: "Valse Balzak (+25 strafpunten)",
            verdictType: .forbidden,
            explanation: "Om een Goeie Balzak te scoren moet je STRIKT minder punten hebben dan alle andere spelers. Bij gelijke stand met een tegenspeler is jouw roep ongeldig en krijg jij 25 strafpunten!"
        ),
        RuleDisputeItem(
            game: "Balzakken",
            question: "Krijg je direct de reset bij exact 69 of 99 punten?",
            verdict: "Ja, onmiddellijk",
            verdictType: .allowed,
            explanation: "Zodra jouw cumulatieve score na een ronde exact op 69 punten eindigt, zakt je score direct terug naar 50. Eindig je exact op 99 punten, zakt je score direct terug naar 75!"
        ),
        RuleDisputeItem(
            game: "Balzakken",
            question: "Hoeveel punten is De Swinger waard als een ander Balzak roept?",
            verdict: "0 punten",
            verdictType: .rule,
            explanation: "De Swinger telt voor 0 strafpunten aan het einde van de ronde. De Lul daarentegen telt als 10 strafpunten!"
        ),

        // Regenwormen
        RuleDisputeItem(
            game: "Regenwormen",
            question: "Mag je een wormsteen stelen als de waarde gelijk is?",
            verdict: "Ja, mits minstens 1 worm gedobbeld",
            verdictType: .allowed,
            explanation: "Als jouw totale dobbelsteenwaarde exact overeenkomt met de bovenste open steen op de stapel van een tegenstander én je hebt minstens 1 worm opzij gelegd, mag je die steen van diens stapel jatten!"
        ),
        RuleDisputeItem(
            game: "Regenwormen",
            question: "Wat als je geen enkele worm hebt gedobbeld?",
            verdict: "Mislukte beurt",
            verdictType: .forbidden,
            explanation: "Je MOET minstens één worm opzij hebben gelegd tijdens je beurt. Is je som hoog genoeg maar heb je 0 wormen, dan is je beurt ongeldig en moet je je bovenste steen inleveren."
        ),

        // Love Letter
        RuleDisputeItem(
            game: "Love Letter",
            question: "Wat gebeurt er als je de Prinses moet afleggen door de Prins?",
            verdict: "Je ligt direct uit de ronde",
            verdictType: .forbidden,
            explanation: "Als een tegenstander de Prins (waarde 5) op jou speelt en jij moet je handkaart afleggen, en dat is de Prinses, lig je per direct uit de ronde. Je bent niet beschermd!"
        ),
        RuleDisputeItem(
            game: "Love Letter",
            question: "Mag je met de Wachter (1) raden op de Wachter?",
            verdict: "Nee, verboden",
            verdictType: .forbidden,
            explanation: "Als je de Wachter speelt, mag je elke kaart van waarde 0 t/m 9 noemen, BEHALVE de Wachter zelf."
        ),

        // Ticket to Ride
        RuleDisputeItem(
            game: "Ticket to Ride",
            question: "Mogen beide dubbele sporen gebruikt worden bij 2 of 3 spelers?",
            verdict: "Nee, slechts één spoor",
            verdictType: .forbidden,
            explanation: "Bij spellen met 2 of 3 spelers mag er slechts één van de dubbele sporen worden geclaimd. Zodra één speler een spoor pakt, is de parallelle verbinding permanent gesloten voor iedereen!"
        ),
        RuleDisputeItem(
            game: "Ticket to Ride",
            question: "Wat levert een ongebruikt station op?",
            verdict: "4 bonuspunten per station",
            verdictType: .rule,
            explanation: "Elk station dat je aan het einde van het spel nog in je voorraad hebt (niet op het bord geplaatst), levert 4 bonuspunten op (maximaal 12 punten bij 3 stations)."
        ),

        // 30 Seconds
        RuleDisputeItem(
            game: "30 Seconds",
            question: "Mag je rijmen of 'klinkt als' gebruiken?",
            verdict: "Nee, streng verboden",
            verdictType: .forbidden,
            explanation: "Je mag geen enkel deel van de naam noemen, niet letterlijk vertalen ('castle' voor kasteel), niet spellen met letters en niet 'rijmt op...' of 'klinkt als...' gebruiken."
        ),

        // Cranium
        RuleDisputeItem(
            game: "Cranium",
            question: "Mag de kleier of tekenaar geluiden maken of gebaren?",
            verdict: "Nee, volledige stilte",
            verdictType: .forbidden,
            explanation: "Bij Creative Cat (tekenen of kleien) mag de actieve speler geen enkel geluid maken, niet praten en geen lichaamstaal/gebaren gebruiken."
        ),

        // Qwixx
        RuleDisputeItem(
            game: "Qwixx",
            question: "Mag je een kruisje links zetten van een bestaand kruisje?",
            verdict: "Nee, nooit meer",
            verdictType: .forbidden,
            explanation: "Rijen lopen altijd strikt van links naar rechts. Een getal dat je eenmaal hebt overgeslagen mag je tijdens de rest van het spel onder geen beding meer aankruisen!"
        )
    ]

    private var filteredDisputes: [RuleDisputeItem] {
        disputes.filter { item in
            let matchesFilter = (selectedGameFilter == "Alle") || (item.game.localizedCaseInsensitiveContains(selectedGameFilter))
            if !matchesFilter { return false }

            if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                return true
            }

            let query = searchText.lowercased()
            return item.game.lowercased().contains(query) ||
                   item.question.lowercased().contains(query) ||
                   item.explanation.lowercased().contains(query) ||
                   item.verdict.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Zoekbalk
                searchHeader

                // Spel filter chips
                filterChips

                // Lijst met discussies en regels
                List {
                    Section {
                        ForEach(filteredDisputes) { item in
                            disputeCard(item)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "scale.3d")
                                .foregroundColor(.blue)
                            Text("Wie heeft gelijk? (\(filteredDisputes.count) kwesties)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }

                    if filteredDisputes.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "questionmark.folder")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("Geen discussies gevonden voor '\(searchText)'")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Spelregels & Scheidsrechter")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Search Header
    private var searchHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Zoek discussie, regel of uitzondering...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(gameFilters, id: \.self) { filter in
                    let isSelected = selectedGameFilter == filter
                    Button(action: {
                        HapticManager.shared.light()
                        selectedGameFilter = filter
                    }) {
                        Text(filter)
                            .font(.caption)
                            .fontWeight(isSelected ? .bold : .medium)
                            .foregroundColor(isSelected ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Dispute Card
    private func disputeCard(_ item: RuleDisputeItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.game.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.blue)

                    Text(item.question)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Oordeel Badge
                HStack(spacing: 4) {
                    Image(systemName: item.verdictType.icon)
                        .font(.system(size: 10))
                    Text(item.verdictType.label)
                        .font(.system(size: 9, weight: .black))
                }
                .foregroundColor(item.verdictType.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.verdictType.color.opacity(0.12))
                .clipShape(Capsule())
            }

            Text(item.verdict)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(item.verdictType.color)

            Text(item.explanation)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GameRulesKnowledgeView()
}
