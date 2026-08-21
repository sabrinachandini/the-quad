# The Quad — Implementation Plan

Phased delivery. Each phase is independently valuable and preserves graceful degradation.

## Phase 0 — Foundation *(CURRENT)*

Repo, SwiftUI shell, five-tab navigation, floating Ask, domain models, local persistence, design tokens, mock LHS data, reference fixtures. The app builds, renders a real Today from fixtures, and is ready to grow.

**Exit:** app runs, five tabs navigate, Today renders the mock student's day from reference fixtures.

## Phase 1 — Schedule Engine

The D1–D6 engine: bell schedules, special days (half day, delayed opening, assembly, exam), admin overrides, and free-block computation. Today/Tomorrow views wired to the engine. **Strong unit tests** across all six rotation days, holidays, overrides, half days, and free blocks.

**Exit:** engine resolves any date to the correct blocks and times; tests cover every rotation day + special day + override.

## Phase 2 — Schedule Import

Screenshot / PDF schedule parsing → confirmation UI → manual correction. The student's real schedule enters the system. Fixture-based parser tests.

**Exit:** a student can import their schedule from an image and correct any parse errors.

## Phase 3 — Work

Manual tasks, the Work UI, due dates, statuses, and the foundation for the planner. No integration required — this is the manual tier of Work.

**Exit:** a student can add, edit, complete, and view tasks grouped by due date.

## Phase 4 — Google Classroom

OAuth spike (Spike 1), the provider abstraction in practice, course + coursework import, and **graceful failure** if LPS policy blocks the scopes.

**Exit:** Classroom assignments flow in when permitted; the app degrades cleanly when not.

## Phase 5 — Grades

Grade domain model, the **what-if engine**, an Aspen access spike (Spike 2), and a polished GradeKit-equivalent UX.

**Exit:** current grades display; what-if projections compute; Aspen path investigated.

## Phase 6 — Planner

Deterministic priority scoring, free-time allocation across detected free blocks, integrated into Today.

**Exit:** the planner suggests what to do in each free block, transparently and deterministically.

## Phase 7 — Directory / Friends / Free Overlap

Student directory, classmates, **mutual** friendships, privacy controls, and availability intersection (shared free blocks).

**Exit:** mutual friends can see overlapping free blocks; no location, opt-in only.

## Phase 8 — Outputs

Notifications (class-change + due dates), WidgetKit widget, optional Live Activities, and the live ICS feed.

**Exit:** notifications fire, the widget shows current/next class, ICS subscription works.

## Phase 9 — Intelligence

Ask — natural-language questions grounded in the student's structured data — plus syllabus parsing.

**Exit:** Ask answers real questions from the student's own schedule/work/grades, grounded and inspectable.
