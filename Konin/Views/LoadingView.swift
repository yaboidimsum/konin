//
//  LoadingView.swift
//  Konin
//

import SwiftUI

struct LoadingView: View {
    let director = GameDirector.shared
    
    @State private var progress: Double = 0.0
    @State private var blinkText = false
    
    // Cached once at view initialization
    private let backgroundImage: Image
    
    init() {
        if let url = Bundle.main.url(forResource: "loading-menu-2", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            self.backgroundImage = Image(nsImage: nsImage)
        } else {
            self.backgroundImage = Image("background-1") // Fallback
        }
    }
    
    var body: some View {
        GeometryReader { windowGeo in
            ZStack {
                // 1. FULL-SCREEN BACKGROUND IMAGE (Read from memory, no disk IO on redraw)
                backgroundImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: windowGeo.size.width, height: windowGeo.size.height)
                    .clipped()
                
                // 2. FULL-SCREEN RADIAL GRADIENT OVERLAY
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.17, blue: 0.17, opacity: 0.0),
                        Color(red: 0.0, green: 0.04, blue: 0.03, opacity: 1.0)
                    ]),
                    center: UnitPoint(x: 0.46, y: 0.50),
                    startRadius: 0,
                    endRadius: max(windowGeo.size.width, windowGeo.size.height) * 0.6
                )
                .frame(width: windowGeo.size.width, height: windowGeo.size.height)
                
                // 3. SCALED FIGMA LAYOUT OVERLAY (1024x768 Canvas)
                let targetSize = CGSize(width: 1024, height: 768)
                let scale = min(windowGeo.size.width / targetSize.width, windowGeo.size.height / targetSize.height)
                
                ZStack {
                    // Loading Text and Bar Column
                    VStack(spacing: 24) {
                        // Progress / Call-to-action text
                        Text(progress < 1.0 ? "\(Int(progress * 100))%" : "Click to continue")
                            .font(.custom("VCR OSD Mono", size: 24))
                            .foregroundColor(.white)
                            .tracking(24 * -0.06) // letterSpacing: -0.06em
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .opacity(blinkText ? 0.2 : 1.0)
                        
                        // Progress Bar Frame
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.black)
                                .frame(height: 37)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 40/255, green: 45/255, blue: 39/255), lineWidth: 4)
                                )
                            
                            // Fill (Same gradient as main menu buttons)
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 98/255, green: 109/255, blue: 95/255),
                                    Color(red: 35/255, green: 39/255, blue: 34/255)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: max(0, CGFloat(progress) * (826 - 8)), height: 37 - 8)
                            .padding(.leading, 4)
                        }
                        .frame(width: 826, height: 37)
                    }
                    .frame(width: 826)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 99)
                    .padding(.top, 654)
                }
                .frame(width: targetSize.width, height: targetSize.height)
                .scaleEffect(scale)
                .position(x: windowGeo.size.width / 2, y: windowGeo.size.height / 2)
            }
            .contentShape(Rectangle()) // Make the whole screen tap-interactive
            .onTapGesture {
                if progress >= 1.0 {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        director.changeState(to: .story(.krotoszyn))
                    }
                }
            }
        }
        .background(Color.black)
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        progress = 0.0
        blinkText = false
        
        let duration: Double = 3.0 // 3 seconds loading duration
        let fps: Double = 60.0
        let interval = 1.0 / fps
        let totalSteps = Int(duration * fps)
        var step = 0
        
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            step += 1
            let ratio = Double(step) / Double(totalSteps)
            
            // Starts slow, jumps fast: pow(ratio, 3.5)
            let currentProgress = pow(ratio, 3.5)
            progress = min(1.0, currentProgress)
            
            if step >= totalSteps {
                timer.invalidate()
                progress = 1.0
                
                // Trigger the click-to-continue blinking loop
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    blinkText = true
                }
            }
        }
    }
}
