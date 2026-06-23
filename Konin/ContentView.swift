//
//  ContentView.swift
//  Konin
//

import SwiftUI

struct ContentView: View {
    @State private var director = GameDirector.shared
    
    var body: some View {
        ZStack {
            // Dark baseline background
            Color.black
                .ignoresSafeArea()
            
            switch director.currentState {
            case .menu:
                MainMenuView()
                    .transition(.opacity)
            case .story(let chapter):
                StoryView(chapter: chapter)
                    .id("story-\(chapter.rawValue)")
                    .transition(.opacity)
            case .playing(let chapter):
                GameView(chapter: chapter)
                    .id("playing-\(chapter.rawValue)")
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
