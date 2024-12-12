enum HTTPHeader {
	case contentType(ContentType)
	case authorization(Authorization)
	case openAIBetaKey(String)
	case custom(key: String, value: String)

	var key: String {
		switch self {
		case .contentType: "Content-Type"
		case .authorization: "Authorization"
		case .openAIBetaKey: "OpenAI-Beta"
		case .custom(let key, _): key
		}
	}

	var value: String {
		switch self {
		case .contentType(let type): type.rawValue
		case .authorization(let auth): auth.rawValue
		case .openAIBetaKey(let version): version
		case .custom(_, let value): value
		}
	}
}

extension HTTPHeader {
	enum ContentType: String {
		case json = "application/json"
	}

	enum Authorization {
		case bearer(secretKey: String)

		var rawValue: String {
			switch self {
			case .bearer(let secretKey): "Bearer \(secretKey)"
			}
		}
	}
}

// MARK: - Helpers
extension [HTTPHeader] {
	static let `default`: Self = [
		.contentType(.json),
	]
}
