import SpriteKit

// MARK: - EnvironmentNode

/// Manages all scrolling environment elements alongside the train tracks.
///
/// Contains three parallax layers (far, mid, near) of pooled `SKSpriteNode`-based
/// objects that move forward following the 3D perspective scaling of the rails.
final class EnvironmentNode: SKNode {

    // MARK: - Types

    private enum ObjectType: CaseIterable {
        case deciduousTreeDark
        case deciduousTreeOlive
        case pineTree
        case bush
        case telegraphPole
        case farmhouse
        case wreckedTank
        case haystack
        case boulder
        case floweringBush
        case cherryBlossomTree
    }

    private enum Layer {
        case far, mid, near
    }

    private struct EnvironmentObject {
        let node: SKNode
        let layer: Layer
        var progress: Double
        var side: CGFloat
        var lateralOffset: CGFloat
        var baseScale: CGFloat
        let maxAlpha: CGFloat
    }

    // MARK: - Constants

    private let sceneWidth: CGFloat
    private let horizonY: CGFloat
    private let sceneCenterX: CGFloat
    
    // MARK: - State

    private var envObjects: [EnvironmentObject] = []
    private var activeChapter: Chapter = .krotoszyn

    // MARK: - Init

    init(sceneSize: CGSize, horizonY: CGFloat) {
        self.sceneWidth = sceneSize.width
        self.horizonY = horizonY
        self.sceneCenterX = sceneSize.width / 2.0
        super.init()

        setupLayer(layer: .far,  count: 8,  zPosition: 0.05, maxAlpha: 0.6)
        setupLayer(layer: .mid,  count: 10, zPosition: 0.58, maxAlpha: 0.85)
        setupLayer(layer: .near, count: 8,  zPosition: 3.12, maxAlpha: 1.0)

        // Initial layout
        update(deltaTime: 0.0, speed: 0.0, visualOffset: 0.0, chapter: .krotoszyn)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Setup Helper

    private func setupLayer(layer: Layer, count: Int, zPosition: CGFloat, maxAlpha: CGFloat) {
        for i in 0..<count {
            let container = SKNode()
            container.zPosition = zPosition
            addChild(container)

            let progress = Double(i) / Double(count)
            let side = Bool.random() ? -1.0 : 1.0

            var lateralOffset: CGFloat = 0.0
            var baseScale: CGFloat = 0.0

            switch layer {
            case .far:
                lateralOffset = CGFloat.random(in: 550...850)
                baseScale = CGFloat.random(in: 0.5...0.8)
            case .mid:
                lateralOffset = CGFloat.random(in: 420...600)
                baseScale = CGFloat.random(in: 0.9...1.3)
            case .near:
                lateralOffset = CGFloat.random(in: 280...400)
                baseScale = CGFloat.random(in: 1.4...2.0)
            }

            let type = ObjectType.allCases.randomElement()!
            populateContainer(container, type: type, chapter: .krotoszyn)

            let obj = EnvironmentObject(
                node: container,
                layer: layer,
                progress: progress,
                side: side,
                lateralOffset: lateralOffset,
                baseScale: baseScale,
                maxAlpha: maxAlpha
            )

            envObjects.append(obj)
        }
    }

    // MARK: - Public API

    /// Call every frame from the scene's `update(_:)`.
    /// - Parameters:
    ///   - deltaTime: Seconds elapsed since last frame.
    ///   - speed: The train's current speed.
    ///   - visualOffset: The lane offset shift from the train controller.
    ///   - chapter: The active chapter.
    func update(deltaTime: TimeInterval, speed: Double, visualOffset: CGFloat, chapter: Chapter) {
        let chapterChanged = (chapter != activeChapter)
        self.activeChapter = chapter

        if chapterChanged {
            repopulateAllObjects(for: chapter)
        }

        let speedFactor = speed / 35.0
        // Adjust the multiplier to sync environment scrolling speed with train speed
        let increment = speedFactor * deltaTime * 0.75

        for i in 0..<envObjects.count {
            var obj = envObjects[i]
            obj.progress += increment

            // Recycle when the object passes the viewport threshold (progress reaches/exceeds 1.0)
            if obj.progress >= 1.0 {
                obj.progress -= 1.0
                obj.side = Bool.random() ? -1.0 : 1.0

                switch obj.layer {
                case .far:
                    obj.lateralOffset = CGFloat.random(in: 550...850)
                    obj.baseScale = CGFloat.random(in: 0.5...0.8)
                case .mid:
                    obj.lateralOffset = CGFloat.random(in: 420...600)
                    obj.baseScale = CGFloat.random(in: 0.9...1.3)
                case .near:
                    obj.lateralOffset = CGFloat.random(in: 280...400)
                    obj.baseScale = CGFloat.random(in: 1.4...2.0)
                }

                obj.node.removeAllChildren()
                let newType = selectRandomType(for: chapter)
                populateContainer(obj.node, type: newType, chapter: chapter)
            }

            // Apply perspective calculation mirroring the rails
            let p = CGFloat(obj.progress)
            let scale = 0.33333 + (1.0 - 0.33333) * p
            let x = sceneCenterX + (obj.lateralOffset * obj.side + visualOffset) * scale
            let y = horizonY - (horizonY - 180.0) * pow(p, 2.0)

            obj.node.position = CGPoint(x: x, y: y)
            obj.node.setScale(scale * obj.baseScale)
            obj.node.alpha = min(1.0, p * 2.5) * obj.maxAlpha

            envObjects[i] = obj
        }
    }

    // MARK: - Helpers

    private func repopulateAllObjects(for chapter: Chapter) {
        for obj in envObjects {
            obj.node.removeAllChildren()
            let type = selectRandomType(for: chapter)
            populateContainer(obj.node, type: type, chapter: chapter)
        }
    }

    private func selectRandomType(for chapter: Chapter) -> ObjectType {
        switch chapter {
        case .krotoszyn:
            // Agricultural / Rural pool
            let pool: [ObjectType] = [
                .deciduousTreeDark, .deciduousTreeOlive, .pineTree,
                .bush, .telegraphPole, .farmhouse, .haystack
            ]
            return pool.randomElement()!
        case .kozmin:
            // Barren / Stormy / Rocky pool
            let pool: [ObjectType] = [
                .deciduousTreeDark, .pineTree, .bush,
                .telegraphPole, .farmhouse, .boulder
            ]
            return pool.randomElement()!
        case .jarocin:
            // Warzone pool
            let pool: [ObjectType] = [
                .deciduousTreeDark, .deciduousTreeOlive, .pineTree,
                .bush, .telegraphPole, .farmhouse, .wreckedTank
            ]
            if Float.random(in: 0...1) < 0.20 {
                return .wreckedTank
            }
            return pool.filter { $0 != .wreckedTank }.randomElement()!
        case .konin:
            // Dreamy / Peaceful pool
            let pool: [ObjectType] = [
                .deciduousTreeDark, .deciduousTreeOlive, .pineTree,
                .bush, .telegraphPole, .farmhouse,
                .cherryBlossomTree, .floweringBush
            ]
            return pool.randomElement()!
        default:
            return ObjectType.allCases.randomElement()!
        }
    }

    // MARK: - Object Building (SKSpriteNode only)

    private func populateContainer(_ container: SKNode, type: ObjectType, chapter: Chapter) {
        let isWartime = (chapter == .jarocin)

        switch type {
        case .deciduousTreeDark:
            let color = isWartime ? SKColor(red: 0.16, green: 0.15, blue: 0.14, alpha: 1.0) : SKColor(red: 0.17, green: 0.42, blue: 0.19, alpha: 1.0)
            buildDeciduousTree(in: container, crownColor: color, isWartime: isWartime)
        case .deciduousTreeOlive:
            let color = isWartime ? SKColor(red: 0.22, green: 0.20, blue: 0.18, alpha: 1.0) : SKColor(red: 0.24, green: 0.46, blue: 0.22, alpha: 1.0)
            buildDeciduousTree(in: container, crownColor: color, isWartime: isWartime)
        case .pineTree:
            buildPineTree(in: container, isWartime: isWartime)
        case .bush:
            buildBush(in: container, isWartime: isWartime)
        case .telegraphPole:
            buildTelegraphPole(in: container, chapter: chapter)
        case .farmhouse:
            buildFarmhouse(in: container, isWartime: isWartime, chapter: chapter)
        case .wreckedTank:
            buildWreckedTank(in: container)
        case .haystack:
            buildHaystack(in: container)
        case .boulder:
            buildBoulder(in: container)
        case .floweringBush:
            buildFloweringBush(in: container)
        case .cherryBlossomTree:
            buildCherryBlossomTree(in: container)
        }
    }

    // MARK: Deciduous Tree

    private func buildDeciduousTree(in container: SKNode, crownColor: SKColor, isWartime: Bool) {
        let trunkWidth:  CGFloat = 8
        let trunkHeight: CGFloat = CGFloat.random(in: 40...60)
        let trunkColor = isWartime ? SKColor(red: 0.18, green: 0.15, blue: 0.12, alpha: 1.0) : SKColor(red: 0.36, green: 0.25, blue: 0.15, alpha: 1.0)

        let trunk = SKSpriteNode(color: trunkColor,
                                 size: CGSize(width: trunkWidth, height: trunkHeight))
        trunk.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        trunk.position = .zero
        container.addChild(trunk)

        let crownWidth:  CGFloat = isWartime ? CGFloat.random(in: 20...30) : CGFloat.random(in: 35...50)
        let crownHeight: CGFloat = isWartime ? CGFloat.random(in: 18...28) : CGFloat.random(in: 30...45)

        let crown = SKSpriteNode(color: crownColor,
                                 size: CGSize(width: crownWidth, height: crownHeight))
        crown.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        crown.position = CGPoint(x: 0, y: trunkHeight - 4) // slight overlap
        container.addChild(crown)

        if isWartime {
            // Add a dead bare branch on the side during wartime
            let branch = SKSpriteNode(color: trunkColor, size: CGSize(width: 14, height: 4))
            branch.anchorPoint = CGPoint(x: 0.0, y: 0.5)
            branch.position = CGPoint(x: 2, y: trunkHeight * 0.6)
            branch.zRotation = .pi / 6
            container.addChild(branch)
        }
    }

    // MARK: Pine Tree

    private func buildPineTree(in container: SKNode, isWartime: Bool) {
        let trunkWidth:  CGFloat = 6
        let trunkHeight: CGFloat = CGFloat.random(in: 50...70)
        let pineGreen = isWartime ? SKColor(red: 0.15, green: 0.14, blue: 0.13, alpha: 1.0) : SKColor(red: 0.11, green: 0.30, blue: 0.15, alpha: 1.0)
        let trunkColor = isWartime ? SKColor(red: 0.18, green: 0.15, blue: 0.12, alpha: 1.0) : SKColor(red: 0.36, green: 0.25, blue: 0.15, alpha: 1.0)

        let trunk = SKSpriteNode(color: trunkColor,
                                 size: CGSize(width: trunkWidth, height: trunkHeight))
        trunk.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        trunk.position = .zero
        container.addChild(trunk)

        // 3 stacked triangular layers built as rotated rectangles
        let layerSizes: [(width: CGFloat, height: CGFloat, yOffset: CGFloat)] = [
            (isWartime ? 18 : 30, isWartime ? 10 : 18, trunkHeight * 0.35),  // bottom foliage layer
            (isWartime ? 14 : 24, isWartime ? 9 : 16, trunkHeight * 0.55),  // middle foliage layer
            (isWartime ? 10 : 16, isWartime ? 8 : 14, trunkHeight * 0.75)   // top foliage layer
        ]

        for info in layerSizes {
            let layer = SKSpriteNode(color: pineGreen,
                                     size: CGSize(width: info.width, height: info.height))
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            layer.position = CGPoint(x: 0, y: info.yOffset)
            container.addChild(layer)

            let sideW: CGFloat = info.width * 0.35
            let sideH: CGFloat = info.height * 0.6

            let leftSide = SKSpriteNode(color: pineGreen,
                                        size: CGSize(width: sideW, height: sideH))
            leftSide.anchorPoint = CGPoint(x: 1.0, y: 0.0)
            leftSide.position = CGPoint(x: -info.width * 0.15, y: info.yOffset)
            leftSide.zRotation = .pi / 8
            container.addChild(leftSide)

            let rightSide = SKSpriteNode(color: pineGreen,
                                         size: CGSize(width: sideW, height: sideH))
            rightSide.anchorPoint = CGPoint(x: 0.0, y: 0.0)
            rightSide.position = CGPoint(x: info.width * 0.15, y: info.yOffset)
            rightSide.zRotation = -.pi / 8
            container.addChild(rightSide)
        }
    }

    // MARK: Bush

    private func buildBush(in container: SKNode, isWartime: Bool) {
        let bushWidth:  CGFloat = CGFloat.random(in: 30...50)
        let bushHeight: CGFloat = CGFloat.random(in: 15...25)
        let bushColor = isWartime ? SKColor(red: 0.15, green: 0.13, blue: 0.12, alpha: 1.0) : SKColor(red: 0.22, green: 0.38, blue: 0.18, alpha: 1.0)

        let body = SKSpriteNode(color: bushColor,
                                size: CGSize(width: bushWidth, height: bushHeight))
        body.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        body.position = .zero
        container.addChild(body)

        let bumpWidth:  CGFloat = bushWidth * 0.6
        let bumpHeight: CGFloat = bushHeight * 0.5

        let bump = SKSpriteNode(color: bushColor,
                                size: CGSize(width: bumpWidth, height: bumpHeight))
        bump.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        bump.position = CGPoint(x: 0, y: bushHeight - 2)
        container.addChild(bump)
    }

    // MARK: Telegraph Pole

    private func buildTelegraphPole(in container: SKNode, chapter: Chapter) {
        let poleWidth:  CGFloat = 6
        let poleHeight: CGFloat = CGFloat.random(in: 80...120)
        let woodColor = SKColor(red: 0.30, green: 0.22, blue: 0.12, alpha: 1.0)

        let pole = SKSpriteNode(color: woodColor,
                                size: CGSize(width: poleWidth, height: poleHeight))
        pole.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        pole.position = .zero
        container.addChild(pole)

        let crossarmWidth:  CGFloat = CGFloat.random(in: 40...60)
        let crossarmHeight: CGFloat = 5.0

        let crossarm = SKSpriteNode(color: woodColor,
                                    size: CGSize(width: crossarmWidth, height: crossarmHeight))
        crossarm.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        crossarm.position = CGPoint(x: 0, y: poleHeight - 8)
        container.addChild(crossarm)

        let cableColor = SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.7)
        let cable = SKSpriteNode(color: cableColor,
                                 size: CGSize(width: 100, height: 2))
        cable.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        cable.position = CGPoint(x: 0, y: poleHeight - 12)
        cable.zRotation = CGFloat.random(in: -0.06...0.06)
        container.addChild(cable)

        // Add climbing vines in Konin
        if chapter == .konin {
            let vineColor = SKColor(red: 0.15, green: 0.38, blue: 0.12, alpha: 0.85)
            for i in 0..<3 {
                let leaf = SKSpriteNode(color: vineColor, size: CGSize(width: 8, height: 4))
                leaf.anchorPoint = CGPoint(x: 0.0, y: 0.5)
                leaf.position = CGPoint(x: 2, y: poleHeight * (0.2 + Double(i) * 0.2))
                leaf.zRotation = .pi / 4 * (i % 2 == 0 ? 1.0 : -1.0)
                container.addChild(leaf)
            }
        }
    }

    // MARK: Farmhouse Silhouette

    private func buildFarmhouse(in container: SKNode, isWartime: Bool, chapter: Chapter) {
        let bodyWidth:  CGFloat = CGFloat.random(in: 40...60)
        let bodyHeight: CGFloat = CGFloat.random(in: 25...35)
        
        let houseColor: SKColor
        let roofColor: SKColor
        
        if isWartime {
            houseColor = SKColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0)
            roofColor = SKColor(red: 0.06, green: 0.05, blue: 0.04, alpha: 1.0)
        } else if chapter == .kozmin {
            houseColor = SKColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1.0)
            roofColor = SKColor(red: 0.17, green: 0.20, blue: 0.24, alpha: 1.0) // slate blue roof
        } else if chapter == .konin {
            houseColor = SKColor(red: 0.14, green: 0.12, blue: 0.10, alpha: 1.0)
            roofColor = SKColor(red: 0.80, green: 0.35, blue: 0.25, alpha: 1.0) // terracotta roof
        } else {
            houseColor = SKColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1.0)
            roofColor = SKColor(red: 0.65, green: 0.20, blue: 0.15, alpha: 1.0) // standard red roof
        }

        let body = SKSpriteNode(color: houseColor,
                                size: CGSize(width: bodyWidth, height: bodyHeight))
        body.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        body.position = .zero
        container.addChild(body)

        let roofWidth:  CGFloat = bodyWidth + 6
        let roofHeight: CGFloat = bodyHeight * 0.35

        let roof = SKSpriteNode(color: roofColor,
                                size: CGSize(width: roofWidth, height: roofHeight))
        roof.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        roof.position = CGPoint(x: 0, y: bodyHeight)
        container.addChild(roof)

        if isWartime {
            let chimney = SKSpriteNode(color: roofColor, size: CGSize(width: 6, height: 10))
            chimney.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            chimney.position = CGPoint(x: bodyWidth * 0.25, y: bodyHeight)
            container.addChild(chimney)
        }
    }

    // MARK: Wrecked Tank

    private func buildWreckedTank(in container: SKNode) {
        let tankColor = SKColor(red: 0.15, green: 0.16, blue: 0.15, alpha: 1.0)
        let treadColor = SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)

        // Tracks / Treads (Base)
        let leftTread = SKSpriteNode(color: treadColor, size: CGSize(width: 48, height: 6))
        leftTread.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        leftTread.position = CGPoint(x: 0, y: 0)
        container.addChild(leftTread)

        // Tank Body
        let body = SKSpriteNode(color: tankColor, size: CGSize(width: 40, height: 12))
        body.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        body.position = CGPoint(x: 0, y: 4)
        container.addChild(body)

        // Turret
        let turret = SKSpriteNode(color: tankColor, size: CGSize(width: 22, height: 8))
        turret.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        turret.position = CGPoint(x: -2, y: 16)
        container.addChild(turret)

        // Barrel
        let barrel = SKSpriteNode(color: treadColor, size: CGSize(width: 24, height: 3))
        barrel.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        barrel.position = CGPoint(x: 4, y: 20)
        barrel.zRotation = CGFloat.random(in: -0.05...0.25) // pointed slightly up
        container.addChild(barrel)

        // Hatch detail
        let hatch = SKSpriteNode(color: treadColor, size: CGSize(width: 6, height: 2))
        hatch.position = CGPoint(x: -6, y: 25)
        container.addChild(hatch)
    }

    // MARK: Haystack

    private func buildHaystack(in container: SKNode) {
        let hayColor = SKColor(red: 0.94, green: 0.82, blue: 0.41, alpha: 1.0)
        let shadowColor = SKColor(red: 0.76, green: 0.62, blue: 0.22, alpha: 1.0)

        let base = SKSpriteNode(color: shadowColor, size: CGSize(width: 44, height: 6))
        base.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        base.position = .zero
        container.addChild(base)

        let dome = SKSpriteNode(color: hayColor, size: CGSize(width: 36, height: 26))
        dome.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        dome.position = CGPoint(x: 0, y: 4)
        container.addChild(dome)

        let top = SKSpriteNode(color: hayColor, size: CGSize(width: 14, height: 10))
        top.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        top.position = CGPoint(x: 0, y: 28)
        container.addChild(top)
    }

    // MARK: Boulder

    private func buildBoulder(in container: SKNode) {
        let stoneColor = SKColor(red: 0.45, green: 0.46, blue: 0.48, alpha: 1.0)
        let shadowColor = SKColor(red: 0.28, green: 0.29, blue: 0.31, alpha: 1.0)

        let base = SKSpriteNode(color: shadowColor, size: CGSize(width: 46, height: 14))
        base.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        base.position = .zero
        container.addChild(base)

        let top = SKSpriteNode(color: stoneColor, size: CGSize(width: 28, height: 18))
        top.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        top.position = CGPoint(x: 4, y: 8)
        container.addChild(top)

        let side = SKSpriteNode(color: shadowColor, size: CGSize(width: 16, height: 12))
        side.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        side.position = CGPoint(x: -12, y: 4)
        container.addChild(side)
    }

    // MARK: Flowering Bush

    private func buildFloweringBush(in container: SKNode) {
        let bushWidth:  CGFloat = CGFloat.random(in: 32...48)
        let bushHeight: CGFloat = CGFloat.random(in: 16...24)
        let bushColor = SKColor(red: 0.22, green: 0.44, blue: 0.20, alpha: 1.0)

        let body = SKSpriteNode(color: bushColor, size: CGSize(width: bushWidth, height: bushHeight))
        body.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        body.position = .zero
        container.addChild(body)

        let bump = SKSpriteNode(color: bushColor, size: CGSize(width: bushWidth * 0.6, height: bushHeight * 0.5))
        bump.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        bump.position = CGPoint(x: 0, y: bushHeight - 2)
        container.addChild(bump)

        let flowerColors = [
            SKColor(red: 0.98, green: 0.85, blue: 0.35, alpha: 0.95), // yellow
            SKColor(red: 0.98, green: 0.55, blue: 0.70, alpha: 0.95)  // pink
        ]

        for i in 0..<5 {
            let color = flowerColors.randomElement()!
            let dot = SKSpriteNode(color: color, size: CGSize(width: 3, height: 3))
            let rx = CGFloat((i - 2)) * (bushWidth * 0.16) + CGFloat.random(in: -3...3)
            let ry = CGFloat.random(in: 4...16)
            dot.position = CGPoint(x: rx, y: ry)
            container.addChild(dot)
        }
    }

    // MARK: Cherry Blossom Tree

    private func buildCherryBlossomTree(in container: SKNode) {
        let trunkWidth:  CGFloat = 8
        let trunkHeight: CGFloat = CGFloat.random(in: 42...55)
        let trunkColor = SKColor(red: 0.36, green: 0.25, blue: 0.15, alpha: 1.0)

        let trunk = SKSpriteNode(color: trunkColor, size: CGSize(width: trunkWidth, height: trunkHeight))
        trunk.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        trunk.position = .zero
        container.addChild(trunk)

        let crownColor = SKColor(red: 0.98, green: 0.65, blue: 0.74, alpha: 1.0)
        let shadowColor = SKColor(red: 0.92, green: 0.50, blue: 0.62, alpha: 1.0)

        let crownWidth:  CGFloat = CGFloat.random(in: 38...48)
        let crownHeight: CGFloat = CGFloat.random(in: 32...42)

        let shadowCrown = SKSpriteNode(color: shadowColor, size: CGSize(width: crownWidth, height: crownHeight))
        shadowCrown.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        shadowCrown.position = CGPoint(x: 0, y: trunkHeight - 6)
        container.addChild(shadowCrown)

        let mainCrown = SKSpriteNode(color: crownColor, size: CGSize(width: crownWidth * 0.85, height: crownHeight * 0.85))
        mainCrown.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        mainCrown.position = CGPoint(x: 2, y: trunkHeight - 2)
        container.addChild(mainCrown)
    }
}

