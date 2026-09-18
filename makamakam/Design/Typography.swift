import SwiftUI

/// Two voices only.
///
/// `engraved` — a serif, for names of the deceased and for memories other people
/// left. Those are voices, and names are what gets engraved in stone.
/// `spoken`  — the app's own voice, a sans.
///
/// Newsreader and Instrument Sans are not bundled (Apple frameworks only, and no
/// licence check has been done), so these resolve to the system serif and the
/// system sans. Swapping in the real faces later means editing this file alone.
extension Font {
    static func engraved(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func spoken(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Arabic script needs more leading and a larger optical size than Latin.
    static func arabic(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
}
