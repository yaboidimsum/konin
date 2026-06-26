//
//  GameView.swift
//  Konin
//

import SwiftUI
import SpriteKit

struct GameView: View {
    let chapter: Chapter
    let director = GameDirector.shared
    
    // Store scene once in State as per SpriteKit best practice
    @State private var scene: GameScene
    
    @State private var showTitleCard = true
    @State private var titleCardOpacity = 1.0
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
    
    var body: some View {
        ZStack {
            // Render SpriteKit scene
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
            
            // HUD Overlay for Coal, Distance, and Closed Captions
            VStack {
                HStack {
                    // Left HUD: Active Chapter
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
                    
                    // Right HUD: Distance progress
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "DISTANCE: %.0f / %.0f m", director.distanceTravelled, chapter.targetDistance))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        ProgressView(value: min(director.distanceTravelled, chapter.targetDistance), total: chapter.targetDistance)
                            .progressViewStyle(.linear)
                            .frame(width: 150)
                            .tint(chapter == .konin ? .teal : .red)
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                }
                .padding()
                
                Spacer()
                
                // Closed Caption dialogue box (yellow retro style)
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
            .padding(.bottom, 220) // Positioned directly above the dashboard HUD
            .allowsHitTesting(false) // Let mouse clicks go to SpriteKit scene
            
            // TITLE CARD OVERLAY
            if showTitleCard {
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
                                Color(red: 0.2, green: 0.17, blue: 0.17, opacity: 0.0),
                                Color(red: 0.0, green: 0.04, blue: 0.03, opacity: 1.0)
                            ]),
                            center: UnitPoint(x: 0.46, y: 0.50),
                            startRadius: 0,
                            endRadius: 550
                        )
                        .frame(width: targetSize.width, height: targetSize.height)
                        
                        // 3. TITLE TEXT (x: 129, y: 197)
                        Text(chapter.actTitle)
                            .font(.custom("VCR OSD Mono", size: 24))
                            .foregroundColor(.white)
                            .tracking(24 * -0.06) // letterSpacing: -0.06em
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
                    .onTapGesture {
                        handleTitleCardTap()
                    }
                }
                .background(Color.black)
                .opacity(titleCardOpacity)
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .onAppear {
            triggerTitleCard()
        }
        .onDisappear {
            scene.cleanUp()
        }
        .onChange(of: chapter) { newChapter in
            scene.start(chapter: newChapter)
            triggerTitleCard()
        }
    }
    
    // Closed captions logic keyed to level progress and chapter
    private var activeCaptionText: String? {
        let dist = director.distanceTravelled
        switch chapter {
        case .prolog:
            break
        case .krotoszyn:
            if dist >= 20.0 && dist <= 110.0 {
                return "John: \"The furnace is hungry. Keep stoking coal (Space) to maintain speed.\""
            } else if dist >= 180.0 && dist <= 270.0 {
                return "John: \"Krotoszyn is fading behind us. We are heading east into the unknown.\""
            }
        case .kozmin:
            if dist >= 40.0 && dist <= 130.0 {
                return "John: \"Three rails ahead! Use A/D to switch lanes, W to snap back to center.\""
            } else if dist >= 260.0 && dist <= 350.0 {
                return "John: \"The tracks are worse here... left, center, right — choose wisely.\""
            }
        case .jarocin:
            if dist >= 50.0 && dist <= 140.0 {
                return "John: \"Luftwaffe in the skies! Take cover (S or Down Arrow) when the warnings wail!\""
            } else if dist >= 320.0 && dist <= 410.0 {
                return "John: \"Bombs are falling close! The passenger cars must survive!\""
            }
        case .tunnel:
            if dist >= 40.0 && dist <= 140.0 {
                return "John: \"It's pitch black. All light is gone. Only the engine's roar remains.\""
            } else if dist >= 220.0 && dist <= 320.0 {
                return "John: \"Almost out of the tunnel... but I hear sirens wailing ahead...\""
            }
        case .konin:
            if dist >= 60.0 && dist <= 160.0 {
                return "John: \"The air... it's so quiet. No sirens. No bombs. The world is at peace.\""
            } else if dist >= 360.0 && dist <= 460.0 {
                return "John: \"Three rails becoming one... the center track leads directly into the light.\""
            }
        case .zolkiew:
            // dist is updated to 0.02 when train halts completely
            if dist > 0.015 {
                return "John: \"The passengers are departing into the silence. May they find peace.\""
            } else {
                return "John: \"We have stopped at the final station. The engine is quiet.\""
            }
        }
        return nil
    }
    
    private func triggerTitleCard() {
        let currentId = titleCardWorkId + 1
        titleCardWorkId = currentId
        
        showTitleCard = true
        titleCardOpacity = 1.0
        titleTextOpacity = 0.0
        
        scene.isWaitingToStart = true
        
        // 1. Fade in the text slowly (start after 0.8s, duration 2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard self.titleCardWorkId == currentId else { return }
            withAnimation(.easeIn(duration: 2.0)) {
                titleTextOpacity = 1.0
            }
        }
        
        // 2. Automatically start fading out to gameplay after 4.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            guard self.titleCardWorkId == currentId else { return }
            startDismissTransition(currentId: currentId)
        }
    }
    
    private func handleTitleCardTap() {
        // Tap allows skipping the remaining delay, triggering immediate dismiss transition
        startDismissTransition(currentId: titleCardWorkId)
    }
    
    private func startDismissTransition(currentId: Int) {
        guard self.titleCardWorkId == currentId else { return }
        self.titleCardWorkId += 1 // Invalidate any other scheduled triggers
        
        // Resume the SpriteKit game update loop!
        scene.isWaitingToStart = false
        
        withAnimation(.easeInOut(duration: 3.0)) {
            titleCardOpacity = 0.0
            titleTextOpacity = 0.0
        }
        
        // After 3.0s (when fade is finished), hide it from the hierarchy
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showTitleCard = false
        }
    }
}

#Preview {
    GameView(chapter: .krotoszyn)}
