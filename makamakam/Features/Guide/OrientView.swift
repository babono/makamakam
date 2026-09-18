import SwiftUI

/// Screen 2. A drawn section plan: rows as labelled lines, graves as cells, the
/// target filled. A `Canvas`, not MapKit and not satellite — at grave scale a
/// map pin is wider than the grave it claims to mark (PRD §7).
struct OrientView: View {
    let grave: Grave
    var onWalk: () -> Void

    @Environment(GraveStore.self) private var store
    @Environment(LocationService.self) private var location
    @Environment(Lang.self) private var lang
    @State private var showFullPlan = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(store.site.name)
                Text(grave.name)
                    .font(.engraved(28))
                    .foregroundStyle(Palette.ink)

            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 20)

            VStack(spacing: 8) {
                SitePlan(
                    site: store.site,
                    graves: store.graves,
                    target: grave,
                    here: location.location,
                    heading: location.headingIsTrustworthy ? location.heading : nil
                )
                .frame(height: 300)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 6).fill(Palette.plaque))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.hairline, lineWidth: 1))

                HStack(spacing: 10) {
                    Image(systemName: location.headingIsTrustworthy ? "location.north.line" : "arrow.up")
                        .font(.system(size: 10))
                    Text(lang.t(location.headingIsTrustworthy ? .planFacing : .planNorthUp))
                        .font(.spoken(12))
                    Spacer(minLength: 8)
                    Button { showFullPlan = true } label: {
                        Label(lang.t(.planExpand), systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.spoken(12, weight: .medium))
                            .foregroundStyle(Palette.grassDeep)
                    }
                }
                .foregroundStyle(Palette.inkSoft)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 16)

            VStack(alignment: .leading, spacing: 14) {
                Plaque {
                    Text(grave.landmark)
                        .font(.spoken(15))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: onWalk) { Text(lang.t(.orientWalk)) }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .fullScreenCover(isPresented: $showFullPlan) {
            PlanScreen(site: store.site, graves: store.graves, target: grave)
        }
    }
}

/// The plan is drawn from row and plot integers, never from coordinates: the
/// survey knows exactly which cell this is, and pretending otherwise would draw
/// a precise-looking fiction.
///
/// Grass under stone, which is what you are actually standing on.
struct SectionPlan: View {
    let store: GraveStore
    let target: Grave
    /// When set, the plan is read-only decoration rather than the main event.
    var compact: Bool = false

    @Environment(Lang.self) private var lang
    @State private var showFullPlan = false

    private var rows: Int { store.site.rows }
    private var plots: Int { store.site.plotsPerRow }

    var body: some View {
        Canvas { context, size in
            let labelWidth: CGFloat = compact ? 24 : 32
            let gap: CGFloat = compact ? 4 : 6
            let usableWidth = size.width - labelWidth
            let cellWidth = (usableWidth - gap * CGFloat(plots - 1)) / CGFloat(plots)
            let cellHeight = (size.height - gap * CGFloat(rows - 1)) / CGFloat(rows)

            for row in 1...rows {
                let y = CGFloat(row - 1) * (cellHeight + gap)

                // Row number, as painted on the kerb.
                let label = Text("\(row)")
                    .font(.system(size: compact ? 9 : 12))
                    .foregroundStyle(Palette.plaque.opacity(0.9))
                context.draw(label, at: CGPoint(x: labelWidth / 2, y: y + cellHeight / 2), anchor: .center)

                // The walkway between rows — rows are what GPS can actually resolve.
                let line = Path { p in
                    p.move(to: CGPoint(x: labelWidth - gap, y: y + cellHeight / 2))
                    p.addLine(to: CGPoint(x: size.width, y: y + cellHeight / 2))
                }
                context.stroke(line, with: .color(Palette.grassPale.opacity(0.35)), lineWidth: 1)

                for plot in 1...plots {
                    let x = labelWidth + CGFloat(plot - 1) * (cellWidth + gap)
                    let rect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight).insetBy(dx: 1, dy: 1)
                    let path = Path(roundedRect: rect, cornerRadius: 2)
                    let occupied = store.graves.contains { $0.row == row && $0.plot == plot }
                    let isTarget = (row == target.row && plot == target.plot)

                    if isTarget {
                        context.fill(path, with: .color(Palette.plaque))
                        context.stroke(path, with: .color(Palette.ink), lineWidth: 2)
                    } else if occupied {
                        context.fill(path, with: .color(Palette.granite.opacity(0.85)))
                    } else {
                        context.stroke(path, with: .color(Palette.grassPale.opacity(0.45)), lineWidth: 1)
                    }
                }
            }
        }
        .padding(12)
        .frame(height: compact ? 140 : 280)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Palette.grassDeep)
        )
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.grassDeep, lineWidth: 1))
        .accessibilityLabel(lang.t(.planAccessibility, store.site.name, store.graves.count))
    }
}
