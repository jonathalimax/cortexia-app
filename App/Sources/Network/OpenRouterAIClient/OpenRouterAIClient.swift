import Dependencies
import Foundation

struct OpenRouterAIClient {
	@Dependency(\.logger) private var logger

	private var request: (_ endpoint: Endpoint, _ body: Data?) async throws -> Data

	/// Makes a request to the OpenRouter API and decodes the response.
	///
	/// - Parameters:
	///   - endpoint: The API endpoint to send the request to.
	///   - body: The request body data, if any. Defaults to `nil`.
	/// - Returns: The decoded response from the API.
	/// - Throws: An error if the request or decoding fails.
	public func request<C: Codable>(_ endpoint: Endpoint, _ body: Data? = nil) async throws -> C {
		// Send the request to the specified endpoint with the provided body data.
		let response = try await request(endpoint, body)
		logger.info("💡 OllamaAI \(endpoint.logIdentifier) requested with response: \(response.prettyPrinted)")
		return try response.decoded()
	}
}

// MARK: - Live
extension OpenRouterAIClient {
	static var live: Self {
		@Dependency(\.networkService) var networkService
		@Dependency(\.keychainService) var keychainService

		return OpenRouterAIClient(
			request: { endpoint, body in
				// Build the base URL by appending the version and path components from the endpoint.
				let baseURL = try URLRequestBuilder.build(endpoint)

				// Retrieve secret key from keychain
				guard let secretKey: String = try? await keychainService.load(.openRouterSecretKey), !secretKey.isEmpty else {
					throw AIClientError.missingSecretKey
				}

				// Prepare HTTP headers with a bearer token for authorization.
				let headers: [HTTPHeader] = [
					.authorization(.bearer(secretKey: secretKey))
				]

				do {
					// Make an asynchronous network request using the URL, HTTP method, and headers.
					return try await networkService.request(baseURL, endpoint.descriptor.method, headers, body)
				} catch {
					if case let .statusCode(code) = error as? HTTPError, code == 401 { throw AIClientError.invalidSecretKey }
					throw error
				}
			}
		)
	}
}

// MARK: - Dependency Registration
extension OpenRouterAIClient: DependencyKey {
	static let liveValue: Self = .live
	static let testValue: Self = .init(request: { _, _ in Data() })
	static let previewValue: Self = .live
}

extension DependencyValues {
	var openRouterAIClient: OpenRouterAIClient {
		get { self[OpenRouterAIClient.self] }
		set { self[OpenRouterAIClient.self] = newValue }
	}
}
