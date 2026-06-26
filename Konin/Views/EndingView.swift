//
//  EndingView.swift
//  Konin
//

import SwiftUI

struct EndingView: View {
    let director = GameDirector.shared
    
    @State private var lineIndex = 0
    @State private var showCredits = false
    @State private var cardOpacity = 0.0
    @State private var vignetteOpacity = 0.0
    
    let lines = [
        "The train never reached Konin.",
        "Destroyed during an air raid in September 1939.",
        "The families, crew, and passengers never arrived at their destination.",
        "Yet some journeys continue beyond the rails."
    ]
    
    var body: some View {
        ZStack {
            // Baseline white background for the entire ending view
            Color.white
                .ignoresSafeArea()
            
            if !showCredits {
                // Narrative Text phase
                ZStack {
                    VStack(spacing: 24) {
                        ForEach(0..<lines.count, id: \.self) { index in
                            Text(lines[index])
                                .font(.system(size: 20, weight: .medium, design: .serif))
                                .italic()
                                .foregroundColor(Color(white: 0.12))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .opacity(lineIndex >= index ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 2.0).delay(Double(index) * 0.5), value: lineIndex)
                        }
                    }
                    .padding(.vertical, 40)
                    .padding(.horizontal, 30)
                    // The frame of the message is white with a soft shadow and double-like premium borders
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 25, x: 0, y: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
                    .opacity(cardOpacity)
                }
                .transition(.opacity)
                .onAppear {
                    playSequence()
                }
            } else {
                // Credits rolling phase
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("LAST TRAIN EAST")
                        .font(.system(size: 36, weight: .heavy, design: .serif))
                        .foregroundColor(.black)
                        .tracking(6)
                    
                    VStack(spacing: 12) {
                        Text("A Historical Arcade Experience")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Divider()
                            .frame(width: 200)
                            .background(Color.black.opacity(0.1))
                        
                        Text("Created by Dimas Prihady Setyawan")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("Developed with Swift, SwiftUI, and SpriteKit")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            director.changeState(to: .menu)
                        }
                    }) {
                        Text("RETURN TO MAIN MENU")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding()
                .transition(.opacity)
            }
            
            // Vignette overlay spanning both phases for visual consistency
            RadialGradient(
                gradient: Gradient(colors: [.clear, Color.black.opacity(0.35)]),
                center: .center,
                startRadius: 180,
                endRadius: 550
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .opacity(vignetteOpacity)
        }
    }
    
    private func playSequence() {
        // Fade in card container and vignette shadow
        withAnimation(.easeOut(duration: 2.0)) {
            cardOpacity = 1.0
            vignetteOpacity = 1.0
        }
        
        // Line-by-line reveal of the text
        for i in 0..<lines.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 3.5 + 2.0) {
                withAnimation {
                    lineIndex = i
                }
            }
        }
        
        // Fade out card frame smoothly before swapping to credits
        let fadeOutTime = Double(lines.count) * 3.5 + 3.0 // 17.0s
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutTime) {
            withAnimation(.easeInOut(duration: 1.5)) {
                cardOpacity = 0.0
            }
        }
        
        // Transition to credits view
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutTime + 2.0) { // 19.0s
            withAnimation(.easeInOut(duration: 2.0)) {
                showCredits = true
            }
        }
    }
}

#Preview {
    EndingView()
}
