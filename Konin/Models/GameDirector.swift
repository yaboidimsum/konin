//
//  GameDirector.swift
//  Konin
//

import Foundation
import Observation
import SpriteKit
import SwiftUI

@Observable
final class GameDirector {
    static let shared = GameDirector()
    
    var currentState: GameState = .menu
    var activeChapter: Chapter = .krotoszyn
    var coalPercentage: Double = 100.0
    var distanceTravelled: Double = 0.0
    var hudOpacity: Double = 1.0
    
    let audio = SynthAudioEngine.shared
    
    /// Weak reference to the active GameScene so we can trigger the cinematic fail fade.
    weak var activeScene: GameScene?
    
    init() {
        audio.start()
        audio.startMenuMusic()
    }
    
    func changeState(to newState: GameState) {
        currentState = newState
        
        if newState != .menu {
            audio.stopMenuMusic(duration: 1.5)
        }
        
        switch newState {
        case .menu:
            audio.stop()
            audio.start()
            audio.setAmbienceActive(false)
            audio.setChapter(.krotoszyn)
            audio.setSpeedRatio(1.0)
            audio.startMenuMusic()
        case .loading:
            break
        case .story(let chapter):
            activeChapter = chapter
            audio.setChapter(chapter)
            if chapter == .prolog || chapter == .krotoszyn {
                audio.startIntroJohn()
            } else {
                audio.setAmbienceActive(false)
            }
            audio.setSpeedRatio(0.3)
        case .playing(let chapter):
            activeChapter = chapter
            coalPercentage = 100.0
            distanceTravelled = 0.0
            hudOpacity = 0.0
            audio.setChapter(chapter)
            if chapter == .krotoszyn {
                audio.stopIntroJohn(duration: 4.0)
            }
            audio.setAmbienceActive(true)
            audio.setSpeedRatio(1.0)
        case .failed:
            audio.setSpeedRatio(0.0)
            audio.setSirenActive(false)
            audio.setAmbienceActive(false)
        case .ending:
            audio.setChapter(.zolkiew)
            audio.stopTrainSound()
            audio.setSpeedRatio(0.0)
        case .credits:
            audio.setChapter(.zolkiew)
            audio.stopTrainSound()
            audio.setSpeedRatio(0.0)
        }
    }
    
    func startGame() {
        changeState(to: .loading)
    }
    
    func advanceFromStory(_ chapter: Chapter) {
        if chapter == .prolog {
            changeState(to: .story(.krotoszyn))
        } else {
            changeState(to: .playing(chapter))
        }
    }
    
    func retryChapter(_ chapter: Chapter) {
        changeState(to: .story(chapter))
    }
    
    func completeChapter(_ chapter: Chapter) {
        withAnimation(.easeInOut(duration: 1.5)) {
            if let nextChapter = chapter.next {
                changeState(to: .playing(nextChapter))
            } else {
                changeState(to: .ending)
            }
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
            withAnimation(.easeInOut(duration: 1.0)) {
                changeState(to: .failed(activeChapter))
            }
        }
    }
}
