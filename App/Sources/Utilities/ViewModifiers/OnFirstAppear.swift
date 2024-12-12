import SwiftUI

private struct OnFirstAppear: ViewModifier {
	@State private var firstTime = true
	let perform: () -> Void

	func body(content: Content) -> some View {
		content.onAppear {
			if firstTime {
				firstTime = false
				perform()
			}
		}
	}
}

extension View {
	/// Adds the `OnFirstAppear` modifier to a view, which performs a specified action only the first time the view appears.
	/// - Parameter perform: A closure to be executed the first time the view appears.
	/// - Returns: A view that will execute the provided closure only on its first appearance.
	func onFirstAppear(perform: @escaping () -> Void) -> some View {
		modifier(OnFirstAppear(perform: perform))
	}
}
