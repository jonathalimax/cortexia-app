/// An enumeration representing the versioning of the OpenAI API.
enum EndpointVersion: String {
	case v1
}

/// Describes the API endpoint details, including the version and HTTP method.
struct EndpointDescriptor {
	/// The version of the API being used.
	let version: EndpointVersion

	/// The HTTP method used for the request.
	let method: HTTPMethod

	/// Initializes a new instance of the Descriptor struct.
	///
	/// - Parameters:
	///   - version: The version of the API to use for the request. Defaults to `.v1`.
	///   - method: The HTTP method to use for the request.
	init(version: EndpointVersion = .v1, method: HTTPMethod) {
		self.version = version
		self.method = method
	}
}
