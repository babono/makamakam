import SwiftUI
import CoreLocation

/// Orient → Approach → Arrive, in one full-screen run so nothing competes with
/// the walk. The phase changes on distance; the person never taps to advance
/// past Orient.
struct GuideFlowView: View {
    let grave: Grave
    var initialStage: Stage = .orient

    @Environment(LocationService.self) private var location
    @Environment(Lang.self) private var lang
    @Environment(ApproachPulse.self) private var pulse
    @Environment(\.dismiss) private var dismiss

    @State private var stage: Stage
    @State private var hasCrossedNear = false

    enum Stage: Hashable { case orient, approach, arrive }

    init(grave: Grave, initialStage: Stage = .orient) {
        self.grave = grave
        self.initialStage = initialStage
        _stage = State(initialValue: initialStage)
    }

    private var distance: Double? {
        guard let target = grave.location else { return nil }
        return location.distance(to: target)
    }

    /// Recomputed as the signal changes: a clear sky keeps the arrow useful
    /// closer in, a bad fix hands over sooner.
    private var handoff: Double {
        Phase.handoffDistance(
            userAccuracy: location.horizontalAccuracy > 0 ? location.horizontalAccuracy : 5,
            graveAccuracy: Phase.surveyAccuracy
        )
    }

    var body: some View {
        ZStack {
            GraniteGround()
            switch stage {
            case .orient:
                OrientView(grave: grave) { stage = .approach }
                    .transition(.opacity)
            case .approach:
                ApproachView(grave: grave, handoff: handoff)
                    .transition(.opacity)
            case .arrive:
                ArriveView(grave: grave, onLeave: { dismiss() })
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.ink)
                    .padding(14)
            }
            .accessibilityLabel(lang.t(.closeGuideAccessibility))
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.45), value: stage)
        .onChange(of: distance ?? .infinity) { _, metres in
            update(for: metres)
            // The pulse runs while walking and stops the moment the app hands
            // over to the photograph — at the graveside it would be noise.
            if stage == .approach {
                pulse.update(distance: metres)
            } else {
                pulse.stop()
            }
        }
        .onAppear {
            if location.authorization == .notDetermined { location.requestPermission() }
            location.start()
            if stage == .approach { pulse.update(distance: distance) }
        }
        .onDisappear { pulse.stop() }
    }

    private func update(for metres: Double) {
        guard stage != .orient else { return }
        if stage == .approach {
            if !hasCrossedNear, metres <= Phase.nearThreshold(handoff: handoff) {
                hasCrossedNear = true
                Feedback.enteringNear()
            }
            if Phase.phase(for: metres, handoff: handoff) == .arrive {
                stage = .arrive
                pulse.stop()
                Feedback.arrived()
            }
        } else if stage == .arrive {
            // Hysteresis, so a 4 m GPS wobble at the graveside does not throw the
            // person back into a navigation screen they have finished with.
            if metres > handoff * 2 {
                stage = .approach
                hasCrossedNear = false
            }
        }
    }
}
