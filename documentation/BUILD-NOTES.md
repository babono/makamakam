# Makamakam — build notes

iOS 17+, SwiftUI, Apple frameworks only. No packages, no backend, no network.
Built against PRD-v2.md; section numbers below refer to it.

## Running it

```
open makamakam.xcodeproj          # scheme: makamakam
```

Command-line builds must either sign, or opt out of CloudKit:

```
xcodebuild -scheme makamakam -destination 'platform=iOS Simulator,name=iPhone 17' build \
  CODE_SIGNING_ALLOWED=NO OTHER_SWIFT_FLAGS='$(inherited) -D NO_CLOUDKIT'
```

An unsigned binary carries no entitlements, and `CKContainer(identifier:)` does
not fail politely without one — it traps on the spot. iOS offers no public way to
ask a running binary what it was signed with, so the guard is a compile-time flag
(`RemoteCatalog.isAvailable`). Xcode signs both device and simulator builds, so
the flag is only ever needed from the command line.

The Simulator has no compass and no real position, so two things help:

1. **Simulated position.** `xcrun simctl location booted set -8.735571,115.173522`
   puts you inside the prototype cemetery, which is what opens the
   presence-locked screens. Anywhere else (try Surabaya,
   `-7.257472,112.752090`) shows the remote state instead.
2. **Launch straight onto a screen** (DEBUG only, `Services/Demo.swift`):

   ```
   xcrun simctl launch booted me.babono.makamakam -demo arrive
   ```

   `-demo` takes `cemetery`, `grave`, `orient`, `approach`, `arrive`, `tend`,
   `memories`, `write`, `saved`, `settings`; `-demoLang id|en` forces the interface
   language; `-demoSearch "Sari"` pre-fills the search field; `-demoSaved
   "A-2-03,A-1-01"` fills the Saved tab; `-demoGrave A-3-02` picks a different grave (default is Ni Wayan
   Sari, the demo script in §16); `-demoMetres 60` sets where the simulated walk
   starts. The guide screens start a simulated walk toward the grave, which is
   also reachable in the app at **Tentang → long-press the version number →
   Simulasi berjalan**.

## Shape of the code

```
Design/      Palette, granite texture, the two type voices, shared components
Localization/ Lang (the chosen language) and the full ID/EN string table
Models/      Grave + Site (seed, read-only), SwiftData records (local, private)
Services/    Geo maths, LocationService, GraveStore, Presence, Identity,
             Records (all SwiftData reads/writes), Feedback, Demo
Features/
  RootView   the three tabs: Find, Saved, Settings
  Find/      FindView (the map), CemeteryView (names inside one cemetery),
             SavedView, GraveView (the hub)
  Guide/     GuideFlowView, OrientView (2), ApproachView (3), ArriveView (4)
  Tend/      TendView (5), PrayerLibrary, PassageView
  Gather/    MemoriesView (6), WriteView (7)
  More/      SettingsView, DeveloperView, SurveyCaptureView, SurveyExportView
Resources/   graves.json — the bundled survey
```

## Where the PRD's rules live in the code

| Rule | Where |
|---|---|
| Words travel, acts don't (§3) | `Presence.atGrave`, read once by `PostComposer` — the only gate left in the app |
| Accuracy never overstated (§7, §12) | `Distance.text` / `Distance.accuracyText` in `Geo.swift` |
| Arrow shrinks as distance falls (§11) | `ApproachView.arrowScale` |
| Heading smoothing + 359°→1° (§12) | `Geo.smooth` / `Geo.delta`, plus a 0.3 s animation |
| Frozen arrow when the compass drifts (§12) | `LocationService.headingIsTrustworthy` → `ApproachView.frozen` |
| Handoff derived, not fixed (§7, §12) | `Phase.handoffDistance(userAccuracy:graveAccuracy:)` — `combined / tan(20°)`, clamped 5–15 m |
| Grave scale is a Canvas, not MapKit (§7) | `SitePlan`, drawn from surveyed offsets |
| No totals, no ranking (§6) | `Records.wall` returns a sorted timeline; nothing counts |
| Post-moderation, not pre-moderation (§10) | posts default to `.approved`; `WallDecision` takes them down |
| One post type, presence verified not claimed (§9) | `WallPostRecord.visitedInPerson`, written by `PostComposer` from the phone's own position |
| Steward removes, never pre-approves (§10) | `Records.setApproval`, `WallStore.decide` |
| The record is never hidden (§10) | only `WallView` and `ProfileView` consult `wallVisibility` |
| One accent, on the arrival screen only (§18) | `Palette.engraved`, used once, in `ArriveView` |
| No notifications, no push (§6) | entitlements emptied, no `UNUserNotificationCenter` anywhere |
| CloudKit-safe models (§13) | every property defaulted, no relationships, no `@Attribute(.unique)` |
| Field capture behind the version number (§14) | `SettingsView` long-press → `SurveyCaptureView` |
| The map stays at cemetery scale (§7) | `FindView` draws one marker, for the burial ground — never a pin per grave |

## Seed data

`Resources/graves.json` holds 27 graves in one block (6 rows), two seeded shared
memories on Ni Wayan Sari and one on Nur Hasanah, and two earlier visits.
Coordinates are generated on a 2.6 m row / 1.2 m plot grid around the prototype
site and stored to 6 decimals. **They are plausible, not surveyed** — they stand
in until the field survey in §14 runs, and `verified: false` on four records is
there to exercise the unverified state.

`SurveyExportView` exports captured rows in exactly this JSON shape, so a survey
run ends with a file that drops straight into the bundle.

## Deliberately not done

- **Prayer text needs a local check.** Al-Fātiḥah, Al-Ikhlāṣ, Al-Falaq, An-Nās,
  Āyat al-Kursī, the salam, the tahlil phrases and the doa ziarah are included in
  full. Yāsīn carries only its opening, labelled as such, because shipping a
  silently truncated surah would be worse than being honest about it. Have the
  caretaker or a local tokoh read all of it before any real use.
- **Hindu Bali tradition** is selectable but shows a note saying the text has not
  been prepared, rather than inventing one.
- **Headstone photos** are not in the bundle; `ArriveView` says so plainly
  instead of showing an empty frame. Add them as asset names in
  `headstonePhoto` once the survey has been run.
- **CloudKit** is not wired up — seeded memories look identical to a live backend
  at zero cost, as §13 allows. The models are already shaped for it.
- **Seed content is never translated.** Names, landmark sentences and the
  memories people wrote stay in the language they were written in — translating
  a neighbour's sentence about a swept yard would be putting words in their
  mouth.


## Design direction

Taken from the material hierarchy of the headstone photograph rather than from a
mood board: **speckled granite ground → white marble plaque → the name painted
into it → grass all around.**

| | |
|---|---|
| `granite` `#C6C5C0` | the ground under every screen, carrying a drawn noise tile |
| `plaque` `#FBFAF7` | every card; anything that carries words sits on marble |
| `ink` `#16181A` | the content, cut into the plaque |
| `grass` `#4A7A3B` | buttons, and the ground of the section plan |
| `engraved` `#A8342A` | the painted lettering — the arrival screen only |

**On the grass texture.** A photographic grass background was considered and
rejected: it fails in direct sun, it fights small type, and photographic
decoration in a burial ground drifts toward the visual vocabulary §6 rules out.
Grass appears instead where you are genuinely looking at the ground — it is the
field the section plan's stone cells sit in — and as the colour of the things you
act on. If it is ever wanted as a texture, the place for it is behind the
`SectionPlan` canvas, which is already a view straight down.

`GraniteTexture` draws its tile once from a fixed seed, so the grain never
shifts between launches and nothing is bundled. Contrast is controlled by hand
rather than inherited from a photograph, which is what keeps it readable outdoors.

## Language

`Lang` holds the choice; `Strings.table` holds every line in both languages, in
one file — the hidden field sheet and the survey screens included, since a
mentor or reviewer will open them as often as the survey team will. The first launch follows the device (Indonesian if the phone is
Indonesian, English otherwise) and after that it is set in About. Prayer
passages carry both meanings; the Arabic and the transliteration are the same in
either language.


## Navigation

Three tabs, SF Symbols, no more:

| Tab | Symbol | What it is |
|---|---|---|
| Find | `magnifyingglass` | The map, full screen and resting at about 7 km across. The search at the top looks for **cemeteries**, not names. Nothing else sits over the map but a recentre button; every burial ground speaks only when its pin is tapped. |
| Saved | `bookmark` | The graves this person keeps coming back to. Local, and nobody is told what is in it. |
| Settings | `gearshape` | Language, who you are, what the app refuses to do, where the data comes from, and the hidden survey mode. |

The map carries exactly one marker — the burial ground — plus the user's own
position. Twenty-seven pins at cemetery zoom would be 44 pt targets over 1 m
plots: precise-looking and false (§7). Everything closer than the gate is handled
by the section plan and the landmark sentence.


## Searching for a cemetery anywhere

Typing in the Find field searches **without a radius**. Someone who has flown home
for a funeral is usually looking for a burial ground a thousand kilometres from
where they are standing, so the 25 km ring around them is exactly the wrong place
to look.

`NearbyCemeteries.searchAnywhere` runs in two stages, because MapKit's search
region is a *bias* and not a fence — asking for "pemakaman" from Bali keeps
answering with Bali:

1. The words as typed, biased to where the person is. This is what finds
   "TPU Karet Bivak" or "Setra Kauh" when they know the name of the place itself.
2. If the best match for those words is more than a kilometre away, the term is
   treated as a **place name**: the cemetery keywords are asked again, centred on
   *there* with a ~35 km span. Typing "Jakarta" from Kuta comes back with TPU
   Pondok Kelapa, TPU Rorotan, Taman Makam Pahlawan and the rest, each about
   950 km out.

Results are grouped **Around here** / **Further away**, capped at twenty, and the
list scrolls inside a fixed height so a city search never grows over the field
that produced it. Choosing one flies the map to it and opens its pin; its marker
stays while the card is open, even though it is far outside the ambient 25 km set.

## Nearby cemeteries

`NearbyCemeteries` is the only part of the app that needs the network, and it is
built to fail quietly. MapKit has no cemetery point-of-interest category, so it
asks the way a person would — `pemakaman`, `makam`, `cemetery` — inside a 25 km
region, then keeps only results whose *name* says burial ground (`pemakaman`,
`makam`, `kuburan`, `setra`, `tpu`, `cemetery`, `graveyard`, `memorial park`), so
a free-text search cannot fill the list with whatever else sits near those words.
The surveyed cemetery is dropped from the results by distance *and* by name: Apple's
pin for a village burial ground can sit a few hundred metres from the gate the
survey was taken at.

They are **pins, and only pins**. Tapping one raises a card naming it, its
distance, and the line that matters — **"Not surveyed — the app can only take you
to the gate"** — plus a Directions button that hands off to Maps. The surveyed
cemetery's own pin (tagged `FindView.siteTag`) raises its own card: the "Surveyed"
mark, the line about the map stopping at the gate, and a button that puts the
cursor in the search field. Dismissing either card leaves a bare map.

Nothing announces the nearby search. If it fails there are simply no grey pins,
which is the truthful state of affairs; the app's own records are unaffected,
since everything else runs from the bundle (§13).

The map marks burial grounds and only burial grounds, plus the user's own
position. The surveyed one is grass with a **magnifying-glass** glyph; the rest
are granite with a **leaf**. The glyph difference is not decoration: in testing,
a green pin was read as "this one is near me" rather than "this one is surveyed",
so the distinction cannot rest on colour. A two-line legend sits at the bottom
left whenever there are other cemeteries on screen, and says what each pin means
in the terms that matter to someone looking for a person — *searchable down to a
grave* against *only as far as the gate* — rather than in the vocabulary of the
survey.


## Finding, in two steps

The search over the map looks for a **burial ground**, not a person: `pemakaman`,
a district name, `Kuta`. Choosing the surveyed one opens `CemeteryView`, and the
search for a name happens there, inside it.

This is the honest shape of the data. There is no national register of the dead
behind this app — there is one cemetery somebody walked with a phone and a
notebook. A single search box promising to find any name anywhere would be
writing a cheque the survey cannot cash, and would leave someone typing their
grandmother's name into a void. Starting at the cemetery also matches how the
question actually reaches a person: they know their friend was buried in Kuta,
not which of 60,000 plots they are in.

Cemeteries with no survey never lead to a name screen at all — their pin offers
directions and says why.

## Whose rite it is

Every grave record carries a `religion`, and the Tend screen follows it:
`Faith.tradition` picks the texts, so a friend of another faith — or none —
standing at a Muslim grave is shown what is said at a Muslim grave. The reader's
own setting is only the **fallback** for a grave whose faith the survey could not
confirm, and the screen always says which of the two happened. A menu still lets
someone pick a different set of texts for one visit; that choice is never written
back to their settings.

`religion` is nullable on purpose. A customary-village cemetery keeps a paper
ledger, and `Faith.unrecorded` is a real state, never inferred from a name — in
Bali, "Ni Wayan Sari" and "Ni Luh Zahra" would both be guessed wrong often enough
to matter. Two seeded graves carry no religion so the fallback path stays visible
in testing, and the survey capture screen records it as an explicit field with
"Tidak tercatat" as its first option.

Faiths with no bundled text (Christian, Catholic, Buddhist, Confucian, other)
say so by name rather than silently offering somebody else's prayers.

## Presence, and testing away from Bali

The prayer texts, the flower record and the memories are all presence-locked
(§3), so away from the cemetery they show the lock rather than the content. That
is the product working, not a bug — but it makes the app hard to test at a desk,
so the hidden field sheet (**Settings → long-press the version number**, hold for
about a second) opens with an **"Anggap saya di pemakaman"** toggle that treats
you as standing there. The same sheet reads out your actual distance from the
site and whether you currently count as present, which tells a missing GPS fix
apart from simply being too far away.

`-demo field` opens the sheet straight from a launch, and `-demoPresent` turns
the presence override on for a launch, and while it is on every screen it
unlocks carries a red **"Test mode — treated as present at the cemetery"** badge.
The locks are the argument of this product, so it must always be visible when one
has been stood down.

Note that the seeded coordinates are invented (see **Seed data**), so standing in
the real cemetery today will *not* unlock anything until the survey replaces them.


## From the mentor review

**Photographs.** A grave carries `photos: [GravePhoto]`, each one `headstone` or
`person`. They show as a strip on the grave screen and open full screen; the
arrival screen prefers the headstone shot. Bundled assets and photographs taken
on this device resolve through one `PhotoStore` — device ones are files in
Documents, so they survive a rebuild and never pass through a server. An empty
set draws **nothing**, not a placeholder: plenty of families have no photograph
of the person, and some would not want one shown, so absence must not read as a
gap. The survey screen takes the headstone shot and, separately, a portrait only
"bila keluarga menawarkan dan mengizinkan".

**Escalating haptics.** The field sheet's **Getaran** section exists so this can
be felt at a desk: a slider that pulses at one held distance, a rehearsal that
walks 80 m → 8 m in eighteen seconds and ends on the arrival tap, and the two
one-shot taps on their own buttons. It reads out the interval and intensity for
the distance it has reached, so the curve can be tuned by feel rather than by
arithmetic. Nothing of it is reachable without the long press.

`ApproachPulse` taps the phone on a timer whose period and
intensity both follow distance — about every 3 s and faint at 80 m, about three
times a second and firm at the 8 m handoff — then stops dead on arrival, where
buzzing at a graveside would be noise. It is a **pace**, not a measurement: the
accuracy line remains the honest number, and it still does not improve as you
approach (§7). Settings carries a toggle, since not everyone will want a phone
pulsing in a burial ground.

**Parentage.** `fatherName` plus `gender` render as "binti Sulaiman", "bin
Hamzah", or "putri dari Nyoman Kertia" where the Arabic form would not belong.
One field serves every case, the line is suppressed when the name on the stone
already carries it, and an unrecorded father or gender simply prints nothing.


## The pin and the hero are one object

A cemetery's pin is its own photograph, and tapping it opens the cemetery screen
with that same photograph as the hero. On iOS 18 and later the picture physically
flies from the pin into the header (`matchedTransitionSource` on the annotation,
`.navigationTransition(.zoom(sourceID:in:))` on the destination); below that it
is an ordinary push, so nothing breaks on iOS 17.

The idea is a **shared element transition**, and the reason it is worth the code
is **cognitive load** — specifically the *extraneous* load in Sweller's cognitive
load theory: effort spent working out what the interface just did, rather than on
the task. When one screen is replaced wholesale by another, the viewer has to
re-establish what they are looking at and confirm it is still the thing they
tapped. Carrying the photograph across answers that question before it is asked:
the Gestalt principle of **common fate** says two things that move together are
read as one thing, so the pin and the hero are understood as the same cemetery
rather than as two pictures that happen to look alike. Material Design calls this
*object constancy*; Apple frames it as preserving continuity. It also protects
against **change blindness** — when everything changes at once, people genuinely
fail to notice what stayed the same.

The rule that follows: the transition must carry the *same* image. A pin showing
a gate that opens onto a hero of a different corner of the cemetery is worse than
no animation, because it teaches that the movement means nothing.

Where there is no photograph the pin falls back to its glyph and the screen says
so plainly. That is the honest common case: Apple's map data has a name and a
coordinate for a village cemetery and never an image, so **the only photographs
that can ever exist here are ones somebody stood at the gate and took**. The
field sheet's *Cemetery photographs* section captures them; they live in
Documents on that phone, and the hero pages through them as a carousel with a
counter, any of which opens full screen.


## Records: bundle first, CloudKit second

`makamakam-web` writes `Cemetery` and `Grave` records to the CloudKit public
database, and `RemoteCatalog` reads them back. The ordering matters and is
deliberate:

1. **The bundled `graves.json` is the floor** and is never removed. Rural
   reception is unreliable and the product has to work with the radio off (§13).
2. **The last snapshot CloudKit gave us**, cached as JSON in Documents, is read
   at init — before any network call returns, and available on a plane.
3. **A fresh fetch** runs once per launch from `RootView`, on a background task
   nothing waits on.

A failed fetch is not an error state worth showing anybody: `refresh()` swallows
it, leaves the previous data exactly where it was, and only Settings mentions it
at all, for someone who went looking. An empty result is discarded rather than
applied — a misconfigured container must not be able to empty somebody's app in
the middle of a cemetery.

`verified` arrives as 0/1 because CloudKit has no boolean, and photographs travel
as a `photosJSON` string so one field carries the whole list. Settings shows when
the records were last refreshed, offers a manual check, and says plainly when the
build has no entitlement at all.

**Turning it on:** add the iCloud capability in Xcode (Signing & Capabilities →
+ Capability → iCloud → CloudKit → container `iCloud.me.babono.makamakam`) — the
entitlements file already names it, but only Xcode can create the container in
the account. Then fill it from the admin panel's *Isi dari survei* button, and
the next launch picks it up.


## The plan, after seeing the place

The gate photograph and the satellite view both said the same thing: this
cemetery has no rows. Markers sit where the ground allowed, around a tree, at
angles. `SectionPlan` drew a grid, which described a filing system rather than a
place, and a visitor cannot match a filing system to what is in front of them.

`SitePlan` draws the real spread. Three decisions hold it up:

**Offsets, not coordinates.** A grave's `x`/`y` are metres east and north of the
gate, from a tape measure. Relative positions are then right to the centimetre
and the whole plot shares one GPS error, instead of every grave carrying its own
3–5 m on top of the visitor's. That matters because the visitor is not matching a
pin to a grave — they are matching a *shape* to what they see, and a shape four
metres out is still unmistakably that shape. A grave with no offsets still plots,
projected from its coordinate.

**The wall is the strongest cue**, so the cemetery carries its corners and the
plan fills them in. When the survey runs, the perimeter is the thing to measure
carefully.

**The reader is a circle, not a dot** — sized to the actual horizontal accuracy.
It says the true thing: *you are somewhere in here, and so are these three
graves; now read the stones.*

Two mistakes worth not repeating. The plan first sized itself to include the
reader, so opening it from an office shrank the cemetery to a speck; the plot now
sets the bounds and a reader outside it is simply not drawn. And it first turned
with `rotationEffect`, which spills a rotated rectangle past its own frame — the
turn happens in the maths instead, so everything stays inside and nothing is
clipped.

**Full screen.** `PlanScreen` is the same drawing, pinchable to 8×, draggable,
double-tap to reset. Tapping a grave raises a card with the name, the parentage
and the plot, and a button into the grave itself — so the plan is a way *into*
the records rather than only a picture of them. It is reached from the cemetery
screen and from Orient.

Three things it got wrong first time, all found by using it:

- **It followed the compass by default**, so the drawing swung every time the
  phone turned. That is right on Orient, where you are walking and matching what
  you face; it is unreadable when you are browsing names. This screen now starts
  north-up, and following is a button.
- **Zoom stopped at 1×**, which meant the fitted plan could never be pulled back
  to see more around it. The range is now 0.6× to 8×.
- **Pan was unclamped**, so the plan could be flung off screen and the canvas
  simply vanished — which reads as a crash and is in fact an offset of two
  thousand points. It is now held within the frame plus a little slack, at
  whatever the current zoom allows.
- **Turning by hand was removed.** It earned nothing: people read this plan
  against the wall and the road, and a fixed north is what makes those readable.
  Grab and Gojek both lock rotation on their pick-a-location maps for the same
  reason. It also cost a great deal — the hand-turn is a *view* transform, so
  every tap had to be un-rotated before it could be tested, and the pan limit
  had to account for a rotated rectangle's extent.

  Following the compass stayed, because it is a different mechanism: that turn
  happens inside `SitePlan`'s own maths, so the positions a tap is tested
  against are already turned. No inverse, no clamp trouble. And it still earns
  its place on Orient, where you are walking and matching the drawing to what
  you face.
- **A gesture that did nothing still took the tap.** When the full screen began
  hit-testing for itself, `SitePlan`'s own tap was left attached and simply
  returned early — but a child's gesture wins over an ancestor's, so the
  parent's tap never fired and nothing could be selected. It is now switched
  *off* with a `GestureMask` rather than ignored.
- **The tap was tested in the drawing's own space**, while the drawing was
  being rotated, scaled and offset by its parent. SwiftUI hands the gesture the
  *untransformed* point, so the further the plan had been moved the further the
  tap landed from the grave that was under the finger. Hit-testing now happens
  where the gestures live, undoing the transforms — subtract the pan, divide by
  the zoom, turn back by the spin — and `SitePlan.layout(in:)` is shared between
  the drawing and the test, so the two can never disagree. The inverse is
  checked round-trip to 1e-13 points across zoom, spin and pan.
- **The pan limit was worked out from the zoom alone**, which stopped being
  right once the plan could also be turned. The rule is now simply that the
  middle of the plan stays on screen.
- **The gestures were attached to the drawing**, which slides and shrinks under
  pan and zoom. Once it moved away from where a finger landed, nothing responded
  and the screen had to be closed and reopened — a freeze that was really a
  hit-testing hole. Touches now belong to a `Color.clear` surface filling the
  frame; only the picture moves. The three gestures are also attached
  separately with `simultaneousGesture` rather than nested in one composition,
  and every one of them settles *all* the anchors on end, so a pinch that turns
  into a drag cannot leave one stale.

It is always **presented, never pushed**: it carries its own `NavigationStack`
so a tapped grave can be opened from inside it, and a stack inside a stack does
not push. The `-demo plan` argument therefore opens the cemetery screen and
raises the cover from there, which is the path a reader takes anyway.

**From a desk:** field sheet → *Posisi palsu* → **Taruh saya di gerbang** stands
you at the gate with a plausible accuracy, which is the only way to look at any
of this without being in Kuta.


## The wall

Visits, flowers and shared memories were three lists of the same thing: what has
happened at this grave. They are one timeline now, oldest first, beginning on the
day of the death — nothing can precede it.

**Nothing is ever counted.** A timeline says what happened; a total would say who
is winning, and §9 rules that out for exactly the reason two siblings would
discover within a week.

**Reading is open to anyone the family allows.** This is a deliberate departure
from §9, taken with the trade understood: it removes reading as a reason to
travel, in exchange for distant family being able to follow a grave they cannot
reach. Presence now protects two things only — **the check-in**, which is a claim
about being somewhere and must be true, and the prayers, which are for someone
standing there.

**The steward has two controls**, per §10: show or remove each post, and one
wall-wide setting — open, family only, or closed. Closed means closed, the family
included, because a family that does not want a wall must be able to say so.

**Private notes never touch the wall.** They are the 3am feeling with nowhere
else to go; the moment they could become content, they stop being that.

The profile is separate: Markdown, written by the family in the admin site where
a keyboard makes prose bearable, rendered here block by block
(`AttributedString(markdown:)` folds everything into one paragraph, so headings
and list items are split out first). Absence is ordinary — most graves will never
have one, and an empty page must not read as a family who could not be bothered.
