// MARK: - ModelResponse
struct ModelResponse: Codable, Equatable {
	let data: [Model]

	// MARK: - Model
	struct Model: Codable, Equatable, Identifiable {
		let id: String
		let ownedBy: String
	}
}
