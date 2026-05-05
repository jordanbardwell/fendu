#if canImport(FoundationModels)
import SwiftUI

@available(iOS 26, *)
struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        if message.role == .assistant && message.text.isEmpty {
            EmptyView()
        } else {
            HStack(alignment: .top, spacing: 8) {
                if message.role == .user {
                    Spacer(minLength: 60)
                }

                if message.role == .assistant {
                    FenduMark(size: 18)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                formattedText
                    .font(.subheadline)
                    .lineSpacing(4)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .clipShape(bubbleShape)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.text
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }

                if message.role == .assistant {
                    Spacer(minLength: 60)
                }
            }
        }
    }

    private var formattedText: Text {
        // Split on newlines, parse each line as markdown, and join with newlines
        let lines = message.text.components(separatedBy: "\n")
        var result = AttributedString()
        for (index, line) in lines.enumerated() {
            if let parsed = try? AttributedString(markdown: line) {
                result.append(parsed)
            } else {
                result.append(AttributedString(line))
            }
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }
        return Text(result)
    }

    private var bubbleBackground: Color {
        message.role == .user ? Color.brandGreen : Color(.systemGray6)
    }

    private var bubbleShape: UnevenRoundedRectangle {
        switch message.role {
        case .user:
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 6,
                topTrailingRadius: 20
            )
        case .assistant:
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 6,
                bottomTrailingRadius: 20,
                topTrailingRadius: 20
            )
        }
    }
}

#endif
