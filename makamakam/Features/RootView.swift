import SwiftUI
import SwiftData

/// Three tabs, and no more. Find is where you arrive, Saved is the short list of
/// people you come back to, Settings is everything the app has to admit about
/// itself.
struct RootView: View {
    @Environment(GraveStore.self) private var store
    @Environment(LocationService.self) private var location
    @Environment(Lang.self) private var lang
    @Environment(WallStore.self) private var wall
    @Environment(SavedSync.self) private var savedSync
    @Environment(\.modelContext) private var context

    @State private var tab: Tab = .find
    @State private var findPath = NavigationPath()
    @State private var openFieldSheet = false

    enum Tab: Hashable { case find, saved, settings }

    var body: some View {
        TabView(selection: $tab) {
            FindView(path: $findPath)
                .tabItem {
                    Label(lang.t(.tabFind), systemImage: "magnifyingglass")
                }
                .tag(Tab.find)

            SavedView()
                .tabItem {
                    Label(lang.t(.tabSaved), systemImage: "bookmark")
                }
                .tag(Tab.saved)

            SettingsView(openFieldSheet: $openFieldSheet)
                .tabItem {
                    Label(lang.t(.tabSettings), systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(Palette.grassDeep)
        .onAppear {
            // Searching needs no location, so nothing is asked for on launch.
            // The permission is requested at the first screen that needs it.
            location.start()
            styleTabBar()
        }
        .task {
            // One refresh per launch, in the background. Nothing waits on it.
            await store.refresh()
            // Sends anything written while there was no signal, then reads.
            await wall.refresh(pushing: context)
            await savedSync.sync(context: context)
        }
        .task {
            openDemoScreenIfRequested()
            // DEBUG only: fills the Saved list for a demo run.
            for id in Demo.seededSavedGraves where !Records.isSaved(id, context: context) {
                Records.toggleSaved(id, context: context)
            }
        }
    }

    /// The tab bar is the one surface UIKit still paints, so it is told to use
    /// marble rather than the system's translucent grey.
    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Palette.plaque)
        appearance.shadowColor = UIColor(Palette.hairline)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    /// DEBUG only; `Demo.screen` is always nil in a release build.
    private func openDemoScreenIfRequested() {
        guard let screen = Demo.screen, let grave = store.grave(id: Demo.graveID) else { return }
        switch screen {
        case .settings, .field:
            tab = .settings
            if screen == .field { openFieldSheet = true }
        case .saved:
            tab = .saved
        case .cemetery, .plan:
            // The full plan opens from the cemetery screen, the way a reader
            // reaches it.
            findPath.append(store.site)
        case .grave:
            findPath.append(grave)
        case .tend, .wall, .profile:
            findPath.append(screen)
        case .orient, .approach, .arrive:
            let metres = Demo.metres ?? (screen == .arrive ? 6 : 40)
            location.startSimulation(target: grave.coordinate, startingMetres: metres)
            findPath.append(screen)
        }
    }
}
