import SwiftUI
import UIKit

/// The speckle in granite, generated once and tiled.
///
/// A drawn tile rather than a bundled photograph: it costs nothing, it works
/// offline, and it stays legible in direct sun because the contrast range is
/// controlled rather than whatever a camera happened to capture.
enum GraniteTexture {
    static let tile: Image = Image(uiImage: makeTile())

    private static let size = 96

    private static func makeTile() -> UIImage {
        let side = CGFloat(size)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { context in
            let cg = context.cgContext
            cg.setFillColor(UIColor.clear.cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: side, height: side))

            // Deterministic, so the grain never shifts between launches.
            var seed: UInt64 = 0x5EED_6A5A
            func random() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double((seed >> 33) % 10_000) / 10_000
            }

            // Fine grain across the whole tile.
            for x in 0..<size {
                for y in 0..<size {
                    let value = random()
                    guard value > 0.55 else { continue }
                    let dark = value > 0.92
                    let alpha = dark ? 0.10 : 0.045
                    cg.setFillColor(UIColor(white: dark ? 0 : 1, alpha: alpha).cgColor)
                    cg.fill(CGRect(x: CGFloat(x), y: CGFloat(y), width: 1, height: 1))
                }
            }

            // The larger flecks that make granite read as stone rather than static.
            for _ in 0..<70 {
                let x = random() * side
                let y = random() * side
                let r = 0.6 + random() * 1.4
                let dark = random() > 0.45
                cg.setFillColor(UIColor(white: dark ? 0 : 1, alpha: dark ? 0.13 : 0.10).cgColor)
                cg.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
            }
        }
    }
}

/// Granite ground: the colour, then the grain tiled over it.
struct GraniteGround: View {
    var body: some View {
        ZStack {
            Palette.granite
            GraniteTexture.tile
                .resizable(resizingMode: .tile)
                .opacity(0.9)
        }
        .ignoresSafeArea()
    }
}
