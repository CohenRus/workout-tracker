//
//  ContentView.swift
//  Tracker
//

import SwiftUI

struct ContentView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(WorkoutLabelStore.self) private var labelStore

    @AppStorage("calendarScope") private var calendarScopeRaw = CalendarScope.month.rawValue
    @AppStorage("appAppearance") private var appearanceRaw = AppAppearance.light.rawValue

    @State private var showSettings = false
    @State private var showMonthJumpSheet = false
    @State private var visibleMonth: Date = Date()
    @State private var visibleWeekAnchor: Date = Date()
    @State private var selectedDay: SelectedCalendarDay?

    private let math = JournalCalendarMath(calendar: .current)
    private var calendar: Calendar { math.calendar }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AppConstants.weekdayGridSpacing), count: AppConstants.weekdayGridColumns)
    }

    private let weekdaySymbols: [String]

    init() {
        weekdaySymbols = JournalCalendarMath(calendar: .current).shortWeekdaySymbols()
    }

    private var appearancePreference: ColorScheme? {
        (AppAppearance(rawValue: appearanceRaw) ?? .light).preferredColorScheme
    }

    private var monthJumpYearsAscending: [Int] {
        let y = calendar.component(.year, from: Date())
        let low = y - AppConstants.calendarJumpYearsPast
        let high = y + AppConstants.calendarJumpYearsFuture
        return Array(low ... high)
    }

    /// Month highlighted in the jump sheet — follows week navigation when in week scope.
    private var monthJumpAnchorMonth: Date {
        switch CalendarScope(rawValue: calendarScopeRaw) ?? .month {
        case .month:
            visibleMonth
        case .week:
            math.startOfMonth(for: visibleWeekAnchor)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.JournalBackdrop()

                VStack(spacing: 0) {
                    Group {
                        switch CalendarScope(rawValue: calendarScopeRaw) ?? .month {
                        case .month:
                            ScrollView {
                                CalendarMonthView(
                                    math: math,
                                    columns: columns,
                                    weekdaySymbols: weekdaySymbols,
                                    visibleMonth: $visibleMonth,
                                    selectedDay: $selectedDay,
                                    onOpenMonthJump: { showMonthJumpSheet = true },
                                    onOpenSettings: { showSettings = true }
                                )
                            }
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .simultaneousGesture(monthWeekSwipeGesture)
                        case .week:
                            CalendarWeekView(
                                math: math,
                                visibleWeekAnchor: $visibleWeekAnchor,
                                selectedDay: $selectedDay,
                                onOpenMonthJump: { showMonthJumpSheet = true },
                                onOpenSettings: { showSettings = true }
                            )
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .simultaneousGesture(monthWeekSwipeGesture)
                        }
                    }
                    .animation(.spring(response: 0.42, dampingFraction: 0.86), value: calendarScopeRaw)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(labelStore)
                    .environment(store)
            }
            .sheet(isPresented: $showMonthJumpSheet) {
                MonthJumpSheet(
                    math: math,
                    years: monthJumpYearsAscending,
                    anchorMonth: monthJumpAnchorMonth,
                    onSelect: { year, month in
                        jumpToMonth(year: year, month: month)
                    }
                )
                .presentationDetents([.height(AppConstants.monthJumpSheetDetentHeight)])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedDay) { day in
                DayLogsSheet(date: day.date)
                    .environment(store)
                    .environment(labelStore)
            }
            .onChange(of: calendarScopeRaw) { _, newRaw in
                switch CalendarScope(rawValue: newRaw) ?? .month {
                case .month:
                    visibleMonth = math.startOfMonth(for: visibleWeekAnchor)
                case .week:
                    visibleWeekAnchor = math.weekAnchorWhenEnteringWeek(visibleMonth: visibleMonth)
                }
            }
        }
        .preferredColorScheme(appearancePreference)
    }

    private func shiftMonth(by value: Int) {
        guard let next = calendar.date(byAdding: .month, value: value, to: math.startOfMonth(for: visibleMonth)) else { return }
        visibleMonth = next
    }

    private func jumpToMonth(year: Int, month: Int) {
        guard let d = math.firstDayOfMonth(year: year, month: month) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            visibleMonth = d
            if (CalendarScope(rawValue: calendarScopeRaw) ?? .month) == .week {
                visibleWeekAnchor = math.weekAnchorWhenEnteringWeek(visibleMonth: d)
            }
        }
    }

    private func shiftWeek(by value: Int) {
        guard let next = calendar.date(byAdding: .day, value: value * 7, to: math.startOfWeek(for: visibleWeekAnchor)) else { return }
        visibleWeekAnchor = next
        visibleMonth = math.startOfMonth(for: next)
    }

    private var monthWeekSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 44)
            .onEnded { value in
                let d = value.translation
                guard abs(d.width) > abs(d.height) else { return }
                let thresh: CGFloat = 55
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    switch CalendarScope(rawValue: calendarScopeRaw) ?? .month {
                    case .month:
                        if d.width <= -thresh { shiftMonth(by: 1) }
                        else if d.width >= thresh { shiftMonth(by: -1) }
                    case .week:
                        if d.width <= -thresh { shiftWeek(by: 1) }
                        else if d.width >= thresh { shiftWeek(by: -1) }
                    }
                }
            }
    }
}

#Preview {
    ContentView()
        .environment(WorkoutLabelStore())
        .environment(WorkoutStore())
}
