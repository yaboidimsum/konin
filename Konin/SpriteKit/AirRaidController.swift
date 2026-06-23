//
//  AirRaidController.swift
//  Konin
//

import Foundation
import SpriteKit

final class AirRaidController {
    weak var scene: GameScene?
    
    private var spawnTimer: TimeInterval = 0.0
    private var activeAttack = false
    private var attackProgress: Double = 0.0
    private var warningNode: SKLabelNode?
    private var planeNode: SKNode?
    private var bombNode: SKSpriteNode?
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func cleanUp() {
        warningNode?.removeFromParent()
        planeNode?.removeFromParent()
        bombNode?.removeFromParent()
        SynthAudioEngine.shared.setSirenActive(false)
        activeAttack = false
    }
    
    func update(deltaTime: TimeInterval, speed: Double, chapter: Chapter) {
        guard let scene = scene else { return }
        
        // 1. Spawning logic
        if chapter.airRaidSpawnInterval < 1000.0 && speed > 5.0 && !activeAttack {
            spawnTimer += deltaTime
            if spawnTimer >= chapter.airRaidSpawnInterval {
                spawnTimer = 0.0
                startAirRaid()
            }
        }
        
        // 2. Attack state animation
        if activeAttack {
            attackProgress += deltaTime * 0.28 // about 3.5 seconds to hit
            
            // Blink warning label
            if let warning = warningNode {
                let blink = sin(Date().timeIntervalSince1970 * 12.0) > 0.0
                warning.isHidden = !blink
            }
            
            if attackProgress < 0.7 {
                // Plane is flying in from sky
                let t = attackProgress / 0.7
                let scale = 0.02 + CGFloat(t) * 0.98
                planeNode?.setScale(scale)
                
                // Position curves down from horizon to center sky
                let startY = scene.horizonY + 150
                let endY = scene.size.height - 150
                let y = startY + (endY - startY) * CGFloat(t)
                planeNode?.position = CGPoint(x: scene.size.width / 2 + scene.trainController.visualOffset * 0.5, y: y)
                planeNode?.isHidden = false
            } else if attackProgress < 1.0 {
                // Plane flies away/behind screen, bomb falls down
                planeNode?.setScale(1.2)
                planeNode?.position.y += CGFloat(deltaTime * 300) // moves up offscreen
                
                if bombNode == nil {
                    spawnBomb()
                }
                
                // Bomb progress
                let tBomb = (attackProgress - 0.7) / 0.3
                let startY = scene.size.height - 120
                let endY = scene.horizonY + 40
                let y = startY + (endY - startY) * CGFloat(tBomb)
                
                bombNode?.position = CGPoint(x: scene.size.width / 2 + scene.trainController.visualOffset, y: y)
                bombNode?.setScale(0.1 + CGFloat(tBomb) * 1.5)
            } else {
                // Impact!
                triggerImpact()
            }
        }
    }
    
    private func startAirRaid() {
        guard let scene = scene else { return }
        activeAttack = true
        attackProgress = 0.0
        
        // 1. Trigger audio siren
        SynthAudioEngine.shared.setSirenActive(true)
        
        // 2. Create warning label
        let warning = SKLabelNode(text: "⚠ LUFTWAFFE DETECTED - TAKE COVER [S / DOWN] ⚠")
        warning.fontName = "Helvetica-Bold"
        warning.fontSize = 20
        warning.fontColor = .red
        warning.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 200)
        warning.zPosition = 8.0
        scene.addChild(warning)
        warningNode = warning
        
        // 3. Create plane node geometry
        let plane = SKNode()
        plane.position = CGPoint(x: scene.size.width / 2, y: scene.horizonY + 150)
        plane.zPosition = 5.0
        plane.isHidden = true
        
        // Wing shape
        let wing = SKSpriteNode(color: .gray, size: CGSize(width: 120, height: 16))
        plane.addChild(wing)
        
        // Fuselage shape
        let fuselage = SKSpriteNode(color: SKColor(white: 0.2, alpha: 1.0), size: CGSize(width: 20, height: 80))
        plane.addChild(fuselage)
        
        // Tail shape
        let tail = SKSpriteNode(color: .gray, size: CGSize(width: 40, height: 10))
        tail.position = CGPoint(x: 0, y: -30)
        plane.addChild(tail)
        
        scene.addChild(plane)
        planeNode = plane
    }
    
    private func spawnBomb() {
        guard let scene = scene else { return }
        
        // Simple bomb representation
        let bomb = SKSpriteNode(color: .black, size: CGSize(width: 16, height: 32))
        bomb.zPosition = 5.0
        scene.addChild(bomb)
        bombNode = bomb
    }
    
    private func triggerImpact() {
        guard let scene = scene else { return }
        
        // Clean up components
        warningNode?.removeFromParent()
        planeNode?.removeFromParent()
        bombNode?.removeFromParent()
        warningNode = nil
        planeNode = nil
        bombNode = nil
        
        SynthAudioEngine.shared.setSirenActive(false)
        activeAttack = false
        
        // Evaluate ducking
        let isDucked = scene.trainController.isDucked
        
        if isDucked {
            // Safe duck!
            scene.cameraController.shake(duration: 0.4, intensity: 8)
            SynthAudioEngine.shared.playExplosion()
            scene.triggerFlash(color: .white)
        } else {
            // Direct Hit!
            scene.cameraController.shake(duration: 0.9, intensity: 25)
            GameDirector.shared.updateCoal(-35.0)
            SynthAudioEngine.shared.playExplosion()
            scene.triggerFlash(color: .orange)
        }
    }
}
