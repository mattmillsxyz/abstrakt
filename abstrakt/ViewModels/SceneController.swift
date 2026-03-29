import Foundation
import SceneKit
import SwiftUI

final class SceneController: ObservableObject {
    let scene = SCNScene()
    private(set) var cameraNode: SCNNode

    // Weak reference used by ExportManager; set by SceneViewContainer
    weak var scnView: SCNView?

    // Per-object root nodes (keyed by SceneObject.id)
    private var objectNodes: [UUID: SCNNode] = [:]
    // Per-object base geometry (shared by all child nodes under that object)
    private var objectGeometries: [UUID: SCNGeometry] = [:]
    // Shared source geometry per type — never modified, only copied
    private var geometryCache: [GeometryType: SCNGeometry] = [:]
    // Last known state for diffing; used to detect which objects changed
    private var lastObjects: [UUID: SceneObject] = [:]
    // Light nodes keyed by LightConfig.id
    private var lightNodes: [UUID: SCNNode] = [:]
    // Ambient fill
    private var ambientNode: SCNNode
    // Currently highlighted object
    private var currentHighlightID: UUID? = nil

    init() {
        // Camera
        let cam = SCNCamera()
        cam.zNear = 0.1
        cam.zFar = 1000
        cameraNode = SCNNode()
        cameraNode.camera = cam
        scene.rootNode.addChildNode(cameraNode)

        // Soft ambient fill so unlit faces aren't pure black
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 80
        ambient.color = NSColor.white
        ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        setCamera(.isometric)
    }

    // MARK: - Geometry cache

    private func sourceGeometry(for type: GeometryType) -> SCNGeometry {
        if let g = geometryCache[type] { return g }
        let g = type.makeGeometry()
        geometryCache[type] = g
        return g
    }

    // MARK: - Main sync entry point

    func sync(with state: AppState) {
        let currentIDs = Set(state.objects.map(\.id))

        // Remove deleted objects
        for removedID in Set(lastObjects.keys).subtracting(currentIDs) {
            objectNodes[removedID]?.removeFromParentNode()
            objectNodes.removeValue(forKey: removedID)
            objectGeometries.removeValue(forKey: removedID)
            lastObjects.removeValue(forKey: removedID)
        }

        // Add/rebuild changed objects
        for object in state.objects {
            objectNodes[object.id]?.isHidden = !object.isVisible
            if lastObjects[object.id] != object {
                rebuildNode(for: object)
                lastObjects[object.id] = object
            }
        }

        updateHighlight(selectedID: state.selectedObjectID)
        scene.background.contents = NSColor(state.backgroundColor)
    }

    // MARK: - Node building

    func rebuildNode(for object: SceneObject) {
        objectNodes[object.id]?.removeFromParentNode()

        // Copy source geometry once per object — all child nodes share this reference
        let geo = sourceGeometry(for: object.geometryType).copy() as! SCNGeometry
        let mat = object.material.makeSCNMaterial()
        geo.materials = [mat]
        objectGeometries[object.id] = geo

        // Root node carries the object's base transform
        // Children carry instance transforms from the modifier pipeline
        let root = SCNNode()
        root.name = object.id.uuidString
        root.position = SCNVector3(object.transform.position)
        root.eulerAngles = degreesToEuler(object.transform.rotation)
        root.scale = SCNVector3(object.transform.scale)

        let instances = ModifierEngine.apply(object: object)
        for inst in instances {
            let child = SCNNode(geometry: geo)
            child.position = SCNVector3(inst.position)
            child.eulerAngles = degreesToEuler(inst.rotation)
            child.scale = SCNVector3(inst.scale)
            root.addChildNode(child)
        }

        scene.rootNode.addChildNode(root)
        objectNodes[object.id] = root
    }

    private func degreesToEuler(_ deg: SIMD3<Float>) -> SCNVector3 {
        SCNVector3(
            x: CGFloat(deg.x) * .pi / 180,
            y: CGFloat(deg.y) * .pi / 180,
            z: CGFloat(deg.z) * .pi / 180
        )
    }

    // MARK: - Selection highlighting
    // Materials are cloned for the selected object — shared materials are never mutated.

    func updateHighlight(selectedID: UUID?) {
        // Un-highlight the previously highlighted object if selection changed
        if currentHighlightID != selectedID, let old = currentHighlightID {
            restoreBaseGeometry(for: old)
        }
        // Always re-apply to selected (covers rebuild after modifier edit)
        if let new = selectedID {
            applyHighlight(for: new)
        }
        currentHighlightID = selectedID
    }

    private func applyHighlight(for id: UUID) {
        // No visual highlight — selection is reflected in the sidebar only.
    }

    private func restoreBaseGeometry(for id: UUID) {
        // Nothing to restore when no highlight is applied.
    }

    // MARK: - Camera
    // Isometric: perspective, camera angled at -35° X / 45° Y, pulled back along the resulting view axis
    // Orthographic: camera straight ahead at (0, 0, 10)

    func setCamera(_ mode: CameraMode) {
        switch mode {
        case .isometric:
            cameraNode.camera?.usesOrthographicProjection = false
            let xDeg: Float = -35
            let yDeg: Float =  45
            let xRad = CGFloat(xDeg * .pi / 180)
            let yRad = CGFloat(yDeg * .pi / 180)
            let dist: CGFloat = 15
            // Position camera along the view direction defined by the euler angles
            cameraNode.eulerAngles = SCNVector3(x: xRad, y: yRad, z: 0)
            cameraNode.position = SCNVector3(
                x:  dist * CGFloat(sin(Float(yRad)) * cos(Float(xRad))),
                y:  dist * CGFloat(-sin(Float(xRad))),
                z:  dist * CGFloat(cos(Float(yRad)) * cos(Float(xRad)))
            )

        case .orthographic:
            cameraNode.camera?.usesOrthographicProjection = true
            cameraNode.camera?.orthographicScale = 5
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
            cameraNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
        }
    }

    // MARK: - Lighting

    func updateLighting(_ lights: [LightConfig]) {
        lightNodes.values.forEach { $0.removeFromParentNode() }
        lightNodes = [:]

        for config in lights where config.isEnabled {
            let light = SCNLight()
            light.type = config.type == .directional ? .directional : .omni
            light.color = NSColor(config.color)
            light.intensity = config.intensity

            let node = SCNNode()
            node.light = light
            node.position = config.positionPreset.position
            node.eulerAngles = config.positionPreset.eulerAngles
            scene.rootNode.addChildNode(node)
            lightNodes[config.id] = node
        }
    }

    // MARK: - Background

    func setBackground(_ color: Color) {
        scene.background.contents = NSColor(color)
    }

    // MARK: - Hit testing

    func hitTest(at point: CGPoint, in view: SCNView) -> UUID? {
        let hits = view.hitTest(point, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue
        ])
        for hit in hits {
            var node: SCNNode? = hit.node
            while let n = node {
                if let name = n.name, let id = UUID(uuidString: name) {
                    return id
                }
                node = n.parent
            }
        }
        return nil
    }
}
