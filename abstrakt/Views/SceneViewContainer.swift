import SwiftUI
import SceneKit

struct SceneViewContainer: NSViewRepresentable {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var sceneController: SceneController

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = sceneController.scene
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = NSColor(appState.backgroundColor)
        view.pointOfView = sceneController.cameraNode
        view.showsStatistics = false

        // Store view reference for export
        sceneController.scnView = view

        let click = NSClickGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleClick(_:))
        )
        view.addGestureRecognizer(click)

        return view
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        nsView.backgroundColor = NSColor(appState.backgroundColor)
        // pointOfView is always the same node; SceneController updates its transform in place
        nsView.pointOfView = sceneController.cameraNode
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(appState: appState, sceneController: sceneController)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        let appState: AppState
        let sceneController: SceneController

        init(appState: AppState, sceneController: SceneController) {
            self.appState = appState
            self.sceneController = sceneController
        }

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            let point = gesture.location(in: view)
            let hitID = sceneController.hitTest(at: point, in: view)
            appState.selectedObjectID = hitID
        }
    }
}
