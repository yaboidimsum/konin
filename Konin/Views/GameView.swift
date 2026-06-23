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
                        .font(.system(size: 15, weight: .semibold, design: .serif))
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
        }
        .onAppear {
            // Scene automatically configures on didMove(to:)
        }
        .onDisappear {
            scene.cleanUp()
        }
    }
    
    // Closed captions logic keyed to level progress and chapter
    private var activeCaptionText: String? {
        let dist = director.distanceTravelled
        switch chapter {
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
}
