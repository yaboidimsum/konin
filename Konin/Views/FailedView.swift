//
//  FailedView.swift
//  Konin
//

import SwiftUI

struct FailedView: View {
    let chapter: Chapter
    let director = GameDirector.shared
    
    @State private var isRetryHovered = false
    @State private var isMenuHovered = false
    
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
                        Color(red: 0.2, green: 0.17, blue: 0.17, opacity: 0.0),
                        Color(red: 0.0, green: 0.04, blue: 0.03, opacity: 1.0)
                    ]),
                    center: UnitPoint(x: 0.46, y: 0.50),
                    startRadius: 0,
                    endRadius: 550
                )
                .frame(width: targetSize.width, height: targetSize.height)
                
                // 3. FAILED SCREEN CONTENT LAYOUT
                ZStack {
                    // Header/Date (x: 129, y: 197)
                    Text("THE ENGINE STALLED")
                        .font(.custom("VCR OSD Mono", size: 24))
                        .foregroundColor(.red)
                        .tracking(24 * -0.06)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 129)
                        .padding(.top, 197)
                    
                    // Body Column (x: 129, y: 294, width: 734)
                    VStack(alignment: .leading, spacing: 21) {
                        Text("The coal reserves depleted. The furnace door went cold.")
                            .font(.custom("VCR OSD Mono", size: 24))
                            .foregroundColor(.white)
                            .tracking(24 * -0.06)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Without fuel, the evacuation train ground to a silent halt on the tracks, stranded in the path of the advancing frontline.")
                            .font(.custom("VCR OSD Mono", size: 24))
                            .foregroundColor(Color(white: 0.7))
                            .tracking(24 * -0.06)
                            .lineSpacing(4)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(width: 734, alignment: .leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 129)
                    .padding(.top, 294)
                    
                    // Button Row/Column at the bottom (x: 129, y: 510, width: 300)
                    VStack(spacing: 20) {
                        // Retry Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                director.retryChapter(chapter)
                            }
                        }) {
                            Text("Retry Chapter")
                                .font(.custom("VCR OSD Mono", size: 24))
                                .tracking(24 * -0.06)
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .frame(width: 300)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 120/255, green: 40/255, blue: 40/255),
                                            Color(red: 40/255, green: 15/255, blue: 15/255)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    Rectangle()
                                        .stroke(isRetryHovered ? Color.white : Color(red: 50/255, green: 20/255, blue: 20/255), lineWidth: 4)
                                )
                        }
                        .buttonStyle(.plain)
                        .onHover { h in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isRetryHovered = h
                            }
                        }
                        
                        // Return to Menu Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                director.changeState(to: .menu)
                            }
                        }) {
                            Text("Return to Menu")
                                .font(.custom("VCR OSD Mono", size: 24))
                                .tracking(24 * -0.06)
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .frame(width: 300)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 80/255, green: 80/255, blue: 80/255),
                                            Color(red: 25/255, green: 25/255, blue: 25/255)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    Rectangle()
                                        .stroke(isMenuHovered ? Color.white : Color(red: 40/255, green: 40/255, blue: 40/255), lineWidth: 4)
                                )
                        }
                        .buttonStyle(.plain)
                        .onHover { h in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isMenuHovered = h
                            }
                        }
                    }
                    .frame(width: 734)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 129)
                    .padding(.top, 510)
                }
                .frame(width: targetSize.width, height: targetSize.height)
                .scaleEffect(scale)
                .position(x: windowGeo.size.width / 2, y: windowGeo.size.height / 2)
            }
        }
        .background(Color.black)
    }
}

#Preview {
    FailedView(chapter: .krotoszyn)
}
