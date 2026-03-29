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
                    step: 0.5
                )
                Vec3Rows(
                    label: "Rotation",
                    value: $appState.objects[idx].transform.rotation,
                    range: -180...180,
                    step: 15
                )
                Vec3Rows(
                    label: "Scale",
                    value: $appState.objects[idx].transform.scale,
                    range: 0.01...20,
                    step: 0.1
                )

                // Chamfer radius — only applicable to Box geometry
                if appState.objects[idx].geometryType == .box {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Chamfer")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary.opacity(0.7))
                            .padding(.bottom, 1)
                        FloatRow(
                            label: "R",
                            value: $appState.objects[idx].chamferRadius,
                            range: 0...0.49,
                            step: 0.01
                        )
                    }
                }
            }
        }
    }

    private var selectedIndex: Int? {
        appState.objects.firstIndex(where: { $0.id == appState.selectedObjectID })
    }
}
