import SwiftUI

struct MaterialSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if let idx = selectedIndex {
            SidebarSection(title: "Material") {
                HStack(spacing: 8) {
                    ColorPicker("Color", selection: $appState.objects[idx].material.color)
                        .labelsHidden()
                        .frame(width: 28, height: 28)
                    Text("Color")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Picker("Preset", selection: $appState.objects[idx].material.preset) {
                    ForEach(MaterialPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .font(.caption)
            }
        }
    }

    private var selectedIndex: Int? {
        appState.objects.firstIndex(where: { $0.id == appState.selectedObjectID })
    }
}
