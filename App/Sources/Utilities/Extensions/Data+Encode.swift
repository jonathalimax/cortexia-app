import Foundation

extension JSONEncoder {
	/// A shared instance of `JSONEncoder` configured with a key encoding strategy to convert keys from camelCase to snake_case.
	///
	/// This instance is used for consistent encoding of keys according to the specified strategy.
	///
	/// - Returns: A `JSONEncoder` instance with `keyEncodingStrategy` set to `.convertToSnakeCase`.
	static let shared: JSONEncoder = {
		let encoder = JSONEncoder()
		// Set the key encoding strategy to convert camelCase keys to snake_case
		encoder.keyEncodingStrategy = .convertToSnakeCase
		return encoder
	}()
}

extension Encodable {
	/// Encodes the current instance to JSON `Data` using the shared `JSONEncoder` instance.
	///
	/// This method utilizes the shared `JSONEncoder` configured with `keyEncodingStrategy` to ensure keys are encoded in snake_case.
	///
	/// - Returns: The encoded `Data` representation of the instance, or `nil` if encoding fails.
	/// - Throws: An error if the encoding process fails.
	func encoded() throws -> Data? {
		// Use the shared JSONEncoder to encode the instance
		try JSONEncoder.shared.encode(self)
	}
}
