import SwiftUI

struct PlayerNameInputField: View {
    var placeholder: String
    @Binding var text: String
    var suggestions: [String]
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool
    @State private var isShowingDropdown: Bool = false

    private var filteredSuggestions: [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return suggestions.filter { candidate in
            let lowerCandidate = candidate.lowercased()
            let lowerInput = trimmed.lowercased()
            return lowerCandidate.contains(lowerInput) && lowerCandidate != lowerInput
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .submitLabel(submitLabel)
                .onSubmit {
                    isShowingDropdown = false
                    onSubmit?()
                }
                .onChange(of: text) { _ in
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    isShowingDropdown = !trimmed.isEmpty && !filteredSuggestions.isEmpty
                }
                .onChange(of: isFocused) { focused in
                    if focused {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        isShowingDropdown = !trimmed.isEmpty && !filteredSuggestions.isEmpty
                    } else {
                        // Korte vertraging zodat de tap op de suggestieknop geregistreerd kan worden
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if !isFocused {
                                isShowingDropdown = false
                            }
                        }
                    }
                }

            if isShowingDropdown && !filteredSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredSuggestions.prefix(4), id: \.self) { item in
                        Button(action: {
                            text = item
                            isShowingDropdown = false
                            isFocused = false
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .foregroundColor(.blue)
                                Text(item)
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Selecteer")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        if item != filteredSuggestions.prefix(4).last {
                            Divider()
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .zIndex(10)
            }
        }
    }
}

#Preview {
    PlayerNameInputField(placeholder: "Speler 1", text: .constant("N"), suggestions: ["Niels", "Nick", "Anna"])
}
