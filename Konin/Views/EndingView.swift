//
//  EndingView.swift
//  Konin
//

import SwiftUI

struct EndingView: View {
    let director = GameDirector.shared
    
    enum EndingPhase {
        case narrative
        case illustration
        case credits
    }
    
    @State private var currentPhase: EndingPhase = .narrative
    @State private var headerOpacity = 0.0
    @State private var lineOpacities: [Double] = [0.0, 0.0, 0.0, 0.0]
    @State private var showContinue = false
    @State private var blinkContinue = false
    
    // Illustration Phase State
    @State private var imageOpacity = 0.0
    @State private var showIllustrationContinue = false
    
    let lines = [
        "The train never reached Konin.",
        "Destroyed during an air raid in September 1939.",
        "The families, crew, and passengers never arrived at their destination.",
        "Yet some journeys continue beyond the rails."
    ]
    
    var body: some View {
        GeometryReader { windowGeo in
            let targetSize = CGSize(width: 1024, height: 768)
            let scale = min(windowGeo.size.width / targetSize.width, windowGeo.size.height / targetSize.height)
            
            ZStack {
                // 1. WHITE BACKGROUND
                Color.white
                    .frame(width: targetSize.width, height: targetSize.height)
                
                // 2. RADIAL GRADIENT OVERLAY (Soft light vignette)
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color(white: 1)
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.5),
                    startRadius: 0,
                    endRadius: 550
                )
                .frame(width: targetSize.width, height: targetSize.height)
                
                // 3. CONTENT LAYOUT
                switch currentPhase {
                case .narrative:
                    ZStack {
                        // Header "SEPTEMBER 1939" at (x: 129, y: 197)
                        Text("September 1939")
                            .font(.custom("VCR OSD Mono", size: 24))
                            .foregroundColor(.black)
                            .tracking(24 * -0.06) // letterSpacing: -0.06em
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .opacity(headerOpacity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.leading, 129)
                            .padding(.top, 197)
                        
                        // Paragraphs at (x: 129, y: 294, width: 734)
                        VStack(alignment: .leading, spacing: 21) {
                            ForEach(0..<lines.count, id: \.self) { index in
                                Text(lines[index])
                                    .font(.custom("VCR OSD Mono", size: 24))
                                    .foregroundColor(.black)
                                    .tracking(24 * -0.06)
                                    .lineSpacing(4)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .opacity(lineOpacities.indices.contains(index) ? lineOpacities[index] : 0.0)
                            }
                        }
                        .frame(width: 734, alignment: .leading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 129)
                        .padding(.top, 294)
                        
                        // Click to Continue Prompt (blinking, bottom center)
                        if showContinue {
                            Text("Click to continue")
                                .font(.custom("VCR OSD Mono", size: 18))
                                .foregroundColor(Color(white: 0.4))
                                .tracking(18 * -0.06)
                                .opacity(blinkContinue ? 0.2 : 1.0)
                                .frame(width: 1024)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .padding(.bottom, 60)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: targetSize.width, height: targetSize.height)
                    .scaleEffect(scale)
                    .position(x: windowGeo.size.width / 2, y: windowGeo.size.height / 2)
                    .transition(.opacity)
                    
                case .illustration:
                    VStack(spacing: 30) {
                        Image("TrainWreck")
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 734, height: 413)
                            .cornerRadius(6)
                            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
                            .opacity(imageOpacity)
                        
                        Text("Wreckage of the evacuation train outside the tunnel, September 1939.")
                            .font(.custom("VCR OSD Mono", size: 18))
                            .foregroundColor(.black)
                            .tracking(18 * -0.06)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .opacity(imageOpacity)
                        
                        Spacer()
                            .frame(height: 20)
                        
                        if showIllustrationContinue {
                            Text("Click to continue")
                                .font(.custom("VCR OSD Mono", size: 18))
                                .foregroundColor(Color(white: 0.4))
                                .tracking(18 * -0.06)
                                .opacity(blinkContinue ? 0.2 : 1.0)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: targetSize.width, height: targetSize.height)
                    .scaleEffect(scale)
                    .position(x: windowGeo.size.width / 2, y: windowGeo.size.height / 2)
                    .transition(.opacity)
                    .onAppear {
                        startIllustrationAnimation()
                    }
                    
                case .credits:
                    ZStack {
                        VStack(spacing: 40) {
                            Text("All Points South")
                                .font(.custom("VCR OSD Mono", size: 36))
                                .foregroundColor(.black)
                                .tracking(36 * -0.06)
                            
                            VStack(spacing: 20) {
                                Text("A Historical Arcade Experience")
                                    .font(.custom("VCR OSD Mono", size: 18))
                                    .foregroundColor(Color(white: 0.3))
                                    .tracking(18 * -0.06)
                                
                                Text("Created by Awan, Evelyn, and Ridwan")
                                    .font(.custom("VCR OSD Mono", size: 20))
                                    .foregroundColor(.black)
                                    .tracking(20 * -0.06)
                                
                                Text("Developed with SwiftUI and SpriteKit")
                                    .font(.custom("VCR OSD Mono", size: 16))
                                    .foregroundColor(Color(white: 0.4))
                                    .tracking(16 * -0.06)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    director.changeState(to: .menu)
                                }
                            }) {
                                Text("Return to Main Menu")
                                    .font(.custom("VCR OSD Mono", size: 18))
                                    .foregroundColor(.white)
                                    .tracking(18 * -0.06)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.black)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(width: 800)
                        .padding(.vertical, 60)
                    }
                    .frame(width: targetSize.width, height: targetSize.height)
                    .scaleEffect(scale)
                    .position(x: windowGeo.size.width / 2, y: windowGeo.size.height / 2)
                    .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleTap()
            }
        }
        .background(Color.white)
        .onAppear {
            startEndingAnimation()
        }
    }
    
    private func startEndingAnimation() {
        headerOpacity = 0.0
        lineOpacities = [0.0, 0.0, 0.0, 0.0]
        showContinue = false
        blinkContinue = false
        currentPhase = .narrative
        
        // Wait 0.8s for screen transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 2.0)) {
                headerOpacity = 1.0
            }
        }
        
        for i in 0..<lines.count {
            let delay = 0.8 + 2.0 + Double(i) * 2.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard currentPhase == .narrative else { return }
                withAnimation(.easeIn(duration: 2.0)) {
                    if lineOpacities.indices.contains(i) {
                        lineOpacities[i] = 1.0
                    }
                }
            }
        }
        
        let totalDelay = 0.8 + 2.0 + Double(lines.count) * 2.2 + 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            guard currentPhase == .narrative else { return }
            withAnimation(.easeIn(duration: 1.0)) {
                showContinue = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                blinkContinue = true
            }
        }
    }
    
    private func startIllustrationAnimation() {
        imageOpacity = 0.0
        showIllustrationContinue = false
        
        withAnimation(.easeIn(duration: 2.0)) {
            imageOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard currentPhase == .illustration else { return }
            withAnimation(.easeIn(duration: 1.0)) {
                showIllustrationContinue = true
            }
        }
    }
    
    private func handleTap() {
        switch currentPhase {
        case .narrative:
            let isFullyLoaded = headerOpacity >= 1.0 && !lineOpacities.contains(where: { $0 < 1.0 })
            if isFullyLoaded {
                withAnimation(.easeInOut(duration: 1.5)) {
                    currentPhase = .illustration
                }
            } else {
                withAnimation {
                    headerOpacity = 1.0
                    lineOpacities = Array(repeating: 1.0, count: lines.count)
                    showContinue = true
                }
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    blinkContinue = true
                }
            }
        case .illustration:
            if showIllustrationContinue {
                withAnimation(.easeInOut(duration: 1.5)) {
                    currentPhase = .credits
                }
            } else {
                withAnimation {
                    imageOpacity = 1.0
                    showIllustrationContinue = true
                }
            }
        case .credits:
            break
        }
    }
}

#Preview {
    EndingView()
}
