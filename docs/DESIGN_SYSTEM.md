# The Quad — Design System

The Quad should feel like a first-party iOS app — calm, fast, native. No edtech chrome, no web-app flatness.

## Typography

- **System fonts only.** SF Pro Display for headings, SF Pro Text for body. Never bundle a custom font.
- Scale:
  - `quadTitle` — 34pt, bold (screen titles)
  - `quadHeadline` — 22pt, semibold (section/card headers)
  - `quadBody` — 17pt, regular (primary content)
  - `quadCaption` — 13pt, regular (metadata, labels)
- Respect Dynamic Type. Use `.rounded` design only where playful emphasis helps (e.g. countdowns), otherwise default.

## Color

- **Per-course accent colors** — 6+ distinct hues, each high-contrast in both light and dark mode. A course keeps its color everywhere (schedule, work, grades) for instant recognition.
- **Semantic tokens** (adaptive light/dark):
  - `background` — the canvas
  - `surface` — cards and raised containers
  - `primary` — primary text
  - `secondary` — secondary text
  - `accent` — brand indigo, used for interactive + the Ask button
  - `destructive` — errors and deletions

## Spacing — 4pt Grid

`xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48`

Everything aligns to the 4pt grid. No arbitrary padding.

## Corner Radii

`small 8 · medium 12 · large 16 · extraLarge 24`

Cards use `large` (16); prominent hero cards use `extraLarge` (24).

## Schedule Visual States

- **Upcoming** — full opacity, normal surface card.
- **Current** — accent border + subtle glow; visually lifted; the anchor of the screen.
- **Completed** — reduced opacity, receded, quiet. Done, but still visible for context.
- **Free block** — *open and airy*: no card background, generous whitespace, a light "Free" label. Free time should feel like breathing room, not another box.

## Motion

- **Spring animations.** Standard: `.spring(response: 0.3, dampingFraction: 0.8)`.
- Standard duration ≈ 0.3s.
- **Respect `reduceMotion`** — fall back to crossfades / no transform when the user has it on.

## Loading States

- **Skeleton shimmer** for primary content — never a spinner for the main view.
- Spinners are acceptable only for small, secondary, inline fetches.

## Empty States

- **Always informative, never blank.** Every empty state teaches or reassures.
  - Work, nothing due: "Nothing due — nice."
  - Grades, not connected: "Connect Aspen to see grades."
  - School, pre-Phase-7: "Coming in Phase 7."

## Dark Mode

- **True black (`#000000`)** background — not dark gray. This reads as a modern consumer app and looks great on OLED. Dark mode is the *default* aesthetic target.

## Haptics

- **Light** — navigation and selection.
- **Medium** — completing a task / turning something in.
- **Heavy** — errors and destructive confirmations.
