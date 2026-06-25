//
//  GameDirector.swift
//  Konin
//

import Foundation
import Observation
import SpriteKit

@Observable
final class GameDirector {
    static let shared = GameDirector()
    
    var currentState: GameState = .menu
    var activeChapter: Chapter = .krotoszyn
    var coalPercentage: Double = 100.0
    var distanceTravelled: Double = 0.0
    
    let audio = SynthAudioEngine.shared
    
    /// Weak reference to the active GameScene so we can trigger the cinematic fail fade.
    weak var activeScene: GameScene?
    
    init() {
        audio.start()
    }
    
    func changeState(to newState: GameState) {
        currentState = newState
        
        switch newState {
        case .menu:
            audio.stop()
            audio.start()
            audio.setAmbienceActive(false)
            audio.setChapter(.krotoszyn)
            audio.setSpeedRatio(1.0)
        case .loading:
            break
        case .story(let chapter):
            activeChapter = chapter
            audio.setAmbienceActive(false)
            audio.setChapter(chapter)
            audio.setSpeedRatio(0.3)
        case .playing(let chapter):
            activeChapter = chapter
            coalPercentage = 100.0
            distanceTravelled = 0.0
            audio.setChapter(chapter)
            audio.setAmbienceActive(true)
            audio.setSpeedRatio(1.0)
        case .failed:
            audio.setSpeedRatio(0.0)
            audio.setSirenActive(false)
            audio.setAmbienceActive(false)
        case .ending:
            audio.setChapter(.zolkiew)
            audio.setAmbienceActive(false)
            audio.setSpeedRatio(0.0)
        case .credits:
            audio.setChapter(.zolkiew)
            audio.setAmbienceActive(false)
            audio.setSpeedRatio(0.0)
        }
    }
    
    func startGame() {
        changeState(to: .loading)
    }
    
    func advanceFromStory(_ chapter: Chapter) {
        changeState(to: .playing(chapter))
    }
    
    func retryChapter(_ chapter: Chapter) {
        changeState(to: .story(chapter))
    }
    
    func completeChapter(_ chapter: Chapter) {
        if let nextChapter = chapter.next {
            changeState(to: .playing(nextChapter))
        } else {
            changeState(to: .ending)
        }
    }
    
    func updateCoal(_ amount: Double) {
        coalPercentage = max(0.0, min(100.0, coalPercentage + amount))
        if coalPercentage <= 0.0 {
            triggerFail()
        }
    }
    
    /// Initiates the cinematic fail sequence.
    /// If a scene is available, it animates the fade-to-black inside the scene first,
    /// then the scene callback dispatches changeState(.failed). Otherwise falls back directly.
    private func triggerFail() {
        if let scene = activeScene {
            scene.triggerFailFade(chapter: activeChapter)
        } else {
            changeState(to: .failed(activeChapter))
        }
    }
}
