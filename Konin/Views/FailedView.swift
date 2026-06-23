//
//  FailedView.swift
//  Konin
//

import SwiftUI

struct FailedView: View {
    let chapter: Chapter
    let director = GameDirector.shared
    @State private var hoveredRetry = false
    @State private var hoveredMenu = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("THE ENGINE STALLED")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(.red)
                        .tracking(4)
                    
                    Text("The coal reserves depleted. The furnace door went cold.")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(.gray)
                }
                
                Text("Without fuel, the evacuation train ground to a silent halt on the tracks, stranded in the path of the advancing frontline.")
                    .font(.system(size: 14, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(Color(white: 0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
                    .padding(24)
                    .background(Color(white: 0.08))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            director.retryChapter(chapter)
                        }
                    }) {
                        Text("RETRY CHAPTER")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(hoveredRetry ? Color.white : Color.red)
                            )
                            .scaleEffect(hoveredRetry ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovered in
                        withAnimation { hoveredRetry = isHovered }
                    }
                    
                    Button(action: {
                        withAnimation {
                            director.changeState(to: .menu)
                        }
                    }) {
                        Text("RETURN TO MENU")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .scaleEffect(hoveredMenu ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovered in
                        withAnimation { hoveredMenu = isHovered }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
