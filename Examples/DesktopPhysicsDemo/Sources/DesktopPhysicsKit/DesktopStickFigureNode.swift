import AppKit
import ImageIO
@preconcurrency import SpriteKit

struct DesktopPaintedAlphaMask: Sendable {
    static let defaultAlphaThreshold: UInt8 = 26

    let width: Int
    let height: Int
    private let alpha: [UInt8]

    init(cgImage: CGImage) {
        width = cgImage.width
        height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            alpha = []
            return
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        alpha = stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
    }

    func isPainted(
        normalizedPoint: CGPoint,
        alphaThreshold: UInt8 = defaultAlphaThreshold
    ) -> Bool {
        guard width > 0,
              height > 0,
              alpha.count == width * height,
              normalizedPoint.x >= 0,
              normalizedPoint.x <= 1,
              normalizedPoint.y >= 0,
              normalizedPoint.y <= 1 else {
            return false
        }
        let x = min(width - 1, Int(normalizedPoint.x * CGFloat(width)))
        let y = min(
            height - 1,
            Int((1 - normalizedPoint.y) * CGFloat(height))
        )
        return alpha[y * width + x] >= alphaThreshold
    }
}

enum DesktopCharacterMotion: String, CaseIterable, Equatable, Sendable {
    case idle
    case walk
    case run
    case jump
    case wallSlide
    case sit
}

enum DesktopCharacterFacing: CGFloat, Equatable, Sendable {
    case left = -1
    case right = 1
}

struct DesktopCharacterAnimationState: Equatable, Sendable {
    let motion: DesktopCharacterMotion
    let facing: DesktopCharacterFacing

    static func resolve(
        grounded: Bool,
        wallSliding: Bool,
        sitting: Bool,
        horizontalSpeed: CGFloat,
        running: Bool,
        facing: DesktopCharacterFacing
    ) -> Self {
        let motion: DesktopCharacterMotion
        if grounded, sitting {
            motion = .sit
        } else if !grounded, wallSliding {
            motion = .wallSlide
        } else if !grounded {
            motion = .jump
        } else if abs(horizontalSpeed) < 24 {
            motion = .idle
        } else if running {
            motion = .run
        } else {
            motion = .walk
        }
        return Self(motion: motion, facing: facing)
    }
}

@MainActor
final class DesktopStickFigureNode: SKNode {
    static let collisionSize = CGSize(width: 34, height: 86)

    private struct Frame {
        let asset: String
        let texture: SKTexture
        let mask: DesktopPaintedAlphaMask
    }

    private static let idleFrames = textures(prefix: "fighter_Idle_", range: 1...8)
    private static let walkFrames = textures(prefix: "fighter_walk_", range: 9...16)
    private static let runFrames = textures(prefix: "fighter_run_", range: 17...24)
    private static let jumpFrames = textures(prefix: "fighter_jump_", range: 43...47)
    private static let wallSlideFrames = [
        frame(named: "fighter_wallslide0083"),
        frame(named: "fighter_wallslide0084")
    ]
    private static let sitFrame = frame(named: "fighter_slide_0025")

    private let sprite = SKSpriteNode(texture: idleFrames[0].texture)
    private var currentFrame = idleFrames[0]
    var currentAsset: String { currentFrame.asset }
    private var stateStartedAt: TimeInterval = 0

    private(set) var animationState = DesktopCharacterAnimationState(
        motion: .idle,
        facing: .right
    )

    override init() {
        super.init()
        sprite.size = CGSize(width: 270, height: 270)
        sprite.position.y = 22
        addChild(sprite)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func update(
        state: DesktopCharacterAnimationState,
        time: TimeInterval,
        delta _: TimeInterval,
        verticalVelocity: CGFloat,
        reduceMotion: Bool
    ) {
        if state != animationState {
            animationState = state
            stateStartedAt = time
        }

        let localTime = max(0, time - stateStartedAt)
        currentFrame = frame(
            for: state.motion,
            time: localTime,
            verticalVelocity: verticalVelocity,
            reduceMotion: reduceMotion
        )
        sprite.texture = currentFrame.texture
        sprite.xScale = state.facing.rawValue
    }

    func isPainted(at point: CGPoint, in coordinateNode: SKNode) -> Bool {
        guard sprite.isHidden == false,
              sprite.alpha > 0,
              sprite.size.width > 0,
              sprite.size.height > 0 else {
            return false
        }
        let local = sprite.convert(point, from: coordinateNode)
        let normalized = CGPoint(
            x: local.x / sprite.size.width + sprite.anchorPoint.x,
            y: local.y / sprite.size.height + sprite.anchorPoint.y
        )
        return currentFrame.mask.isPainted(normalizedPoint: normalized)
    }

    private func frame(
        for motion: DesktopCharacterMotion,
        time: TimeInterval,
        verticalVelocity: CGFloat,
        reduceMotion: Bool
    ) -> Frame {
        switch motion {
        case .idle:
            loopFrame(in: Self.idleFrames, time: time, framesPerSecond: 8, reduceMotion: reduceMotion)
        case .walk:
            loopFrame(in: Self.walkFrames, time: time, framesPerSecond: 11, reduceMotion: reduceMotion)
        case .run:
            loopFrame(in: Self.runFrames, time: time, framesPerSecond: 15, reduceMotion: reduceMotion)
        case .jump:
            jumpFrame(time: time, verticalVelocity: verticalVelocity)
        case .wallSlide:
            loopFrame(
                in: Self.wallSlideFrames,
                time: time,
                framesPerSecond: 5,
                reduceMotion: reduceMotion
            )
        case .sit:
            Self.sitFrame
        }
    }

    private func loopFrame(
        in textures: [Frame],
        time: TimeInterval,
        framesPerSecond: Double,
        reduceMotion: Bool
    ) -> Frame {
        guard !reduceMotion else { return textures[0] }
        let index = Int(time * framesPerSecond) % textures.count
        return textures[index]
    }

    private func jumpFrame(time: TimeInterval, verticalVelocity: CGFloat) -> Frame {
        if time < 0.07 { return Self.jumpFrames[0] }
        if verticalVelocity > 350 { return Self.jumpFrames[1] }
        if verticalVelocity >= 0 { return Self.jumpFrames[2] }
        return Self.jumpFrames[3]
    }

    private static func textures(
        prefix: String,
        range: ClosedRange<Int>
    ) -> [Frame] {
        range.map { frame(named: prefix + String(format: "%04d", $0)) }
    }

    private static func frame(named name: String) -> Frame {
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "StickFigureCC0"
        ), let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            fatalError("Missing bundled stick-figure frame: \(name).png")
        }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        return Frame(
            asset: name + ".png",
            texture: texture,
            mask: DesktopPaintedAlphaMask(cgImage: image)
        )
    }
}
