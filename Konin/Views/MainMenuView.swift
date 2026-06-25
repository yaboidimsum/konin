//
//  MainMenuView.swift
//  Konin
//

import SwiftUI

struct MainMenuView: View {
    let director = GameDirector.shared
    
    @State private var isPlayHovered = false
    @State private var isSelectHovered = false
    @State private var isQuitHovered = false
    @State private var hoveredChapter: Chapter? = nil
    @State private var isBackHovered = false
    
    @State private var currentMenu: MenuState = .main
    
    private enum MenuState {
        case main
        case chapterSelect
    }
    
    // Cached once at view initialization
    private let backgroundImage: Image
    
    init() {
        if let url = Bundle.main.url(forResource: "background-1", withExtension: "png"),
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
                    // TITLE TEXT (All Points South)
                    Text("All Points South")
                        .font(.custom("VCR OSD Mono", size: 96))
                        .foregroundColor(.white)
                        .frame(width: 900, height: 94, alignment: .leading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 62)
                        .padding(.top, 181)
                    
                    // MENU PANEL (Main / Chapter Select)
                    VStack(spacing: 16) {
                        if currentMenu == .main {
                            // Play Game Button
                            Button(action: {
                                withAnimation {
                                    director.startGame()
                                }
                            }) {
                                Text("Play Game")
                                    .font(.custom("VCR OSD Mono", size: 24))
                                    .tracking(24 * -0.06) // letterSpacing: -0.06em
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 98/255, green: 109/255, blue: 95/255),
                                                Color(red: 35/255, green: 39/255, blue: 34/255)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        Rectangle()
                                            .stroke(isPlayHovered ? Color.white : Color(red: 40/255, green: 45/255, blue: 39/255), lineWidth: 4)
                                    )
                            }
                            .buttonStyle(.plain)
                            .onHover { h in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isPlayHovered = h
                                }
                            }
                            
                            // Select Chapter Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    currentMenu = .chapterSelect
                                }
                            }) {
                                Text("Select Chapter")
                                    .font(.custom("VCR OSD Mono", size: 24))
                                    .tracking(24 * -0.06)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 98/255, green: 109/255, blue: 95/255),
                                                Color(red: 35/255, green: 39/255, blue: 34/255)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        Rectangle()
                                            .stroke(isSelectHovered ? Color.white : Color(red: 40/255, green: 45/255, blue: 39/255), lineWidth: 4)
                                    )
                            }
                            .buttonStyle(.plain)
                            .onHover { h in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isSelectHovered = h
                                }
                            }
                            
                            // Quit Button
                            Button(action: {
                                #if os(macOS)
                                NSApplication.shared.terminate(nil)
                                #endif
                            }) {
                                Text("Quit")
                                    .font(.custom("VCR OSD Mono", size: 24))
                                    .tracking(24 * -0.06)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 98/255, green: 109/255, blue: 95/255),
                                                Color(red: 35/255, green: 39/255, blue: 34/255)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        Rectangle()
                                            .stroke(isQuitHovered ? Color.white : Color(red: 40/255, green: 45/255, blue: 39/255), lineWidth: 4)
                                    )
                            }
                            .buttonStyle(.plain)
                            .onHover { h in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isQuitHovered = h
                                }
                            }
                        } else {
                            // Chapter Select list
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 8) {
                                    ForEach(Chapter.allCases, id: \.self) { chapter in
                                        Button(action: {
                                            withAnimation {
                                                director.changeState(to: .story(chapter))
                                            }
                                        }) {
                                            Text(chapter.title)
                                                .font(.custom("VCR OSD Mono", size: 14))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 12)
                                                .frame(maxWidth: .infinity)
                                                .background(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color(red: 98/255, green: 109/255, blue: 95/255),
                                                            Color(red: 35/255, green: 39/255, blue: 34/255)
                                                        ]),
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .overlay(
                                                    Rectangle()
                                                        .stroke(hoveredChapter == chapter ? Color.white : Color(red: 40/255, green: 45/255, blue: 39/255), lineWidth: 2)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .onHover { h in
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                hoveredChapter = h ? chapter : nil
                                            }
                                        }
                                    }
                                    
                                    Spacer().frame(height: 6)
                                    
                                    // Back Button
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            currentMenu = .main
                                        }
                                    }) {
                                        Text("<< Back")
                                            .font(.custom("VCR OSD Mono", size: 16))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 120/255, green: 80/255, blue: 80/255),
                                                        Color(red: 50/255, green: 30/255, blue: 30/255)
                                                    ]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .overlay(
                                                Rectangle()
                                                    .stroke(isBackHovered ? Color.white : Color(red: 60/255, green: 35/255, blue: 35/255), lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .onHover { h in
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            isBackHovered = h
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 330)
                        }
                    }
                    .padding(16)
                    .frame(width: 280)
                    .background(Color.black.opacity(0.45))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 372) // Adjusted leading padding to keep centered (1024 - 280)/2 = 372
                    .padding(.top, 319)    // Adjusted top padding slightly
                    
                    // OSD INSTRUCTIONS BAR (bottom center)
                    Text("OSD INSTRUCTIONS: WASD/ARROWS - MOVE/DUCK | SPACE - COAL | H - HONK")
                        .font(.custom("VCR OSD Mono", size: 12))
                        .foregroundColor(Color(white: 0.6))
                        .frame(width: 1024)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 36)
                }
                .frame(width: targetSize.width, height: targetSize.height)
                .scaleEffect(scale)
                .position(x: windowGeo.size.width / 2, y: windowGeo.size.height / 2)
            }
        }
        .background(Color.black)
    }
}
