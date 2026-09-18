import SwiftUI
import SwiftData

/// Said once, before the first thing anyone posts.
///
/// There is no login screen because CloudKit needs none — the Apple ID on the
/// phone is already the identity. That convenience has a cost: nothing tells a
/// person that their words are about to leave the device. This does.
struct PostDestinationSheet: View {
    var onAgree: () -> Void

    @Environment(Lang.self) private var lang
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(lang.t(.postDestinationBody))
                        .font(.spoken(16))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(5)

                    Button {
                        onAgree()
                        dismiss()
                    } label: {
                        Text(lang.t(.postDestinationAgree))
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button { dismiss() } label: {
                        Text(lang.t(.postDestinationCancel))
                    }
                    .buttonStyle(PrimaryButtonStyle(filled: false))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .ground()
            .navigationTitle(lang.t(.postDestinationTitle))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// One composer for the wall.
///
/// A visit and a story were two screens with two sets of rules; they are one
/// thing written in two situations. What separates them is not the button but
/// where the phone is — and that is read from the phone, at the moment of
/// writing, never offered as a field somebody could tick. Presence is verified,
/// never claimed.
struct PostComposer: View {
    let grave: Grave

    @Environment(GraveStore.self) private var store
    @Environment(Identity.self) private var identity
    @Environment(Presence.self) private var presence
    @Environment(Lang.self) private var lang
    @Environment(WallStore.self) private var wallStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var body_ = ""
    @State private var leftFlowers = true
    @State private var explaining = false

    /// Read once, when the sheet opens, so a post cannot change its nature while
    /// somebody is typing.
    @State private var atGrave = false

    private var canSend: Bool {
        // Standing at the grave is itself worth recording, so a visit may carry
        // no words. A story is only a story if something was written.
        (atGrave || !body_.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            && identity.isNamed
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(lang.t(atGrave ? .wallPostHereNote : .wallPostAwayNote))
                        .font(.spoken(14))
                        .foregroundStyle(Palette.inkSoft)
                        .lineSpacing(4)

                    if atGrave {
                        Plaque {
                            VStack(alignment: .leading, spacing: 10) {
                                Toggle(isOn: $leftFlowers) {
                                    Text(lang.t(.flowerButton))
                                        .font(.spoken(16))
                                        .foregroundStyle(Palette.ink)
                                }
                                .tint(Palette.grass)

                                Text(lang.t(.flowerNote))
                                    .font(.spoken(13))
                                    .foregroundStyle(Palette.inkSoft)
                                    .lineSpacing(3)
                            }
                        }
                    }

                    Plaque(padding: 12) {
                        ZStack(alignment: .topLeading) {
                            if body_.isEmpty {
                                Text(lang.t(atGrave ? .wallCheckInNote : .wallStoryPlaceholder, grave.name))
                                    .font(.engraved(18))
                                    .foregroundStyle(Palette.inkSoft.opacity(0.6))
                                    .padding(.top, 10)
                                    .padding(.leading, 5)
                            }
                            TextEditor(text: $body_)
                                .font(.engraved(19))
                                .foregroundStyle(Palette.ink)
                                .lineSpacing(6)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 180)
                        }
                    }

                    Plaque {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(lang.t(.writtenByEyebrow))
                            TextField(lang.t(.fieldName), text: Binding(
                                get: { identity.name }, set: { identity.name = $0 }
                            ))
                            .font(.spoken(16))
                            .textInputAutocapitalization(.words)
                            Hairline()
                            TextField(lang.t(.fieldRelationship), text: Binding(
                                get: { identity.relationship }, set: { identity.relationship = $0 }
                            ))
                            .font(.spoken(16))
                            Hairline()
                            Text(lang.t(.attributionNote))
                                .font(.spoken(13))
                                .foregroundStyle(Palette.inkSoft)
                        }
                    }

                    Button { attempt() } label: { Text(lang.t(.wallPostSend)) }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!canSend)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .ground()
            .navigationTitle(lang.t(.wallPostTitle))
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .onAppear { atGrave = presence.atGrave(grave) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(lang.t(.cancel)) { dismiss() }
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            .sheet(isPresented: $explaining) {
                PostDestinationSheet {
                    wallStore.hasBeenTold = true
                    send()
                }
            }
        }
    }

    private func attempt() {
        if wallStore.hasBeenTold { send() } else { explaining = true }
    }

    private func send() {
        Records.addPost(
            graveID: grave.id,
            authorName: identity.name,
            relationship: identity.relationship.isEmpty
                ? lang.t(.relationshipUnstated)
                : identity.relationship,
            body: body_.trimmingCharacters(in: .whitespacesAndNewlines),
            visitedInPerson: atGrave,
            leftFlowers: leftFlowers,
            context: context
        )
        if atGrave { Feedback.arrived() }
        Task { await wallStore.refresh(pushing: context) }
        dismiss()
    }
}
