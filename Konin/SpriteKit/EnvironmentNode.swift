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
        case deadBranch
        case treeEbi1
        case treeEbi2
        case treeEbi3
        case treeEbi4
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
                .bush, .telegraphPole, .farmhouse, .haystack,
                .treeEbi1, .treeEbi2, .treeEbi3, .treeEbi4
            ]
            return pool.randomElement()!
        case .kozmin:
            // Barren / Stormy / Rocky pool
            let pool: [ObjectType] = [
                .deciduousTreeDark, .pineTree, .bush,
                .telegraphPole, .farmhouse, .boulder,
                .deadBranch, .treeEbi1, .treeEbi2
            ]
            return pool.randomElement()!
        case .jarocin:
            // Warzone pool
            let pool: [ObjectType] = [
                .deciduousTreeDark, .deciduousTreeOlive, .pineTree,
                .bush, .telegraphPole, .farmhouse, .wreckedTank,
                .deadBranch, .treeEbi1, .treeEbi2, .treeEbi3, .treeEbi4
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
                .floweringBush, .treeEbi1, .treeEbi2, .treeEbi3, .treeEbi4
            ]
            return pool.randomElement()!
        default:
            return ObjectType.allCases.randomElement()!
        }
    }

    // MARK: - Object Building (SKSpriteNode only)

    private func populateContainer(_ container: SKNode, type: ObjectType, chapter: Chapter) {
        let isWartime = (chapter == .jarocin || chapter == .kozmin)

        switch type {
        case .deciduousTreeDark:
            buildDeciduousTree(in: container, imageName: "tree-oak", isWartime: isWartime)
        case .deciduousTreeOlive:
            buildDeciduousTree(in: container, imageName: "tree-birch", isWartime: isWartime)
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
        case .deadBranch:
            buildEnvironmentItem(in: container, imageName: "dead-branch", size: CGSize(width: 64, height: 64), isWartime: isWartime)
        case .treeEbi1:
            buildEnvironmentItem(in: container, imageName: "tree-1", size: CGSize(width: 128, height: 128), isWartime: isWartime)
        case .treeEbi2:
            buildEnvironmentItem(in: container, imageName: "tree-2", size: CGSize(width: 128, height: 128), isWartime: isWartime)
        case .treeEbi3:
            buildEnvironmentItem(in: container, imageName: "tree-3", size: CGSize(width: 128, height: 128), isWartime: isWartime)
        case .treeEbi4:
            buildEnvironmentItem(in: container, imageName: "tree-4", size: CGSize(width: 128, height: 128), isWartime: isWartime)
        }
    }

    private func buildEnvironmentItem(in container: SKNode, imageName: String, size: CGSize, isWartime: Bool) {
        let tex = SKTexture(imageNamed: imageName)
        tex.filteringMode = .nearest
        
        let sprite = SKSpriteNode(texture: tex, size: size)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        sprite.position = .zero
        
        if isWartime {
            // Tint tree to look burnt/dark in war/barren chapters
            sprite.color = SKColor(red: 0.15, green: 0.14, blue: 0.13, alpha: 1.0)
            sprite.colorBlendFactor = 0.85
        }
        
        container.addChild(sprite)
    }

    // MARK: Deciduous Tree

    // MARK: Deciduous Tree

    private func buildDeciduousTree(in container: SKNode, imageName: String, isWartime: Bool) {
        let tex = SKTexture(imageNamed: imageName)
        tex.filteringMode = .nearest
        
        let tree = SKSpriteNode(texture: tex)
        tree.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        tree.position = .zero
        
        if isWartime {
            // Tint tree to look burnt/dark
            tree.color = SKColor(red: 0.15, green: 0.14, blue: 0.13, alpha: 1.0)
            tree.colorBlendFactor = 0.85
        }
        
        container.addChild(tree)
    }

    // MARK: Pine Tree

    private func buildPineTree(in container: SKNode, isWartime: Bool) {
        let tex = SKTexture(imageNamed: "tree-pine")
        tex.filteringMode = .nearest
        
        let tree = SKSpriteNode(texture: tex)
        tree.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        tree.position = .zero
        
        if isWartime {
            // Tint tree to look burnt/dark
            tree.color = SKColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1.0)
            tree.colorBlendFactor = 0.85
        }
        
        container.addChild(tree)
    }

    // MARK: Bush

    private func buildBush(in container: SKNode, isWartime: Bool) {
        let tex = SKTexture(imageNamed: "bush-small")
        tex.filteringMode = .nearest
        
        let bush = SKSpriteNode(texture: tex)
        bush.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        bush.position = .zero
        
        if isWartime {
            bush.color = SKColor(red: 0.15, green: 0.13, blue: 0.12, alpha: 1.0)
            bush.colorBlendFactor = 0.8
        }
        
        container.addChild(bush)
    }

    // MARK: Telegraph Pole

    private func buildTelegraphPole(in container: SKNode, chapter: Chapter) {
        let isWartime = (chapter == .jarocin || chapter == .kozmin)
        let imageName = isWartime ? "telegraph-pole-broken" : "telegraph-pole"
        
        let poleTex = SKTexture(imageNamed: imageName)
        poleTex.filteringMode = .nearest
        
        let pole = SKSpriteNode(texture: poleTex)
        pole.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        pole.position = .zero
        container.addChild(pole)
        
        let poleHeight = pole.size.height

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
        let isDamaged = (chapter == .jarocin || chapter == .kozmin)
        let imageName = isDamaged ? "farmhouse-damaged" : "farmhouse-polish"
        
        let tex = SKTexture(imageNamed: imageName)
        tex.filteringMode = .nearest
        
        let house = SKSpriteNode(texture: tex)
        house.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        house.position = .zero
        
        if isDamaged {
            // Apply burnt color overlay
            house.color = SKColor(red: 0.25, green: 0.22, blue: 0.20, alpha: 1.0)
            house.colorBlendFactor = 0.55
        }
        
        container.addChild(house)
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
        let tex = SKTexture(imageNamed: "bush-flower")
        tex.filteringMode = .nearest
        
        let bush = SKSpriteNode(texture: tex)
        bush.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        bush.position = .zero
        container.addChild(bush)
    }

    // MARK: Cherry Blossom Tree

}

