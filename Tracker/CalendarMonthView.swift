//
//  CalendarMonthView.swift
//  Tracker
//

import SwiftUI

struct CalendarMonthView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(WorkoutLabelStore.self) private var labelStore
    @Environment(\.colorScheme) private var colorScheme

    let math: JournalCalendarMath
    let columns: [GridItem]
    let weekdaySymbols: [String]

    @Binding var visibleMonth: Date
    @Binding var selectedDay: SelectedCalendarDay?

    let onOpenMonthJump: () -> Void
    let onOpenSettings: () -> Void

    @ScaledMetric(relativeTo: .caption2) private var monthCellHeight = AppConstants.monthCellFixedHeight

    private var calendar: Calendar { math.calendar }

    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            weekdayHeader
            calendarGrid
                .animation(.smooth(duration: 0.38), value: visibleMonth)
        }
        .padding(.horizontal, AppConstants.horizontalPadding)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    private var monthHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Color.clear
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

            Button {
                onOpenMonthJump()
            } label: {
                HStack(alignment: .center, spacing: 5) {
                    Text(math.monthYearTitle(for: visibleMonth))
                        .font(.system(.title2, design: .serif).weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .lineLimit(2)
                    Image(systemName: "chevron.down")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppTheme.inkMuted.opacity(0.9))
                        .imageScale(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Go to month")
            .accessibilityValue(math.monthYearTitle(for: visibleMonth))
            .accessibilityHint("Opens a picker to choose a month and year. Swipe sideways on the calendar below to choose another month.")

            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(JournalCircleButtonStyle())
            .accessibilityLabel("Settings")
        }
        .transaction { $0.animation = nil }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: AppConstants.weekdayGridSpacing) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.inkMuted)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.cornerPanel, style: .continuous)
                .fill(AppTheme.surface.opacity(colorScheme == .dark ? 0.88 : 0.78))
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerPanel, style: .continuous)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: AppConstants.weekdayGridSpacing) {
            ForEach(math.monthGridSlots(for: visibleMonth)) { slot in
                if let day = slot.day {
                    monthDayCell(for: day)
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerCell, style: .continuous)
                        .fill(Color.clear)
                        .frame(height: monthCellHeight)
                }
            }
        }
    }

    private func monthDayCell(for day: Date) -> some View {
        let logs = store.logs(on: day)
        let isToday = calendar.isDateInToday(day)

        return Button {
            selectedDay = SelectedCalendarDay(normalizing: day, calendar: calendar)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    dayNumberBubble(day: day, isToday: isToday)
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 2) {
                    let previewLogs = Array(logs.prefix(AppConstants.monthCellPreviewLimit))
                    ForEach(previewLogs) { log in
                        let stripe = WorkoutLabelResolution.stripe(for: log, labelStore: labelStore, colorScheme: colorScheme)
                        CalendarSharedViews.workoutPreviewStripe(
                            title: stripe.title,
                            color: stripe.color,
                            compact: true,
                            colorScheme: colorScheme
                        )
                    }
                    if logs.count > AppConstants.monthCellPreviewLimit {
                        Text("+\(logs.count - AppConstants.monthCellPreviewLimit) more")
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppTheme.inkMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(6)
            .frame(maxWidth: .infinity)
            .frame(height: monthCellHeight, alignment: .topLeading)
            .clipped()
            .background {
                RoundedRectangle(cornerRadius: AppTheme.cornerCell, style: .continuous)
                    .fill(AppTheme.surface)
                    .shadow(
                        color: Color.black.opacity(0.10),
                        radius: 10,
                        y: 5
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cornerCell, style: .continuous)
                    .strokeBorder(
                        CalendarSharedViews.strokeGradient(isToday: isToday),
                        lineWidth: isToday ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dayNumberBubble(day: Date, isToday: Bool) -> some View {
        let n = calendar.component(.day, from: day)
        Text("\(n)")
            .font(.system(.caption, design: .rounded).weight(isToday ? .bold : .semibold))
            .foregroundStyle(isToday ? Color.white : AppTheme.ink)
            .frame(minWidth: 24, minHeight: 24)
            .background {
                if isToday {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.accentColor.opacity(0.28), radius: 3.5, y: 2)
                }
            }
    }
}
