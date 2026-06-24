//
//  TrainController.swift
//  Konin
//

import Foundation
import SpriteKit

final class TrainController {
    weak var scene: GameScene?
    
    // Lane configuration: 0 = Left, 1 = Center, 2 = Right
    var currentLane: Int = 1  // start in center
    var targetLane: Int = 1
    
    // Lateral offset (spring-damped) — applied to all scene elements
    var visualOffset: CGFloat = 0.0   // lane 1 (center) = 0
    private var visualOffsetVelocity: CGFloat = 0.0

    // Lean angle (degrees) — read by CameraController
    var leanAngle: CGFloat = 0.0
    private var leanVelocity: CGFloat = 0.0
    
    // Spam prevention cooldown
    private var switchCooldownTimer: TimeInterval = 0.0
    private let switchCooldownDuration: TimeInterval = 0.35 // delay in seconds (350ms)
    
    // Train physics
    var speed: Double = 0.0
    var targetSpeed: Double = 0.0
    var distanceTravelled: Double = 0.0
    
    // Ducking
    var isDucked: Bool = false
    var duckVisualOffset: CGFloat = 0.0
    
    var hasTriggeredEnding: Bool = false
    
    // Startup ramp
    private var startupTimer: TimeInterval = 0.0
    private let startupDuration: TimeInterval = 3.0
    private var isStartingUp: Bool = true
    
    // Lane offset map: lane 0 = +160 (shift right so left track centres),
    //                  lane 1 = 0 (centre already centred),
    //                  lane 2 = -160 (shift left so right track centres)
    static let laneOffsets: [CGFloat] = [160.0, 0.0, -160.0]
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func update(deltaTime: TimeInterval, chapter: Chapter) {
        guard let scene = scene else { return }
        let dt = CGFloat(deltaTime)
        
        // Update track switch cooldown timer
        if switchCooldownTimer > 0.0 {
            switchCooldownTimer -= deltaTime
        }
        
        // 1. Target speed
        if GameDirector.shared.coalPercentage <= 0 {
            targetSpeed = 0.0
        } else if chapter == .zolkiew {
            targetSpeed = 0.0
        } else {
            let coalFactor = GameDirector.shared.coalPercentage / 100.0
            let topSpeed = chapter == .konin ? 25.0 : (15.0 + coalFactor * 20.0)
            
            if isStartingUp {
                startupTimer += deltaTime
                let ramp = min(1.0, startupTimer / startupDuration)
                let easedRamp = ramp * ramp * (3.0 - 2.0 * ramp)
                targetSpeed = topSpeed * easedRamp
                if startupTimer >= startupDuration { isStartingUp = false }
            } else {
                targetSpeed = topSpeed
            }
        }
        
        // 2. Smooth speed
        let accel = 12.0
        if speed < targetSpeed {
            speed = min(targetSpeed, speed + accel * deltaTime)
        } else if speed > targetSpeed {
            speed = max(targetSpeed, speed - accel * 2.5 * deltaTime)
        }
        
        // 3. Distance
        if speed > 0 {
            distanceTravelled += speed * deltaTime * 0.5
            GameDirector.shared.distanceTravelled = distanceTravelled
            SynthAudioEngine.shared.setSpeedRatio(Float(speed / 35.0))
            
            if distanceTravelled >= chapter.targetDistance && chapter.targetDistance > 0 && !hasTriggeredEnding {
                speed = 0; targetSpeed = 0
                hasTriggeredEnding = true
                DispatchQueue.main.async {
                    if chapter == .konin {
                        GameDirector.shared.completeChapter(chapter)
                    } else {
                        self.scene?.triggerChapterSuccessFade(chapter: chapter)
                    }
                }
            }
        } else if chapter == .zolkiew && speed <= 0.1 && !hasTriggeredEnding {
            hasTriggeredEnding = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                GameDirector.shared.completeChapter(.zolkiew)
            }
        }
        
        // 4. Lateral spring-damper toward target lane offset
        let targetOffset = TrainController.laneOffsets[targetLane]
        let stiffness: CGFloat = 80.0
        let damping: CGFloat   = 22.0
        let force = (targetOffset - visualOffset) * stiffness - visualOffsetVelocity * damping
        visualOffsetVelocity += force * dt
        visualOffset += visualOffsetVelocity * dt
        
        // 5. Lean from lateral velocity (spring-smoothed)
        let targetLean: CGFloat = -visualOffsetVelocity * 0.045
        let leanStiffness: CGFloat = 60.0
        let leanDamping: CGFloat   = 16.0
        let leanForce = (targetLean - leanAngle) * leanStiffness - leanVelocity * leanDamping
        leanVelocity += leanForce * dt
        leanAngle += leanVelocity * dt
        leanAngle = max(-7.0, min(7.0, leanAngle))
        
        // 6. Duck interpolation
        let targetDuckOffset: CGFloat = isDucked ? -80.0 : 0.0
        duckVisualOffset += (targetDuckOffset - duckVisualOffset) * (1.0 - exp(-10.0 * dt))
    }
    
    /// Shift one lane to the left (towards lane 0)
    func shiftLaneLeft() {
        guard speed > 5.0 && switchCooldownTimer <= 0.0 else { return }
        let newLane = max(0, targetLane - 1)
        if newLane != targetLane {
            targetLane = newLane
            switchCooldownTimer = switchCooldownDuration
            SynthAudioEngine.shared.playRailSwitch()
        }
    }
    
    /// Shift one lane to the right (towards lane 2)
    func shiftLaneRight() {
        guard speed > 5.0 && switchCooldownTimer <= 0.0 else { return }
        let newLane = min(2, targetLane + 1)
        if newLane != targetLane {
            targetLane = newLane
            switchCooldownTimer = switchCooldownDuration
            SynthAudioEngine.shared.playRailSwitch()
        }
    }
    
    /// Instantly target the center lane (1) from any position
    func returnToCenter() {
        guard speed > 5.0 && switchCooldownTimer <= 0.0 else { return }
        if targetLane != 1 {
            targetLane = 1
            switchCooldownTimer = switchCooldownDuration
            SynthAudioEngine.shared.playRailSwitch()
        }
    }
    
    func setDucked(_ ducked: Bool) {
        isDucked = ducked
    }
    
    func resetStartup() {
        isStartingUp = true
        startupTimer = 0.0
        speed = 0.0
        targetSpeed = 0.0
        visualOffsetVelocity = 0.0
        leanVelocity = 0.0
        switchCooldownTimer = 0.0
    }
}
