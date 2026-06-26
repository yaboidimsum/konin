//
//  SynthAudioEngine.swift
//  Konin
//

import Foundation
import AVFoundation

final class SynthAudioEngine: @unchecked Sendable {
    static let shared = SynthAudioEngine()
    
    // MARK: - Audio Players
    private var ambiencePlayer: AVAudioPlayer?     // ww2-ambience.mp3 (wartime)
    private var peacefulPlayer: AVAudioPlayer?      // cod-fh.mp3 (peaceful chapters)
    private var level3Player: AVAudioPlayer?        // level-3.mp3 (Chapter 3)
    private var trainPlayer: AVAudioPlayer?         // train-sound-effect.mp3
    private var stukaPlayer: AVAudioPlayer?         // stuka.mp3
    private var damagePlayer: AVAudioPlayer?        // damage.mp3
    private var explosion1Player: AVAudioPlayer?    // dragon-studio-loud-explosion-425457.mp3
    private var explosion2Player: AVAudioPlayer?    // universfield-epic-cinematic-explosion-454857.mp3
    private var honkPlayer: AVAudioPlayer?          // Horn.mp3
    private var menuPlayer: AVAudioPlayer?          // Medal of Honor Allied Assault theme (menu background music)
    private var krotoszynPlayer: AVAudioPlayer?     // Medal of Honor Allied Assault Lighting (Chapter 1 gameplay)
    private var introJohnPlayer: AVAudioPlayer?     // Introduction-john.mp3 (intro screen background music)
    private var introSection1Player: AVAudioPlayer? // introduction/section-1.mp3 (voiceover section 1)
    private var introSection2Player: AVAudioPlayer? // introduction/section-2.mp3 (voiceover section 2)
    
    // MARK: - State
    private var isAmbienceActive: Bool = false
    private var isRunning = false
    private var currentChapter: Chapter = .krotoszyn
    
    // Target volumes per chapter
    private var ambienceTargetVolume: Float = 0.35
    private var trainTargetVolume: Float = 0.55
    
    // MARK: - Fade State (timer driven)
    private struct FadeState {
        var isActive = false
        var startVolume: Float = 0.0
        var targetVolume: Float = 0.0
        var elapsed: TimeInterval = 0.0
        var duration: TimeInterval = 1.0
        var completion: (() -> Void)?
    }
    
    private var ambienceFade = FadeState()
    private var peacefulFade = FadeState()
    private var level3Fade = FadeState()
    private var trainFade = FadeState()
    private var stukaFade = FadeState()
    private var introJohnFade = FadeState()
    private var menuFade = FadeState()
    private var krotoszynFade = FadeState()
    
    // Timer for fades (macOS and iOS compatible)
    private var fadeTimer: Timer?
    private var lastFadeTime: TimeInterval = 0.0
    
    private init() {
        if Thread.isMainThread {
            self.setup()
        } else {
            DispatchQueue.main.sync {
                self.setup()
            }
        }
    }
    
    private func setup() {
        configureAudioSession()
        loadPlayer(resource: "ww2-ambience", store: &ambiencePlayer, initialVolume: 0.0)
        loadPlayer(resource: "train-sound-effect", store: &trainPlayer, initialVolume: 0.0)
        loadPlayer(resource: "cod-fh", store: &peacefulPlayer, initialVolume: 0.0)
        loadPlayer(resource: "level-3", store: &level3Player, initialVolume: 0.0)
        loadPlayer(resource: "stuka", store: &stukaPlayer, initialVolume: 0.0)
        loadPlayer(resource: "damage", store: &damagePlayer, initialVolume: 0.0)
        loadPlayer(resource: "dragon-studio-loud-explosion-425457", store: &explosion1Player, initialVolume: 0.0)
        loadPlayer(resource: "universfield-epic-cinematic-explosion-454857", store: &explosion2Player, initialVolume: 0.0)
        loadPlayer(resource: "Horn", store: &honkPlayer, initialVolume: 0.0)
        loadPlayer(resource: "YTMP3GG_YouTube_01-Medal-of-Honor-Allied-Assault-Main-Ti_Media_-kWeJ9ywQJM_006_128k", store: &menuPlayer, initialVolume: 0.0)
        loadPlayer(resource: "YTMP3GG_YouTube_05-Medal-of-Honor-Allied-Assault-Lightin_Media_G0t4Y-cdDNE_005_128k", store: &krotoszynPlayer, initialVolume: 0.0)
        loadPlayer(resource: "Introduction-john", store: &introJohnPlayer, initialVolume: 0.0)
        loadIntroSectionPlayer(resource: "section-1", store: &introSection1Player)
        loadIntroSectionPlayer(resource: "section-2", store: &introSection2Player)
    }
    
    // MARK: - Audio Session Configuration
    
    private func configureAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            print("[Audio] iOS Audio Session configured successfully")
        } catch {
            print("[Audio] Failed to configure iOS audio session: \(error)")
        }
        #endif
    }
    
    // MARK: - Player Loading
    
    private func loadPlayer(resource: String, store: inout AVAudioPlayer?, initialVolume: Float) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3") else {
            print("[Audio] \(resource).mp3 not found in bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = initialVolume
            player.prepareToPlay()
            store = player
            print("[Audio] Loaded \(resource).mp3 successfully")
        } catch {
            print("[Audio] Failed to load \(resource).mp3: \(error)")
        }
    }
    
    // MARK: - Public API
    
    func start() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard !self.isRunning else { return }
            self.isRunning = true
            self.startFadeLoop()
        }
    }
    
    func stop() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isRunning = false
            self.stopFadeLoop()
            
            self.ambienceFade.isActive = false
            self.peacefulFade.isActive = false
            self.level3Fade.isActive = false
            self.trainFade.isActive = false
            self.stukaFade.isActive = false
            self.introJohnFade.isActive = false
            self.menuFade.isActive = false
            self.krotoszynFade.isActive = false
            
            self.ambiencePlayer?.stop()
            self.ambiencePlayer?.volume = 0.0
            self.peacefulPlayer?.stop()
            self.peacefulPlayer?.volume = 0.0
            self.level3Player?.stop()
            self.level3Player?.volume = 0.0
            self.trainPlayer?.stop()
            self.trainPlayer?.volume = 0.0
            self.stukaPlayer?.stop()
            self.stukaPlayer?.volume = 0.0
            self.damagePlayer?.stop()
            self.damagePlayer?.volume = 0.0
            self.explosion1Player?.stop()
            self.explosion1Player?.volume = 0.0
            self.explosion2Player?.stop()
            self.explosion2Player?.volume = 0.0
            self.honkPlayer?.stop()
            self.honkPlayer?.volume = 0.0
            self.introJohnPlayer?.stop()
            self.introJohnPlayer?.volume = 0.0
            self.menuPlayer?.stop()
            self.menuPlayer?.volume = 0.0
            self.krotoszynPlayer?.stop()
            self.krotoszynPlayer?.volume = 0.0
            self.introSection1Player?.stop()
            self.introSection1Player?.volume = 0.0
            self.introSection2Player?.stop()
            self.introSection2Player?.volume = 0.0
        }
    }
    
    func setAmbienceActive(_ active: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isAmbienceActive = active
            if active {
                self.startAmbience()
                self.startTrainSound()
            } else {
                self.stopAmbience()
                self.stopTrainSound()
            }
        }
    }
    
    func setAmbienceOnlyActive(_ active: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isAmbienceActive = active
            if active {
                self.startAmbience()
            } else {
                self.stopAmbience()
            }
        }
    }
    
    func startIntroJohn() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.ensurePlaying(self.introJohnPlayer)
            self.fadeIn(player: self.introJohnPlayer, fade: &self.introJohnFade, to: 0.22, duration: 2.5)
        }
    }
    
    func stopIntroJohn(duration: TimeInterval = 2.0) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let player = self.introJohnPlayer else { return }
            self.fadeOut(player: player, fade: &self.introJohnFade, duration: duration) {
                player.pause()
            }
        }
    }
    
    func startMenuMusic() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.ensurePlaying(self.menuPlayer)
            self.fadeIn(player: self.menuPlayer, fade: &self.menuFade, to: 0.28, duration: 2.0)
        }
    }
    
    func stopMenuMusic(duration: TimeInterval = 1.5) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let player = self.menuPlayer else { return }
            self.fadeOut(player: player, fade: &self.menuFade, duration: duration) {
                player.pause()
            }
        }
    }
    
    func playIntroSection1() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.introSection2Player?.stop()
            if let p = self.introSection1Player {
                p.currentTime = 0
                p.volume = 1.0
                p.play()
            }
        }
    }
    
    func playIntroSection2() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.introSection1Player?.stop()
            if let p = self.introSection2Player {
                p.currentTime = 0
                p.volume = 1.0
                p.play()
            }
        }
    }
    
    func stopIntroSections() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.introSection1Player?.stop()
            self.introSection2Player?.stop()
        }
    }
    
    func setChapter(_ chapter: Chapter) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let oldChapter = self.currentChapter
            self.currentChapter = chapter
            
            if chapter == .jarocin {
                self.level3Player?.currentTime = 0.0
            }
            if chapter == .krotoszyn {
                self.krotoszynPlayer?.currentTime = 0.0
            }
            
            switch chapter {
            case .krotoszyn:
                self.ambienceTargetVolume = 0.30
                self.trainTargetVolume    = 0.50
            case .kozmin:
                self.ambienceTargetVolume = 0.40
                self.trainTargetVolume    = 0.55
            case .jarocin:
                self.ambienceTargetVolume = 0.55
                self.trainTargetVolume    = 0.65
            case .tunnel:
                self.ambienceTargetVolume = 0.20
                self.trainTargetVolume    = 0.80
            case .konin:
                self.ambienceTargetVolume = 0.45
                self.trainTargetVolume    = 0.35
            case .zolkiew:
                self.ambienceTargetVolume = 0.40
                self.trainTargetVolume    = 0.20
            case .prolog:
                self.ambienceTargetVolume = 0.30
                self.trainTargetVolume    = 0.50
            }
            
            let wasJarocin = (oldChapter == .jarocin)
            let isJarocin = (chapter == .jarocin)
            let wasKrotoszyn = (oldChapter == .krotoszyn)
            let isKrotoszyn = (chapter == .krotoszyn)
            let wasPeaceful = Self.isPeacefulChapter(oldChapter)
            let isPeaceful = Self.isPeacefulChapter(chapter)
            
            guard self.isAmbienceActive else { return }
            
            if isJarocin {
                // Fade in level-3
                self.ensurePlaying(self.level3Player)
                self.fadeIn(player: self.level3Player, fade: &self.level3Fade, to: self.ambienceTargetVolume, duration: 2.5)
                
                // Fade out others
                self.fadeOut(player: self.ambiencePlayer, fade: &self.ambienceFade, duration: 2.5) { [weak self] in
                    self?.ambiencePlayer?.pause()
                }
                self.fadeOut(player: self.peacefulPlayer, fade: &self.peacefulFade, duration: 2.5) { [weak self] in
                    self?.peacefulPlayer?.pause()
                }
                self.fadeOut(player: self.menuPlayer, fade: &self.menuFade, duration: 2.5) { [weak self] in
                    self?.menuPlayer?.pause()
                }
                self.fadeOut(player: self.krotoszynPlayer, fade: &self.krotoszynFade, duration: 2.5) { [weak self] in
                    self?.krotoszynPlayer?.pause()
                }
            } else if isKrotoszyn {
                // Fade in krotoszynPlayer (Medal of Honor Lighting)
                self.ensurePlaying(self.krotoszynPlayer)
                self.fadeIn(player: self.krotoszynPlayer, fade: &self.krotoszynFade, to: self.ambienceTargetVolume, duration: 2.5)
                
                // Fade out others
                self.fadeOut(player: self.ambiencePlayer, fade: &self.ambienceFade, duration: 2.5) { [weak self] in
                    self?.ambiencePlayer?.pause()
                }
                self.fadeOut(player: self.peacefulPlayer, fade: &self.peacefulFade, duration: 2.5) { [weak self] in
                    self?.peacefulPlayer?.pause()
                }
                self.fadeOut(player: self.level3Player, fade: &self.level3Fade, duration: 2.5) { [weak self] in
                    self?.level3Player?.pause()
                }
                self.fadeOut(player: self.menuPlayer, fade: &self.menuFade, duration: 2.5) { [weak self] in
                    self?.menuPlayer?.pause()
                }
            } else if isPeaceful {
                // Fade in peaceful
                self.ensurePlaying(self.peacefulPlayer)
                self.fadeIn(player: self.peacefulPlayer, fade: &self.peacefulFade, to: self.ambienceTargetVolume, duration: 2.5)
                
                // Fade out others
                self.fadeOut(player: self.ambiencePlayer, fade: &self.ambienceFade, duration: 2.5) { [weak self] in
                    self?.ambiencePlayer?.pause()
                }
                self.fadeOut(player: self.level3Player, fade: &self.level3Fade, duration: 2.5) { [weak self] in
                    self?.level3Player?.pause()
                }
                self.fadeOut(player: self.menuPlayer, fade: &self.menuFade, duration: 2.5) { [weak self] in
                    self?.menuPlayer?.pause()
                }
                self.fadeOut(player: self.krotoszynPlayer, fade: &self.krotoszynFade, duration: 2.5) { [weak self] in
                    self?.krotoszynPlayer?.pause()
                }
            } else {
                // Fade in wartime ambience
                self.ensurePlaying(self.ambiencePlayer)
                self.fadeIn(player: self.ambiencePlayer, fade: &self.ambienceFade, to: self.ambienceTargetVolume, duration: 2.5)
                
                // Fade out others
                self.fadeOut(player: self.peacefulPlayer, fade: &self.peacefulFade, duration: 2.5) { [weak self] in
                    self?.peacefulPlayer?.pause()
                }
                self.fadeOut(player: self.level3Player, fade: &self.level3Fade, duration: 2.5) { [weak self] in
                    self?.level3Player?.pause()
                }
                self.fadeOut(player: self.menuPlayer, fade: &self.menuFade, duration: 2.5) { [weak self] in
                    self?.menuPlayer?.pause()
                }
                self.fadeOut(player: self.krotoszynPlayer, fade: &self.krotoszynFade, duration: 2.5) { [weak self] in
                    self?.krotoszynPlayer?.pause()
                }
            }
            
            self.fadeIn(player: self.trainPlayer, fade: &self.trainFade, to: self.trainTargetVolume, duration: 1.5)
        }
    }
    
    // MARK: - No-ops (called by other systems)
    
    func setSpeedRatio(_ ratio: Float) {}
    
    func playExplosion() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let useFirst = Bool.random()
            let player = useFirst ? self.explosion1Player : self.explosion2Player
            
            guard let p = player else { return }
            p.currentTime = 0
            p.numberOfLoops = 0
            p.volume = 1.0
            let ok = p.play()
            if !ok {
                print("[Audio] explosion.play() returned false")
            }
        }
    }
    
    func playHonk() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let player = self.honkPlayer else { return }
            player.currentTime = 0
            player.numberOfLoops = 0
            player.volume = 1.0
            let ok = player.play()
            if !ok {
                print("[Audio] honk.play() returned false")
            }
        }
    }
    
    func setSirenActive(_ active: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let player = self.stukaPlayer else { return }
            if active {
                self.stukaFade.isActive = false
                player.volume = 0.9
                player.currentTime = 0
                player.numberOfLoops = 0
                let ok = player.play()
                if !ok {
                    print("[Audio] stuka.play() returned false")
                }
            } else {
                self.fadeOut(player: player, fade: &self.stukaFade, duration: 0.8) {
                    player.pause()
                }
            }
        }
    }
    
    func playCoalShovel() {}
    func playRailSwitch() {}
    func playOverheatDenial() {}
    
    func playDamage() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let player = self.damagePlayer else { return }
            player.currentTime = 0
            player.numberOfLoops = 0
            player.volume = 1.0
            let ok = player.play()
            if !ok {
                print("[Audio] damage.play() returned false")
            }
        }
    }
    
    func getLevel3PlayTime() -> TimeInterval {
        return level3Player?.currentTime ?? 0.0
    }
    
    // MARK: - Private Playback
    
    private static func isPeacefulChapter(_ chapter: Chapter) -> Bool {
        chapter == .konin || chapter == .zolkiew
    }
    
    private func ensurePlaying(_ player: AVAudioPlayer?) {
        guard let player = player, !player.isPlaying else { return }
        player.volume = 0.0
        let ok = player.play()
        if !ok {
            print("[Audio] player.play() returned false for \(player.url?.lastPathComponent ?? "unknown")")
        }
    }
    
    private func startAmbience() {
        if currentChapter == .jarocin {
            ensurePlaying(level3Player)
            fadeIn(player: level3Player, fade: &level3Fade, to: ambienceTargetVolume, duration: 3.0)
            fadeOut(player: ambiencePlayer, fade: &ambienceFade, duration: 1.5) { [weak self] in
                self?.ambiencePlayer?.pause()
            }
            fadeOut(player: peacefulPlayer, fade: &peacefulFade, duration: 1.5) { [weak self] in
                self?.peacefulPlayer?.pause()
            }
            fadeOut(player: menuPlayer, fade: &menuFade, duration: 1.5) { [weak self] in
                self?.menuPlayer?.pause()
            }
        } else if currentChapter == .krotoszyn {
            ensurePlaying(krotoszynPlayer)
            fadeIn(player: krotoszynPlayer, fade: &krotoszynFade, to: ambienceTargetVolume, duration: 3.0)
            fadeOut(player: ambiencePlayer, fade: &ambienceFade, duration: 1.5) { [weak self] in
                self?.ambiencePlayer?.pause()
            }
            fadeOut(player: peacefulPlayer, fade: &peacefulFade, duration: 1.5) { [weak self] in
                self?.peacefulPlayer?.pause()
            }
            fadeOut(player: level3Player, fade: &level3Fade, duration: 1.5) { [weak self] in
                self?.level3Player?.pause()
            }
            fadeOut(player: menuPlayer, fade: &menuFade, duration: 1.5) { [weak self] in
                self?.menuPlayer?.pause()
            }
        } else if Self.isPeacefulChapter(currentChapter) {
            ensurePlaying(peacefulPlayer)
            fadeIn(player: peacefulPlayer, fade: &peacefulFade, to: ambienceTargetVolume, duration: 3.0)
            fadeOut(player: ambiencePlayer, fade: &ambienceFade, duration: 1.5) { [weak self] in
                self?.ambiencePlayer?.pause()
            }
            fadeOut(player: level3Player, fade: &level3Fade, duration: 1.5) { [weak self] in
                self?.level3Player?.pause()
            }
            fadeOut(player: menuPlayer, fade: &menuFade, duration: 1.5) { [weak self] in
                self?.menuPlayer?.pause()
            }
            fadeOut(player: krotoszynPlayer, fade: &krotoszynFade, duration: 1.5) { [weak self] in
                self?.krotoszynPlayer?.pause()
            }
        } else {
            ensurePlaying(ambiencePlayer)
            fadeIn(player: ambiencePlayer, fade: &ambienceFade, to: ambienceTargetVolume, duration: 3.0)
            fadeOut(player: peacefulPlayer, fade: &peacefulFade, duration: 1.5) { [weak self] in
                self?.peacefulPlayer?.pause()
            }
            fadeOut(player: level3Player, fade: &level3Fade, duration: 1.5) { [weak self] in
                self?.level3Player?.pause()
            }
            fadeOut(player: menuPlayer, fade: &menuFade, duration: 1.5) { [weak self] in
                self?.menuPlayer?.pause()
            }
            fadeOut(player: krotoszynPlayer, fade: &krotoszynFade, duration: 1.5) { [weak self] in
                self?.krotoszynPlayer?.pause()
            }
        }
    }
    
    private func stopAmbience() {
        fadeOut(player: ambiencePlayer, fade: &ambienceFade, duration: 1.5) { [weak self] in
            self?.ambiencePlayer?.pause()
        }
        fadeOut(player: peacefulPlayer, fade: &peacefulFade, duration: 1.5) { [weak self] in
            self?.peacefulPlayer?.pause()
        }
        fadeOut(player: level3Player, fade: &level3Fade, duration: 1.5) { [weak self] in
            self?.level3Player?.pause()
        }
        fadeOut(player: menuPlayer, fade: &menuFade, duration: 1.5) { [weak self] in
            self?.menuPlayer?.pause()
        }
        fadeOut(player: krotoszynPlayer, fade: &krotoszynFade, duration: 1.5) { [weak self] in
            self?.krotoszynPlayer?.pause()
        }
    }
    
    private func startTrainSound() {
        ensurePlaying(trainPlayer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            self.fadeIn(player: self.trainPlayer, fade: &self.trainFade, to: self.trainTargetVolume, duration: 3.5)
        }
    }
    
    private func stopTrainSound() {
        fadeOut(player: trainPlayer, fade: &trainFade, duration: 2.0) { [weak self] in
            self?.trainPlayer?.pause()
        }
    }
    
    // MARK: - Fade Engine (Timer based)
    
    private func startFadeLoop() {
        guard fadeTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(fadeStep), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        fadeTimer = timer
        lastFadeTime = CACurrentMediaTime()
    }
    
    private func stopFadeLoop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
    }
    
    @objc private func fadeStep() {
        let now = CACurrentMediaTime()
        let dt = now - lastFadeTime
        lastFadeTime = now
        
        processFade(player: ambiencePlayer, fade: &ambienceFade, dt: dt)
        processFade(player: peacefulPlayer, fade: &peacefulFade, dt: dt)
        processFade(player: level3Player, fade: &level3Fade, dt: dt)
        processFade(player: trainPlayer, fade: &trainFade, dt: dt)
        processFade(player: stukaPlayer, fade: &stukaFade, dt: dt)
        processFade(player: introJohnPlayer, fade: &introJohnFade, dt: dt)
        processFade(player: menuPlayer, fade: &menuFade, dt: dt)
        processFade(player: krotoszynPlayer, fade: &krotoszynFade, dt: dt)
    }
    
    private func processFade(player: AVAudioPlayer?, fade: inout FadeState, dt: TimeInterval) {
        guard fade.isActive, let player = player else { return }
        
        fade.elapsed += dt
        let t = min(Float(fade.elapsed / fade.duration), 1.0)
        
        let smoothT = t * t * (3.0 - 2.0 * t)
        player.volume = fade.startVolume + (fade.targetVolume - fade.startVolume) * smoothT
        
        if t >= 1.0 {
            player.volume = fade.targetVolume
            fade.isActive = false
            fade.completion?()
            fade.completion = nil
        }
    }
    
    private func fadeIn(player: AVAudioPlayer?, fade: inout FadeState, to target: Float, duration: TimeInterval) {
        guard let player = player else { return }
        fade.isActive = true
        fade.startVolume = player.volume
        fade.targetVolume = target
        fade.elapsed = 0.0
        fade.duration = duration
        fade.completion = nil
    }
    
    private func fadeOut(player: AVAudioPlayer?, fade: inout FadeState, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let player = player else { completion?(); return }
        fade.isActive = true
        fade.startVolume = player.volume
        fade.targetVolume = 0.0
        fade.elapsed = 0.0
        fade.duration = duration
        fade.completion = completion
    }
    
    private func loadIntroSectionPlayer(resource: String, store: inout AVAudioPlayer?) {
        guard let url = findAudioURL(forResource: resource, withExtension: "mp3") else {
            print("[Audio] \(resource).mp3 not found in bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = 1.0
            player.prepareToPlay()
            store = player
            print("[Audio] Loaded \(resource).mp3 successfully")
        } catch {
            print("[Audio] Failed to load \(resource).mp3: \(error)")
        }
    }
    
    private func findAudioURL(forResource name: String, withExtension ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "introduction") {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Audio/introduction") {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Konin/Audio/introduction") {
            return url
        }
        return nil
    }
}
