#if canImport(FoundationModels)
import SwiftUI

@available(iOS 26, *)
struct ChatUnavailableView: View {
    let reason: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "cpu")
                    .font(.system(size: 30))
                    .foregroundStyle(.gray)
            }

            Text("AI Chat Unavailable")
                .font(.title3)
                .fontWeight(.bold)

            Text(reason)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#endif
