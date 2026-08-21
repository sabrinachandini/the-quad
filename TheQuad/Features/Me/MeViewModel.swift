import Foundation
import Observation

@Observable
final class MeViewModel {
    var displayName: String = "Alex Rivera"
    var gradeLevel: Int = 11
    var schoolYear: String = "2025-26"

    var integrations: [IntegrationConnection]
    var notifications: NotificationPreference

    init() {
        self.integrations = [
            IntegrationConnection(id: UUID(), provider: .googleClassroom, isConnected: false, connectedEmail: nil, keychainRef: nil, lastSyncedAt: nil),
            IntegrationConnection(id: UUID(), provider: .aspen, isConnected: false, connectedEmail: nil, keychainRef: nil, lastSyncedAt: nil)
        ]
        self.notifications = .default
    }

    func label(for provider: IntegrationProvider) -> String {
        switch provider {
        case .googleClassroom: return "Google Classroom"
        case .aspen: return "Aspen"
        case .googleIdentity: return "Google (LPS)"
        case .apple: return "Apple"
        }
    }
}
