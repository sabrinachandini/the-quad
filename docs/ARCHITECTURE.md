# The Quad — Architecture

## Stack

- **Language / UI:** Swift, SwiftUI
- **Minimum OS:** iOS 17.0
- **Pattern:** MVVM-ish with a clean, framework-free **domain layer** (engines + models). Views are thin; view models orchestrate; engines are pure and testable.

## Layers

```
Views (SwiftUI)
  ↓ observe
ViewModels (@Observable)
  ↓ call
Domain Engines (ScheduleEngine, FreeBlockEngine, PlannerEngine)  ← pure, unit-tested
  ↓ read
Models (value types) + Providers (adapters)
  ↓ persist / fetch
SwiftData (local) + Supabase (friends/directory/ICS) + Integrations (Classroom/Aspen)
```

The domain engines have **no UIKit/SwiftUI dependency** and no I/O. They take models in and return models out, which makes them trivially testable.

## Persistence

- **Local-first with SwiftData.** Courses, enrollments, tasks, cached assignments, grades, calendar dates, and bell schedules live on-device.
- SwiftData chosen over Core Data because the iOS 17+ floor lets us use the modern, less-boilerplate API (see `docs/DECISIONS.md`).

## Provider Adapter Pattern

All external data flows through protocols so app logic never couples to a vendor:

| Protocol | Concrete implementations |
|---|---|
| `AssignmentProvider` | `ClassroomAssignmentProvider`, `ManualAssignmentProvider` |
| `GradeProvider` | `AspenGradeProvider` |
| `ScheduleSource` | `UploadedScheduleSource` |
| `CalendarProvider` | `AdminCalendarSource` |

A provider being unavailable (e.g. Classroom blocked by LPS policy) degrades gracefully: the app falls back to the manual provider and the tier drops, but nothing breaks.

## Data Provenance

Every model that can originate from multiple sources carries a `DataProvenance`:

```
enum DataProvenance { case classroom, aspen, student, parsedSchedule, admin, inferred }
```

Provenance drives trust, conflict resolution, and UI labeling (e.g. "from Classroom", "you added this"). Admin data trumps inferred data; student edits trump parsed data.

## ICS Generation (First-Class Output)

The Quad generates a live **ICS calendar feed** per user from the resolved schedule + assignments. This is a first-class output, not an afterthought: students subscribe once and their system calendar stays in sync. The feed updates when the admin changes the calendar.

## Notifications

- Built on **UNUserNotificationCenter**.
- Local notifications for class-change reminders and assignment due dates, scheduled from the resolved schedule.
- Server/CloudKit push reserved for friend-request and directory events.

## Widgets

- **WidgetKit** extension reads shared state from an **App Group** container.
- Shows current/next class and today's rotation day.

## Live Activities (Optional)

- **ActivityKit**, optional, for a current-class countdown on the Lock Screen / Dynamic Island.
- Gated behind a preference; see `docs/OPEN_QUESTIONS.md` on whether it's signal or noise.

## Backend

- **Minimal Supabase** for the features that genuinely need a server: friend graph, directory, and ICS feed hosting.
- Everything else is on-device. The backend is deliberately thin.

## Auth

- **Sign in with Apple** — primary. Reliable, privacy-preserving, not subject to school policy.
- **LPS Google OAuth** — secondary, for LPS identity and (potentially) Classroom. May be blocked by school Workspace policy; treated as best-effort.

## Cross-Cutting

- **Structured logging** — a small logging facade emitting structured events (category + level + fields), not `print`.
- **Dependency injection** — engines and providers injected via SwiftUI `Environment` or explicit initializer injection. No global singletons for domain logic.
