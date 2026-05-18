//
//  MonthJumpSheet.swift
//  Tracker
//

import SwiftUI

/// Sheet UI for picking a calendar month: horizontal year ribbon + 4×3 month lattice (journal / editorial tone).
struct MonthJumpSheet: View {
    let math: JournalCalendarMath
    /// Ascending calendar years (inclusive range).
    let years: [Int]
    let anchorMonth: Date
    let onSelect: (Int, Int) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedYear: Int

    private var calendar: Calendar { math.calendar }

    private let monthColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    init(
        math: JournalCalendarMath,
        years: [Int],
        anchorMonth: Date,
        onSelect: @escaping (Int, Int) -> Void
    ) {
        self.math = math
        self.years = years
        self.anchorMonth = anchorMonth
        self.onSelect = onSelect
        let y = math.calendar.component(.year, from: anchorMonth)
        _selectedYear = State(initialValue: y)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                yearRibbon
                    .padding(.top, 8)

                Rectangle()
                    .fill(AppTheme.hairline)
                    .frame(height: 1)
                    .padding(.horizontal, 22)
                    .opacity(0.85)

                monthLattice
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            AppTheme.journalBackground
                .ignoresSafeArea()
        }
    }

    private var yearRibbon: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(years, id: \.self) { year in
                        yearPill(year: year)
                            .id(year)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
            .onAppear {
                scrollYearIntoView(proxy: proxy, year: selectedYear)
            }
            .onChange(of: selectedYear) { _, newValue in
                scrollYearIntoView(proxy: proxy, year: newValue)
            }
        }
    }

    private func scrollYearIntoView(proxy: ScrollViewProxy, year: Int) {
        withAnimation(.easeInOut(duration: 0.28)) {
            proxy.scrollTo(year, anchor: .center)
        }
    }

    private func yearPill(year: Int) -> some View {
        let isOn = selectedYear == year
        return Button {
            selectedYear = year
        } label: {
            Text(String(year))
                .font(.system(.subheadline, design: .rounded).weight(isOn ? .bold : .semibold))
                .foregroundStyle(isOn ? AppTheme.ink : AppTheme.inkMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    Capsule(style: .continuous)
                        .fill(isOn ? Color.accentColor.opacity(colorScheme == .dark ? 0.22 : 0.16) : AppTheme.surface.opacity(0.92))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isOn ? Color.accentColor.opacity(0.55) : AppTheme.hairline,
                            lineWidth: isOn ? 1.5 : 1
                        )
                }
                .shadow(
                    color: isOn ? Color.accentColor.opacity(0.18) : Color.black.opacity(colorScheme == .dark ? 0.12 : 0.06),
                    radius: isOn ? 8 : 4,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(year))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var monthLattice: some View {
        LazyVGrid(columns: monthColumns, spacing: 10) {
            ForEach(1 ... 12, id: \.self) { month in
                monthCell(month: month)
            }
        }
    }

    private func monthCell(month: Int) -> some View {
        let isAnchor = isAnchorMonth(month)
        return Button {
            onSelect(selectedYear, month)
            dismiss()
        } label: {
            Text(math.shortMonthTitle(month: month))
                .font(.system(.callout, design: .rounded).weight(isAnchor ? .bold : .semibold))
                .foregroundStyle(isAnchor ? Color.accentColor : AppTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background {
                    RoundedRectangle(cornerRadius: AppTheme.cornerCell, style: .continuous)
                        .fill(isAnchor ? Color.accentColor.opacity(colorScheme == .dark ? 0.14 : 0.10) : AppTheme.surface)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cornerCell, style: .continuous)
                        .strokeBorder(
                            monthCellBorder(isAnchor: isAnchor),
                            lineWidth: isAnchor ? 1.5 : 1
                        )
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.14 : 0.08),
                    radius: isAnchor ? 10 : 6,
                    y: 3
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(math.fullMonthTitle(month: month))
        .accessibilityHint("Shows \(String(selectedYear)) \(math.fullMonthTitle(month: month)) in the journal")
    }

    private func monthCellBorder(isAnchor: Bool) -> LinearGradient {
        if isAnchor {
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.75), Color.accentColor.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(colors: [AppTheme.hairline, AppTheme.hairline], startPoint: .top, endPoint: .bottom)
    }

    private func isAnchorMonth(_ month: Int) -> Bool {
        let y = calendar.component(.year, from: anchorMonth)
        let m = calendar.component(.month, from: anchorMonth)
        return selectedYear == y && month == m
    }
}
