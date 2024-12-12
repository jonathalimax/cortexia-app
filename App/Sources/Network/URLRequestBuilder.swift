import Dependencies
import Foundation

enum URLRequestBuilder {
	@Dependency(\.defaultAppStorage) private static var appStorage
	@Dependency(\.configurationService) private static var configurationService

	enum Error: Swift.Error {
		case missingBaseURL
	}

	static func build(_ endpoint: APIEndpoint) throws -> URL {
		try retrieveBaseURL()
			.appendingPathComponent(endpoint.descriptor.version.rawValue)
			.appendingPathComponent(endpoint.path)
	}

	private static func retrieveBaseURL() throws -> URL {
		// Retrieve the selected API key from appStorage using a predefined key
		// If no API is selected, default to .openAI
		let selectedAPI = appStorage.string(forKey: .selectedAPI)
		let selectedAPIKey = CompatibleOpenAIKey(rawValue: selectedAPI ?? "") ?? .openAI

		// Determine the environment variable key based on the selected API
		switch selectedAPIKey {
		case .openAI:
			return try configurationService.openAIBaseURL()

		case .openRouter:
			return try configurationService.openRouterBaseURL()

		case .ollama:
			// If using Ollama, retrieve the URL from appStorage
			guard let value = appStorage.string(forKey: .ollamaBaseURL), let url = URL(string: value) else {
				throw Error.missingBaseURL
			}

			return url
		}
	}
}
