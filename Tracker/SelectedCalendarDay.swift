//
//  SelectedCalendarDay.swift
//  Tracker
//

import Foundation

/// Stable sheet identity for a calendar day without conforming `Date` to `Identifiable` app-wide.
struct SelectedCalendarDay: Identifiable, Hashable {
    let id: TimeInterval
    /// Normalized start-of-day in the given calendar.
    let date: Date

    init(normalizing date: Date, calendar: Calendar) {
        let start = calendar.startOfDay(for: date)
        self.date = start
        id = start.timeIntervalSinceReferenceDate
    }
}
