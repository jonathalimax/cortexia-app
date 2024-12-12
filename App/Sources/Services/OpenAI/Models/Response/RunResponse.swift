struct RunResponse: Codable, Equatable {
	let id: String
	let status: Status

	enum Status: String, Codable {
		case completed, cancelled, failed, expired, incomplete
	}
}
