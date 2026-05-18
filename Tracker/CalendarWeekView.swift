//
//  CalendarWeekView.swift
//  Tracker
//

import SwiftUI

struct CalendarWeekView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(WorkoutLabelStore.self) private var labelStore
    @Environment(\.colorScheme) private var colorScheme

    let math: JournalCalendarMath

    @Binding var visibleWeekAnchor: Date
    @Binding var selectedDay: SelectedCalendarDay?

    let onOpenMonthJump: () -> Void
    let onOpenSettings: () -> Void

    private var calendar: Calendar { math.calendar }

    var body: some View {
        VStack(spacing: 12) {
            weekRangeHeader
            GeometryReader { geo in
                HStack(alignment: .top, spacing: 6) {
                    ForEach(math.daysInWeek(for: visibleWeekAnchor), id: \.timeIntervalSinceReferenceDate) { day in
                        weekDayColumn(for: day, columnHeight: geo.size.height)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.smooth(duration: 0.38), value: visibleWeekAnchor)
        }
        .padding(.horizontal, AppConstants.horizontalPadding)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private var weekRangeHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Color.clear
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

            Button {
                onOpenMonthJump()
            } label: {
                HStack(alignment: .center, spacing: 5) {
                    Text(math.weekRangeTitle(for: visibleWeekAnchor))
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .lineLimit(3)
                    Image(systemName: "chevron.down")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppTheme.inkMuted.opacity(0.9))
                        .imageScale(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Go to month")
            .accessibilityValue(math.weekRangeTitle(for: visibleWeekAnchor))
            .accessibilityHint("Opens a picker to choose a month and year. Swipe sideways on the week columns to move to another week.")

            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(JournalCircleButtonStyle())
            .accessibilityLabel("Settings")
        }
    }

    private func weekDayColumn(for day: Date, columnHeight: CGFloat) -> some View {
        let logs = store.logs(on: day)
        let isToday = calendar.isDateInToday(day)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                selectedDay = SelectedCalendarDay(normalizing: day, calendar: calendar)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(math.shortWeekdaySymbol(for: day))
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.inkMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text("\(calendar.component(.day, from: day))")
                        .font(.system(.largeTitle, design: .rounded).weight(isToday ? .bold : .semibold))
                        .foregroundStyle(isToday ? Color.accentColor : AppTheme.ink)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens details to add or remove workouts")

            Divider()
                .opacity(colorScheme == .dark ? 0.32 : 0.22)
                .padding(.top, 4)
                .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 7) {
                    let weekSlice = Array(logs.prefix(AppConstants.weekColumnPreviewLimit))
                    ForEach(weekSlice) { log in
                        let stripe = WorkoutLabelResolution.stripe(for: log, labelStore: labelStore, colorScheme: colorScheme)
                        CalendarSharedViews.workoutPreviewStripe(
                            title: stripe.title,
                            color: stripe.color,
                            compact: false,
                            colorScheme: colorScheme
                        )
                    }
                    if logs.count > AppConstants.weekColumnPreviewLimit {
                        Text("+\(logs.count - AppConstants.weekColumnPreviewLimit) more")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.inkMuted)
                            .padding(.top, 2)
                    }
                }
                .padding(.top, 2)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: columnHeight, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.cornerPanel, style: .continuous)
                .fill(AppTheme.surface)
                .shadow(
                    color: Color.black.opacity(isToday ? 0.12 : 0.11),
                    radius: isToday ? 11 : 12,
                    y: isToday ? 5 : 5
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerPanel, style: .continuous)
                .strokeBorder(
                    CalendarSharedViews.weekStrokeGradient(isToday: isToday),
                    lineWidth: isToday ? 1.5 : 1
                )
        }
    }
}
