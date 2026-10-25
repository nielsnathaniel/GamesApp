import UIKit

/// Centrale beheerder voor voelbare trillingen (Haptic Feedback) via de iPhone Taptic Engine
final class HapticManager {
    static let shared = HapticManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        // Pre-warm generators for lower latency
        lightGenerator.prepare()
        selectionGenerator.prepare()
    }

    /// Lichte tik (bijv. bij navigatie, chips aantikken, startspeler aftellen)
    func light() {
        lightGenerator.impactOccurred()
    }

    /// Medium tik (bijv. bij punten optellen/aftrekken, knop indrukken)
    func medium() {
        mediumGenerator.impactOccurred()
    }

    /// Zware tik (bijv. bij ronde afronden, beurt wissel)
    func heavy() {
        heavyGenerator.impactOccurred()
    }

    /// Subtiele selectie-klik (bijv. bij segmented pickers, steppers, schijven)
    func selection() {
        selectionGenerator.selectionChanged()
    }

    /// Succes trilling (bijv. bij winst, juiste gok, spel opgeslagen)
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Waarschuwing trilling (bijv. bij laatste 3 seconden van een timer)
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Fout trilling (bijv. bij tijd om, ongeldige invoer, valse balzak)
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    /// Feestelijke opeenvolgende trillingen voor het winnaarscherm
    func celebration() {
        notificationGenerator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            self?.heavyGenerator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) { [weak self] in
            self?.notificationGenerator.notificationOccurred(.success)
        }
    }
}
