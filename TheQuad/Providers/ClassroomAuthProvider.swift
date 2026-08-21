import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

enum ClassroomAuthState: Equatable {
    case notConfigured
    case disconnected
    case connecting
    case connected(email: String, lastSync: Date)
    case needsReauthorization
    case blockedBySchoolPolicy
    case failed(String)
}

@Observable
final class ClassroomAuthProvider: NSObject {
    static let shared = ClassroomAuthProvider()

    var authState: ClassroomAuthState = .disconnected
    var connectedEmail: String?

    private var currentSession: ASWebAuthenticationSession?

    override private init() {
        super.init()
    }

    // MARK: - Public API

    func connect(from viewController: UIViewController) async {
        guard let clientID = GoogleConfig.clientID,
              let reversedClientID = GoogleConfig.reversedClientID else {
            authState = .notConfigured
            return
        }

        authState = .connecting

        // Generate PKCE
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        // Build auth URL
        var components = URLComponents(string: GoogleConfig.authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: reversedClientID + GoogleConfig.redirectURISuffix),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: GoogleConfig.scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        guard let authURL = components.url else {
            authState = .failed("Could not build authorization URL")
            return
        }

        let callbackScheme = reversedClientID
        do {
            let callbackURL = try await presentAuthSession(url: authURL, callbackScheme: callbackScheme)
            guard let callbackComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
                authState = .failed("Invalid callback URL")
                return
            }

            // Check for access_denied (school policy block)
            if let error = callbackComponents.queryItems?.first(where: { $0.name == "error" })?.value {
                if error == "access_denied" {
                    authState = .blockedBySchoolPolicy
                    return
                }
                let errorDesc = callbackComponents.queryItems?.first(where: { $0.name == "error_description" })?.value ?? error
                if errorDesc.lowercased().contains("admin_policy") || errorDesc.lowercased().contains("admin policy") {
                    authState = .blockedBySchoolPolicy
                    return
                }
                authState = .failed(errorDesc)
                return
            }

            guard let code = callbackComponents.queryItems?.first(where: { $0.name == "code" })?.value else {
                authState = .failed("No authorization code in callback")
                return
            }

            // Exchange code for tokens
            let tokenResponse = try await exchangeCode(code, codeVerifier: codeVerifier, clientID: clientID, reversedClientID: reversedClientID)
            let email = extractEmail(from: tokenResponse.idToken)
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn ?? 3600))

            try ClassroomTokenStore.shared.save(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken,
                expiresAt: expiresAt
            )

            connectedEmail = email
            authState = .connected(email: email ?? "LHS Student", lastSync: Date())
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // LPS Workspace admin-block shows a "This app is blocked" page and never
            // redirects back — the user closes the browser, which looks like a cancel.
            // Treat as blockedBySchoolPolicy so the user gets a meaningful next step.
            authState = .blockedBySchoolPolicy
        } catch {
            authState = .failed(error.localizedDescription)
        }
    }

    func refresh() async {
        guard let refreshToken = try? ClassroomTokenStore.shared.loadRefreshToken(),
              let clientID = GoogleConfig.clientID else {
            authState = .needsReauthorization
            return
        }

        do {
            let tokenResponse = try await refreshAccessToken(refreshToken: refreshToken, clientID: clientID)
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn ?? 3600))
            try ClassroomTokenStore.shared.save(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken ?? refreshToken,
                expiresAt: expiresAt
            )
        } catch {
            authState = .needsReauthorization
        }
    }

    func disconnect() {
        try? ClassroomTokenStore.shared.delete()
        connectedEmail = nil
        authState = .disconnected
    }

    func tryResumeSession() async {
        guard GoogleConfig.clientID != nil else {
            authState = .notConfigured
            return
        }

        guard let accessToken = try? ClassroomTokenStore.shared.loadAccessToken(),
              !accessToken.isEmpty else {
            authState = .disconnected
            return
        }

        // Check expiry
        if let expiry = try? ClassroomTokenStore.shared.loadExpiry(), expiry < Date() {
            await refresh()
            return
        }

        // Attempt to restore email from stored token
        let email = connectedEmail ?? "LHS Student"
        authState = .connected(email: email, lastSync: Date())
    }

    // MARK: - Private helpers

    private func presentAuthSession(url: URL, callbackScheme: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = callbackURL {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: ClassroomAuthError.noCallback)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.currentSession = session
            session.start()
        }
    }

    private func exchangeCode(_ code: String, codeVerifier: String, clientID: String, reversedClientID: String) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: GoogleConfig.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "code": code,
            "client_id": clientID,
            "redirect_uri": reversedClientID + GoogleConfig.redirectURISuffix,
            "grant_type": "authorization_code",
            "code_verifier": codeVerifier
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func refreshAccessToken(refreshToken: String, clientID: String) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: GoogleConfig.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "refresh_token": refreshToken,
            "client_id": clientID,
            "grant_type": "refresh_token"
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func extractEmail(from idToken: String?) -> String? {
        guard let idToken = idToken else { return nil }
        let segments = idToken.components(separatedBy: ".")
        guard segments.count >= 2 else { return nil }
        var base64 = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["email"] as? String
    }

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension ClassroomAuthProvider: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Supporting types
private struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let expiresIn: Int?
    let tokenType: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

enum ClassroomAuthError: Error {
    case noCallback
    case noCode
}
