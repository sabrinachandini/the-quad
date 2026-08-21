# Google Classroom Integration

## Status

| Component | Status |
|---|---|
| OAuth 2.0 flow (ASWebAuthenticationSession) | IMPLEMENTED |
| Token storage (iOS Keychain) | IMPLEMENTED |
| Classroom REST API client | IMPLEMENTED |
| Assignment normalization | IMPLEMENTED |
| Blocked-by-school-policy handling | IMPLEMENTED |
| Google Cloud project configured | NOT YET — human step required |
| Tested against real LHS Classroom | NOT YET |

## Human Steps Required

A Google Cloud project must be created to get an OAuth client ID.
Without this, the integration shows "Setup Required."

### Step-by-step setup

1. Go to https://console.cloud.google.com
2. Click "Select a project" → "New Project"
   - Project name: `The Quad`
   - Click Create
3. In the left sidebar: APIs & Services → Library
4. Search for "Google Classroom API" → click it → click Enable
5. APIs & Services → Credentials → Create Credentials → OAuth client ID
6. If prompted to configure consent screen:
   - User type: External
   - App name: The Quad
   - User support email: your email
   - Developer contact: your email
   - Click Save and Continue (skip Scopes and Test users for now)
7. Back in Create OAuth client ID:
   - Application type: iOS
   - Name: The Quad iOS
   - Bundle ID: com.thequad.app
   - Click Create
8. Copy the Client ID — it looks like: `123456789-abcdef.apps.googleusercontent.com`
9. The Reversed Client ID is the Client ID reversed by segments: `com.googleusercontent.apps.123456789-abcdef`

### Configure The Quad

1. Create file at `TheQuad/Config/GoogleService.plist` (copy from `GoogleService.plist.template`)
2. Replace `REPLACE_WITH_YOUR_GOOGLE_OAUTH_CLIENT_ID` with your Client ID
3. Replace `REPLACE_WITH_YOUR_REVERSED_CLIENT_ID` with the Reversed Client ID
4. In `TheQuad/Info.plist`, replace `REPLACE_WITH_REVERSED_CLIENT_ID` with the Reversed Client ID
5. Run `xcodegen generate` and rebuild

### What happens if LPS blocks it

If Lexington Public Schools has set a Google Workspace policy that restricts which third-party apps
can access student accounts, the OAuth flow will return `access_denied`.

The app handles this gracefully — it shows "School Account Restriction" with instructions
to use manual assignment entry instead.

To check: ask LPS IT or go to myaccount.google.com → Security → Third-party apps with account access
while signed in with the LPS student account.

## Architecture

```
Student → ASWebAuthenticationSession → Google OAuth → LPS Workspace → tokens
Tokens → iOS Keychain → ClassroomAuthProvider
ClassroomAuthProvider → ClassroomAssignmentProvider → Classroom REST API → [Assignment]
```

## Key files

| File | Purpose |
|---|---|
| `TheQuad/Config/GoogleConfig.swift` | Central config: endpoints, scopes, reads from GoogleService.plist |
| `TheQuad/Config/GoogleService.plist.template` | Template — copy to GoogleService.plist and fill in credentials |
| `TheQuad/Providers/ClassroomTokenStore.swift` | iOS Keychain token persistence |
| `TheQuad/Providers/ClassroomAuthProvider.swift` | OAuth 2.0 + PKCE flow, session resume, token refresh |
| `TheQuad/Providers/ClassroomAssignmentProvider.swift` | REST API calls, Assignment normalization |
| `TheQuad/Features/Me/ClassroomConnectView.swift` | Connect/disconnect UI sheet |

## Security

- OAuth tokens stored in iOS Keychain (device-local, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`)
- PKCE used (S256) — protects against auth code interception
- No Google password ever collected
- Tokens never logged or sent to The Quad servers
- Refresh token used to renew access without re-prompting user
- `GoogleService.plist` is in `.gitignore` — credentials never committed to source control
