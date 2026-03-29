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
                ScaleRows(idx: idx)

                // Chamfer radius — Box (native) and Cylinder (capsule blend)
                if appState.objects[idx].geometryType == .box ||
                   appState.objects[idx].geometryType == .cylinder {
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

// MARK: - Scale rows with uniform lock

private struct ScaleRows: View {
    @EnvironmentObject var appState: AppState
    let idx: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Header + lock toggle
            HStack {
                Text("Scale")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary.opacity(0.7))
                Spacer()
                Button {
                    let locked = !appState.objects[idx].scaleLocked
                    appState.objects[idx].scaleLocked = locked
                    // Snap all axes to X when re-locking
                    if locked {
                        let v = appState.objects[idx].transform.scale.x
                        appState.objects[idx].transform.scale = SIMD3(v, v, v)
                    }
                } label: {
                    Image(systemName: appState.objects[idx].scaleLocked ? "lock.fill" : "lock.open")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(appState.objects[idx].scaleLocked ? Color.yellow : .secondary)
                }
                .buttonStyle(.borderless)
                .help(appState.objects[idx].scaleLocked ? "Unlock axes" : "Lock axes")
            }
            .padding(.bottom, 1)

            if appState.objects[idx].scaleLocked {
                // Single slider drives all three axes uniformly
                FloatRow(
                    label: "·",
                    value: Binding(
                        get: { appState.objects[idx].transform.scale.x },
                        set: { v in
                            appState.objects[idx].transform.scale = SIMD3(v, v, v)
                        }
                    ),
                    range: 0.01...20,
                    step: 0.1
                )
            } else {
                FloatRow(label: "X", value: $appState.objects[idx].transform.scale.x, range: 0.01...20, step: 0.1)
                FloatRow(label: "Y", value: $appState.objects[idx].transform.scale.y, range: 0.01...20, step: 0.1)
                FloatRow(label: "Z", value: $appState.objects[idx].transform.scale.z, range: 0.01...20, step: 0.1)
            }
        }
    }
}
