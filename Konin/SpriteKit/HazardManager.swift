//
//  HazardManager.swift
//  Konin
//

import Foundation
import SpriteKit

final class HazardNode: SKSpriteNode {
    var lane: Int = 0
    var progress: Double = 0.0
    var hasCollided: Bool = false
    var warningFlashed: Bool = false
}

final class HazardManager {
    weak var scene: GameScene?
    
    private var spawnTimer: TimeInterval = 0.0
    private var activeHazards: [HazardNode] = []
    private var spawnCount: Int = 0
    
    // Track last spawned lane to bias toward alternation
    private var lastSpawnedLane: Int = -1
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func cleanUp() {
        for hazard in activeHazards { hazard.removeFromParent() }
        activeHazards.removeAll()
        spawnCount = 0
        lastSpawnedLane = -1
    }
    
    func update(deltaTime: TimeInterval, speed: Double, chapter: Chapter) {
        guard let scene = scene else { return }
        
        // 1. Spawn
        if chapter.obstacleSpawnInterval < 1000.0 && speed > 5.0 {
            spawnTimer += deltaTime
            let escalation = max(0.6, 1.0 - Double(spawnCount) * 0.04)
            let interval   = chapter.obstacleSpawnInterval * escalation
            if spawnTimer >= interval {
                spawnTimer = 0.0
                spawnHazard()
            }
        }
        
        // 2. Update active hazards
        var toRemove: [HazardNode] = []
        
        for hazard in activeHazards {
            let increment = (speed / 35.0) * deltaTime * 0.42
            hazard.progress += increment
            let t = hazard.progress
            
            if t >= 1.0 {
                toRemove.append(hazard)
                hazard.removeFromParent()
                continue
            }
            
            // Pre-warning flash
            if t >= 0.10 && !hazard.warningFlashed {
                hazard.warningFlashed = true
                scene.triggerRailWarningFlash(lane: hazard.lane)
            }
            
            // Perspective position — using unified perspective projection matching rails
            let cx = scene.size.width / 2
            let X_track: CGFloat
            switch hazard.lane {
            case 0: X_track = -160.0
            case 1: X_track = 0.0
            default: X_track = 160.0
            }
            
            let scaleFactor = 0.33333 + (1.0 - 0.33333) * CGFloat(t)
            let visualX = cx + (X_track + scene.trainController.visualOffset) * scaleFactor
            
            let horizonY = scene.horizonY
            let bottomY: CGFloat = 180.0
            let y = horizonY - (horizonY - bottomY) * CGFloat(pow(t, 2.0))
            
            hazard.position = CGPoint(x: visualX, y: y)
            
            let scale = 0.05 + 0.95 * CGFloat(t)
            hazard.setScale(scale)
            hazard.zPosition = 3.0
            
            // Colour pulse gets faster as it approaches
            let pulseSpeed = 8.0 + t * 20.0
            let pulse = sin(Date().timeIntervalSince1970 * pulseSpeed)
            hazard.color = pulse > 0.0 ? .red : SKColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1.0)
            
            // 3. Collision — check logical targetLane for responsiveness when the hazard reaches the train (t >= 0.95)
            if t >= 0.95 && !hazard.hasCollided {
                hazard.hasCollided = true
                if scene.trainController.targetLane == hazard.lane {
                    triggerCollision()
                }
            }
        }
        
        activeHazards.removeAll { toRemove.contains($0) }
    }
    
    private func spawnHazard() {
        guard let scene = scene else { return }
        
        // Pick a lane that isn't the last spawned one (bias = 80%)
        // This ensures the player always has a reachable safe lane
        let lane: Int
        if lastSpawnedLane < 0 {
            lane = Int.random(in: 0...2)
        } else {
            // Build list of lanes excluding last
            var candidates = [0, 1, 2].filter { $0 != lastSpawnedLane }
            if Double.random(in: 0...1) < 0.80 {
                lane = candidates.randomElement() ?? lastSpawnedLane
            } else {
                lane = lastSpawnedLane
            }
        }
        lastSpawnedLane = lane
        spawnCount += 1
        
        let hazardSize = CGSize(width: 90, height: 14)
        let hazard = HazardNode(color: .red, size: hazardSize)
        hazard.lane = lane
        hazard.progress = 0.0
        
        let label = SKLabelNode(text: "⚠  BROKEN RAIL")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 10
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        label.position = .zero
        hazard.addChild(label)
        
        scene.addChild(hazard)
        activeHazards.append(hazard)
    }
    
    private func triggerCollision() {
        guard let scene = scene else { return }
        scene.cameraController.shake(duration: 0.7, intensity: 18)
        GameDirector.shared.updateCoal(-30.0)
        SynthAudioEngine.shared.playExplosion()
        SynthAudioEngine.shared.playDamage()
        scene.triggerFlash(color: SKColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 0.7))
    }
    
}
