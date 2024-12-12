import Foundation

@testable import Cortexia

extension OpenAIService {
	static let stub: Self = {
		.init(
			chatCompletions: { _, _ in .mock },
			fetchModels: { _ in .mock }
		)
	}()
}
