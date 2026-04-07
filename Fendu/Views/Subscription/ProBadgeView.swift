import SwiftUI

struct ProBadgeView: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.brandOrange)
            .clipShape(Capsule())
    }
}
