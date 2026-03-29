import Foundation
import SceneKit
import SwiftUI

// MARK: - Instance (modifier pipeline output unit)

struct Instance: Equatable {
    var position: SIMD3<Float>
    var rotation: SIMD3<Float>   // degrees
    var scale: SIMD3<Float>

    static let identity = Instance(
        position: .zero,
        rotation: .zero,
        scale: SIMD3<Float>(1, 1, 1)
    )
}

// MARK: - Transform

struct Transform: Equatable {
    var position: SIMD3<Float> = .zero
    var rotation: SIMD3<Float> = .zero          // degrees
    var scale: SIMD3<Float> = SIMD3(5, 5, 5)   // uniform or per-axis
}

// MARK: - GeometryType

enum GeometryType: String, CaseIterable, Equatable, Hashable {
    case box      = "Box"
    case sphere   = "Sphere"
    case cylinder = "Cylinder"
    case plane    = "Plane"

    func makeGeometry(chamferRadius: Float = 0) -> SCNGeometry {
        switch self {
        case .box:
            return SCNBox(width: 1, height: 1, length: 1, chamferRadius: CGFloat(chamferRadius))
        case .sphere:
            let s = SCNSphere(radius: 0.5)
            s.segmentCount = 96     // high enough to stay smooth at large scales
            return s
        case .cylinder:
            return SCNCylinder(radius: 0.4, height: 1)
        case .plane:
            return SCNPlane(width: 1, height: 1)
        }
    }

    var sfSymbol: String {
        switch self {
        case .box:      return "cube"
        case .sphere:   return "circle.circle"
        case .cylinder: return "cylinder"
        case .plane:    return "rectangle"
        }
    }

    var displayName: String { rawValue }
}

// MARK: - Material

enum MaterialPreset: String, CaseIterable, Equatable {
    case plastic = "Plastic"
    case metal   = "Metal"
    case glass   = "Glass"
    case matte   = "Matte"
}

struct MaterialConfig: Equatable {
    var color: Color = .white
    var preset: MaterialPreset = .plastic

    func apply(to material: SCNMaterial) {
        material.diffuse.contents = NSColor(color)
        switch preset {
        case .plastic:
            material.lightingModel = .phong
            material.shininess = 80
            material.specular.contents = NSColor.white.withAlphaComponent(0.4)
            material.transparency = 1.0
        case .metal:
            material.lightingModel = .physicallyBased
            material.metalness.contents = NSColor.white
            material.roughness.contents = NSColor(white: 0.2, alpha: 1.0)
            material.transparency = 1.0
        case .glass:
            material.lightingModel = .phong
            material.shininess = 200
            material.specular.contents = NSColor.white
            material.transparency = 0.35
            material.isDoubleSided = true
        case .matte:
            material.lightingModel = .lambert
            material.shininess = 0
            material.specular.contents = NSColor.black
            material.transparency = 1.0
        }
    }

    func makeSCNMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        apply(to: m)
        return m
    }
}

// MARK: - SceneObject

struct SceneObject: Identifiable, Equatable {
    let id: UUID
    var name: String
    var geometryType: GeometryType
    var transform: Transform
    var material: MaterialConfig
    var modifiers: [Modifier]
    var isVisible: Bool
    /// Per-object seed combined with modifier seeds for deterministic noise
    var seed: Int
    /// Chamfer (rounded edge) radius — only visible on Box; ignored by other geometry types
    var chamferRadius: Float

    init(
        id: UUID = UUID(),
        name: String,
        geometryType: GeometryType,
        transform: Transform = Transform(),
        material: MaterialConfig = MaterialConfig(),
        modifiers: [Modifier] = [],
        isVisible: Bool = true,
        seed: Int? = nil,
        chamferRadius: Float? = nil
    ) {
        self.id = id
        self.name = name
        self.geometryType = geometryType
        self.transform = transform
        self.material = material
        self.modifiers = modifiers
        self.isVisible = isVisible
        self.seed = seed ?? Int.random(in: 1...Int.max)
        self.chamferRadius = chamferRadius ?? (geometryType == .box ? 0.04 : 0.0)
    }
}

// MARK: - Camera

enum CameraMode: String, CaseIterable, Equatable {
    case isometric    = "Iso"
    case orthographic = "Ortho"
}

// MARK: - Aspect Ratio
// Named AspectRatioMode to avoid collision with SwiftUI.AspectRatio

enum AspectRatioMode: String, CaseIterable, Equatable {
    case square  = "1:1"
    case port45  = "4:5"
    case land169 = "16:9"
    case port916 = "9:16"
    case land54  = "5:4"
    case port34  = "3:4"
    case land43  = "4:3"

    var value: CGFloat {
        switch self {
        case .square:  return 1.0
        case .port45:  return 4.0 / 5.0
        case .land169: return 16.0 / 9.0
        case .port916: return 9.0 / 16.0
        case .land54:  return 5.0 / 4.0
        case .port34:  return 3.0 / 4.0
        case .land43:  return 4.0 / 3.0
        }
    }
}

// MARK: - Lighting

enum LightType: String, CaseIterable, Equatable {
    case directional = "Directional"
    case omni        = "Omni"
}

enum LightPositionPreset: String, CaseIterable, Equatable {
    case front  = "Front"
    case back   = "Back"
    case top    = "Top"
    case bottom = "Bottom"
    case left   = "Left"
    case right  = "Right"

    var position: SCNVector3 {
        switch self {
        case .front:  return SCNVector3( 0,  0,  10)
        case .back:   return SCNVector3( 0,  0, -10)
        case .top:    return SCNVector3( 0,  10,  0)
        case .bottom: return SCNVector3( 0, -10,  0)
        case .left:   return SCNVector3(-10,  0,  0)
        case .right:  return SCNVector3( 10,  0,  0)
        }
    }

    var eulerAngles: SCNVector3 {
        let π = CGFloat.pi
        switch self {
        case .front:  return SCNVector3( 0,      0, 0)
        case .back:   return SCNVector3( 0,      π, 0)
        case .top:    return SCNVector3(-π / 2,  0, 0)
        case .bottom: return SCNVector3( π / 2,  0, 0)
        case .left:   return SCNVector3( 0,  π / 2, 0)
        case .right:  return SCNVector3( 0, -π / 2, 0)
        }
    }
}

struct LightConfig: Identifiable, Equatable {
    let id: UUID
    var type: LightType
    var color: Color
    var intensity: CGFloat
    var positionPreset: LightPositionPreset
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        type: LightType = .directional,
        color: Color = .white,
        intensity: CGFloat = 1000,
        positionPreset: LightPositionPreset = .top,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.type = type
        self.color = color
        self.intensity = intensity
        self.positionPreset = positionPreset
        self.isEnabled = isEnabled
    }
}

// MARK: - Export

enum ExportFormat: String, CaseIterable {
    case jpg = "JPG"
    case png = "PNG"
}

// MARK: - SCNVector3 convenience init from SIMD3<Float>

extension SCNVector3 {
    init(_ v: SIMD3<Float>) {
        self.init(x: CGFloat(v.x), y: CGFloat(v.y), z: CGFloat(v.z))
    }
}
