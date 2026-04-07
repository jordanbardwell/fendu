#if canImport(FoundationModels)
import Foundation
import FoundationModels

@available(iOS 26, *)
@Generable
struct BudgetInsight {
    @Guide(description: "A short, conversational insight about the user's budget in 1-2 sentences")
    var text: String

    @Guide(description: "The sentiment: positive, warning, or neutral")
    var sentiment: InsightSentiment
}

@available(iOS 26, *)
@Generable
enum InsightSentiment: String {
    case positive
    case warning
    case neutral
}

@available(iOS 26, *)
@Observable @MainActor
final class InsightViewModel {

    var insight: BudgetInsight?
    var isLoading: Bool = false

    private var lastGeneratedPaycheckId: String?

    func generateIfNeeded(provider: BudgetDataProvider, currentPaycheckId: String) async {
        guard currentPaycheckId != lastGeneratedPaycheckId else { return }
        guard !isLoading else { return }

        // Check model availability
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return }

        isLoading = true

        let summary = provider.currentPaycheckSummary()
        let session = LanguageModelSession {
            "Generate a brief, helpful budget insight based on the data provided. Be conversational and encouraging."
        }

        do {
            let response = try await session.respond(
                to: "Here is the user's current budget data:\n\(summary)\n\nGenerate a short insight.",
                generating: BudgetInsight.self
            )
            insight = response.content
            lastGeneratedPaycheckId = currentPaycheckId
        } catch {
            // Insight is optional — silently fail
        }

        isLoading = false
    }

    func reset() {
        insight = nil
        lastGeneratedPaycheckId = nil
    }
}

#endif
