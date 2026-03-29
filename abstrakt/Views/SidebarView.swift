import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let obj = appState.selectedObject {
                    // Object header
                    ObjectHeaderRow(object: obj)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 4)
                    Divider().padding(.horizontal, 8)

                    TransformSection()
                    MaterialSection()
                    ModifierSection()
                } else {
                    Text("Select an object")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    Divider().padding(.horizontal, 8)
                }

                LightingSection()
            }
        }
        .frame(width: 260)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 0))
    }
}

// MARK: - Object header row

struct ObjectHeaderRow: View {
    let object: SceneObject
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: object.geometryType.sfSymbol)
                .font(.system(size: 12))
                .foregroundStyle(.yellow)
                .frame(width: 18)

            Text(object.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Spacer()

            // Randomize seed
            Button {
                appState.randomizeSeed()
            } label: {
                Image(systemName: "dice")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Randomize seed")

            // Delete
            Button {
                appState.deleteSelected()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.borderless)
            .help("Delete object")
        }
    }
}
