import SwiftUI

struct ChatMessageView: View {
	let message: String
	let type: `Type`

	enum `Type` {
		case sent, received
	}

	var body: some View {
		Text(message)
			.applyChatMessageStyle(type)
	}
}

private extension Text {
	@ViewBuilder
	func applyChatMessageStyle(_ type: ChatMessageView.`Type`) -> some View {
		switch type {
		case .sent:
			self.applyMessageBubble()

		case .received:
			self
				.foregroundStyle(.adaptiveWhite)
				.padding(.vertical)
		}
	}
}

#Preview("Sent message") {
	ZStack {
		Color.adaptiveBackground

		ChatMessageView(message: "First chat message", type: .sent)
	}
	.ignoresSafeArea()
}

#Preview("Received message") {
	ZStack {
		Color.adaptiveBackground

		ChatMessageView(message: "First chat message", type: .received)
	}
	.ignoresSafeArea()
}
