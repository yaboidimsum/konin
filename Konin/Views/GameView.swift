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

    // Tracks whether voiceover has already been played this session
    @State private var krotoszyn1AudioPlayed = false
    @State private var krotoszyn2AudioPlayed = false
    @State private var krotoszyn3AudioPlayed = false
    @State private var kozmin1AudioPlayed = false
    @State private var kozmin2AudioPlayed = false
    @State private var kozmin3AudioPlayed = false
    @State private var jarocin1AudioPlayed = false
    @State private var jarocin2AudioPlayed = false
    @State private var jarocin3AudioPlayed = false
    @State private var tunnel1AudioPlayed = false
    @State private var tunnel2AudioPlayed = false
    @State private var konin1AudioPlayed = false
    @State private var konin2AudioPlayed = false
    @State private var konin3AudioPlayed = false
    @State private var konin4AudioPlayed = false
    @State private var zolkiew1AudioPlayed = false
    @State private var zolkiew2AudioPlayed = false
    @State private var zolkiew3AudioPlayed = false
    @State private var zolkiew4AudioPlayed = false
    @State private var zolkiew5AudioPlayed = false
    @State private var zolkiew6AudioPlayed = false
    @State private var zolkiew7AudioPlayed = false
    @State private var zolkiew8AudioPlayed = false


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
            resetAudioTrackingFlags()
            triggerTitleCard()
        }
    }

    // MARK: - Closed Captions
    //
    // Reads caption ranges from Chapter enum so no logic lives here.
    // Returns the first range that the current distance falls inside.

    private var activeCaptionText: String? {
        let dist = director.distanceTravelled
        let active = chapter.captionRanges.first { dist >= $0.min && dist <= $0.max }

        if let active {
            let ranges = chapter.captionRanges

            // ── Krotoszyn ────────────────────────────────────────────────────
            if chapter == .krotoszyn {
                if let r = ranges.first, active.min == r.min, !krotoszyn1AudioPlayed {
                    DispatchQueue.main.async {
                        krotoszyn1AudioPlayed = true
                        SynthAudioEngine.shared.playKrotoszyn1Announcement()
                    }
                }
                if ranges.count > 1, active.min == ranges[1].min, !krotoszyn2AudioPlayed {
                    DispatchQueue.main.async {
                        krotoszyn2AudioPlayed = true
                        SynthAudioEngine.shared.playKrotoszyn2Announcement()
                    }
                }
                if ranges.count > 2, active.min == ranges[2].min, !krotoszyn3AudioPlayed {
                    DispatchQueue.main.async {
                        krotoszyn3AudioPlayed = true
                        SynthAudioEngine.shared.playKrotoszyn3Announcement()
                    }
                }
            }
            
            // ── Kozmin ───────────────────────────────────────────────────────
            if chapter == .kozmin {
                if let r = ranges.first, active.min == r.min, !kozmin1AudioPlayed {
                    DispatchQueue.main.async {
                        kozmin1AudioPlayed = true
                        SynthAudioEngine.shared.playKozmin1Announcement()
                    }
                }
                if ranges.count > 1, active.min == ranges[1].min, !kozmin2AudioPlayed {
                    DispatchQueue.main.async {
                        kozmin2AudioPlayed = true
                        SynthAudioEngine.shared.playKozmin2Announcement()
                    }
                }
                if ranges.count > 2, active.min == ranges[2].min, !kozmin3AudioPlayed {
                    DispatchQueue.main.async {
                        kozmin3AudioPlayed = true
                        SynthAudioEngine.shared.playKozmin3Announcement()
                    }
                }
            }
            
            // ── Jarocin ──────────────────────────────────────────────────────
            if chapter == .jarocin {
                if let r = ranges.first, active.min == r.min, !jarocin1AudioPlayed {
                    DispatchQueue.main.async {
                        jarocin1AudioPlayed = true
                        SynthAudioEngine.shared.playJarocin1Announcement()
                    }
                }
                if ranges.count > 1, active.min == ranges[1].min, !jarocin2AudioPlayed {
                    DispatchQueue.main.async {
                        jarocin2AudioPlayed = true
                        SynthAudioEngine.shared.playJarocin2Announcement()
                    }
                }
                if ranges.count > 2, active.min == ranges[2].min, !jarocin3AudioPlayed {
                    DispatchQueue.main.async {
                        jarocin3AudioPlayed = true
                        SynthAudioEngine.shared.playJarocin3Announcement()
                    }
                }
            }

            // ── Tunnel ───────────────────────────────────────────────────────
            if chapter == .tunnel {
                if let r = ranges.first, active.min == r.min, !tunnel1AudioPlayed {
                    DispatchQueue.main.async {
                        tunnel1AudioPlayed = true
                        SynthAudioEngine.shared.playTunnel1Announcement()
                    }
                }
                if ranges.count > 1, active.min == ranges[1].min, !tunnel2AudioPlayed {
                    DispatchQueue.main.async {
                        tunnel2AudioPlayed = true
                        SynthAudioEngine.shared.playTunnel2Announcement()
                    }
                }
            }

            // ── Konin ────────────────────────────────────────────────────────
            if chapter == .konin {
                if let r = ranges.first, active.min == r.min, !konin1AudioPlayed {
                    DispatchQueue.main.async {
                        konin1AudioPlayed = true
                        SynthAudioEngine.shared.playKonin1Announcement()
                    }
                }
                if ranges.count > 1, active.min == ranges[1].min, !konin2AudioPlayed {
                    DispatchQueue.main.async {
                        konin2AudioPlayed = true
                        SynthAudioEngine.shared.playKonin2Announcement()
                    }
                }
                if ranges.count > 2, active.min == ranges[2].min, !konin3AudioPlayed {
                    DispatchQueue.main.async {
                        konin3AudioPlayed = true
                        SynthAudioEngine.shared.playKonin3Announcement()
                    }
                }
                if ranges.count > 3, active.min == ranges[3].min, !konin4AudioPlayed {
                    DispatchQueue.main.async {
                        konin4AudioPlayed = true
                        SynthAudioEngine.shared.playKonin4Announcement()
                    }
                }
            }

            // ── Zolkiew ──────────────────────────────────────────────────────
            if chapter == .zolkiew {
                if let r = ranges.first, active.min == r.min, !zolkiew1AudioPlayed {
                    DispatchQueue.main.async {
                        zolkiew1AudioPlayed = true
                        SynthAudioEngine.shared.playZolkiew1Announcement()
                    }
                }
                if ranges.count > 1, active.min == ranges[1].min, !zolkiew2AudioPlayed {
                    DispatchQueue.main.async {
                        zolkiew2AudioPlayed = true
                        SynthAudioEngine.shared.playZolkiew2Announcement()
                    }
                }
                if ranges.count > 2, active.min == ranges[2].min, !zolkiew3AudioPlayed {
                    DispatchQueue.main.async {
                        zolkiew3AudioPlayed = true
                        SynthAudioEngine.shared.playZolkiew3Announcement()
                    }
                }
                if ranges.count > 3, active.min == ranges[3].min, !zolkiew4AudioPlayed {
                    DispatchQueue.main.async {
                        zolkiew4AudioPlayed = true
                        SynthAudioEngine.shared.playZolkiew4Announcement()
                    }
                }
                if ranges.count > 4, active.min == ranges[4].min, !zolkiew5AudioPlayed {
                    DispatchQueue.main.async {
                        zolkiew5AudioPlayed = true
                        SynthAudioEngine.shared.playZolkiew5Announcement()
                    }
                }
                if ranges.count > 5, active.min == ranges[5].min, !zolkiew6AudioPlayed {
                    DispatchQueue.main.async {
                        zolkiew6AudioPlayed = true
                        SynthAudioEngine.shared.playZolkiew6Announcement()
                    }
                }
                if ranges.count > 6, active.min == ranges[6].min, !zolkiew7AudioPlayed {
                    DispatchQueue.main.async {
                        zolkiew7AudioPlayed = true
                        SynthAudioEngine.shared.playZolkiew7Announcement()
                    }
                }
                if ranges.count > 7, active.min == ranges[7].min, !zolkiew8AudioPlayed {
                    DispatchQueue.main.async {
                        zolkiew8AudioPlayed = true
                        SynthAudioEngine.shared.playZolkiew8Announcement()
                    }
                }
            }
        }

        return active?.text
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
    
    // MARK: - Helpers
    
    private func resetAudioTrackingFlags() {
        krotoszyn1AudioPlayed = false
        krotoszyn2AudioPlayed = false
        krotoszyn3AudioPlayed = false
        kozmin1AudioPlayed = false
        kozmin2AudioPlayed = false
        kozmin3AudioPlayed = false
        jarocin1AudioPlayed = false
        jarocin2AudioPlayed = false
        jarocin3AudioPlayed = false
        tunnel1AudioPlayed = false
        tunnel2AudioPlayed = false
        konin1AudioPlayed = false
        konin2AudioPlayed = false
        konin3AudioPlayed = false
        konin4AudioPlayed = false
        zolkiew1AudioPlayed = false
        zolkiew2AudioPlayed = false
        zolkiew3AudioPlayed = false
        zolkiew4AudioPlayed = false
        zolkiew5AudioPlayed = false
        zolkiew6AudioPlayed = false
        zolkiew7AudioPlayed = false
        zolkiew8AudioPlayed = false
    }
}

#Preview {
    GameView(chapter: .krotoszyn)
}
