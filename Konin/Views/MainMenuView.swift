//
//  MainMenuView.swift
//  Konin
//

import SwiftUI

struct MainMenuView: View {
    let director = GameDirector.shared
    @State private var animateStart = false
    @State private var hovered = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Grid texture pattern for interest
            GeometryReader { geo in
                Path { path in
                    let size = 40.0
                    for x in stride(from: 0.0, to: geo.size.width, by: size) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0.0, to: geo.size.height, by: size) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color(white: 1.0, opacity: 0.02), lineWidth: 1)
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title Group
                VStack(spacing: 12) {
                    Text("LAST TRAIN EAST")
                        .font(.system(size: 48, weight: .heavy, design: .serif))
                        .foregroundColor(.white)
                        .tracking(8)
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 0)
                    
                    Text("Escort the innocent. Outrun the storm.")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(2)
                }
                
                // Narrative context quote
                Text("“September 1939. German forces push east into Poland. The rails are the last lifeline for thousands of fleeing families.”")
                    .font(.system(size: 14, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(Color(white: 0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 1.0, opacity: 0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(white: 1.0, opacity: 0.08), lineWidth: 1)
                            )
                    )
                
                Spacer()
                
                // Play Button
                Button(action: {
                    withAnimation {
                        director.startGame()
                    }
                }) {
                    Text("BEGIN THE JOURNEY")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(hovered ? Color.red : Color.white)
                                .shadow(color: hovered ? Color.red.opacity(0.5) : Color.white.opacity(0.3), radius: hovered ? 12 : 6)
                        )
                        .scaleEffect(hovered ? 1.05 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hovered = isHovered
                    }
                }
                
                Text("Use WASD/Arrows to switch tracks and duck. Space to fuel the furnace.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.8))
                
                Spacer()
            }
            .padding()
        }
    }
}
