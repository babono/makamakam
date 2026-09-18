import SwiftUI
import CoreLocation

/// The cemetery seen from above, drawn to scale from surveyed offsets.
///
/// It replaces the row-and-plot grid, which described a filing system rather
/// than a place: at Pemakaman Islam II the markers sit where the ground allowed,
/// around a tree, in clusters, at angles. A grid of that is a drawing of
/// somewhere else.
///
/// What makes this trustworthy is *relative* accuracy. Offsets come from a tape
/// measure, so the distances between graves are right to the centimetre; the
/// whole plot shares one GPS error instead of each grave carrying its own. The
/// visitor is therefore not matching a pin to a grave — they are matching a
/// shape to what is in front of them, and a shape that is four metres out is
/// still unmistakably that shape.
struct SitePlan: View {
    let site: Site
    let graves: [Grave]
    let target: Grave?
    /// Where the person is, and how well that is known. Both are drawn, because
    /// the circle is the honest part (PRD §7).
    var here: CLLocation?
    /// Degrees true. The plan turns so that what is drawn matches what is faced.
    var heading: Double?
    var onSelect: ((Grave) -> Void)?
    /// False where a parent transforms this view and tests taps itself.
    var handlesOwnTaps: Bool = true
    /// Set by a parent that hit-tests for us, so the right grave lights up.
    var highlighted: String?

    @Environment(Lang.self) private var lang
    @State private var selected: String?

    /// A grave is about a metre by two.
    private let graveLength: Double = 2.0
    private let graveWidth: Double = 0.9

    /// How far the drawing is turned, in radians. Zero until the compass is
    /// worth trusting, and then the plan faces the way the reader does.
    private var turn: Double {
        guard let heading else { return 0 }
        return -heading * .pi / 180
    }

    /// Turns a point about the middle of the plot. Doing this in the maths
    /// rather than with `rotationEffect` keeps everything inside the frame — a
    /// rotated view spills past its bounds, and clipping it cuts off graves.
    private func turned(_ x: Double, _ y: Double) -> (x: Double, y: Double) {
        guard turn != 0 else { return (x, y) }
        let centre = plotCentre
        let dx = x - centre.x
        let dy = y - centre.y
        return (
            x: centre.x + dx * cos(turn) - dy * sin(turn),
            y: centre.y + dx * sin(turn) + dy * cos(turn)
        )
    }

    private var plotCentre: (x: Double, y: Double) {
        let plot = rawPlotBounds
        return ((plot.minX + plot.maxX) / 2, (plot.minY + plot.maxY) / 2)
    }

    private var positions: [(grave: Grave, x: Double, y: Double)] {
        graves.map { grave in
            let position = grave.localPosition(origin: site)
            let rotated = turned(position.x, position.y)
            return (grave, rotated.x, rotated.y)
        }
    }

    private var corners: [(x: Double, y: Double)] {
        (site.boundary ?? []).compactMap { corner in
            guard corner.count == 2 else { return nil }
            return turned(corner[0], corner[1])
        }
    }

    /// The plot before it is turned — the frame of reference the turn happens in.
    private var rawPlotBounds: (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        var xs = graves.map { $0.localPosition(origin: site).x }
        var ys = graves.map { $0.localPosition(origin: site).y }
        for corner in site.boundary ?? [] where corner.count == 2 {
            xs.append(corner[0])
            ys.append(corner[1])
        }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else {
            return (0, 0, 1, 1)
        }
        return (minX, minY, maxX, maxY)
    }

    private var herePosition: (x: Double, y: Double)? {
        guard let here else { return nil }
        let raw = Geo.localOffset(of: here.coordinate, from: site.coordinate)
        let position = turned(raw.x, raw.y)
        // Someone at the office is a thousand kilometres away, and fitting them
        // into the frame shrinks the cemetery to a speck. The plan is a drawing
        // of the burial ground; a reader who is not in it simply is not on it.
        let plot = plotBounds
        let margin = 40.0
        let inside = position.x > plot.minX - margin && position.x < plot.maxX + margin
            && position.y > plot.minY - margin && position.y < plot.maxY + margin
        return inside ? position : nil
    }

    /// Everything fixed to the ground, as drawn: the wall and the graves.
    private var plotBounds: (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        var xs = positions.map(\.x)
        var ys = positions.map(\.y)
        for corner in corners {
            xs.append(corner.x)
            ys.append(corner.y)
        }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else {
            return (0, 0, 1, 1)
        }
        return (minX, minY, maxX, maxY)
    }

    /// What must fit on screen: the plot, plus the reader when they are in it.
    private var bounds: (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        let plot = plotBounds
        var minX = plot.minX, maxX = plot.maxX, minY = plot.minY, maxY = plot.maxY
        if let herePosition {
            minX = min(minX, herePosition.x); maxX = max(maxX, herePosition.x)
            minY = min(minY, herePosition.y); maxY = max(maxY, herePosition.y)
        }
        let margin = 3.0
        return (minX - margin, minY - margin, maxX + margin, maxY + margin)
    }

    /// Whether the reader is drawn on the plan at all.
    var showsReader: Bool { herePosition != nil }

    /// How metres on the ground become points on the canvas. Both the drawing
    /// and the tap test use this, so a tap can never land somewhere the drawing
    /// did not put a grave.
    struct Layout {
        let box: (minX: Double, minY: Double, maxX: Double, maxY: Double)
        let scale: Double
        let offsetX: Double
        let offsetY: Double

        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(
                x: offsetX + (x - box.minX) * scale,
                // North is up, so y grows upward on the ground and downward on
                // the screen.
                y: offsetY + (box.maxY - y) * scale
            )
        }
    }

    func layout(in size: CGSize) -> Layout {
        let box = bounds
        let spanX = max(box.maxX - box.minX, 1)
        let spanY = max(box.maxY - box.minY, 1)
        // One scale for both axes: a plan that stretches one way is a lie about
        // the shape, and the shape is the whole point.
        let scale = min(size.width / spanX, size.height / spanY)
        return Layout(
            box: box,
            scale: scale,
            offsetX: (size.width - spanX * scale) / 2,
            offsetY: (size.height - spanY * scale) / 2
        )
    }

    /// The grave nearest a point on the canvas, if a finger could plausibly have
    /// meant it. A fingertip is wider than a grave at this scale, so "nearest
    /// within reach" beats "inside the shape".
    func grave(at point: CGPoint, in size: CGSize) -> Grave? {
        let layout = layout(in: size)
        // A fingertip is about 44 points across; a grave at fitted zoom is
        // barely three. The reach grows with the drawing so that zooming in
        // makes the target easier, never harder.
        let reach = max(26, 1.6 * layout.scale)
        var best: (grave: Grave, distance: Double)?

        for entry in positions {
            let centre = layout.point(entry.x, entry.y)
            let distance = hypot(point.x - centre.x, point.y - centre.y)
            if distance <= reach, best == nil || distance < best!.distance {
                best = (entry.grave, distance)
            }
        }
        return best?.grave
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = layout(in: proxy.size)
            let box = layout.box
            let scale = layout.scale

            Canvas { context, _ in
                func point(_ x: Double, _ y: Double) -> CGPoint {
                    layout.point(x, y)
                }

                // The wall
                if corners.count >= 3 {
                    var path = Path()
                    for (index, corner) in corners.enumerated() {
                        let position = point(corner.x, corner.y)
                        if index == 0 { path.move(to: position) } else { path.addLine(to: position) }
                    }
                    path.closeSubpath()
                    context.fill(path, with: .color(Palette.grassDeep.opacity(0.85)))
                    context.stroke(path, with: .color(Palette.grassDeep), lineWidth: 2)
                }

                // The graves, as the oblongs they are
                let siteBearing = site.graveBearing ?? 0
                for entry in positions {
                    let bearing = entry.grave.bearing ?? siteBearing
                    // Each stone turns with the ground it is drawn on.
                    let bearingOnScreen = bearing + (turn * 180 / .pi)
                    let isTarget = entry.grave.id == target?.id
                    let isSelected = entry.grave.id == (highlighted ?? selected)
                    let centre = point(entry.x, entry.y)
                    let length = graveLength * scale
                    let width = graveWidth * scale

                    var shape = Path(
                        roundedRect: CGRect(
                            x: -width / 2, y: -length / 2, width: width, height: length
                        ),
                        cornerRadius: min(width, length) * 0.3
                    )
                    shape = shape.applying(
                        CGAffineTransform(rotationAngle: bearingOnScreen * .pi / 180)
                            .concatenating(CGAffineTransform(translationX: centre.x, y: centre.y))
                    )

                    if isTarget {
                        context.fill(shape, with: .color(Palette.plaque))
                        context.stroke(shape, with: .color(Palette.engraved), lineWidth: 2)
                    } else if isSelected {
                        context.fill(shape, with: .color(Palette.plaque))
                        context.stroke(shape, with: .color(Palette.ink), lineWidth: 1.5)
                    } else {
                        context.fill(shape, with: .color(Palette.granite))
                        context.stroke(shape, with: .color(Palette.graniteDeep.opacity(0.7)), lineWidth: 0.5)
                    }
                }

                // The person: a circle the size of what the phone actually
                // knows, never a dot pretending to be a position.
                if let herePosition, let here {
                    let centre = point(herePosition.x, herePosition.y)
                    let accuracy = max(here.horizontalAccuracy, 1) * scale
                    let circle = Path(
                        ellipseIn: CGRect(
                            x: centre.x - accuracy, y: centre.y - accuracy,
                            width: accuracy * 2, height: accuracy * 2
                        )
                    )
                    context.fill(circle, with: .color(Palette.ink.opacity(0.14)))
                    context.stroke(circle, with: .color(Palette.ink.opacity(0.45)), lineWidth: 1)

                    let dot = Path(
                        ellipseIn: CGRect(x: centre.x - 4, y: centre.y - 4, width: 8, height: 8)
                    )
                    context.fill(dot, with: .color(Palette.ink))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: turn)
            .contentShape(Rectangle())
            // Switched off, not merely ignored, when a parent hit-tests for us.
            //
            // A gesture that is attached and then does nothing still *takes* the
            // tap: a child's gesture wins over an ancestor's, so the full-screen
            // plan's own tap never fired and no grave could be selected. The
            // mask is what actually lets the tap through.
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        guard let tapped = grave(at: value.location, in: proxy.size) else { return }
                        selected = tapped.id
                        onSelect?(tapped)
                    },
                including: handlesOwnTaps ? .all : .subviews
            )
        }
        .accessibilityLabel(lang.t(.planAccessibility, site.name, graves.count))
    }

}
