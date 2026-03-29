import SwiftUI

struct TransformSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if let idx = selectedIndex {
            SidebarSection(title: "Transform") {
                Vec3Rows(
                    label: "Position",
                    value: $appState.objects[idx].transform.position,
                    range: -20...20,
                    step: 0.5   // snap to 0.5 increments
                )
                Vec3Rows(
                    label: "Rotation",
                    value: $appState.objects[idx].transform.rotation,
                    range: -180...180,
                    step: 15    // snap to 15° increments
                )
            }
        }
    }

    private var selectedIndex: Int? {
        appState.objects.firstIndex(where: { $0.id == appState.selectedObjectID })
    }
}
