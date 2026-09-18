# Whiteboard: cognitive load — 5 minutes

**The question:** what did you learn about reducing cognitive load, and where is it
in the app, screen by screen?

---

## The frame (45 s) — draw this first

Draw one person, and around them write: **grief · bright sun · never been here ·
feels they have no right to ask.**

> "Cognitive load has three parts. Intrinsic is the task itself. Extraneous is
> what the design adds. Germane is the effort of actually learning.
>
> My user arrives with intrinsic load already at the ceiling — they are grieving,
> outdoors in the sun, in a place they have never been, doing something they are
> not sure they are entitled to do. Grief eats working memory. So I have almost no
> budget for extraneous load. Everything I removed, I removed for that reason."

Working memory holds about **four** things at once (Cowan, not Miller's 7±2).
That is the whole budget.

---

## The funnel (2½ min) — draw five boxes left to right

```
 FIND → CEMETERY → PICK → WALK → ARRIVE
  1        2         3      3      2
```

Write the number of things asked of the user under each box. That is the argument.

**1 · Find — one decision, not two.**
The search looks for *cemeteries*, not people. A single box promising to find any
name anywhere would be a bigger decision space and a promise the data cannot keep.
Pins are photographs of the gate: **recognition, not recall** — you know the place
when you see it, you cannot describe it.

**2 · Cemetery — match a shape, don't decode a code.**
The plan draws the real irregular spread from tape-measured offsets, so the visitor
matches a *shape* to what they see. The old version drew a tidy grid of rows and
plots: that is a filing system, and reading it means translating "Blok A, Baris 2"
into a place — pure extraneous load. Block and row are now optional labels shown on
one screen only.

**3 · Pick — three fields.**
The card that appears when you tap a grave carries **name, parentage, year of
death**. Nothing else. It answers exactly one question: *is this them?* Faith,
photographs, the wall and the profile all wait until after arrival. **Progressive
disclosure**: the right amount of information is the amount that answers the
question in front of you.

**4 · Walk — one arrow, one distance, one line.**
Three elements, and they shrink to two channels: the phone **pulses faster and
harder as you close in**, so the eyes can stay on the graves instead of the screen.
Moving information from the visual channel to touch frees the channel that is
doing the real work (Mayer's modality effect).
The arrow also *shrinks* as you get closer — the opposite of AirTag — because GPS
error stays fixed while distance falls, so confidence genuinely drops. An arrow
that grew would be most confident exactly where it is least trustworthy.

**5 · Arrive — the app stops talking.**
Below the handoff distance the numbers disappear and a photograph of the headstone
appears with one sentence of landmark. The hardest cognitive step — *is this the
one?* — is handed to the thing humans are best at, comparing two pictures.

---

## Two mistakes I made (45 s) — this is the part that shows learning

**Colour alone failed.** Green pin = surveyed, grey = not. A tester read green as
"near me". Colour is a weak channel carrying meaning on its own, so it now carries
a **different glyph** as well, and the legend describes it in the user's terms —
*"searchable down to a grave"* / *"only as far as the gate"* — not in mine
("surveyed"). **Redundant coding, and label by consequence rather than category.**

**I built two of something.** The wall had a check-in and a story as separate
posts with separate buttons, and before that there were three lists — visits,
flowers, memories. Every extra surface is a decision before you write a word.
Now: **one timeline, one composer**, and where the phone is decides what the post
becomes. I also deleted private notes entirely.
**The largest reduction in cognitive load I made was removing a feature, not
redesigning one.**

---

## The rule (15 s) — write it in the corner

> **One question per screen.**
> *Which cemetery? · Which grave? · Which way? · Is this them? · What do I say?*
>
> If a screen cannot be reduced to one question, it is two screens.

---

## If they ask

**"How do you know it worked?"** I don't, yet — it needs testing with the
caretaker and with two or three people from the outer circle. What I can show is
the counting: three lists became one, two composers became one, a private-note
feature was removed, and the confirmation card holds three fields. §17 of the PRD
lists what still has to be asked of real users.

**"Isn't hiding things also a cost?"** Yes — progressive disclosure trades recall
for navigation. The test I use: does the hidden thing answer the question *this*
screen asks? Faith does not help you decide "is this them", so it waits. The
landmark sentence does, so it stays.

**"What about accessibility?"** Same budget, harder: large type, high contrast for
sunlight and older eyes, a single accent colour used once so it means something,
and never colour alone.

**"Where do you still have too much?"** The grave screen has four doors and could
probably carry three. And the Settings screen is honest but long — it explains
iCloud, language, haptics and what the app refuses to do, which is a lot of reading
for a screen nobody came to read.
