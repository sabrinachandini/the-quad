# The LHS Schedule Model

This is the most important domain document in the repository. The Quad's entire reason to exist is being *correct* about the Lexington High School rotating schedule. Read it before touching any schedule code.

## The 6-Day Rotation

LHS runs a **6-day rotation**: Day 1, Day 2, Day 3, Day 4, Day 5, Day 6, then back to Day 1.

**Weekends and holidays do NOT advance the cycle.** If Friday is Day 4, and Monday is a school day, Monday is Day 5 — the weekend did not consume a rotation slot. Likewise a holiday in the middle of the week is skipped, not counted.

The rotation advances **only on days school is actually in session.**

## Academic Blocks

Courses live in blocks: **A, B, C, D, E, F, G, H, I**, plus **Homeroom** and the **Flex / I block**.

## The Key Insight

> **A block ≠ first period.**

The block *letter* identifies the *course* (e.g. "AP Chem is my A block"). The *time slot* that block meets **depends on the Day (1–6)**. The rotation shifts which block occupies which slot each day.

Example (reference, `reference_2025_26`):

| Slot | Day 1 | Day 2 | Day 3 | Day 4 | Day 5 | Day 6 |
|------|-------|-------|-------|-------|-------|-------|
| 1    | A     | B     | C     | D     | E     | F     |
| 2    | B     | C     | D     | E     | F     | A     |
| 3    | C     | D     | E     | F     | A     | B     |
| 4    | D     | E     | F     | A     | B     | C     |
| 5    | E     | F     | A     | B     | C     | D     |
| 6    | F     | A     | B     | C     | D     | E     |

So your A-block course meets 1st slot on Day 1, but 6th slot on Day 2, 5th slot on Day 3, and so on.

## Correct Mental Model

```
SchoolYear
  → CalendarDate (a specific date)
    → DayType (day1…day6, or a special day)
      → BellSchedule (ordered MeetingSlots for that day type)
        → MeetingSlot (a time slot bound to an AcademicBlock)
          → AcademicBlock (the course identity)
            → StudentCourse (this student's enrolled course in that block)
```

To answer "where am I now?": resolve today's `DayType`, get its `BellSchedule`, find the current `MeetingSlot`, read its `AcademicBlock`, look up the student's enrolled course for that block.

## Incorrect Mental Model (Do NOT Build This)

```
Day → Period 1 → Course      ❌ WRONG
```

There is no fixed "Period 1 course." Period 1 holds a *different block* every rotation day. Any code that assumes a stable period-to-course mapping is broken by design and will silently show students the wrong class.

## Reference Bell Times (`reference_2025_26`)

School runs roughly **7:55 AM – 2:20 PM**, **6 blocks per day**, with **Flex / I Block on certain days** and **lunch embedded** mid-day. Approximate reference times:

| Slot | Time |
|------|------|
| Period 1 | 7:55 – 8:50 |
| Period 2 | 8:55 – 9:50 |
| Period 3 | 9:55 – 10:50 |
| Lunch    | 10:55 – 11:25 |
| Period 4 | 11:30 – 12:25 |
| Period 5 | 12:30 – 1:25 |
| Period 6 | 1:30 – 2:20 |

55-minute periods, 5-minute passing, ~30-minute embedded lunch. **These are reference values, not authoritative.** Confirm with admin before treating as ground truth.

## Special Days

Support these explicitly, each with its **own template** — never derive them algorithmically from the standard day:

- **D1–D6** — the standard rotation.
- **No school** — not a school day; rotation does not advance.
- **Half days** — use an **explicit half-day template**. Do **not** "divide the full day by 2." Half-day bell times are their own thing.
- **Delayed openings** — explicit template with a later start.
- **Assemblies** — explicit template with a shortened/rearranged block set.
- **Exam schedules** — explicit exam-block template.

## Overrides

**Admin overrides trump the generated rotation, always.** If the generated rotation says Day 3 but an admin marked that date as an assembly, the assembly wins. Overrides are the highest-priority source.

## 2026-27 Warning

The **2026-27 date-to-DayType mappings are UNVERIFIED.** They must be **admin-editable** and are marked `isVerified = false` (`needs_verification`) until confirmed. Never hardcode 2026-27 rotation dates as if they were known.
