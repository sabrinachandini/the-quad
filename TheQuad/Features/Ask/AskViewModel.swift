import Foundation
import Observation

@Observable
final class AskViewModel {
    struct Exchange: Identifiable {
        let id = UUID()
        let question: String
        let response: AskResponse
    }

    var exchanges: [Exchange] = []
    var inputText: String = ""
    var isThinking: Bool = false

    private let engine = AskEngine()

    func submit() {
        let q = inputText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        inputText = ""
        isThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            let response = self.engine.answer(q)
            self.exchanges.append(Exchange(question: q, response: response))
            self.isThinking = false
        }
    }

    func submitSuggestion(_ text: String) {
        inputText = text
        submit()
    }
}
