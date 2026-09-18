> **Superseded by [PRD-v4](PRD-v4.md).** Kept for the reasoning v4 inherits.

# Makamakam — Product Requirements v3

**Platform:** iOS 17+, SwiftUI, Apple frameworks only, plus a Next.js admin site
**Status:** Working prototype for the Apple Developer Academy challenge
**Prototype site:** Pemakaman Islam II, Lingkungan Desa Adat Kuta — Gg. Kamboja, Tuban, Badung, Bali

*Supersedes v2. This version is written from the app as it now stands rather than
as it was imagined. Main changes: the three pillars survive but Gather is now a
**wall** and a **profile** rather than messages; **private notes have been
removed**; records live in **CloudKit**, edited through an **admin site**; the
grave-level drawing is a **surveyed plan** rather than a row-and-plot grid; and
one presence rule has been deliberately relaxed.*

---

## 1. Challenge statement

Empower the people at the edge of a loss — cousins, old friends, neighbours — to
find a grave they were never shown, tend it in their own tradition, and leave the
family a memory of the person that only they hold.

Unchanged from v2, and still the thing to judge the product against.

## 2. The three pillars

| | Object | Job | Requires presence |
|---|---|---|---|
| **Locate** | A place | Get me to the grave | — |
| **Tend** | An act | Know what to do while standing there | Yes |
| **Gather** | People | What happened here, and who this person was | Posting a visit: yes. Everything else: no |

## 3. Governing rule

**Words travel. Acts don't.**

A doa said alone in a room is as valid as one said at a graveside, so words can be
written from anywhere. Scattering a flower and praying at the plot are acts, and
acts need a body in a place.

**What changed in v3.** v2 also made *reading* an act, and locked the memories to
the cemetery. That has been relaxed: the wall is readable from anywhere the family
allows. The trade was made knowingly — it removes reading as a reason to travel,
and buys the ability of a daughter in Surabaya to follow her mother's grave. What
presence still protects is the **check-in**, because it is a claim about being
somewhere and must therefore be true, and the **prayers**, which exist for someone
standing there.

## 4. Problem

Unchanged from v2 and still the foundation: **wayfinding** (staff search by date
of death in a paper ledger; one Jakarta cemetery holds ~60,000 plots),
**entitlement** (Doka's *disenfranchised grief* — the cousin, the school friend and
the neighbour have nowhere to put the loss), **a funeral happens once** (a grave,
unlike a funeral, is available on a Tuesday afternoon three years later),
**asymmetry of memory** (the outer circle holds stories the family has never
heard), **distance**, and **seasonality**.

One correction from the field: at the prototype site the graves are **not laid out
in rows**. Markers sit where the ground allowed, around a tree, at angles, many
uninscribed. Any design that assumes a grid describes a filing system rather than
a place. See §8.

## 5. Users

**Primary — the outer circle.** Cousin, old friend, former neighbour, colleague.

**Primary — the immediate family.** Owns the grave record, holds the wall, writes
the profile.

**Secondary — the distant relative.** Cannot travel. Now able to read the wall,
which is the point of the change in §3.

**Also a user, newly — the pengurus.** The caretaker or committee keeps the
records current through the admin site. v2 put cemetery operators out of scope;
that remains true of *plot inventory and burial rights*, but somebody has to be
able to correct a name without a developer.

## 6. Non-goals

Decisions already made. Do not reintroduce.

- **No gamification.** No scores, streaks, collection mechanics, avatars, bouncy
  motion, sound by default, or the word "unlock" anywhere in the interface.
- **Nothing is ever counted.** The wall is a timeline, never a total. A timeline
  says what happened; a total says who is winning, and two siblings would find
  that out within a week.
- **No purchases of any kind.**
- **No music.** If ambient sound is ever wanted, use Qur'an recitation.
- **Nothing is added to the physical grave.** No QR plaques, beacons, hardware.
  Messages are left **for people**, never "on a grave". Use "tend", never
  "decorate".
- **No notifications, ever, unless explicitly requested.** The app must not try to
  increase its own usage — pull, never push. Distance is shown where someone is
  already looking; it is never sent to them.
- **No public feed.** Content is per-grave and governed by that grave's family.
- **No virtual ziarah.**
- **No cemetery-wide mapping pipeline.** No drone survey, no orthomosaic, no
  custom map tiles. Reasoning in §8.
- **No Android, no web app.** The website is marketing, privacy and admin only.

## 7. Constraints

**GPS accuracy is 3–5 m; graves are ~1 m apart.** The app cannot identify which
grave you are standing at.

**Accuracy does not improve as you approach.** The arrow therefore *shrinks* as
distance falls, and the app hands over to a photograph at ~8 m.

**Errors compound.** A coordinate recorded by a phone standing at a grave carries
its own 3–5 m error, on top of the visitor's. Ten metres of combined error is most
of a small cemetery. This is why positions are surveyed as offsets (§8).

**Coordinate precision:** at this latitude 1° longitude ≈ 110,030 m. Store 6
decimal places (~11 cm); trust at most 5 (~1.1 m).

**MapKit is wrong at grave scale**, and so are custom tiles: a more beautiful map
does not make GPS more accurate, and OSM has no data for individual plots in an
Indonesian village cemetery. Cemetery-level: MapKit. Grave-level: a SwiftUI
`Canvas`.

**`ARGeoTrackingConfiguration` is very likely unavailable in Indonesia.**

**CloudKit's public database has no server-side logic and coarse permissions.** A
person may edit only what they created. This shapes moderation (§10) and is the
reason stewardship cannot be enforced by the database.

## 8. Core data model

| Field | Job |
|---|---|
| `x`, `y` | **Position.** Metres east and north of the cemetery's origin — the gate — measured with a tape. Relative accuracy is centimetres, and the whole plot shares one GPS error instead of each grave carrying its own. This is what the plan is drawn from. |
| `coordinate` | A destination to walk toward. Derived from the offsets, or the only thing a hurried survey managed. |
| `bearing` | Which way the stone lies. Nil falls back to the cemetery's figure; no grave is drawn at an angle nobody measured. |
| `section` / `row` / `plot` | **A label**, because that is how the pengurus refers to a grave. It no longer decides where anything is drawn. |
| `photos` | The headstone, and the person where the family offered one. Empty is ordinary. |
| `landmark` | The caretaker's knowledge, written down. Bridges the last few metres. |
| `religion` | Decides which prayers are shown. Nullable, and **never inferred from a name**. |
| `fatherName`, `gender` | Renders "binti Sulaiman", "bin Hamzah", or "putri dari …". |
| `verified` | Whether a human physically stood there. |
| `stewardName` | The family member who holds the record. |
| `profileMarkdown` | The life of the person, written by the family in the admin. |
| `wallVisibility` | open, family, or closed. |

The cemetery carries the **gate** as its origin, the **wall** as corner offsets,
and `graveBearing`.

## 9. Pillar detail

### Locate

Find tab: the map, full screen, resting at about 7 km. **The search finds
cemeteries, not people** — there is no national register of the dead behind this
app, there is one cemetery somebody walked with a notebook, and starting at the
burial ground is both honest and how the question actually arrives. Search runs
without a radius, so "Jakarta" works from Kuta.

Pins are photographs where one exists. The surveyed cemetery is grass with a
magnifying glass; everything else is granite with a leaf, sourced from Apple Maps
and labelled as such. A legend says what each means in the terms that matter:
*searchable down to a grave* against *only as far as the gate*.

Inside a cemetery: a **surveyed plan** — the real spread, drawn to scale from
offsets, the wall filled in, the reader as a **circle sized to actual accuracy
rather than a dot**. North stays up; the plan follows the compass only while
walking. Then Orient → Approach (one arrow, one distance, one accuracy line,
escalating haptics) → **Arrive**, where the app stops navigating and shows the
headstone photograph and the landmark sentence.

### Tend

Prayer text by tradition, following the **faith recorded for the person buried
there**, not the reader's own setting; the reader's setting is only the fallback
where the survey could not confirm it, and the screen says which of the two
happened. Arabic, transliteration, Indonesian and English meaning.

Presence required. The flower and the visit log have moved to the wall.

### Gather

**The wall.** One timeline per grave, beginning on the day of the death: visits,
flowers, stories, in the order they happened. A **check-in** is one post — that
you came, optionally with kamboja, optionally a line — and is the one thing that
still requires standing at the grave. Stories may be written from anywhere.
Nothing is totalled.

**The profile.** Markdown, written by the family in the admin where a keyboard
makes prose bearable, rendered in the app. Absence is ordinary.

**Private notes were removed.** v2 gave the 3am feeling somewhere to land that was
never shared. In practice it was a second writing surface with different rules
about a different destination, and explaining "this one is private, that one is
not" cost more than it gave. What remains is one place to write, with one
explanation of where it goes.

## 10. Permissions

The immediate family owns the grave record. The steward can show or remove any
post, and set the wall to open, family-only or closed — closed means closed, the
family included, because a family that does not want a wall must be able to say so.

**Moderation is its own record, not a field on the post.** CloudKit lets a person
edit only what they created, so a steward can never write to a stranger's record.
A decision is therefore a `WallDecision` made by the steward, latest one winning —
which is also closer to the truth: the post is what somebody said, the decision is
what the family did about it.

**The database cannot enforce stewardship.** Anyone with the app could write a
claim. For one cemetery this is acceptable; before real families depend on it,
stewardship should be granted from the admin with the server key, which only the
operator holds.

## 11. Screens

1. **Find** — the map, cemetery search, pins.
2. **Cemetery** — hero photograph, the plan, and the name search.
3. **Plan, full screen** — pinch, drag, tap a grave to open it.
4. **Grave** — name, parentage, faith, photographs, and the doors.
5. **Orient** — the surveyed plan with the target marked.
6. **Approach** — one arrow, one distance, one accuracy line.
7. **Arrive** — the photograph and the landmark. The signature moment.
8. **Tend** — prayers, by the faith of the person buried there.
9. **Wall** — the timeline, the check-in, the steward's controls.
10. **Profile** — the life, as the family wrote it.
11. **Saved** — the graves this person keeps.
12. **Settings** — language, iCloud, vibration, what the app refuses to do.

Plus a **field mode** behind a long press on the version number: presence
override, haptics rehearsal, simulated walk, survey capture and JSON export.

## 12. Interaction detail

- Distance rounds to whole metres above 20 m, 5 m increments below.
- Heading is low-pass filtered with the 359°→1° wraparound handled explicitly.
- **Haptics escalate**: about every 3 s and faint at 80 m, three times a second
  and firm at the 8 m handoff, then silent on arrival. A pace, not a measurement.
  It can be turned off.
- If heading confidence is poor the arrow freezes and the landmark takes over.
- Motion is slow fades, never bounces.
- Words live on marble; granite is only ever the ground.

## 13. Data

**Bundled `graves.json`** — the floor. Read at launch, works with the radio off.

**CloudKit** — `Cemetery`, `Grave`, `Photo` (assets), `WallPost`, `WallDecision`
in the **public** database; `SavedGrave` in each person's **private** database,
because which graves somebody keeps is theirs alone.

**Precedence**: bundle, then the last cached snapshot, then a fresh fetch. A
failed sync changes nothing on screen, and an empty result is discarded rather
than applied — a misconfigured container must not empty somebody's app in the
middle of a cemetery.

**Identity**: CloudKit's own, which is the Apple ID already on the phone. There is
no login screen because there is no second account. Because that convenience is
invisible, the app explains where a post is going **before the first one**, and
Settings reports the account state plainly — including, in red, when nothing can
leave the phone.

**Development and production are different databases.** Xcode builds read
development; TestFlight and the App Store read production. Deploying a schema
copies the shape and not the records.

## 14. Field survey

Permission from the *pengurus* / desa adat first.

1. Stand at the gate for ~60 s of averaged GPS. That single point is the only
   absolute position needed.
2. Walk the perimeter with a tape and record the **wall corners**. This does more
   navigational work than any individual pin.
3. Record each grave as an **offset in metres** from the gate, plus name,
   parentage, faith, death date, a landmark sentence, and a headstone photograph.
   A portrait only where the family offers and permits.

Etiquette: long trousers, do not step over graves, ask before photographing.

**The bundled 27 graves are invented** — plausible positions inside a boundary
traced from satellite imagery. They exist to exercise the app, not to describe the
dead.

## 15. Acceptance criteria

- Someone who is not immediate family, knowing only a name, reaches the correct
  grave without asking anyone.
- Time from opening the app to standing at the grave is under 5 minutes.
- The app never displays a distance or position more precise than its accuracy.
- A story written by a friend reaches the family's phone, attributable to them.
- A family that wants no wall can have none.
- No screen would embarrass someone holding the phone beside a grave.
- **Everything except sync works with the network disabled.**
- No screen totals, ranks, or counts any act of remembrance.

## 16. Demo script

An old school friend hears that Ni Wayan Sari has died. He never knew the family
well and doesn't feel he can ask where she's buried.

He searches the cemetery → opens it → sees the plan and her name → walks, the
arrow counting down and the phone pulsing faster → at 8 m the photograph appears
with the landmark line → he confirms → the doa is there, in her faith → he
scatters kamboja and records the visit → he writes what he remembers: she taught
him to ride a motorbike in 1985 and shouted the whole way.

Her daughter, in Surabaya, reads it on the wall. She had never heard that story.

## 17. Open questions

- Does the caretaker corroborate the wayfinding problem at *this* cemetery?
- Ask two or three people: *"Has someone you weren't close family to died, and you
  didn't go to the grave because it felt like it wasn't your place?"*
- Ask a bereaved family whether reading what a father's old friends remember would
  feel like an intrusion.
- **Was opening the wall right?** v2 argued reading should require presence. v3
  relaxed it. Worth asking families and visitors directly.
- Correct tuning for the 8 m handoff, and for the haptic curve.
- **The prayer text needs checking** with the caretaker or a local tokoh before
  wider use. Yāsīn currently carries only its opening, labelled as such.
- Stewardship enforcement, before real families depend on it.

## 18. Design direction

Taken from the material hierarchy of the headstone itself: **speckled granite
ground → white marble plaque → the name painted into it → grass all around.**

Granite `#C6C5C0` under every screen, with a drawn noise tile. Marble `#FBFAF7`
for anything carrying words. Ink `#16181A`. Grass `#4A7A3B` for the things you act
on, and for the ground of the plan. Engraved red `#A8342A` **once**, on the
arrival screen, where you confirm a name.

Serif for names of the deceased and for what other people wrote — those are
voices, and names are what gets engraved. Sans for everything the app says itself.
High contrast, large type, read outdoors in bright sun by people who may be older
and are often upset.

Indonesian and English throughout, chosen by the reader.
