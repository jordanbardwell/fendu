import SwiftUI

struct AccountsGridView: View {
    let accounts: [Account]
    let onEdit: (Account) -> Void
    let onDelete: (Account) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Your Accounts")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add Account")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(Color.brandGreen)
                }
            }
            .padding(.bottom, 16)

            Divider()
                .padding(.bottom, 4)

            ForEach(accounts) { account in
                AccountRowView(
                    account: account,
                    onEdit: { onEdit(account) },
                    onDelete: { onDelete(account) }
                )
                if account.id != accounts.last?.id {
                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
    }
}
