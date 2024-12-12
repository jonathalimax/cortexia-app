@testable import Cortexia

extension ChatResponse {
	static let mock: ChatResponse = .init(
		id: "chatcmpl-9zkrGSMmZLHPgmZOJDxbtCYPR9tV7",
		object: "chat.completion",
		created: 1724505158,
		model: "gpt-4o-2024-05-13",
		choices: [
			.init(
				index: 0,
				message: .init(role: .assistant, content: "Hello! How can I assist you today?"),
				finishReason: "stop"
			)
		],
		usage: .init(
			promptTokens: 0,
			completionTokens: 0,
			totalTokens: 0
		)
	)

	static let missingChoices: ChatResponse = .init(
		id: "chatcmpl-9zkrGSMmZLHPgmZOJDxbtCYPR9tV7",
		object: "chat.completion",
		created: 1724505158,
		model: "gpt-4o-2024-05-13",
		choices: [],
		usage: .init(
			promptTokens: 0,
			completionTokens: 0,
			totalTokens: 0
		)
	)
}
