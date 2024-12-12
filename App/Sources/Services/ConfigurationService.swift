import Foundation
import Dependencies

/// A service that provides configuration settings for the application.
///
/// `ConfigurationService` is responsible for retrieving configuration values, such as URLs, from the application's environment or configuration files.
///
/// - Note: The `ConfigurationService` uses environment variables or configuration files to obtain its settings.
struct ConfigurationService {
	/// Returns the base URL for OpenAI.
	var openAIBaseURL: () throws -> URL
	/// Returns the base URL for OpenRouter.
	var openRouterBaseURL: () throws -> URL
	/// Scheme URL for deep links
	var schemaURL: () throws -> String
}

extension ConfigurationService {
	enum Error: Swift.Error {
		case missingEnvironmentVariable(String)
		case invalidURL(String)
		case missingSchemaURL
	}
}

extension ConfigurationService {
	static let live: Self = ConfigurationService(
		openAIBaseURL: {
			let urlKey = "OPENAI_BASE_URL"
			guard let urlString = Bundle.main.infoDictionary?[urlKey] as? String else { throw Error.missingEnvironmentVariable(urlKey) }
			guard let url = URL(string: urlString) else { throw Error.invalidURL(urlString) }
			return url
		},
		openRouterBaseURL: {
			let urlKey = "OPENROUTER_BASE_URL"
			guard let urlString = Bundle.main.infoDictionary?[urlKey] as? String else { throw Error.missingEnvironmentVariable(urlKey) }
			guard let url = URL(string: urlString) else { throw Error.invalidURL(urlString) }
			return url
		},
		schemaURL: {
			let urlKey = "CFBundleURLTypes"
			guard
				let urlTypes = Bundle.main.infoDictionary?[urlKey] as? [[String: Any]],
				let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String],
				let scheme = urlSchemes.first
			else { throw Error.missingSchemaURL }

			return scheme
		}
	)
}

// MARK: - Dependency Registration
extension ConfigurationService: DependencyKey {
	static var liveValue: Self = .live
}

extension DependencyValues {
	var configurationService: ConfigurationService {
		get { self[ConfigurationService.self] }
		set { self[ConfigurationService.self] = newValue }
	}
}
