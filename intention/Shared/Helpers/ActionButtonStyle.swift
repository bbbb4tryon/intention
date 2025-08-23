//
//  ActionButtonStyle.swift
//  intention
//
//  Created by Benjamin Tryon on 6/12/25.

import SwiftUI

struct ActionButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: ThemeManager
    var screen: ScreenName
    var role: Role = .primary
    var isLoading = false

    enum Role { case primary, secondary, destructive }

    func makeBody(configuration: Configuration) -> some View {
        let palette = theme.palette(for: screen)
        let disabled = !(Environment(\.isEnabled).wrappedValue)

        let bg: Color = switch role {
        case .primary: palette.accent
        case .secondary: palette.primary
        case .destructive: palette.danger
        }
        let fg: Color = .white   // buttons should not rely on themed text colors

        HStack(spacing: 8) {
            if isLoading { ProgressView().progressViewStyle(.circular) }
            configuration.label
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .font(theme.fontTheme.toFont(.headline))
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.vertical, 10)
        .background(bg)
        .foregroundStyle(fg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(disabled ? 0.5 : (configuration.isPressed ? 0.85 : 1))
        .scaleEffect(configuration.isPressed && !disabled ? 0.97 : 1)
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isButton)
    }
}

extension Button {
    func primaryActionStyle(screen: ScreenName) -> some View {
        self.buttonStyle(ActionButtonStyle(screen: screen, role: .primary))
    }
    func secondaryActionStyle(screen: ScreenName) -> some View {
        self.buttonStyle(ActionButtonStyle(screen: screen, role: .secondary))
    }
    func destructiveActionStyle(screen: ScreenName) -> some View {
        self.buttonStyle(ActionButtonStyle(screen: screen, role: .destructive))
    }
}
