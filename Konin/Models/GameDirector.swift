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
    var isPaused: Bool = false {
        didSet {
            if isPaused {
                activeScene?.pauseGame()
            } else {
                activeScene?.resumeGame()
            }
        }
    }
    
    let audio = SynthAudioEngine.shared
    
    /// Weak reference to the active GameScene so we can trigger the cinematic fail fade.
    weak var activeScene: GameScene?
    
    private init() {
        audio.start()
        audio.startMenuMusic()
    }
    
    // MARK: - State Machine
    
    func changeState(to newState: GameState) {
        currentState = newState
        isPaused = false
        
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
            
        case .cutscene(let chapter):
            // Cutscenes play before a chapter's story/bridge screen.
            // Currently only .prolog has a cutscene.
            activeChapter = chapter
            audio.setChapter(chapter)
            audio.startIntroJohn()
            audio.setSpeedRatio(0.0)
            
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
            audio.setSpeedRatio(chapter.isGhostSegment ? 0.6 : 1.0)
            
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
    
    // MARK: - Navigation Helpers
    
    // Full game flow:
    //
    //   .menu
    //     → .loading
    //     → .cutscene(.prolog)          ← cinematic opening (6 scenes)
    //     → .story(.krotoszyn)          ← bridge text "the sky turned red..."
    //     → .playing(.krotoszyn)
    //     → .story(.kozmin)             ← bridge text "Krotoszyn has crumbled..."
    //     → .playing(.kozmin)
    //     → .story(.jarocin)
    //     → .playing(.jarocin)
    //     → .story(.tunnel)             ← triggered by explosion, not chapter complete
    //     → .playing(.tunnel)
    //     → .story(.konin)
    //     → .playing(.konin)
    //     → .story(.zolkiew)
    //     → .playing(.zolkiew)
    //     → .ending
    //     → .credits
    
    /// Called by LoadingView once assets are ready.
    func startGame() {
        changeState(to: .cutscene(.prolog))
    }
    
    /// Called when a cutscene finishes (player taps through all scenes).
    func advanceFromCutscene(_ chapter: Chapter) {
        switch chapter {
            
        case .prolog:
            changeState(to: .story(.krotoszyn))
            
        case .zolkiew:
            changeState(to: .ending)
            
        default:
            changeState(to: .story(chapter))
        }
    }
    
    /// Called when the player taps "continue" on a StoryView.
    /// Called when the player taps "continue" on a StoryView.
    func advanceFromStory(_ chapter: Chapter) {
        // POTONG JALUR DI SINI
        if chapter == .zolkiew {
            changeState(to: .cutscene(.zolkiew)) // Langsung masuk dialog visual, gak pake gameplay lokomotif!
        } else {
            changeState(to: .playing(chapter)) // Chapter lain tetep masuk gameplay normal
        }
    }
    
    /// Called when a chapter's gameplay is successfully completed.
    func completeChapter(_ chapter: Chapter) {
        withAnimation(.easeInOut(duration: 1.5)) {
            
            switch chapter {
                
            case .zolkiew:
                changeState(to: .cutscene(.zolkiew))
                
            default:
                if let nextChapter = chapter.next {
                    changeState(to: .story(nextChapter))
                } else {
                    changeState(to: .ending)
                }
            }
        }
    }
    
    /// Called from FailView when the player chooses to retry.
    func retryChapter(_ chapter: Chapter) {
        changeState(to: .story(chapter))
    }
    
    // MARK: - Coal Management
    
    func updateCoal(_ amount: Double) {
        coalPercentage = max(0.0, min(100.0, coalPercentage + amount))
        if coalPercentage <= 0.0 {
            triggerFail()
        }
    }
    
    // MARK: - Fail Sequence
    
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
