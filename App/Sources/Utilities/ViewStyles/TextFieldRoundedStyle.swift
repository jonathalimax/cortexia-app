import SwiftUI

/// A custom `TextFieldStyle` that applies rounded styling to a `TextField`, including a rounded background and a placeholder view.
struct TextFieldRoundedStyle<Placeholder: View>: TextFieldStyle {
	// A binding to the text displayed in the `TextField`.
	let text: Binding<String>

	/// A closure that returns the placeholder view to display when the `TextField` is empty.
	let placeholder: () -> Placeholder

	func _body(configuration: TextField<Self._Label>) -> some View {
		configuration
			.padding()
			.frame(height: 46)
			.background(.darkGrey.opacity(0.6))
			.overlay {
				if text.wrappedValue.isEmpty {
					placeholder()
						.allowsHitTesting(false)
				}
			}
			.clipShape(.rect(cornerRadius: 18))
	}
}
