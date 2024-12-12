/// An enumeration representing various types of HTTP errors that can occur during network requests.
enum HTTPError: Error {
	/// Represents an invalid response from the server.
	case invalidResponse

	/// Represents an HTTP status code error.
	/// - Parameter code: The HTTP status code returned by the server.
	case statusCode(Int)

	/// Represents a network-related error.
	/// - Parameter error: The underlying network error that occurred.
	case network(Error)
}
