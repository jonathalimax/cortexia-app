import Foundation
import SwiftData

@Model
class ChatMessage: Equatable {
	/// A unique identifier for the message.
	@Attribute(.unique)
	var id: String
	/// The identifier of the chat to which the message belongs.
	var chatID: String
	/// The content of the message.
	var content: String
	/// The date and time when the message was sent.
	var sentAt: Date
	/// The role of the message sender (e.g., user or assistant).
	var sender: Role
	/// Number of tokens in the message
	var tokens: Int
	/// Costs in dollar based on tokens
	var costs: Double

	init(id: String, chatID: String, content: String, sentAt: Date, sender: Role, tokens: Int, costs: Double) {
		self.id = id
		self.chatID = chatID
		self.content = content
		self.sentAt = sentAt
		self.sender = sender
		self.tokens = tokens
		self.costs = costs
	}
}
