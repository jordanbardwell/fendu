import SwiftUI
import SwiftData

struct AccountFormSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let editingAccount: Account?

    @State private var name: String
    @State private var type: AccountType
    @State private var selectedIssuer: CardIssuer?
    @State private var selectedCard: String?

    private var isEditing: Bool { editingAccount != nil }

    init(editingAccount: Account?) {
        self.editingAccount = editingAccount
        if let account = editingAccount {
            _name = State(initialValue: account.name)
            _type = State(initialValue: account.type)
        } else {
            _name = State(initialValue: "")
            _type = State(initialValue: .credit)
        }
    }

    private var resolvedName: String {
        if type == .credit, let issuer = selectedIssuer, let card = selectedCard {
            return "\(issuer.name) \(card)"
        }
        return name
    }

    private var canSave: Bool {
        if type == .credit {
            return selectedIssuer != nil && selectedCard != nil
        }
        return !name.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Type picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TYPE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        Picker("Type", selection: $type) {
                            ForEach(AccountType.allCases.filter { $0 != .bill && $0 != .checking && $0 != .savings && $0 != .loan }) { accountType in
                                Text(accountType.displayName).tag(accountType)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Credit card picker or name field
                    if type == .credit {
                        creditCardSelectionView
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACCOUNT NAME")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.gray.opacity(0.7))
                                .tracking(1.5)

                            TextField("e.g. Phone Bill, Savings, etc.", text: $name)
                                .fontWeight(.bold)
                                .padding(16)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    Button {
                        saveAccount()
                    } label: {
                        Text(isEditing ? "Save Changes" : "Create Account")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.brandGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                }
                .padding(24)
            }
            .navigationTitle(isEditing ? "Edit Account" : "New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .onAppear {
            if let account = editingAccount, account.type == .credit {
                matchExistingCard(account.name)
            }
        }
        .onChange(of: type) { _, newType in
            if newType != .credit {
                selectedIssuer = nil
                selectedCard = nil
            }
        }
    }

    // MARK: - Credit Card Selection

    private let selectionFeedback = UISelectionFeedbackGenerator()

    private var creditCardSelectionView: some View {
        VStack(spacing: 16) {
            // Issuer picker — 2-column grid with capsule chips
            VStack(alignment: .leading, spacing: 8) {
                Text("ISSUER")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.gray.opacity(0.7))
                    .tracking(1.5)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(CreditCardCatalog.issuers) { issuer in
                        let isSelected = selectedIssuer?.name == issuer.name
                        Button {
                            selectionFeedback.selectionChanged()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if isSelected {
                                    selectedIssuer = nil
                                    selectedCard = nil
                                } else {
                                    selectedIssuer = issuer
                                    selectedCard = nil
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(isSelected ? Color.brandGreen : .gray.opacity(0.5))
                                Text(issuer.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(
                                isSelected
                                    ? Color.brandGreen.opacity(0.12)
                                    : Color(.systemGray6)
                            )
                            .foregroundStyle(
                                isSelected
                                    ? Color.brandGreen
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isSelected
                                            ? Color.brandGreen.opacity(0.5)
                                            : Color(.systemGray4).opacity(0.3),
                                        lineWidth: 1.5
                                    )
                            )
                        }
                    }
                }
            }

            // Card picker — shown after issuer is selected
            if let issuer = selectedIssuer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CARD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray.opacity(0.7))
                        .tracking(1.5)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(issuer.cards, id: \.self) { card in
                            let isSelected = selectedCard == card
                            Button {
                                selectionFeedback.selectionChanged()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedCard = card
                                }
                            } label: {
                                Text(card)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(
                                        isSelected
                                            ? Color.brandGreen.opacity(0.12)
                                            : Color(.systemGray6)
                                    )
                                    .foregroundStyle(
                                        isSelected
                                            ? Color.brandGreen
                                            : .primary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                isSelected
                                                    ? Color.brandGreen.opacity(0.5)
                                                    : Color(.systemGray4).opacity(0.3),
                                                lineWidth: 1.5
                                            )
                                    )
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Preview of resolved name
            if let issuer = selectedIssuer, let card = selectedCard {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(Color.brandGreen)
                    Text("\(issuer.name) \(card)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.brandGreen.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.opacity)
            }
        }
    }

    // MARK: - Helpers

    private func matchExistingCard(_ accountName: String) {
        for issuer in CreditCardCatalog.issuers {
            for card in issuer.cards {
                if accountName == "\(issuer.name) \(card)" {
                    selectedIssuer = issuer
                    selectedCard = card
                    return
                }
            }
        }
        // No match found — might be a custom-named credit card from before
        // Leave pickers empty, user can re-select
    }

    private func saveAccount() {
        guard canSave else { return }
        let finalName = resolvedName

        if let account = editingAccount {
            account.name = finalName
            account.type = type
        } else {
            let newAccount = Account(name: finalName, type: type)
            modelContext.insert(newAccount)
        }
        WidgetReloader.reloadAll()
        dismiss()
    }
}
