import SwiftUI

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

// MARK: - Labeled float slider (compact)

struct FloatRow: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    var step: Float = 0.1

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(width: 14, alignment: .center)
            Slider(value: $value, in: range, step: step)
            Text(String(format: "%.2f", value))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(width: 38, alignment: .trailing)
        }
    }
}

// MARK: - Three-axis float rows (X/Y/Z)

struct Vec3Rows: View {
    let label: String
    @Binding var value: SIMD3<Float>
    var range: ClosedRange<Float> = -10...10
    var step: Float = 0.1

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary.opacity(0.7))
                .padding(.bottom, 1)
            FloatRow(label: "X", value: $value.x, range: range, step: step)
            FloatRow(label: "Y", value: $value.y, range: range, step: step)
            FloatRow(label: "Z", value: $value.z, range: range, step: step)
        }
    }
}

// MARK: - Sidebar section container

struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: title)
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            Divider()
                .padding(.horizontal, 8)
        }
    }
}

// MARK: - Icon button

struct IconButton: View {
    let icon: String
    let action: () -> Void
    var isDestructive: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isDestructive ? .red : .secondary)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Toggle chip style

struct ChipToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(label, isOn: $isOn)
            .toggleStyle(.checkbox)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
