import Foundation
import SwiftUI

enum MoveDirection { case up, down }

final class AppState: ObservableObject {
    @Published var objects: [SceneObject] = []
    @Published var selectedObjectID: UUID? = nil
    @Published var cameraMode: CameraMode = .isometric
    @Published var backgroundColor: Color = .black
    @Published var aspectRatioMode: AspectRatioMode = .square
    @Published var lights: [LightConfig] = [
        LightConfig(type: .directional, color: .white,              intensity: 1200, positionPreset: .top),
        LightConfig(type: .omni,        color: Color(white: 0.35), intensity: 500,  positionPreset: .front, isEnabled: false)
    ]
    @Published var exportScale: Int = 2
    @Published var exportFormat: ExportFormat = .png
    /// Stored by ContentView via GeometryReader so ExportManager can use it
    @Published var viewportSize: CGSize = CGSize(width: 1280, height: 800)
    /// Vertical inset (top and bottom) for the aspect ratio crop frame.
    /// Measured dynamically from the toolbar height so the frame sits just below the toolbar.
    @Published var cropVerticalInset: CGFloat = 60

    // MARK: - Computed selected object

    var selectedObject: SceneObject? {
        get { objects.first(where: { $0.id == selectedObjectID }) }
        set {
            guard let updated = newValue,
                  let idx = objects.firstIndex(where: { $0.id == updated.id })
            else { return }
            objects[idx] = updated
        }
    }

    // MARK: - Object management

    func addObject(type: GeometryType) {
        let count = objects.filter { $0.geometryType == type }.count
        let name = count == 0 ? type.displayName : "\(type.displayName) \(count + 1)"
        let obj = SceneObject(name: name, geometryType: type)
        objects.append(obj)
        selectedObjectID = obj.id
    }

    func deleteSelected() {
        guard let id = selectedObjectID else { return }
        objects.removeAll { $0.id == id }
        selectedObjectID = objects.last?.id
    }

    // MARK: - Modifier management

    func addModifier(_ type: ModifierType) {
        guard let id = selectedObjectID,
              let idx = objects.firstIndex(where: { $0.id == id })
        else { return }
        objects[idx].modifiers.append(Modifier(type: type))
    }

    func removeModifier(modifierID: UUID) {
        guard let id = selectedObjectID,
              let objIdx = objects.firstIndex(where: { $0.id == id })
        else { return }
        objects[objIdx].modifiers.removeAll { $0.id == modifierID }
    }

    func moveModifier(modifierID: UUID, direction: MoveDirection) {
        guard let id = selectedObjectID,
              let objIdx = objects.firstIndex(where: { $0.id == id }),
              let modIdx = objects[objIdx].modifiers.firstIndex(where: { $0.id == modifierID })
        else { return }
        switch direction {
        case .up:
            guard modIdx > 0 else { return }
            objects[objIdx].modifiers.swapAt(modIdx, modIdx - 1)
        case .down:
            guard modIdx < objects[objIdx].modifiers.count - 1 else { return }
            objects[objIdx].modifiers.swapAt(modIdx, modIdx + 1)
        }
    }

    func toggleModifier(modifierID: UUID) {
        guard let id = selectedObjectID,
              let objIdx = objects.firstIndex(where: { $0.id == id }),
              let modIdx = objects[objIdx].modifiers.firstIndex(where: { $0.id == modifierID })
        else { return }
        objects[objIdx].modifiers[modIdx].isEnabled.toggle()
    }

    func applyPreset(_ modifiers: [Modifier]) {
        guard let id = selectedObjectID,
              let idx = objects.firstIndex(where: { $0.id == id })
        else { return }
        objects[idx].modifiers = modifiers
    }

    func randomizeSeed() {
        guard let id = selectedObjectID,
              let idx = objects.firstIndex(where: { $0.id == id })
        else { return }
        objects[idx].seed = Int.random(in: 1...Int.max)
    }

    // MARK: - Light management

    func addLight() {
        guard lights.count < 3 else { return }
        let presets: [LightPositionPreset] = [.right, .back, .bottom]
        let preset = presets[min(lights.count - 1, presets.count - 1)]
        lights.append(LightConfig(type: .omni, positionPreset: preset))
    }

    func removeLight(id: UUID) {
        guard lights.count > 1 else { return }
        lights.removeAll { $0.id == id }
    }
}
