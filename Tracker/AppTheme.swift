//
//  AppTheme.swift
//  Tracker
//

import SwiftUI
import UIKit

/// User-selected interface style, persisted with `@AppStorage("appAppearance")`.
enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    /// `nil` means follow the system setting.
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// Non-optional scheme for APIs that do not accept `nil`. `.system` maps to `.light` as a neutral fallback — prefer `preferredColorScheme` for `.preferredColorScheme(_:)`.
    var colorScheme: ColorScheme {
        preferredColorScheme ?? .light
    }
}

enum AppTheme {
    // MARK: Field (full-screen)

    /// Tea-stained paper (light) / lamp-lit inkwell (dark). Dark is intentionally deeper than `surface` so cards read as elevated.
    static var journalBackground: Color {
        Color(uiColor: UIColor { t in
            if t.userInterfaceStyle == .dark {
                UIColor(red: 0.097, green: 0.080, blue: 0.072, alpha: 1)
            } else {
                UIColor(red: 0.964, green: 0.940, blue: 0.901, alpha: 1)
            }
        })
    }

    // MARK: Surfaces

    /// Cards, list rows, and the weekday strip — clearly lighter than `journalBackground` in dark mode (previously almost the same RGB).
    static var surface: Color {
        Color(uiColor: UIColor { t in
            if t.userInterfaceStyle == .dark {
                // Slightly lifted vs. background so list/calendar cells feel a bit less heavy.
                UIColor(red: 0.212, green: 0.184, blue: 0.168, alpha: 1)
            } else {
                UIColor(red: 0.995, green: 0.989, blue: 0.981, alpha: 1)
            }
        })
    }

    /// Segmented control track — recessed pocket between field and raised surface.
    static var segmentedChromeFill: Color {
        Color(uiColor: UIColor { t in
            if t.userInterfaceStyle == .dark {
                UIColor(red: 0.118, green: 0.099, blue: 0.090, alpha: 1)
            } else {
                UIColor(red: 0.926, green: 0.904, blue: 0.858, alpha: 1)
            }
        })
    }

    // MARK: Type & chrome

    static var ink: Color {
        Color(uiColor: UIColor { t in
            if t.userInterfaceStyle == .dark {
                UIColor(red: 0.945, green: 0.918, blue: 0.872, alpha: 1)
            } else {
                UIColor(red: 0.168, green: 0.138, blue: 0.122, alpha: 1)
            }
        })
    }

    static var inkMuted: Color {
        Color(uiColor: UIColor { t in
            if t.userInterfaceStyle == .dark {
                // Brighter than before so captions, weekdays, and secondary body read clearly on charcoal.
                UIColor(red: 0.765, green: 0.705, blue: 0.645, alpha: 1)
            } else {
                UIColor(red: 0.448, green: 0.412, blue: 0.382, alpha: 1)
            }
        })
    }

    // MARK: Label stripes (shared calendar chips & pickers)

    /// Bottom blend of the vertical color bar in a label chip (higher = bar stays vivid longer).
    static func labelStripeBarBottomBlend(for colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? 0.88 : 0.78
    }

    static func labelChipWashOpacity(for colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? 0.28 : 0.22
    }

    static func labelChipOutlineOpacity(for colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? 0.42 : 0.28
    }

    /// Day sheet label grid: left bar when unselected, cell fill, outline — tuned so picks read in dark mode.
    static func labelPickerBarOpacity(selected: Bool, colorScheme: ColorScheme) -> CGFloat {
        if selected { return 1 }
        return colorScheme == .dark ? 0.56 : 0.45
    }

    static func labelPickerFillOpacity(selected: Bool, colorScheme: ColorScheme) -> CGFloat {
        switch (selected, colorScheme == .dark) {
        case (true, true): return 0.34
        case (true, false): return 0.26
        case (false, true): return 0.13
        case (false, false): return 0.10
        }
    }

    static func labelPickerStrokeOpacity(selected: Bool, colorScheme: ColorScheme) -> CGFloat {
        switch (selected, colorScheme == .dark) {
        case (true, true): return 0.55
        case (true, false): return 0.42
        case (false, true): return 0.28
        case (false, false): return 0.22
        }
    }

    /// Fallback stripe when `WorkoutLog.labelId` no longer matches any label.
    static func missingLabelStripe(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.62, green: 0.58, blue: 0.54)
            : Color(red: 0.52, green: 0.50, blue: 0.47)
    }

    /// Panel and cell outlines — warm umber in light, soft rim light in dark (avoids cool `Color.primary` on custom bases).
    static var hairline: Color {
        Color(uiColor: UIColor { t in
            if t.userInterfaceStyle == .dark {
                UIColor(white: 1, alpha: 0.11)
            } else {
                UIColor(red: 0.32, green: 0.26, blue: 0.20, alpha: 0.11)
            }
        })
    }

    /// Outer edge on segmented “chrome” capsules.
    static var chromeRim: Color {
        Color(uiColor: UIColor { t in
            if t.userInterfaceStyle == .dark {
                UIColor(white: 1, alpha: 0.15)
            } else {
                UIColor(red: 0.30, green: 0.24, blue: 0.19, alpha: 0.10)
            }
        })
    }

    static let cornerChip: CGFloat = 6
    static let cornerCell: CGFloat = 14
    static let cornerPanel: CGFloat = 16

    struct JournalBackdrop: View {
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            ZStack {
                AppTheme.journalBackground
                // Quiet vignette + top bloom so the field feels spatial, not a flat swatch.
                LinearGradient(
                    stops: [
                        .init(
                            color: (colorScheme == .light ? Color.white : Color(red: 0.55, green: 0.48, blue: 0.42))
                                .opacity(colorScheme == .light ? 0.07 : 0.045),
                            location: 0
                        ),
                        .init(color: .clear, location: 0.42),
                        .init(
                            color: (colorScheme == .light
                                ? Color(red: 0.42, green: 0.32, blue: 0.22)
                                : Color.black)
                                .opacity(colorScheme == .light ? 0.05 : 0.34),
                            location: 1
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    /// Outline for settings / header circle buttons — warm in light, soft highlight in dark.
    static func circleButtonRing(pressed: Bool, colorScheme: ColorScheme) -> Color {
        switch (pressed, colorScheme == .dark) {
        case (true, true): Color.white.opacity(0.42)
        case (true, false): Color.black.opacity(0.26)
        case (false, true): Color.white.opacity(0.16)
        case (false, false): Color(red: 0.30, green: 0.24, blue: 0.19).opacity(0.12)
        }
    }
}

struct JournalCircleButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundStyle(AppTheme.ink.opacity(configuration.isPressed ? 0.55 : 1))
            .frame(width: 42, height: 42)
            .background {
                ZStack {
                    Circle()
                        .fill(AppTheme.surface)
                    Circle()
                        .fill(
                            Color.black.opacity(
                                configuration.isPressed
                                    ? (colorScheme == .dark ? 0.28 : 0.12)
                                    : 0
                            )
                        )
                }
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(configuration.isPressed ? 0.22 : 0.52)
                        : Color.black.opacity(configuration.isPressed ? 0.05 : 0.18),
                    radius: configuration.isPressed ? 2 : (colorScheme == .dark ? 12 : 10),
                    y: configuration.isPressed ? 0 : (colorScheme == .dark ? 5 : 5)
                )
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        AppTheme.circleButtonRing(pressed: configuration.isPressed, colorScheme: colorScheme),
                        lineWidth: configuration.isPressed ? 1.5 : 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.84 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct ScopeSegmentedStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(4)
            .background {
                Capsule(style: .continuous)
                    .fill(AppTheme.segmentedChromeFill)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.38 : 0.12),
                        radius: colorScheme == .dark ? 12 : 14,
                        y: colorScheme == .dark ? 6 : 7
                    )
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(AppTheme.chromeRim, lineWidth: 1)
            }
    }
}

extension View {
    func journalScopeChrome() -> some View {
        modifier(ScopeSegmentedStyleModifier())
    }
}
