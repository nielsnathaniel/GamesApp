import SwiftUI

struct JattenSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var aantalSpelers: Int = 3
    @State private var spelers: [String] = Array(repeating: "", count: 5)
    @State private var showAlert = false
    @FocusState private var focusedField: Int?

    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 12) {
                    if UIImage(named: "Jatten") != nil {
                        Image("Jatten")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.purple)
                    }
                    
                    Text("Jatten")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 0)
                .frame(maxWidth: .infinity, alignment: .center)

                // Kies aantal spelers (2 t/m 5)
                Text("Aantal Spelers")
                    .font(.headline)
                    .padding(.top, 8)

                HStack(spacing: 12) {
                    ForEach(2...5, id: \.self) { number in
                        Button(action: {
                            aantalSpelers = number
                        }) {
                            Text("\(number)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(aantalSpelers == number ? .white : .purple)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(aantalSpelers == number ? Color.purple : Color.clear)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.purple, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()

                // Speluitleg / info kaart
                HStack(spacing: 10) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Speldoel")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Het spel stopt zodra een speler als eerste 6 kaarten van dezelfde waarde verzameld heeft!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 12)

                // Invoervelden voor spelersnamen met dropdown voorstellen
                VStack(spacing: 12) {
                    ForEach(0..<aantalSpelers, id: \.self) { index in
                        PlayerNameInputField(
                            placeholder: "Naam Speler \(index + 1)",
                            text: $spelers[index],
                            suggestions: scoreManager.savedPlayerNames,
                            submitLabel: index < aantalSpelers - 1 ? .next : .done
                        )
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 20)

                // Start spel knop
                NavigationLink(destination: JattenGameView(spelers: spelers.prefix(aantalSpelers).map { Player(name: $0) })) {
                    Text("Start Spel")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    scoreManager.savePlayerNames(spelers.prefix(aantalSpelers).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
                })
                .padding(.horizontal)
                .disabled(spelers.prefix(aantalSpelers).contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }))
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Invoerfout"), message: Text("Vul alle spelersnamen in."), dismissButton: .default(Text("OK")))
                }
            }
            .padding()
        }
        .onAppear {
            scoreManager.refresh()
        }
    }
}

#Preview {
    JattenSetupView()
}
