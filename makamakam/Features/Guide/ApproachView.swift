import SwiftUI

/// Screen 3. One arrow, one distance, one accuracy line.
///
/// The arrow *shrinks* as the distance falls (PRD §11). Growing confidence is
/// what an AirTag can honestly show with a UWB radio at both ends; a phone with
/// 3–5 m of GPS error cannot, and copying that UI would feel broken exactly when
/// it matters most.
struct ApproachView: View {
    let grave: Grave
    /// Where the arrow will hand over, which is also where it is smallest.
    let handoff: Double

    @Environment(LocationService.self) private var location
    @Environment(Lang.self) private var lang

    private var distance: Double? {
        grave.location.flatMap { location.distance(to: $0) }
    }

    private var rotation: Double? {
        grave.coordinate.flatMap { location.arrowRotation(to: $0) }
    }

    /// Full size far away, shrinking to 0.45 at the handoff.
    ///
    /// **This is deliberate and inverts what an AirTag does — do not "fix" it.**
    /// A UWB radio at both ends earns growing confidence as it closes; a phone
    /// with 3–5 m of GPS error does the opposite, because the error stays fixed
    /// while the distance shrinks. An arrow that swelled on approach would be
    /// most emphatic exactly where it is least trustworthy.
    private var arrowScale: CGFloat {
        guard let distance else { return 1 }
        let far = 60.0
        let clamped = min(max(distance, handoff), far)
        let t = (clamped - handoff) / max(far - handoff, 1)
        return 0.45 + 0.55 * CGFloat(t)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(grave.name)
                    .font(.engraved(22))
                    .foregroundStyle(Palette.ink)

            }
            .padding(.top, 56)

            Spacer()

            if location.location == nil {
                waiting
            } else if location.headingIsTrustworthy, let rotation {
                arrow(rotation: rotation)
            } else {
                frozen
            }

            Spacer()

            Plaque(padding: 22) {
                VStack(spacing: 10) {
                    Text(distance.map { Distance.text($0) } ?? "—")
                        .font(.spoken(52, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())

                    Text(Distance.accuracyText(location.horizontalAccuracy, lang: lang))
                        .font(.spoken(14))
                        .foregroundStyle(Palette.inkSoft)

                    Text(lang.t(.approachHonestyNote))
                        .font(.spoken(13))
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 12)
                        .padding(.top, 2)

                    if location.simulating {
                        Text(lang.t(.simulationBadge))
                            .font(.spoken(11))
                            .foregroundStyle(Palette.inkSoft)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .quiet(distance.map { Distance.text($0) } ?? "—")
    }

    private func arrow(rotation: Double) -> some View {
        Image(systemName: "arrow.up")
            .font(.system(size: 150, weight: .thin))
            .foregroundStyle(Palette.ink)
            .scaleEffect(arrowScale)
            .rotationEffect(.degrees(rotation))
            // ~0.3 s smoothing on top of the low-pass filter in LocationService;
            // the wraparound is handled there, so this never spins the long way.
            .animation(.easeInOut(duration: 0.3), value: rotation)
            .animation(.easeInOut(duration: 0.6), value: arrowScale)
            .accessibilityLabel(lang.t(.arrowAccessibility))
    }

    /// Compass drift near metal is expected. A flailing arrow is worse than no
    /// arrow, so it freezes and the landmark takes over (PRD §12).
    private var frozen: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.up")
                .font(.system(size: 150, weight: .thin))
                .foregroundStyle(Palette.graniteDeep)
            Plaque {
                VStack(spacing: 10) {
                    Text(lang.t(.approachCompassUntrusted))
                        .font(.spoken(15))
                        .foregroundStyle(Palette.inkSoft)
                    Text(grave.landmark)
                        .font(.spoken(16))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
        }
    }

    private var waiting: some View {
        VStack(spacing: 16) {
            Image(systemName: "location")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(Palette.graniteDeep)
            Plaque {
                VStack(spacing: 10) {
                    Text(lang.t(.approachWaiting))
                        .font(.spoken(16))
                        .foregroundStyle(Palette.inkSoft)
                    Text(grave.landmark)
                        .font(.spoken(15))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
        }
    }
}
