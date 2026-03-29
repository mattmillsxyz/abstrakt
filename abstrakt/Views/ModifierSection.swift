import SwiftUI

// MARK: - Modifier Section Container

struct ModifierSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if let objIdx = selectedIndex {
            SidebarSection(title: "Modifiers") {
                let modifiers = appState.objects[objIdx].modifiers

                if modifiers.isEmpty {
                    Text("No modifiers")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(modifiers) { mod in
                        ModifierRow(
                            modifier: mod,
                            objectID: appState.objects[objIdx].id,
                            isFirst: mod.id == modifiers.first?.id,
                            isLast:  mod.id == modifiers.last?.id
                        )
                    }
                }

                // Add modifier menu
                Menu {
                    ForEach(ModifierType.allCases, id: \.self) { type in
                        Button(type.rawValue) { appState.addModifier(type) }
                    }
                } label: {
                    Label("Add Modifier", systemImage: "plus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .padding(.top, 2)
            }
        }
    }

    private var selectedIndex: Int? {
        appState.objects.firstIndex(where: { $0.id == appState.selectedObjectID })
    }
}

// MARK: - Individual Modifier Row

struct ModifierRow: View {
    let modifier: Modifier
    let objectID: UUID
    let isFirst: Bool
    let isLast: Bool

    @EnvironmentObject var appState: AppState
    @State private var isExpanded = true

    // Mutation helpers — write directly into AppState.objects
    private func updateParams(_ params: ModifierParameters) {
        guard let objIdx = appState.objects.firstIndex(where: { $0.id == objectID }),
              let modIdx = appState.objects[objIdx].modifiers.firstIndex(where: { $0.id == modifier.id })
        else { return }
        appState.objects[objIdx].modifiers[modIdx].parameters = params
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header row
            HStack(spacing: 4) {
                // Enable toggle
                Button {
                    appState.toggleModifier(modifierID: modifier.id)
                } label: {
                    Image(systemName: modifier.isEnabled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundStyle(modifier.isEnabled ? .yellow : .secondary)
                }
                .buttonStyle(.borderless)
                .frame(width: 18)

                Text(modifier.type.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(modifier.isEnabled ? .primary : .secondary)

                Spacer()

                // Reorder
                if !isFirst {
                    IconButton(icon: "chevron.up") {
                        appState.moveModifier(modifierID: modifier.id, direction: .up)
                    }
                }
                if !isLast {
                    IconButton(icon: "chevron.down") {
                        appState.moveModifier(modifierID: modifier.id, direction: .down)
                    }
                }

                // Expand / collapse
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)

                // Delete
                IconButton(icon: "xmark", action: {
                    appState.removeModifier(modifierID: modifier.id)
                }, isDestructive: false)
            }

            // Parameter controls
            if isExpanded {
                Group {
                    switch modifier.parameters {
                    case .array(let p):
                        ArrayParamsView(
                            params: Binding(get: { p }, set: { updateParams(.array($0)) })
                        )
                    case .radialArray(let p):
                        RadialArrayParamsView(
                            params: Binding(get: { p }, set: { updateParams(.radialArray($0)) })
                        )
                    case .noiseOffset(let p):
                        NoiseOffsetParamsView(
                            params: Binding(get: { p }, set: { updateParams(.noiseOffset($0)) })
                        )
                    case .scaleGradient(let p):
                        ScaleGradientParamsView(
                            params: Binding(get: { p }, set: { updateParams(.scaleGradient($0)) })
                        )
                    case .rotationOffset(let p):
                        RotationOffsetParamsView(
                            params: Binding(get: { p }, set: { updateParams(.rotationOffset($0)) })
                        )
                    }
                }
                .padding(.leading, 20)
                .opacity(modifier.isEnabled ? 1 : 0.4)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Parameter Views

struct ArrayParamsView: View {
    @Binding var params: ArrayParams

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CountRow(label: "Count", value: $params.count, range: 1...500)
            Vec3Rows(label: "Offset", value: $params.offset, range: -10...10, step: 0.1)
            ChipToggle(label: "Relative", isOn: $params.relative)
        }
    }
}

struct RadialArrayParamsView: View {
    @Binding var params: RadialArrayParams

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CountRow(label: "Count", value: $params.count, range: 1...500)
            FloatRow(label: "R", value: $params.radius, range: 0...20, step: 0.1)
            FloatRow(label: "°",  value: $params.totalAngle, range: 0...720, step: 15)
            HStack {
                Text("Axis").font(.caption).foregroundStyle(.secondary)
                Picker("", selection: $params.axis) {
                    ForEach(RadialAxis.allCases, id: \.self) { ax in
                        Text(ax.rawValue).tag(ax)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }
}

struct NoiseOffsetParamsView: View {
    @Binding var params: NoiseOffsetParams

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Vec3Rows(label: "Amplitude", value: $params.amplitude, range: 0...5, step: 0.05)
            HStack(spacing: 6) {
                Text("Seed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .leading)
                Stepper(value: $params.seed, in: 0...9999) {
                    Text("\(params.seed)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .controlSize(.mini)
            }
        }
    }
}

struct ScaleGradientParamsView: View {
    @Binding var params: ScaleGradientParams

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FloatRow(label: "▶", value: $params.startScale, range: 0.01...5, step: 0.05)
            FloatRow(label: "■", value: $params.endScale,   range: 0.01...5, step: 0.05)
        }
    }
}

struct RotationOffsetParamsView: View {
    @Binding var params: RotationOffsetParams

    var body: some View {
        Vec3Rows(
            label: "°/Step",
            value: $params.rotationPerStep,
            range: -90...90,
            step: 1
        )
    }
}

// MARK: - Count row (int stepper)

struct CountRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 38, alignment: .leading)
            Stepper(value: $value, in: range) {
                Text("\(value)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
            }
            .controlSize(.mini)
        }
    }
}
