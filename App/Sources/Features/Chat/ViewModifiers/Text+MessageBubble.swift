import SwiftUI

extension Text {
	/// Applies a custom styling to the view, making it resemble a chat message bubble.
	func applyMessageBubble(textColor: Color = .white, backgroundColor: Color = .blue.opacity(0.9)) -> some View {
		self
			.padding(.horizontal)
			.padding(.vertical, 12)
			.foregroundColor(textColor)
			.background(backgroundColor)
			.clipShape(.rect(cornerRadius: 22))
			.shadow(color: Color.adaptiveBackground.opacity(0.5), radius: 4, x: 4, y: 4)
	}
}
