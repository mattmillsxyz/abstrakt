import Foundation

// MARK: - ModifierEngine

/// Pure functional modifier pipeline. Stateless — same inputs always produce same outputs.
enum ModifierEngine {
    static let instanceCap = 1000

    /// Entry point. Starts from a single identity instance and threads it through each enabled modifier.
    static func apply(object: SceneObject) -> [Instance] {
        var instances: [Instance] = [.identity]

        for modifier in object.modifiers where modifier.isEnabled {
            instances = step(modifier, instances: instances, object: object)
            if instances.count > instanceCap {
                instances = Array(instances.prefix(instanceCap))
            }
        }

        return instances
    }

    private static func step(
        _ modifier: Modifier,
        instances: [Instance],
        object: SceneObject
    ) -> [Instance] {
        switch modifier.parameters {
        case .array(let p):          return applyArray(p, to: instances)
        case .radialArray(let p):    return applyRadialArray(p, to: instances)
        case .noiseOffset(let p):    return applyNoiseOffset(p, to: instances, objectSeed: object.seed)
        case .scaleGradient(let p):  return applyScaleGradient(p, to: instances)
        case .rotationOffset(let p): return applyRotationOffset(p, to: instances)
        }
    }

    // MARK: Array

    private static func applyArray(_ p: ArrayParams, to instances: [Instance]) -> [Instance] {
        var result: [Instance] = []
        result.reserveCapacity(min(instances.count * p.count, instanceCap))
        for base in instances {
            for i in 0..<max(1, p.count) {
                var inst = base
                let fi = Float(i)
                if p.relative {
                    inst.position += p.offset * fi * base.scale
                } else {
                    inst.position += p.offset * fi
                }
                result.append(inst)
            }
        }
        return result
    }

    // MARK: Radial Array

    private static func applyRadialArray(_ p: RadialArrayParams, to instances: [Instance]) -> [Instance] {
        var result: [Instance] = []
        result.reserveCapacity(min(instances.count * p.count, instanceCap))
        let totalRad = p.totalAngle * .pi / 180.0

        for base in instances {
            for i in 0..<max(1, p.count) {
                let angle = p.count > 1
                    ? totalRad * Float(i) / Float(p.count)
                    : 0.0
                var inst = base
                switch p.axis {
                case .y:
                    inst.position.x = base.position.x + p.radius * sin(angle)
                    inst.position.z = base.position.z + p.radius * cos(angle)
                case .x:
                    inst.position.y = base.position.y + p.radius * sin(angle)
                    inst.position.z = base.position.z + p.radius * cos(angle)
                case .z:
                    inst.position.x = base.position.x + p.radius * sin(angle)
                    inst.position.y = base.position.y + p.radius * cos(angle)
                }
                result.append(inst)
            }
        }
        return result
    }

    // MARK: Noise Offset (deterministic via seeded LCG)

    private static func applyNoiseOffset(
        _ p: NoiseOffsetParams,
        to instances: [Instance],
        objectSeed: Int
    ) -> [Instance] {
        // Combine object seed and modifier seed for determinism
        let combined = UInt64(bitPattern: Int64(truncatingIfNeeded: objectSeed))
                     &+ UInt64(bitPattern: Int64(truncatingIfNeeded: p.seed))
        var rng = SeededRNG(seed: combined == 0 ? 1 : combined)

        return instances.map { inst in
            var copy = inst
            copy.position.x += Float(rng.nextDouble() * 2.0 - 1.0) * p.amplitude.x
            copy.position.y += Float(rng.nextDouble() * 2.0 - 1.0) * p.amplitude.y
            copy.position.z += Float(rng.nextDouble() * 2.0 - 1.0) * p.amplitude.z
            return copy
        }
    }

    // MARK: Scale Gradient

    private static func applyScaleGradient(_ p: ScaleGradientParams, to instances: [Instance]) -> [Instance] {
        let n = instances.count
        return instances.enumerated().map { idx, inst in
            let t = n > 1 ? Float(idx) / Float(n - 1) : 0
            let s = p.startScale + (p.endScale - p.startScale) * t
            var copy = inst
            copy.scale = inst.scale * s
            return copy
        }
    }

    // MARK: Rotation Offset

    private static func applyRotationOffset(_ p: RotationOffsetParams, to instances: [Instance]) -> [Instance] {
        return instances.enumerated().map { idx, inst in
            var copy = inst
            copy.rotation += p.rotationPerStep * Float(idx)
            return copy
        }
    }
}

// MARK: - SeededRNG (Linear Congruential Generator)

/// Deterministic PRNG. Same seed always produces the same sequence.
struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 6364136223846793005 : seed
    }

    mutating func next() -> UInt64 {
        // Knuth's MMIX LCG constants
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    /// Returns a Double in [0, 1)
    mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
