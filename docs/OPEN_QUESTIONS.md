# The Quad — Open Questions

Unresolved questions that block or shape future work. Resolve into `docs/DECISIONS.md` as answers land.

## Q-1 — Classroom OAuth on managed accounts *(Spike 1)*
Can LPS-managed Google accounts authorize Google Classroom OAuth scopes for a third-party app, or does Workspace policy block it? This determines whether Phase 4 (Classroom) is viable at all. **Owner:** Spike 1.

## Q-2 — Aspen access mechanism *(Spike 2)*
How does a GradeKit-style approach actually access Aspen for Lexington specifically — session cookies? A reverse-engineered API? What's stable and permissible? Credentials must stay in device Keychain regardless. **Owner:** Spike 2.

## Q-3 — 2026-27 rotation dates
What are the exact 2026-27 Day-1 through Day-6 date assignments? Currently unknown and `needs_verification`. Must be **admin-editable**, never hardcoded. **Owner:** admin input.

## Q-4 — Free-block visibility default
Should free-block availability default to **friends-only** or a broader **classmates** scope? Leaning friends-only for privacy, but that reduces the "who else is free" value. **Owner:** product.

## Q-5 — Live Activities: signal or noise?
Is a current-class countdown Live Activity genuinely useful, or just clutter on the Lock Screen? Ship gated behind a preference and evaluate. **Owner:** product / Phase 8.

## Q-6 — ICS feed hosting
Host the per-user ICS feed on a **Supabase edge function** or **CloudKit**? Trade-offs in auth, cost, and update latency. **Owner:** Phase 8.

## Q-7 — Grade weighting rules
Does LHS use a standard weighted GPA, or custom weighting/rounding rules per course? The what-if engine must match reality exactly. **Owner:** admin input / Phase 5.

---

## Classroom OAuth Spike (Spike 1) — Status: In Progress

### What we know
- Required scopes: `classroom.courses.readonly`, `classroom.coursework.me.readonly`, `classroom.student-submissions.me.readonly`
- GoogleSignIn iOS SDK available via SPM: `github.com/google/GoogleSignIn-iOS`
- Classroom REST API is well-documented and stable

### Key risk
LPS uses Google Workspace for Education. School admins can restrict which OAuth apps students authorize. If LPS has set "Trusted apps only" policy, third-party apps cannot acquire Classroom scopes even with student consent.

### Investigation needed
- [ ] Test sign-in flow with an actual LHS student Google account
- [ ] Check if `classroom.coursework.me.readonly` scope is grantable
- [ ] If blocked: document the exact OAuth error returned
- [ ] Fallback path: manual assignment entry (already implemented)

---

## Aspen Spike (Spike 2) — Status: Not Started
- GradeKit approach: likely uses a WKWebView session to the Aspen web portal
- Credentials must stay on-device (Keychain only — never server-side)
- Need to reverse-engineer Aspen's web API endpoints for Lexington's instance
- Risk: Aspen web structure may change; brittle scraping approach
