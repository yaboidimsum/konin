//
//  StoryView.swift
//  Konin
//

import SwiftUI

struct StoryView: View {
    let chapter: Chapter
    let director = GameDirector.shared
    
    @State private var lineOpacities: [Double]
    @State private var showContinue = false
    @State private var blinkContinue = false
    
    init(chapter: Chapter) {
        self.chapter = chapter
        let lineCount = chapter.storyParagraphs.count + 1
        self._lineOpacities = State(initialValue: Array(repeating: 0.0, count: lineCount))
    }
    
    var body: some View {
        GeometryReader { windowGeo in
            let targetSize = CGSize(width: 1024, height: 768)
            let scale = min(windowGeo.size.width / targetSize.width, windowGeo.size.height / targetSize.height)
            
            ZStack {
                // 1. BLACK BACKGROUND
                Color.black
                    .frame(width: targetSize.width, height: targetSize.height)
                
                // 2. RADIAL GRADIENT OVERLAY
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.0),
                        Color.black
                    ]),
                    center: UnitPoint(x: 0.46, y: 0.50),
                    startRadius: 0,
                    endRadius: 550
                )
                .frame(width: targetSize.width, height: targetSize.height)
                
                // 3. STORY LAYOUT
                ZStack {
                    // Header/Date (x: 129, y: 197)
                    Text(chapter.storyHeader)
                        .font(.custom("VCR OSD Mono", size: 24))
                        .foregroundColor(.white)
                        .tracking(24 * -0.06) // letterSpacing: -0.06em
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .opacity(lineOpacities.indices.contains(0) ? lineOpacities[0] : 0.0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 129)
                        .padding(.top, 197)
                    
                    // Body Column (x: 129, y: 294, width: 734)
                    VStack(alignment: .leading, spacing: 21) {
                        ForEach(0..<chapter.storyParagraphs.count, id: \.self) { index in
                            let opacityIndex = index + 1
                            Text(chapter.storyParagraphs[index])
                                .font(.custom("VCR OSD Mono", size: 24))
                                .foregroundColor(.white)
                                .tracking(24 * -0.06)
                                .lineSpacing(4)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(lineOpacities.indices.contains(opacityIndex) ? lineOpacities[opacityIndex] : 0.0)
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
                            .foregroundColor(Color(white: 0.6))
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
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleTap()
            }
        }
        .background(Color.black)
        .onAppear {
            startTextAnimation()
        }
    }
    
    private func startTextAnimation() {
        let lineCount = chapter.storyParagraphs.count + 1
        lineOpacities = Array(repeating: 0.0, count: lineCount)
        showContinue = false
        blinkContinue = false
        
        // Wait 0.8s for the screen fade-in transition to fully complete, then fade in the header slowly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard director.currentState == .story(chapter) else { return }
            withAnimation(.easeIn(duration: 2.0)) {
                if lineOpacities.indices.contains(0) {
                    lineOpacities[0] = 1.0
                }
            }
        }
        
        for i in 0..<chapter.storyParagraphs.count {
            let delay = 0.8 + 2.0 + Double(i) * 2.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard director.currentState == .story(chapter) else { return }
                
                withAnimation(.easeIn(duration: 2.0)) {
                    let opacityIndex = i + 1
                    if lineOpacities.indices.contains(opacityIndex) {
                        lineOpacities[opacityIndex] = 1.0
                    }
                }
            }
        }
        
        let totalDelay = 0.8 + 2.0 + Double(chapter.storyParagraphs.count) * 2.2 + 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            guard director.currentState == .story(chapter) else { return }
            
            withAnimation(.easeIn(duration: 1.0)) {
                showContinue = true
            }
            
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                blinkContinue = true
            }
        }
    }
    
    private func handleTap() {
        let isFullyLoaded = !lineOpacities.contains(where: { $0 < 1.0 })
        if isFullyLoaded {
            // Advance to the game with a very slow cinematic transition (4.0 seconds)
            withAnimation(.easeInOut(duration: 4.0)) {
                director.advanceFromStory(chapter)
            }
        } else {
            // Skip the fade animation, display all text immediately and show prompt
            withAnimation {
                let lineCount = chapter.storyParagraphs.count + 1
                lineOpacities = Array(repeating: 1.0, count: lineCount)
                showContinue = true
            }
            
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                blinkContinue = true
            }
        }
    }
}

#Preview {
    StoryView(chapter: .prolog)
}
