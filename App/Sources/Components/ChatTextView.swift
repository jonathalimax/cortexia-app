import SwiftUI

struct ChatTextView: View {
	@Binding var text: String
	@State private var feedback: Bool = false

	var onSendTapped: () -> Void
	var onPencilTapped: () -> Void

	var body: some View {
		HStack(spacing: 16) {
			TextField(text: $text, label: {})
				.textFieldStyle(TextFieldRoundedStyle(text: $text, placeholder: { placeholder }))
				.foregroundStyle(.white)
				.submitLabel(.send)

			Button(
				action: { onPencilTapped() },
				label: {
					Image(systemName: "pencil.circle.fill")
						.resizable()
						.foregroundStyle(.adaptiveWhite.opacity(0.6))
						.frame(width: 28, height: 28)
				}
			)

			Button(
				action: {
					onSendTapped()
					feedback.toggle()
				},
				label: {
					Image(systemName: "arrow.up.message.fill")
						.resizable()
						.foregroundStyle(.adaptiveWhite.opacity(text.isEmpty ? 0.2 : 0.6))
						.frame(width: 28, height: 28)
						.animation(.default, value: text.isEmpty)
				}
			)
			.disabled(text.isEmpty)
			.sensoryFeedback(.success, trigger: feedback)
		}
	}

	private var placeholder: some View {
		HStack {
			Text("Ask anything..")
				.foregroundStyle(Color.white.opacity(0.5))

			Spacer()
		}
		.padding()
	}
}

#Preview(traits: .sizeThatFitsLayout) {
	ZStack {
		ChatTextView(
			text: .constant(""),
			onSendTapped: {},
			onPencilTapped: {}
		)
	}
	.ignoresSafeArea()
}
