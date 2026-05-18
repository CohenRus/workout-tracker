//
//  TrackerApp.swift
//  Tracker
//
//  Created by Cohen Russell on 5/17/26.
//

import SwiftUI

@main
struct TrackerApp: App {
    @State private var labelStore = WorkoutLabelStore()
    @State private var workoutStore = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(labelStore)
                .environment(workoutStore)
        }
    }
}
