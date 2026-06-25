//
//  ContentView.swift
//  Konin
//

import SwiftUI

struct ContentView: View {
    @State private var director = GameDirector.shared
    
    private var isWhiteBackgroundState: Bool {
        switch director.currentState {
        case .ending, .credits:
            return true
        case .playing(let chapter):
            return chapter == .zolkiew
        default:
            return false
        }
    }
    
    var body: some View {
        ZStack {
            // Dynamic baseline background to prevent black flashes during transitions
            (isWhiteBackgroundState ? Color.white : Color.black)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.0), value: isWhiteBackgroundState)
            
            switch director.currentState {
            case .menu:
                MainMenuView()
                    .transition(.opacity)
            case .loading:
                LoadingView()
                    .transition(.opacity)
            case .story(let chapter):
                StoryView(chapter: chapter)
                    .id("story-\(chapter.rawValue)")
                    .transition(.opacity)
            case .playing(let chapter):
                GameView(chapter: chapter)
                    .transition(.opacity)
            case .failed(let chapter):
                FailedView(chapter: chapter)
                    .transition(.opacity)
            case .ending:
                EndingView()
                    .transition(.opacity)
            case .credits:
                EndingView()
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
  
#Preview {
    ContentView()
}
