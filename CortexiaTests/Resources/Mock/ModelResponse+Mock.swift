@testable import Cortexia

extension ModelResponse {
	static let mock: Self = .init(
		data: [
			.init(id: "model1", ownedBy: "openAI"),
			.init(id: "model2", ownedBy: "openAI"),
		]
	)
}
