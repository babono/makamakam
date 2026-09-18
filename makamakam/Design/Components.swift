import SwiftUI

/// Granite ground under every screen.
struct Ground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(GraniteGround())
            .tint(Palette.grass)
    }
}

extension View {
    func ground() -> some View { modifier(Ground()) }

    /// Slow fades, never bounces (PRD §12).
    func quiet(_ value: some Equatable) -> some View {
        animation(.easeInOut(duration: 0.35), value: value)
    }
}

/// A marble plaque set into the granite. Everything the app says sits on one,
/// the way every name in that cemetery sits on a white panel cut into the stone.
struct Plaque<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Palette.plaque)
                    .shadow(color: .black.opacity(0.14), radius: 3, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 1)
    }
}

/// A section label: small, soft, generously tracked.
struct Eyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.spoken(12, weight: .medium))
            .tracking(1.2)
            .foregroundStyle(Palette.inkSoft)
    }
}

/// Grass, because it is the thing you walk on to get there.
struct PrimaryButtonStyle: ButtonStyle {
    var filled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.spoken(17, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(filled ? Palette.plaque : Palette.grassDeep)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(filled ? Palette.grass : Palette.plaque)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(filled ? Color.clear : Palette.grass, lineWidth: 1.2)
                    )
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Never render an unverified record with the same confidence as a verified one
/// (PRD §8).
struct VerificationMark: View {
    let verified: Bool
    @Environment(Lang.self) private var lang

    var body: some View {
        Text(lang.t(verified ? .verifiedYes : .verifiedNo))
            .font(.spoken(12))
            .foregroundStyle(verified ? Palette.grassDeep : Palette.inkSoft)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(verified ? Palette.grassPale.opacity(0.55) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(verified ? Palette.grassPale : Palette.hairline, lineWidth: 1)
                    )
            )
    }
}

/// The small pill under a door, saying plainly that this one needs presence.
struct LockNote: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.spoken(12))
            .foregroundStyle(Palette.inkSoft)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 3).stroke(Palette.hairline, lineWidth: 1))
    }
}


/// Shown wherever the hidden field override — not the person's actual position —
/// is what opened a presence-locked screen. The locks are the argument of this
/// product, so it must always be obvious when one has been stood down.
struct PretendPresenceBadge: View {
    @Environment(Presence.self) private var presence
    @Environment(Lang.self) private var lang

    var body: some View {
        if presence.pretendPresent {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 11, weight: .medium))
                Text(lang.t(.pretendPresentBadge))
                    .font(.spoken(12))
            }
            .foregroundStyle(Palette.engraved)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Palette.engraved.opacity(0.4), lineWidth: 1)
            )
        }
    }
}
