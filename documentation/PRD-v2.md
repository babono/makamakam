> **Superseded by [PRD-v3](PRD-v3.md)**, written from the app as it now stands.
> Kept for the reasoning behind decisions v3 inherits.

# Makamakam — Product Requirements v2

**Platform:** iOS 17+, SwiftUI, Apple frameworks only
**Status:** Prototype for Apple Developer Academy challenge
**Prototype site:** Pemakaman Islam II, Lingkungan Desa Adat Kuta — Jl. Bypass Ngurah Rai, Tuban, Badung, Bali

*Supersedes v1. Main changes: the primary user is now the outer circle rather than immediate family; "Learn" has been absorbed into Gather; messages split into private and shared; the flower records a physical act instead of replacing one; the words/acts rule now governs what is location-locked.*

---

## 1. Challenge statement

Empower the people at the edge of a loss — cousins, old friends, neighbours — to find a grave they were never shown, tend it in their own tradition, and leave the family a memory of the person that only they hold.

## 2. The three pillars

| | Object | Job | Requires presence |
|---|---|---|---|
| **Locate** | A place | Get me to the grave | — |
| **Tend** | An act | Know what to do while standing there | Yes |
| **Gather** | People | Memories flow from the outer circle to the family | Writing: no. Reading: yes |

## 3. Governing rule

**Words travel. Acts don't.**

A doa said alone in a room is as valid as one said at a graveside, so words can be written from anywhere. Scattering a flower, praying at the plot, reading what others left — these are acts, and acts need a body in a place.

Every location-lock in this product follows from that one line. It also keeps the remote experience from quietly becoming a substitute for going.

## 4. Problem

**Wayfinding.** Indonesian cemetery reporting describes visitors arriving unable to locate a relative, most having not visited in a long time, many from out of town or overseas. Staff search by date of death using a system or a paper ledger. One Jakarta cemetery holds ~60,000 plots.

**Entitlement.** The barrier for the outer circle is not only that they don't know where the grave is — it's that they don't feel it's their place to ask the family or to turn up. Kenneth Doka's term for this is *disenfranchised grief*: mourning a society gives no recognised role to. The spouse and children receive condolences; the cousin, the school friend, the neighbour, the colleague have nowhere to put the loss.

**A funeral happens once.** It is a fixed hour on a fixed day, and people miss it — through work, distance, or not hearing in time. That absence becomes a small permanent debt with no way to settle it. A grave, unlike a funeral, is available on a Tuesday afternoon three years later. The product makes mourning **asynchronous**: you can attend on your own schedule, alone, late.

**Asymmetry of memory.** The outer circle holds stories the family has never heard. Bereaved families are often too close, or too raw, to write about their own parent. A friend isn't.

**Distance.** Tuban and Kuta have a large migrant Muslim population from Java, Madura and Lombok. Families are commonly scattered across islands and most cannot attend at Lebaran.

**Seasonality.** Visits cluster around Idulfitri, with a weekly Friday tradition alongside. The typical user is an infrequent, high-stakes visitor with no route memory.

## 5. Users

**Primary — the outer circle.** Cousin, old friend, former neighbour, colleague. Feels the loss, has no role, doesn't know the grave, won't ask. Holds the memories the family lacks.

**Primary — the immediate family.** Owns the grave record. Receives what the outer circle writes. Also needs Locate, though for them it's a convenience rather than a barrier.

**Secondary — the distant relative.** Cannot travel. Writes; someone else carries.

**Not a user — the cemetery operator.** Plot inventory, capacity and burial-rights management are out of scope. Different product, existing commercial market.

## 6. Non-goals

Decisions already made. Do not reintroduce.

- **No gamification.** No scores, streaks, collection mechanics, avatars, bouncy motion, sound by default, or the word "unlock" anywhere in the interface. Pokémon GO was asked to remove Pokéstops from Arlington National Cemetery, the U.S. Holocaust Memorial Museum, and Hiroshima Peace Memorial Park. The visual vocabulary of play reads as desecration in a burial ground.
- **No purchases of any kind.** No paid digital flowers, no in-app purchases attached to a grave.
- **No music.** Classical adab holds that eating and laughing at a graveside are makruh because a cemetery is *tempat mengambil pelajaran* — a place for taking lessons and remembering the hereafter — and those acts dispel that state. Music sits squarely in the same territory, and its status is contested in Indonesian practice regardless. If ambient sound is ever wanted for a remote mode, use Qur'an recitation.
- **Nothing is added to the physical grave.** No QR plaques, beacons, or hardware. Jumhur ulama hold that building on a grave is haram, with the reasoning extending to ornamentation. The product's justification is that it satisfies the desire to personalise a resting place *without* touching it. In the interface, messages are left **for people**, never "on a grave." Use "tend," never "decorate."
- **No notifications, ever, unless explicitly requested.** No "you haven't visited in 30 days." No death-anniversary push. Someone opening this app at 3am is not an engagement win. This feature must not try to increase its own usage — it is pull, never push.
- **No public feed.** All content is family-scoped. A public memory board attached to real graves invites abuse and requires moderation the team cannot provide.
- **No virtual ziarah.** The app does not simulate a visit or render a grave as a place you stand facing.
- **No cemetery-wide mapping pipeline.** No drone survey, no orthomosaic, no plot polygons. 25–40 hand-surveyed graves in one section.
- **No Android, no web.**

## 7. Constraints

**GPS accuracy is 3–5 m; graves are ~1 m apart.** The app cannot identify which grave you're standing at, only which row. Every navigation decision follows from this.

**Accuracy does not improve as you approach.** Error stays fixed while distance shrinks, so confidence *falls* near the target — the inverse of AirTag Precision Finding, which uses UWB radios at both ends and is unavailable here. Copying that UI literally produces an app that feels broken at the emotionally critical moment.

**Coordinate precision:** at this latitude 1° longitude ≈ 110,033 m. Store 6 decimal places (~0.11 m); trust at most 5 (~1.1 m).

**No plot polygons.** Boundary corners would each carry 3–5 m error on a 1×2 m grave. Polygons would overlap neighbours and look precise while being fiction.

**MapKit is wrong at grave scale.** At maximum useful zoom a grave is ~14 pt wide against a 44 pt tap target — pins overlap threefold. Cemetery-level: MapKit. Grave-level: a SwiftUI `Canvas` schematic drawn from row and plot integers.

**`ARGeoTrackingConfiguration` is very likely unavailable in Indonesia.** Verify with `checkAvailability` on a real device before planning any AR geo-anchor feature.

## 8. Core data model

Split the coordinate's job from the identity's job.

| Field | Job |
|---|---|
| `coordinate` | A destination. "Walk toward this spot." |
| `section` / `row` / `plot` | Identity. Which grave this is. |
| `headstonePhoto` | Visual confirmation at close range. |
| `landmark` | The caretaker's knowledge, written down. Bridges the last few metres. |
| `verified` | Whether a human physically stood there. Never render unverified pins with the same confidence as verified ones. |
| `stewardID` | The family member who claimed this grave. Approves and removes shared memories. |

## 9. Pillar detail

### Locate

Search by name, guide to within a few metres, hand off to headstone photo and landmark line.

Available to anyone. This is the pillar that removes the entitlement barrier — the friend never has to ask the family where to go.

### Tend

What to do while standing there.

**Prayer text.** Salam on entering, Yasin, tahlil, doa ziarah kubur. Arabic, Latin transliteration, Indonesian meaning. Many people don't have these memorised and feel quietly embarrassed about it — this is the highest-value, lowest-risk screen in the product and likely the most used. Selectable by tradition, since the prototype site is Muslim but Bali is not uniformly so.

**Flower.** Records that you left a real one. *Tabur bunga* is the central act of ziarah in Indonesia and people are already doing it standing there — the app does not offer a virtual substitute, it notes the real act so someone who couldn't come can see it happened. Use kamboja specifically. **Never display a cumulative count.** Show the most recent visit and who made it; nothing ranked, nothing totalled, or two siblings will silently compete over who visits more.

**Visit log.** Who came, when.

All three require presence.

### Gather

**A private note.** Any relationship, addressed to the deceased. Only the author ever sees it. This is where "Ibu, I miss you" goes, and where the 3am feeling has somewhere to land without becoming content.

Addressing the dead is not the concern — the salam recited on entering a cemetery is spoken directly to its occupants and is sunnah. The line is **address versus petition**: "I miss you, I named my daughter after you" is address; "help me with this" is petition, which is the syirik concern the fiqh literature returns to. This line is held by **placeholder copy, not by rules.** "Write to Ibu" produces address. Never write "make a wish" or "ask Ibu for."

**A shared memory.** Written by the outer circle, read by the family. This is the pillar's reason to exist — a story the children have never heard is a piece of their parent they didn't own.

Writing travels; reading is location-locked. From home you may see **that** memories exist near you — a count and a place, never content. Copy reads "these can be read at the cemetery," never "unlock."

## 10. Permissions

The immediate family owns the grave record. The first immediate-family claimant becomes steward and can approve or remove any shared memory. Not only to prevent abuse — some families won't want a memory board at all, and that must be their call.

Everyone else contributes and waits. Private notes are never visible to the steward or anyone else.

## 11. Screens

1. **Find** — search leads, saved graves below, small map at the bottom. Typing a name goes straight to the grave.
2. **Orient** — drawn section plan; rows as labelled lines, graves as cells, target filled. `Canvas`, not MapKit, not satellite.
3. **Approach** — one arrow, one distance, one accuracy line. Arrow rotation = bearing minus heading. The arrow *shrinks* as distance falls.
4. **Arrive** — below ~8 m the arrow is replaced by the headstone photo and landmark text. The app stops navigating and asks the person to look. This handoff is the product's signature moment.
5. **Tend** — prayer text, flower, visit record.
6. **Memories** — what the outer circle left, in chronological order. Reading requires presence.
7. **Write** — private note or shared memory, chosen explicitly and plainly labelled.

## 12. Interaction detail

- Distance rounds to whole metres above 20 m, 5 m increments below. Never show precision you don't have.
- Smooth heading with a low-pass filter or ~0.3 s animation; handle the 359°→1° wraparound explicitly or the arrow spins the long way.
- Haptics: `.light` crossing into the near phase, `.medium` on arrival.
- Compass drift near metal is expected. If heading confidence is poor, freeze the arrow and show the landmark text rather than letting it flail.
- Motion is slow fades, never bounces.

## 13. Data

**Seed data** — bundled `graves.json`, read-only, offline. Rural cemetery reception is unreliable and the demo must not depend on network.

**User data** — SwiftData, local. Saved graves, visit logs, private notes.

**Shared memories** — for the prototype, seed two or three with earlier timestamps directly in the JSON. Visually identical to a live backend at zero cost. Only if time allows, move to CloudKit: public database for grave records, private for the user's own, `CKShare` for family-scoped memories.

**CloudKit gotchas** — `@Attribute(.unique)` is unsupported when SwiftData syncs with CloudKit; dedupe in code. Every property must be optional or carry a default, and every relationship must be optional.

## 14. Field survey

Permission from the *pengurus* / desa adat first — this is a customary-village cemetery, not a city-run TPU. Build a hidden capture mode (long-press the version number) recording coordinates, name, section/row/plot, headstone photo and one landmark sentence per grave, exporting JSON. 25–40 graves in one section, roughly 3 hours.

Etiquette: long trousers, do not step over graves, ask before photographing.

## 15. Acceptance criteria

- Someone who is not immediate family, knowing only a name, reaches the correct grave without asking anyone.
- Time from opening the app to standing at the grave is under 5 minutes.
- The app never displays a distance or position more precise than its actual accuracy.
- A shared memory written by a friend reaches the family and is attributable to them.
- No screen would embarrass someone holding the phone beside a grave — test this literally with the caretaker.
- Everything works with the network disabled.
- No screen totals, ranks, or counts any act of remembrance.

## 16. Demo script

An old school friend hears that Ni Wayan Sari has died. He never knew the family well and doesn't feel he can ask where she's buried.

He searches her name → the section plan shows Row 4, Plot 12 → he walks, the arrow counts down → at 8 m the photo appears with the landmark line → he confirms → the doa is there, so he knows what to recite → he leaves kamboja and records the visit → he writes what he remembers: she taught him to ride a motorbike in 1985 and shouted the whole way.

Her daughter, in Surabaya, reads it. She had never heard that story.

## 17. Open questions

- Does the caretaker corroborate the wayfinding problem at *this* cemetery? If nobody ever asks him, the premise needs rechecking.
- **Ask two or three people:** "Has someone you weren't close family to died, and you didn't go to the grave because it felt like it wasn't your place?" Immediate recognition validates the outer-circle premise. Puzzlement means going back to the immediate family as primary user.
- **Ask a bereaved family:** "Would you want to read what your father's old friends remember about him, or would that feel like an intrusion?" One clear yes is required before building shared memories. If mixed, ship private notes only and let families opt in.
- Correct tuning for the visual handoff threshold — 8 m is a starting guess.

## 18. Design direction

Limestone `#EFEDE6`, shade-green ink `#1C2621`, moss `#5B6961`, hairline `#D6D3C9`, and one ochre `#C9A227` drawn from the yellow throat of the *kamboja* planted throughout Indonesian cemeteries. Ochre appears on the arrival screen only — restraint is the argument. An app in a burial ground earns trust by being visibly unwilling to entertain you.

Newsreader serif for names of the deceased and for memories left by others — those are voices, and names are what gets engraved. Instrument Sans for everything the app itself says.

High contrast, large type: used outdoors in bright sun by people who may be older and are often upset.
