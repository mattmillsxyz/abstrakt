//
//  ContentView.swift
//  abstrakt
//
//  Created by Matt Mills on 3/29/26.
//

import SwiftUI
import SceneKit

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
