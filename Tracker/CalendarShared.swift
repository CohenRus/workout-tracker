//
//  CalendarShared.swift
//  Tracker
//

import SwiftUI

enum CalendarSharedViews {
    static func strokeGradient(isToday: Bool) -> LinearGradient {
        if isToday {
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.95), Color.accentColor.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(colors: [AppTheme.hairline, AppTheme.hairline], startPoint: .top, endPoint: .bottom)
    }

    static func weekStrokeGradient(isToday: Bool) -> LinearGradient {
        if isToday {
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.85), Color.accentColor.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(colors: [AppTheme.hairline, AppTheme.hairline], startPoint: .top, endPoint: .bottom)
    }

    @ViewBuilder
    static func workoutPreviewStripe(title: String, color: Color, compact: Bool, colorScheme: ColorScheme) -> some View {
        let font: Font = compact
            ? .system(.caption2, design: .rounded).weight(.semibold)
            : .system(.caption, design: .rounded).weight(.semibold)
        let barWidth: CGFloat = compact ? 2 : 4
        let verticalPad: CGFloat = compact ? 2 : 6
        let horizontalPad: CGFloat = compact ? 4 : 8

        let barBlend = AppTheme.labelStripeBarBottomBlend(for: colorScheme)
        let wash = AppTheme.labelChipWashOpacity(for: colorScheme)
        let rim = AppTheme.labelChipOutlineOpacity(for: colorScheme)

        HStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(barBlend)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: barWidth)

            Text(title)
                .font(font)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(compact ? 1 : 4)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.72)
                .padding(.vertical, verticalPad)
                .padding(.horizontal, horizontalPad)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerChip, style: .continuous)
                .fill(color.opacity(wash))
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerChip, style: .continuous)
                .strokeBorder(color.opacity(rim), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerChip, style: .continuous))
    }
}
