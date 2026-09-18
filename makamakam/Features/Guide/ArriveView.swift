import SwiftUI

/// Screen 4. Below ~8 m the arrow is replaced by the headstone photo and the
/// landmark line. The app stops navigating and asks the person to look.
/// This handoff is the product's signature moment (PRD §11).
///
/// The engraved red appears here and nowhere else — it is the colour of a name
/// painted into stone, used on the one screen where you confirm a name.
struct ArriveView: View {
    let grave: Grave
    var onLeave: () -> Void

    @Environment(Lang.self) private var lang
    @State private var showTend = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Rectangle()
                        .fill(Palette.engraved)
                        .frame(width: 44, height: 3)
                    Text(lang.t(.arriveHeadline))
                        .font(.spoken(15))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(4)
                }
                .padding(.top, 60)

                Plaque(padding: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        HeadstoneImage(grave: grave)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(grave.name)
                                .font(.engraved(32))
                                .foregroundStyle(Palette.engraved)
                                .fixedSize(horizontal: false, vertical: true)
                            if let parentage = grave.parentageLine(lang) {
                                Text(parentage)
                                    .font(.engraved(18))
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            Text(grave.landmark)
                                .font(.spoken(17))
                                .foregroundStyle(Palette.ink)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 4)
                            VerificationMark(verified: grave.verified)
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    }
                }

                VStack(spacing: 12) {
                    Button { showTend = true } label: { Text(lang.t(.arriveConfirm)) }
                        .buttonStyle(PrimaryButtonStyle())
                    Button(action: onLeave) { Text(lang.t(.arriveReject)) }
                        .buttonStyle(PrimaryButtonStyle(filled: false))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .fullScreenCover(isPresented: $showTend) {
            NavigationStack {
                TendView(grave: grave)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(lang.t(.close)) { showTend = false }
                                .foregroundStyle(Palette.ink)
                        }
                    }
            }
        }
    }
}

/// Visual confirmation at close range. When the survey has no photo yet, the app
/// says so rather than showing an empty frame that looks like a loading failure.
struct HeadstoneImage: View {
    let grave: Grave
    @Environment(Lang.self) private var lang

    var body: some View {
        Group {
            if let headstone = grave.photoList.first(where: { $0.kind == .headstone }),
               PhotoStore.image(for: headstone) != nil {
                GravePhotoImage(photo: headstone)
            } else if let name = grave.headstonePhoto, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Palette.granite
                    GraniteTexture.tile.resizable(resizingMode: .tile)
                    VStack(spacing: 10) {
                        Image(systemName: "camera.metering.unknown")
                            .font(.system(size: 26, weight: .thin))
                            .foregroundStyle(Palette.inkSoft)
                        Text(lang.t(.arrivePhotoMissing))
                            .font(.spoken(13))
                            .foregroundStyle(Palette.inkSoft)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(20)
                }
            }
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.hairline, lineWidth: 1))
    }
}
