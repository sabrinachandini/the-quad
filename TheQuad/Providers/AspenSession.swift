import Foundation

// MARK: - Errors

enum AspenSessionError: Error, LocalizedError {
    case invalidCredentials
    case sessionExpired
    case networkError(Error)
    case unexpectedResponse(Int)
    case serverUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid Aspen ID or password."
        case .sessionExpired:
            return "Your Aspen session expired. Please sign in again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unexpectedResponse(let code):
            return "Unexpected response from Aspen (HTTP \(code))."
        case .serverUnavailable:
            return "Aspen is currently unavailable. Try again later."
        }
    }
}

// MARK: - Auth Response

private struct AspenAuthResponse: Decodable {
    let csrfToken: String?
    let aspenUrl: String?
    let authToken: String?
    let code: Int?
    let message: String?
}

// MARK: - Session Actor

/// HTTP session actor scoped to the Aspen portal.
/// Uses a private cookie storage so cookies don't bleed into URLSession.shared.
actor AspenSession {
    static let shared = AspenSession()

    let baseURL = "https://ma-lexington.myfollett.com"
    private let deploymentID = "ma-lexington"

    private var session: URLSession
    private var isAuthenticated = false

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = HTTPCookieStorage()
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Authenticates against Aspen's new Angular SPA login system.
    ///
    /// Flow:
    ///   1. POST /app/rest/auth (username + password body, deploymentId header)
    ///   2. On success, parse JSON response for aspenUrl
    ///   3. GET aspenUrl to establish the classic /aspen/ session cookie
    func authenticate(username: String, password: String) async throws {
        isAuthenticated = false

        // Step 1 — authenticate with the REST auth endpoint
        guard let authURL = URL(string: "\(baseURL)/app/rest/auth") else {
            throw AspenSessionError.serverUnavailable
        }

        var authRequest = URLRequest(url: authURL)
        authRequest.httpMethod = "POST"
        authRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        authRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        authRequest.setValue(deploymentID, forHTTPHeaderField: "deploymentId")
        authRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
                             forHTTPHeaderField: "User-Agent")

        // password must be URL-encoded per the Angular client
        let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? password
        let body = "username=\(percentEncode(username))&password=\(encodedPassword)"
        authRequest.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await session.data(for: authRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AspenSessionError.serverUnavailable
            }

            if httpResponse.statusCode >= 500 {
                throw AspenSessionError.serverUnavailable
            }

            if httpResponse.statusCode == 401 {
                throw AspenSessionError.invalidCredentials
            }

            guard httpResponse.statusCode == 200 else {
                // Try to parse error message from JSON before throwing
                if let parsed = try? JSONDecoder().decode(AspenAuthResponse.self, from: data),
                   let msg = parsed.message?.lowercased(),
                   (msg.contains("invalid") || msg.contains("password") || msg.contains("username")) {
                    throw AspenSessionError.invalidCredentials
                }
                throw AspenSessionError.unexpectedResponse(httpResponse.statusCode)
            }

            // Step 2 — parse auth response
            let authResp = try? JSONDecoder().decode(AspenAuthResponse.self, from: data)

            // Step 3 — if there's an aspenUrl, follow it to bridge into the classic /aspen/ session
            if let aspenUrlString = authResp?.aspenUrl,
               let bridgeURL = URL(string: aspenUrlString.hasPrefix("http") ? aspenUrlString : "\(baseURL)\(aspenUrlString)") {
                var bridgeRequest = URLRequest(url: bridgeURL)
                bridgeRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
                                       forHTTPHeaderField: "User-Agent")
                _ = try? await session.data(for: bridgeRequest)
            }

            isAuthenticated = true

        } catch let error as AspenSessionError {
            throw error
        } catch {
            throw AspenSessionError.networkError(error)
        }
    }

    func fetchHTML(path: String, queryItems: [URLQueryItem] = []) async throws -> String {
        guard isAuthenticated else {
            throw AspenSessionError.sessionExpired
        }

        var components = URLComponents(string: "\(baseURL)\(path)")
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw AspenSessionError.serverUnavailable
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
                         forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AspenSessionError.serverUnavailable
            }

            if httpResponse.statusCode >= 500 {
                throw AspenSessionError.serverUnavailable
            }

            if httpResponse.statusCode == 401 {
                isAuthenticated = false
                throw AspenSessionError.sessionExpired
            }

            guard let html = String(data: data, encoding: .utf8) ??
                             String(data: data, encoding: .isoLatin1) else {
                throw AspenSessionError.unexpectedResponse(httpResponse.statusCode)
            }

            if AspenHTMLParser.isLoginPage(html) {
                isAuthenticated = false
                throw AspenSessionError.sessionExpired
            }

            if AspenHTMLParser.isErrorPage(html) {
                throw AspenSessionError.unexpectedResponse(httpResponse.statusCode)
            }

            return html

        } catch let error as AspenSessionError {
            throw error
        } catch {
            throw AspenSessionError.networkError(error)
        }
    }

    func logout() async {
        _ = try? await fetchHTML(path: "/aspen/logout.do")
        reset()
    }

    func reset() {
        isAuthenticated = false
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = HTTPCookieStorage()
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    // MARK: - Helpers

    private func percentEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
}
