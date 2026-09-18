# Makamakam

An iOS app for the people at the edge of a loss — the cousin, the school friend, the
neighbour — to find a grave they were never shown, tend it in their own tradition,
and leave the family a memory only they hold.

Built for the Apple Developer Academy challenge, against one real cemetery:
**Pemakaman Islam II, Lingkungan Desa Adat Kuta**, Tuban, Badung, Bali.

> **The rule the whole product follows:** words travel, acts don't. Prayers and
> stories can be read and written from anywhere. The check-in cannot, because it
> asserts presence and must therefore be earned.

---

## Running it

```
open makamakam.xcodeproj          # scheme: makamakam, iOS 17+
```

The Simulator has no compass and no real position, so two things help:

```bash
# stand inside the cemetery
xcrun simctl location booted set -8.729891,115.177190

# open straight onto a screen (DEBUG only)
xcrun simctl launch booted me.babono.makamakam -demo arrive
```

`-demo` takes `cemetery`, `plan`, `grave`, `orient`, `approach`, `arrive`, `tend`,
`wall`, `profile`, `saved`, `settings`, `field`. Others: `-demoLang id|en`,
`-demoGrave A-2-03`, `-demoMetres 60`, `-demoSearch "Kuta"`, `-demoPresent`.

**Command-line builds must sign, or opt out of CloudKit** — an unsigned binary has
no entitlements and `CKContainer(identifier:)` traps rather than failing politely:

```bash
xcodebuild -scheme makamakam -destination 'platform=iOS Simulator,name=iPhone 17' build \
  CODE_SIGNING_ALLOWED=NO OTHER_SWIFT_FLAGS='$(inherited) -D NO_CLOUDKIT'
```

**From a desk:** Settings → long-press the version number → *Posisi palsu* → **Taruh
saya di gerbang**. That field sheet also carries the survey capture, a haptics
rehearsal and a simulated walk.

## What's here

```
makamakam/
  Design/        palette, granite texture, the two type voices
  Localization/  Lang + every line of copy in Indonesian and English
  Models/        Grave, Site, Wall, and the SwiftData records
  Services/      geo maths, location, CloudKit sync, the survey store
  Features/
    Find/        the map, the cemetery, saved graves, a grave
    Guide/       the plan, orient, approach, arrive
    Tend/        prayers
    Gather/      the wall, the composer, the profile
    More/        settings and the hidden field mode
  Resources/     graves.json — the bundled survey
documentation/
  PRD.md                        what this is and why it is that way
  BUILD-NOTES.md                how it is built, and what was learned the hard way
  whiteboard-cognitive-load.md  a 5-minute talk about the design decisions
```

The admin site and the marketing pages live in a separate repository,
[`makamakam-web`](https://github.com/babono/makamakam-web): a Next.js app that edits
the CloudKit records, publishes the privacy policy, and exports `graves.json`.

## How it works

**Locate.** The search finds *cemeteries*, not people — there is no national register
of the dead behind this, and starting at the burial ground is honest. Inside one, a
`Canvas` draws the real irregular spread from tape-measured offsets, with the reader
as a circle sized to actual GPS accuracy rather than a confident dot. Then an arrow
that **shrinks** as it closes — inverting AirTag, because error stays fixed while
distance falls — handing over to a headstone photograph at a distance derived from
angular error rather than guessed.

**Tend.** Prayers in Arabic, transliteration and meaning, following the faith
recorded for the person buried there rather than the reader's own setting.

**Gather.** One wall per grave: visits, flowers and stories in the order they
happened, never counted. A post written at the graveside is marked as a visit;
presence is verified, never claimed. The family holds the wall and can close it —
and the grave stays findable regardless.

**Storage.** A bundled survey is the floor, so everything but sync works with the
radio off. CloudKit holds the shared records, and each person's saved graves live in
their own private database. Identity is the Apple ID already on the phone, so there
is no login screen — which is why the app explains where a post is going before the
first one.

## Before this is used for real

- **The 27 bundled graves are invented.** Plausible positions inside a boundary
  traced from satellite imagery, to exercise the app. They do not describe the dead.
- **The prayer text needs checking** with the caretaker or a local tokoh. Yāsīn
  carries only its opening, labelled as such.
- **Stewardship is not enforceable** by CloudKit; it needs the kelompok to vouch
  through the admin.
- The survey itself is unrun: `documentation/PRD.md` §14 is the method, §17 the
  questions still to ask.

## Licence

None yet. Ask before reusing the survey data or the prayer texts — the first belongs
to a community, and the second to a tradition.
