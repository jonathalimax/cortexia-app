import Dependencies
import Foundation

/// A service responsible for performing network requests.
struct NetworkService {
	/// Performs a network request.
	/// - Parameters:
	///   - url: The URL for the network request.
	///   - httpMethod: The HTTP method to use for the request (e.g., GET, POST).
	///   - headers: An array of HTTP headers to include in the request.
	///   - body: An optional data payload to include in the request body.
	/// - Returns: The data received from the network response.
	/// - Throws: An error if the network request fails or if the response is not valid.
	var request: (_ url: URL, _ httpMethod: HTTPMethod, _ headers: [HTTPHeader], _ body: Data?) async throws -> Data

	var stream: (_ url: URL, _ httpMethod: HTTPMethod, _ headers: [HTTPHeader], _ body: Data?) async throws -> URLSession.AsyncBytes
}

// MARK: - Network implementation
extension NetworkService {
	static func live(urlSession: URLSession = .shared) -> Self {
		@Dependency(\.logger) var logger

		return NetworkService(
			request: { url, method, headers, body in
				do {
					let request = buildRequest(url, method, headers, body)
					let (data, response) = try await urlSession.data(for: request)

					try handleResponse(response)
					logger.info("📦 Network response data: \(data.prettyPrinted)")

					return data

				} catch {
					throw parseError(error)
				}
			},
			stream: { url, method, headers, body in
				do {
					let request = buildRequest(url, method, headers, body)
					let (bytes, response) = try await urlSession.bytes(for: request)

					try handleResponse(response)

					return bytes
				} catch {
					throw parseError(error)
				}
			}
		)
	}

	private static func buildRequest(_ url: URL, _ method: HTTPMethod, _ headers: [HTTPHeader], _ body: Data?) -> URLRequest {
		@Dependency(\.logger) var logger

		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue
		request.setHeaders(headers)
		request.httpBody = body

		logger.info("🌏 Network request method: \(request.httpMethod ?? "empty")")
		logger.info("🌏 Network request url: \(request.url?.absoluteString ?? "empty")")
		logger.info("🌏 Network request body: \(request.httpBody?.prettyPrinted ?? "empty")")
		logger.info("🌏 Network request headers: \(request.allHTTPHeaderFields ?? [:])")

		return request
	}

	private static func handleResponse(_ response: URLResponse) throws {
		@Dependency(\.logger) var logger

		// Handle HTTP errors
		guard let httpResponse = response as? HTTPURLResponse else {
			throw HTTPError.invalidResponse
		}

		logger.info("📦 Network response status code: \(httpResponse.statusCode)")

		if !(200..<300).contains(httpResponse.statusCode) {
			throw HTTPError.statusCode(httpResponse.statusCode)
		}
	}

	private static func parseError(_ error: Error) -> Error {
		switch error {
		case HTTPError.invalidResponse: error
		case HTTPError.statusCode: error
		default: HTTPError.network(error)
		}
	}
}

// MARK: - Helpers
extension URLRequest {
	mutating func setHeaders(_ headers: [HTTPHeader]) {
		for header in [HTTPHeader].default + headers {
			self.setValue(header.value, forHTTPHeaderField: header.key)
		}
	}
}

// MARK: - Dependency registration
extension NetworkService: DependencyKey {
	static var liveValue: NetworkService = .live()
	static var testValue: NetworkService = .init(request: { _, _, _, _ in throw NSError() }, stream: { _, _, _, _ in throw NSError() })
	static var previewValue: NetworkService = .live()
}

extension DependencyValues {
	var networkService: NetworkService {
		get { self[NetworkService.self] }
		set { self[NetworkService.self] = newValue }
	}
}
