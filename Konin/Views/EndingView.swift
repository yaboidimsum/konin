//
//  EndingView.swift
//  Konin
//

import SwiftUI

struct EndingView: View {
    let director = GameDirector.shared
    
    @State private var lineIndex = 0
    @State private var fadeToWhite = false
    @State private var showCredits = false
    
    let lines = [
        "The train never reached Konin.",
        "Destroyed during an air raid in September 1939.",
        "The families, crew, and passengers never arrived at their destination.",
        "Yet some journeys continue beyond the rails."
    ]
    
    var body: some View {
        ZStack {
            if !showCredits {
                // Narrative Text phase
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        ForEach(0..<lines.count, id: \.self) { index in
                            Text(lines[index])
                                .font(.system(size: 20, weight: .medium, design: .serif))
                                .italic()
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .opacity(lineIndex >= index ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 2.0).delay(Double(index) * 0.5), value: lineIndex)
                        }
                    }
                    
                    // Flash/Fade overlay to solid white
                    if fadeToWhite {
                        Color.white
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }
                }
                .onAppear {
                    playSequence()
                }
            } else {
                // Credits rolling phase
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                    
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
            }
        }
    }
    
    private func playSequence() {
        // Line-by-line reveal
        for i in 0..<lines.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 3.5 + 1.0) {
                withAnimation {
                    lineIndex = i
                }
            }
        }
        
        // Trigger fade to white
        let fadeTime = Double(lines.count) * 3.5 + 3.0
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeTime) {
            withAnimation(.easeInOut(duration: 3.0)) {
                fadeToWhite = true
            }
        }
        
        // Swap to credits
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeTime + 4.5) {
            withAnimation(.easeInOut(duration: 2.0)) {
                showCredits = true
            }
        }
    }
}
