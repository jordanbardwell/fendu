import SwiftUI

private func paymentMethodIcon(for method: String) -> String {
    switch method {
    case "Cash": return "banknote"
    case "Venmo": return "v.circle.fill"
    case "Zelle": return "bolt.fill"
    case "PayPal": return "p.circle.fill"
    case "Apple Pay": return "apple.logo"
    case "CashApp": return "dollarsign.square.fill"
    default: return "paperplane.fill"
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    let accountName: String
    var fundingAccountName: String? = nil

    private var iconName: String {
        if transaction.isIncome {
            return "arrow.down.left"
        } else if transaction.isPaymentMethod {
            return paymentMethodIcon(for: transaction.paymentMethod)
        } else if transaction.isTransfer {
            return "arrow.left.arrow.right"
        }
        return "creditcard"
    }

    private var tintColor: Color {
        if transaction.isIncome {
            return Color.brandGreen
        } else if transaction.isPaymentMethod {
            return Color.brandGreen
        } else if transaction.isTransfer {
            return .blue
        }
        return .gray
    }

    private var typeLabel: String {
        if transaction.isIncome {
            return "INCOME"
        } else if transaction.isPaymentMethod {
            return "PAYMENT"
        } else if transaction.isTransfer {
            return "TRANSFER"
        }
        return "ALLOCATED"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tintColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(tintColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(accountName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                if let fundingName = fundingAccountName {
                    Text("from \(fundingName)")
                        .font(.system(size: 10))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.brandGreen.opacity(0.7))
                }
                Text(transaction.note.isEmpty ? "No note" : transaction.note)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.isIncome
                    ? "+\(abs(transaction.amount).asCurrency())"
                    : "-\(transaction.amount.asCurrency())")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(typeLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(tintColor.opacity(0.6))
                    .tracking(1.5)
            }
        }
        .padding(.vertical, 4)
    }
}
