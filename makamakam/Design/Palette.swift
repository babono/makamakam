import SwiftUI

/// Drawn from the material hierarchy of an Indonesian cemetery headstone:
/// speckled granite ground, a white marble plaque set into it, the name cut and
/// painted into the plaque, grass all around.
///
/// Granite is the ground, marble is every surface that carries words, and the
/// engraved red appears once — on the arrival screen, where you confirm a name.
/// Grass is for the things you act on.
enum Palette {
    /// Granite. The ground under every screen, carrying a noise tile.
    static let granite      = Color(hex: 0xC6C5C0)
    static let graniteDeep  = Color(hex: 0xA9A8A3)

    /// Marble plaque. Cards, sheets, anything a name or a voice sits on.
    static let plaque       = Color(hex: 0xFBFAF7)

    /// Cut into the stone.
    static let ink          = Color(hex: 0x16181A)
    static let inkSoft      = Color(hex: 0x5A5C5B)

    static let hairline     = Color(hex: 0xD5D4CF)

    /// Grass. Buttons, and the ground of the section plan.
    static let grass        = Color(hex: 0x4A7A3B)
    static let grassDeep    = Color(hex: 0x33562A)
    static let grassPale    = Color(hex: 0xBFCDB0)

    /// The painted lettering. Arrival screen only.
    static let engraved     = Color(hex: 0xA8342A)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
