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

// MARK: - Session Actor

/// HTTP session actor scoped to the Aspen portal.
/// Uses a private cookie storage so cookies don't bleed into URLSession.shared.
actor AspenSession {
    static let shared = AspenSession()

    let baseURL = "https://ma-lexington.myfollett.com"

    private var session: URLSession
    private var isAuthenticated = false

    private init() {
        let config = URLSessionConfiguration.ephemeral
        // Private cookie storage — never shared with the rest of the app
        config.httpCookieStorage = HTTPCookieStorage()
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    func authenticate(username: String, password: String) async throws {
        isAuthenticated = false

        guard let url = URL(string: "\(baseURL)/aspen/logon.do") else {
            throw AspenSessionError.serverUnavailable
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
                         forHTTPHeaderField: "User-Agent")
        request.setValue(baseURL, forHTTPHeaderField: "Origin")
        request.setValue("\(baseURL)/aspen/logon.do", forHTTPHeaderField: "Referer")

        let body = "username=\(percentEncode(username))&password=\(percentEncode(password))&mobile=false"
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AspenSessionError.serverUnavailable
            }

            // Server error range
            if httpResponse.statusCode >= 500 {
                throw AspenSessionError.serverUnavailable
            }

            // Check final URL — if still on logon.do, auth failed
            let finalURL = httpResponse.url?.absoluteString ?? ""
            if finalURL.contains("logon.do") {
                // Also check body for error messages
                let body = String(data: data, encoding: .utf8) ?? ""
                if body.contains("Invalid login") ||
                   body.contains("user name or password") ||
                   body.contains("authentication failed") ||
                   AspenHTMLParser.isLoginPage(body) {
                    throw AspenSessionError.invalidCredentials
                }
                // Ambiguous redirect back to login — treat as invalid creds
                throw AspenSessionError.invalidCredentials
            }

            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 302 else {
                throw AspenSessionError.unexpectedResponse(httpResponse.statusCode)
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

            guard let html = String(data: data, encoding: .utf8) ??
                             String(data: data, encoding: .isoLatin1) else {
                throw AspenSessionError.unexpectedResponse(httpResponse.statusCode)
            }

            // Detect session expiry — redirected back to login
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
        // Rebuild session to clear all cookies
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
