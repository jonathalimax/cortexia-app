protocol APIEndpoint {
	var path: String { get }
	var descriptor: EndpointDescriptor { get }
	var logIdentifier: String { get }
}

extension APIEndpoint {
	var logIdentifier: String {
		"\(descriptor.method.rawValue.capitalized) /\(descriptor.version.rawValue)/\(path)"
	}
}
