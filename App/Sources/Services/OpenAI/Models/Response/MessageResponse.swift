struct MessageResponse: Codable, Equatable {
	/// A unique identifier for the message response.
	let id: String
	/// Model used to generate the output.
	let model: String
	/// The timestamp of when the message was first created
	/// Represented in Unix epoch time format (seconds since January 1, 1970 at 00:00:00 UTC)
	let createdAt: Int?
	/// An array of `Choice` objects, representing the possible choices or completions in response to the user's input.
	let choices: [Choice]
	/// Usage statistics for the completion request
	let usage: Usage
}

extension MessageResponse {
	struct Choice: Codable, Equatable {
		/// The message content associated with this choice.
		let message: ChoiceMessage
	}

	struct ChoiceMessage: Codable, Equatable {
		/// The textual content of the message.
		let content: String
		/// The role of the message sender, such as user or assistant.
		let role: Role
	}

	struct Usage: Codable, Equatable {
		/// Number of tokens in the generated completion
		let completionTokens: Int
		/// Number of tokens in the prompt
		let promptTokens: Int
	}
}
