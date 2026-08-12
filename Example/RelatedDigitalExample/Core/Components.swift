//
//  Components.swift
//  RelatedDigitalExample
//
//  Shared building blocks. Screens are assembled almost entirely out of these
//  so that adding a new SDK surface stays a few lines of declarative code.
//

import SwiftUI

// MARK: - Screen scaffold

/// Standard scrolling screen: themed background, consistent padding, title.
struct Screen<Content: View>: View {
    var title: String
    var subtitle: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, Theme.Spacing.xs)
                }
                content()
            }
            .padding(Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Card

/// Grouped container with an optional header and trailing accessory.
struct Card<Content: View>: View {
    var title: String?
    var systemImage: String?
    var footnote: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                HStack(spacing: Theme.Spacing.s) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    Text(title.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.m)
                .padding(.bottom, Theme.Spacing.s)
            }

            VStack(spacing: 0) { content() }

            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.vertical, Theme.Spacing.m)
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.separator, lineWidth: 1)
        )
    }
}

/// Hairline used between rows inside a `Card`.
struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: 1)
            .padding(.leading, Theme.Spacing.l)
    }
}

// MARK: - Rows

/// Tappable row that triggers an SDK call.
struct ActionRow: View {
    var title: String
    var subtitle: String?
    var systemImage: String?
    var tint: Color = Theme.accent
    var showsChevron = false
    var isEnabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.m) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 26, height: 26)
                        .background(tint.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(isEnabled ? Theme.textPrimary : Theme.textTertiary)
                        .multilineTextAlignment(.leading)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: Theme.Spacing.s)
                Image(systemName: showsChevron ? "chevron.right" : "arrow.up.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

/// Read-only key/value row. Long-press or tap the icon to copy the value.
struct InfoRow: View {
    var label: String
    var value: String?
    var isMonospaced = true
    var placeholder = "—"

    @EnvironmentObject private var toast: ToastCenter

    private var resolved: String { (value?.isEmpty == false ? value : nil) ?? placeholder }
    private var isEmpty: Bool { value?.isEmpty != false }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 128, alignment: .leading)

            Text(resolved)
                .font(isMonospaced ? Theme.mono(12) : .subheadline)
                .foregroundStyle(isEmpty ? Theme.textTertiary : Theme.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !isEmpty {
                Button {
                    UIPasteboard.general.string = value
                    toast.show("\(label) copied", icon: "doc.on.doc.fill")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }
}

/// Toggle row bound to an SDK flag.
struct SwitchRow: View {
    var title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Theme.Spacing.s)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }
}

/// Single-line text entry row.
struct FieldRow: View {
    var label: String
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 128, alignment: .leading)
            TextField(placeholder, text: $text)
                .font(Theme.mono(13))
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }
}

// MARK: - Small elements

/// Status chip: `Push · granted`, `SDK · ready`, …
struct Pill: View {
    var text: String
    var tint: Color
    var systemImage: String?

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 10, weight: .bold))
            }
            Text(text).font(.caption2.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 5)
        .background(tint.opacity(0.14))
        .clipShape(Capsule())
    }
}

/// Full-width primary button used for the main action of a screen.
struct PrimaryButton: View {
    var title: String
    var systemImage: String?
    var tint: Color = Theme.accent
    var isLoading = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else if let systemImage {
                    Image(systemName: systemImage).font(.subheadline.weight(.semibold))
                }
                Text(title).font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tint)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

/// Monospaced payload preview with a copy affordance.
struct PayloadBlock: View {
    var text: String
    var maxHeight: CGFloat? = nil

    @EnvironmentObject private var toast: ToastCenter

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: maxHeight)

            Button {
                UIPasteboard.general.string = text
                toast.show("Copied to clipboard", icon: "doc.on.doc.fill")
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption.weight(.medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.accent)
        }
        .padding(Theme.Spacing.m)
        .background(Theme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }
}

/// Inline explanatory note, quieter than a `Card`.
struct Note: View {
    var text: String
    var systemImage = "info.circle.fill"
    var tint: Color = Theme.info

    init(_ text: String, systemImage: String = "info.circle.fill", tint: Color = Theme.info) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

/// Prominent inline warning with a title.
struct Banner: View {
    var title: String
    var message: String
    var systemImage: String
    var tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

/// Placeholder shown when a list has nothing to display yet.
struct EmptyState: View {
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(Theme.textTertiary)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
        .padding(.horizontal, Theme.Spacing.l)
    }
}

// MARK: - Toasts

/// Lightweight feedback for actions that have no visible UI of their own —
/// which is most SDK calls in this app.
@MainActor
final class ToastCenter: ObservableObject {

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        var message: String
        var icon: String
        var tint: Color

        static func == (lhs: Toast, rhs: Toast) -> Bool { lhs.id == rhs.id }
    }

    @Published private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, icon: String = "checkmark.circle.fill", tint: Color = Theme.success) {
        current = Toast(message: message, icon: icon, tint: tint)
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            self?.current = nil
        }
    }

    func showError(_ message: String) {
        show(message, icon: "exclamationmark.triangle.fill", tint: Theme.danger)
    }
}

struct ToastOverlay: ViewModifier {
    @EnvironmentObject private var toast: ToastCenter

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let item = toast.current {
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: item.icon).foregroundStyle(item.tint)
                    Text(item.message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.m)
                .background(Theme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Theme.separator, lineWidth: 1))
                .shadow(color: .black.opacity(0.18), radius: 18, y: 6)
                // Clears the tab bar: the overlay sits outside the TabView, so
                // the tab bar is not part of its safe-area inset.
                .padding(.bottom, 96)
                .padding(.horizontal, Theme.Spacing.l)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: toast.current)
    }
}

extension View {
    func toastOverlay() -> some View { modifier(ToastOverlay()) }
}
