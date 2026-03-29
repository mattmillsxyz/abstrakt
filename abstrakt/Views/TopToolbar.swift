import SwiftUI

struct TopToolbar: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var sceneController: SceneController

    var body: some View {
        HStack(spacing: 10) {
            // Add shape buttons
            ForEach(GeometryType.allCases, id: \.self) { type in
                Button {
                    appState.addObject(type: type)
                } label: {
                    Image(systemName: type.sfSymbol)
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 26, height: 26)
                }
                .help("Add \(type.displayName)")
            }

            toolbarDivider

            // Camera group: icon + projection toggle + aspect ratio
            Image(systemName: "camera")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Picker("Camera", selection: $appState.cameraMode) {
                ForEach(CameraMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 90)
            .help("Toggle camera mode")

            Picker("Ratio", selection: $appState.aspectRatioMode) {
                ForEach(AspectRatioMode.allCases, id: \.self) { ratio in
                    Text(ratio.rawValue).tag(ratio)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 68)
            .help("Aspect ratio overlay")

            toolbarDivider

            // Presets
            Menu("Presets") {
                ForEach(Presets.all, id: \.name) { preset in
                    Button(preset.name) {
                        appState.applyPreset(preset.modifiers)
                    }
                    .disabled(appState.selectedObjectID == nil)
                }
            }
            .frame(width: 70)

            toolbarDivider

            // Background color
            ColorPicker("", selection: $appState.backgroundColor)
                .labelsHidden()
                .frame(width: 26, height: 26)
                .help("Background color")

            toolbarDivider

            // Export
            ExportButton()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .buttonStyle(.borderless)
    }

    private var toolbarDivider: some View {
        Divider()
            .frame(height: 18)
            .opacity(0.5)
    }
}

// MARK: - Export button

struct ExportButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var sceneController: SceneController

    var body: some View {
        Menu {
            Section("Format") {
                Picker("Format", selection: $appState.exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.inline)
            }
            Section("Resolution") {
                Picker("Scale", selection: $appState.exportScale) {
                    Text("1×").tag(1)
                    Text("2×").tag(2)
                    Text("4×").tag(4)
                }
                .pickerStyle(.inline)
            }
            Divider()
            Button {
                ExportManager.export(
                    scene: sceneController.scene,
                    camera: sceneController.cameraNode,
                    viewportSize: appState.viewportSize,
                    aspectRatio: appState.aspectRatioMode,
                    scale: appState.exportScale,
                    format: appState.exportFormat,
                    backgroundColor: appState.backgroundColor,
                    cropVerticalInset: appState.cropVerticalInset
                )
            } label: {
                Label("Export…", systemImage: "square.and.arrow.up")
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
                .font(.system(size: 13, weight: .medium))
        }
    }
}
