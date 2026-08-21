# AGENTS.md — Instructions for AI Coding Agents

This file governs how AI coding agents work in **The Quad** repository. Read it fully before making any non-trivial change.

## Required Reading Before Significant Changes

Before making any significant change, **always read these documents first**:

1. `docs/PRD.md` — the product requirements. What we are building and why.
2. `docs/ARCHITECTURE.md` — the technical shape of the app.
3. `docs/DATA_MODEL.md` — the canonical entity definitions.

If your change touches the schedule, also read `docs/LHS_SCHEDULE_MODEL.md`.

## Non-Negotiable Principles

- **Optimize specifically for Lexington High School.** Never generalize away LHS-specific behavior in the name of "reusability." LHS specificity is a *feature*, not tech debt. If a change would make the app more generic and less correct for LHS, do not make it.
- **Never invent school facts.** Bell times, room numbers, course data, and calendar date-to-DayType mappings must come from fixtures (`reference_2025_26`) or admin-provided data. If you do not have a real value, mark it `needs_verification` — do not fabricate a plausible-looking one.
- **Preserve graceful degradation.** The app must work at the *schedule-only* tier with no Google Classroom and no Aspen connection. Never introduce a hard dependency on an external integration for a core flow.
- **Build to native iOS quality.** No web wrappers, no WebViews for primary content, no edtech visual language. This is a consumer-grade native iOS app. It should feel like it belongs next to Apple's own apps.
- **All external integrations go through provider adapters.** Google Classroom and Aspen must be reached only through the `AssignmentProvider` / `GradeProvider` / `ScheduleSource` / `CalendarProvider` protocols. Never couple app logic (view models, engines, views) directly to a concrete provider.
- **The schedule engine must have strong unit tests.** Any change to `ScheduleEngine` or `FreeBlockEngine` must keep tests green and add tests for new behavior. Cover all 6 rotation days, holidays, half days, delayed openings, admin overrides, and free-block computation.

## Data Provenance & Verification

- Mark all 2025-26 reference fixtures clearly as `reference_2025_26` in code comments and in the `isVerified` flag.
- Mark all 2026-27 date mappings as `needs_verification` (`isVerified = false`). These are placeholders until an admin confirms them.
- Every piece of data carries a `DataProvenance`. Respect it. Do not silently promote `.inferred` data to `.admin`.

## Process

- **Prefer implementation over planning.** This scaffold exists so agents can build. Write real code.
- **Update `docs/DECISIONS.md`** whenever you make an architectural choice worth remembering.
- **Do not silently simplify product requirements.** If a requirement seems hard or over-specified, implement it as written or raise it explicitly in `docs/OPEN_QUESTIONS.md`. Do not quietly cut scope.

## Quick Orientation

- App target source: `TheQuad/`
- Tests: `TheQuadTests/`
- Docs: `docs/`
- Reference LHS data: `TheQuad/Fixtures/LHSFixtures_2025_26.swift`
- Mock student for dev: `TheQuad/Fixtures/MockStudentSchedule.swift`
