# The Quad — Decisions Log

Architectural decisions worth remembering. Append new decisions as they are made.

## D-001 — SwiftData over Core Data
**Decision:** Use SwiftData for local persistence.
**Why:** The iOS 17+ deployment floor unlocks the modern SwiftData API — far less boilerplate, native Swift value/model ergonomics, and good enough for a local-first app. Core Data's extra machinery isn't justified here.

## D-002 — Sign in with Apple as primary auth
**Decision:** Sign in with Apple is the primary authentication method; LPS Google OAuth is secondary.
**Why:** LPS Google OAuth may be blocked by school Workspace policy (Spike 1). Onboarding must never depend on a policy we don't control. Apple sign-in is reliable, private, and universally available.

## D-003 — Supabase for backend
**Decision:** Use a minimal Supabase backend for friend graph, directory, and ICS feed hosting.
**Why:** These are the only genuinely server-side features. Supabase is fast to stand up and keeps the backend thin; everything else stays on-device.

## D-004 — Provider adapter pattern (no direct coupling)
**Decision:** All external data (Classroom, Aspen) flows through protocol adapters; app logic never references a concrete provider.
**Why:** Enables graceful degradation — an unavailable integration swaps to a fallback provider and drops a tier instead of breaking. Also keeps engines/views testable and vendor-agnostic.

## D-005 — Deterministic planner first, AI later
**Decision:** Build the planner with deterministic priority scoring first; add AI enrichment only afterward.
**Why:** Inspectability over magic. Students (and we) must be able to see *why* the planner suggested something. Determinism is testable; a black box is not.

## D-006 — True black dark mode
**Decision:** Dark mode uses true black (`#000000`), not dark gray.
**Why:** Consumer-app aesthetic, great on OLED, and signals "this is not edtech." Dark mode is the default design target.
