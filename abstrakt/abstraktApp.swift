//
//  abstraktApp.swift
//  abstrakt
//
//  Created by Matt Mills on 3/29/26.
//

import SwiftUI

@main
struct abstraktApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1440, height: 900)
        .windowResizability(.contentSize)
    }
}
