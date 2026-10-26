import SwiftUI
import PhotosUI

/// Sheet om tafelkleur en optionele avatar (emoji of foto) voor een speler in te stellen.
struct PlayerProfileEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var scoreManager = ScoreManager.shared

    let playerName: String

    @State private var selectedColorHex: String = "#3B82F6"
    @State private var selectedEmoji: String? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    init(playerName: String) {
        self.playerName = playerName
    }

    private var currentDraftProfile: PlayerProfile {
        PlayerProfile(
            name: playerName,
            colorHex: selectedColorHex,
            emoji: selectedEmoji,
            photoData: selectedPhotoData
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Live Avatar Preview Header
                    VStack(spacing: 12) {
                        PlayerAvatarView(
                            name: playerName,
                            size: 96,
                            showBorder: true,
                            customProfile: currentDraftProfile
                        )
                        .padding(.top, 8)

                        Text(playerName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Kies een herkenbare tafelkleur en optioneel een avatar of foto")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // 1. Tafelkleuren
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(Color(hex: selectedColorHex) ?? .blue)
                            Text("Tafelkleur")
                                .font(.headline)
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(TableColorPalette.colors, id: \.self) { hex in
                                let isSelected = (selectedColorHex.uppercased() == hex.uppercased())
                                Button(action: {
                                    HapticManager.shared.light()
                                    selectedColorHex = hex
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: hex) ?? .blue)
                                            .frame(width: 44, height: 44)

                                        if isSelected {
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: 3)
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .shadow(color: (Color(hex: hex) ?? .blue).opacity(isSelected ? 0.45 : 0.2), radius: isSelected ? 5 : 2, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 2. Foto van Camera Roll
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .foregroundColor(.blue)
                            Text("Eigen Foto (Optioneel)")
                                .font(.headline)
                        }
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                    Text(selectedPhotoData != nil ? "Wijzig Foto" : "Kies Foto uit Bibliotheek")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        // Comprimeer en sla op
                                        if let image = UIImage(data: data),
                                           let compressed = image.jpegData(compressionQuality: 0.6) {
                                            await MainActor.run {
                                                selectedPhotoData = compressed
                                                selectedEmoji = nil // Foto heeft voorrang
                                                HapticManager.shared.light()
                                            }
                                        }
                                    }
                                }
                            }

                            if selectedPhotoData != nil {
                                Button(action: {
                                    HapticManager.shared.light()
                                    selectedPhotoData = nil
                                    selectedPhotoItem = nil
                                }) {
                                    Text("Verwijder Foto")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.red.opacity(0.12))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 3. Emoji Avatars
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "face.smiling.fill")
                                .foregroundColor(.orange)
                            Text("Emoji Avatar (Optioneel)")
                                .font(.headline)
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(AvatarEmojiPalette.emojis, id: \.self) { emoji in
                                let isSelected = (selectedEmoji == emoji && selectedPhotoData == nil)
                                Button(action: {
                                    HapticManager.shared.light()
                                    selectedPhotoData = nil
                                    selectedPhotoItem = nil
                                    if selectedEmoji == emoji {
                                        selectedEmoji = nil // Deselecteren = terug naar initialen
                                    } else {
                                        selectedEmoji = emoji
                                    }
                                }) {
                                    Text(emoji)
                                        .font(.system(size: 26))
                                        .frame(width: 46, height: 46)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(isSelected ? Color(hex: selectedColorHex)?.opacity(0.25) ?? Color.blue.opacity(0.25) : Color(UIColor.secondarySystemGroupedBackground))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color(hex: selectedColorHex) ?? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)

                        if selectedEmoji != nil || selectedPhotoData != nil {
                            Button(action: {
                                HapticManager.shared.light()
                                selectedEmoji = nil
                                selectedPhotoData = nil
                                selectedPhotoItem = nil
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Gebruik standaard initialen")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Spelerprofiel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Opslaan") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                loadExistingProfile()
            }
        }
    }

    private func loadExistingProfile() {
        let existing = scoreManager.profile(for: playerName)
        selectedColorHex = existing.colorHex
        selectedEmoji = existing.emoji
        selectedPhotoData = existing.photoData
    }

    private func saveProfile() {
        HapticManager.shared.success()
        let updated = PlayerProfile(
            name: playerName,
            colorHex: selectedColorHex,
            emoji: selectedEmoji,
            photoData: selectedPhotoData
        )
        scoreManager.saveProfile(updated)
    }
}
