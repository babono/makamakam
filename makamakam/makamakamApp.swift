import SwiftUI
import SwiftData

@main
struct makamakamApp: App {
    @State private var store: GraveStore
    @State private var location: LocationService
    @State private var identity = Identity()
    @State private var lang = Lang()
    @State private var pulse = ApproachPulse()
    @State private var wall = WallStore()
    @State private var saved = SavedSync()
    @State private var presence: Presence

    init() {
        let store = GraveStore()
        let location = LocationService()
        _store = State(initialValue: store)
        _location = State(initialValue: location)
        _presence = State(initialValue: Presence(location: location, store: store))
    }

    private let container: ModelContainer = {
        let schema = Schema([
            SavedGrave.self,
            WallPostRecord.self,
            StewardClaim.self,
            WallSetting.self,
            SurveyRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(location)
                .environment(identity)
                .environment(lang)
                .environment(pulse)
                .environment(wall)
                .environment(saved)
                .environment(presence)
                .environment(\.locale, lang.locale)
                .preferredColorScheme(.light)   // one ground, granite, read in sunlight
        }
        .modelContainer(container)
    }
}
