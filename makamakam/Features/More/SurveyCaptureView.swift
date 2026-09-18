import SwiftUI
import SwiftData
import CoreLocation
import UIKit

/// One grave per pass: coordinates, name, section/row/plot, headstone photo and
/// a single landmark sentence. Roughly 25–40 graves in one section, about three
/// hours (PRD §14).
///
/// Etiquette, for whoever runs this: long trousers, do not step over graves, ask
/// before photographing.
struct SurveyCaptureView: View {
    @Environment(LocationService.self) private var location
    @Environment(Lang.self) private var lang
    @Environment(\.modelContext) private var context

    @State private var name = ""
    /// Empty, and allowed to stay that way: most stones here have no number.
    @State private var section = ""
    @State private var row = 0
    @State private var plot = 0
    @State private var deathDate = ""
    @State private var landmark = ""
    @State private var religion = "islam"
    @State private var fatherName = ""
    @State private var gender = ""
    @State private var portrait: UIImage?
    @State private var capturingPortrait = false
    @State private var photo: UIImage?
    @State private var showCamera = false
    @State private var savedNote: String?

    private var fix: (lat: Double, lon: Double, accuracy: Double)? {
        guard let loc = location.location else { return nil }
        return (loc.coordinate.latitude, loc.coordinate.longitude, loc.horizontalAccuracy)
    }

    var body: some View {
        Form {
            Section(lang.t(.surveyIdentity)) {
                TextField(lang.t(.surveyNameField), text: $name)
                TextField(lang.t(.surveyFatherField), text: $fatherName)
                Picker(lang.t(.surveyGender), selection: $gender) {
                    Text(lang.t(.surveyUnrecorded)).tag("")
                    Text(lang.t(.surveyGenderMale)).tag("m")
                    Text(lang.t(.surveyGenderFemale)).tag("f")
                }
                TextField(lang.t(.surveyDeathDate), text: $deathDate)
                    .keyboardType(.numbersAndPunctuation)
                TextField(lang.t(.surveyBlock), text: $section)
                Stepper(row == 0 ? lang.t(.surveyUnrecorded) : lang.t(.surveyRow, row),
                        value: $row, in: 0...40)
                Stepper(plot == 0 ? lang.t(.surveyUnrecorded) : lang.t(.surveyPlot, plot),
                        value: $plot, in: 0...60)
                Picker(lang.t(.surveyReligion), selection: $religion) {
                    Text(lang.t(.surveyUnrecorded)).tag("")
                    ForEach([Faith.islam, .hindu, .kristen, .katolik, .buddha, .konghucu, .other]) { faith in
                        Text(lang.t(faith.labelKey)).tag(faith.rawValue)
                    }
                }
            }

            Section {
                if let fix {
                    // Six decimals stored, five trusted (PRD §7).
                    Text(String(format: "%.6f, %.6f", fix.lat, fix.lon))
                        .monospaced()
                    Text(lang.t(.surveyAccuracyValue, fix.accuracy))
                        .foregroundStyle(.secondary)
                } else {
                    Text(lang.t(.surveyWaitingFix))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(lang.t(.surveyCoordsHeader))
            } footer: {
                Text(lang.t(.surveyCoordsNote))
            }

            Section(lang.t(.surveyHeadstoneHeader)) {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                }
                Button(lang.t(photo == nil ? .surveyTakePhoto : .surveyRetakePhoto)) {
                    capturingPortrait = false
                    showCamera = true
                }
            }

            Section {
                if let portrait {
                    Image(uiImage: portrait)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                }
                Button(lang.t(portrait == nil ? .surveyTakePortrait : .surveyRetakePortrait)) {
                    capturingPortrait = true
                    showCamera = true
                }
            } header: {
                Text(lang.t(.surveyPortraitHeader))
            } footer: {
                Text(lang.t(.surveyPortraitNote))
            }

            Section {
                TextField(lang.t(.surveyLandmarkField), text: $landmark, axis: .vertical)
                    .lineLimit(2...5)
            } header: {
                Text(lang.t(.surveyLandmarkHeader))
            } footer: {
                Text(lang.t(.surveyLandmarkNote))
            }

            Section {
                Button(lang.t(.surveySave)) { save() }
                    .disabled(!canSave)
                if let savedNote {
                    Text(savedNote).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(lang.t(.surveyTitle))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: capturingPortrait ? $portrait : $photo)
                .ignoresSafeArea()
        }
        .onAppear { location.start() }
    }

    private var canSave: Bool {
        fix != nil && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        guard let fix else { return }
        let record = SurveyRecord(
            name: name.trimmingCharacters(in: .whitespaces),
            section: section.uppercased(),   // may be empty
            row: row,
            plot: plot,
            latitude: fix.lat,
            longitude: fix.lon,
            accuracy: fix.accuracy,
            landmark: landmark.trimmingCharacters(in: .whitespacesAndNewlines),
            deathDate: deathDate.trimmingCharacters(in: .whitespaces),
            religion: religion,
            fatherName: fatherName.trimmingCharacters(in: .whitespaces),
            gender: gender,
            photoData: photo?.jpegData(compressionQuality: 0.7),
            portraitData: portrait?.jpegData(compressionQuality: 0.7)
        )
        context.insert(record)
        try? context.save()

        savedNote = lang.t(.surveySaved, record.name)
        // Move to the next plot in the row, which is how the survey actually walks.
        name = ""
        deathDate = ""
        landmark = ""
        fatherName = ""
        gender = ""
        photo = nil
        portrait = nil
        if plot > 0 { plot += 1 }
    }
}

/// The camera, or the photo library where there is no camera (simulator).
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
