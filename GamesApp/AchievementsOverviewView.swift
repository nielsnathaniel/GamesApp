import SwiftUI

struct AchievementsOverviewView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var selectedPlayer: String = ""
    @State private var filterMode: AchievementFilter = .all

    enum AchievementFilter: String, CaseIterable, Identifiable {
        case all = "Alle"
        case unlocked = "Ontgrendeld"
        case locked = "Nog te halen"

        var id: String { rawValue }
    }

    private var activePlayerName: String {
        if !selectedPlayer.isEmpty && scoreManager.savedPlayerNames.contains(selectedPlayer) {
            return selectedPlayer
        }
        return scoreManager.savedPlayerNames.first ?? "Speler"
    }

    private var achievements: [PlayerAchievementProgress] {
        AchievementManager.shared.evaluateAchievements(for: activePlayerName, in: scoreManager)
    }

    private var filteredAchievements: [PlayerAchievementProgress] {
        switch filterMode {
        case .all:
            return achievements
        case .unlocked:
            return achievements.filter { $0.isUnlocked }
        case .locked:
            return achievements.filter { !$0.isUnlocked }
        }
    }

    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Spelerkiezer Chips
                    playerSelectorChips

                    // Voortgang banner
                    progressBanner

                    // Filter switch
                    Picker("Filter", selection: $filterMode) {
                        ForEach(AchievementFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Badges Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredAchievements) { item in
                            achievementCard(item)
                        }
                    }
                    .padding(.horizontal)

                    if filteredAchievements.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "medal.star")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("Geen badges in deze categorie")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 30)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Bordspel Badges")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if selectedPlayer.isEmpty, let first = scoreManager.savedPlayerNames.first {
                    selectedPlayer = first
                }
            }
        }
    }

    // MARK: - Player Selector Chips
    private var playerSelectorChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(scoreManager.savedPlayerNames, id: \.self) { name in
                    let isSelected = activePlayerName == name
                    Button(action: {
                        HapticManager.shared.light()
                        selectedPlayer = name
                    }) {
                        HStack(spacing: 6) {
                            PlayerAvatarView(name: name, size: 22)
                            Text(name)
                                .font(.caption)
                                .fontWeight(isSelected ? .bold : .medium)
                                .foregroundColor(isSelected ? .white : .primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Progress Banner
    private var progressBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                    .frame(width: 70, height: 70)

                let total = max(1, achievements.count)
                Circle()
                    .trim(from: 0, to: CGFloat(unlockedCount) / CGFloat(total))
                    .stroke(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(unlockedCount)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    Text("/\(achievements.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(activePlayerName)'s Badges")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(unlockedCount == achievements.count ? "🏆 Alle badges ontgrendeld! Een echte grootmeester." : "Speel spellen om meer medailles en badges te ontgrendelen!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Achievement Card
    private func achievementCard(_ item: PlayerAchievementProgress) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(item.isUnlocked ? Color.yellow.opacity(0.18) : Color.gray.opacity(0.12))
                    .frame(width: 54, height: 54)

                Text(item.achievement.icon)
                    .font(.system(size: 28))
                    .grayscale(item.isUnlocked ? 0.0 : 0.9)
                    .opacity(item.isUnlocked ? 1.0 : 0.5)

                if item.isUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                        .offset(x: 18, y: -18)
                }
            }

            VStack(spacing: 4) {
                Text(item.achievement.title)
                    .font(.system(size: 13, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(item.isUnlocked ? .primary : .secondary)
                    .lineLimit(1)

                Text(item.achievement.game)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(item.isUnlocked ? .blue : .secondary.opacity(0.7))

                Text(item.achievement.description)
                    .font(.system(size: 10))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .frame(height: 38, alignment: .top)

                Text(item.progressText)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(item.isUnlocked ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(item.isUnlocked ? Color.green.opacity(0.12) : Color(UIColor.tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(item.isUnlocked ? Color.yellow.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: item.isUnlocked ? Color.yellow.opacity(0.15) : Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    AchievementsOverviewView()
}
