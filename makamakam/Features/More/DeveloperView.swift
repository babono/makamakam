import SwiftUI
import SwiftData
import CoreLocation

/// Hidden behind a long press on the version number. Three jobs: the field survey
/// (PRD §14), rehearsing the walk without standing in Bali, and feeling the
/// approach pulse without walking to a grave.
struct DeveloperView: View {
    @Environment(GraveStore.self) private var store
    @Environment(LocationService.self) private var location
    @Environment(Presence.self) private var presence
    @Environment(ApproachPulse.self) private var pulse
    @Environment(Lang.self) private var lang
    @Environment(\.dismiss) private var dismiss

    @State private var simulationTarget: String = ""
    /// Metres, for feeling the pulse at one held distance.
    @State private var testDistance: Double = 40
    @State private var sitePhoto: UIImage?
    @State private var capturingSitePhoto = false

    var body: some View {
        List {
            presenceSection
            standSection
            sitePhotoSection
            hapticsSection
            surveySection
            simulationSection
            stateSection
        }
        .onDisappear { pulse.stopRehearsing() }
        .navigationTitle(lang.t(.fieldTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(lang.t(.close)) { dismiss() }
            }
        }
    }

    private var presenceSection: some View {
        Section {
            Toggle(lang.t(.fieldPresenceToggle), isOn: Binding(
                get: { presence.pretendPresent },
                set: { presence.pretendPresent = $0 }
            ))
        } header: {
            Text(lang.t(.fieldPresenceHeader))
        } footer: {
            Text(lang.t(.fieldPresenceNote))
        }
    }

    private var sitePhotoSection: some View {
        Section {
            LabeledContent(lang.t(.fieldSitePhotoCount),
                           value: "\(SitePhotoStore.captured.count)")
            Button(lang.t(.fieldSitePhotoAdd)) { capturingSitePhoto = true }
            if !SitePhotoStore.captured.isEmpty {
                Button(lang.t(.fieldSitePhotoClear), role: .destructive) {
                    SitePhotoStore.removeAll()
                    sitePhoto = nil
                }
            }
        } header: {
            Text(lang.t(.fieldSitePhotoHeader))
        } footer: {
            Text(lang.t(.fieldSitePhotoNote))
        }
        .sheet(isPresented: $capturingSitePhoto) {
            CameraPicker(image: Binding(
                get: { sitePhoto },
                set: { image in
                    sitePhoto = image
                    if let image { SitePhotoStore.add(image) }
                }
            ))
            .ignoresSafeArea()
        }
    }

    private var hapticsSection: some View {
        Section {
            Toggle(lang.t(.fieldPulseToggle), isOn: Binding(
                get: { pulse.enabled },
                set: { pulse.enabled = $0 }
            ))

            Button(lang.t(pulse.isRehearsing ? .fieldRehearseStop : .fieldRehearse)) {
                if pulse.isRehearsing {
                    pulse.stopRehearsing()
                } else {
                    pulse.rehearse()
                }
            }
            .disabled(!pulse.enabled)

            if let metres = pulse.rehearsedDistance {
                LabeledContent(lang.t(.fieldRehearseAt), value: String(format: "%.0f m", metres))
                LabeledContent(lang.t(.fieldInterval), value: String(format: "%.2f s", ApproachPulse.interval(for: metres)))
                LabeledContent(lang.t(.fieldIntensity), value: String(format: "%.0f%%", ApproachPulse.intensity(for: metres) * 100))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(lang.t(.fieldHoldAt, Int(testDistance)))
                    .font(.footnote)
                Slider(value: $testDistance, in: 8...80, step: 1) { editing in
                    if editing {
                        pulse.update(distance: testDistance)
                    } else {
                        pulse.stop()
                    }
                }
                .disabled(!pulse.enabled || pulse.isRehearsing)
            }

            Button(lang.t(.fieldTapNear)) { Feedback.enteringNear() }
            Button(lang.t(.fieldTapArrive)) { Feedback.arrived() }
        } header: {
            Text(lang.t(.fieldHapticsHeader))
        } footer: {
            Text(lang.t(.fieldHapticsNote))
        }
    }

    private var surveySection: some View {
        Section(lang.t(.fieldSurveyHeader)) {
            NavigationLink { SurveyCaptureView() } label: {
                Label(lang.t(.fieldRecordGrave), systemImage: "mappin.and.ellipse")
            }
            NavigationLink { SurveyExportView() } label: {
                Label(lang.t(.fieldExport), systemImage: "square.and.arrow.up")
            }
        }
    }

    private var standSection: some View {
        Section {
            Button(lang.t(.fieldStandAtGate)) {
                location.standAt(store.site.coordinate)
                dismiss()
            }
            if location.simulating {
                Button(lang.t(.fieldSimStop), role: .destructive) {
                    location.stopSimulation()
                }
            }
        } header: {
            Text(lang.t(.fieldStandHeader))
        } footer: {
            Text(lang.t(.fieldStandNote))
        }
    }

    private var simulationSection: some View {
        Section {
            Picker(lang.t(.fieldSimTarget), selection: $simulationTarget) {
                Text("—").tag("")
                ForEach(store.graves) { grave in
                    Text("\(grave.shortPlotLabel) · \(grave.name)").tag(grave.id)
                }
            }
            Button(lang.t(.fieldSimStart)) {
                guard let grave = store.grave(id: simulationTarget) else { return }
                location.startSimulation(target: grave.coordinate)
                dismiss()
            }
            .disabled(simulationTarget.isEmpty)

            if location.simulating {
                Button(lang.t(.fieldSimStop), role: .destructive) {
                    location.stopSimulation()
                }
            }
        } header: {
            Text(lang.t(.fieldSimHeader))
        } footer: {
            Text(lang.t(.fieldSimNote))
        }
    }

    private var stateSection: some View {
        Section(lang.t(.fieldStateHeader)) {
            LabeledContent(lang.t(.fieldAuth), value: authorizationText)
            LabeledContent(lang.t(.fieldPosition), value: location.location.map {
                String(format: "%.6f, %.6f", $0.coordinate.latitude, $0.coordinate.longitude)
            } ?? lang.t(.fieldNone))
            LabeledContent(lang.t(.fieldAccuracy), value: location.horizontalAccuracy > 0
                ? String(format: "±%.1f m", location.horizontalAccuracy) : lang.t(.fieldNone))
            LabeledContent(lang.t(.fieldHeading), value: location.heading.map {
                String(format: "%.0f°", $0)
            } ?? lang.t(.fieldNone))
            LabeledContent(lang.t(.fieldHeadingUsable), value: lang.t(location.headingIsTrustworthy ? .fieldYes : .fieldNo))
            LabeledContent(lang.t(.fieldDistanceToSite), value: presence.metresFromSite.map {
                String(format: "%.0f m", $0)
            } ?? lang.t(.fieldNone))
            LabeledContent(lang.t(.fieldCountedPresent), value: lang.t(presence.atSite ? .fieldYes : .fieldNo))
        }
    }

    private var authorizationText: String {
        switch location.authorization {
        case .notDetermined: return lang.t(.authNotAsked)
        case .denied: return lang.t(.authDenied)
        case .restricted: return lang.t(.authRestricted)
        case .authorizedAlways: return lang.t(.authAlways)
        case .authorizedWhenInUse: return lang.t(.authWhenInUse)
        @unknown default: return lang.t(.authUnknown)
        }
    }
}
