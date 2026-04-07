#if canImport(FoundationModels)
import Foundation
import FoundationModels

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var text: String
    let timestamp: Date

    enum Role { case user, assistant }
}

@available(iOS 26, *)
@Observable @MainActor
final class ChatViewModel {

    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isGenerating: Bool = false
    var errorMessage: String?
    var modelAvailability: ModelAvailability = .checking
    var shouldResetSession: Bool = false

    enum ModelAvailability {
        case checking
        case available
        case unavailable(String)
    }

    private var session: LanguageModelSession?
    private var dataProvider: BudgetDataProvider?
    private var messageCountSinceReset: Int = 0

    private static let systemPrompt = """
    You are Fendu's budget assistant. You ONLY answer questions about the user's budget data. \
    Use the provided tools to look up budget data — never guess numbers. \
    If a question is not about their budget, spending, bills, accounts, or paychecks, reply: \
    "I can only help with questions about your budget. Try asking about your spending, bills, or accounts!" \
    Never make up facts, product descriptions, or general knowledge answers. \
    All amounts are USD. Keep answers brief but clear. Be encouraging but honest about overspending. \
    Reference actual account names and dollar amounts from the tools. \
    "Spending" means transactions/allocations (getTransactions), NOT recurring bills (getBillSchedule). \
    Only include bills if the user specifically asks about bills. \
    When listing bills, ALWAYS list every single bill from the tool — never summarize or pick just one. \
    When comparing paychecks, reference the paycheck period dates — never use today's date. \
    Format responses with **bold** for account names, bill names, and labels. \
    Use line breaks to separate each item in lists — never run items together in a paragraph.
    """

    // MARK: - Setup

    func checkAvailability() {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            modelAvailability = .available
        case .unavailable(.appleIntelligenceNotEnabled):
            modelAvailability = .unavailable("Enable Apple Intelligence in Settings to use AI Chat.")
        case .unavailable(.deviceNotEligible):
            modelAvailability = .unavailable("AI Chat requires iPhone 15 Pro or newer.")
        case .unavailable(.modelNotReady):
            modelAvailability = .unavailable("The AI model is still downloading. Please try again later.")
        default:
            modelAvailability = .unavailable("AI Chat is not available on this device.")
        }
    }

    func configure(with provider: BudgetDataProvider) {
        self.dataProvider = provider
        createSession(with: provider)
    }

    private func createSession(with provider: BudgetDataProvider) {
        let tools: [any Tool] = [
            GetCurrentPaycheckTool(dataProvider: provider),
            GetTransactionsTool(dataProvider: provider),
            GetAccountsTool(dataProvider: provider),
            GetBillScheduleTool(dataProvider: provider),
            GetPaycheckHistoryTool(dataProvider: provider),
        ]

        session = LanguageModelSession(tools: tools) {
            Self.systemPrompt
        }
        messageCountSinceReset = 0
        shouldResetSession = false
    }

    // MARK: - Messaging

    func sendMessage(_ text: String) async {
        guard let session, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(role: .user, text: text, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        isGenerating = true
        errorMessage = nil

        // Add placeholder for assistant response
        let assistantMessage = ChatMessage(role: .assistant, text: "", timestamp: Date())
        messages.append(assistantMessage)

        do {
            let stream = session.streamResponse(to: text)
            for try await partial in stream {
                if let lastIndex = messages.indices.last {
                    messages[lastIndex].text = partial.content
                }
            }
        } catch {
            if let lastIndex = messages.indices.last {
                if messages[lastIndex].text.isEmpty {
                    messages[lastIndex].text = "Sorry, I couldn't process that. Please try again."
                }
            }
            errorMessage = error.localizedDescription
        }

        isGenerating = false
        messageCountSinceReset += 1
        ChatMessageTracker.recordMessage()

        // Suggest reset after ~6 exchanges to manage context window
        if messageCountSinceReset >= 6 {
            shouldResetSession = true
        }
    }

    func resetSession() {
        guard let provider = dataProvider else { return }
        messages.removeAll()
        createSession(with: provider)
    }
}

#endif
