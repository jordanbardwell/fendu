import SwiftUI

struct PaycheckSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var config: PaycheckConfig

    @State private var amount: String
    @State private var frequency: PayFrequency
    @State private var startDate: Date
    @State private var semiMonthlyDay1: Int
    @State private var semiMonthlyDay2: Int

    init(config: PaycheckConfig) {
        self.config = config
        _amount = State(initialValue: String(format: "%.0f", config.amount))
        _frequency = State(initialValue: config.frequency)
        _startDate = State(initialValue: config.startDate)
        _semiMonthlyDay1 = State(initialValue: config.semiMonthlyDay1)
        _semiMonthlyDay2 = State(initialValue: config.semiMonthlyDay2)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BASE AMOUNT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray.opacity(0.7))
                        .tracking(1.5)

                    HStack {
                        Text("$")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.gray.opacity(0.5))
                        TextField("0", text: $amount)
                            .font(.title3)
                            .fontWeight(.bold)
                            .keyboardType(.decimalPad)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("FREQUENCY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray.opacity(0.7))
                        .tracking(1.5)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(PayFrequency.allCases) { freq in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    frequency = freq
                                }
                            } label: {
                                Text(freq.displayName)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        frequency == freq
                                            ? Color.brandGreen
                                            : Color(.systemGray6)
                                    )
                                    .foregroundStyle(
                                        frequency == freq
                                            ? .white
                                            : .secondary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                                            .opacity(frequency == freq ? 0 : 1)
                                    )
                            }
                        }
                    }
                }

                if frequency == .semiMonthly {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PAY DAYS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        HStack(spacing: 12) {
                            dayPicker(label: "First", selection: $semiMonthlyDay1)
                            dayPicker(label: "Second", selection: $semiMonthlyDay2)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NEXT PAY DATE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                            )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                Button {
                    saveChanges()
                } label: {
                    Text("Save Changes")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.brandGreen.opacity(0.2), radius: 8, y: 4)
                }
            }
            .padding(24)
            .navigationTitle("Paycheck Settings")
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
    }

    private func dayPicker(label: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.gray)
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.brandGreen)
                Picker("", selection: selection) {
                    ForEach(1...31, id: \.self) { day in
                        Text(daySuffix(day)).tag(day)
                    }
                }
                .labelsHidden()
                .tint(.primary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func daySuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "\(day)st"
        case 2, 22: return "\(day)nd"
        case 3, 23: return "\(day)rd"
        default: return "\(day)th"
        }
    }

    private func saveChanges() {
        config.amount = Double(amount) ?? config.amount
        // Only update frequency/startDate if they actually changed,
        // since paycheck IDs are date-based — changing dates orphans transactions
        if frequency != config.frequency {
            config.frequency = frequency
        }
        if !Calendar.current.isDate(startDate, inSameDayAs: config.startDate) {
            config.startDate = startDate
        }
        config.semiMonthlyDay1 = semiMonthlyDay1
        config.semiMonthlyDay2 = semiMonthlyDay2
        dismiss()
    }
}
