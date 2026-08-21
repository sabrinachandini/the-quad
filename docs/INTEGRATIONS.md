# The Quad — Integrations

Every integration goes through a provider adapter (see `docs/ARCHITECTURE.md`). Each can be absent without breaking the app.

## Google Classroom

- **Purpose:** import courses and coursework as `Assignment`s.
- **Auth:** OAuth 2.0.
- **Scopes:** `classroom.courses.readonly`, `classroom.coursework.me.readonly` (read-only, student's own work).
- **Risk (Spike 1):** LPS Google Workspace policy may block third-party apps from authorizing these scopes on managed student accounts. This is unresolved — see `docs/OPEN_QUESTIONS.md`.
- **Degradation:** if unavailable, Work falls back to `ManualAssignmentProvider`. The app stays fully usable at a lower tier.

## Aspen / SIS

- **Purpose:** import grades for the Grades tab and what-if engine.
- **Assumption:** **no public API.** We investigate a GradeKit-style approach (Spike 2).
- **Credentials:** MUST be stored in the **device-local Keychain**, never on a server. The Quad never sees or stores SIS credentials server-side.
- **Status:** Spike 2 — access mechanism unknown (session cookies vs. reverse-engineered endpoints). See `docs/OPEN_QUESTIONS.md`.
- **Degradation:** if unavailable, Grades shows the "Connect Aspen to see grades" empty state.

## Google Sign-In (Identity)

- **Purpose:** LPS identity, and the OAuth foundation Classroom would build on.
- **Relationship to auth:** secondary. **Sign in with Apple is the primary/fallback** auth so the app never depends on school policy to onboard.

## ICS Feed

- **Purpose:** a live per-user calendar feed of resolved schedule + assignments.
- **Behavior:** generate a stable feed URL per user; regenerate contents when the admin changes the calendar so subscribers stay in sync.
- **Hosting:** Supabase edge function vs. CloudKit — open question.

## WidgetKit + ActivityKit

- **WidgetKit** widget reads shared state from the **App Group** container (current/next class, rotation day).
- **ActivityKit** Live Activity (optional) for a current-class countdown.

## Push Notifications

- **APNs**, delivered via a minimal server or **CloudKit**, for friend-request / directory events.
- Local notifications (via `UNUserNotificationCenter`) handle schedule and due-date reminders without any server round-trip.
