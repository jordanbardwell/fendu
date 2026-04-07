#if canImport(FoundationModels)
import SwiftUI
import SwiftData
import FoundationModels

@available(iOS 26, *)
struct ChatView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query private var accounts: [Account]
    @Query private var allTransactions: [Transaction]
    @Query private var configs: [PaycheckConfig]
    @Query private var paycheckStatuses: [PaycheckStatus]
    @Query private var allBillAssignments: [BillAssignment]
    @Query private var allBillSkips: [BillSkip]
    @Query private var allBillOverrides: [BillAmountOverride]
    @Query private var splits: [PaycheckSplit]

    @State private var viewModel = ChatViewModel()
    @State private var showProPaywall = false

    private var config: PaycheckConfig? { configs.first }

    private var dataProvider: BudgetDataProvider? {
        guard let config else { return nil }
        return BudgetDataProvider(
            config: config,
            accounts: accounts,
            allTransactions: allTransactions,
            allBillAssignments: allBillAssignments,
            allBillSkips: allBillSkips,
            allBillOverrides: allBillOverrides,
            paycheckStatuses: paycheckStatuses,
            splits: splits
        )
    }

    private let suggestedPrompts = [
        "How am I doing this paycheck?",
        "Break down my spending",
        "When's my next bill?",
        "Compare to last paycheck",
    ]

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.modelAvailability {
                case .checking:
                    ProgressView("Checking AI availability...")
                case .unavailable(let reason):
                    ChatUnavailableView(reason: reason)
                case .available:
                    chatContent
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.title2)
                            .foregroundStyle(Color.brandGreen)
                        Text("Budget Chat")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }

                if case .available = viewModel.modelAvailability,
                   !viewModel.messages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.resetSession()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
        }
        .task {
            viewModel.checkAvailability()
            if let provider = dataProvider {
                viewModel.configure(with: provider)
            }
        }
        .onChange(of: allTransactions.count) { _, _ in
            if let provider = dataProvider {
                viewModel.configure(with: provider)
            }
        }
        .onChange(of: allBillAssignments.count) { _, _ in
            if let provider = dataProvider {
                viewModel.configure(with: provider)
            }
        }
        .sheet(isPresented: $showProPaywall) {
            ProFeaturePaywallView(trigger: .aiChat)
        }
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {

                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }

                        if viewModel.isGenerating,
                           let last = viewModel.messages.last,
                           last.text.isEmpty {
                            typingIndicator
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.messages.last?.text) { _, _ in
                    if let lastId = viewModel.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }

            // Context reset suggestion
            if viewModel.shouldResetSession {
                resetSuggestionBar
            }

            // Suggested prompts when empty
            if viewModel.messages.isEmpty {
                suggestedPromptsView
            }

            // Input bar
            inputBar

            // Free tier counter
            if !subscriptionManager.isPro {
                let remaining = ChatMessageTracker.remainingMessages
                Text("\(remaining) message\(remaining == 1 ? "" : "s") remaining this month")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Suggested Prompts

    private var suggestedPromptsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(Color.brandGreen.opacity(0.6))
                .padding(.bottom, 4)

            Text("Ask about your budget")
                .font(.subheadline)
                .foregroundStyle(.gray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestedPrompts, id: \.self) { prompt in
                        Button {
                            sendPrompt(prompt)
                        } label: {
                            Text(prompt)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.brandGreen)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.brandGreen.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about your budget...", text: $viewModel.inputText)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
                .disabled(viewModel.isGenerating)
                .onSubmit {
                    sendPrompt(viewModel.inputText)
                }

            Button {
                sendPrompt(viewModel.inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating
                            ? Color.gray.opacity(0.4)
                            : Color.brandGreen
                    )
            }
            .disabled(
                viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Reset Suggestion

    private var resetSuggestionBar: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .font(.caption)
                .foregroundStyle(.orange)
            Text("Conversation getting long.")
                .font(.caption)
                .foregroundStyle(.gray)
            Button("Start fresh") {
                viewModel.resetSession()
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.brandGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(.systemGray6).opacity(0.6))
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack {
            TypingBubbleView()

            Spacer()
        }
    }

    // MARK: - Actions

    private func sendPrompt(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !ChatMessageTracker.canSendMessage(isPro: subscriptionManager.isPro) {
            showProPaywall = true
            return
        }

        Task {
            await viewModel.sendMessage(trimmed)
        }
    }
}

#endif
