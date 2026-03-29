import SwiftUI

struct AspectRatioOverlay: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geo in
            let cropRect = Self.centeredCropRect(
                for: appState.aspectRatioMode,
                in: geo.size,
                verticalInset: appState.cropVerticalInset
            )

            ZStack {
                // Letterbox: dark fill with even-odd hole for the crop region
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geo.size))
                    path.addRect(cropRect)
                }
                .fill(Color.black.opacity(0.4), style: FillStyle(eoFill: true))

                // Yellow aspect frame border
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow.opacity(0.85), lineWidth: 1.5)
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
            }
        }
    }

    // MARK: - Crop rect calculation (mirrors ExportManager logic)

    /// Returns the largest centered CGRect that fits within `size` (minus vertical insets)
    /// for the given aspect ratio. The inset is applied equally top and bottom so the
    /// frame sits below the toolbar and has matching breathing room at the bottom.
    static func centeredCropRect(
        for ratio: AspectRatioMode,
        in size: CGSize,
        verticalInset: CGFloat = 0
    ) -> CGRect {
        let available = CGSize(
            width:  size.width,
            height: size.height - verticalInset * 2
        )
        let r = ratio.value
        var w = available.width
        var h = available.height
        if w / h > r {
            w = h * r
        } else {
            h = w / r
        }
        return CGRect(
            x: (size.width   - w) / 2,
            y: verticalInset + (available.height - h) / 2,
            width:  w,
            height: h
        )
    }
}
