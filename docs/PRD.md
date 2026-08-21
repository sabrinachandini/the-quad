# The Quad — Product Requirements Document

## Product Thesis

At any moment, The Quad answers a student's four real questions:

1. **Where do I need to be?** — the LHS rotating schedule, resolved for right now.
2. **What do I need to do?** — assignments and tasks, prioritized.
3. **How am I doing?** — grades and what-if projections.
4. **When I'm free, who else is free?** — free-block detection and mutual-friend overlap.

The Quad is built **specifically for Lexington High School**, not as generic edtech. Its correctness about *this school's* schedule, blocks, and rhythms is the entire point. If a generic scheduling app could do it, we have failed.

## Product Shape

**Five tabs plus a floating Ask:**

- **Today** — the anchor. What's now, what's next, the full rotating day, free blocks.
- **Work** — assignments and student tasks, grouped and prioritized.
- **Grades** — course standing, categories, what-if projections.
- **School** — directory, classmates, mutual friends, free-block overlap.
- **Me** — profile, integrations, notifications, school-year selection.
- **Ask** (floating) — natural-language questions grounded in the student's own structured data.

### Time-Awareness

The app reads the clock and biases its emphasis:

- **Morning / during school:** Today is emphasized — current class, time remaining, what's next.
- **Evening:** Tomorrow is emphasized — tomorrow's rotation day, what's due, what to prep.

## Graceful Degradation Tiers

The Quad delivers value at every tier and never hard-fails when an integration is absent:

1. **Schedule-only** (no accounts) — full rotating schedule, free blocks, manual tasks. This tier alone is a shippable product.
2. **+ Google Classroom** — real assignments and coursework flow in automatically.
3. **+ Aspen** — real grades and what-if projections.
4. **Full intelligence** — Ask, planner allocation across free blocks, syllabus grounding.

Higher tiers *enrich*; lower tiers *stand alone*.

## User Stories

### Schedule View
- *As a student,* I open the app and immediately see today's rotation day (e.g. "Day 3") and my current class with a live countdown, so I know exactly where to be.
- *As a student,* I scroll the full day and see every block in its correct Day-3 time slot, with free blocks shown as open, airy space.

### Free Block Detection
- *As a student,* I see my free blocks for today computed automatically from the bell schedule minus my enrolled courses — I never enter them manually.

### Friend Overlap
- *As a student,* when I have a free block, I can see which of my mutual friends are also free at the same time.

### Assignment Tracking
- *As a student,* I see everything due, grouped by day, pulled from Classroom when connected and entered by hand otherwise.
- *As a student,* I can add a manual task (e.g. "study for chem quiz") with a due date and estimated minutes.

### Grade What-If
- *As a student,* I can see my current grade per course and ask "what if I get a 90 on the next test?" and see the projected result.

### Notifications
- *As a student,* I get a notification before my next class and before assignments are due, on my terms.

### Widgets
- *As a student,* my home screen widget shows my current/next class without opening the app.

## Success Metrics

- **60-second onboarding** — from install to a correct, personalized Today view in under a minute.
- **Schedule accuracy** — 100% correct block-to-time-slot resolution across all six rotation days and special days.
- **Daily active use** — students open Today most school mornings; it becomes a habit.
- **Degradation resilience** — a schedule-only user reports the app as "useful" without any integration.

## Non-Goals (Explicitly Out of Scope)

- **No parent accounts.** This is a student app.
- **No teacher tools.** We do not build gradebooks or class management.
- **No social feed.** No posts, no timelines, no likes.
- **No DMs.** No in-app messaging.
- **No location tracking.** We never track or share a student's physical location.

Free-block *availability* is shared (opt-in, mutual-friends-only) — but never location.
