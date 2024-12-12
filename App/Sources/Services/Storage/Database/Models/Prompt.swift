import Foundation
import SwiftData

@Model
class Prompt: Equatable {
	var id: UUID
	var text: String
	var createdAt: Date

	init(id: UUID, text: String, createdAt: Date) {
		self.id = id
		self.text = text
		self.createdAt = createdAt
	}
}
