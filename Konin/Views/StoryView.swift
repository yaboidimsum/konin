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

    // Used to cancel scheduled DispatchQueue blocks when view disappears or chapter changes.
    @State private var animationToken: UUID = UUID()

    init(chapter: Chapter) {
        self.chapter = chapter
        let lineCount = chapter.storyParagraphs.count + 1 // +1 for the header
        self._lineOpacities = State(initialValue: Array(repeating: 0.0, count: lineCount))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { windowGeo in
            let targetSize = CGSize(width: 1024, height: 768)
            let scale = min(windowGeo.size.width / targetSize.width,
                            windowGeo.size.height / targetSize.height)

            ZStack {
                // 1. BLACK BACKGROUND
                Color.black
                    .frame(width: targetSize.width, height: targetSize.height)

                // 2. RADIAL GRADIENT OVERLAY — subtle warm vignette
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.17, blue: 0.17, opacity: 0.0),
                        Color(red: 0.0, green: 0.04, blue: 0.03, opacity: 1.0)
                    ]),
                    center: UnitPoint(x: 0.46, y: 0.50),
                    startRadius: 0,
                    endRadius: 550
                )
                .frame(width: targetSize.width, height: targetSize.height)

                // 3. STORY LAYOUT
                ZStack {
                    // Header / Date line  (x: 129, y: 197)
                    Text(chapter.storyHeader)
                        .font(.custom("VCR OSD Mono", size: 24))
                        .foregroundColor(.white)
                        .tracking(24 * -0.06)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .opacity(lineOpacities.indices.contains(0) ? lineOpacities[0] : 0.0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 129)
                        .padding(.top, 197)

                    // Body paragraphs  (x: 129, y: 294, width: 734)
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
                                .opacity(lineOpacities.indices.contains(opacityIndex)
                                         ? lineOpacities[opacityIndex] : 0.0)
                        }
                    }
                    .frame(width: 734, alignment: .leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 129)
                    .padding(.top, 294)

                    // "Click to continue" prompt — blinks after all lines are visible
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
            .onTapGesture { handleTap() }
        }
        .background(Color.black)
        .onAppear {
            startTextAnimation()
        }
        // FIX: reset + restart animation if the same view is reused for a different chapter
        .onChange(of: chapter) { _ in
            animationToken = UUID()
            startTextAnimation()
        }
    }

    // MARK: - Animation

    private func startTextAnimation() {
        let lineCount = chapter.storyParagraphs.count + 1
        lineOpacities = Array(repeating: 0.0, count: lineCount)
        showContinue = false
        blinkContinue = false

        // Capture token so stale closures from a previous run are no-ops
        let token = animationToken

        // Header fades in first (wait for parent screen transition to finish)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard self.animationToken == token,
                  self.director.currentState == .story(self.chapter) else { return }
            withAnimation(.easeIn(duration: 2.0)) {
                if self.lineOpacities.indices.contains(0) {
                    self.lineOpacities[0] = 1.0
                }
            }
        }

        // Body paragraphs fade in sequentially
        for i in 0..<chapter.storyParagraphs.count {
            let delay = 0.8 + 2.0 + Double(i) * 2.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard self.animationToken == token,
                      self.director.currentState == .story(self.chapter) else { return }
                withAnimation(.easeIn(duration: 2.0)) {
                    let idx = i + 1
                    if self.lineOpacities.indices.contains(idx) {
                        self.lineOpacities[idx] = 1.0
                    }
                }
            }
        }

        // Show "click to continue" after all lines have appeared
        let totalDelay = 0.8 + 2.0 + Double(chapter.storyParagraphs.count) * 2.2 + 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            guard self.animationToken == token,
                  self.director.currentState == .story(self.chapter) else { return }
            withAnimation(.easeIn(duration: 1.0)) {
                self.showContinue = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                self.blinkContinue = true
            }
        }
    }

    // MARK: - Input

    private func handleTap() {
        let isFullyLoaded = lineOpacities.allSatisfy { $0 >= 1.0 }

        if isFullyLoaded {
            // Advance with a slow cinematic fade (4 seconds to feel weighty)
            withAnimation(.easeInOut(duration: 4.0)) {
                director.advanceFromStory(chapter)
            }
        } else {
            // Skip animation — reveal everything immediately
            // Invalidate pending async blocks so they don't fight the instant reveal
            animationToken = UUID()
            withAnimation {
                lineOpacities = Array(repeating: 1.0, count: chapter.storyParagraphs.count + 1)
                showContinue = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                blinkContinue = true
            }
        }
    }
}

#Preview {
    StoryView(chapter: .krotoszyn)
}
