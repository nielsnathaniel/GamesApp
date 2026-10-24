import SwiftUI

struct SettingsView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    var body: some View {
        NavigationStack {
            List {
                // 1. Gegevensbeheer (Navigeer naar dedicated GegevensbeheerView)
                Section(header: Label("Gegevensbeheer", systemImage: "cylinder.split.1x2.fill")) {
                    NavigationLink(destination: GegevensbeheerView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "externaldrive.fill.badge.person.crop")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Gegevensbeheer")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Opgeslagen spelers & spelsessies beheren")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("\(scoreManager.fetchPlayerNames().count) spelers")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // 2. Speluitleg & Regels
                Section(header: Label("Spelregels Quick Reference", systemImage: "book.closed.fill")) {
                    DisclosureGroup("Balzakken Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Doel: Minste punten overhouden (einde bij 100 strafpunten)")
                            Text("• Kaarten: Balzakken van -1 (Bruisbal) t/m 11 (Blauwe Bal)")
                            Text("• De Swinger: Ruil je hand met een tegenspeler (0 pt als een ander Balzak roept)")
                            Text("• De Lul: Tegenstander pakt 2 kaarten (10 strafpunten als een ander Balzak roept!)")
                            Text("• BALZAK! roepen: Alleen tijdens je beurt met 5 punten of minder (zonder actiekaart)")
                            Text("• Goeie Balzak!: Roeper noteert 0 punten, overige spelers noteren handpunten")
                            Text("• Valse Balzak!: Roeper krijgt 25 strafpunten! Laagste speler noteert 0 punten")
                            Text("• Precies 69 punten: Strafpunten gaan terug naar 50!")
                            Text("• Precies 99 punten: Strafpunten gaan terug naar 75!")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Jatten Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Doel: Als eerste 6 kaarten van dezelfde waarde verzamelen!")
                            Text("• Einde: Het spel stopt direct zodra iemand 6 dezelfde heeft")
                            Text("• Beurt 1: Leg 1 kaart uit je hand open in je verzameling")
                            Text("• Beurt 2: Steel kaarten blind uit de hand van 1 tegenstander")
                            Text("• Pas op: Trek je 2 dezelfde waarden tijdens het jatten? Beurt voorbij en buit terug!")
                            Text("• Oplichter: Steel 1 open kaart naar keuze uit de verzameling van het slachtoffer")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Duizenden Kaartwaardes") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Joker = 25 punten")
                            Text("• Aas = 20 punten")
                            Text("• Heer / Vrouw / Boer / 10 = 10 punten")
                            Text("• Kaarten 4 t/m 9 = 5 punten")
                            Text("• Schoppen 3 = 100 strafpunten (bij verlies)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Beverbende Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Laagste totaalscore na alle rondes wint")
                            Text("• Waarde van kaarten: 0 t/m 9")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Crockinole Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Puntenverschil per ronde gaat naar de rondewinnaar")
                            Text("• 100 punten nodig om een set te winnen")
                            Text("• Wie als eerste 3 sets wint, wint de wedstrijd!")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Love Letter Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Doel: Zorg dat jouw liefdesbrief de Prinses bereikt!")
                            Text("• Beurt: Trek 1 kaart en speel 1 van je 2 kaarten uit")
                            Text("• Ronde winnen: Enige overgebleven speler OF hoogste handkaart als de trekstapel leeg is")
                            Text("• 9: Prinses (9 pt) - Verlies direct als je haar moet afleggen")
                            Text("• 8: Gravin (8 pt) - Moet afgelegd worden als je ook Koning of Prins hebt")
                            Text("• 7: Koning (7 pt) - Ruil je handkaart met een andere speler")
                            Text("• 6: Kanselier (6 pt) - Trek 2 kaarten, leg 2 kaarten onderop de trekstapel")
                            Text("• 5: Prins (5 pt) - Dwing een speler om zijn/haar handkaart af te leggen")
                            Text("• 4: Dienstmeid (4 pt) - Beschermd tegen alle kaarten tot je volgende beurt")
                            Text("• 3: Baron (3 pt) - Vergelijk handkaarten in het geheim; laagste ligt eruit")
                            Text("• 2: Priester (2 pt) - Bekijk stiekem de handkaart van een medespeler")
                            Text("• 1: Wacht (1 pt) - Noem een kaartwaarde (niet Wacht); raad je goed, dan ligt die speler eruit")
                            Text("• 0: Spion (0 pt) - +1 bonusfiche als je overleeft en als enige een spion speelde")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }
                }

                // 3. Over GamesApp
                Section(header: Label("Over GamesApp", systemImage: "info.circle.fill")) {
                    HStack {
                        Text("Versie")
                        Spacer()
                        Text("1.0 (iOS 18+)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Ondersteunde Spellen")
                        Spacer()
                        Text("8 spellen")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Instellingen")
            .onAppear {
                scoreManager.refresh()
            }
        }
    }
}

#Preview {
    SettingsView()
}
