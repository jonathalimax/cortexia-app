import Dependencies
import Foundation

/// A client for interacting with the OpenAI API.
struct OpenAIClient {
	@Dependency(\.logger) private var logger

	private var request: (_ endpoint: Endpoint, _ body: Data?) async throws -> Data
	var stream: (_ endpoint: Endpoint, _ body: Data?) async throws -> URLSession.AsyncBytes

	/// Makes a request to the OpenAI API and decodes the response.
	///
	/// - Parameters:
	///   - endpoint: The API endpoint to send the request to.
	///   - body: The request body data, if any. Defaults to `nil`.
	/// - Returns: The decoded response from the API.
	/// - Throws: An error if the request or decoding fails.
	public func request<C: Codable>(_ endpoint: Endpoint, _ body: Data? = nil) async throws -> C {
		// Send the request to the specified endpoint with the provided body data.
		let response = try await request(endpoint, body)
		logger.info("💡 OpenAI \(endpoint.logIdentifier) requested with response: \(response.prettyPrinted)")
		return try response.decoded()
	}
}

// MARK: - Live
extension OpenAIClient {
	static var live: Self {
		@Dependency(\.networkService) var networkService
		@Dependency(\.keychainService) var keychainService
		@Dependency(\.reachabilityService) var reachabilityService
		@Dependency(\.configurationService) var configurationService

		return OpenAIClient(
			request: { endpoint, body in
				// Verify network connection first
				guard case .connected = reachabilityService.status else {
					throw ReachabilityService.Error.noConnection
				}

				// Build the base URL by appending the version and path components from the endpoint.
				let baseURL = try URLRequestBuilder.build(endpoint)

				// Retrieve openAI secret key from keychain
				guard let storedSecretKey: String = try? await keychainService.load(.openAISecretKey), !storedSecretKey.isEmpty else {
					throw AIClientError.missingSecretKey
				}

				// Prepare HTTP headers with a bearer token for authorization.
				let headers: [HTTPHeader] = [
					.authorization(.bearer(secretKey: storedSecretKey)),
					.openAIBetaKey("assistants=v2")
				]

				do {
					// Make an asynchronous network request using the URL, HTTP method, and headers.
					return try await networkService.request(baseURL, endpoint.descriptor.method, headers, body)
				} catch {
					if case let .statusCode(code) = error as? HTTPError, code == 401 { throw AIClientError.invalidSecretKey }
					throw error
				}
			},
			stream: { endpoint, body in
				// Build the base URL by appending the version and path components from the endpoint.
				var baseURL = try configurationService.openAIBaseURL()
				baseURL = baseURL.appendingPathComponent(endpoint.descriptor.version.rawValue)
				baseURL = baseURL.appendingPathComponent(endpoint.path)

				// Retrieve openAI secret key from keychain
				guard let storedSecretKey: String = try? await keychainService.load(.openAISecretKey), !storedSecretKey.isEmpty else {
					throw AIClientError.missingSecretKey
				}

				// Prepare HTTP headers with a bearer token for authorization.
				let headers: [HTTPHeader] = [
					.authorization(.bearer(secretKey: storedSecretKey)),
					.openAIBetaKey("assistants=v2")
				]

				do {
					return try await networkService.stream(baseURL, endpoint.descriptor.method, headers, body)
				} catch {
					if case let .statusCode(code) = error as? HTTPError, code == 401 { throw AIClientError.invalidSecretKey }
					throw error
				}
			}
		)
	}
}

// MARK: - Dependency Registration
extension OpenAIClient: DependencyKey {
	static let liveValue: Self = .live
	static let testValue: Self = .init(request: { _, _ in Data() }, stream: { _, _ in throw NSError() })
	static let previewValue: Self = .live
}

extension DependencyValues {
	var openAIClient: OpenAIClient {
		get { self[OpenAIClient.self] }
		set { self[OpenAIClient.self] = newValue }
	}
}
