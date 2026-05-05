import SwiftUI

struct FenduMark: View {
    var size: CGFloat = 22

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let midX = w / 2
            let splitY = h * (32.0 / 56.0)
            let gap: CGFloat = w * 0.04

            // Top block (trapezoid with diagonal)
            var top = Path()
            top.move(to: .init(x: 0, y: 0))
            top.addLine(to: .init(x: w, y: 0))
            top.addLine(to: .init(x: w, y: splitY - gap))
            top.addLine(to: .init(x: midX, y: splitY - gap))
            top.closeSubpath()
            context.fill(top, with: .foreground)

            // Bottom-left
            let bl = Path(CGRect(
                x: 0,
                y: splitY,
                width: midX - gap / 2,
                height: h - splitY
            ))
            context.fill(bl, with: .foreground)

            // Bottom-right
            let br = Path(CGRect(
                x: midX + gap / 2,
                y: splitY,
                width: w - midX - gap / 2,
                height: h - splitY
            ))
            context.fill(br, with: .foreground)
        }
        .frame(width: size, height: size)
    }
}
