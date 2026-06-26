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
    var variant: Int = 0
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
            
            // Keep the light color at the mine red (pulsing red/dark red)
            let pulseColor = pulse > 0.0 ? SKColor.red : SKColor(red: 0.2, green: 0.0, blue: 0.0, alpha: 1.0)
            
            if let light = hazard.childNode(withName: "indicator_light") as? SKSpriteNode {
                light.color = pulseColor
            }
            
            // 3. Collision — check logical targetLane for responsiveness when the hazard reaches the train (t >= 0.95)
            if t >= 0.95 && !hazard.hasCollided {
                hazard.hasCollided = true
                if scene.trainController.targetLane == hazard.lane {
                    triggerCollision(for: hazard)
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
        
        let hazard = HazardNode(color: .clear, size: CGSize(width: 60, height: 60))
        hazard.lane = lane
        hazard.progress = 0.0
        
        let variant = Int.random(in: 0...3)
        hazard.variant = variant
        
        switch variant {
        case 0:
            // --- VARIANT 0: German S2-Schrapnellmine (Canister style) ---
            // 1. Dirt/gravel mound at the base (semi-buried look)
            let dirtMound = SKSpriteNode(color: SKColor(red: 0.23, green: 0.19, blue: 0.15, alpha: 1.0), size: CGSize(width: 44, height: 12))
            dirtMound.position = CGPoint(x: 0, y: -16)
            dirtMound.zPosition = 0.1
            hazard.addChild(dirtMound)
            
            // 2. Main cylindrical body of the S2-mine
            let mineBody = SKSpriteNode(color: SKColor(red: 0.24, green: 0.29, blue: 0.21, alpha: 1.0), size: CGSize(width: 28, height: 20))
            mineBody.position = CGPoint(x: 0, y: -6)
            mineBody.zPosition = 0.2
            
            // Give it a dark metal border
            let border = SKSpriteNode(color: SKColor(red: 0.12, green: 0.15, blue: 0.10, alpha: 1.0), size: CGSize(width: 30, height: 22))
            border.position = .zero
            border.zPosition = -0.05
            mineBody.addChild(border)
            hazard.addChild(mineBody)
            
            // 3. Fuse cap
            let fuseCap = SKSpriteNode(color: SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0), size: CGSize(width: 6, height: 5))
            fuseCap.position = CGPoint(x: 0, y: 6)
            fuseCap.zPosition = 0.3
            hazard.addChild(fuseCap)
            
            // 4. Three igniter prongs (bouncing S-mine signature look)
            let prongAngles: [CGFloat] = [-0.3, 0.0, 0.3]
            for angle in prongAngles {
                let prong = SKSpriteNode(color: SKColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0), size: CGSize(width: 1.5, height: 8))
                prong.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                prong.position = CGPoint(x: 0, y: 8)
                prong.zRotation = angle
                prong.zPosition = 0.2
                hazard.addChild(prong)
            }
            
            // 5. Pulsing red indicator light
            let glowNode = SKSpriteNode(color: .red, size: CGSize(width: 6, height: 6))
            glowNode.name = "indicator_light"
            glowNode.position = CGPoint(x: 0, y: -6)
            glowNode.zPosition = 0.4
            hazard.addChild(glowNode)
            
        case 1:
            // --- VARIANT 1: German Tellermine 43 (Disc style) ---
            // 1. Dirt/gravel mound at the base
            let dirtMound = SKSpriteNode(color: SKColor(red: 0.23, green: 0.19, blue: 0.15, alpha: 1.0), size: CGSize(width: 52, height: 10))
            dirtMound.position = CGPoint(x: 0, y: -16)
            dirtMound.zPosition = 0.1
            hazard.addChild(dirtMound)
            
            // 2. Wide flat body
            let mineBody = SKSpriteNode(color: SKColor(red: 0.35, green: 0.38, blue: 0.41, alpha: 1.0), size: CGSize(width: 38, height: 12))
            mineBody.position = CGPoint(x: 0, y: -10)
            mineBody.zPosition = 0.2
            
            // Give it a dark metal border
            let border = SKSpriteNode(color: SKColor(red: 0.13, green: 0.15, blue: 0.16, alpha: 1.0), size: CGSize(width: 40, height: 14))
            border.position = .zero
            border.zPosition = -0.05
            mineBody.addChild(border)
            hazard.addChild(mineBody)
            
            // 3. Central pressure plate
            let plate = SKSpriteNode(color: SKColor(red: 0.55, green: 0.58, blue: 0.60, alpha: 1.0), size: CGSize(width: 16, height: 6))
            plate.position = CGPoint(x: 0, y: -7)
            plate.zPosition = 0.3
            hazard.addChild(plate)
            
            // 4. Side carry handle loop
            let handle = SKSpriteNode(color: SKColor(red: 0.30, green: 0.32, blue: 0.35, alpha: 1.0), size: CGSize(width: 6, height: 4))
            handle.position = CGPoint(x: -21, y: -10)
            handle.zPosition = 0.15
            hazard.addChild(handle)
            
            // 5. Pulsing indicator light (Red)
            let glowNode = SKSpriteNode(color: .red, size: CGSize(width: 5, height: 5))
            glowNode.name = "indicator_light"
            glowNode.position = CGPoint(x: 0, y: -7)
            glowNode.zPosition = 0.4
            hazard.addChild(glowNode)
            
        case 2:
            // --- VARIANT 2: German Stockmine 43 (Stake/Concrete style) ---
            // 1. Wooden stake driven into ground
            let stake = SKSpriteNode(color: SKColor(red: 0.36, green: 0.25, blue: 0.20, alpha: 1.0), size: CGSize(width: 4, height: 24))
            stake.position = CGPoint(x: 0, y: -14)
            stake.zPosition = 0.15
            hazard.addChild(stake)
            
            // 2. Concrete cylindrical body
            let mineBody = SKSpriteNode(color: SKColor(red: 0.50, green: 0.55, blue: 0.55, alpha: 1.0), size: CGSize(width: 16, height: 20))
            mineBody.position = CGPoint(x: 0, y: 4)
            mineBody.zPosition = 0.2
            
            // Dark border
            let border = SKSpriteNode(color: SKColor(red: 0.25, green: 0.27, blue: 0.27, alpha: 1.0), size: CGSize(width: 18, height: 22))
            border.position = .zero
            border.zPosition = -0.05
            mineBody.addChild(border)
            hazard.addChild(mineBody)
            
            // 3. Top fuse wire loop
            let wireLoop = SKSpriteNode(color: SKColor(red: 0.74, green: 0.76, blue: 0.78, alpha: 1.0), size: CGSize(width: 6, height: 4))
            wireLoop.position = CGPoint(x: 0, y: 16)
            wireLoop.zPosition = 0.3
            hazard.addChild(wireLoop)
            
            // 4. Pulsing indicator light (Red)
            let glowNode = SKSpriteNode(color: .red, size: CGSize(width: 5, height: 5))
            glowNode.name = "indicator_light"
            glowNode.position = CGPoint(x: 0, y: 4)
            glowNode.zPosition = 0.4
            hazard.addChild(glowNode)
            
        default:
            // --- VARIANT 3: Snapped/Broken Rail ---
            // 1. Broken wooden sleeper
            let brokenSleeper = SKSpriteNode(color: SKColor(red: 0.36, green: 0.25, blue: 0.20, alpha: 1.0), size: CGSize(width: 48, height: 10))
            brokenSleeper.position = CGPoint(x: 0, y: -12)
            brokenSleeper.zPosition = 0.1
            brokenSleeper.zRotation = 0.15
            hazard.addChild(brokenSleeper)
            
            // 2. Snapped rail left (vertical grey block, tilted)
            let leftRail = SKSpriteNode(color: SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), size: CGSize(width: 6, height: 16))
            leftRail.position = CGPoint(x: -16, y: -4)
            leftRail.zPosition = 0.2
            leftRail.zRotation = -0.4
            hazard.addChild(leftRail)
            
            // 3. Snapped rail right
            let rightRail = SKSpriteNode(color: SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), size: CGSize(width: 6, height: 18))
            rightRail.position = CGPoint(x: 16, y: -2)
            rightRail.zPosition = 0.2
            rightRail.zRotation = 0.35
            hazard.addChild(rightRail)
            
            // 4. Red Warning Lantern/Flag on a small stake
            let stake = SKSpriteNode(color: SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0), size: CGSize(width: 3, height: 26))
            stake.position = CGPoint(x: -6, y: 0)
            stake.zPosition = 0.15
            stake.zRotation = -0.1
            hazard.addChild(stake)
            
            let lantern = SKSpriteNode(color: SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0), size: CGSize(width: 8, height: 10))
            lantern.position = CGPoint(x: -6, y: 13)
            lantern.zPosition = 0.3
            hazard.addChild(lantern)
            
            // 5. Pulsing red indicator light on the lantern
            let glowNode = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 4))
            glowNode.name = "indicator_light"
            glowNode.position = CGPoint(x: -6, y: 13)
            glowNode.zPosition = 0.4
            hazard.addChild(glowNode)
        }
        
        scene.addChild(hazard)
        activeHazards.append(hazard)
    }
    
    private func triggerCollision(for hazard: HazardNode) {
        guard let scene = scene else { return }
        
        let damage: Double
        let shakeIntensity: CGFloat
        switch hazard.variant {
        case 1: // Tellermine (Big)
            damage = -45.0
            shakeIntensity = 24.0
        case 0: // S2-mine (Medium)
            damage = -30.0
            shakeIntensity = 18.0
        case 3: // Broken rail (Severe)
            damage = -35.0
            shakeIntensity = 20.0
        default: // Stockmine (Small)
            damage = -15.0
            shakeIntensity = 12.0
        }
        
        scene.cameraController.shake(duration: 0.7, intensity: shakeIntensity)
        GameDirector.shared.updateCoal(damage)
        SynthAudioEngine.shared.playExplosion()
        SynthAudioEngine.shared.playDamage()
        scene.triggerFlash(color: SKColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 0.7))
    }
    
}
