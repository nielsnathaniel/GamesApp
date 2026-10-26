import SwiftUI

struct TafelschikkingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var seatedPlayers: [String] = []
    @State private var startPlayerIndex: Int? = nil
    @State private var needleRotation: Double = 0.0
    @State private var isSpinning: Bool = false
    @State private var showConfetti: Bool = false
    @State private var newPlayerName: String = ""
    @State private var showAddPlayerSheet: Bool = false
    @State private var showReorderSheet: Bool = false
    @State private var selectedSwapIndex: Int? = nil

    // Drag & Drop State
    @State private var draggedPlayerIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var hoverTargetIndex: Int? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Sfeervolle donkere speeltafel achtergrond
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.10, blue: 0.13),
                        Color(red: 0.04, green: 0.05, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    // Header balk met status
                    headerBar

                    // Snelle spelerskiezer (chips)
                    savedPlayersSection

                    // De interactieve ronde tafel
                    GeometryReader { geo in
                        let tableSize = min(geo.size.width, geo.size.height) * 0.88
                        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                        let tableRadius = tableSize / 2

                        ZStack {
                            // Tafel ondergrond met vilt-effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.12, green: 0.35, blue: 0.22), // Groen vilt
                                            Color(red: 0.06, green: 0.20, blue: 0.12),
                                            Color(red: 0.03, green: 0.10, blue: 0.06)
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: tableRadius
                                    )
                                )
                                .frame(width: tableSize, height: tableSize)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.85, green: 0.65, blue: 0.30), // Goud/houten rand
                                                    Color(red: 0.45, green: 0.30, blue: 0.12),
                                                    Color(red: 0.85, green: 0.65, blue: 0.30)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 8
                                        )
                                )
                                .shadow(color: .black.opacity(0.6), radius: 14, x: 0, y: 8)

                            // Kloksgewijze richtingspijlen op het laken
                            if seatedPlayers.count >= 2 {
                                Circle()
                                    .stroke(
                                        Color.white.opacity(0.12),
                                        style: StrokeStyle(lineWidth: 2, dash: [6, 8])
                                    )
                                    .frame(width: tableSize * 0.65, height: tableSize * 0.65)

                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption2)
                                    Text("MET DE KLOK MEE")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .tracking(1.2)
                                }
                                .foregroundColor(.white.opacity(0.35))
                                .offset(y: -tableRadius * 0.35)
                            }

                            // Centrale spil / kompasnaald
                            centerSpinner(radius: tableRadius)

                            // Spelers op de stoelen rondom de tafel
                            if seatedPlayers.isEmpty {
                                emptyTablePlaceholder
                            } else {
                                ForEach(Array(seatedPlayers.enumerated()), id: \.offset) { index, player in
                                    playerSeatView(
                                        player: player,
                                        index: index,
                                        total: seatedPlayers.count,
                                        center: center,
                                        radius: tableRadius * 0.82
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Bedieningsknoppen onderaan
                    controlButtons
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Tafelschikking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Klaar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Snelle knop om volgorde via lijst aan te passen
                        Button(action: { showReorderSheet = true }) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        .disabled(seatedPlayers.count < 2)

                        Menu {
                            Button(action: { showReorderSheet = true }) {
                                Label("Volgorde lijst", systemImage: "list.number")
                            }
                            .disabled(seatedPlayers.count < 2)

                            Button(action: randomizeSeats) {
                                Label("Hussel stoelen", systemImage: "shuffle")
                            }
                            .disabled(seatedPlayers.count < 2)

                            Button(action: shiftSeatsClockwise) {
                                Label("Draai 1 stoel door", systemImage: "arrow.clockwise")
                            }
                            .disabled(seatedPlayers.count < 2)

                            Button(role: .destructive, action: {
                                seatedPlayers.removeAll()
                                startPlayerIndex = nil
                            }) {
                                Label("Tafel leegmaken", systemImage: "trash")
                            }
                            .disabled(seatedPlayers.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showReorderSheet) {
                reorderSheet
            }
            .onAppear {
                loadInitialPlayers()
            }
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "person.3.sequence.fill")
                        .foregroundColor(.green)
                    Text("Wie zit waar?")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text(seatedPlayers.count < 2 ? "Voeg minimaal 2 spelers toe aan de tafel" : "Sleep een speler naar een andere stoel om te wisselen")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()

            if let startIndex = startPlayerIndex, seatedPlayers.indices.contains(startIndex) {
                HStack(spacing: 6) {
                    Text("Startspeler:")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    Text(seatedPlayers[startIndex])
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.2))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Saved Players Quick Chips
    private var savedPlayersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Knop om direct een nieuwe naam toe te voegen
                Button(action: { showAddPlayerSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Speler")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }

                ForEach(scoreManager.savedPlayerNames, id: \.self) { name in
                    let isSeated = seatedPlayers.contains(name)
                    Button(action: {
                        togglePlayer(name)
                    }) {
                        HStack(spacing: 6) {
                            PlayerAvatarView(name: name, size: 20)
                            Text(name)
                                .font(.caption)
                                .fontWeight(isSeated ? .bold : .medium)
                                .foregroundColor(.white)

                            if isSeated {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSeated ? Color.green.opacity(0.25) : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSeated ? Color.green : Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showAddPlayerSheet) {
            addCustomPlayerSheet
        }
    }

    // MARK: - Add Player Sheet
    private var addCustomPlayerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Naam van de speler", text: $newPlayerName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .padding(.top, 20)

                Button("Aan tafel zetten") {
                    let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && !seatedPlayers.contains(trimmed) {
                        seatedPlayers.append(trimmed)
                        scoreManager.savePlayerName(trimmed)
                        newPlayerName = ""
                        showAddPlayerSheet = false
                    }
                }
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .navigationTitle("Nieuwe Speler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") { showAddPlayerSheet = false }
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }

    // MARK: - Reorder Sheet (Drag Handles)
    private var reorderSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(seatedPlayers, id: \.self) { player in
                        HStack(spacing: 12) {
                            PlayerAvatarView(name: player, size: 36)
                            Text(player)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .onMove { indices, newOffset in
                        seatedPlayers.move(fromOffsets: indices, toOffset: newOffset)
                        startPlayerIndex = nil
                    }
                } footer: {
                    Text("Sleep de hendels rechts om de zitplaatsen met de klok mee te herschikken.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Tafelvolgorde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klaar") {
                        showReorderSheet = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Center Spinner (Bottle / Compass Needle)
    private func centerSpinner(radius: CGFloat) -> some View {
        ZStack {
            // Centrale cirkel / as
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.95, green: 0.75, blue: 0.30), Color(red: 0.50, green: 0.35, blue: 0.10)],
                        center: .center,
                        startRadius: 5,
                        endRadius: 35
                    )
                )
                .frame(width: 58, height: 58)
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)

            // De draaiende naald / pijl
            VStack(spacing: 0) {
                // Wijzerkop
                PolygonTriangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 22, height: radius * 0.62)
                    .shadow(color: .yellow.opacity(0.6), radius: 6, x: 0, y: 0)

                // Balansuiteinde
                Circle()
                    .fill(Color.orange)
                    .frame(width: 14, height: 14)
            }
            .offset(y: -radius * 0.28)
            .rotationEffect(.degrees(needleRotation))

            // Centrum gouden knop
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 16, height: 16)
        }
    }

    // MARK: - Player Seat View (with Direct Circular Drag & Drop)
    private func playerSeatView(
        player: String,
        index: Int,
        total: Int,
        center: CGPoint,
        radius: CGFloat
    ) -> some View {
        // Bereken positie op de cirkel (start bovenaan -π/2 en ga met de klok mee)
        let angle = (2.0 * Double.pi * Double(index) / Double(total)) - (Double.pi / 2.0)
        let baseX = radius * cos(angle)
        let baseY = radius * sin(angle)

        let isStartPlayer = startPlayerIndex == index
        let turnOrder = turnOrderLabel(for: index)
        let isSelectedForSwap = selectedSwapIndex == index
        let isDraggingThis = draggedPlayerIndex == index
        let isHoverTarget = hoverTargetIndex == index

        let currentX = isDraggingThis ? (baseX + dragOffset.width) : baseX
        let currentY = isDraggingThis ? (baseY + dragOffset.height) : baseY

        return VStack(spacing: 3) {
            ZStack(alignment: .topTrailing) {
                PlayerAvatarView(name: player, size: 48)
                    .overlay(
                        Circle()
                            .stroke(
                                isDraggingThis ? Color.green : (isHoverTarget ? Color.cyan : (isStartPlayer ? Color.yellow : (isSelectedForSwap ? Color.cyan : Color.white.opacity(0.4)))),
                                lineWidth: (isDraggingThis || isHoverTarget) ? 4.0 : (isStartPlayer ? 3.5 : (isSelectedForSwap ? 3 : 1.5))
                            )
                    )
                    .scaleEffect(isDraggingThis ? 1.25 : (isHoverTarget ? 1.15 : 1.0))
                    .shadow(
                        color: isDraggingThis ? Color.green.opacity(0.9) : (isHoverTarget ? Color.cyan.opacity(0.9) : (isStartPlayer ? Color.yellow.opacity(0.8) : Color.black.opacity(0.3))),
                        radius: isDraggingThis ? 14 : (isHoverTarget ? 10 : (isStartPlayer ? 8 : 3))
                    )

                // Beurtvolgorde badge (bijv. 👑 1e, 2e, 3e...)
                if let turn = turnOrder {
                    Text(turn)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isStartPlayer ? .black : .white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(isStartPlayer ? Color.yellow : Color.black.opacity(0.75))
                        .clipShape(Capsule())
                        .offset(x: 10, y: -4)
                }
            }

            // Naam en wisselknop
            Text(isHoverTarget ? "Wissel" : player)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isHoverTarget ? .cyan : .white)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(isHoverTarget ? Color.cyan.opacity(0.35) : Color.black.opacity(0.6))
                .clipShape(Capsule())
        }
        .offset(x: currentX, y: currentY)
        .zIndex(isDraggingThis ? 100 : (isHoverTarget ? 50 : 1))
        .gesture(
            DragGesture(minimumDistance: 3, coordinateSpace: .global)
                .onChanged { gesture in
                    handleDragChanged(index: index, translation: gesture.translation, radius: radius, total: total)
                }
                .onEnded { gesture in
                    handleDragEnded(index: index)
                }
        )
        .onTapGesture {
            handleSeatTap(index: index)
        }
    }

    // MARK: - Turn Order Calculation
    private func turnOrderLabel(for index: Int) -> String? {
        guard let start = startPlayerIndex, seatedPlayers.count >= 2 else { return nil }
        let total = seatedPlayers.count
        let offset = (index - start + total) % total
        if offset == 0 {
            return "👑 1e"
        } else {
            return "\(offset + 1)e"
        }
    }

    // MARK: - Empty Table Placeholder
    private var emptyTablePlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.6))

            Text("Tik op spelers hierboven om\nze aan tafel te zetten")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        VStack(spacing: 10) {
            if let swapIdx = selectedSwapIndex, seatedPlayers.indices.contains(swapIdx) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.cyan)
                    Text("Tik op een andere stoel om te wisselen met \(seatedPlayers[swapIdx])")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Spacer()
                    Button("Annuleren") { selectedSwapIndex = nil }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
            }

            if seatedPlayers.count >= 2 {
                Button(action: { showReorderSheet = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Pas volgorde aan via lijst")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                }
            }

            HStack(spacing: 12) {
                // Wissel / Schikking knop
                Button(action: shiftSeatsClockwise) {
                    Label("1 Stoel door", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(12)
                }
                .disabled(seatedPlayers.count < 2 || isSpinning)

                // Hoofdknop: Startspeler kiezen via pijl
                Button(action: spinNeedle) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.headline)
                        Text(isSpinning ? "Draait..." : (startPlayerIndex == nil ? "Kies Startspeler" : "Opnieuw Draaien"))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: seatedPlayers.count >= 2 ? [Color.yellow, Color.orange] : [Color.gray, Color.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: seatedPlayers.count >= 2 ? Color.orange.opacity(0.5) : .clear, radius: 8, x: 0, y: 4)
                }
                .disabled(seatedPlayers.count < 2 || isSpinning)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Logic & Actions
    private func loadInitialPlayers() {
        if seatedPlayers.isEmpty {
            let saved = scoreManager.savedPlayerNames
            if saved.count >= 2 {
                seatedPlayers = Array(saved.prefix(6))
            }
        }
    }

    private func togglePlayer(_ name: String) {
        HapticManager.shared.light()
        if let idx = seatedPlayers.firstIndex(of: name) {
            seatedPlayers.remove(at: idx)
            startPlayerIndex = nil
        } else {
            if seatedPlayers.count < 10 {
                seatedPlayers.append(name)
                startPlayerIndex = nil
            }
        }
    }

    private func handleSeatTap(index: Int) {
        HapticManager.shared.light()
        if let first = selectedSwapIndex {
            if first != index {
                seatedPlayers.swapAt(first, index)
                startPlayerIndex = nil
            }
            selectedSwapIndex = nil
        } else {
            selectedSwapIndex = index
        }
    }

    // MARK: - Drag Gesture Handling
    private func handleDragChanged(index: Int, translation: CGSize, radius: CGFloat, total: Int) {
        guard !isSpinning, total >= 2 else { return }
        if draggedPlayerIndex == nil {
            draggedPlayerIndex = index
            selectedSwapIndex = nil
            HapticManager.shared.light()
        }
        dragOffset = translation

        // Bereken positie van vinger ten opzichte van tafelcentrum
        let originalAngle = (2.0 * Double.pi * Double(index) / Double(total)) - (Double.pi / 2.0)
        let fingerX = (radius * cos(originalAngle)) + translation.width
        let fingerY = (radius * sin(originalAngle)) + translation.height

        // Zoek de dichtstbijzijnde andere stoel
        var closestIdx: Int? = nil
        var minDistance: CGFloat = 85.0 // Ruime magnetische radius voor soepel oppikken

        for j in 0..<total where j != index {
            let jAngle = (2.0 * Double.pi * Double(j) / Double(total)) - (Double.pi / 2.0)
            let jX = radius * cos(jAngle)
            let jY = radius * sin(jAngle)
            let dist = hypot(fingerX - jX, fingerY - jY)
            if dist < minDistance {
                minDistance = dist
                closestIdx = j
            }
        }

        if hoverTargetIndex != closestIdx {
            hoverTargetIndex = closestIdx
            if closestIdx != nil {
                HapticManager.shared.light()
            }
        }
    }

    private func handleDragEnded(index: Int) {
        if let target = hoverTargetIndex, target != index {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                seatedPlayers.swapAt(index, target)
                startPlayerIndex = nil
            }
            HapticManager.shared.success()
        }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            dragOffset = .zero
            draggedPlayerIndex = nil
            hoverTargetIndex = nil
        }
    }

    private func shiftSeatsClockwise() {
        HapticManager.shared.light()
        guard seatedPlayers.count > 1 else { return }
        let last = seatedPlayers.removeLast()
        seatedPlayers.insert(last, at: 0)
        startPlayerIndex = nil
    }

    private func randomizeSeats() {
        HapticManager.shared.medium()
        seatedPlayers.shuffle()
        startPlayerIndex = nil
    }

    private func spinNeedle() {
        guard seatedPlayers.count >= 2, !isSpinning else { return }
        isSpinning = true
        selectedSwapIndex = nil
        startPlayerIndex = nil

        // Kies willekeurig een winnaar
        let winner = Int.random(in: 0..<seatedPlayers.count)

        // Bereken exacte hoek van de speler
        let playerAngle = Double(winner) * (360.0 / Double(seatedPlayers.count))

        // Voeg 5 tot 7 volle rondes toe voor een spectaculaire spin
        let fullRotations = Double(Int.random(in: 5...7)) * 360.0
        let targetRotation = needleRotation + fullRotations + (playerAngle - (needleRotation.truncatingRemainder(dividingBy: 360.0)))

        HapticManager.shared.medium()

        withAnimation(.timingCurve(0.15, 0.85, 0.25, 1.0, duration: 3.2)) {
            needleRotation = targetRotation
        }

        // Simuleer tikkende haptics tijdens de vertraging
        scheduleTickHaptics()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            isSpinning = false
            startPlayerIndex = winner
            HapticManager.shared.success()
        }
    }

    private func scheduleTickHaptics() {
        let delays = [0.2, 0.5, 0.9, 1.4, 1.9, 2.3, 2.7, 3.0]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if isSpinning {
                    HapticManager.shared.light()
                }
            }
        }
    }
}

// MARK: - Polygon Triangle Shape for Pointer
struct PolygonTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // Pijl punt
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    TafelschikkingView()
}
