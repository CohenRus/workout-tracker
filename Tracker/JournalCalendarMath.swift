//
//  JournalCalendarMath.swift
//  Tracker
//

import Foundation

struct JournalCalendarMath {
    var calendar: Calendar

    private var formatLocale: Locale {
        calendar.locale ?? .autoupdatingCurrent
    }

    func monthYearTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year().locale(formatLocale))
    }

    func weekRangeTitle(for date: Date) -> String {
        let days = daysInWeek(for: date)
        guard let first = days.first, let last = days.last else { return "" }
        let y1 = calendar.component(.year, from: first)
        let y2 = calendar.component(.year, from: last)
        let m1 = calendar.component(.month, from: first)
        let m2 = calendar.component(.month, from: last)
        let d1 = calendar.component(.day, from: first)
        let d2 = calendar.component(.day, from: last)

        if m1 == m2, y1 == y2 {
            let monthName = first.formatted(.dateTime.month(.wide).locale(formatLocale))
            return "\(monthName) \(d1) – \(d2), \(y1)"
        }
        let left = first.formatted(.dateTime.month(.wide).day().year().locale(formatLocale))
        let right = last.formatted(.dateTime.month(.wide).day().year().locale(formatLocale))
        return "\(left) – \(right)"
    }

    func shortWeekdaySymbol(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).locale(formatLocale))
    }

    func startOfMonth(for date: Date) -> Date {
        let c = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: c) ?? date
    }

    /// First instant of the given calendar month; `month` is 1...12.
    func firstDayOfMonth(year: Int, month: Int) -> Date? {
        guard (1 ... 12).contains(month) else { return nil }
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = 1
        return calendar.date(from: c)
    }

    /// Localized full month name for calendar menus; `month` is 1...12.
    func fullMonthTitle(month: Int) -> String {
        guard month >= 1, month <= 12 else { return "" }
        let symbols = calendar.monthSymbols
        guard month <= symbols.count else { return "" }
        return symbols[month - 1]
    }

    /// Short month label (e.g. Jan, Feb); `month` is 1...12.
    func shortMonthTitle(month: Int) -> String {
        guard month >= 1, month <= 12 else { return "" }
        let symbols = calendar.shortMonthSymbols
        guard month <= symbols.count else { return "" }
        return symbols[month - 1]
    }

    func startOfWeek(for date: Date) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: dayStart)
        let first = calendar.firstWeekday
        let delta = (weekday - first + 7) % 7
        return calendar.date(byAdding: .day, value: -delta, to: dayStart) ?? dayStart
    }

    func daysInWeek(for date: Date) -> [Date] {
        let start = startOfWeek(for: date)
        return (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    func daysInMonthGrid(for visibleMonth: Date) -> [Date?] {
        let start = startOfMonth(for: visibleMonth)
        guard let range = calendar.range(of: .day, in: .month, for: start),
              let firstWeekday = calendar.dateComponents([.weekday], from: start).weekday else { return [] }

        let padding = (firstWeekday - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: padding)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                cells.append(date)
            }
        }

        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }

    /// Stable SwiftUI identities for month grid cells (visible month + slot + optional day).
    func monthGridSlots(for visibleMonth: Date) -> [MonthGridSlot] {
        let y = calendar.component(.year, from: visibleMonth)
        let m = calendar.component(.month, from: visibleMonth)
        let prefix = "\(y)-\(m)"
        return daysInMonthGrid(for: visibleMonth).enumerated().map { idx, day in
            if let day {
                return MonthGridSlot(
                    id: "\(prefix)-d-\(day.timeIntervalSinceReferenceDate)",
                    day: day
                )
            }
            return MonthGridSlot(
                id: "\(prefix)-empty-\(idx)",
                day: nil
            )
        }
    }

    func weekAnchorWhenEnteringWeek(visibleMonth: Date, today: Date = Date()) -> Date {
        let todayStart = calendar.startOfDay(for: today)
        if calendar.isDate(todayStart, equalTo: visibleMonth, toGranularity: .month) {
            return todayStart
        }
        return startOfMonth(for: visibleMonth)
    }

    func shortWeekdaySymbols() -> [String] {
        var cal = calendar
        cal.locale = .current
        return cal.shortWeekdaySymbols
    }
}

struct MonthGridSlot: Identifiable {
    let id: String
    let day: Date?
}
