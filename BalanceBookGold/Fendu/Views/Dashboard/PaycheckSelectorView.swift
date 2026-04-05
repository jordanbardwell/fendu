import SwiftUI

struct PaycheckPillData: Identifiable, Equatable {
    let id: String
    let date: Date
    let progress: Double
    let isDone: Bool
}

struct PaycheckSelectorView: View {
    let pills: [PaycheckPillData]
    let selectedId: String?
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(pills) { pill in
                    PaycheckPillView(
                        pill: pill,
                        isSelected: selectedId == pill.id,
                        onSelect: onSelect
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct PaycheckPillView: View {
    let pill: PaycheckPillData
    let isSelected: Bool
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(pill.date.formattedShortMonthDay())
                .font(.subheadline)
                .fontWeight(.bold)

            if pill.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? .white : Color.brandGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Base
                    Capsule()
                        .fill(
                            isSelected
                                ? Color.brandGreen
                                : pill.isDone
                                    ? Color.brandGreen.opacity(0.1)
                                    : Color(.systemGray6)
                        )

                    // Progress fill (hidden when done or fully empty)
                    if !pill.isDone && pill.progress > 0 {
                        Capsule()
                            .fill(
                                isSelected
                                    ? Color.white.opacity(0.2)
                                    : Color.brandGreen.opacity(0.25)
                            )
                            .frame(width: geo.size.width * pill.progress)
                            .animation(.easeInOut(duration: 0.4), value: pill.progress)
                    }
                }
            }
        )
        .foregroundStyle(
            isSelected
                ? .white
                : pill.isDone
                    ? Color.brandGreen
                    : .gray
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    pill.isDone && !isSelected
                        ? Color.brandGreen.opacity(0.3)
                        : !pill.isDone && !isSelected && pill.progress > 0
                            ? Color.brandGreen.opacity(0.3)
                            : Color.clear,
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: isSelected
                ? Color.brandGreen.opacity(0.2)
                : .clear,
            radius: 8, y: 4
        )
        .onTapGesture {
            onSelect(pill.id)
        }
    }
}
