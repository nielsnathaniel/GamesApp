import SwiftUI

/// Een herbruikbaar invoerveld voor scores waarbij de gebruiker op het getal kan tikken
/// om direct met een cijfertoetsenbord (numberPad) te typen.
/// Bevat een 'Gereed' knop op de toetsenbordbalk en optioneel een '+/-' knop voor negatieve scores.
struct NumericScoreInputView: View {
    @Binding var score: Int
    var allowNegative: Bool = true
    var range: ClosedRange<Int>? = nil
    var tintColor: Color = .blue
    var placeholder: String = "0"
    var minWidth: CGFloat = 58
    var height: CGFloat = 36
    var font: Font = .title3

    @FocusState private var isFocused: Bool
    @State private var text: String = ""

    var body: some View {
        HStack(spacing: 2) {
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(font)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(minWidth: minWidth, minHeight: height)
                .focused($isFocused)
        }
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? tintColor : Color.secondary.opacity(0.3), lineWidth: isFocused ? 2 : 1)
        )
        .onAppear {
            text = "\(score)"
        }
        .onChange(of: score) { _, newScore in
            if !isFocused {
                text = "\(newScore)"
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused {
                // Als de score 0 is, maak het leeg zodat de gebruiker direct zijn getal kan intypen
                if text == "0" {
                    text = ""
                }
            } else {
                commitText()
            }
        }
        .onChange(of: text) { _, newText in
            parseAndApply(newText)
        }
        .toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    if allowNegative {
                        Button(action: {
                            score = -score
                            text = "\(score)"
                        }) {
                            Text("+ / -")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }

                    Spacer()

                    Button("Gereed") {
                        isFocused = false
                        commitText()
                    }
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(tintColor)
                }
            }
        }
    }

    private func parseAndApply(_ input: String) {
        let isNeg = input.hasPrefix("-")
        let digits = input.filter { $0.isNumber }
        if let val = Int(digits) {
            var applied = (isNeg && allowNegative) ? -val : val
            if let range = range {
                applied = min(range.upperBound, max(range.lowerBound, applied))
            }
            score = applied
        } else if digits.isEmpty {
            let fallback = (range?.lowerBound ?? 0) > 0 ? (range?.lowerBound ?? 0) : 0
            score = fallback
        }
    }

    private func commitText() {
        let isNeg = text.hasPrefix("-")
        let digits = text.filter { $0.isNumber }
        if let val = Int(digits) {
            var applied = (isNeg && allowNegative) ? -val : val
            if let range = range {
                applied = min(range.upperBound, max(range.lowerBound, applied))
            }
            score = applied
            text = "\(applied)"
        } else {
            let fallback = (range?.lowerBound ?? 0) > 0 ? (range?.lowerBound ?? 0) : 0
            score = fallback
            text = "\(fallback)"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var score: Int = 42
        var body: some View {
            VStack(spacing: 20) {
                Text("Score: \(score)")
                NumericScoreInputView(score: $score, tintColor: .orange)
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
