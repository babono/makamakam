import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Exports captured rows in exactly the shape `graves.json` expects, so a survey
/// run ends with a file that can be dropped straight into the bundle.
struct SurveyExportView: View {
    @Environment(\.modelContext) private var context
    @Environment(Lang.self) private var lang
    @Query(sort: \SurveyRecord.capturedAt) private var records: [SurveyRecord]

    @State private var exportURL: URL?

    var body: some View {
        List {
            Section {
                if records.isEmpty {
                    Text(lang.t(.exportEmpty))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.name).font(.headline)
                            Text(String(format: "%.6f, %.6f · ±%.0f m", record.latitude, record.longitude, record.accuracy))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !record.landmark.isEmpty {
                                Text(record.landmark).font(.caption)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        offsets.map { records[$0] }.forEach(context.delete)
                        try? context.save()
                    }
                }
            } header: {
                Text(lang.t(.exportCount, records.count))
            }

            Section {
                Button(lang.t(.exportPrepare)) { prepare() }
                    .disabled(records.isEmpty)
                if let exportURL {
                    ShareLink(item: exportURL) { Text(lang.t(.exportShare)) }
                }
            } footer: {
                Text(lang.t(.exportNote))
            }
        }
        .navigationTitle(lang.t(.exportTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Photographs are written beside the JSON as files; the JSON carries their
    /// names, which is what the bundle expects.
    private func photoEntries(for record: SurveyRecord) -> [[String: Any]] {
        var entries: [[String: Any]] = []
        let stem = record.id
        if record.photoData != nil {
            entries.append(["id": "\(stem)-nisan", "kind": "headstone",
                            "source": "\(stem)-nisan.jpg", "caption": NSNull()])
        }
        if record.portraitData != nil {
            entries.append(["id": "\(stem)-orang", "kind": "person",
                            "source": "\(stem)-orang.jpg", "caption": NSNull()])
        }
        return entries
    }

    private func prepare() {
        let rows: [[String: Any]] = records.map { record in
            [
                "id": record.id,
                "name": record.name,
                "birthYear": NSNull(),
                "deathDate": record.deathDate.isEmpty ? NSNull() : record.deathDate,
                "section": record.section.isEmpty ? NSNull() : record.section,
                "row": record.row > 0 ? record.row : NSNull(),
                "plot": record.plot > 0 ? record.plot : NSNull(),
                "latitude": (record.latitude * 1_000_000).rounded() / 1_000_000,
                "longitude": (record.longitude * 1_000_000).rounded() / 1_000_000,
                "headstonePhoto": NSNull(),
                "landmark": record.landmark,
                "religion": record.religion.isEmpty ? NSNull() : record.religion,
                "fatherName": record.fatherName.isEmpty ? NSNull() : record.fatherName,
                "gender": record.gender.isEmpty ? NSNull() : record.gender,
                "photos": photoEntries(for: record),
                // Captured by a person who physically stood there.
                "verified": true,
                "stewardName": NSNull()
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: ["graves": rows], options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("graves-survey.json")
        try? data.write(to: url)

        // The photographs themselves, named to match the JSON.
        for record in records {
            let stem = record.id
            if let nisan = record.photoData {
                try? nisan.write(to: FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(stem)-nisan.jpg"))
            }
            if let portrait = record.portraitData {
                try? portrait.write(to: FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(stem)-orang.jpg"))
            }
        }
        exportURL = url
    }
}
