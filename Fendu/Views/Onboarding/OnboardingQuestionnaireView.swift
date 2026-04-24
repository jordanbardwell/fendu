import SwiftUI

struct OnboardingQuestionnaireView: View {
    let onComplete: () -> Void

    @State private var step = 0
    @State private var selectedGoal: Int? = nil
    @State private var selectedPainPoints: Set<Int> = []
    @State private var demoAllocations: Set<Int> = []
    @State private var isAnimating = false

    private let demoPaycheck: Double = 2500

    private let goals: [(emoji: String, label: String)] = [
        ("📉", "Stop living paycheck to paycheck"),
        ("📋", "Replace my budgeting spreadsheet"),
        ("💵", "Know what I can actually spend after bills"),
        ("🏦", "Split my paycheck across accounts"),
        ("📅", "Stay ahead of recurring bills"),
        ("🎯", "Finally stick to a budget that works"),
    ]

    private let painPoints: [(emoji: String, label: String, solution: String, solutionIcon: String)] = [
        ("✏️", "Manually calculating where each paycheck goes", "Set up once — auto-split every paycheck", "arrow.triangle.branch"),
        ("🔄", "Other apps only track where money already went", "Plan where money goes before you spend it", "arrow.right.circle"),
        ("😰", "Forgetting a bill and overdrafting", "Every bill accounted for, every pay period", "bell.badge"),
        ("⏳", "Spending 30+ min on budget math each pay period", "Full paycheck planned in under 2 minutes", "clock"),
        ("🤔", "Never knowing what's actually safe to spend", "See exactly what's left after every bill", "eye"),
        ("🗂️", "Juggling multiple accounts with no clear plan", "One view — every account, every paycheck", "square.grid.2x2"),
    ]

    private let demoItems: [(emoji: String, name: String, amount: Double)] = [
        ("🏠", "Rent", 1200),
        ("💰", "Savings", 400),
        ("🚗", "Car Payment", 350),
        ("⚡", "Utilities", 150),
        ("📱", "Phone", 85),
        ("🎬", "Subscriptions", 45),
    ]

    private var demoRemaining: Double {
        let allocated = demoAllocations.reduce(0.0) { $0 + demoItems[$1].amount }
        return demoPaycheck - allocated
    }

    private var progress: CGFloat {
        CGFloat(step + 1) / 12.0
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.brandGreen)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 28)
            .opacity(step == 0 || step == 4 ? 0 : 1)

            switch step {
            case 0: welcomeStep
            case 1: goalStep
            case 2: painPointsStep
            case 3: solutionStep
            case 4: processingStep
            case 5: demoStep
            case 6: valueDeliveryStep
            default: EmptyView()
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Screen 1: Welcome

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            // App icon
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.brandGreen)
                )
                .padding(.bottom, 36)

            Text("Welcome to\nfendu.")
                .font(.system(size: 48, weight: .black))
                .tracking(-2)
                .lineSpacing(-4)
                .foregroundStyle(.white)

            Text("Plan every paycheck. Split across accounts.\nKnow exactly what's left.")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.95))
                .padding(.top, 20)

            Spacer()

            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Get started")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 999))
            }
            .padding(.horizontal, 24)

            Text("Takes about 2 minutes")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brandGreen)
    }

    // MARK: - Screen 2: Goal Question

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What would help you most?")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(goals.indices, id: \.self) { index in
                        let isSelected = selectedGoal == index
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedGoal = index
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(goals[index].emoji)
                                    .font(.title3)
                                Text(goals[index].label)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brandGreen)
                                        .font(.title3)
                                }
                            }
                            .padding(16)
                            .background(isSelected ? Color.brandGreen.opacity(0.08) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? Color.brandGreen : Color.clear, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation { step = 2 }
            } label: {
                Text("Continue")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(selectedGoal != nil ? Color.brandGreen : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(selectedGoal == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Screen 3: Pain Points

    private var painPointsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What makes budgeting frustrating?")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Select all that apply")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(painPoints.indices, id: \.self) { index in
                        let isSelected = selectedPainPoints.contains(index)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if isSelected {
                                    selectedPainPoints.remove(index)
                                } else {
                                    selectedPainPoints.insert(index)
                                }
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(painPoints[index].emoji)
                                    .font(.title3)
                                Text(painPoints[index].label)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(isSelected ? Color.brandGreen : .gray.opacity(0.4))
                                    .font(.title3)
                            }
                            .padding(16)
                            .background(isSelected ? Color.brandGreen.opacity(0.08) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? Color.brandGreen : Color.clear, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    withAnimation { step = 1 }
                } label: {
                    Text("Back")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    withAnimation { step = 3 }
                } label: {
                    Text("Continue")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(!selectedPainPoints.isEmpty ? Color.brandGreen : Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedPainPoints.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Screen 4: Personalized Solution

    private var solutionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Here's how Fendu fixes that")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(selectedPainPoints.sorted(), id: \.self) { index in
                        let item = painPoints[index]
                        VStack(alignment: .leading, spacing: 10) {
                            Text(item.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .strikethrough(true, color: .secondary.opacity(0.5))

                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandGreen.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: item.solutionIcon)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.brandGreen)
                                }

                                Text(item.solution)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    withAnimation { step = 2 }
                } label: {
                    Text("Back")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    withAnimation { step = 4 }
                } label: {
                    Text("Show Me How It Works")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Screen 5: Processing Moment

    private var processingStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.brandGreen.opacity(0.12))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
                Image(systemName: "gearshape.2")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.brandGreen)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            }

            Text("Building your experience...")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .onAppear {
            isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isAnimating = false
                    step = 5
                }
            }
        }
    }

    // MARK: - Screen 6: App Demo

    private var demoStep: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Try it — split a paycheck")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("You just got paid \(demoPaycheck.asCurrency()). Tap to allocate.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            HStack {
                Text("Remaining")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(demoRemaining.asCurrency())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(demoRemaining >= 0 ? Color.brandGreen : .red)
                    .contentTransition(.numericText())
            }
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(demoItems.indices, id: \.self) { index in
                        let item = demoItems[index]
                        let isSelected = demoAllocations.contains(index)

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if isSelected {
                                    demoAllocations.remove(index)
                                } else {
                                    demoAllocations.insert(index)
                                }
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(item.emoji)
                                    .font(.title3)

                                Text(item.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(item.amount.asCurrency())
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundStyle(isSelected ? Color.brandGreen : .secondary)

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? Color.brandGreen : .gray.opacity(0.4))
                                    .font(.title3)
                            }
                            .padding(16)
                            .background(isSelected ? Color.brandGreen.opacity(0.08) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? Color.brandGreen : Color.clear, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            Spacer(minLength: 0)

            if demoAllocations.count < 3 {
                Text("Select at least \(3 - demoAllocations.count) more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }

            Button {
                withAnimation { step = 6 }
            } label: {
                Text("See My Breakdown")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(demoAllocations.count >= 3 ? Color.brandGreen : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(demoAllocations.count < 3)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Screen 7: Value Delivery

    private var valueDeliveryStep: some View {
        let totalAllocated = demoAllocations.reduce(0.0) { $0 + demoItems[$1].amount }
        let leftToSpend = demoPaycheck - totalAllocated

        return VStack(alignment: .leading, spacing: 20) {
            Text("Your budget at a glance")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(demoAllocations.sorted(), id: \.self) { index in
                        let item = demoItems[index]
                        HStack(spacing: 14) {
                            Text(item.emoji)
                                .font(.title3)
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(item.amount.asCurrency())
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    HStack(spacing: 14) {
                        Text("✨")
                            .font(.title3)
                        Text("Left to spend")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(leftToSpend.asCurrency())
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.brandGreen)
                    }
                    .padding(16)
                    .background(Color.brandGreen.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
            }

            Text("You just planned a whole paycheck in 15 seconds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            Button {
                onComplete()
            } label: {
                Text("Set Up My Real Budget")
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
}
