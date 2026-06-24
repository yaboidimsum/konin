//
//  StoryView.swift
//  Konin
//

import SwiftUI

struct StoryView: View {
    let chapter: Chapter
    let director = GameDirector.shared
    
    var body: some View {
        ZStack {
            // Dark thematic background
            Color(white: 0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Chapter Heading
                Text(chapter.title.uppercased())
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(chapter == .konin ? .teal : .red.opacity(0.8))
                    .tracking(4)
                
                Spacer()
                
                // Story lines display - instantly shown all at once
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(chapter.storyText, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundColor(.white)
                            .lineSpacing(6)
                    }
                }
                .frame(maxWidth: 600, alignment: .leading)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 1.0, opacity: 0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(white: 1.0, opacity: 0.05), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // Depart/Start Button shown instantly
                Button(action: {
                    director.advanceFromStory(chapter)
                }) {
                    Text(chapter == .zolkiew ? "ARRIVE AT STATION" : "DEPART STATION")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(chapter == .konin ? Color.teal : Color.red)
                        )
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // Automatically advance to the next chapter after 6.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                if director.currentState == .story(chapter) {
                    withAnimation {
                        director.advanceFromStory(chapter)
                    }
                }
            }
        }
    }
}
