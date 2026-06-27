import SpriteKit

// MARK: - EnvironmentNode

final class EnvironmentNode: SKNode {
    
    // MARK: - Types
    
    private enum ObjectType: CaseIterable {
        case tree
        case tree1
        case tree2
        case tree3
        case things
        case telegraphPole
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
        
        update(deltaTime: 0.0, speed: 0.0, visualOffset: 0.0, chapter: .krotoszyn)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - Setup
    
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
                lateralOffset = CGFloat.random(in: 700...1000)  // lebih jauh ke pinggir
                baseScale = CGFloat.random(in: 0.4...0.6)       // lebih kecil
            case .mid:
                lateralOffset = CGFloat.random(in: 550...750)
                baseScale = CGFloat.random(in: 0.6...0.9)
            case .near:
                lateralOffset = CGFloat.random(in: 400...550)
                baseScale = CGFloat.random(in: 0.9...1.3)
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
    
    func update(deltaTime: TimeInterval, speed: Double, visualOffset: CGFloat, chapter: Chapter) {
        let chapterChanged = (chapter != activeChapter)
        self.activeChapter = chapter
        
        if chapterChanged {
            repopulateAllObjects(for: chapter)
        }
        
        let speedFactor = speed / 35.0
        let increment = speedFactor * deltaTime * 0.75
        
        for i in 0..<envObjects.count {
            var obj = envObjects[i]
            obj.progress += increment
            
            if obj.progress >= 1.0 {
                obj.progress -= 1.0
                obj.side = Bool.random() ? -1.0 : 1.0
                
                switch obj.layer {
                case .far:
                    obj.lateralOffset = CGFloat.random(in: 550...850)
                    obj.baseScale = CGFloat.random(in: 1.2...1.8)
                case .mid:
                    obj.lateralOffset = CGFloat.random(in: 420...600)
                    obj.baseScale = CGFloat.random(in: 2.0...2.8)
                case .near:
                    obj.lateralOffset = CGFloat.random(in: 280...400)
                    obj.baseScale = CGFloat.random(in: 3.0...4.5)
                }
                
                obj.node.removeAllChildren()
                let newType = selectRandomType(for: chapter)
                populateContainer(obj.node, type: newType, chapter: chapter)
            }
            
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
            let pool: [ObjectType] = [
                .tree, .tree1, .tree2, .tree3,
                .things, .telegraphPole, .haystack
            ]
            return pool.randomElement()!
            
        case .kozmin:
            let pool: [ObjectType] = [
                .tree, .tree1, .tree3,
                .boulder, .telegraphPole, .things
            ]
            return pool.randomElement()!
            
        case .jarocin:
            if Float.random(in: 0...1) < 0.20 { return .wreckedTank }
            let pool: [ObjectType] = [
                .tree, .tree2, .things, .telegraphPole
            ]
            return pool.randomElement()!
            
        case .konin:
            let pool: [ObjectType] = [
                .tree, .tree1, .tree2, .tree3,
                .floweringBush, .cherryBlossomTree, .things
            ]
            return pool.randomElement()!
            
        default:
            return ObjectType.allCases.randomElement()!
        }
    }
    
    // MARK: - Asset Helper
    
    private func makeSpriteFromAsset(_ name: String, height: CGFloat) -> SKSpriteNode {
        let tex = SKTexture(imageNamed: name)
        tex.filteringMode = .nearest
        let ratio = tex.size().width / tex.size().height
        let sprite = SKSpriteNode(texture: tex, size: CGSize(width: height * ratio, height: height))
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        return sprite
    }
    
    // MARK: - Object Building
    
    private func populateContainer(_ container: SKNode, type: ObjectType, chapter: Chapter) {
        let isWartime = (chapter == .jarocin)
        
        switch type {
            
        case .tree:
            let h = CGFloat.random(in: 80...120)
            let s = makeSpriteFromAsset("tree", height: h)
            if isWartime { s.color = SKColor(white: 0.4, alpha: 1.0); s.colorBlendFactor = 0.5 }
            container.addChild(s)
            
        case .tree1:
            let h = CGFloat.random(in: 75...115)
            let s = makeSpriteFromAsset("tree1", height: h)
            if isWartime { s.color = SKColor(white: 0.4, alpha: 1.0); s.colorBlendFactor = 0.5 }
            container.addChild(s)
            
        case .tree2:
            let h = CGFloat.random(in: 70...110)
            let s = makeSpriteFromAsset("tree2", height: h)
            if isWartime { s.color = SKColor(white: 0.4, alpha: 1.0); s.colorBlendFactor = 0.5 }
            container.addChild(s)
            
        case .tree3:
            let h = CGFloat.random(in: 80...120)
            let s = makeSpriteFromAsset("tree3", height: h)
            if isWartime { s.color = SKColor(white: 0.4, alpha: 1.0); s.colorBlendFactor = 0.5 }
            container.addChild(s)
            
        case .things:
            let h = CGFloat.random(in: 40...70)
            let s = makeSpriteFromAsset("things", height: h)
            if isWartime { s.color = SKColor(white: 0.35, alpha: 1.0); s.colorBlendFactor = 0.5 }
            container.addChild(s)
            
        case .telegraphPole:
            buildTelegraphPole(in: container, chapter: chapter)
            
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
    
    // MARK: - Telegraph Pole
    
    private func buildTelegraphPole(in container: SKNode, chapter: Chapter) {
        let poleWidth:  CGFloat = 6
        let poleHeight: CGFloat = CGFloat.random(in: 80...120)
        let woodColor = SKColor(red: 0.30, green: 0.22, blue: 0.12, alpha: 1.0)
        
        let pole = SKSpriteNode(color: woodColor,
                                size: CGSize(width: poleWidth, height: poleHeight))
        pole.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        pole.position = .zero
        container.addChild(pole)
        
        let crossarm = SKSpriteNode(color: woodColor,
                                    size: CGSize(width: CGFloat.random(in: 40...60), height: 5))
        crossarm.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        crossarm.position = CGPoint(x: 0, y: poleHeight - 8)
        container.addChild(crossarm)
        
        let cableColor = SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.7)
        let cable = SKSpriteNode(color: cableColor, size: CGSize(width: 100, height: 2))
        cable.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        cable.position = CGPoint(x: 0, y: poleHeight - 12)
        cable.zRotation = CGFloat.random(in: -0.06...0.06)
        container.addChild(cable)
        
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
    
    // MARK: - Wrecked Tank
    
    private func buildWreckedTank(in container: SKNode) {
        let tankColor  = SKColor(red: 0.15, green: 0.16, blue: 0.15, alpha: 1.0)
        let treadColor = SKColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        
        let leftTread = SKSpriteNode(color: treadColor, size: CGSize(width: 48, height: 6))
        leftTread.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        leftTread.position = CGPoint(x: 0, y: 0)
        container.addChild(leftTread)
        
        let body = SKSpriteNode(color: tankColor, size: CGSize(width: 40, height: 12))
        body.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        body.position = CGPoint(x: 0, y: 4)
        container.addChild(body)
        
        let turret = SKSpriteNode(color: tankColor, size: CGSize(width: 22, height: 8))
        turret.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        turret.position = CGPoint(x: -2, y: 16)
        container.addChild(turret)
        
        let barrel = SKSpriteNode(color: treadColor, size: CGSize(width: 24, height: 3))
        barrel.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        barrel.position = CGPoint(x: 4, y: 20)
        barrel.zRotation = CGFloat.random(in: -0.05...0.25)
        container.addChild(barrel)
        
        let hatch = SKSpriteNode(color: treadColor, size: CGSize(width: 6, height: 2))
        hatch.position = CGPoint(x: -6, y: 25)
        container.addChild(hatch)
    }
    
    // MARK: - Haystack
    
    private func buildHaystack(in container: SKNode) {
        let hayColor    = SKColor(red: 0.94, green: 0.82, blue: 0.41, alpha: 1.0)
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
    
    // MARK: - Boulder
    
    private func buildBoulder(in container: SKNode) {
        let stoneColor  = SKColor(red: 0.45, green: 0.46, blue: 0.48, alpha: 1.0)
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
    
    // MARK: - Flowering Bush
    
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
            SKColor(red: 0.98, green: 0.85, blue: 0.35, alpha: 0.95),
            SKColor(red: 0.98, green: 0.55, blue: 0.70, alpha: 0.95)
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
    
    // MARK: - Cherry Blossom Tree
    
    private func buildCherryBlossomTree(in container: SKNode) {
        let trunkWidth:  CGFloat = 8
        let trunkHeight: CGFloat = CGFloat.random(in: 42...55)
        let trunkColor = SKColor(red: 0.36, green: 0.25, blue: 0.15, alpha: 1.0)
        
        let trunk = SKSpriteNode(color: trunkColor, size: CGSize(width: trunkWidth, height: trunkHeight))
        trunk.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        trunk.position = .zero
        container.addChild(trunk)
        
        let crownColor  = SKColor(red: 0.98, green: 0.65, blue: 0.74, alpha: 1.0)
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
