import AppKit
@preconcurrency import SpriteKit

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

    private static let idleFrames = textures(prefix: "fighter_Idle_", range: 1...8)
    private static let walkFrames = textures(prefix: "fighter_walk_", range: 9...16)
    private static let runFrames = textures(prefix: "fighter_run_", range: 17...24)
    private static let jumpFrames = textures(prefix: "fighter_jump_", range: 43...47)
    private static let wallSlideFrames = [
        texture(named: "fighter_wallslide0083"),
        texture(named: "fighter_wallslide0084")
    ]
    private static let sitFrame = texture(named: "fighter_slide_0025")

    private let sprite = SKSpriteNode(texture: idleFrames[0])
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
        sprite.texture = texture(
            for: state.motion,
            time: localTime,
            verticalVelocity: verticalVelocity,
            reduceMotion: reduceMotion
        )
        sprite.xScale = state.facing.rawValue
    }

    private func texture(
        for motion: DesktopCharacterMotion,
        time: TimeInterval,
        verticalVelocity: CGFloat,
        reduceMotion: Bool
    ) -> SKTexture {
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
        in textures: [SKTexture],
        time: TimeInterval,
        framesPerSecond: Double,
        reduceMotion: Bool
    ) -> SKTexture {
        guard !reduceMotion else { return textures[0] }
        let index = Int(time * framesPerSecond) % textures.count
        return textures[index]
    }

    private func jumpFrame(time: TimeInterval, verticalVelocity: CGFloat) -> SKTexture {
        if time < 0.07 { return Self.jumpFrames[0] }
        if verticalVelocity > 350 { return Self.jumpFrames[1] }
        if verticalVelocity >= 0 { return Self.jumpFrames[2] }
        return Self.jumpFrames[3]
    }

    private static func textures(
        prefix: String,
        range: ClosedRange<Int>
    ) -> [SKTexture] {
        range.map { texture(named: prefix + String(format: "%04d", $0)) }
    }

    private static func texture(named name: String) -> SKTexture {
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "StickFigureCC0"
        ), let image = NSImage(contentsOf: url) else {
            fatalError("Missing bundled stick-figure frame: \(name).png")
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
}
