import Foundation

struct MessageStreamResponse: Codable, Equatable {
	/// A unique identifier for the message.
	let id: String

	/// The timestamp of when the message was first created
	/// Represented in Unix epoch time format (seconds since January 1, 1970 at 00:00:00 UTC)
	let createdAt: Int

	/// An identifier for the thread to which the message belongs.
	let threadId: String

	/// The role of the message sender, which can be "system", "user", or "assistant".
	let role: Role

	/// The content of the message.
	let content: [Content]
}

extension MessageStreamResponse {
	struct Content: Codable, Equatable {
		/// The type of content. The only case currently defined is "text".
		let type: `Type`

		/// The text content of the message.
		let text: Text

		enum `Type`: String, Codable {
			/// A case representing text content.
			case text
		}

		struct Text: Codable, Equatable {
			/// The actual text value.
			let value: String
		}
	}
}
