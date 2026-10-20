import SwiftUI

struct RandomNumberScreen: View {
    @Binding var randomNumbers: [Int]
    @Binding var currentRandomIndex: Int

    var body: some View {
        VStack {
            if currentRandomIndex < randomNumbers.count {
                Text("\(randomNumbers[currentRandomIndex])")
                    .font(.system(size: 100))
                    .onTapGesture {
                        currentRandomIndex += 1
                    }
            } else {
                VStack {
                    Text("Alle nummers zijn geweest!")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                    Button(action: {
                        currentRandomIndex = 0
                    }) {
                        Text("Terug")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(50)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.green)
            }

            if currentRandomIndex > 0 {
                Text("Vorige: \(randomNumbers[currentRandomIndex - 1])")
                    .font(.caption)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}
