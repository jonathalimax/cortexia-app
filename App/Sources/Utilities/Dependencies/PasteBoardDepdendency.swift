import Dependencies
import SwiftUI

extension UIPasteboard: @retroactive DependencyKey {
	public static var liveValue: UIPasteboard = .general
	public static var testValue: UIPasteboard = .init()
	public static var previewValue: UIPasteboard = .init()
}

extension DependencyValues {
	var pasteboard: UIPasteboard {
		get { self[UIPasteboard.self] }
		set { self[UIPasteboard.self] = newValue }
	}
}
