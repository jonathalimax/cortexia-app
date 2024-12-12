import SwiftData

@Model
class GenerativeAIModel: Equatable {
	@Attribute(.unique)
	var id: String
	var owner: String

	init(id: String, owner: String) {
		self.id = id
		self.owner = owner
	}
}
