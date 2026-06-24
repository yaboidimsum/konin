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
        update(deltaTime: 0.0, speed: 0.0, visualOffset: 0.0)
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
            populateContainer(container, type: type)

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
    func update(deltaTime: TimeInterval, speed: Double, visualOffset: CGFloat) {
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
                let newType = ObjectType.allCases.randomElement()!
                populateContainer(obj.node, type: newType)
            }

            // Apply perspective calculation mirroring the rails
            let p = CGFloat(obj.progress)
            let scale = 0.15625 + (1.0 - 0.15625) * p
            let x = sceneCenterX + (obj.lateralOffset * obj.side + visualOffset) * scale
            let y = horizonY - (horizonY - 180.0) * pow(p, 2.0)

            obj.node.position = CGPoint(x: x, y: y)
            obj.node.setScale(scale * obj.baseScale)
            obj.node.alpha = min(1.0, p * 2.5) * obj.maxAlpha

            envObjects[i] = obj
        }
    }

    // MARK: - Object Building (SKSpriteNode only)

    private func populateContainer(_ container: SKNode, type: ObjectType) {
        switch type {
        case .deciduousTreeDark:
            buildDeciduousTree(in: container,
                               crownColor: SKColor(red: 0.17, green: 0.42, blue: 0.19, alpha: 1.0))
        case .deciduousTreeOlive:
            buildDeciduousTree(in: container,
                               crownColor: SKColor(red: 0.24, green: 0.46, blue: 0.22, alpha: 1.0))
        case .pineTree:
            buildPineTree(in: container)
        case .bush:
            buildBush(in: container)
        case .telegraphPole:
            buildTelegraphPole(in: container)
        case .farmhouse:
            buildFarmhouse(in: container)
        }
    }

    // MARK: Deciduous Tree

    private func buildDeciduousTree(in container: SKNode, crownColor: SKColor) {
        let trunkWidth:  CGFloat = 8
        let trunkHeight: CGFloat = CGFloat.random(in: 40...60)

        let trunk = SKSpriteNode(color: SKColor(red: 0.36, green: 0.25, blue: 0.15, alpha: 1.0),
                                 size: CGSize(width: trunkWidth, height: trunkHeight))
        trunk.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        trunk.position = .zero
        container.addChild(trunk)

        let crownWidth:  CGFloat = CGFloat.random(in: 35...50)
        let crownHeight: CGFloat = CGFloat.random(in: 30...45)

        let crown = SKSpriteNode(color: crownColor,
                                 size: CGSize(width: crownWidth, height: crownHeight))
        crown.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        crown.position = CGPoint(x: 0, y: trunkHeight - 4) // slight overlap
        container.addChild(crown)
    }

    // MARK: Pine Tree

    private func buildPineTree(in container: SKNode) {
        let trunkWidth:  CGFloat = 6
        let trunkHeight: CGFloat = CGFloat.random(in: 50...70)
        let pineGreen = SKColor(red: 0.11, green: 0.30, blue: 0.15, alpha: 1.0)

        let trunk = SKSpriteNode(color: SKColor(red: 0.36, green: 0.25, blue: 0.15, alpha: 1.0),
                                 size: CGSize(width: trunkWidth, height: trunkHeight))
        trunk.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        trunk.position = .zero
        container.addChild(trunk)

        // 3 stacked triangular layers built as rotated rectangles
        let layerSizes: [(width: CGFloat, height: CGFloat, yOffset: CGFloat)] = [
            (30, 18, trunkHeight * 0.35),  // bottom foliage layer
            (24, 16, trunkHeight * 0.55),  // middle foliage layer
            (16, 14, trunkHeight * 0.75)   // top foliage layer
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

    private func buildBush(in container: SKNode) {
        let bushWidth:  CGFloat = CGFloat.random(in: 30...50)
        let bushHeight: CGFloat = CGFloat.random(in: 15...25)
        let bushColor = SKColor(red: 0.22, green: 0.38, blue: 0.18, alpha: 1.0)

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

    private func buildTelegraphPole(in container: SKNode) {
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
    }

    // MARK: Farmhouse Silhouette

    private func buildFarmhouse(in container: SKNode) {
        let bodyWidth:  CGFloat = CGFloat.random(in: 40...60)
        let bodyHeight: CGFloat = CGFloat.random(in: 25...35)
        let houseColor = SKColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1.0)

        let body = SKSpriteNode(color: houseColor,
                                size: CGSize(width: bodyWidth, height: bodyHeight))
        body.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        body.position = .zero
        container.addChild(body)

        let roofWidth:  CGFloat = bodyWidth + 6
        let roofHeight: CGFloat = bodyHeight * 0.35

        let roofColor = SKColor(red: 0.10, green: 0.08, blue: 0.06, alpha: 1.0)
        let roof = SKSpriteNode(color: roofColor,
                                size: CGSize(width: roofWidth, height: roofHeight))
        roof.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        roof.position = CGPoint(x: 0, y: bodyHeight)
        container.addChild(roof)
    }
}
