import Foundation

extension OllamaAIClient {
	enum Endpoint: APIEndpoint {
		case chat
	}
}

// MARK: - Endpoint descriptor
extension OllamaAIClient.Endpoint {
	var path: String {
		switch self {
		case .chat: "chat/completions"
		}
	}

	var descriptor: EndpointDescriptor {
		switch self {
		case .chat: .init(version: .v1, method: .post)
		}
	}
}
