import SwiftUI

/// Herbruikbare avatar view voor spelers:
/// Toont foto (indien gekozen), avatar-emoji (indien gekozen),
/// of de initialen met de herkenbare tafelkleur van de speler.
struct PlayerAvatarView: View {
    var name: String
    var size: CGFloat = 36
    var showBorder: Bool = true
    var customProfile: PlayerProfile? = nil

    @ObservedObject private var scoreManager = ScoreManager.shared

    private var profile: PlayerProfile {
        if let custom = customProfile { return custom }
        return scoreManager.profile(for: name)
    }

    var body: some View {
        ZStack {
            if let photoData = profile.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let emoji = profile.emoji, !emoji.isEmpty {
                Circle()
                    .fill(profile.color.opacity(0.18))
                    .frame(width: size, height: size)
                Text(emoji)
                    .font(.system(size: size * 0.52))
            } else {
                Circle()
                    .fill(profile.color.opacity(0.20))
                    .frame(width: size, height: size)
                Text(profile.initials)
                    .font(.system(size: max(9, size * 0.40), weight: .bold, design: .rounded))
                    .foregroundColor(profile.color)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(profile.color.opacity(showBorder ? 0.45 : 0.0), lineWidth: max(1.5, size * 0.045))
        )
        .shadow(color: profile.color.opacity(showBorder ? 0.20 : 0.0), radius: 3, x: 0, y: 1)
    }
}
