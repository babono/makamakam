import SwiftUI
import SwiftData

/// The life of the person, written by the family.
///
/// Markdown, because the family is writing prose rather than filling a form —
/// paragraphs, a list of the children, a line of emphasis. It is authored in the
/// admin site, where a keyboard makes that bearable, and read here.
///
/// Absence is ordinary: most graves will never have one, and an empty page must
/// not read as a family who could not be bothered.
struct ProfileView: View {
    let grave: Grave

    @Environment(GraveStore.self) private var store
    @Environment(Identity.self) private var identity
    @Environment(Lang.self) private var lang
    @Environment(\.modelContext) private var context

    private var isSteward: Bool {
        Records.isSteward(identity, graveID: grave.id, store: store, context: context)
    }

    /// The profile is something the living wrote, so the family governs it —
    /// exactly as they govern the wall. The record of the burial is not theirs
    /// to hide (PRD §10).
    private var canRead: Bool {
        switch Records.wallVisibility(for: grave, context: context) {
        case .open: return true
        case .family, .closed: return isSteward
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                nameplate

                if !canRead {
                    Plaque {
                        Text(lang.t(.wallHiddenFromYou))
                            .font(.spoken(15))
                            .foregroundStyle(Palette.inkSoft)
                            .lineSpacing(4)
                    }
                } else if let markdown = grave.profileMarkdown, !markdown.isEmpty {
                    Plaque(padding: 22) {
                        VStack(alignment: .leading, spacing: 14) {
                            Eyebrow(lang.t(.profileEyebrow))
                            MarkdownText(markdown)
                        }
                    }
                } else {
                    Plaque {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lang.t(.profileEmpty))
                                .font(.spoken(16))
                                .foregroundStyle(Palette.ink)
                            Text(lang.t(.profileEmptyNote))
                                .font(.spoken(14))
                                .foregroundStyle(Palette.inkSoft)
                                .lineSpacing(3)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 90)
        }
        .ground()
        .navigationTitle(lang.t(.profileTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var nameplate: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(grave.name)
                .font(.engraved(28))
                .foregroundStyle(Palette.ink)
            if let parentage = grave.parentageLine(lang) {
                Text(parentage)
                    .font(.engraved(17))
                    .foregroundStyle(Palette.inkSoft)
            }
            Text(grave.yearsLine(lang))
                .font(.spoken(14))
                .foregroundStyle(Palette.inkSoft)
        }
    }
}

/// Markdown, rendered block by block.
///
/// `AttributedString(markdown:)` handles the inline marks — bold, italic, links —
/// but folds every block into one paragraph, so headings and list items are
/// split out first. A family writing about their mother should get paragraphs
/// where they typed paragraphs.
struct MarkdownText: View {
    let source: String

    init(_ source: String) { self.source = source }

    private enum Block: Identifiable {
        case heading(String)
        case paragraph(String)
        case item(String)

        var id: String {
            switch self {
            case let .heading(text): return "h\(text)"
            case let .paragraph(text): return "p\(text)"
            case let .item(text): return "l\(text)"
            }
        }
    }

    private var blocks: [Block] {
        var blocks: [Block] = []
        var paragraph: [String] = []

        func flush() {
            let joined = paragraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if !joined.isEmpty { blocks.append(.paragraph(joined)) }
            paragraph = []
        }

        for line in source.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flush()
            } else if trimmed.hasPrefix("#") {
                flush()
                blocks.append(.heading(trimmed.drop(while: { $0 == "#" || $0 == " " }).description))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flush()
                blocks.append(.item(String(trimmed.dropFirst(2))))
            } else {
                paragraph.append(trimmed)
            }
        }
        flush()
        return blocks
    }

    private func inline(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks) { block in
                switch block {
                case let .heading(text):
                    Text(inline(text))
                        .font(.spoken(18, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                case let .paragraph(text):
                    // The family's own words, in the voice the app keeps for
                    // people rather than for itself.
                    Text(inline(text))
                        .font(.engraved(18))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(7)
                        .fixedSize(horizontal: false, vertical: true)
                case let .item(text):
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Rectangle()
                            .fill(Palette.grass)
                            .frame(width: 10, height: 1)
                            .padding(.top, 9)
                        Text(inline(text))
                            .font(.engraved(18))
                            .foregroundStyle(Palette.ink)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
