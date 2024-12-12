import Foundation

extension JSONDecoder {
	/// A shared JSONDecoder instance configured with a key decoding strategy.
	///
	/// This extension provides a pre-configured instance of `JSONDecoder` with a `keyDecodingStrategy`
	/// set to `.convertFromSnakeCase`. This strategy allows for the automatic conversion of JSON keys
	/// from snake_case to camelCase, which is useful when decoding JSON data that follows different naming conventions.
	///
	/// - Returns: A `JSONDecoder` instance configured with `.convertFromSnakeCase` key decoding strategy.
	static let shared: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}()
}

extension Data {
	/// Decodes the data into a specified `Decodable` type.
	///
	/// This extension provides a convenient method to decode `Data` into a model that conforms to the `Decodable` protocol.
	/// It uses the `JSONDecoder.shared` instance for decoding, which has been configured to handle JSON keys with
	/// different naming conventions by converting from snake_case to camelCase.
	///
	/// - Returns: An optional instance of the specified type `T` if decoding is successful; `nil` if decoding fails.
	///
	/// - Parameter T: The type to decode the data into. This type must conform to the `Decodable` protocol.
	func decoded<T: Decodable>() throws -> T {
		return try JSONDecoder.shared.decode(T.self, from: self)
	}
}
