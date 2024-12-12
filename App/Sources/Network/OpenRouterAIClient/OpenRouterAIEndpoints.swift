import Foundation

extension OpenRouterAIClient {
	enum Endpoint: APIEndpoint {
		case chat
	}
}

// MARK: - Endpoint descriptor
extension OpenRouterAIClient.Endpoint {
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
