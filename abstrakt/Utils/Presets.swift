import Foundation

struct PresetDefinition {
    let name: String
    let modifiers: [Modifier]
}

enum Presets {
    static var all: [PresetDefinition] = [
        staircase,
        circleBurst,
        organicScatter,
        spiral
    ]

    static var staircase: PresetDefinition {
        PresetDefinition(name: "Staircase", modifiers: [
            Modifier(type: .array, parameters: .array(
                ArrayParams(count: 10, offset: SIMD3<Float>(1.2, 1.2, 0), relative: false)
            )),
            Modifier(type: .rotationOffset, parameters: .rotationOffset(
                RotationOffsetParams(rotationPerStep: SIMD3<Float>(0, 10, 0))
            ))
        ])
    }

    static var circleBurst: PresetDefinition {
        PresetDefinition(name: "Circle Burst", modifiers: [
            Modifier(type: .radialArray, parameters: .radialArray(
                RadialArrayParams(count: 12, radius: 3.0, axis: .y, totalAngle: 360)
            ))
        ])
    }

    static var organicScatter: PresetDefinition {
        PresetDefinition(name: "Organic Scatter", modifiers: [
            Modifier(type: .array, parameters: .array(
                ArrayParams(count: 20, offset: SIMD3<Float>(0.6, 0, 0), relative: false)
            )),
            Modifier(type: .noiseOffset, parameters: .noiseOffset(
                NoiseOffsetParams(amplitude: SIMD3<Float>(0.5, 0.5, 0.5), seed: 42)
            )),
            Modifier(type: .scaleGradient, parameters: .scaleGradient(
                ScaleGradientParams(startScale: 1.0, endScale: 0.3)
            ))
        ])
    }

    static var spiral: PresetDefinition {
        PresetDefinition(name: "Spiral", modifiers: [
            Modifier(type: .radialArray, parameters: .radialArray(
                RadialArrayParams(count: 24, radius: 2.5, axis: .y, totalAngle: 720)
            )),
            Modifier(type: .scaleGradient, parameters: .scaleGradient(
                ScaleGradientParams(startScale: 1.0, endScale: 0.3)
            )),
            Modifier(type: .rotationOffset, parameters: .rotationOffset(
                RotationOffsetParams(rotationPerStep: SIMD3<Float>(15, 0, 0))
            ))
        ])
    }
}
