//
//  ContentView.swift
//  abstrakt
//
//  Created by Matt Mills on 3/29/26.
//

import SwiftUI
import SceneKit

// Passes the toolbar's bottom edge (in canvas-local coordinates) up to ContentView.
private struct ToolbarBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 60
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var sceneController = SceneController()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Full-bleed 3D canvas
                SceneViewContainer()
                    .ignoresSafeArea()

                // Aspect ratio frame overlay (non-interactive)
                AspectRatioOverlay()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // Top toolbar — centered horizontally
                VStack {
                    HStack {
                        Spacer()
                        TopToolbar()
                        Spacer()
                    }
                    .padding(.top, 14)
                    // Measure where the toolbar's bottom edge sits so the crop frame
                    // can start just below it with a small gap.
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ToolbarBottomKey.self,
                                value: proxy.frame(in: .named("canvas")).maxY + 10
                            )
                        }
                    )
                    Spacer()
                }

                // Left sidebar — floats over the canvas
                HStack(alignment: .top) {
                    SidebarView()
                        .padding(.leading, 14)
                        .padding(.top, 66)
                    Spacer()
                }
            }
            .coordinateSpace(name: "canvas")
            .onPreferenceChange(ToolbarBottomKey.self) { inset in
                appState.cropVerticalInset = inset
            }
            .onAppear {
                appState.viewportSize = geo.size
                sceneController.sync(with: appState)
                sceneController.updateLighting(appState.lights)
                sceneController.setCamera(appState.cameraMode)
                sceneController.setBackground(appState.backgroundColor)
            }
            .onChange(of: geo.size) { _, newSize in
                appState.viewportSize = newSize
            }
            // Immediate rebuild triggers
            .onChange(of: appState.objects) { _, _ in
                sceneController.sync(with: appState)
            }
            .onChange(of: appState.selectedObjectID) { _, newID in
                sceneController.updateHighlight(selectedID: newID)
            }
            .onChange(of: appState.lights) { _, newLights in
                sceneController.updateLighting(newLights)
            }
            .onChange(of: appState.cameraMode) { _, newMode in
                sceneController.setCamera(newMode)
            }
            .onChange(of: appState.backgroundColor) { _, newColor in
                sceneController.setBackground(newColor)
            }
        }
        .preferredColorScheme(.dark)
        .environmentObject(appState)
        .environmentObject(sceneController)
    }
}
