import Foundation
import AVFoundation
import AudioToolbox
import SwiftUI

/// Centraal audiobeheer voor geluidseffecten, timers en bordspelacties.
/// Genereert standalone PCM audiogolven in het geheugen zodat er geen externe mp3's nodig zijn.
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @AppStorage("app_sound_enabled") var isSoundEnabled: Bool = true

    private var audioPlayers: [String: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
        prepareAudioBuffers()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SoundManager: Kon audiosessie niet initialiseren: \(error)")
        }
    }

    // MARK: - Geluiden Voorbereiden (In-Memory Synthesized Audio)
    private func prepareAudioBuffers() {
        // 1. Zachte kloktik (1000Hz, 35ms)
        if let tickData = createWaveData(type: .tick) {
            audioPlayers["tick"] = try? AVAudioPlayer(data: tickData)
            audioPlayers["tick"]?.prepareToPlay()
        }

        // 2. Luide timer zoemer (Bzzzzzzt, 220Hz zaagtand met resonantie, 800ms)
        if let buzzerData = createWaveData(type: .buzzer) {
            audioPlayers["buzzer"] = try? AVAudioPlayer(data: buzzerData)
            audioPlayers["buzzer"]?.prepareToPlay()
        }

        // 3. Goeie Balzak / Triomf Fanfare (Majeur drieklank)
        if let successData = createWaveData(type: .successChime) {
            audioPlayers["success"] = try? AVAudioPlayer(data: successData)
            audioPlayers["success"]?.prepareToPlay()
        }

        // 4. Valse Balzak / Komische fail honk
        if let failData = createWaveData(type: .failHonk) {
            audioPlayers["fail"] = try? AVAudioPlayer(data: failData)
            audioPlayers["fail"]?.prepareToPlay()
        }
    }

    // MARK: - Publieke Afspeelmethodes
    func playTimerTick() {
        guard isSoundEnabled else { return }
        play(soundKey: "tick", fallbackSystemSound: 1057)
    }

    func playTimerBuzzer() {
        guard isSoundEnabled else { return }
        play(soundKey: "buzzer", fallbackSystemSound: 1025)
    }

    func playBalzakGood() {
        guard isSoundEnabled else { return }
        play(soundKey: "success", fallbackSystemSound: 1022)
    }

    func playBalzakFail() {
        guard isSoundEnabled else { return }
        play(soundKey: "fail", fallbackSystemSound: 1006)
    }

    private func play(soundKey: String, fallbackSystemSound: SystemSoundID) {
        if let player = audioPlayers[soundKey] {
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(fallbackSystemSound)
        }
    }

    // MARK: - Audio Synthesizer (PCM WAV Generator)
    private enum SoundType {
        case tick
        case buzzer
        case successChime
        case failHonk
    }

    private func createWaveData(type: SoundType) -> Data? {
        let sampleRate: Double = 44100.0

        let duration: Double
        switch type {
        case .tick: duration = 0.04
        case .buzzer: duration = 0.85
        case .successChime: duration = 0.50
        case .failHonk: duration = 0.60
        }

        let numSamples = Int(sampleRate * duration)
        var samples = [Int16]()
        samples.reserveCapacity(numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            var sample: Double = 0.0

            switch type {
            case .tick:
                // Korte felle klik met exponentiële decay
                let envelope = exp(-t * 90.0)
                sample = sin(2.0 * .pi * 1200.0 * t) * envelope

            case .buzzer:
                // Bordspelzoemer: 220Hz grondtoon + 440Hz & 880Hz harmonischen (zaagtand/vierkant)
                let envelope: Double
                if t < 0.05 {
                    envelope = t / 0.05 // snelle fade-in
                } else if t > duration - 0.1 {
                    envelope = (duration - t) / 0.1 // zachte fade-out
                } else {
                    envelope = 1.0
                }
                let wave1 = sin(2.0 * .pi * 220.0 * t)
                let wave2 = sin(2.0 * .pi * 440.0 * t) * 0.6
                let wave3 = sin(2.0 * .pi * 660.0 * t) * 0.4
                sample = (wave1 + wave2 + wave3) * 0.55 * envelope

            case .successChime:
                // Majeur akkoord: C5 (523Hz), E5 (659Hz), G5 (784Hz) opbouwend
                let envelope = 1.0 - (t / duration)
                let freq: Double
                if t < 0.15 {
                    freq = 523.25
                } else if t < 0.30 {
                    freq = 659.25
                } else {
                    freq = 783.99
                }
                sample = sin(2.0 * .pi * freq * t) * envelope * 0.8

            case .failHonk:
                // Omlaag glijdende komische 'wah' (van 240Hz naar 140Hz)
                let envelope = 1.0 - (t / duration)
                let currentFreq = 240.0 - (100.0 * (t / duration))
                sample = sin(2.0 * .pi * currentFreq * t) * envelope * 0.75
            }

            // Normaliseer naar Int16 bereik (-32767 tot 32767)
            let clamped = max(-1.0, min(1.0, sample))
            samples.append(Int16(clamped * 32760.0))
        }

        return makeWavData(samples: samples, sampleRate: Int(sampleRate))
    }

    private func makeWavData(samples: [Int16], sampleRate: Int) -> Data {
        var data = Data()
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample) / 8)
        let blockAlign = Int16(numChannels * bitsPerSample / 8)
        let subchunk2Size = Int32(samples.count * 2)
        let chunkSize = Int32(36 + subchunk2Size)

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(withUnsafeBytes(of: chunkSize.littleEndian) { Data($0) })
        data.append(contentsOf: "WAVE".utf8)

        // fmt subchunk
        data.append(contentsOf: "fmt ".utf8)
        let subchunk1Size: Int32 = 16
        data.append(withUnsafeBytes(of: subchunk1Size.littleEndian) { Data($0) })
        let audioFormat: Int16 = 1 // PCM
        data.append(withUnsafeBytes(of: audioFormat.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        let sampleRateInt32 = Int32(sampleRate)
        data.append(withUnsafeBytes(of: sampleRateInt32.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })

        // data subchunk
        data.append(contentsOf: "data".utf8)
        data.append(withUnsafeBytes(of: subchunk2Size.littleEndian) { Data($0) })

        // Audio samples
        samples.withUnsafeBufferPointer { buffer in
            data.append(Data(buffer: buffer))
        }

        return data
    }
}
