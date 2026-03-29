import Foundation
import SceneKit
import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum ExportManager {

    /// Renders the scene at scale × viewportSize, center-crops to the aspect ratio,
    /// and saves to a user-chosen file via NSSavePanel.
    static func export(
        scene: SCNScene,
        camera: SCNNode?,
        viewportSize: CGSize,
        aspectRatio: AspectRatioMode,
        scale: Int,
        format: ExportFormat,
        backgroundColor: Color
    ) {
        // 1. Present save panel (must run on main thread — button actions are already on main)
        let panel = NSSavePanel()
        panel.allowedContentTypes = format == .jpg ? [.jpeg] : [.png]
        let ext = format == .jpg ? "jpg" : "png"
        panel.nameFieldStringValue = "export.\(ext)"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // 2. Determine render size (pixels)
        let renderSize = CGSize(
            width:  viewportSize.width  * CGFloat(scale),
            height: viewportSize.height * CGFloat(scale)
        )

        // 3. Render via SCNRenderer (off-screen, any size)
        guard let device = MTLCreateSystemDefaultDevice() else {
            presentError("Metal device unavailable — export requires a GPU.")
            return
        }
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = scene
        renderer.pointOfView = camera

        let isTransparent = (format == .png)
        let savedBackground = scene.background.contents
        if isTransparent {
            scene.background.contents = NSColor.clear
        }

        let rendered = renderer.snapshot(atTime: 0, with: renderSize, antialiasingMode: .multisampling4X)

        if isTransparent {
            scene.background.contents = savedBackground
        }

        // 4. Center-crop to aspect ratio (matches overlay exactly)
        let cropInViewCoords = AspectRatioOverlay.centeredCropRect(for: aspectRatio, in: viewportSize)
        guard let cropped = crop(image: rendered,
                                 cropInViewCoords: cropInViewCoords,
                                 viewportSize: viewportSize,
                                 scale: scale)
        else {
            presentError("Failed to crop exported image.")
            return
        }

        // 5. Encode and write
        guard let tiff = cropped.tiffRepresentation,
              let rep  = NSBitmapImageRep(data: tiff)
        else { return }

        let data: Data?
        switch format {
        case .jpg:
            data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92])
        case .png:
            data = rep.representation(using: .png, properties: [:])
        }

        guard let fileData = data else { return }
        do {
            try fileData.write(to: url)
        } catch {
            presentError("Could not save file: \(error.localizedDescription)")
        }
    }

    // MARK: - Center-crop helper

    /// Crops `image` so that only the region defined by `cropInViewCoords` (in view/point space)
    /// is included. Converts to image-space coordinates correctly for NSImage.
    private static func crop(
        image: NSImage,
        cropInViewCoords: CGRect,
        viewportSize: CGSize,
        scale: Int
    ) -> NSImage? {
        let sc = CGFloat(scale)
        let outSize = CGSize(
            width:  cropInViewCoords.width  * sc,
            height: cropInViewCoords.height * sc
        )
        guard outSize.width > 0, outSize.height > 0 else { return nil }

        // Source rect in the rendered image's coordinate system.
        // NSImage uses a bottom-left origin, so we must flip the y axis.
        // cropInViewCoords.minY is pixels from the TOP in view space.
        // In NSImage space: y from bottom = (viewportHeight - cropMaxY) * scale
        let srcX  = cropInViewCoords.minX * sc
        let srcY  = (viewportSize.height - cropInViewCoords.maxY) * sc  // flip
        let srcW  = outSize.width
        let srcH  = outSize.height

        let result = NSImage(size: outSize)
        result.lockFocus()
        defer { result.unlockFocus() }

        // Draw the source image offset so the desired region appears at (0,0)
        image.draw(
            in: NSRect(x: -srcX, y: -srcY, width: image.size.width, height: image.size.height),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )

        _ = srcW + srcH  // suppress unused-variable warnings
        return result
    }

    // MARK: - Error presentation

    private static func presentError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Export Error"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}
