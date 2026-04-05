import SwiftUI

struct DepositAccountEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let account: Account
    let paycheckAmount: Double
    let assignedToOthers: Double
    @Binding var splitMode: SplitMode
    @Binding var fixedAmount: String
    let onDelete: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SplitAssignmentView(
                        account: account,
                        paycheckAmount: paycheckAmount,
                        assignedToOthers: assignedToOthers,
                        splitMode: $splitMode,
                        fixedAmount: $fixedAmount
                    )

                    // Save
                    Button {
                        onSave()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.brandGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Delete
                    Button {
                        onDelete()
                        dismiss()
                    } label: {
                        Text("Delete Account")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red.opacity(0.8))
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle(account.name)
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
}
