//
//  CameraController.swift
//  Konin
//

import Foundation
import SpriteKit

final class CameraController {
    weak var scene: GameScene?
    var cameraNode: SKCameraNode
    
    /// All cockpit/HUD elements should be parented to this node (not directly to cameraNode).
    /// Shaking this node makes the cockpit jiggle visibly inside the viewport.
    /// The world (environment, rails, sky) is completely unaffected.
    let cockpitNode: SKNode = SKNode()
    
    private var basePosition: CGPoint = .zero
    
    // Smoothed camera Y (for duck offset) — avoids snapping
    private var smoothCameraY: CGFloat = 0.0
    
    // MARK: - Impact Shake (cockpit-only)
    private var shakeTimer: TimeInterval = 0.0
    private var shakeIntensity: CGFloat = 0.0
    
    // MARK: - Train Rumble (continuous cockpit bobbing)
    // Multiple overlapping sine waves → organic, non-repeating vibration.
    private var rumbleTime: Double = 0.0
    
    // MARK: - Rumble Boost
    private var rumbleBoost: CGFloat = 1.0
    private var rumbleBoostDecay: CGFloat = 1.5
    
    private struct RumbleLayer {
        let frequency: Double   // Hz
        let ampY: CGFloat       // vertical displacement in points
        let ampX: CGFloat       // horizontal displacement in points
        let phaseOffset: Double // radians — keeps layers from aligning
    }
    
    private let rumbleLayers: [RumbleLayer] = [
        // Heavy slow carriage roll
        RumbleLayer(frequency: 2.1,  ampY: 4.0, ampX: 1.5, phaseOffset: 0.00),
        // Track undulation
        RumbleLayer(frequency: 3.8,  ampY: 2.5, ampX: 0.8, phaseOffset: 1.23),
        // Rail joint bumps
        RumbleLayer(frequency: 7.3,  ampY: 1.5, ampX: 0.4, phaseOffset: 2.71),
        // Track rattle
        RumbleLayer(frequency: 11.9, ampY: 0.8, ampX: 0.2, phaseOffset: 0.88),
        // High-freq engine vibration
        RumbleLayer(frequency: 17.2, ampY: 0.4, ampX: 0.1, phaseOffset: 3.90),
    ]
    
    init(scene: GameScene) {
        self.scene = scene
        self.cameraNode = SKCameraNode()
    }
    
    func setup(in scene: SKScene) {
        basePosition = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        smoothCameraY = basePosition.y
        cameraNode.position = basePosition
        scene.addChild(cameraNode)
        scene.camera = cameraNode
        
        // cockpitNode sits at the centre of camera-space (0,0)
        cockpitNode.position = .zero
        cockpitNode.zPosition = 0
        cameraNode.addChild(cockpitNode)
    }
    
    /// Trigger an impact shake — applied only to cockpitNode, so world-space
    /// nodes (environment, rails, sky) remain completely steady.
    func shake(duration: TimeInterval, intensity: CGFloat) {
        shakeTimer = duration
        // Take the stronger intensity if another shake is already running
        shakeIntensity = max(shakeIntensity, intensity)
    }
    
    /// Temporarily boost the train cockpit's continuous rumble speed and amplitude
    func boostRumble(multiplier: CGFloat, decaySpeed: CGFloat = 1.5) {
        rumbleBoost = max(rumbleBoost, multiplier)
        rumbleBoostDecay = decaySpeed
    }
    
    func update(deltaTime: TimeInterval) {
        guard let train = scene?.trainController else { return }
        let dt = CGFloat(deltaTime)
        
        // 1. Keep camera node completely static.
        //    This guarantees that the environment, sky, ground, and rails stay perfectly stable.
        cameraNode.position = basePosition
        cameraNode.zRotation = 0.0
        
        // Interpolate the vertical duck offset to keep the animation smooth.
        let targetY = basePosition.y + train.duckVisualOffset
        let smoothSpeed: CGFloat = 12.0
        smoothCameraY += (targetY - smoothCameraY) * (1.0 - exp(-smoothSpeed * dt))
        let duckOffset = basePosition.y - smoothCameraY
        
        // 2. Speed-proportional rumble factor (smoothstep ease-in)
        let rawNorm  = CGFloat(min(train.speed / 25.0, 1.0))
        let speedNorm = rawNorm * rawNorm * (3.0 - 2.0 * rawNorm)
        
        // 3. Continuous cockpit rumble — layered sine/cosine waves
        rumbleTime += deltaTime
        var jitterX: CGFloat = 0.0
        var jitterY: CGFloat = 0.0
        
        for layer in rumbleLayers {
            let phase  = CGFloat(rumbleTime * layer.frequency * 2.0 * Double.pi + layer.phaseOffset)
            let phaseX = phase + .pi / 2.0    // offset so X and Y aren't phase-locked
            jitterY += sin(phase)  * layer.ampY
            jitterX += cos(phaseX) * layer.ampX
        }
        
        // Decays back to 1.0
        if rumbleBoost > 1.0 {
            rumbleBoost -= rumbleBoostDecay * dt
            if rumbleBoost < 1.0 {
                rumbleBoost = 1.0
            }
        }
        
        // 4. Impact shake — decays over time, added on top of rumble.
        var shakeX: CGFloat = 0.0
        var shakeY: CGFloat = 0.0
        if shakeTimer > 0.0 {
            shakeTimer -= deltaTime
            shakeIntensity *= CGFloat(1.0 - deltaTime * 1.5)
            shakeX = CGFloat.random(in: -shakeIntensity...shakeIntensity)
            shakeY = CGFloat.random(in: -shakeIntensity...shakeIntensity)
        }
        
        // 5. Lean rotates the cockpit node slightly on lane change
        cockpitNode.zRotation = train.leanAngle * (.pi / 180.0)
        
        // 6. Write combined offset (rumble, impact shake, and duck) to cockpitNode only
        cockpitNode.position = CGPoint(
            x: jitterX * speedNorm * rumbleBoost + shakeX,
            y: jitterY * speedNorm * rumbleBoost + shakeY + duckOffset
        )
    }
}
