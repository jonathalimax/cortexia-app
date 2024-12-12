import Dependencies
import Foundation

enum DeepLink: String {
	case baseURL = "base_url"
	case secretKey = "secret_key"
	case model

	static var schemaURL: String? {
		@Dependency(\.configurationService) var configurationService
		return try? configurationService.schemaURL()
	}

	var url: URL {
		guard let schema = DeepLink.schemaURL, let url = URL(string: "\(schema)://\(self.rawValue)") else {
			fatalError("Invalid URL for DeepLink: \(self.rawValue)")
		}

		return url
	}
}
