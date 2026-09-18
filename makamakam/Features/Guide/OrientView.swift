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

    /// The cemetery this grave lies in, which is not necessarily the first one.
    private var site: Site { store.site(of: grave) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(site.name)
                Text(grave.name)
                    .font(.engraved(28))
                    .foregroundStyle(Palette.ink)

            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 20)

            VStack(spacing: 8) {
                SitePlan(
                    site: site,
                    graves: store.graves(in: site),
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
            PlanScreen(site: site, graves: store.graves(in: site), target: grave)
        }
    }
}
