import SwiftUI

/// Photographs a survey collected: the headstone, and the person where the
/// family offered one.
///
/// Absence is the normal state — plenty of families have no photograph, and some
/// would not want one shown — so an empty set draws nothing at all rather than a
/// placeholder implying something is missing.
struct GravePhotoStrip: View {
    let photos: [GravePhoto]
    @Environment(Lang.self) private var lang
    @State private var opened: GravePhoto?

    var body: some View {
        if !photos.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(lang.t(.photosEyebrow))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photos) { photo in
                            Button { opened = photo } label: {
                                GravePhotoThumb(photo: photo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .fullScreenCover(item: $opened) { photo in
                PhotoViewer(photo: photo) { opened = nil }
            }
        }
    }
}

private struct GravePhotoThumb: View {
    let photo: GravePhoto
    @Environment(Lang.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GravePhotoImage(photo: photo)
                .frame(width: 130, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.hairline, lineWidth: 1))
            Text(photo.caption ?? lang.t(photo.kind == .person ? .photoPerson : .photoHeadstone))
                .font(.spoken(12))
                .foregroundStyle(Palette.inkSoft)
                .lineLimit(1)
        }
    }
}

/// Bundled assets and photographs taken on this device resolve the same way.
struct GravePhotoImage: View {
    let photo: GravePhoto

    var body: some View {
        if let image = PhotoStore.image(for: photo) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Palette.granite
                GraniteTexture.tile.resizable(resizingMode: .tile)
                Image(systemName: photo.kind == .person ? "person" : "camera.metering.unknown")
                    .font(.system(size: 22, weight: .thin))
                    .foregroundStyle(Palette.inkSoft)
            }
        }
    }
}

struct PhotoViewer: View {
    let photo: GravePhoto
    var onClose: () -> Void
    @Environment(Lang.self) private var lang

    var body: some View {
        ZStack {
            Palette.ink.ignoresSafeArea()
            GravePhotoImage(photo: photo)
                .scaledToFit()
                .padding(.horizontal, 8)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.plaque)
                    .padding(16)
            }
            .accessibilityLabel(lang.t(.photoClose))
        }
        .overlay(alignment: .bottom) {
            if let caption = photo.caption {
                Text(caption)
                    .font(.spoken(14))
                    .foregroundStyle(Palette.plaque)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

/// Where photographs live. Bundled ones come from the asset catalogue; ones the
/// survey took on this device are files in Documents, so they survive a rebuild
/// and never pass through a server.
enum PhotoStore {
    static func image(for photo: GravePhoto) -> UIImage? {
        if let asset = UIImage(named: photo.source) { return asset }
        let url = directory.appendingPathComponent(photo.source)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GravePhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    @discardableResult
    static func save(_ image: UIImage, named name: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let url = directory.appendingPathComponent(name)
        try? data.write(to: url)
        return name
    }
}

/// Photographs of the burial ground itself, taken from the field sheet.
///
/// Apple's map data carries no photograph of a village cemetery — nothing but a
/// name and a pin — so the only way a gate can appear on the map is if somebody
/// stood at it and took the picture.
enum SitePhotoStore {
    private static func key(_ siteID: String) -> String { "site.photos.\(siteID)" }

    static func captured(for siteID: String) -> [GravePhoto] {
        let names = UserDefaults.standard.stringArray(forKey: key(siteID)) ?? []
        return names.enumerated().map { index, name in
            GravePhoto(id: "site-\(index)-\(name)", kind: .cemetery, source: name, caption: nil)
        }
    }

    static func add(_ image: UIImage, to siteID: String) {
        let name = "site-\(UUID().uuidString).jpg"
        guard PhotoStore.save(image, named: name) != nil else { return }
        var names = UserDefaults.standard.stringArray(forKey: key(siteID)) ?? []
        names.append(name)
        UserDefaults.standard.set(names, forKey: key(siteID))
    }

    static func removeAll(for siteID: String) {
        for photo in captured(for: siteID) {
            try? FileManager.default.removeItem(
                at: PhotoStore.directory.appendingPathComponent(photo.source))
        }
        UserDefaults.standard.removeObject(forKey: key(siteID))
    }
}
