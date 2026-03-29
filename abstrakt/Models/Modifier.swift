import Foundation

// MARK: - Radial Array Axis

enum RadialAxis: String, CaseIterable, Equatable {
    case x = "X"
    case y = "Y"
    case z = "Z"
}

// MARK: - Parameter Structs

struct ArrayParams: Equatable {
    var count: Int = 5
    var offset: SIMD3<Float> = SIMD3<Float>(1.2, 0, 0)
    var relative: Bool = false
}

struct RadialArrayParams: Equatable {
    var count: Int = 8
    var radius: Float = 3.0
    var axis: RadialAxis = .y
    var totalAngle: Float = 360.0
}

struct NoiseOffsetParams: Equatable {
    var amplitude: SIMD3<Float> = SIMD3<Float>(0.5, 0.5, 0.5)
    var seed: Int = 42
}

struct ScaleGradientParams: Equatable {
    var startScale: Float = 1.0
    var endScale: Float = 0.2
}

struct RotationOffsetParams: Equatable {
    var rotationPerStep: SIMD3<Float> = SIMD3<Float>(0, 15, 0)
}

// MARK: - ModifierParameters

enum ModifierParameters: Equatable {
    case array(ArrayParams)
    case radialArray(RadialArrayParams)
    case noiseOffset(NoiseOffsetParams)
    case scaleGradient(ScaleGradientParams)
    case rotationOffset(RotationOffsetParams)

    static func defaults(for type: ModifierType) -> ModifierParameters {
        switch type {
        case .array:          return .array(ArrayParams())
        case .radialArray:    return .radialArray(RadialArrayParams())
        case .noiseOffset:    return .noiseOffset(NoiseOffsetParams())
        case .scaleGradient:  return .scaleGradient(ScaleGradientParams())
        case .rotationOffset: return .rotationOffset(RotationOffsetParams())
        }
    }
}

// MARK: - ModifierType

enum ModifierType: String, CaseIterable, Equatable {
    case array          = "Array"
    case radialArray    = "Radial Array"
    case noiseOffset    = "Noise Offset"
    case scaleGradient  = "Scale Gradient"
    case rotationOffset = "Rotation Offset"
}

// MARK: - Modifier

struct Modifier: Identifiable, Equatable {
    let id: UUID
    var type: ModifierType
    var isEnabled: Bool
    var parameters: ModifierParameters

    init(
        id: UUID = UUID(),
        type: ModifierType,
        isEnabled: Bool = true,
        parameters: ModifierParameters? = nil
    ) {
        self.id = id
        self.type = type
        self.isEnabled = isEnabled
        self.parameters = parameters ?? .defaults(for: type)
    }
}
