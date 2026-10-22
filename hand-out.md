# Hand-out: GamesApp iOS Project 📱🎲

Dit document dient als overdracht en briefing voor **Antigravity** (en ontwikkelaars) op de MacBook. Het bevat alle nodige context over de architectuur, recente updates, spelregels, datastructuren en werkwijzen.

---

## 1. Projectoverzicht
* **Projectnaam:** GamesApp
* **Platform:** iOS (Swift / SwiftUI, Xcode)
* **GitHub Repository:** `https://github.com/nielsnathaniel/GamesApp.git`
* **Branch:** `main`
* **Taal van de UI:** Nederlands
* **Doel:** Een moderne, intuïtieve score-tracking app voor diverse bord- en kaartspellen met vrienden en familie, inclusief diepgaande statistieken, rondegeschiedenis en spelersbeheer.

### Ondersteunde Spellen:
1. **Balzakken:** Populair dobbel/kaartspel met speciale regels (69 en 99 straffen, Valse Balzak, Balzak!).
2. **Duizenden:** Klassiek kaartspel met melds, slagen en minpunten.
3. **Beverbende:** Tactisch kaartspel waarbij de laagste score wint.
4. **Crokinole (Crockinole):** Schijvenspel met 20-gaten en differentieel scoreverloop.
5. **Nmbr9:** Puzzel- en cijferspel met lagenvermenigvuldigers.
6. **Regenwormen:** Dobbelspel rondom stenen en wormen.
7. **Jatten:** Kaartspel met push-your-luck elementen.

---

## 2. Navigatie & Belangrijkste Schermen

De app gebruikt een centrale `TabView` in [`ContentView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/ContentView.swift) met drie hoofdonderdelen:

```
[ Tab 0: Spellen ] ───► CurrentGameView (Spelkeuze & Actieve spelsessies)
[ Tab 1: Statistieken ] ► StatisticsView (Analytics dashboard met 4 segmenten)
[ Tab 2: Instellingen ] ─► SettingsView (Spelersbeheer, Geschiedenis, Spelregels)
```

### Belangrijke Bestanden:
* [`ContentView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/ContentView.swift): TabView configuratie (Spellen, Statistieken, Instellingen) inclusief interactieve sorteeropties voor het spellenaanbod:
  - **Populair**: Sorteert spellen op basis van het aantal gespeelde potjes (meest gespeeld bovenaan) met een subtiele vlam-badge (`🔥 Xx`) en speelfrequentie.
  - **Toegevoegd**: Behoudt de standaard/oorspronkelijke volgorde van de spellen.
  - **Alfabetisch**: Sorteert de spellen op alfabetische volgorde (A-Z).
  - De geselecteerde sorteervoorkeur wordt bewaard via `@AppStorage`.
* [`ScoreManager.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/ScoreManager.swift): Singleton (`@Observable` / `ObservableObject`) data-engine. Regelt persistentie via `UserDefaults`, `GameHistory`, `savedPlayers`, winnaars, H2H-statistieken, 2v2 Duo-statistieken en Balzakken leaderboards.
* [`StatisticsView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/StatisticsView.swift): Gloednieuw statistiekenscherm met:
  1. *Overzicht:* KPI-tegels (totale potjes, actieve spelers, records) & populariteitsgrafieken.
  2. *Spelers & Rangen:* Podium (🥇, 🥈, 🥉), winpercentages en ranglijsten.
  3. *Wie wint van wie?:* Head-to-head rivaliteiten met filter per spel.
  4. *Duo's 🤝:* Partner-chemie en droomteams ranking voor Crokinole 2v2.
  5. *Balzakken 🎯:* Balzakken Hall of Fame (Balzakken Koning & Gevaarlijkste Speler, ranglijst juiste vs foute balzakken).
* [`SettingsView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/SettingsView.swift): Volledig gerenoveerd:
  - *Spelersbeheer:* Namen toevoegen, lijst bekijken, swipe-to-delete.
  - *Geschiedenis van Potjes:* Chronologische lijst met scores en swipe-to-delete.
  - *Gegevensbeheer:* Bevestigingsdialoog voor het wissen van geschiedenis of spelers.
  - *Spelregels Quick Reference:* Inklapbare handleidingen voor de spellen.
* [`BalzakkenGameView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/BalzakkenGameView.swift):
  - Knoppen zijn vereenvoudigd naar puur de getallen: `-1`, `+1`, `+5`, `+11`.
  - Registratie van Juiste Balzakken (`BALZAK! (0)`) en Foute Balzakken (`Valse Balzak (+25)`). Balzakstatistieken worden per ronde geregistreerd zodat herhaaldelijk klikken niet tot dubbeltelling leidt.
  - In-game puntengeschiedenis (ronde per ronde popup sheet).
  - "Wie mag beginnen?": Ronde 1 willekeurig gekozen met dobbelsteen-knop, daarna opvolgend met de klok mee ("om de beurt").
* [`BeverbendeScoreView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/BeverbendeScoreView.swift): Rondegeschiedenis sheet en startspeler-indicator.
* [`CrockinoleSetupView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/CrockinoleSetupView.swift) & [`CrockinoleGameView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/CrockinoleGameView.swift):
  - Keuze tussen 1 vs 1 en 2 vs 2 (Teams).
  - Spelers kiezen uit bestaande spelers (quick chips / suggesties) of direct toevoegen.
  - Teamnamen worden automatisch afgeleid van de gekozen spelers (bijv. "Niels & Tom") — overbodige tekstvelden voor teamnamen zijn geëlimineerd.
  - Schietvolgorde-indicator ("Aan de beurt om te schieten") voor 2v2 wedstrijden.
  - **In-game telwijze aanpassen:** Tijdens het spelen kan op ieder gewenst moment geswitcht worden tussen:
    - **Alles (Direct):** Direct punten toevoegen via presets (5, 10, 15, ..., 50 pt).
    - **Berekend (Per schijf):** Schijf voor schijf tellen per ring (Centrum 20 pt, Binnenring 15 pt, Middenring 10 pt, Buitenring 5 pt) met handige steppers en automatische subtotalen.
  - Duidelijke preview op de "Ronde beëindigen" knop die direct toont hoeveel differentiële punten er naar welk team gaan.
* [`JattenSetupView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/JattenSetupView.swift) & [`JattenGameView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/JattenGameView.swift):
  - Aantal rondes keuze verwijderd (spel stopt immers zodra iemand 6 dezelfde heeft).
  - **Puntentelling en `+` invoerknoppen verwijderd:** Jatten kent geen punten per ronde. De overbodige `+` knop en het dropdown-invoerscherm (`-1`, `+1`, `+5`, `+10`) zijn volledig weggehaald.
  - Prominente `🏆 6 dezelfde!` knop op elke spelerskaart voor directe winst en overgang naar `WinnaarView`.
  - Startspeler-indicator ("Wie mag beginnen?") en steelbeurt-indicator ("Aan de beurt") om de steelvolgorde bij te houden.
* [`WinnaarView.swift`](file:///Users/niels/Documents/apps/GamesApp/GamesApp/WinnaarView.swift): Eindscherm met animaties, podium en automatische opslag naar `ScoreManager`.

---

## 3. Datamodel & Persistentie (`ScoreManager.swift`)

Data wordt als JSON opgeslagen in `UserDefaults`.

```swift
struct GameHistory: Identifiable, Codable {
    let id: UUID
    let date: Date
    let gameType: String
    let players: [PlayerScore]
    let winner: String
}

struct PlayerScore: Identifiable, Codable {
    let id: UUID
    let name: String
    let score: Int
    var juisteBalzakken: Int = 0  // Aantal keren BALZAK! (0 punten)
    var fouteBalzakken: Int = 0   // Aantal keren Valse Balzak (+25)
}
```

> **Belangrijk:** Houd bij eventuele aanpassingen in `PlayerScore` rekening met backward-compatibility (gebruik default values bij decoding zodat bestaande bewaarde potjes in `UserDefaults` niet crashen).

---

## 4. Git & Workflow op de MacBook

### Eenmalig clonen op de MacBook:
```bash
git clone https://github.com/nielsnathaniel/GamesApp.git
cd GamesApp
open GamesApp.xcodeproj
```

### Dagelijkse routine:
1. **Voor je begint:**
   ```bash
   git pull origin main
   ```
   *(Of in Xcode: Integrate -> Pull...)*
2. **Klaar met werken:**
   ```bash
   git add .
   git commit -m "Beschrijving van je aanpassingen"
   git push origin main
   ```
   *(Of in Xcode: Integrate -> Commit... met 'Push to remote' aangevinkt)*

---

## 5. Ontwikkel- en Bouwinstructies

### Testen & Bouwen via CLI:
```bash
xcodebuild -scheme GamesApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

### Richtlijnen voor UI & Code:
* **UI Design:** Modern iOS design, strakke cards, afgeronde hoeken (`.clipShape(RoundedRectangle(cornerRadius: 16))`), SF Symbols en levendige kleuraccenten.
* **Geen hardcoded logica doorbreken:** De spelregels (bijv. 69 en 99 regels bij Balzakken, kaartwaarden bij Duizenden, laagste score wint bij Beverbende) moeten te allen tijde bewaard blijven.
* **Taal:** Alle labels, knoppen, dialogen en teksten zijn in het **Nederlands**.

---
*Gegenereerd voor naadloze overdracht naar Antigravity op macOS.*
