//
//  SynthAudioEngine.swift
//  Konin
//

import Foundation
import AVFoundation

final class SynthAudioEngine: @unchecked Sendable {
    static let shared = SynthAudioEngine()
    
    // MARK: - WW2 Ambience Player (Wartime chapters)
    private var ambiencePlayer: AVAudioPlayer?
    private var ambienceFadeTimer: Timer?
    
    // MARK: - Peaceful/COD Ambience Player (Peaceful chapters)
    private var peacefulPlayer: AVAudioPlayer?
    private var peacefulFadeTimer: Timer?
    
    private var isAmbienceActive: Bool = false
    private var isRunning = false
    private var currentChapter: Chapter = .krotoszyn
    
    // Volume per chapter (ambience intensity varies)
    private var ambienceTargetVolume: Float = 0.35
    
    // MARK: - Train Sound Effect Player
    private var trainPlayer: AVAudioPlayer?
    private var trainTargetVolume: Float = 0.55
    private var trainFadeTimer: Timer?
    
    private init() {
        setupAudioSession()
        prepareAmbiencePlayer()
        prepareTrainPlayer()
        preparePeacefulPlayer()
    }
    
    // MARK: - Audio Session
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to setup AVAudioSession: \(error)")
        }
        #endif
    }
    
    // MARK: - Player Setup
    
    private func prepareAmbiencePlayer() {
        guard let url = Bundle.main.url(forResource: "ww2-ambience", withExtension: "mp3") else {
            print("SynthAudioEngine: ww2-ambience.mp3 not found in bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.5
            player.prepareToPlay()
            self.ambiencePlayer = player
        } catch {
            print("SynthAudioEngine: Failed to create ambience player: \(error)")
        }
    }
    
    private func preparePeacefulPlayer() {
        let logPath = "/Users/dimasps32/Developer/gamejam/Konin/audio_debug.txt"
        func writeLog(_ message: String) {
            try? message.write(toFile: logPath, atomically: true, encoding: .utf8)
        }
        
        guard let url = Bundle.main.url(forResource: "cod-fh", withExtension: "mp3") else {
            writeLog("Error: cod-fh.mp3 not found in bundle main url")
            print("SynthAudioEngine: cod-fh.mp3 not found in bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.0
            player.prepareToPlay()
            self.peacefulPlayer = player
            writeLog("Success: cod-fh.mp3 loaded and prepared successfully. URL: \(url.absoluteString)")
        } catch {
            writeLog("Error: Failed to create AVAudioPlayer: \(error.localizedDescription)")
            print("SynthAudioEngine: Failed to create peaceful player: \(error)")
        }
    }
    
    private func prepareTrainPlayer() {
        guard let url = Bundle.main.url(forResource: "train-sound-effect", withExtension: "mp3") else {
            print("SynthAudioEngine: train-sound-effect.mp3 not found in bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.3
            player.prepareToPlay()
            self.trainPlayer = player
        } catch {
            print("SynthAudioEngine: Failed to create train player: \(error)")
        }
    }
    
    // MARK: - Public API
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
    }
    
    func stop() {
        isRunning = false
        ambienceFadeTimer?.invalidate()
        ambienceFadeTimer = nil
        peacefulFadeTimer?.invalidate()
        peacefulFadeTimer = nil
        trainFadeTimer?.invalidate()
        trainFadeTimer = nil
        
        ambiencePlayer?.stop()
        ambiencePlayer?.volume = 0.0
        peacefulPlayer?.stop()
        peacefulPlayer?.volume = 0.0
        trainPlayer?.stop()
        trainPlayer?.volume = 0.0
    }
    
    func setAmbienceActive(_ active: Bool) {
        isAmbienceActive = active
        if active {
            startAmbience()
            startTrainSound()
        } else {
            stopAmbience()
            stopTrainSound()
        }
    }
    
    func setChapter(_ chapter: Chapter) {
        let oldChapter = currentChapter
        currentChapter = chapter
        
        switch chapter {
        case .krotoszyn:
            ambienceTargetVolume = 0.30
            trainTargetVolume    = 0.50
        case .kozmin:
            ambienceTargetVolume = 0.40
            trainTargetVolume    = 0.55
        case .jarocin:
            ambienceTargetVolume = 0.55
            trainTargetVolume    = 0.65
        case .tunnel:
            ambienceTargetVolume = 0.20  // Muffled outside sound
            trainTargetVolume    = 0.80  // Louder inside tunnel — echoing walls
        case .konin:
            ambienceTargetVolume = 0.45  // Let cod-fh play beautifully
            trainTargetVolume    = 0.35
        case .zolkiew:
            ambienceTargetVolume = 0.40
            trainTargetVolume    = 0.20
        }
        
        let wasPeaceful = (oldChapter == .konin || oldChapter == .zolkiew)
        let isPeaceful = (chapter == .konin || chapter == .zolkiew)
        
        if isAmbienceActive {
            if wasPeaceful != isPeaceful {
                // Crossfade ambient sources
                if isPeaceful {
                    fade(player: ambiencePlayer, to: 0.0, duration: 2.0, timer: &ambienceFadeTimer) { [weak self] in
                        self?.ambiencePlayer?.pause()
                    }
                    if peacefulPlayer?.isPlaying == false {
                        peacefulPlayer?.volume = 0.0
                        peacefulPlayer?.play()
                    }
                    fade(player: peacefulPlayer, to: ambienceTargetVolume, duration: 2.0, timer: &peacefulFadeTimer)
                } else {
                    fade(player: peacefulPlayer, to: 0.0, duration: 2.0, timer: &peacefulFadeTimer) { [weak self] in
                        self?.peacefulPlayer?.pause()
                    }
                    if ambiencePlayer?.isPlaying == false {
                        ambiencePlayer?.volume = 0.0
                        ambiencePlayer?.play()
                    }
                    fade(player: ambiencePlayer, to: ambienceTargetVolume, duration: 2.0, timer: &ambienceFadeTimer)
                }
            } else {
                if isPeaceful {
                    if peacefulPlayer?.isPlaying == true {
                        fade(player: peacefulPlayer, to: ambienceTargetVolume, duration: 1.5, timer: &peacefulFadeTimer)
                    }
                } else {
                    if ambiencePlayer?.isPlaying == true {
                        fade(player: ambiencePlayer, to: ambienceTargetVolume, duration: 1.5, timer: &ambienceFadeTimer)
                    }
                }
            }
            
            if trainPlayer?.isPlaying == true {
                fade(player: trainPlayer, to: trainTargetVolume, duration: 1.5, timer: &trainFadeTimer)
            }
        }
    }
    
    // MARK: - Kept as no-ops (other systems call these)
    
    func setSpeedRatio(_ ratio: Float) {}
    func playExplosion() {}
    func setSirenActive(_ active: Bool) {}
    func playCoalShovel() {}
    func playRailSwitch() {}
    func playOverheatDenial() {}
    
    // MARK: - Ambience Playback
    
    private func startAmbience() {
        let isPeaceful = (currentChapter == .konin || currentChapter == .zolkiew)
        if isPeaceful {
            if peacefulPlayer == nil { preparePeacefulPlayer() }
            guard let player = peacefulPlayer else { return }
            if !player.isPlaying {
                player.volume = 0.0
                player.play()
            }
            fade(player: player, to: ambienceTargetVolume, duration: 3.0, timer: &peacefulFadeTimer)
            
            // Ensure wartime player is stopped
            fade(player: ambiencePlayer, to: 0.0, duration: 1.5, timer: &ambienceFadeTimer) { [weak self] in
                self?.ambiencePlayer?.pause()
            }
        } else {
            if ambiencePlayer == nil { prepareAmbiencePlayer() }
            guard let player = ambiencePlayer else { return }
            if !player.isPlaying {
                player.volume = 0.0
                player.play()
            }
            fade(player: player, to: ambienceTargetVolume, duration: 3.0, timer: &ambienceFadeTimer)
            
            // Ensure peaceful player is stopped
            fade(player: peacefulPlayer, to: 0.0, duration: 1.5, timer: &peacefulFadeTimer) { [weak self] in
                self?.peacefulPlayer?.pause()
            }
        }
    }
    
    private func stopAmbience() {
        if let player = ambiencePlayer {
            fade(player: player, to: 0.0, duration: 1.5, timer: &ambienceFadeTimer) {
                player.pause()
            }
        }
        if let player = peacefulPlayer {
            fade(player: player, to: 0.0, duration: 1.5, timer: &peacefulFadeTimer) {
                player.pause()
            }
        }
    }
    
    private func startTrainSound() {
        if trainPlayer == nil { prepareTrainPlayer() }
        guard let player = trainPlayer else { return }
        if !player.isPlaying {
            player.volume = 0.0
            player.play()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self, let player = self.trainPlayer else { return }
            self.fade(player: player, to: self.trainTargetVolume, duration: 3.5, timer: &self.trainFadeTimer)
        }
    }
    
    private func stopTrainSound() {
        guard let player = trainPlayer else { return }
        fade(player: player, to: 0.0, duration: 2.0, timer: &trainFadeTimer) {
            player.pause()
        }
    }
    
    private func fade(
        player: AVAudioPlayer?,
        to target: Float,
        duration: TimeInterval,
        timer: inout Timer?,
        completion: (() -> Void)? = nil
    ) {
        timer?.invalidate()
        guard let player = player else { completion?(); return }
        
        let steps = 40
        let interval = duration / Double(steps)
        let startVolume = player.volume
        let delta = (target - startVolume) / Float(steps)
        var step = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak player] t in
            guard let player = player else { t.invalidate(); return }
            step += 1
            if step >= steps {
                player.volume = target
                t.invalidate()
                completion?()
            } else {
                player.volume = startVolume + delta * Float(step)
            }
        }
    }
}
