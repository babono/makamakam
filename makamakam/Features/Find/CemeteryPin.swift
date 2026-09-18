import SwiftUI

/// A burial ground on the map, shown as its own photograph where one exists.
///
/// A photograph is the thing a visitor actually recognises — the gate, the wall,
/// the trees — where a leaf glyph is only a category. Where no photograph exists
/// the pin falls back to the glyph rather than inventing a picture, which is the
/// normal case for every cemetery but the surveyed one: Apple's map data carries
/// a name and a coordinate, never an image.
struct CemeteryPin: View {
    let photo: GravePhoto?
    let surveyed: Bool
    var selected: Bool = false

    private var diameter: CGFloat { selected ? 68 : 52 }

    /// The annotation clips to whatever its content measures, so the view is
    /// always the size of the *largest* state it can reach, with room for the
    /// ring and the shadow. Letting the bounds change with the pin is what
    /// clipped a flat edge off the circle while the zoom transition ran.
    private static let canvas: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .fill(Palette.plaque)
                .shadow(color: .black.opacity(0.22), radius: 3, y: 2)

            Group {
                if let photo, PhotoStore.image(for: photo) != nil {
                    GravePhotoImage(photo: photo)
                        .scaledToFill()
                } else {
                    ZStack {
                        (surveyed ? Palette.grass : Palette.graniteDeep)
                        Image(systemName: surveyed ? "text.magnifyingglass" : "leaf")
                            .font(.system(size: selected ? 22 : 17, weight: .medium))
                            .foregroundStyle(Palette.plaque)
                    }
                }
            }
            .frame(width: diameter - 6, height: diameter - 6)
            .clipShape(Circle())
        }
        .frame(width: diameter, height: diameter)
        .overlay(
            Circle().stroke(surveyed ? Palette.grass : Palette.plaque, lineWidth: surveyed ? 3 : 2)
        )
        // One layer, so the shadow is cast by the finished pin rather than by
        // each piece of it.
        .compositingGroup()
        .frame(width: Self.canvas, height: Self.canvas)
        .animation(.easeInOut(duration: 0.25), value: selected)
    }
}
