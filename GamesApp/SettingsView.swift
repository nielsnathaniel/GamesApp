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

                    DisclosureGroup("30 Seconds Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Teamspel: 2, 3 of 4 teams met minimaal 2 spelers per team")
                            Text("• Beurt: 1 speler omschrijft 5 begrippen in 30 seconden, teamgenoten raden")
                            Text("• Omschrijver rouleert automatisch elke beurt binnen het team")
                            Text("• Dobbelsteen (0, 1 of 2): Deze worp wordt afgetrokken van je aantal goed geraden namen")
                            Text("• Stappen: max(0, geraden - dobbelsteen)")
                            Text("• Winnaar: Het eerste team dat de finish (bijv. 35 punten) bereikt!")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Cranium Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Teamspel: 2 tot 4 teams strijden op 4 verschillende breingebieden")
                            Text("• 🟡 Data Head: Trivia, weetjes, feiten & wetenschap")
                            Text("• 🔵 Creative Cat: Tekenen, kleien & sculpturen boetseren")
                            Text("• 🔴 Word Worm: Woordpuzzels, anagrammen & achterstevoren spellen")
                            Text("• 🟢 Star Performer: Uitbeelden, zingen, neuriën & typetjes nadoen")
                            Text("• 🟣 Club Cranium: Alle teams strijden tegelijk; winnaar pakt een bonuspunt!")
                            Text("• Timer: 60 seconden per opdracht")
                            Text("• Winnaar: Eerste team in Cranium Centrale dat alle 4 de categorieën heeft voltooid!")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Qwixx Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Rijen: Rood & Geel lopen op (2 ➔ 12), Groen & Blauw lopen af (12 ➔ 2)")
                            Text("• Aankruisen: Altijd van links naar rechts; overgeslagen getallen mag je niet meer aankruisen")
                            Text("• Rij sluiten: Minstens 5 kruisjes in die rij + het laatste getal (12 of 2) aankruisen")
                            Text("• Misworp: -5 punten als je tijdens je beurt als actieve speler niets kunt of wilt aankruisen")
                            Text("• Puntentelling per rij: 1x=1pt, 2x=3pt, 3x=6pt, 4x=10pt, ..., 12x=78pt (n*(n+1)/2)")
                            Text("• Einde: Zodra 2 rijen gesloten zijn of iemand 4 misworpen heeft")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Pig Hole Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Start: Totaal 60 varkentjes verdeeld over het aantal spelers (bijv. 4 spelers = 15 elk, 3 = 20 elk)")
                            Text("• Doel: Als eerste al je varkentjes kwijtraken!")
                            Text("• Ronde 1: Iedereen gooit maximaal 1x met de dobbelsteen")
                            Text("• Ronde 2: Iedereen gooit maximaal 2x met de dobbelsteen")
                            Text("• Ronde 3+: Gooi zovaak door als je durft!")
                            Text("• Gooi 1 t/m 5: Zet 1 varkentje in het bijbehorende vakje")
                            Text("• Vakje bezet? Pech! Pak alle varkentjes op dat vakje op, beurt voorbij!")
                            Text("• Gooi een 6 (Varkensgat): Gooi 1 varkentje door het gat, permanent kwijt!")
                            Text("• Winnaar: Degene die als eerste al zijn varkentjes kwijt is (0 varkentjes) wint")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Ticket to Ride Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Doel: Meeste punten scoren met treinroutes en bestemmingskaarten")
                            Text("• Routepunten: 1 wagon=1pt, 2=2pt, 3=4pt, 4=7pt, 5=10pt, 6=15pt, 8=21pt")
                            Text("• Voltooide tickets: Leveren de aangegeven punten op")
                            Text("• Mislukte tickets: Punten worden als strafpunten afgetrokken")
                            Text("• Langste aaneengesloten route: +10 bonuspunten")
                            Text("• Globetrotter (meeste voltooide tickets): +10 bonuspunten")
                            Text("• Ongebruikte stations: 4 punten per station (max 12 pt)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Quickstop Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Doel: Zo min mogelijk strafpunten (bliksemschichten ⚡️) verzamelen; minste strafpunten wint!")
                            Text("• Kaarten: Elke speler start elke ronde met 5 letterkaarten")
                            Text("• Spelverloop: Roep zo snel mogelijk een passend woord bij het openliggende thema en leg je letter af")
                            Text("• Wissel van thema: Na 3 goede antwoorden wordt het volgende thema voorgelezen")
                            Text("• Rondewinst: Wie als eerste al zijn handkaarten kwijt is, krijgt 0 strafpunten")
                            Text("• Strafpunten: De andere spelers tellen de bliksems ⚡️ op hun overgebleven handkaarten")
                            Text("• Einde spel: Zodra iemand 40 strafpunten (of de gekozen limiet) bereikt. De speler met de laagste score wint!")
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
                        Text("14 spellen")
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
