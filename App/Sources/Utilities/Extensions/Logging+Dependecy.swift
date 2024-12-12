import Dependencies
import Foundation
import Logging

extension Logger: @retroactive DependencyKey {
	public static var liveValue: Logger = .init(label: Bundle.main.bundleIdentifier ?? "com.logging.default")
}

extension DependencyValues {
	var logger: Logger {
		get { self[Logger.self] }
		set { self[Logger.self] = newValue }
	}
}
