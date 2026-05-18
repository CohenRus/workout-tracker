//
//  WorkoutLabelResolution.swift
//  Tracker
//

import SwiftUI

enum WorkoutLabelResolution {
    static func stripe(for log: WorkoutLog, labelStore: WorkoutLabelStore, colorScheme: ColorScheme) -> (title: String, color: Color) {
        stripe(labelId: log.labelId, labelStore: labelStore, colorScheme: colorScheme)
    }

    static func stripe(labelId: UUID, labelStore: WorkoutLabelStore, colorScheme: ColorScheme) -> (title: String, color: Color) {
        if let lbl = labelStore.label(id: labelId) {
            return (lbl.name, lbl.stripeColor)
        }
        return ("Missing label", AppTheme.missingLabelStripe(for: colorScheme))
    }
}
