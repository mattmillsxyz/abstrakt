import SwiftUI

struct LightingSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        SidebarSection(title: "Lighting") {
            ForEach($appState.lights) { $light in
                LightRow(light: $light, canDelete: appState.lights.count > 1) {
                    appState.removeLight(id: light.id)
                }
            }

            if appState.lights.count < 3 {
                Button {
                    appState.addLight()
                } label: {
                    Label("Add Light", systemImage: "plus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .padding(.top, 2)
            }
        }
    }
}

// MARK: - Individual light row

struct LightRow: View {
    @Binding var light: LightConfig
    let canDelete: Bool
    let onDelete: () -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: light.type == .directional ? "sun.max" : "lightbulb")
                    .font(.system(size: 11))
                    .foregroundStyle(light.isEnabled ? .yellow : .secondary)
                    .frame(width: 16)

                Text(light.type.rawValue)
                    .font(.caption.weight(.medium))

                Spacer()

                Toggle("", isOn: $light.isEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)

                if canDelete {
                    IconButton(icon: "trash", action: onDelete, isDestructive: true)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    // Type
                    Picker("Type", selection: $light.type) {
                        ForEach(LightType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .font(.caption)
                    .labelsHidden()

                    // Color
                    HStack {
                        ColorPicker("Color", selection: $light.color)
                            .labelsHidden()
                            .frame(width: 24, height: 24)
                        Text("Color")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    // Intensity
                    HStack(spacing: 6) {
                        Text("Intensity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 54, alignment: .leading)
                        Slider(value: $light.intensity, in: 0...3000, step: 50)
                        Text("\(Int(light.intensity))")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(width: 34, alignment: .trailing)
                    }

                    // Position preset
                    Picker("Position", selection: $light.positionPreset) {
                        ForEach(LightPositionPreset.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.caption)
                }
                .padding(.leading, 20)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
    }
}
