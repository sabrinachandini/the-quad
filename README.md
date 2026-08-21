# The Quad

**Everything LHS.**

The Quad is a native iPhone "student OS" for **Lexington High School**. At any moment it answers the four questions a student actually has: *where do I need to be, what do I need to do, how am I doing,* and *when I'm free, who else is free.*

## What It Is

A single, fast, native app that unifies a student's day:

- The **LHS rotating 6-day schedule** (Day 1–Day 6), rendered for *today* and *tomorrow*.
- **Work** — assignments and tasks, from Google Classroom (when available) and manual entry.
- **Grades** — current standing and what-if projections (from Aspen when available).
- **School** — directory, classmates, and mutual-friend free-block overlap.
- **Me** — profile, integrations, and preferences.

It works at a **schedule-only tier** with zero external integrations, and gets richer as Classroom and Aspen connect.

## Primary Navigation

`Today` · `Work` · `Grades` · `School` · `Me` — plus a floating **Ask**.

## Platform

- **SwiftUI**, **iOS 17+**
- Local-first persistence via **SwiftData**
- Minimal Supabase backend for friend/directory/ICS features
- Sign in with Apple (primary); LPS Google (secondary, policy-permitting)

## How to Run

1. Open `TheQuad.xcodeproj` in Xcode 15 or later.
2. Select the **TheQuad** scheme and an iOS 17+ simulator.
3. Build & run (`⌘R`).

The app ships with reference LHS fixtures (`reference_2025_26`) and a mock student schedule, so it renders a real day immediately without any integration.

## Structure

```
the-quad/
├── docs/            Product & engineering docs (start with docs/PRD.md)
├── TheQuad/         The SwiftUI app
│   ├── Navigation/  Root tab shell
│   ├── Design/      Design tokens & course colors
│   ├── Models/      Domain models
│   ├── Engine/      Schedule / free-block / planner engines
│   ├── Providers/   Integration adapter protocols + concrete providers
│   ├── Fixtures/    Reference LHS data + mock student
│   ├── Features/    Today / Work / Grades / School / Me
│   └── Resources/   Assets
└── TheQuadTests/    Unit tests (schedule engine, free-block engine)
```

## Documentation

Start with **[docs/PRD.md](docs/PRD.md)**. See also `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, and `docs/LHS_SCHEDULE_MODEL.md`.
