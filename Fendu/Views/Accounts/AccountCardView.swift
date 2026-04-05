import SwiftUI

struct AccountRowView: View {
    let account: Account
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var iconName: String {
        switch account.type {
        case .credit: return "creditcard"
        case .checking: return "dollarsign.arrow.circlepath"
        case .savings: return "banknote"
        case .loan: return "building.columns"
        case .bill: return "doc.text"
        case .other: return "square.grid.2x2"
        }
    }

    var body: some View {
        Button {
            onEdit()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 36, height: 36)
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(account.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text(account.type.displayName)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.gray.opacity(0.4))
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
