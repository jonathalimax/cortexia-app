struct Message: Identifiable, Equatable {
	var id: String
	var content: String
	let sender: Role
	let tokens: Int
	var costs: Double?

	init(id: String, content: String, sender: Role, tokens: Int = .zero, costs: Double? = nil) {
		self.id = id
		self.content = content
		self.sender = sender
		self.tokens = tokens
		self.costs = costs
	}
}
