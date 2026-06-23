//
//  CoalSystem.swift
//  Konin
//

import Foundation
import SpriteKit

final class CoalSystem {
    weak var scene: GameScene?
    
    // Cooldown between stokes (prevents button mashing exploit)
    private let stokeCooldown: TimeInterval = 0.55
    private var lastStokeTime: TimeInterval = 0.0
    
    // Overheat: after 4 rapid stokes, furnace needs a pause
    private var stokeStreak: Int = 0
    private let maxStokeStreak: Int = 4
    private var overheatTimer: TimeInterval = 0.0
    private let overheatDuration: TimeInterval = 3.5
    var isOverheated: Bool = false
    
    // Critical low coal warning pulse
    private var warningPulseTimer: TimeInterval = 0.0
    private let warningPulseInterval: TimeInterval = 1.2
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func update(deltaTime: TimeInterval, chapter: Chapter) {
        // Decrease coal over time
        let decay = chapter.coalDecayRate * deltaTime
        GameDirector.shared.updateCoal(-decay)
        
        // Overheat cooldown
        if isOverheated {
            overheatTimer -= deltaTime
            if overheatTimer <= 0 {
                isOverheated = false
                stokeStreak = 0
                // Signal the furnace is ready again
                scene?.triggerFurnaceCooled()
            }
        }
        
        // Critical coal warning (below 25%)
        let coal = GameDirector.shared.coalPercentage
        if coal > 0 && coal < 25.0 {
            warningPulseTimer += deltaTime
            if warningPulseTimer >= warningPulseInterval {
                warningPulseTimer = 0
                scene?.triggerLowCoalWarning()
            }
        } else {
            warningPulseTimer = 0
        }
    }
    
    func stokeCoal() {
        guard !isOverheated else {
            // Audible denial clank
            SynthAudioEngine.shared.playOverheatDenial()
            return
        }
        
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastStokeTime >= stokeCooldown else { return }
        lastStokeTime = currentTime
        
        // Each stoke adds progressively less coal when streak is high
        let streakMultiplier = max(0.5, 1.0 - Double(stokeStreak) * 0.12)
        let gain = 18.0 * streakMultiplier
        GameDirector.shared.updateCoal(gain)
        
        // Synthesize audio
        SynthAudioEngine.shared.playCoalShovel()
        
        // Visual flash in furnace
        scene?.triggerFurnaceFlash()
        
        // Increment streak
        stokeStreak += 1
        if stokeStreak >= maxStokeStreak {
            isOverheated = true
            overheatTimer = overheatDuration
            stokeStreak = 0
            scene?.triggerFurnaceOverheat()
        }
    }
}
