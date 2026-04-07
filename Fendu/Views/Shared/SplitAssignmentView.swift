import SwiftUI

enum SplitMode {
    case fixed
    case remainder
}

struct SplitAssignmentView: View {
    let account: Account
    let paycheckAmount: Double
    let assignedToOthers: Double
    @Binding var splitMode: SplitMode
    @Binding var fixedAmount: String

    private var typedFixed: Double {
        Double(fixedAmount) ?? 0
    }

    private var remainderValue: Double {
        max(paycheckAmount - assignedToOthers, 0)
    }

    private var remainingToAssign: Double {
        let myAmount = splitMode == .fixed ? typedFixed : remainderValue
        return paycheckAmount - assignedToOthers - myAmount
    }

    private var bannerAmount: Double {
        splitMode == .remainder ? remainderValue : remainingToAssign
    }

    private var bannerLabel: String {
        splitMode == .remainder ? "this account receives" : "left to assign"
    }

    var body: some View {
        VStack(spacing: 28) {
            // Running total banner
            VStack(spacing: 4) {
                Text(bannerAmount.asCurrency())
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(bannerAmount >= 0 ? Color.brandGreen : Color.brandOrange)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: bannerAmount)
                Text(bannerLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                (bannerAmount >= 0 ? Color.brandGreen : Color.brandOrange).opacity(0.06)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Account identity
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 48, height: 48)
                    Image(systemName: account.type == .checking ? "dollarsign.arrow.circlepath" : "banknote")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray)
                }
                Text(account.name)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(account.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            // Selection cards
            VStack(spacing: 12) {
                // Fixed Amount card
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        splitMode = .fixed
                    }
                } label: {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: splitMode == .fixed ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(splitMode == .fixed ? Color.brandGreen : .gray.opacity(0.4))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fixed Amount")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                Text("Set a specific dollar amount")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }

                        if splitMode == .fixed {
                            HStack {
                                Text("$")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray.opacity(0.5))
                                TextField("0", text: $fixedAmount)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(16)
                    .background(
                        splitMode == .fixed
                            ? Color.brandGreen.opacity(0.04)
                            : Color(.systemGray6).opacity(0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                splitMode == .fixed
                                    ? Color.brandGreen.opacity(0.4)
                                    : Color(.systemGray4).opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(.plain)

                // Remainder card
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        splitMode = .remainder
                        fixedAmount = ""
                    }
                } label: {
                    HStack {
                        Image(systemName: splitMode == .remainder ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(splitMode == .remainder ? Color.brandGreen : .gray.opacity(0.4))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Remainder")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Text(splitMode == .remainder
                                ? "Gets whatever's left: \(remainderValue.asCurrency())"
                                : "Gets whatever's left after other accounts")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        splitMode == .remainder
                            ? Color.brandGreen.opacity(0.06)
                            : Color(.systemGray6).opacity(0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                splitMode == .remainder
                                    ? Color.brandGreen.opacity(0.4)
                                    : Color(.systemGray4).opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}
