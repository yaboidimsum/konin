//
//  GameView.swift
//  Konin
//

import SwiftUI
import SpriteKit

struct GameView: View {
    let chapter: Chapter
    let director = GameDirector.shared

    // Store scene once in @State as per SpriteKit best practice
    @State private var scene: GameScene

    @State private var showTitleCard = false
    @State private var titleCardOpacity = 0.0
    @State private var titleTextOpacity = 0.0
    @State private var titleCardWorkId = 0

    init(chapter: Chapter) {
        self.chapter = chapter

        let s = GameScene()
        s.activeChapter = chapter
        s.size = CGSize(width: 1024, height: 768)
        s.scaleMode = .aspectFill
        _scene = State(initialValue: s)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // ── SpriteKit Scene ──────────────────────────────────────────────
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            // ── HUD Overlay ──────────────────────────────────────────────────
            VStack {
                HStack {
                    // Left HUD: chapter title
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chapter.title.uppercased())
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("Destination: Żółkiew")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)

                    Spacer()

                    // Right HUD: distance progress
                    // Hide distance bar for chapters that have no target distance
                    if chapter.targetDistance > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(format: "DISTANCE: %.0f / %.0f m",
                                        director.distanceTravelled,
                                        chapter.targetDistance))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)

                            ProgressView(
                                value: min(director.distanceTravelled, chapter.targetDistance),
                                total: chapter.targetDistance
                            )
                            .progressViewStyle(.linear)
                            .frame(width: 150)
                            // Ghost segment chapters use a calm teal tint
                            .tint(chapter.isGhostSegment ? .teal : .red)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                    }
                }
                .padding()

                Spacer()

                // ── Closed Caption Box ───────────────────────────────────────
                if let caption = activeCaptionText {
                    Text(caption)
                        .font(.custom("VCR OSD Mono", size: 16))
                        .tracking(16 * -0.04)
                        .foregroundColor(Color(red: 1.0, green: 0.92, blue: 0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 40)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(.bottom, 220) // Sit above the dashboard HUD
            .allowsHitTesting(false) // Pass clicks through to SpriteKit

            // ── Title Card Overlay ───────────────────────────────────────────
            if showTitleCard {
                GeometryReader { windowGeo in
                    let targetSize = CGSize(width: 1024, height: 768)
                    let scale = min(windowGeo.size.width / targetSize.width,
                                    windowGeo.size.height / targetSize.height)

                    ZStack {
                        Color.black
                            .frame(width: targetSize.width, height: targetSize.height)

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

                        Text(chapter.actTitle)
                            .font(.custom("VCR OSD Mono", size: 24))
                            .foregroundColor(.white)
                            .tracking(24 * -0.06)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .opacity(titleTextOpacity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.leading, 129)
                            .padding(.top, 197)
                    }
                    .frame(width: targetSize.width, height: targetSize.height)
                    .scaleEffect(scale)
                    .position(x: windowGeo.size.width / 2, y: windowGeo.size.height / 2)
                    .contentShape(Rectangle())
                    .onTapGesture { handleTitleCardTap() }
                }
                .background(Color.black)
                .opacity(titleCardOpacity)
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .onAppear    { triggerTitleCard() }
        .onDisappear { scene.cleanUp() }
        .onChange(of: chapter) { newChapter in
            scene.start(chapter: newChapter)
            triggerTitleCard()
        }
    }

    // MARK: - Closed Captions
    //
    // Reads caption ranges from Chapter enum so no logic lives here.
    // Returns the first range that the current distance falls inside.

    private var activeCaptionText: String? {
        let dist = director.distanceTravelled
        return chapter.captionRanges.first { dist >= $0.min && dist <= $0.max }?.text
    }

    // MARK: - Title Card

    private func triggerTitleCard() {
        let currentId = titleCardWorkId + 1
        titleCardWorkId = currentId

        showTitleCard    = true
        titleCardOpacity = 1.0
        titleTextOpacity = 0.0

        scene.isWaitingToStart = true

        // Fade in title text after 0.8 s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard self.titleCardWorkId == currentId else { return }
            withAnimation(.easeIn(duration: 2.0)) { titleTextOpacity = 1.0 }
        }

        // Auto-dismiss after 4.5 s
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            guard self.titleCardWorkId == currentId else { return }
            startDismissTransition(currentId: currentId)
        }
    }

    private func handleTitleCardTap() {
        startDismissTransition(currentId: titleCardWorkId)
    }

    private func startDismissTransition(currentId: Int) {
        guard titleCardWorkId == currentId else { return }
        titleCardWorkId += 1 // Invalidate any other pending closures

        scene.isWaitingToStart = false

        withAnimation(.easeInOut(duration: 3.0)) {
            titleCardOpacity = 0.0
            titleTextOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showTitleCard = false
        }
    }
}

#Preview {
    GameView(chapter: .krotoszyn)
}
