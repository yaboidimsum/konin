//
//  AirRaidController.swift
//  Konin
//
//  Created by Dimas Prihady Setyawan.
//

import Foundation
import SpriteKit

final class AirRaidController {
    weak var scene: GameScene?
    
    private class AttackingPlane {
        let node: SKNode
        var bombNode: SKSpriteNode?
        let startDelay: TimeInterval
        let lateralOffset: CGFloat
        var hasDroppedBomb = false
        var hasExploded = false
        
        init(node: SKNode, startDelay: TimeInterval, lateralOffset: CGFloat) {
            self.node = node
            self.startDelay = startDelay
            self.lateralOffset = lateralOffset
        }
    }
    
    private var spawnTimer: TimeInterval = 0.0
    private var activeAttack = false
    private var attackTimer: TimeInterval = 0.0
    private var warningNode: SKLabelNode?
    private var activePlanes: [AttackingPlane] = []
    private let warningDelay: TimeInterval = 18.0
    private var jarocinTimer: TimeInterval = 0.0
    private var hasSpawnedStukaAttack = false
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func cleanUp() {
        warningNode?.removeFromParent()
        warningNode = nil
        for plane in activePlanes {
            plane.node.removeFromParent()
            plane.bombNode?.removeFromParent()
        }
        activePlanes.removeAll()
        SynthAudioEngine.shared.setSirenActive(false)
        activeAttack = false
        jarocinTimer = 0.0
        hasSpawnedStukaAttack = false
    }
    
    func update(deltaTime: TimeInterval, speed: Double, chapter: Chapter) {
        guard let scene = scene else { return }
        
        // 1. Spawning logic
        if chapter == .jarocin {
            if speed > 5.0 && !activeAttack {
                spawnTimer += deltaTime
                if !hasSpawnedStukaAttack {
                    hasSpawnedStukaAttack = true
                    spawnTimer = 0.0
                    startAirRaid()
                } else if spawnTimer >= chapter.airRaidSpawnInterval {
                    spawnTimer = 0.0
                    startAirRaid()
                }
            }
        } else if chapter.airRaidSpawnInterval < 1000.0 && speed > 5.0 && !activeAttack {
            spawnTimer += deltaTime
            if spawnTimer >= chapter.airRaidSpawnInterval {
                spawnTimer = 0.0
                startAirRaid()
            }
        }
        
        // 2. Attack state animation
        if activeAttack {
            attackTimer += deltaTime
            
            // Update each active plane
            for plane in activePlanes {
                let localTimer = (attackTimer - warningDelay) - plane.startDelay
                
                if localTimer < 0.0 {
                    plane.node.isHidden = true
                } else if localTimer < 2.5 {
                    // Swooping down (2.5 seconds duration)
                    let t = localTimer / 2.5
                    let scale = 0.02 + CGFloat(t) * 0.98
                    plane.node.setScale(scale)
                    
                    let startY = scene.horizonY + 150
                    let endY = scene.size.height - 150
                    let y = startY + (endY - startY) * CGFloat(t)
                    
                    plane.node.position = CGPoint(
                        x: scene.size.width / 2 + plane.lateralOffset + scene.trainController.visualOffset * 0.5,
                        y: y
                    )
                    plane.node.isHidden = false
                } else if localTimer < 3.5 {
                    // Flying away, bomb falling down (1.0 second duration)
                    plane.node.setScale(1.2)
                    plane.node.position.y += CGFloat(deltaTime * 300)
                    
                    if !plane.hasDroppedBomb {
                        plane.hasDroppedBomb = true
                        let bomb = SKSpriteNode(color: .black, size: CGSize(width: 16, height: 32))
                        bomb.zPosition = 5.0
                        bomb.position = CGPoint(
                            x: scene.size.width / 2 + plane.lateralOffset + scene.trainController.visualOffset,
                            y: scene.size.height - 120
                        )
                        
                        // Yellow nose for high visibility
                        let nose = SKSpriteNode(color: .yellow, size: CGSize(width: 16, height: 6))
                        nose.position = CGPoint(x: 0, y: -13) // At the bottom nose
                        bomb.addChild(nose)
                        
                        // Dark gray tail fins
                        let fins = SKSpriteNode(color: .darkGray, size: CGSize(width: 24, height: 8))
                        fins.position = CGPoint(x: 0, y: 12) // At the top fin area
                        bomb.addChild(fins)
                        
                        scene.addChild(bomb)
                        plane.bombNode = bomb
                        
                        scene.cameraController.boostRumble(multiplier: 3.5, decaySpeed: 2.0)
                    }
                    
                    let tBomb = (localTimer - 2.5) / 1.0
                    let startY = scene.size.height - 120
                    let endY = scene.horizonY + 40
                    let y = startY + (endY - startY) * CGFloat(tBomb)
                    
                    plane.bombNode?.position = CGPoint(
                        x: scene.size.width / 2 + plane.lateralOffset + scene.trainController.visualOffset,
                        y: y
                    )
                    plane.bombNode?.setScale(0.1 + CGFloat(tBomb) * 1.5)
                } else if !plane.hasExploded {
                    // Impact!
                    plane.hasExploded = true
                    triggerSingleImpact(plane: plane)
                }
            }
            
            // Check if all planes have finished their attacks
            let allFinished = activePlanes.allSatisfy { $0.hasExploded }
            if allFinished {
                // End air raid wave
                warningNode?.removeFromParent()
                warningNode = nil
                SynthAudioEngine.shared.setSirenActive(false)
                activeAttack = false
                activePlanes.removeAll()
            }
        }
    }
    
    private func startAirRaid() {
        guard let scene = scene else { return }
        activeAttack = true
        attackTimer = 0.0
        activePlanes.removeAll()
        
        // 1. Trigger audio siren
        SynthAudioEngine.shared.setSirenActive(true)
        
        // 2. Spawn 2 or 3 planes (always double or triple plane attack!)
        let planeCount = Int.random(in: 2...3)
        
        for i in 0..<planeCount {
            // Stagger each plane by 1.25 seconds to create a wave feel
            let startDelay = Double(i) * 1.25
            
            // Separate them horizontally
            var lateralOffset: CGFloat = 0.0
            if planeCount == 2 {
                lateralOffset = i == 0 ? -120.0 : 120.0
            } else { // 3 planes
                if i == 0 {
                    lateralOffset = -160.0
                } else if i == 1 {
                    lateralOffset = 160.0
                } else {
                    lateralOffset = 0.0
                }
            }
            
            // Create plane node geometry
            let plane = SKNode()
            plane.position = CGPoint(x: scene.size.width / 2 + lateralOffset, y: scene.horizonY + 150)
            plane.zPosition = 5.0
            plane.isHidden = true
            
            // Wing shape
            let wing = SKSpriteNode(color: .gray, size: CGSize(width: 120, height: 16))
            plane.addChild(wing)
            
            // Add Balkenkreuz markings on the left and right wing tips
            for wingSide in [-1.0, 1.0] {
                let markX = wingSide * 40.0
                
                // White backing square
                let backing = SKSpriteNode(color: .white, size: CGSize(width: 14, height: 14))
                backing.position = CGPoint(x: markX, y: 0)
                plane.addChild(backing)
                
                // Black vertical bar
                let vert = SKSpriteNode(color: .black, size: CGSize(width: 4, height: 12))
                vert.position = CGPoint(x: markX, y: 0)
                plane.addChild(vert)
                
                // Black horizontal bar
                let horiz = SKSpriteNode(color: .black, size: CGSize(width: 12, height: 4))
                horiz.position = CGPoint(x: markX, y: 0)
                plane.addChild(horiz)
            }
            
            // Fuselage shape
            let fuselage = SKSpriteNode(color: SKColor(white: 0.2, alpha: 1.0), size: CGSize(width: 20, height: 80))
            plane.addChild(fuselage)
            
            // Tail shape
            let tail = SKSpriteNode(color: .gray, size: CGSize(width: 40, height: 10))
            tail.position = CGPoint(x: 0, y: -30)
            plane.addChild(tail)
            
            scene.addChild(plane)
            
            let attackingPlane = AttackingPlane(node: plane, startDelay: startDelay, lateralOffset: lateralOffset)
            activePlanes.append(attackingPlane)
        }
    }
    
    private func triggerSingleImpact(plane: AttackingPlane) {
        guard let scene = scene else { return }
        
        // Clean up visual elements
        plane.node.removeFromParent()
        plane.bombNode?.removeFromParent()
        
        // Evaluate ducking
        let isDucked = scene.trainController.isDucked
        
        if isDucked {
            // Safe duck! Blast is still extremely close
            scene.cameraController.shake(duration: 0.6, intensity: 12)
            scene.cameraController.boostRumble(multiplier: 3.0, decaySpeed: 2.0)
            SynthAudioEngine.shared.playExplosion()
            scene.triggerFlash(color: SKColor(red: 1.0, green: 0.95, blue: 0.70, alpha: 1.0))
        } else {
            // Direct Hit! Massive damage and violent cabin damage
            scene.cameraController.shake(duration: 1.3, intensity: 35)
            scene.cameraController.boostRumble(multiplier: 8.0, decaySpeed: 3.0)
            GameDirector.shared.updateCoal(-45.0) // high stakes (requires stoking/ducking)
            SynthAudioEngine.shared.playExplosion()
            SynthAudioEngine.shared.playDamage()
            scene.triggerFlash(color: .red) // red flash for critical impact
        }
    }
}
