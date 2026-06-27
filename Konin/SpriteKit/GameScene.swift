//
//  GameScene.swift
//  Konin
//

import SpriteKit
import SwiftUI

final class GameScene: SKScene {
    // Controllers & Systems
    var trainController: TrainController!
    var coalSystem: CoalSystem!
    var hazardManager: HazardManager!
    var airRaidController: AirRaidController!
    var cameraController: CameraController!
    
    // Core parameters
    var horizonY: CGFloat = 480.0
    var activeChapter: Chapter = .krotoszyn
    private var lastUpdateTime: TimeInterval = 0.0
    private var isConfigured = false
    var isWaitingToStart = true
    
    // Background nodes
    private var skyNode: SKSpriteNode!
    private var groundNode: SKSpriteNode!
    private var horizonLine: SKSpriteNode!
    private var tunnelDarkness: SKSpriteNode!
    private var headlightBeam: SKSpriteNode!
    private var citySilhouette: SKNode?
    
    // Rails & Sleepers (Ties)
    private var railNodes: [SKSpriteNode] = []
    private var originalRailPositions: [CGFloat] = []
    private var sleeperNodes: [SKSpriteNode] = []
    private var sleeperProgress: [Double] = []
    private let numSleepers = 7 // Fixed pool size per track
    private var sleeperTex: SKTexture?
    
    // Middle Track (2) Rails & Sleepers
    private var middleRailNodes: [SKSpriteNode] = []
    private var originalMiddleRailPositions: [CGFloat] = []
    private var middleSleeperNodes: [SKSpriteNode] = []
    private var middleSleeperProgress: [Double] = []
    
    // Dynamic track transparency states
    var sideTracksAlpha: CGFloat = 1.0
    var middleTrackAlpha: CGFloat = 0.0
    private var whiteTransitionOverlay: SKSpriteNode!
    
    // Fail-state fade overlay (black, fades in before state switch)
    private var failOverlay: SKSpriteNode!
    private var isFadingToFail: Bool = false
    
    // Station approach node (shown at ~80% distance)
    private var stationNode: SKNode!
    private var stationVisible: Bool = false
    
    // Procedural city skylines node
    private var citySkylinesNode: SKNode!
    
    // Cabin UI Nodes (relative to Camera)
    private var dashboardNode: SKSpriteNode!
    private var furnaceDoor: SKSpriteNode!
    private var furnaceFire: SKSpriteNode!
    private var coalMeterLabel: SKLabelNode!
    private var coalMeterFill: SKSpriteNode!

    // Cockpit Instruments
    private var speedNeedle: SKSpriteNode!
    private var pressureNeedle: SKSpriteNode!
    private var pressureGaugeBG: SKSpriteNode!
    private var speedometerBG: SKSpriteNode!
    private var odometerLabel: SKLabelNode!
    private var pressureWarningLight: SKSpriteNode!
    private var speedLabel: SKLabelNode!

    // Dial constants
    private let dialStartAngle: CGFloat = -.pi * 0.75
    private let dialSweep: CGFloat = .pi * 1.5

    // Scrolling Environment
    private var environmentNode: EnvironmentNode?
    
    // Key state trackers (macOS)
    private var activeKeys: Set<UInt16> = []
    private var keyMonitor: Any?
    
    // Horizon Luftwaffe & AA visuals (Jarocin chapter only)
    private var horizonPlaneTimer: TimeInterval = 0.0
    private var horizonAATimer: TimeInterval = 0.0
    private var smokeSpawnTimer: TimeInterval = 0.0
    private var nextAATime: TimeInterval = 1.0
    private var nextPlaneTime: TimeInterval = 4.0
    
    override func didMove(to view: SKView) {
        // Set view properties as per SpriteKit best practice
        view.ignoresSiblingOrder = true
        
        // Background color
        backgroundColor = .black
        
        // Register this scene as the active scene in GameDirector for fail callbacks
        GameDirector.shared.activeScene = self
        
        // Bind controllers
        trainController = TrainController(scene: self)
        coalSystem = CoalSystem(scene: self)
        hazardManager = HazardManager(scene: self)
        airRaidController = AirRaidController(scene: self)
        cameraController = CameraController(scene: self)
        
        // Setup Camera
        cameraController.setup(in: self)
        
        // Build the game graphics
        setupBackground()
        setupTracksAndRails()
        setupCabinOverlay()
        
        isConfigured = true
        
        // Initialize state configuration immediately
        start(chapter: activeChapter)
        
        // Setup keyboard event monitor to capture keys reliably on macOS
        #if os(macOS)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self, self.isConfigured else { return event }
            let handled: Bool
            if event.type == .keyDown {
                handled = self.handleKeyDown(keyCode: event.keyCode, characters: event.charactersIgnoringModifiers)
            } else if event.type == .keyUp {
                handled = self.handleKeyUp(keyCode: event.keyCode)
            } else {
                handled = false
            }
            return handled ? nil : event
        }
        #endif
        
        // Direct focus for keyboard events
        #if os(macOS)
        view.window?.makeFirstResponder(self)
        #endif
    }
    
    func start(chapter: Chapter) {
        activeChapter = chapter
        lastUpdateTime = 0.0
        isWaitingToStart = true
        
        // Reset — startup ramp, begin at center lane
        trainController.resetStartup() 
        trainController.currentLane = 1
        trainController.targetLane = 1
        trainController.visualOffset = 0.0     // center lane = 0 offset
        trainController.leanAngle = 0.0
        trainController.distanceTravelled = 0.0
        trainController.isDucked = false
        trainController.duckVisualOffset = 0.0
        trainController.hasTriggeredEnding = false
        
        hazardManager.cleanUp()
        airRaidController.cleanUp()
        
        // Reset transition variables
        sideTracksAlpha = 1.0
        middleTrackAlpha = 1.0   // center track always visible now
        if whiteTransitionOverlay != nil {
            if chapter == .zolkiew {
                whiteTransitionOverlay.alpha = 1.0
                whiteTransitionOverlay.run(SKAction.fadeOut(withDuration: 3.0))
            } else {
                whiteTransitionOverlay.alpha = 0.0
            }
        }
        
        // Reset fail fade, but fade in from black for gameplay chapters (except zolkiew, which fades in from white)
        isFadingToFail = false
        if failOverlay != nil {
            if chapter == .zolkiew {
                failOverlay.alpha = 0.0
            } else {
                failOverlay.color = .black
                failOverlay.alpha = 1.0
                failOverlay.run(SKAction.fadeOut(withDuration: 1.8))
            }
        }
        
        // Reset station
        stationVisible = false
        stationNode?.alpha = 0.0
        stationNode?.setScale(0.0)
        
        // Style colors based on chapter
        applyChapterStyling(chapter)
        
        // Trigger chapter credits in Chapter 1 (Krotoszyn)
        if chapter == .krotoszyn {
            showChapter1Credits()
        } else {
            enumerateChildNodes(withName: "chapter_credits") { node, _ in
                node.removeFromParent()
            }
        }
    }
    
    func cleanUp() {
        hazardManager.cleanUp()
        airRaidController.cleanUp()
        
        // Deregister from GameDirector
        if GameDirector.shared.activeScene === self {
            GameDirector.shared.activeScene = nil
        }
        
        #if os(macOS)
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        #endif
    }
    
    private func setupBackground() {
        // 1. Sky
        skyNode = SKSpriteNode(color: .blue, size: CGSize(width: size.width * 2, height: size.height - horizonY))
        skyNode.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        skyNode.position = CGPoint(x: size.width / 2, y: horizonY)
        skyNode.zPosition = 0.0
        addChild(skyNode)
        
        // 2. Ground
        groundNode = SKSpriteNode(color: .green, size: CGSize(width: size.width * 2, height: horizonY))
        groundNode.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        groundNode.position = CGPoint(x: size.width / 2, y: 0.0)
        groundNode.zPosition = 0.1
        addChild(groundNode)
        
        // 2.5 Asset-based city silhouette (Chapter 1 only)
        setupCitySilhouette()
        
        // 2.6 Procedural city skylines (all chapters)
        setupCitySkylines()
        
        // 2.7 Station approach node
        setupStation()
        
        // 3. Horizon line
        horizonLine = SKSpriteNode(color: .darkGray, size: CGSize(width: size.width * 2, height: 4))
        horizonLine.position = CGPoint(x: size.width / 2, y: horizonY)
        horizonLine.zPosition = 0.2
        addChild(horizonLine)
        
        // 4. Tunnel Darkness
        tunnelDarkness = SKSpriteNode(color: .black, size: CGSize(width: size.width * 2, height: size.height))
        tunnelDarkness.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tunnelDarkness.zPosition = 4.0
        tunnelDarkness.alpha = 0.0
        addChild(tunnelDarkness)
        
        // 5. Headlight Beam
        let beamSize = CGSize(width: 400, height: horizonY - 180)
        let beam = SKSpriteNode(color: .yellow, size: beamSize)
        beam.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        beam.position = CGPoint(x: size.width / 2, y: 180)
        beam.zPosition = 3.9
        beam.alpha = 0.0
        beam.blendMode = .add
        addChild(beam)
        headlightBeam = beam
        
        // 6. Fail fade overlay (black, starts invisible, sits above everything)
        failOverlay = SKSpriteNode(color: .black, size: CGSize(width: size.width * 2, height: size.height * 2))
        failOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        failOverlay.zPosition = 50.0
        failOverlay.alpha = 0.0
        addChild(failOverlay)

        // Scrolling environment (trees, telegraph poles, parallaxes)
        setupEnvironmentNode()
    }

    
    private func setupCitySilhouette() {
        let node = SKNode()
        node.position = CGPoint(x: size.width / 2, y: horizonY)
        node.zPosition = 0.15
        addChild(node)
        citySilhouette = node
        
        let fullTexture = SKTexture(imageNamed: "Horizon-1")
        fullTexture.filteringMode = .nearest
        let textureSize = fullTexture.size()
        
        // Scale down the base size to avoid covering the whole sky
        let scale: CGFloat = 1.5
        let spriteWidth = textureSize.width * scale
        let spriteHeight = textureSize.height * scale
        
        // Render a single city silhouette in the middle of the view
        let bgSprite = SKSpriteNode(texture: fullTexture, size: CGSize(width: spriteWidth, height: spriteHeight))
        bgSprite.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        bgSprite.position = .zero
        node.addChild(bgSprite)
    }
    
    // MARK: - Procedural City Skylines
    
    /// Draws a procedurally-generated city silhouette sitting on the horizon line.
    /// Two depth layers (far/near) give a subtle parallax feel.
    private func setupCitySkylines() {
        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: horizonY)
        container.zPosition = 0.13  // just below the image silhouette
        addChild(container)
        citySkylinesNode = container
        
        rebuildCitySkylines(for: .krotoszyn) // Default population
    }
    
    private func rebuildCitySkylines(for chapter: Chapter) {
        guard let container = citySkylinesNode else { return }
        container.removeAllChildren()
        
        let isWartime = (chapter == .jarocin)
        
        // Far layer — small, muted buildings
        addSkylineLayer(
            to: container,
            seed: 42,
            count: 28,
            spanWidth: size.width * 1.6,
            minH: 18, maxH: 55,
            minW: 14, maxW: 38,
            color: isWartime ? SKColor(red: 0.14, green: 0.13, blue: 0.12, alpha: 0.75) : SKColor(white: 0.20, alpha: 0.55),
            yOffset: 0,
            zPos: 0.0,
            isWartime: isWartime
        )
        
        // Near layer — taller, slightly brighter, more left-right spread
        addSkylineLayer(
            to: container,
            seed: 99,
            count: 18,
            spanWidth: size.width * 1.4,
            minH: 30, maxH: 80,
            minW: 18, maxW: 52,
            color: isWartime ? SKColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 0.90) : SKColor(white: 0.14, alpha: 0.70),
            yOffset: 0,
            zPos: 0.01,
            isWartime: isWartime
        )
    }
    
    private func addSkylineLayer(
        to parent: SKNode,
        seed: UInt64,
        count: Int,
        spanWidth: CGFloat,
        minH: CGFloat, maxH: CGFloat,
        minW: CGFloat, maxW: CGFloat,
        color: SKColor,
        yOffset: CGFloat,
        zPos: CGFloat,
        isWartime: Bool
    ) {
        // Deterministic pseudo-random using seed
        var rng = SeededRNG(seed: seed)
        
        for i in 0..<count {
            let t = CGFloat(i) / CGFloat(count - 1)  // 0..1 across width
            let x = (t - 0.5) * spanWidth + rng.nextFloat() * 30 - 15
            let h = minH + rng.nextFloat() * (maxH - minH)
            let w = minW + rng.nextFloat() * (maxW - minW)
            
            let building = SKNode()
            building.position = CGPoint(x: x, y: yOffset)
            building.zPosition = zPos
            parent.addChild(building)
            
            if isWartime {
                // Procedural damaged building
                let blockCount = Int(rng.nextFloat() * 2) + 1
                if blockCount == 1 {
                    let mainBlock = SKSpriteNode(color: color, size: CGSize(width: w, height: h))
                    mainBlock.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                    building.addChild(mainBlock)
                    
                    if rng.nextFloat() < 0.40 {
                        let chimney = SKSpriteNode(color: color, size: CGSize(width: 4, height: CGFloat.random(in: 12...22)))
                        chimney.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                        chimney.position = CGPoint(x: (rng.nextFloat() - 0.5) * w * 0.6, y: h)
                        building.addChild(chimney)
                    }
                    
                    if h > 35 && rng.nextFloat() < 0.50 {
                        let holeSize = CGFloat.random(in: 6...12)
                        let skyColor = SKColor(red: 0.28, green: 0.27, blue: 0.25, alpha: 1.0)
                        let hole = SKSpriteNode(color: skyColor, size: CGSize(width: holeSize, height: holeSize))
                        hole.position = CGPoint(x: (rng.nextFloat() - 0.5) * w * 0.5, y: rng.nextFloat() * h * 0.7 + h * 0.15)
                        hole.zPosition = 0.05
                        building.addChild(hole)
                    }
                } else {
                    let w1 = w * CGFloat.random(in: 0.4...0.6)
                    let w2 = w - w1
                    let h1 = h
                    let h2 = h * CGFloat.random(in: 0.3...0.6)
                    
                    let b1 = SKSpriteNode(color: color, size: CGSize(width: w1, height: h1))
                    b1.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                    b1.position = CGPoint(x: -w2/2, y: 0)
                    building.addChild(b1)
                    
                    let b2 = SKSpriteNode(color: color, size: CGSize(width: w2, height: h2))
                    b2.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                    b2.position = CGPoint(x: w1/2, y: 0)
                    building.addChild(b2)
                    
                    if rng.nextFloat() < 0.40 {
                        let chimney = SKSpriteNode(color: color, size: CGSize(width: 4, height: CGFloat.random(in: 12...22)))
                        chimney.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                        chimney.position = CGPoint(x: -w2/2, y: h1)
                        building.addChild(chimney)
                    }
                }
            } else {
                let base = SKSpriteNode(color: color, size: CGSize(width: w, height: h))
                base.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                building.addChild(base)
                
                if h > 35 {
                    let numWindows = Int(rng.nextFloat() * 4) + 1
                    for _ in 0..<numWindows {
                        let wx = (rng.nextFloat() - 0.5) * w * 0.6
                        let wy = rng.nextFloat() * h * 0.6 + h * 0.1
                        let dot = SKSpriteNode(color: SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.6),
                                              size: CGSize(width: 3, height: 3))
                        dot.position = CGPoint(x: wx, y: wy)
                        dot.zPosition = 0.1
                        building.addChild(dot)
                    }
                }
            }
        }
    }
    
    // MARK: - Station Node
    
    private func setupStation() {
        let node = SKNode()
        // Starts off-screen to the left, slightly above horizon
        node.position = CGPoint(x: size.width * 0.22, y: horizonY)
        node.zPosition = 0.18  // in front of skylines, behind horizon line
        node.alpha = 0.0
        node.setScale(0.0)
        addChild(node)
        stationNode = node
        
        // Platform roof — wide horizontal canopy
        let roof = SKSpriteNode(color: SKColor(white: 0.18, alpha: 1.0),
                                size: CGSize(width: 180, height: 14))
        roof.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        roof.position = CGPoint(x: 0, y: 38)
        node.addChild(roof)
        
        // Thin roof overhang shadow line
        let overhang = SKSpriteNode(color: SKColor(white: 0.08, alpha: 1.0),
                                    size: CGSize(width: 190, height: 3))
        overhang.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        overhang.position = CGPoint(x: 0, y: 50)
        node.addChild(overhang)
        
        // Main building body
        let body = SKSpriteNode(color: SKColor(white: 0.22, alpha: 1.0),
                                size: CGSize(width: 160, height: 50))
        body.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        body.position = CGPoint(x: 0, y: 0)
        node.addChild(body)
        
        // Clock tower
        let tower = SKSpriteNode(color: SKColor(white: 0.16, alpha: 1.0),
                                 size: CGSize(width: 32, height: 70))
        tower.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        tower.position = CGPoint(x: -55, y: 0)
        node.addChild(tower)
        
        // Clock face
        let clockFace = SKSpriteNode(color: SKColor(red: 0.85, green: 0.78, blue: 0.55, alpha: 0.9),
                                     size: CGSize(width: 18, height: 18))
        clockFace.position = CGPoint(x: -55, y: 55)
        node.addChild(clockFace)
        
        // Support pillars
        for offset: CGFloat in [-60, -20, 20, 60] {
            let pillar = SKSpriteNode(color: SKColor(white: 0.28, alpha: 1.0),
                                      size: CGSize(width: 6, height: 38))
            pillar.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            pillar.position = CGPoint(x: offset, y: 0)
            node.addChild(pillar)
        }
        
        // Platform surface strip
        let platform = SKSpriteNode(color: SKColor(white: 0.30, alpha: 1.0),
                                    size: CGSize(width: 200, height: 6))
        platform.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        platform.position = CGPoint(x: 0, y: 0)
        node.addChild(platform)
        
        for wx: CGFloat in [-40, 0, 40] {
            let win = SKSpriteNode(color: SKColor(red: 1.0, green: 0.88, blue: 0.55, alpha: 0.85),
                                   size: CGSize(width: 14, height: 16))
            win.position = CGPoint(x: wx, y: 22)
            node.addChild(win)
        }
    }

    // MARK: - Scrolling Environment

    private func setupEnvironmentNode() {
        let env = EnvironmentNode(sceneSize: size, horizonY: horizonY)
        env.zPosition = 2.5
        addChild(env)
        self.environmentNode = env
    }

    private func setupTracksAndRails() {

        let centerX = size.width / 2
        let bottomY: CGFloat = 180.0
        
        let baseTrackTexture = SKTexture(imageNamed: "rail-foundation")
        
        // Crop the textured metallic rail from rail-foundation.png (X: 40-65, Y: 150-170 in SpriteKit coords)
        let railTexture = SKTexture(rect: CGRect(x: 40.0/436.0, y: 150.0/192.0, width: 25.0/436.0, height: 20.0/192.0), in: baseTrackTexture)
        railTexture.filteringMode = .nearest
        
        // Crop the textured wood sleeper from rail-foundation.png (X: 68-367, Y: 49-136 in SpriteKit coords)
        let sleeperTexture = SKTexture(rect: CGRect(x: 68.0/436.0, y: 49.0/192.0, width: 299.0/436.0, height: 87.0/192.0), in: baseTrackTexture)
        sleeperTexture.filteringMode = .nearest
        
        // Save the sleeper texture as a property of the scene so we can use it in updateSleepers
        self.sleeperTex = sleeperTexture
        
        // Left Track (0) Rails
        let track0_rail0_start = CGPoint(x: centerX - 202, y: bottomY)
        let track0_rail0_end = CGPoint(x: centerX - 35, y: horizonY)
        
        let track0_rail1_start = CGPoint(x: centerX - 118, y: bottomY)
        let track0_rail1_end = CGPoint(x: centerX - 15, y: horizonY)
        
        // Right Track (1) Rails
        let track1_rail0_start = CGPoint(x: centerX + 118, y: bottomY)
        let track1_rail0_end = CGPoint(x: centerX + 15, y: horizonY)
        
        let track1_rail1_start = CGPoint(x: centerX + 202, y: bottomY)
        let track1_rail1_end = CGPoint(x: centerX + 35, y: horizonY)
        
        let railsPoints = [
            (track0_rail0_start, track0_rail0_end),
            (track0_rail1_start, track0_rail1_end),
            (track1_rail0_start, track1_rail0_end),
            (track1_rail1_start, track1_rail1_end)
        ]
        
        
        // Create rail sprites (width 6.0 to be clearly visible and textured)
        originalRailPositions.removeAll()
        for points in railsPoints {
            let rail = SKSpriteNode(texture: railTexture, color: .lightGray, size: CGSize(width: 6.0, height: 1.0))
            rail.colorBlendFactor = 0.7
            rail.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            rail.zPosition = 1.0
            addChild(rail)
            railNodes.append(rail)
            originalRailPositions.append(points.0.x)
        }
        
        // Create Fixed Sleepers Pool to prevent GC churn (SpriteKit skill optimization)
        for track in 0...1 {
            for i in 0..<numSleepers {
                let sleeper = SKSpriteNode(texture: sleeperTexture, color: .lightGray, size: CGSize(width: 1, height: 1))
                sleeper.colorBlendFactor = 0.7
                sleeper.zPosition = 0.5
                addChild(sleeper)
                sleeperNodes.append(sleeper)
                
                // Stagger progress evenly
                let progress = Double(i) / Double(numSleepers)
                sleeperProgress.append(progress)
            }
        }
        
        // Middle Track (center lane) Rails
        let track2_rail0_start = CGPoint(x: centerX - 42, y: bottomY)
        let track2_rail0_end = CGPoint(x: centerX - 10, y: horizonY)
        
        let track2_rail1_start = CGPoint(x: centerX + 42, y: bottomY)
        let track2_rail1_end = CGPoint(x: centerX + 10, y: horizonY)
        
        let middleRailsPoints = [
            (track2_rail0_start, track2_rail0_end),
            (track2_rail1_start, track2_rail1_end)
        ]
        
        originalMiddleRailPositions.removeAll()
        for points in middleRailsPoints {
            let rail = SKSpriteNode(texture: railTexture, color: .lightGray, size: CGSize(width: 6.0, height: 1.0))
            rail.colorBlendFactor = 0.7
            rail.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            rail.zPosition = 1.0
            rail.alpha = 1.0   // always visible — center is now a permanent lane
            addChild(rail)
            middleRailNodes.append(rail)
            originalMiddleRailPositions.append(points.0.x)
        }
        
        // Create Sleeper Pool for Center Track
        for i in 0..<numSleepers {
            let sleeper = SKSpriteNode(texture: sleeperTexture, color: .lightGray, size: CGSize(width: 1, height: 1))
            sleeper.colorBlendFactor = 0.7
            sleeper.zPosition = 0.5
            sleeper.alpha = 1.0   // always visible
            addChild(sleeper)
            middleSleeperNodes.append(sleeper)
            
            let progress = Double(i) / Double(numSleepers)
            middleSleeperProgress.append(progress)
        }
    }
    
    private func setupCabinOverlay() {
        guard let camera = camera else { return }
        let cockpit = cameraController.cockpitNode
        let hw = size.width / 2
        let hh = size.height / 2
        let dashH: CGFloat = 230

        // ── 1. COCKPIT TEXTURED BACKGROUND ────────────────────────────────────
        let cockpitTexture = SKTexture(imageNamed: "train-cockpit")
        cockpitTexture.filteringMode = .nearest
        let cockpitBg = SKSpriteNode(texture: cockpitTexture, size: size)
        cockpitBg.position = .zero
        cockpitBg.zPosition = 9.9
        cockpit.addChild(cockpitBg)

        // ── 2. DASHBOARD BODY ─────────────────────────────────────────────────
        dashboardNode = SKSpriteNode(
            color: .clear,
            size: CGSize(width: size.width, height: dashH))
        dashboardNode.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        dashboardNode.position = CGPoint(x: 0, y: -hh)
        dashboardNode.zPosition = 10.0
        cockpit.addChild(dashboardNode)

        // ── 3. FURNACE DOOR (left of centre) ─────────────────────────────────
        let furnaceX: CGFloat = -size.width * 0.17
        let furnaceY: CGFloat = 108

        let doorFrame = SKSpriteNode(color: SKColor(red: 0.20, green: 0.14, blue: 0.11, alpha: 1.0),
                                      size: CGSize(width: 162, height: 116))
        doorFrame.position = CGPoint(x: furnaceX, y: furnaceY)
        doorFrame.zPosition = 11.0
        dashboardNode.addChild(doorFrame)

        furnaceDoor = SKSpriteNode(color: SKColor(red: 0.11, green: 0.08, blue: 0.07, alpha: 1.0),
                                    size: CGSize(width: 142, height: 96))
        furnaceDoor.position = .zero
        furnaceDoor.zPosition = 0.1
        doorFrame.addChild(furnaceDoor)

        furnaceFire = SKSpriteNode(color: .orange, size: CGSize(width: 108, height: 70))
        furnaceFire.position = .zero
        furnaceFire.zPosition = 10.9
        furnaceFire.blendMode = .add
        furnaceDoor.addChild(furnaceFire)

        for hx: CGFloat in [-72, 72] {
            let hinge = SKSpriteNode(color: SKColor(white: 0.38, alpha: 1.0),
                                      size: CGSize(width: 10, height: 30))
            hinge.position = CGPoint(x: hx, y: 0)
            hinge.zPosition = 11.2
            doorFrame.addChild(hinge)
        }

        let fuelTitle = SKLabelNode(text: "FURNACE")
        fuelTitle.fontName = "CourierNewPS-BoldMT"
        fuelTitle.fontSize = 9
        fuelTitle.fontColor = SKColor(white: 0.50, alpha: 1.0)
        fuelTitle.position = CGPoint(x: furnaceX, y: furnaceY - 68)
        fuelTitle.zPosition = 11.5
        dashboardNode.addChild(fuelTitle)

        // ── 4. COAL FUEL BAR ─────────────────────────────────────────────────
        let barW: CGFloat = 148
        let barX = furnaceX
        let barY: CGFloat = 44

        let gaugeBG = SKSpriteNode(color: SKColor(white: 0.05, alpha: 1.0),
                                    size: CGSize(width: barW, height: 12))
        gaugeBG.position = CGPoint(x: barX, y: barY)
        gaugeBG.zPosition = 11.0
        dashboardNode.addChild(gaugeBG)

        for tick in [0.25, 0.5, 0.75] {
            let t = SKSpriteNode(color: SKColor(white: 0.30, alpha: 1.0),
                                  size: CGSize(width: 1, height: 16))
            t.position = CGPoint(x: (CGFloat(tick) - 0.5) * barW, y: 0)
            t.zPosition = 0.2
            gaugeBG.addChild(t)
        }

        coalMeterFill = SKSpriteNode(
            color: SKColor(red: 0.88, green: 0.28, blue: 0.08, alpha: 1.0),
            size: CGSize(width: barW - 4, height: 8))
        coalMeterFill.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        coalMeterFill.position = CGPoint(x: -(barW - 4) / 2, y: 0)
        coalMeterFill.zPosition = 11.1
        gaugeBG.addChild(coalMeterFill)

        coalMeterLabel = SKLabelNode(text: "FUEL")
        coalMeterLabel.fontName = "CourierNewPS-BoldMT"
        coalMeterLabel.fontSize = 9
        coalMeterLabel.fontColor = SKColor(white: 0.55, alpha: 1.0)
        coalMeterLabel.horizontalAlignmentMode = .left
        coalMeterLabel.position = CGPoint(x: barX - barW / 2, y: barY + 9)
        coalMeterLabel.zPosition = 11.2
        dashboardNode.addChild(coalMeterLabel)

        // ── 5. SPEEDOMETER DIAL (right of centre) ─────────────────────────────
        let spdX: CGFloat = size.width * 0.16
        let spdY: CGFloat = 114
        let dialR: CGFloat = 52

        speedometerBG = makeDialBackground(radius: dialR,
                                            fill: SKColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0),
                                            ring: SKColor(white: 0.30, alpha: 1.0))
        speedometerBG.position = CGPoint(x: spdX, y: spdY)
        speedometerBG.zPosition = 11.0
        dashboardNode.addChild(speedometerBG)

        addDialTicks(to: speedometerBG, radius: dialR - 6, count: 9, length: 8,
                     color: SKColor(white: 0.55, alpha: 1.0))
        addDialTicks(to: speedometerBG, radius: dialR - 6, count: 41, length: 4,
                     color: SKColor(white: 0.28, alpha: 1.0))

        // Speed labels: 0, 20, 40, 60, 80 km/h
        for (i, val) in [(0, "0"), (2, "20"), (4, "40"), (6, "60"), (8, "80")] {
            let angle = dialStartAngle + CGFloat(i) / 8.0 * dialSweep
            let r = dialR - 18
            let lbl = SKLabelNode(text: val)
            lbl.fontName = "CourierNewPS-BoldMT"
            lbl.fontSize = 7
            lbl.fontColor = SKColor(white: 0.65, alpha: 1.0)
            lbl.verticalAlignmentMode = .center
            lbl.horizontalAlignmentMode = .center
            lbl.position = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            lbl.zPosition = 0.3
            speedometerBG.addChild(lbl)
        }

        let spdCentre = makeDialBackground(radius: 5, fill: SKColor(white: 0.55, alpha: 1.0), ring: .clear)
        spdCentre.zPosition = 0.5
        speedometerBG.addChild(spdCentre)

        speedNeedle = SKSpriteNode(color: SKColor(red: 1.0, green: 0.22, blue: 0.08, alpha: 1.0),
                                    size: CGSize(width: 3, height: dialR - 10))
        speedNeedle.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        speedNeedle.position = .zero
        speedNeedle.zPosition = 0.4
        speedNeedle.zRotation = dialStartAngle + .pi / 2
        speedometerBG.addChild(speedNeedle)

        let spdTitle = SKLabelNode(text: "SPEED")
        spdTitle.fontName = "CourierNewPS-BoldMT"
        spdTitle.fontSize = 7
        spdTitle.fontColor = SKColor(white: 0.40, alpha: 1.0)
        spdTitle.position = CGPoint(x: 0, y: -dialR + 13)
        spdTitle.zPosition = 0.3
        speedometerBG.addChild(spdTitle)

        speedLabel = SKLabelNode(text: "0")
        speedLabel.fontName = "CourierNewPS-BoldMT"
        speedLabel.fontSize = 11
        speedLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0)
        speedLabel.verticalAlignmentMode = .center
        speedLabel.horizontalAlignmentMode = .center
        speedLabel.position = CGPoint(x: 0, y: -12)
        speedLabel.zPosition = 0.4
        speedometerBG.addChild(speedLabel)

        // ── 6. BOILER PRESSURE DIAL (far left) ───────────────────────────────
        let presX: CGFloat = -size.width * 0.30
        let presY: CGFloat = 144
        let presR: CGFloat = 38

        pressureGaugeBG = makeDialBackground(
            radius: presR,
            fill: SKColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0),
            ring: SKColor(white: 0.26, alpha: 1.0))
        pressureGaugeBG.position = CGPoint(x: presX, y: presY)
        pressureGaugeBG.zPosition = 11.0
        dashboardNode.addChild(pressureGaugeBG)

        addDialTicks(to: pressureGaugeBG, radius: presR - 5, count: 7, length: 6,
                     color: SKColor(white: 0.48, alpha: 1.0))

        let presCentre = makeDialBackground(radius: 4, fill: SKColor(white: 0.45, alpha: 1.0), ring: .clear)
        presCentre.zPosition = 0.5
        pressureGaugeBG.addChild(presCentre)

        pressureNeedle = SKSpriteNode(
            color: SKColor(red: 0.25, green: 0.82, blue: 1.0, alpha: 1.0),
            size: CGSize(width: 2.5, height: presR - 7))
        pressureNeedle.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        pressureNeedle.position = .zero
        pressureNeedle.zPosition = 0.4
        pressureNeedle.zRotation = dialStartAngle + .pi / 2
        pressureGaugeBG.addChild(pressureNeedle)

        let presTitle = SKLabelNode(text: "BOILER")
        presTitle.fontName = "CourierNewPS-BoldMT"
        presTitle.fontSize = 7
        presTitle.fontColor = SKColor(white: 0.38, alpha: 1.0)
        presTitle.position = CGPoint(x: 0, y: -presR + 9)
        presTitle.zPosition = 0.3
        pressureGaugeBG.addChild(presTitle)

        // ── 7. ODOMETER DISPLAY ───────────────────────────────────────────────
        let odomBorder = SKSpriteNode(color: SKColor(white: 0.22, alpha: 1.0),
                                       size: CGSize(width: 116, height: 30))
        odomBorder.position = CGPoint(x: spdX, y: 44)
        odomBorder.zPosition = 11.0
        dashboardNode.addChild(odomBorder)

        let odomBG = SKSpriteNode(color: SKColor(red: 0.05, green: 0.06, blue: 0.06, alpha: 1.0),
                                   size: CGSize(width: 112, height: 26))
        odomBG.position = .zero
        odomBG.zPosition = 0.1
        odomBorder.addChild(odomBG)

        odometerLabel = SKLabelNode(text: "0000 m")
        odometerLabel.fontName = "CourierNewPS-BoldMT"
        odometerLabel.fontSize = 12
        odometerLabel.fontColor = SKColor(red: 0.35, green: 1.0, blue: 0.4, alpha: 1.0)
        odometerLabel.verticalAlignmentMode = .center
        odometerLabel.horizontalAlignmentMode = .center
        odometerLabel.position = .zero
        odometerLabel.zPosition = 0.3
        odomBG.addChild(odometerLabel)

        let odomTitle = SKLabelNode(text: "DIST")
        odomTitle.fontName = "CourierNewPS-BoldMT"
        odomTitle.fontSize = 8
        odomTitle.fontColor = SKColor(white: 0.38, alpha: 1.0)
        odomTitle.position = CGPoint(x: spdX, y: 33)
        odomTitle.zPosition = 11.1
        dashboardNode.addChild(odomTitle)

        // ── 8. OVERHEAT WARNING LIGHT ─────────────────────────────────────────
        pressureWarningLight = makeDialBackground(
            radius: 9,
            fill: SKColor(red: 0.65, green: 0.05, blue: 0.05, alpha: 1.0),
            ring: SKColor(red: 0.35, green: 0.05, blue: 0.05, alpha: 1.0))
        pressureWarningLight.position = CGPoint(x: presX + 58, y: presY)
        pressureWarningLight.zPosition = 11.0
        pressureWarningLight.alpha = 0.3
        dashboardNode.addChild(pressureWarningLight)

        let warnLbl = SKLabelNode(text: "!")
        warnLbl.fontName = "CourierNewPS-BoldMT"
        warnLbl.fontSize = 10
        warnLbl.fontColor = .white
        warnLbl.verticalAlignmentMode = .center
        warnLbl.horizontalAlignmentMode = .center
        warnLbl.zPosition = 0.2
        pressureWarningLight.addChild(warnLbl)

        // ── 9. WHITE TRANSITION OVERLAY (on camera, not cockpitNode) ─────────
        whiteTransitionOverlay = SKSpriteNode(color: .white, size: size)
        whiteTransitionOverlay.position = .zero
        whiteTransitionOverlay.zPosition = 99.0
        whiteTransitionOverlay.alpha = 0.0
        camera.addChild(whiteTransitionOverlay)
        
        // ── 10. VIGNETTE OVERLAY (on camera, on top of everything) ───────────
        if let vignetteTexture = createVignetteTexture(size: size) {
            let vignetteNode = SKSpriteNode(texture: vignetteTexture)
            vignetteNode.position = .zero
            vignetteNode.zPosition = 95.0 // Below white flash overlay (99.0) but above everything else
            camera.addChild(vignetteNode)
        }
    }

    // MARK: - Dial Helpers

    private func makeDialBackground(radius: CGFloat, fill: SKColor, ring: SKColor) -> SKSpriteNode {
        let node = SKSpriteNode(color: fill, size: CGSize(width: radius * 2, height: radius * 2))
        if ring != .clear {
            let ringNode = SKSpriteNode(color: ring, size: CGSize(width: (radius + 4) * 2, height: (radius + 4) * 2))
            ringNode.zPosition = -0.1
            node.addChild(ringNode)
        }
        return node
    }

    private func addDialTicks(to parent: SKNode, radius: CGFloat, count: Int, length: CGFloat, color: SKColor) {
        for i in 0..<count {
            let angle = dialStartAngle + CGFloat(i) / CGFloat(count - 1) * dialSweep
            let inner = radius - length
            let tick = SKSpriteNode(color: color, size: CGSize(width: 1.5, height: length))
            tick.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            tick.position = CGPoint(x: cos(angle) * inner, y: sin(angle) * inner)
            tick.zRotation = angle + .pi / 2
            tick.zPosition = 0.2
            parent.addChild(tick)
        }
    }

    
    private func createLineNode(from: CGPoint, to: CGPoint, color: SKColor, width: CGFloat) -> SKSpriteNode {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        
        let line = SKSpriteNode(color: color, size: CGSize(width: width, height: length))
        line.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        line.position = from
        line.zRotation = angle - .pi / 2
        
        return line
    }
    
    private func updateLineNode(_ line: SKSpriteNode, from: CGPoint, to: CGPoint, width: CGFloat = 6.0) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        
        line.position = from
        line.size = CGSize(width: width, height: length)
        line.zRotation = angle - .pi / 2
    }

    
    private func applyChapterStyling(_ chapter: Chapter) {
        // Toggle city silhouette visibility based on active chapter (Krotoszyn is the first city)
        if chapter == .krotoszyn {
            citySilhouette?.isHidden = false
            citySilhouette?.alpha = 0.0
            citySilhouette?.setScale(0.70)
        } else {
            citySilhouette?.isHidden = true
            citySilhouette?.alpha = 0.0
        }
        
        // Hide city skylines and environment during tunnel
        if chapter == .tunnel {
            citySkylinesNode?.isHidden = true
            environmentNode?.isHidden = true
        } else {
            citySkylinesNode?.isHidden = false
            citySkylinesNode?.alpha = 0.0
            citySkylinesNode?.setScale(0.70)
            environmentNode?.isHidden = false
            rebuildCitySkylines(for: chapter)
        }
        
        updateWartimeSky(isWartime: (chapter == .jarocin))
        
        // Reset texture to nil so fallback to solid colors works for other chapters
        skyNode?.texture = nil
        
        switch chapter {
        case .prolog, .krotoszyn:
            // Horizon Sky color #0D4969
            skyNode.texture = nil
            skyNode.color = SKColor(red: 13.0/255.0, green: 73.0/255.0, blue: 105.0/255.0, alpha: 1.0)
            groundNode.color = SKColor(red: 0.28, green: 0.35, blue: 0.22, alpha: 1.0)
            horizonLine.color = SKColor(red: 0.4, green: 0.35, blue: 0.2, alpha: 1.0)
            tunnelDarkness.alpha = 0.0
            headlightBeam.alpha = 0.0
            updateRailsColor(.lightGray)
        case .kozmin:
            // Stormy Grey (Foggy green-grey bottom to Deep navy-charcoal top)
            let skySize = CGSize(width: size.width * 2, height: size.height - horizonY)
            let topColor = SKColor(red: 0.12, green: 0.14, blue: 0.17, alpha: 1.0)
            let bottomColor = SKColor(red: 0.36, green: 0.39, blue: 0.36, alpha: 1.0)
            if let gradTexture = createSkyGradientTexture(size: skySize, topColor: topColor, bottomColor: bottomColor) {
                skyNode.texture = gradTexture
                skyNode.color = .white
            } else {
                skyNode.color = topColor
            }
            groundNode.color = SKColor(red: 0.22, green: 0.2, blue: 0.18, alpha: 1.0)
            horizonLine.color = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            tunnelDarkness.alpha = 0.0
            headlightBeam.alpha = 0.0
            updateRailsColor(.gray)
        case .jarocin:
            // wartime desaturated gradient fading from orange (bottom) to grey (top) (background-2 reference)
            let skySize = CGSize(width: size.width * 2, height: size.height - horizonY)
            let topColor = SKColor(red: 0.28, green: 0.27, blue: 0.25, alpha: 1.0)
            let bottomColor = SKColor(red: 0.85, green: 0.35, blue: 0.15, alpha: 1.0)
            if let gradTexture = createSkyGradientTexture(size: skySize, topColor: topColor, bottomColor: bottomColor) {
                skyNode.texture = gradTexture
                skyNode.color = .white
            } else {
                skyNode.color = topColor
            }
            groundNode.color = SKColor(red: 0.50, green: 0.48, blue: 0.46, alpha: 1.0)
            horizonLine.color = SKColor(red: 0.18, green: 0.17, blue: 0.16, alpha: 1.0)
            tunnelDarkness.alpha = 0.0
            headlightBeam.alpha = 0.0
            updateRailsColor(.gray)
        case .tunnel:
            // Dimmed/Black
            skyNode.color = .black
            groundNode.color = SKColor(white: 0.05, alpha: 1.0)
            horizonLine.color = SKColor(white: 0.02, alpha: 1.0)
            tunnelDarkness.alpha = 0.85
            headlightBeam.alpha = 0.25
            updateRailsColor(.darkGray)
        case .konin:
            // Dreamy sunrise (Peach bottom to Pastel Blue top)
            let skySize = CGSize(width: size.width * 2, height: size.height - horizonY)
            let topColor = SKColor(red: 0.65, green: 0.76, blue: 0.97, alpha: 1.0)
            let bottomColor = SKColor(red: 0.97, green: 0.79, blue: 0.65, alpha: 1.0)
            if let gradTexture = createSkyGradientTexture(size: skySize, topColor: topColor, bottomColor: bottomColor) {
                skyNode.texture = gradTexture
                skyNode.color = .white
            } else {
                skyNode.color = topColor
            }
            groundNode.color = SKColor(red: 0.45, green: 0.65, blue: 0.45, alpha: 1.0)
            horizonLine.color = SKColor(red: 0.6, green: 0.7, blue: 0.7, alpha: 1.0)
            tunnelDarkness.alpha = 0.0
            headlightBeam.alpha = 0.0
            updateRailsColor(SKColor(red: 0.95, green: 0.85, blue: 0.55, alpha: 1.0))
            
            // Dreamy floaty particle effect
            spawnDreamParticles()
        case .zolkiew:
            // Solid white fadeout
            skyNode.color = .white
            groundNode.color = .white
            horizonLine.color = .white
            tunnelDarkness.alpha = 0.0
            headlightBeam.alpha = 0.0
            updateRailsColor(.white)
        }
    }
    
    private func updateRailsColor(_ color: SKColor) {
        for rail in railNodes {
            rail.color = color
        }
        for rail in middleRailNodes {
            rail.color = color
        }
    }
    
    private func spawnDreamParticles() {
        let emitter = SKEmitterNode()
        emitter.position = CGPoint(x: size.width / 2, y: horizonY + 80)
        emitter.zPosition = 2.0
        
        emitter.particleBirthRate = 8
        emitter.particleLifetime = 4.0
        emitter.particleLifetimeRange = 1.0
        
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        
        emitter.particleColor = .white
        emitter.particleColorAlphaSpeed = -0.2
        emitter.particleScale = 0.04
        emitter.particleScaleRange = 0.03
        emitter.particleScaleSpeed = 0.02
        
        addChild(emitter)
    }
    
    func triggerFurnaceFlash() {
        // Flare furnace fire size/intensity
        let scaleUp = SKAction.scale(to: 1.25, duration: 0.1)
        let colorize = SKAction.colorize(with: .white, colorBlendFactor: 0.5, duration: 0.05)
        let resetColor = SKAction.colorize(with: .orange, colorBlendFactor: 0.0, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        
        furnaceFire.run(SKAction.sequence([
            SKAction.group([scaleUp, colorize]),
            SKAction.group([scaleDown, resetColor])
        ]))
        
        // Spawn ember sparks
        let sparks = SKEmitterNode()
        sparks.position = CGPoint(x: 0, y: 0)
        sparks.zPosition = 10.8
        sparks.numParticlesToEmit = 15
        sparks.particleBirthRate = 100
        sparks.particleLifetime = 0.5
        sparks.particleSpeed = 120
        sparks.particleSpeedRange = 40
        sparks.emissionAngle = .pi / 2
        sparks.emissionAngleRange = .pi / 3
        sparks.particleColor = .yellow
        sparks.particleScale = 0.08
        sparks.particleScaleSpeed = -0.15
        
        furnaceFire.addChild(sparks)
        sparks.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.removeFromParent()
        ]))
    }
    
    func triggerFlash(color: SKColor) {
        let flash = SKSpriteNode(color: color, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 9.0
        flash.alpha = 0.6
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.45),
            SKAction.removeFromParent()
        ]))
    }
    
    /// Pulsing orange/red vignette flash when coal is critically low
    func triggerLowCoalWarning() {
        let flash = SKSpriteNode(color: SKColor(red: 0.9, green: 0.2, blue: 0.0, alpha: 1.0), size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 8.5
        flash.alpha = 0.0
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.25, duration: 0.3),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // Also shake the coal label
        coalMeterLabel.run(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.2),
            SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.2)
        ]))
    }
    
    /// Furnace glows green briefly when overheat cooldown expires (ready again)
    func triggerFurnaceCooled() {
        let glow = SKAction.colorize(with: SKColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0), colorBlendFactor: 0.8, duration: 0.2)
        let reset = SKAction.colorize(with: .orange, colorBlendFactor: 0.0, duration: 0.4)
        furnaceFire.run(SKAction.sequence([glow, reset]))
    }
    
    /// Furnace goes dark red when overheated — player must wait
    func triggerFurnaceOverheat() {
        furnaceFire.run(SKAction.colorize(with: SKColor(red: 0.6, green: 0.05, blue: 0.0, alpha: 1.0), colorBlendFactor: 0.9, duration: 0.3))
        
        // Smoke puff particles
        let smoke = SKEmitterNode()
        smoke.position = CGPoint(x: 0, y: 20)
        smoke.zPosition = 10.8
        smoke.numParticlesToEmit = 20
        smoke.particleBirthRate = 60
        smoke.particleLifetime = 1.2
        smoke.particleSpeed = 60
        smoke.particleSpeedRange = 20
        smoke.emissionAngle = .pi / 2
        smoke.emissionAngleRange = .pi / 4
        smoke.particleColor = SKColor(white: 0.4, alpha: 0.8)
        smoke.particleColorAlphaSpeed = -0.7
        smoke.particleScale = 0.12
        smoke.particleScaleSpeed = 0.06
        furnaceFire.addChild(smoke)
        smoke.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent()
        ]))
        
        // Camera shake — furnace judder
        cameraController.shake(duration: 0.4, intensity: 6)
    }
    
    /// Brief flash on the side matching the approaching hazard lane
    func triggerRailWarningFlash(lane: Int) {
        // For 3 lanes: left=25%, center=50%, right=75% of screen
        let flashX: CGFloat
        switch lane {
        case 0: flashX = size.width * 0.22
        case 1: flashX = size.width * 0.50
        default: flashX = size.width * 0.78
        }
        let flash = SKSpriteNode(color: .yellow, size: CGSize(width: size.width / 3.2, height: size.height))
        flash.position = CGPoint(x: flashX, y: size.height / 2)
        flash.zPosition = 8.0
        flash.alpha = 0.0
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.18, duration: 0.12),
            SKAction.fadeOut(withDuration: 0.35),
            SKAction.removeFromParent()
        ]))
    }
    
    // Core Game Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard isConfigured else { return }
        
        if isWaitingToStart {
            lastUpdateTime = currentTime
            return
        }
        
        if lastUpdateTime == 0.0 {
            lastUpdateTime = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // 1. Update systems & controllers
        trainController.update(deltaTime: deltaTime, chapter: activeChapter)
        coalSystem.update(deltaTime: deltaTime, chapter: activeChapter)
        hazardManager.update(deltaTime: deltaTime, speed: trainController.speed, chapter: activeChapter)
        airRaidController.update(deltaTime: deltaTime, speed: trainController.speed, chapter: activeChapter)
        cameraController.update(deltaTime: deltaTime)
        
        // 2. Refresh sleeper coordinates to simulate forward velocity
        updateSleepers(deltaTime: deltaTime)
        environmentNode?.update(deltaTime: deltaTime, speed: trainController.speed, visualOffset: trainController.visualOffset, chapter: activeChapter)
        updateCityApproach(deltaTime: deltaTime)
        
        // Update horizon Luftwaffe & AA flak visuals during Jarocin air raids
        if activeChapter == .jarocin {
            updateHorizonVisuals(deltaTime: deltaTime)
        }
        
        // 3. Update dashboard gauges
        updateGauges()
        
        // 4. Update Konin-specific transitions (middle rail, white flash)
        updateKoninTransition(deltaTime: deltaTime)
        
        // 5. Station approach reveal
        updateStationApproach()
        
        // 6. Fail fade-to-black
        updateFailFade(deltaTime: deltaTime)
    }
    
    private func updateSleepers(deltaTime: TimeInterval) {
        // Sleeper approach speed maps directly to train speed
        let speedFactor = trainController.speed / 35.0
        let baseIncrement = speedFactor * deltaTime * 1.2
        
        let centerX = size.width / 2
        let bottomY: CGFloat = 180.0
        let visualOffset = trainController.visualOffset
        
        // 1. Update side track sleepers
        for track in 0...1 {
            let X_track: CGFloat = track == 0 ? -160.0 : 160.0
            for i in 0..<numSleepers {
                let index = track * numSleepers + i
                var progress = sleeperProgress[index]
                
                // Increment progress
                progress += baseIncrement
                if progress >= 1.0 { progress -= 1.0 }
                sleeperProgress[index] = progress
                
                let sleeper = sleeperNodes[index]
                let y = horizonY - (horizonY - bottomY) * CGFloat(pow(progress, 2.0))
                
                // Unified perspective projection matching rail.png
                let scale = 0.33333 + (1.0 - 0.33333) * CGFloat(progress)
                let x = centerX + (X_track + visualOffset) * scale
                
                sleeper.position = CGPoint(x: x, y: y)
                
                let w = 140.0 * scale
                let h = 35.0 * scale
                sleeper.size = CGSize(width: w, height: h)
                
                // Fade sleepers near the horizon, scaled by side tracks alpha
                sleeper.alpha = CGFloat(progress) * sideTracksAlpha
            }
        }
        
        // 2. Update center track sleepers — always visible (permanent lane)
        for i in 0..<numSleepers {
            var progress = middleSleeperProgress[i]
            
            progress += baseIncrement
            if progress >= 1.0 { progress -= 1.0 }
            middleSleeperProgress[i] = progress
            
            let sleeper = middleSleeperNodes[i]
            let y = horizonY - (horizonY - bottomY) * CGFloat(pow(progress, 2.0))
            
            let X_track: CGFloat = 0.0
            let scale = 0.33333 + (1.0 - 0.33333) * CGFloat(progress)
            let x = centerX + (X_track + visualOffset) * scale
            
            sleeper.position = CGPoint(x: x, y: y)
            
            let w = 140.0 * scale
            let h = 35.0 * scale
            sleeper.size = CGSize(width: w, height: h)
            
            // Center sleepers use sideTracksAlpha complement — fades out only during Konin merge
            sleeper.alpha = CGFloat(progress) * middleTrackAlpha
        }
        
        // 3. Update headlight beam alignment (always straight ahead of the cabin)
        headlightBeam.position.x = centerX
        
        // 4. Update rail lines dynamically to maintain perfect perspective
        let track0_center_bottom = centerX - 160.0 + visualOffset
        let track0_center_horizon = centerX + (-160.0 + visualOffset) * 0.33333
        updateLineNode(railNodes[0], from: CGPoint(x: track0_center_bottom - 42.0, y: bottomY), to: CGPoint(x: track0_center_horizon - 10.0, y: horizonY), width: 6.0)
        updateLineNode(railNodes[1], from: CGPoint(x: track0_center_bottom + 42.0, y: bottomY), to: CGPoint(x: track0_center_horizon + 10.0, y: horizonY), width: 6.0)
        
        let track1_center_bottom = centerX + 160.0 + visualOffset
        let track1_center_horizon = centerX + (160.0 + visualOffset) * 0.33333
        updateLineNode(railNodes[2], from: CGPoint(x: track1_center_bottom - 42.0, y: bottomY), to: CGPoint(x: track1_center_horizon - 10.0, y: horizonY), width: 6.0)
        updateLineNode(railNodes[3], from: CGPoint(x: track1_center_bottom + 42.0, y: bottomY), to: CGPoint(x: track1_center_horizon + 10.0, y: horizonY), width: 6.0)
        
        let track2_center_bottom = centerX + visualOffset
        let track2_center_horizon = centerX + visualOffset * 0.33333
        updateLineNode(middleRailNodes[0], from: CGPoint(x: track2_center_bottom - 42.0, y: bottomY), to: CGPoint(x: track2_center_horizon - 10.0, y: horizonY), width: 6.0)
        updateLineNode(middleRailNodes[1], from: CGPoint(x: track2_center_bottom + 42.0, y: bottomY), to: CGPoint(x: track2_center_horizon + 10.0, y: horizonY), width: 6.0)
        
        // 5. Update city silhouette horizontal position (subtle parallax)
        if let cityNode = citySilhouette {
            cityNode.position.x = centerX + visualOffset * 0.15
        }
    }
    
    private func updateGauges() {
        let coalPercent = GameDirector.shared.coalPercentage
        let speed = trainController.speed

        // ── Fuel bar ───────────────────────────────────────────────────────
        let barW: CGFloat = 144
        let fuelWidth = barW * CGFloat(coalPercent / 100.0)
        coalMeterFill.size.width = max(1, fuelWidth)

        if coalPercent <= 25.0 {
            let pulse = sin(Date().timeIntervalSince1970 * 10.0) > 0.0
            coalMeterFill.color = pulse ? .red : SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)
            coalMeterLabel.fontColor = .red
        } else if coalPercent <= 60.0 {
            coalMeterFill.color = SKColor(red: 0.95, green: 0.62, blue: 0.05, alpha: 1.0)
            coalMeterLabel.fontColor = SKColor(white: 0.60, alpha: 1.0)
        } else {
            coalMeterFill.color = SKColor(red: 0.88, green: 0.28, blue: 0.08, alpha: 1.0)
            coalMeterLabel.fontColor = SKColor(white: 0.55, alpha: 1.0)
        }

        // ── Furnace fire flicker ───────────────────────────────────────────
        let fireIntensity = 0.5 + 0.5 * CGFloat(coalPercent / 100.0)
        let flicker = CGFloat.random(in: -0.06...0.06)
        furnaceFire.alpha = max(0, min(1, fireIntensity + flicker))

        // ── Speedometer needle (smooth) ────────────────────────────────────
        let maxSpeed: Double = 80.0  // km/h top of dial
        let speedKmh = speed * 2.2   // rough m/s → km/h
        let speedNorm = CGFloat(min(speedKmh, maxSpeed) / maxSpeed)
        let targetSpdAngle = dialStartAngle + speedNorm * dialSweep + .pi / 2
        speedNeedle.zRotation += (targetSpdAngle - speedNeedle.zRotation) * 0.08
        speedLabel.text = "\(Int(speedKmh))"

        // ── Boiler pressure needle (very slow — sluggish like real steam) ──
        let pressureNorm = CGFloat(min(coalPercent / 100.0, 1.0))
        let targetPresAngle = dialStartAngle + pressureNorm * dialSweep + .pi / 2
        pressureNeedle.zRotation += (targetPresAngle - pressureNeedle.zRotation) * 0.012

        // ── Overheat warning light ─────────────────────────────────────────
        if coalPercent <= 10.0 {
            let flash = sin(Date().timeIntervalSince1970 * 8.0) > 0.0
            pressureWarningLight.alpha = flash ? 1.0 : 0.3
        } else {
            pressureWarningLight.alpha = 0.3
        }

        // ── Odometer ──────────────────────────────────────────────────────
        let dist = Int(trainController.distanceTravelled)
        odometerLabel.text = String(format: "%04d m", dist)
    }

    
    // Keyboard Event Handling (macOS Responder methods)
    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        _ = handleKeyDown(keyCode: event.keyCode, characters: event.charactersIgnoringModifiers)
    }
    
    override func keyUp(with event: NSEvent) {
        _ = handleKeyUp(keyCode: event.keyCode)
    }
    
    private func handleKeyDown(keyCode: UInt16, characters: String?) -> Bool {
        guard isConfigured else { return false }
        
        let normalizedKey = characters?.lowercased()
        if keyCode == 4 || normalizedKey == "h" {
            SynthAudioEngine.shared.playHonk()
            return true
        }
        
        guard !isWaitingToStart else { return false }
        
        switch keyCode {
        case 0, 123: // A / Left Arrow — shift one lane left
            trainController.shiftLaneLeft()
        case 13, 126: // W / Up Arrow — return to center lane
            trainController.returnToCenter()
        case 2, 124: // D / Right Arrow — shift one lane right
            trainController.shiftLaneRight()
        case 1, 125: // S / Down Arrow — duck
            trainController.setDucked(true)
        case 49: // Space — stoke furnace
            coalSystem.stokeCoal()
        case 12: // Q — jalan
            trainController.setBraking(false)
            return true
        case 11: // B — brake
            trainController.setBraking(true)
            
            return true
        default:
            return false
        }
        
        return true
    }
    
    private func handleKeyUp(keyCode: UInt16) -> Bool {
        guard isConfigured && !isWaitingToStart else { return false }
        
        switch keyCode {
        case 1, 125: // S / Down Arrow
            trainController.setDucked(false)
            return true
        default:
            return false
        }
        
        return true
    }
    #endif
    
    private func updateKoninTransition(deltaTime: TimeInterval) {
        if activeChapter == .konin {
            let targetDist = activeChapter.targetDistance
            guard targetDist > 0 else { return }
            let progressRatio = trainController.distanceTravelled / targetDist
            
            // Phase 1: At 70% progress, fade out side tracks and force to center lane (1)
            if progressRatio >= 0.70 {
                sideTracksAlpha = max(0.0, sideTracksAlpha - CGFloat(deltaTime) * 0.8)
                trainController.targetLane = 1   // center lane
            }
            
            // Phase 2: At 90% progress, fade to white
            if progressRatio >= 0.90 {
                let whiteProgress = (progressRatio - 0.90) / 0.10
                whiteTransitionOverlay.alpha = min(1.0, CGFloat(whiteProgress))
            } else {
                whiteTransitionOverlay.alpha = 0.0
            }
            
            // Apply rail alphas — side tracks fade, center track stays at 1
            for rail in railNodes {
                rail.alpha = sideTracksAlpha
            }
            for rail in middleRailNodes {
                rail.alpha = middleTrackAlpha  // stays 1.0
            }
        } else {
            // Keep defaults for non-Konin chapters
            sideTracksAlpha = 1.0
            middleTrackAlpha = 1.0   // center always visible
            if whiteTransitionOverlay != nil && activeChapter != .zolkiew {
                whiteTransitionOverlay.alpha = 0.0
            }
            for rail in railNodes {
                rail.alpha = 1.0
            }
            for rail in middleRailNodes {
                rail.alpha = 1.0
            }
        }
    }
    
    // MARK: - Station Approach
    
    private func updateStationApproach() {
        guard activeChapter.targetDistance > 0 else { return }
        guard activeChapter != .tunnel && activeChapter != .konin else { return }
        let progress = trainController.distanceTravelled / activeChapter.targetDistance
        
        // Show station when 80% of chapter is done
        let showThreshold = 0.80
        if progress >= showThreshold && !stationVisible {
            stationVisible = true
            
            // Fade + scale in from tiny at horizon
            stationNode.run(SKAction.group([
                SKAction.fadeIn(withDuration: 1.2),
                SKAction.scale(to: 0.6, duration: 1.2)
            ]))
        }
        
        // While visible, grow the station as the train approaches
        if stationVisible && progress < 1.0 {
            let approachProgress = max(0, (progress - showThreshold) / (1.0 - showThreshold))
            let targetScale = 0.6 + approachProgress * 0.9  // 0.6 → 1.5 as train arrives
            let currentScale = stationNode.xScale
            // Smooth interpolation
            let newScale = currentScale + (targetScale - currentScale) * 0.06
            stationNode.setScale(newScale)
            
            // Move station slightly toward center as scale grows (parallax pull-in)
            let baseX = size.width * 0.22
            let pullX = baseX + approachProgress * size.width * 0.06
            let curX = stationNode.position.x
            stationNode.position.x = curX + (pullX - curX) * 0.06
        }
    }
    
    // MARK: - Fail Fade
    
    /// Called by GameDirector (via CoalSystem) — smoothly fades to black before switching state
    func triggerFailFade(chapter: Chapter) {
        guard !isFadingToFail else { return }
        isFadingToFail = true
        
        // Stop the train grinding to a halt
        trainController.targetSpeed = 0.0
        SynthAudioEngine.shared.setSpeedRatio(0.0)
        
        // Shake the camera first — train jolts to a stop
        cameraController.shake(duration: 0.8, intensity: 14)
        
        // Begin dark red tinge → full black fade
        failOverlay.color = SKColor(red: 0.15, green: 0.0, blue: 0.0, alpha: 1.0)
        failOverlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.45, duration: 0.6),              // dark red tinge
            SKAction.colorize(with: .black, colorBlendFactor: 1.0, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2),              // full blackout
            SKAction.wait(forDuration: 0.4),
            SKAction.run {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        GameDirector.shared.changeState(to: .failed(chapter))
                    }
                }
            }
        ]))
    }
    
    /// Fades the screen to black upon successful chapter completion before transitioning state
    func triggerChapterSuccessFade(chapter: Chapter) {
        guard !isFadingToFail else { return }
        isFadingToFail = true
        
        trainController.targetSpeed = 0.0
        SynthAudioEngine.shared.setSpeedRatio(0.0)
        
        failOverlay.color = .black
        failOverlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 1.8),
            SKAction.wait(forDuration: 0.4),
            SKAction.run {
                DispatchQueue.main.async {
                    GameDirector.shared.completeChapter(chapter)
                }
            }
        ]))
    }
    
    private func updateFailFade(deltaTime: TimeInterval) {
        // No per-frame work needed — SKAction handles the overlay animation
    }

    private func updateCityApproach(deltaTime: TimeInterval) {
        guard activeChapter.targetDistance > 0 else { return }
        let progress = min(1.0, max(0.0, trainController.distanceTravelled / activeChapter.targetDistance))
        
        // Scale starts at 0.70 (very far away, small silhouette) and grows to 1.40 (close)
        // Opacity starts at 0.0 (completely hidden/hazy) and rises to 1.0 (fully visible)
        let targetScale = 0.70 + progress * 0.70
        let targetAlpha = progress
        
        if let cityNode = citySilhouette, !cityNode.isHidden {
            cityNode.alpha = cityNode.alpha + (targetAlpha - cityNode.alpha) * 0.08
            
            let currentScale = cityNode.xScale
            let newScale = currentScale + (targetScale - currentScale) * 0.08
            cityNode.setScale(newScale)
        }
        
        if let skylinesNode = citySkylinesNode, !skylinesNode.isHidden {
            skylinesNode.alpha = skylinesNode.alpha + (targetAlpha - skylinesNode.alpha) * 0.08
            
            let currentScale = skylinesNode.xScale
            let newScale = currentScale + (targetScale - currentScale) * 0.08
            skylinesNode.setScale(newScale)
        }
    }

    private func showChapter1Credits() {
        // Clean up any existing credit nodes first to prevent overlaps
        enumerateChildNodes(withName: "chapter_credits") { node, _ in
            node.removeFromParent()
        }
        
        let credits = [
            "Awan: Game Design",
            "Ebi: Illustrator",
            "Ridwan: Train lover"
        ]
        
        let startDelay: TimeInterval = 2.0
        let fadeDuration: TimeInterval = 1.0
        let stayDuration: TimeInterval = 2.5
        let stepDelay: TimeInterval = fadeDuration * 2.0 + stayDuration + 0.5 // 5.0s per credit
        
        for (index, text) in credits.enumerated() {
            let label = SKLabelNode(fontNamed: "HelveticaNeue-Light")
            label.name = "chapter_credits"
            label.text = text
            label.fontSize = 24
            label.fontColor = SKColor(white: 0.95, alpha: 1.0)
            label.position = CGPoint(x: size.width / 2.0, y: size.height - 200.0)
            label.zPosition = 90.0
            label.alpha = 0.0
            addChild(label)
            
            let delayTime = startDelay + Double(index) * stepDelay
            let sequence = SKAction.sequence([
                SKAction.wait(forDuration: delayTime),
                SKAction.fadeIn(withDuration: fadeDuration),
                SKAction.wait(forDuration: stayDuration),
                SKAction.fadeOut(withDuration: fadeDuration),
                SKAction.removeFromParent()
            ])
            
            label.run(sequence)
        }
    }

    private func createSkyGradientTexture(size: CGSize, topColor: SKColor, bottomColor: SKColor) -> SKTexture? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard let context = CGContext(data: nil, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        context.clear(CGRect(origin: .zero, size: size))
        
        let colors = [
            bottomColor.cgColor,
            topColor.cgColor
        ] as CFArray
        
        let locations: [CGFloat] = [0.0, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors, locations: locations) else {
            return nil
        }
        
        let startPoint = CGPoint(x: size.width / 2.0, y: 0.0)
        let endPoint = CGPoint(x: size.width / 2.0, y: size.height)
        
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: .drawsAfterEndLocation)
        
        guard let cgImage = context.makeImage() else { return nil }
        return SKTexture(cgImage: cgImage)
    }

    private func createVignetteTexture(size: CGSize) -> SKTexture? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard let context = CGContext(data: nil, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        context.clear(CGRect(origin: .zero, size: size))
        
        let colors = [
            CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0),
            CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0),
            CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.55),
            CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.98)
        ] as CFArray
        
        let locations: [CGFloat] = [0.0, 0.35, 0.75, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors, locations: locations) else {
            return nil
        }
        
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        let startRadius: CGFloat = 0.0
        let endRadius: CGFloat = sqrt(pow(size.width / 2.0, 2.0) + pow(size.height / 2.0, 2.0))
        
        context.drawRadialGradient(gradient,
                                   startCenter: center, startRadius: startRadius,
                                   endCenter: center, endRadius: endRadius,
                                   options: .drawsAfterEndLocation)
        
        guard let cgImage = context.makeImage() else { return nil }
        return SKTexture(cgImage: cgImage)
    }

    private func updateHorizonVisuals(deltaTime: TimeInterval) {
        // 1. Subtle Luftwaffe planes
        horizonPlaneTimer += deltaTime
        if horizonPlaneTimer >= nextPlaneTime {
            horizonPlaneTimer = 0.0
            nextPlaneTime = Double.random(in: 2.5...5.5) // much more frequent squadron fly-bys
            spawnSubtleHorizonPlane()
        }
        
        // 2. Anti-aircraft tracers
        horizonAATimer += deltaTime
        if horizonAATimer >= nextAATime {
            horizonAATimer = 0.0
            nextAATime = Double.random(in: 0.08...0.20) // extremely intense rate of AA fire
            triggerAAFire()
        }
        
        // 3. Spawning rising smoke plumes from the background city
        updateSmokePlumes(deltaTime: deltaTime)
    }
    
    private func spawnSubtleHorizonPlane() {
        let count = Int.random(in: 2...4) // squadrons of 2-4 planes
        let formationOffsetDir = Bool.random() ? 1.0 : -1.0
        
        for i in 0..<count {
            let plane = SKNode()
            plane.zPosition = 0.18
            
            // Stagger spawn delay or position
            let delay = Double(i) * Double.random(in: 0.4...0.8)
            let darkColor = SKColor(white: CGFloat.random(in: 0.10...0.16), alpha: CGFloat.random(in: 0.40...0.65))
            
            let body = SKSpriteNode(color: darkColor, size: CGSize(width: 15, height: 4))
            body.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            plane.addChild(body)
            
            let wing = SKSpriteNode(color: darkColor, size: CGSize(width: 4, height: 11))
            wing.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            wing.position = CGPoint(x: -2, y: 0)
            plane.addChild(wing)
            
            let startDelayAction = SKAction.wait(forDuration: delay)
            let startX: CGFloat = -40
            let startY = horizonY + CGFloat.random(in: 40...160) + (CGFloat(i) * 15.0 * formationOffsetDir)
            
            let setupPos = SKAction.run {
                plane.position = CGPoint(x: startX, y: startY)
            }
            
            let targetX = size.width + 40
            let duration = Double.random(in: 11.0...17.0)
            let move = SKAction.moveTo(x: targetX, duration: duration)
            let remove = SKAction.removeFromParent()
            
            plane.run(SKAction.sequence([
                startDelayAction,
                setupPos,
                move,
                remove
            ]))
            
            addChild(plane)
        }
    }
    
    private func triggerAAFire() {
        let shotsCount = Int.random(in: 2...5) // burst of 2-5 flak shots
        
        for i in 0..<shotsCount {
            let delay = Double(i) * Double.random(in: 0.05...0.15)
            
            let fireAction = SKAction.run { [weak self] in
                guard let self = self else { return }
                
                let centerX = self.size.width / 2
                let startX = centerX + CGFloat.random(in: -450...450)
                let startY = self.horizonY
                
                let targetX = startX + CGFloat.random(in: -120...120)
                let targetY = self.horizonY + CGFloat.random(in: 120...280)
                
                let bullet = SKSpriteNode(color: SKColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 0.95), size: CGSize(width: 3, height: 3))
                bullet.position = CGPoint(x: startX, y: startY)
                bullet.zPosition = 0.19
                self.addChild(bullet)
                
                let duration = Double.random(in: 0.20...0.35)
                let move = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: duration)
                
                let spawnExplosion = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.spawnFlakExplosion(at: CGPoint(x: targetX, y: targetY))
                }
                
                let remove = SKAction.removeFromParent()
                bullet.run(SKAction.sequence([move, spawnExplosion, remove]))
            }
            
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                fireAction
            ]))
        }
    }
    
    private func spawnFlakExplosion(at point: CGPoint) {
        let flakColor = SKColor(white: CGFloat.random(in: 0.14...0.22), alpha: CGFloat.random(in: 0.65...0.85))
        let flak = SKSpriteNode(color: flakColor, size: CGSize(width: 5, height: 5))
        flak.position = point
        flak.zPosition = 0.19
        addChild(flak)
        
        let expand = SKAction.scale(to: CGFloat.random(in: 2.2...3.5), duration: 0.35)
        let fade = SKAction.fadeOut(withDuration: 0.35)
        let group = SKAction.group([expand, fade])
        let remove = SKAction.removeFromParent()
        
        flak.run(SKAction.sequence([group, remove]))
    }
    
    private func updateWartimeSky(isWartime: Bool) {
        if isWartime {
            if childNode(withName: "wartimeHorizonGlow") == nil {
                // Warm copper glow at the horizon
                let glow = SKSpriteNode(color: SKColor(red: 0.85, green: 0.35, blue: 0.15, alpha: 0.45),
                                        size: CGSize(width: size.width * 2, height: 45))
                glow.name = "wartimeHorizonGlow"
                glow.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                glow.position = CGPoint(x: size.width / 2, y: horizonY)
                glow.zPosition = 0.02
                addChild(glow)
            }
            
            if childNode(withName: "wartimeClouds") == nil {
                let clouds = SKNode()
                clouds.name = "wartimeClouds"
                addChild(clouds)
                
                let cloudColors = [
                    SKColor(red: 0.20, green: 0.19, blue: 0.18, alpha: 0.5),
                    SKColor(red: 0.35, green: 0.33, blue: 0.31, alpha: 0.3),
                    SKColor(red: 0.24, green: 0.23, blue: 0.22, alpha: 0.4)
                ]
                
                let cloudHeights: [CGFloat] = [12, 18, 15]
                let cloudYOffsets: [CGFloat] = [15, 60, 110]
                
                for i in 0..<3 {
                    let strip = SKSpriteNode(color: cloudColors[i], size: CGSize(width: size.width * 2.5, height: cloudHeights[i]))
                    strip.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                    strip.position = CGPoint(x: size.width / 2, y: horizonY + cloudYOffsets[i])
                    strip.zPosition = 0.01
                    clouds.addChild(strip)
                }
            }
        } else {
            childNode(withName: "wartimeHorizonGlow")?.removeFromParent()
            childNode(withName: "wartimeClouds")?.removeFromParent()
        }
    }
    
    private func updateSmokePlumes(deltaTime: TimeInterval) {
        smokeSpawnTimer += deltaTime
        if smokeSpawnTimer >= 0.18 {
            smokeSpawnTimer = 0.0
            
            let sources: [CGFloat] = [
                size.width * 0.2,
                size.width * 0.32,
                size.width * 0.48,
                size.width * 0.65,
                size.width * 0.82
            ]
            let startX = sources.randomElement()!
            
            let sizeVal = CGFloat.random(in: 4...8)
            let puff = SKSpriteNode(color: SKColor(red: 0.18, green: 0.17, blue: 0.16, alpha: 0.6), size: CGSize(width: sizeVal, height: sizeVal))
            puff.position = CGPoint(x: startX, y: horizonY + CGFloat.random(in: 0...5))
            puff.zPosition = 0.12
            addChild(puff)
            
            let duration = Double.random(in: 5.5...9.0)
            let moveUp = SKAction.moveBy(x: -CGFloat.random(in: 35...80), y: CGFloat.random(in: 80...160), duration: duration)
            let scaleUp = SKAction.scale(to: CGFloat.random(in: 3.5...6.0), duration: duration)
            let fadeOut = SKAction.fadeOut(withDuration: duration)
            let remove = SKAction.removeFromParent()
            
            puff.run(SKAction.sequence([
                SKAction.group([moveUp, scaleUp, fadeOut]),
                remove
            ]))
        }
    }
}

// MARK: - Deterministic RNG (seeded, for reproducible skylines)

struct SeededRNG {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        // xorshift64 — fast, simple, reproducible
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
    
    /// Returns a value in [0, 1)
    mutating func nextFloat() -> CGFloat {
        return CGFloat(next() & 0xFFFF) / CGFloat(0xFFFF)
    }
}
