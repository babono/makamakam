import SwiftUI

/// The plan, full screen, where it can be pinched and pushed about.
///
/// The inline plan answers "where is this grave"; this answers "what is here" —
/// which is the question someone asks when they know a name is in this cemetery
/// but not which stone, or when they are simply looking at who lies where.
struct PlanScreen: View {
    let site: Site
    let graves: [Grave]
    var target: Grave?

    @Environment(LocationService.self) private var location
    @Environment(Lang.self) private var lang
    @Environment(\.dismiss) private var dismiss

    @State private var zoom: CGFloat = 1
    @State private var pinchAnchor: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var panAnchor: CGSize = .zero
    @State private var selected: Grave?
    @State private var opened: Grave?
    @State private var frame: CGSize = .zero
    /// Whether the compass drives the plan.
    ///
    /// Off to begin with, unlike the inline plan. This screen is for *browsing* —
    /// finding who lies where, reading names — and a drawing that swings every
    /// time the phone turns is unreadable for that. Orient still follows the
    /// compass, because there you are walking and matching what you face.
    @State private var followsHeading = false

    private let zoomRange: ClosedRange<CGFloat> = 0.6...8

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                GraniteGround()

                plan

                if let selected {
                    selectionCard(selected)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .transition(.opacity)
                } else {
                    // On marble, like everything else the app says. Over the
                    // grass it was unreadable, and a plan you can drag under
                    // the words makes that worse with every gesture.
                    Plaque(padding: 14) {
                        Text(lang.t(followsHeading ? .planFacing : .planFullHint))
                            .font(.spoken(13))
                            .foregroundStyle(Palette.inkSoft)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .transition(.opacity)
                }
            }
            .quiet(selected?.id)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(lang.t(.close)) { dismiss() }
                        .foregroundStyle(Palette.ink)
                }
                ToolbarItem(placement: .bottomBar) {
                    // Following the compass is a choice here, not the default.
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            followsHeading.toggle()
                        }
                    } label: {
                        Label(
                            lang.t(followsHeading ? .planFacing : .planFollow),
                            systemImage: followsHeading ? "location.north.line.fill" : "location.north.line"
                        )
                        .labelStyle(.titleAndIcon)
                        .font(.spoken(13))
                        .foregroundStyle(followsHeading ? Palette.grassDeep : Palette.inkSoft)
                    }
                    .disabled(!location.headingIsTrustworthy)
                }
                ToolbarItem(placement: .principal) {
                    Text(site.name)
                        .font(.spoken(15, weight: .medium))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if hasBeenMoved {
                        Button(lang.t(.planReset)) { reset() }
                            .foregroundStyle(Palette.grassDeep)
                    }
                }
            }
            .navigationDestination(item: $opened) { GraveView(grave: $0) }
        }
    }

    private var hasBeenMoved: Bool {
        abs(zoom - 1) > 0.01 || pan != .zero || followsHeading
    }

    /// Keeps the plan reachable. Without a limit it can be flung off the screen
    /// and the canvas simply disappears, which looks like a crash and is in fact
    /// an offset of two thousand points.
    private func held(_ proposed: CGSize, in size: CGSize) -> CGSize {
        guard size != .zero else { return proposed }
        // The middle of the plan stays on screen, whatever the zoom or the
        // turn. Working the limit out from the zoom alone was wrong once the
        // plan could also be rotated, and the plot could still be lost.
        let limitX = size.width / 2
        let limitY = size.height / 2
        return CGSize(
            width: min(max(proposed.width, -limitX), limitX),
            height: min(max(proposed.height, -limitY), limitY)
        )
    }

    private var plan: some View {
        GeometryReader { proxy in
            ZStack {
                // A hit surface that never moves.
                //
                // The gestures used to live on the drawing itself, which slides
                // and shrinks under pan and zoom — so once it moved away from
                // where a finger landed, nothing responded at all and the screen
                // had to be closed and reopened. Touches belong to the frame;
                // only the picture moves.
                Color.clear.contentShape(Rectangle())

                planView
                .padding(16)
                .scaleEffect(zoom)
                .offset(pan)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            // Clipped so a pushed-about plan never runs under the toolbar.
            .clipped()
            .contentShape(Rectangle())
            // Separate simultaneous gestures rather than one nested composition:
            // a nested SimultaneousGesture can be left mid-flight when a finger
            // lifts during a pinch, and then no anchor is ever brought up to
            // date again.
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(magnifyGesture)
            // One tap gesture, not two. A double-tap attached alongside a
            // single tap makes every single tap wait for it — and if it wins the
            // race, the single tap never arrives at all, which is why tapping a
            // grave stopped working. Reset lives in the toolbar instead.
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        selected = graveAt(value.location, in: proxy.size)
                    }
            )
            .onAppear { frame = proxy.size }
            .onChange(of: proxy.size) { _, size in frame = size }
        }
    }

    private var planView: SitePlan {
        SitePlan(
            site: site,
            graves: graves,
            target: target,
            here: location.location,
            // Once a hand is on it, the compass lets go — otherwise the two
            // turns fight each other and the plan never settles.
            heading: followsHeading && location.headingIsTrustworthy ? location.heading : nil,
            onSelect: nil,
            handlesOwnTaps: false,
            highlighted: selected?.id
        )
    }

    /// Undoes the transforms to find where a finger landed *on the ground*.
    ///
    /// `scaleEffect` works about the view's centre and `offset` moves it
    /// afterwards, so the inverse runs the other way: subtract the pan, then
    /// divide by the zoom. Testing the tap in the drawing's own space instead is
    /// what made it select the wrong grave — SwiftUI gives the untransformed
    /// point, which drifts further from the truth the more the plan has moved.
    ///
    /// Following the compass needs no term here: that turn happens inside
    /// `SitePlan`'s own maths, so the positions it tests against are already
    /// turned. That is precisely why the hand-turn had to go and the
    /// compass-turn could stay.
    private func graveAt(_ point: CGPoint, in size: CGSize) -> Grave? {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let unpanned = CGPoint(x: point.x - pan.width, y: point.y - pan.height)
        let unscaled = CGPoint(
            x: (unpanned.x - centre.x) / zoom + centre.x,
            y: (unpanned.y - centre.y) / zoom + centre.y
        )

        // Back into the padded canvas the plan is actually drawn in.
        let inset: CGFloat = 16
        let canvas = CGSize(width: size.width - inset * 2, height: size.height - inset * 2)
        let onCanvas = CGPoint(x: unscaled.x - inset, y: unscaled.y - inset)

        return planView.grave(at: onCanvas, in: canvas)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                pan = held(
                    CGSize(
                        width: panAnchor.width + value.translation.width,
                        height: panAnchor.height + value.translation.height
                    ),
                    in: frame
                )
            }
            .onEnded { _ in settle() }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(
                    max(pinchAnchor * value.magnification, zoomRange.lowerBound),
                    zoomRange.upperBound
                )
                pan = held(pan, in: frame)
            }
            .onEnded { _ in settle() }
    }

    /// Brings both anchors up to date at once, so a pinch that turns into a
    /// drag cannot leave one behind.
    private func settle() {
        pinchAnchor = zoom
        panAnchor = pan
    }

    private func selectionCard(_ grave: Grave) -> some View {
        Plaque(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(grave.name)
                            .font(.engraved(22))
                            .foregroundStyle(Palette.ink)
                        if let parentage = grave.parentageLine(lang) {
                            Text(parentage)
                                .font(.engraved(15))
                                .foregroundStyle(Palette.inkSoft)
                        }
                        // Three fields, and no more. This card answers one
                        // question — is this them — and faith, photographs, the
                        // wall and the profile all belong after arrival. Adding
                        // anything here makes the question harder to answer.
                        if let died = grave.deathDate.map({ String($0.prefix(4)) }) {
                            Text(lang.t(.died, died))
                                .font(.spoken(13))
                                .foregroundStyle(Palette.inkSoft)
                        }
                    }
                    Spacer(minLength: 8)
                    Button { selected = nil } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.inkSoft)
                    }
                }

                Button { opened = grave } label: {
                    Text(lang.t(.planOpenGrave))
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func reset() {
        withAnimation(.easeInOut(duration: 0.3)) {
            zoom = 1
            pan = .zero
            followsHeading = false
        }
        pinchAnchor = 1
        panAnchor = .zero
    }
}
