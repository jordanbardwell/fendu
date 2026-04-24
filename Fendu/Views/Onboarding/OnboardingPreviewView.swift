import SwiftUI
import SwiftData

struct OnboardingPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configs: [PaycheckConfig]
    @Query private var splits: [PaycheckSplit]
    @Query private var accounts: [Account]
    @Query private var allBillAssignments: [BillAssignment]

    let onContinue: () -> Void

    private var config: PaycheckConfig? { configs.first }

    private var firstPaycheck: PaycheckInstance? {
        guard let config else { return nil }
        let instances = PaycheckGenerator.generateInstances(from: config)
        let currentId = PaycheckGenerator.currentPaycheckId(from: instances)
        return instances.first { $0.id == currentId } ?? instances.first
    }

    private var accountSplits: [(name: String, amount: Double)] {
        guard let paycheck = firstPaycheck else { return [] }
        let sortedSplits = splits.sorted { $0.orderIndex < $1.orderIndex }
        return sortedSplits.compactMap { split in
            guard let account = accounts.first(where: { $0.id.uuidString == split.accountId }) else { return nil }
            let amount: Double
            if split.isRemainder {
                let fixedTotal = sortedSplits.filter { !$0.isRemainder }.reduce(0.0) { $0 + $1.amount }
                amount = paycheck.baseAmount - fixedTotal
            } else {
                amount = split.amount
            }
            return (name: account.name, amount: amount)
        }
    }

    private var applicableBills: [(name: String, amount: Double)] {
        guard let paycheck = firstPaycheck, let config else { return [] }
        return allBillAssignments
            .filter { $0.appliesTo(paycheckId: paycheck.id, frequency: config.frequency, semiMonthlyDay1: config.semiMonthlyDay1, semiMonthlyDay2: config.semiMonthlyDay2) }
            .compactMap { assignment in
                let name = accounts.first { $0.id.uuidString == assignment.billAccountId }?.name ?? "Bill"
                return (name: name, amount: assignment.amount)
            }
    }

    private var totalBills: Double {
        applicableBills.reduce(0) { $0 + $1.amount }
    }

    private var leftAfterBills: Double {
        (firstPaycheck?.baseAmount ?? 0) - totalBills
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Ready to go")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color.brandGreen)
                .textCase(.uppercase)

            Text("Your first\npaycheck.")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.5)
                .multilineTextAlignment(.center)

            // Dark preview card
            if let paycheck = firstPaycheck {
                VStack(alignment: .leading, spacing: 12) {
                    // Date label
                    Text("\(paycheck.date.formatted(.dateTime.month(.abbreviated).day()).uppercased()) · PAYCHECK")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(.gray)

                    // Large amount
                    let intPart = Int(paycheck.baseAmount)
                    let formatted = NumberFormatter.localizedString(from: NSNumber(value: intPart), number: .decimal)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("$\(formatted)")
                            .font(.system(size: 40, weight: .bold))
                            .tracking(-1)
                            .foregroundStyle(.white)
                        Text(".00")
                            .font(.system(size: 40, weight: .bold))
                            .tracking(-1)
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    // Split labels inline
                    if !accountSplits.isEmpty {
                        HStack(spacing: 16) {
                            ForEach(Array(accountSplits.enumerated()), id: \.offset) { _, split in
                                Text("\(split.name) \(split.amount.asCurrency())")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.gray)
                            }
                            if totalBills > 0 {
                                Text("Free \(leftAfterBills.asCurrency())")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.brandOrange)
                            }
                        }

                        // Segmented progress bar
                        GeometryReader { geo in
                            HStack(spacing: 2) {
                                ForEach(Array(accountSplits.enumerated()), id: \.offset) { index, split in
                                    let fraction = paycheck.baseAmount > 0 ? split.amount / paycheck.baseAmount : 0
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(splitColor(for: index))
                                        .frame(width: max(geo.size.width * fraction - 2, 4))
                                }
                                if totalBills > 0 {
                                    let billFraction = totalBills / paycheck.baseAmount
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.brandOrange)
                                        .frame(width: max(geo.size.width * billFraction - 2, 4))
                                }
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding(20)
                .background(Color(red: 20/255, green: 20/255, blue: 20/255))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                // Bill rows below the card
                if !applicableBills.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(applicableBills.enumerated()), id: \.offset) { _, bill in
                            HStack {
                                Text(bill.name)
                                    .font(.system(size: 15))
                                Spacer()
                                Text("-\(bill.amount.asCurrency())")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .padding(.vertical, 10)

                            Divider()
                        }

                        HStack {
                            Text("Left after bills")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text(leftAfterBills.asCurrency())
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.brandGreen)
                        }
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Looks right — continue")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func splitColor(for index: Int) -> Color {
        let colors: [Color] = [Color.brandGreen, .blue, .purple, .cyan]
        return colors[index % colors.count]
    }
}
