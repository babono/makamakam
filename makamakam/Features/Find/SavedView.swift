import SwiftUI
import SwiftData

/// The short list of people you come back to. Kept on this phone; nobody is told
/// whose graves you keep.
struct SavedView: View {
    @Environment(GraveStore.self) private var store
    @Environment(Lang.self) private var lang
    @Query private var saved: [SavedGrave]

    private var graves: [Grave] {
        saved.sorted { $0.savedAt > $1.savedAt }.compactMap { store.grave(id: $0.graveID) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if graves.isEmpty {
                        Plaque {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(lang.t(.savedEmpty))
                                    .font(.spoken(16))
                                    .foregroundStyle(Palette.ink)
                                Text(lang.t(.savedEmptyNote))
                                    .font(.spoken(14))
                                    .foregroundStyle(Palette.inkSoft)
                                    .lineSpacing(3)
                            }
                        }
                    } else {
                        ForEach(graves) { grave in
                            NavigationLink(value: grave) { GraveRow(grave: grave) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .ground()
            .navigationTitle(lang.t(.savedTitle))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Grave.self) { GraveView(grave: $0) }
        }
    }
}
