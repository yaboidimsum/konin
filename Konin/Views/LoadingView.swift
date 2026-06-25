//
//  LoadingView.swift
//  Konin
//

import SwiftUI

struct LoadingView: View {
    let director = GameDirector.shared
    
    @State private var progress: Double = 0.0
    @State private var blinkText = false
    @State private var isTransitioning = false
    @State private var showSecondContinue = false
    @State private var blinkSecondContinue = false
    @State private var activeCaption: String? = nil
    @State private var isHovered = false
    
    @State private var bgScale: Double = 1.0
    @State private var slideScale: Double = 1.15
    @State private var slideOffset: CGFloat = 2000.0
    @State private var slideOpacity: Double = 0.0
    
    @State private var introTask: Task<Void, Never>? = nil
    
    // Cached once at view initialization
    private let backgroundImage: Image // loading-menu-2
    private let slideInImage: Image?   // loading-menu-image-1
    
    init() {
        if let url = Bundle.main.url(forResource: "loading-menu-2", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            self.backgroundImage = Image(nsImage: nsImage)
        } else {
            self.backgroundImage = Image("background-1") // Fallback
        }
        
        if let url = Bundle.main.url(forResource: "loading-menu-image-1", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            self.slideInImage = Image(nsImage: nsImage)
        } else {
            self.slideInImage = nil
        }
    }
    
    var body: some View {
        GeometryReader { windowGeo in
            ZStack {
                // 1. FULL-SCREEN BACKGROUND IMAGE (scales up subtly)
                backgroundImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: windowGeo.size.width, height: windowGeo.size.height)
                    .scaleEffect(bgScale)
                    .clipped()
                
                // 2. FULL-SCREEN SLIDE-IN IMAGE (slides in full screen, zoom out over 10s)
                if let slideImage = slideInImage {
                    slideImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: windowGeo.size.width, height: windowGeo.size.height)
                        .scaleEffect(slideScale)
                        .clipped()
                        .opacity(slideOpacity)
                        .offset(x: slideOffset)
                }
                
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
                    
                    // Loading Text and Bar Column (fades out when transitioning)
                    VStack(spacing: 24) {
                        // Progress / Call-to-action text
                        Text(progress < 1.0 ? "\(Int(progress * 100))%" : "Click to continue")
                            .font(.custom("VCR OSD Mono", size: 24))
                            .foregroundColor(.white)
                            .tracking(24 * -0.06) // letterSpacing: -0.06em
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .opacity(blinkText ? 0.2 : 1.0)
                        
                        // Progress Bar Frame
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.black)
                                .frame(height: 37)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 40/255, green: 45/255, blue: 39/255), lineWidth: 4)
                                )
                            
                            // Fill (Same gradient as main menu buttons)
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 98/255, green: 109/255, blue: 95/255),
                                    Color(red: 35/255, green: 39/255, blue: 34/255)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: max(0, CGFloat(progress) * (826 - 8)), height: 37 - 8)
                            .padding(.leading, 4)
                        }
                        .frame(width: 826, height: 37)
                    }
                    .frame(width: 826)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 99)
                    .padding(.top, 654)
                    .opacity(isTransitioning ? 0.0 : 1.0)
                    
                    // Closed Caption dialogue box (yellow retro style)
                    if let caption = activeCaption {
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
                            .frame(width: 826)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 140)
                            .transition(.opacity)
                    }
                    
                    // Second Click to Continue Prompt (blinking, bottom center)
                    if showSecondContinue {
                        Text("Click to continue")
                            .font(.custom("VCR OSD Mono", size: 24))
                            .foregroundColor(.white)
                            .tracking(24 * -0.06)
                            .opacity(blinkSecondContinue ? 0.2 : 1.0)
                            .frame(width: 1024)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 60)
                            .transition(.opacity)
                    }
                    
                    // Skip Button (top right, visible only during introduction cutscene playback)
                    if isTransitioning && !showSecondContinue {
                        Button(action: {
                            // Stop audio monologues
                            SynthAudioEngine.shared.stopIntroSections()
                            activeCaption = nil
                            introTask?.cancel()
                            introTask = nil
                            
                            // Transition to Story chapter 1 view
                            withAnimation(.easeInOut(duration: 0.8)) {
                                director.changeState(to: .story(.krotoszyn))
                            }
                        }) {
                            Text(">> SKIP")
                                .font(.custom("VCR OSD Mono", size: 16))
                                .tracking(16 * -0.04)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
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
                                        .stroke(isHovered ? Color.white : Color(red: 40/255, green: 45/255, blue: 39/255), lineWidth: 2)
                                )
                                .scaleEffect(isHovered ? 1.05 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHovered = hovering
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, 60)
                        .padding(.top, 50)
                    }
                }
                .frame(width: targetSize.width, height: targetSize.height)
                .scaleEffect(scale)
                .position(x: windowGeo.size.width / 2, y: windowGeo.size.height / 2)
            }
            .contentShape(Rectangle()) // Make the whole screen tap-interactive
            .onTapGesture {
                if progress >= 1.0 {
                    if !isTransitioning {
                        isTransitioning = true
                        
                        // Start the introduction background music
                        SynthAudioEngine.shared.startIntroJohn()
                        
                        withAnimation {
                            blinkText = false
                        }
                        
                        // Start monologue animation sequence task
                        introTask = Task {
                            // 1. first background zoom first (duration 15.0s)
                            withAnimation(.easeInOut(duration: 15.0)) {
                                bgScale = 1.15
                            }
                            
                            // Speak first narrative
                            SynthAudioEngine.shared.playIntroSection1()
                            withAnimation(.easeInOut(duration: 0.5)) {
                                activeCaption = "John: \"My name is John Patrekov. I was born in Kraków and have driven these rails for a long time, carrying cargo and supplies. I was looking forward to my retirement, planning to live peacefully as a baker with my family. But it turns out things did not go well, because my country called.\""
                            }
                            
                            // Wait 15.0s for bg zoom to finish
                            do {
                                try await Task.sleep(nanoseconds: 15_000_000_000)
                            } catch {
                                return // Cancelled
                            }
                            
                            // 2. slide in normal not slow
                            slideOffset = windowGeo.size.width
                            slideOpacity = 0.0
                            slideScale = 1.15
                            
                            withAnimation(.easeInOut(duration: 1.0)) {
                                slideOffset = 0.0
                                slideOpacity = 1.0
                            }
                            
                            // Wait 1.0s for slide-in animation to complete (reaches +16.0s)
                            do {
                                try await Task.sleep(nanoseconds: 1_000_000_000)
                            } catch {
                                return // Cancelled
                            }
                            
                            // 3. second photo zoom out over 15.0s
                            withAnimation(.easeInOut(duration: 15.0)) {
                                slideScale = 1.0
                            }
                            
                            // Wait 0.6s to reach +16.6s
                            do {
                                try await Task.sleep(nanoseconds: 600_000_000)
                            } catch {
                                return // Cancelled
                            }
                            
                            // 2b. speak second narrative and update closed captions
                            SynthAudioEngine.shared.playIntroSection2()
                            withAnimation(.easeInOut(duration: 0.5)) {
                                activeCaption = "John: \"Now, I must board the train once again for a dangerous journey, one that could very well end my life. I only hope I will live to see my family again.\""
                            }
                            
                            // Wait 14.4s for the remaining of the 15.0s photo zoom out (reaches +31.0s)
                            do {
                                try await Task.sleep(nanoseconds: 14_400_000_000)
                            } catch {
                                return // Cancelled
                            }
                            
                            // Show second continue prompt
                            withAnimation(.easeInOut(duration: 0.5)) {
                                activeCaption = nil
                            }
                            withAnimation(.easeIn(duration: 0.6)) {
                                showSecondContinue = true
                            }
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                blinkSecondContinue = true
                            }
                        }
                    } else if showSecondContinue {
                        // Clean up speech synthesis
                        SynthAudioEngine.shared.stopIntroSections()
                        activeCaption = nil
                        introTask?.cancel()
                        introTask = nil
                        
                        // Transition to Story chapter 1 view
                        withAnimation(.easeInOut(duration: 0.8)) {
                            director.changeState(to: .story(.krotoszyn))
                        }
                    }
                }
            }
        }
        .background(Color.black)
        .onAppear {
            startLoadingAnimation()
        }
        .onDisappear {
            // Stop speech if we navigate away early
            introTask?.cancel()
            introTask = nil
            SynthAudioEngine.shared.stopIntroSections()
            activeCaption = nil
        }
    }
    
    private func startLoadingAnimation() {
        progress = 0.0
        blinkText = false
        isTransitioning = false
        showSecondContinue = false
        blinkSecondContinue = false
        bgScale = 1.0
        slideScale = 1.15
        slideOffset = 2000.0
        slideOpacity = 0.0
        
        let duration: Double = 3.0 // 3 seconds loading duration
        let fps: Double = 60.0
        let interval = 1.0 / fps
        let totalSteps = Int(duration * fps)
        var step = 0
        
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            step += 1
            let ratio = Double(step) / Double(totalSteps)
            
            // Starts slow, jumps fast: pow(ratio, 3.5)
            let currentProgress = pow(ratio, 3.5)
            progress = min(1.0, currentProgress)
            
            if step >= totalSteps {
                timer.invalidate()
                progress = 1.0
                
                // Trigger the click-to-continue blinking loop
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    blinkText = true
                }
            }
        }
    }
}

