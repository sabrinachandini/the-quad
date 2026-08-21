# Aspen Grade Integration

The Quad integrates with the Follett Aspen X2/X3 student portal used by Lexington Public Schools to pull live grade data onto the student's device.

## How It Works

Aspen does not expose a public API. The integration is a **device-local authenticated web session** — the app logs into Aspen as the student, fetches HTML pages, and parses them. No server owned by The Quad ever sees credentials or grade data.

### Authentication Flow

1. Student enters their Aspen ID and password in `AspenConnectView`.
2. `AspenGradeProvider.connect(username:password:)` is called.
3. `AspenSession.authenticate(username:password:)` POSTs to `https://ma-lexington.myfollett.com/aspen/logon.do`.
4. On success (final URL is not `logon.do`), credentials are saved to the **device Keychain** via `AspenKeychainStore`.
5. Grade pages are fetched and parsed.

### Grade Fetch Flow

1. GET `/aspen/portalClassList.do` — lists all courses with current letter/percentage grades.
2. For each course: GET `/aspen/portalClassDetail.do?oid=<OID>` — fetches the category breakdown and individual assignment grades.
3. Results are cached in `UserDefaults` (JSON-encoded `[CourseGrade]`) under key `aspen.cached_grades`.

### Session Resume on Launch

`AppState.init()` calls `AspenGradeProvider.shared.tryResumeSession()` in a background Task. This:
1. Loads cached grades immediately so the UI has data.
2. Reads credentials from Keychain.
3. Re-authenticates (Aspen sessions expire — always re-auth).
4. Fetches fresh grades and updates the UI.

## Security Architecture

| Concern | Approach |
|---|---|
| Credential storage | iOS Keychain, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — never backed up to iCloud |
| Cookie isolation | `URLSessionConfiguration.ephemeral` with private `HTTPCookieStorage` — never shared with URLSession.shared |
| Grade data | JSON in `UserDefaults` — no credentials, no PII beyond what Aspen already shows |
| Server involvement | None. The Quad servers never receive credentials or grade data. |
| Disconnect | Keychain cleared immediately, session reset, UserDefaults cache removed |

## File Map

| File | Role |
|---|---|
| `Providers/AspenKeychainStore.swift` | Keychain CRUD for username + password |
| `Providers/AspenSession.swift` | URLSession actor — auth, cookie management, HTML fetch |
| `Providers/AspenHTMLParser.swift` | NSRegularExpression HTML parser — course list + detail |
| `Providers/AspenGradeProvider.swift` | @Observable provider — connection state, fetch orchestration, caching |
| `Features/Me/AspenConnectView.swift` | SwiftUI credential entry form |
| `Features/Me/MeView.swift` | Aspen row in Me tab — state-driven |

## Failure Modes

| Scenario | Behavior |
|---|---|
| Wrong password | `AspenConnectionState.failed("Invalid Aspen ID or password.")` |
| Session expired mid-session | `AspenConnectionState.sessionExpired` — prompts re-auth |
| Aspen server down | `AspenConnectionState.failed("Aspen is currently unavailable.")` — cached grades shown |
| HTML structure changed | `AspenParseError.structureChanged(description)` — fails closed, surfaces error |
| Keychain unavailable | Logged; session proceeds for this launch but credentials not persisted |
| No courses found | `AspenParseError.noCoursesFound` — surface to user |

## Testing Against Real LHS Aspen

The parser is tested against fixture HTML only. Before shipping, Sabrina needs to:

1. Build and run the app on a real device or simulator with network access.
2. In the Me tab, tap **Connect** on the Aspen Grades row.
3. Enter a real LHS Aspen student ID and password.
4. Observe: connection state should reach `.connected`, grades should populate in the Grade Summary.

### What to Check

- [ ] Login succeeds (no "Invalid login" error for valid credentials).
- [ ] Course list parses (courses appear in `AspenGradeProvider.shared.courses`).
- [ ] Course detail parses (categories and entries are non-empty for at least one course).
- [ ] Session resume on relaunch (kill and reopen the app — grades still show).
- [ ] Disconnect clears everything (tap Disconnect — Me row shows "Connect" again).

### If the Parser Fails

Aspen's HTML structure varies by district configuration and Aspen version. If `AspenParseError.structureChanged` is thrown:

1. Capture the raw HTML by temporarily logging it from `AspenSession.fetchHTML`.
2. Identify the actual table structure and update `AspenHTMLParser.findTableRange` and `parseCourseRow`.
3. The parser is designed to fail loudly rather than silently return garbage, which makes these issues easier to diagnose.

## Known Limitations

- **OID-to-course mapping**: The integration does not currently match Aspen OIDs to The Quad's Course model (which uses internal UUIDs from `MockStudentSchedule`). As a result, `CourseGrade.courseId` is a new UUID per sync rather than a stable ID. The grade screen shows courses from Aspen data, not matched to the schedule. This is a Phase 2 concern.
- **Grade categories**: Aspen category page structure varies. If categories don't parse, the provider returns an empty category list rather than erroring.
- **Rate limiting**: Aspen does not advertise rate limits. The integration fetches one course detail page per course per refresh. For a typical 7-course schedule, this is 8 HTTP requests per refresh.
