# Makamakam — Product Requirements

**Platform:** iOS 17+, SwiftUI, Apple frameworks only, plus a Next.js admin site
**Status:** Working prototype for the Apple Developer Academy challenge
**Site:** Pemakaman Islam II, Lingkungan Desa Adat Kuta — Gg. Kamboja, Tuban, Badung, Bali

---

## 1. Challenge

Empower the people at the edge of a loss — cousins, old friends, neighbours — to
find a grave they were never shown, tend it in their own tradition, and leave the
family a memory of the person that only they hold.

## 2. The three pillars

| | Object | Job |
|---|---|---|
| **Locate** | A place | Get me to the grave |
| **Tend** | An act | Know what to do while standing there |
| **Gather** | People | What happened here, and who this person was |

## 3. The rule

**Words travel; acts don't. Prayers and stories can be read and written from
anywhere. The check-in cannot, because it asserts presence and must therefore be
earned.**

Exactly one thing in this product requires standing at the grave: the check-in,
and the kamboja attached to it. Everything else — the name, the parentage, the
dates, the photographs, the location, the plan, the prayer text, the wall and the
profile — is reachable from anywhere, subject only to `wallVisibility`.

## 4. Problem

**Wayfinding.** Indonesian cemetery reporting describes visitors arriving unable to
locate a relative. Staff search by date of death in a system or a paper ledger. One
Jakarta cemetery holds ~60,000 plots.

**Entitlement.** The barrier for the outer circle is not only that they don't know
where the grave is — it's that they don't feel it's their place to ask the family or
to turn up. Doka's term is *disenfranchised grief*: mourning a society gives no
recognised role to.

**A funeral happens once.** People miss it, through work, distance, or not hearing
in time. A grave, unlike a funeral, is available on a Tuesday afternoon three years
later. The product makes mourning **asynchronous**.

**Asymmetry of memory.** The outer circle holds stories the family has never heard.
Bereaved families are often too close, or too raw, to write about their own parent.
A friend isn't.

**Distance and seasonality.** Tuban and Kuta have a large migrant Muslim population
from Java, Madura and Lombok; families are scattered and most cannot attend at
Lebaran. Visits cluster around Idulfitri, with a weekly Friday tradition alongside.
The typical user is an infrequent, high-stakes visitor with no route memory.

**From the field, three things that change the design:**

- **The graves are not in rows.** Markers sit where the ground allowed, around a
  tree, at angles. A grid describes a filing system rather than a place.
- **Some stones carry no name and no dates.** Nobody can find those graves by
  walking and reading, so wayfinding is not a convenience here — for them it is the
  only route there is. It also breaks the survey: a name cannot be read off a blank
  stone, so it must come from a person.
- **Graves are managed collectively.** A *kelompok* manages blocks of graves rather
  than each family managing its own.

## 5. Users

**The outer circle.** Cousin, old friend, former neighbour, colleague. Feels the
loss, has no role, doesn't know the grave, won't ask.

**The immediate family.** Owns the grave record, holds the wall, writes the profile.

**The distant relative.** Cannot travel. Reads the wall; writes and someone else
carries.

**The pengurus.** Keeps the records current through the admin site. Plot inventory,
capacity and burial rights remain out of scope.

**The kelompok.** A group managing a block of graves — closer than the committee,
wider than one household. Likely holder of the written list, and the people who can
say which family belongs to which grave. **The product does not address them yet,
and should.**

## 6. Non-goals

Decisions already made. Do not reintroduce.

- **No gamification.** No scores, streaks, collection mechanics, avatars, bouncy
  motion, sound by default, or the word "unlock" anywhere.
- **Nothing is ever counted.** The wall is a timeline, never a total. A timeline
  says what happened; a total says who is winning.
- **No purchases of any kind.**
- **No music.** If ambient sound is ever wanted, use Qur'an recitation.
- **Nothing is added to the physical grave.** No plaques, beacons or hardware.
  Messages are left **for people**, never "on a grave". Use "tend", never
  "decorate".
- **No notifications, ever, unless explicitly requested.** The app must not try to
  increase its own usage — pull, never push. Distance is shown where someone is
  already looking; it is never sent to them.
- **No public feed.** Content is per-grave and governed by that grave's family.
- **No virtual ziarah.** The app does not simulate a visit.
- **No cemetery-wide mapping pipeline.** No drone survey, no orthomosaic, no custom
  tiles: a better-looking map does not make GPS more accurate.
- **No Android, no web app.** The website is marketing, privacy and admin only.

## 7. Constraints

**GPS accuracy is 3–5 m; graves are ~1 m apart.** The app cannot identify which
grave you are standing at.

**Accuracy does not improve as you approach**, so the arrow *shrinks* rather than
growing, and the app hands over to a photograph before the arrow becomes a liar.

**Errors compound, and the arrow falls off a cliff.** What matters is the direction
error the distance error produces: `atan(e / d)` — about 6° at 30 m, 45° at 3 m for
a 3 m error. Three things make the real error larger than the figure on screen: the
surveyed coordinate carries its own error on top of the visitor's (two 3 m errors
combine to ~4.2 m); `horizontalAccuracy` is a 68% radius, so one reading in three is
worse than reported; and quoted figures are open-sky, while this site has kamboja
throughout, a boundary wall and stones.

So the handoff is **derived, not chosen**: hand over where the direction error would
exceed **20°**, clamped to 5–15 m.

**Coordinate precision:** at this latitude 1° longitude ≈ 110,030 m. Store 6 decimal
places (~11 cm); trust at most 5 (~1.1 m).

**MapKit is wrong at grave scale.** Cemetery-level: MapKit. Grave-level: a SwiftUI
`Canvas` drawn from surveyed offsets.

**CloudKit's public database has no server-side logic and coarse permissions.** A
person may edit only what they created. This shapes moderation (§10), and is why
stewardship cannot be enforced by the database.

## 8. Data model

| Field | Job |
|---|---|
| `x`, `y` | **Position.** Metres east and north of the gate, measured with a tape. Relative accuracy is centimetres, and the whole plot shares one GPS error instead of each grave carrying its own. The plan is drawn from these. |
| `coordinate` | A destination to walk toward. |
| `bearing` | Which way the stone lies. Nil falls back to the cemetery's figure; no grave is drawn at an angle nobody measured. |
| `section` / `row` / `plot` | **Optional, and only a label** — how a pengurus refers to a grave, not how the app finds one. Shown on the grave's own screen and in a list; never on the walk. |
| `photos` | The headstone, and the person where the family offered one. Empty is ordinary. |
| `landmark` | The caretaker's knowledge, written down. Bridges the last few metres. |
| `religion` | Decides which prayers are shown. Nullable, and **never inferred from a name**. |
| `fatherName`, `gender` | Renders "binti Sulaiman", "bin Hamzah", or "putri dari …". |
| `verified` | Whether a human physically stood there. |
| `stewardName` | The family member who holds the record. **Known gap:** stewardship here is collective, and one name cannot express a kelompok. Needs a conversation with the group before it is designed. |
| `profileMarkdown` | The life of the person, written by the family. |
| `wallVisibility` | open, family, or closed. |

A grave's **name may be unknown**, or may have come from the kelompok's list rather
than from the stone. The model should say which; it does not yet.

The cemetery carries the **gate** as its origin, the **wall** as corner offsets, and
`graveBearing`.

## 9. The pillars in detail

### Locate

The map, full screen, resting at about 7 km. **The search finds cemeteries, not
people** — there is no national register of the dead behind this app, and starting
at the burial ground is both honest and how the question actually arrives. There may
be **several surveyed cemeteries**: each gets its own pin, its own plan and its own
graves, and a name is searched inside one rather than across all of them. Search
runs without a radius, so "Jakarta" works from Kuta.

Pins are photographs where one exists. The surveyed cemetery is grass with a
magnifying glass; the rest are granite with a leaf, sourced from Apple Maps and
labelled as such. The legend says what each means in the terms that matter:
*searchable down to a grave* against *only as far as the gate*.

Inside a cemetery: a **plan drawn to scale from offsets**, the wall filled in, the
reader as a **circle sized to actual accuracy rather than a dot**. North stays up.
Then Orient → Approach (one arrow, one distance, one accuracy line, escalating
haptics) → **Arrive**, where the app stops navigating and shows the headstone
photograph and the landmark sentence.

### Tend

Prayer text following the **faith recorded for the person buried there**, not the
reader's own setting; that is only the fallback where the survey could not confirm
it, and the screen says which of the two happened. Arabic, transliteration, and
meaning in both languages. No presence required.

### Gather

**The wall.** One timeline per grave. Anyone may add to it from anywhere. A post
made while standing at the grave is marked as a visit and may carry kamboja;
presence is verified, never claimed. Posts appear immediately; the steward may
remove any of them, and sets whether the wall is open, family-only, or closed. Name,
photographs, dates and location remain visible regardless — a grave must stay
findable even when its family wants no wall.

**The profile.** Markdown, written by the family in the admin where a keyboard makes
prose bearable, rendered in the app. Absence is ordinary.

## 10. Permissions

| `wallVisibility` | Wall and profile | Everyone else sees |
|---|---|---|
| `open` | anyone, anywhere | — |
| `family` | linked family, anywhere | name, photos, dates, location |
| `closed` | nobody | name, photos, dates, location |

The steward governs what the living added, never the record of the burial itself.
You cannot navigate someone to a grave whose name they cannot search.

**Moderation is post-moderation.** A post is on the wall the moment it is written
and leaves only if the steward takes it down. CloudKit cannot let a steward edit a
stranger's record, so approval could never have been a field on the post;
`WallDecision` is a separate record, latest one winning. And a friend who writes at
2am and hears nothing for a week will not write again — that cost is larger than
something unwanted being briefly visible.

**The database cannot enforce stewardship.** Anyone with the app could write a
claim. The answer is in the field rather than the schema: the kelompok already knows
which family belongs to which grave, so stewardship should be vouched for by them
and granted from the admin with the server key.

## 11. Screens

**Find** (the map) · **Cemetery** (hero, plan, name search) · **Plan, full screen**
(pinch, drag, tap a grave) · **Grave** (name, parentage, faith, photographs, doors)
· **Orient** · **Approach** · **Arrive** · **Tend** · **Wall** · **Profile** ·
**Saved** · **Settings**.

Plus a **field mode** behind a long press on the version number: presence override,
haptics rehearsal, simulated walk, survey capture and JSON export.

## 12. Interaction detail

- Distance rounds to whole metres above 20 m, 5 m increments below. Never show
  precision you don't have.
- The handoff distance is **computed**: `combined / tan(20°)`, clamped 5–15 m. The
  near phase stays proportional to it.
- **The arrow shrinks as it closes**, inverting AirTag. A UWB radio at both ends
  earns growing confidence; a phone does the opposite. Deliberate, and commented as
  such in the source.
- Heading is low-pass filtered with the 359°→1° wraparound handled explicitly. If
  confidence is poor the arrow freezes and the landmark takes over.
- **Haptics escalate**: about every 3 s and faint at 80 m, three times a second and
  firm at the handoff, silent on arrival. A pace, not a measurement. Can be turned
  off.
- **The card where a person is chosen carries three fields**: name, parentage, year
  of death. That is what answers *is this them*.
- Motion is slow fades, never bounces. Words live on marble; granite is only ever
  the ground.

## 13. Data and sync

**Bundled `graves.json`** is the floor: read at launch, works with the radio off.

**CloudKit** holds `Cemetery`, `Grave`, `Photo` (assets), `WallPost` and
`WallDecision` in the **public** database, and `SavedGrave` in each person's
**private** database, because which graves somebody keeps is theirs alone.

**Precedence:** bundle, then the last cached snapshot, then a fresh fetch. A failed
sync changes nothing on screen, and an empty result is discarded rather than applied
— a misconfigured container must not empty somebody's app in the middle of a
cemetery.

**Identity** is CloudKit's own, which is the Apple ID already on the phone. There is
no login screen because there is no second account. Because that convenience is
invisible, the app explains where a post is going **before the first one**, and
Settings reports the account state plainly — including, in red, when nothing can
leave the phone.

**Development and production are different databases.** Xcode builds read
development; TestFlight and the App Store read production. Deploying a schema copies
the shape and not the records.

## 14. Field survey

Permission from the *pengurus* / desa adat first — this is a customary-village
cemetery, not a city-run TPU.

1. **Ask the kelompok for their list.** A group that collects dues keeps a record,
   and it is both the fastest cold start and the *only* possible source for the
   graves whose stones carry no name.
2. Stand at the gate for ~60 s of averaged GPS. That single point is the only
   absolute position needed.
3. Walk the perimeter with a tape and record the **wall corners**. The shape does
   more navigational work than any individual pin.
4. Record each grave as an **offset in metres** from the gate, plus name, parentage,
   faith, death date, a landmark sentence, and a headstone photograph. A portrait
   only where the family offers and permits.

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
- A family that wants no wall can have none, and the grave stays findable.
- No screen would embarrass someone holding the phone beside a grave — test this
  literally, with the caretaker.
- Everything except sync works with the network disabled.
- No screen totals, ranks, or counts any act of remembrance.

## 16. Demo script

An old school friend hears that Ni Wayan Sari has died. He never knew the family
well and doesn't feel he can ask where she's buried.

He searches the cemetery → opens it → finds her name → walks, the arrow counting
down and the phone pulsing faster → at the handoff the photograph appears with the
landmark line → he confirms → the doa is there, in her faith → he scatters kamboja
and records the visit → he writes what he remembers: she taught him to ride a
motorbike in 1985 and shouted the whole way.

Her daughter, in Surabaya, reads it on the wall. She had never heard that story.

## 17. Open questions

- Does the caretaker corroborate the wayfinding problem at *this* cemetery? If
  nobody ever asks him, the premise needs rechecking.
- Ask two or three people: *"Has someone you weren't close family to died, and you
  didn't go to the grave because it felt like it wasn't your place?"* Immediate
  recognition validates the outer-circle premise.
- Ask a bereaved family whether reading what a father's old friends remember would
  feel like an intrusion. One clear yes is required before relying on the wall.
- **Was opening the wall and the prayers right?** Earlier drafts required presence
  for both. Ask the same families in the same conversation — it is one question
  about what presence is for.
- **What does the kelompok actually do?** Maintenance, dues, burial arrangements?
  Do they keep a written list, and in what form?
- **Can anyone name the uninscribed graves?** If the kelompok can, that is the only
  route those graves have. If nobody can, the product should say so rather than
  leave a blank.
- Tuning for the **20° angular ceiling** and the **5–15 m clamp**, against
  `horizontalAccuracy` logged at the site — in the open and under the kamboja
  canopy, which will not agree.
- **The prayer text needs checking** with the caretaker or a local tokoh before
  wider use. Yāsīn currently carries only its opening, labelled as such.
- Stewardship enforcement, before real families depend on it.

## 18. Design direction

Taken from the material hierarchy of the headstone itself: **speckled granite ground
→ white marble plaque → the name painted into it → grass all around.**

Granite `#C6C5C0` under every screen, with a drawn noise tile. Marble `#FBFAF7` for
anything carrying words. Ink `#16181A`. Grass `#4A7A3B` for the things you act on,
and for the ground of the plan. Engraved red `#A8342A` **once**, on the arrival
screen, where you confirm a name.

Serif for names of the deceased and for what other people wrote — those are voices,
and names are what gets engraved. Sans for everything the app says itself. High
contrast, large type, read outdoors in bright sun by people who may be older and are
often upset.

Indonesian and English throughout, chosen by the reader.
