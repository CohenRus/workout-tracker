//
//  AppConstants.swift
//  Tracker
//

import CoreGraphics

enum AppConstants {
    /// Matches app id for `Logger` subsystem (see `WorkoutStore` / `WorkoutLabels`).
    static let bundleLoggerSubsystem = "Cohdoo.Tracker"

    /// Coalesce JSON writes after rapid edits (both workout and label stores).
    static let persistenceDebounceNanoseconds: UInt64 = 400_000_000

    static let applicationSupportSubdirectory = "Cohdoo.Tracker"
    static let workoutsFileName = "workouts.json"
    static let labelsFileName = "labels.json"

    /// Max characters for optional per-entry details in the day sheet.
    static let maxWorkoutDetailLength = 100

    /// Max characters for a workout label name.
    static let maxLabelNameLength = 48

    /// Max chips drawn inside a day (extra logs show “+N more”). Kept small so fixed cell height fits.
    static let monthCellPreviewLimit = 3

    /// Every day cell is exactly this tall in month view (content is clipped).
    static let monthCellFixedHeight: CGFloat = 102

    /// Max stripes shown per day column in week view before “+N more”.
    static let weekColumnPreviewLimit = 24

    static let weekdayGridColumns = 7
    static let weekdayGridSpacing: CGFloat = 3

    static let horizontalPadding: CGFloat = 18

    /// Sheet height for the month/year jump picker (year ribbon + divider + 4×3 grid + padding).
    static let monthJumpSheetDetentHeight: CGFloat = 360

    /// Year range for the month header “jump to month” menu, relative to the current calendar year.
    static let calendarJumpYearsPast = 20
    static let calendarJumpYearsFuture = 1
}
