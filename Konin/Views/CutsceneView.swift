//
//  CutsceneView.swift
//  Konin
//
//  Placeholder cutscene viewer — displays a sequence of scene cards
//  (image + caption) with tap-to-advance. Replace placeholder assets
//  with real pixel art once available.
//
//  To add a cutscene for another chapter, add its scenes to
//  `CutsceneScene.scenes(for:)` below.
//

import SwiftUI

// MARK: - Data

struct CutsceneScene: Identifiable {
    let id: Int
    let imageName: String   // Asset catalog name — swap in real art here
    let caption: String     // Displayed at the bottom of the scene card

    /// All scenes for a given chapter's cutscene.
    /// Currently only .prolog is defined.
    static func scenes(for chapter: Chapter) -> [CutsceneScene] {
        switch chapter {
        case .prolog:
            return [
                CutsceneScene(
                    id: 0,
                    imageName: "cutscene_prolog_01",   // desk radio, fighter silhouettes outside
                    caption: "September 1st, 1939. A desk radio fills the crew room with news of the German advance.\nOutside, fighter silhouettes darken the western sky."
                ),
                CutsceneScene(
                    id: 1,
                    imageName: "cutscene_prolog_02",   // station master bursts in, sirens
                    caption: "The Station Master bursts through the door, breathless.\nIn the distance, air-raid sirens begin to wail."
                ),
                CutsceneScene(
                    id: 2,
                    imageName: "cutscene_prolog_03",   // SM shouting, chaos
                    caption: "\"Evacuate NOW! Load everyone you can!\nWe must leave before the lines are cut!\""
                ),
                CutsceneScene(
                    id: 3,
                    imageName: "cutscene_prolog_04",   // John running to locomotive, steam, chaos
                    caption: "John sprints to the locomotive. The engine roars to life.\nTerrified passengers scramble to board the carriages."
                ),
                CutsceneScene(
                    id: 4,
                    imageName: "cutscene_prolog_05",   // brakeman signal, John nods, throttle
                    caption: "\"All ready, sir! Keep this train and everyone inside safe!\"\nJohn nods. He pulls the throttle."
                ),
                CutsceneScene(
                    id: 5,
                    imageName: "cutscene_prolog_06",   // train leaving, station explodes behind
                    caption: "The train accelerates out of the station.\nBehind them, a massive explosion obliterates everything they knew."
                )
            ]
        default:
            return []
        }
    }
}

// MARK: - View

struct CutsceneView: View {
    let chapter: Chapter
    let director = GameDirector.shared

    private let scenes: [CutsceneScene]

    @State private var currentIndex: Int = 0
    @State private var sceneOpacity: Double = 0.0
    @State private var captionOpacity: Double = 0.0
    @State private var showSkip: Bool = false

    init(chapter: Chapter) {
        self.chapter = chapter
        self.scenes = CutsceneScene.scenes(for: chapter)
    }

    // MARK: Body

    var body: some View {
        GeometryReader { geo in
            let targetSize = CGSize(width: 1024, height: 768)
            let scale = min(geo.size.width / targetSize.width,
                            geo.size.height / targetSize.height)

            ZStack {
                Color.black.ignoresSafeArea()

                if scenes.isEmpty {
                    // Safety fallback — should never happen in shipping build
                    VStack(spacing: 16) {
                        Text("[ No cutscene defined for \(chapter.title) ]")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                        continueButton
                    }
                } else {
                    ZStack {
                        sceneCard(scenes[currentIndex])
                            .opacity(sceneOpacity)

                        // Skip button — top right
                        if showSkip {
                            Button(action: skipAll) {
                                Text("SKIP  ▶▶")
                                    .font(.custom("VCR OSD Mono", size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(.top, 20)
                            .padding(.trailing, 24)
                            .transition(.opacity)
                        }

                        // Scene counter — bottom left
                        Text("\(currentIndex + 1) / \(scenes.count)")
                            .font(.custom("VCR OSD Mono", size: 12))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .padding(.leading, 24)
                            .padding(.bottom, 20)
                    }
                    .frame(width: targetSize.width, height: targetSize.height)
                    .scaleEffect(scale)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .contentShape(Rectangle())
                    .onTapGesture { advanceScene() }
                }
            }
        }
        .onAppear { fadeInCurrentScene() }
    }

    // MARK: Scene Card

    @ViewBuilder
    private func sceneCard(_ scene: CutsceneScene) -> some View {
        VStack(spacing: 0) {
            // Image area — shows placeholder if asset not found
            ZStack {
                Rectangle()
                    .fill(Color(white: 0.08))

                if NSImage(named: scene.imageName) != nil {
                    Image(scene.imageName)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    // Placeholder until real art is added
                    VStack(spacing: 12) {
                        Image(systemName: "film")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.15))
                        Text("[ \(scene.imageName) ]")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }

                // Vignette
                RadialGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.55)]),
                    center: .center,
                    startRadius: 200,
                    endRadius: 520
                )
            }
            .frame(height: 540)

            // Caption bar
            ZStack {
                Color.black

                Text(scene.caption)
                    .font(.custom("VCR OSD Mono", size: 18))
                    .tracking(18 * -0.04)
                    .foregroundColor(Color(red: 1.0, green: 0.92, blue: 0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 80)
                    .opacity(captionOpacity)
            }
            .frame(height: 228)
        }
        .frame(width: 1024, height: 768)
    }

    // MARK: Continue Button (empty scenes fallback)

    private var continueButton: some View {
        Button(action: finishCutscene) {
            Text("Continue")
                .font(.custom("VCR OSD Mono", size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.4)))
        }
        .buttonStyle(.plain)
    }

    // MARK: Logic

    private func fadeInCurrentScene() {
        sceneOpacity  = 0.0
        captionOpacity = 0.0

        withAnimation(.easeIn(duration: 0.8)) {
            sceneOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeIn(duration: 1.2)) {
                captionOpacity = 1.0
            }
        }
        // Show skip button after first scene is visible
        if !showSkip {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showSkip = true }
            }
        }
    }

    private func advanceScene() {
        let nextIndex = currentIndex + 1
        guard nextIndex < scenes.count else {
            finishCutscene()
            return
        }
        // Fade out → update index → fade in
        withAnimation(.easeOut(duration: 0.4)) {
            sceneOpacity   = 0.0
            captionOpacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            currentIndex = nextIndex
            fadeInCurrentScene()
        }
    }

    private func skipAll() {
        finishCutscene()
    }

    private func finishCutscene() {
        withAnimation(.easeInOut(duration: 1.5)) {
            director.advanceFromCutscene(chapter)
        }
    }
}

#Preview {
    CutsceneView(chapter: .prolog)
}
