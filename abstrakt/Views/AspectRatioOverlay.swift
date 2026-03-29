import SwiftUI

struct AspectRatioOverlay: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geo in
            let cropRect = centeredCropRect(for: appState.aspectRatioMode, in: geo.size)

            ZStack {
                // Letterbox: dark fill with even-odd hole for the crop region
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geo.size))
                    path.addRect(cropRect)
                }
                .fill(Color.black.opacity(0.4), style: FillStyle(eoFill: true))

                // Yellow aspect frame border
                Rectangle()
                    .stroke(Color.yellow.opacity(0.85), lineWidth: 1.5)
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
            }
        }
    }

    // MARK: - Crop rect calculation (mirrors ExportManager logic)

    /// Returns the largest centered CGRect that fits `size` with the given aspect ratio.
    static func centeredCropRect(for ratio: AspectRatioMode, in size: CGSize) -> CGRect {
        let r = ratio.value
        var w = size.width
        var h = size.height
        if w / h > r {
            w = h * r
        } else {
            h = w / r
        }
        return CGRect(
            x: (size.width  - w) / 2,
            y: (size.height - h) / 2,
            width:  w,
            height: h
        )
    }

    private func centeredCropRect(for ratio: AspectRatioMode, in size: CGSize) -> CGRect {
        Self.centeredCropRect(for: ratio, in: size)
    }
}
