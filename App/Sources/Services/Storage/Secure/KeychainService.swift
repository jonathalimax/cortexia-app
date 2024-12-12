import Dependencies
import Foundation
import Security

/// A service for interacting with the iOS Keychain.
struct KeychainService {
	/// Saves data to the Keychain for a given key.
	/// - Parameters:
	///   - data: The data to be stored.
	///   - key: The key under which the data is stored.
	var save: (_ data: Data, _ key: KeychainKey) async throws -> Void

	/// Loads data from the Keychain for a given key.
	/// - Parameter key: The key under which the data is stored.
	/// - Returns: The data associated with the key.
	var load: (_ key: KeychainKey) async throws -> Data

	/// Deletes data from the Keychain for a given key.
	/// - Parameter key: The key under which the data is stored.
	var delete: (_ key: KeychainKey) async throws -> Void

	/// Errors that can occur during Keychain operations.
	enum Error: Swift.Error {
		case notFound
		case operationFailed
	}

	/// Loads and decodes data from the Keychain for a given key.
	///
	/// This function retrieves data stored in the Keychain and decodes it into the specified type.
	/// It uses the provided key to find the data and attempts to decode it using `JSONDecoder`.
	///
	/// - Parameter key: The key under which the data is stored in the Keychain.
	/// - Returns: The decoded data of the specified type.
	/// - Throws: An error if the data could not be found, decoded, or another Keychain operation error occurs.
	///
	/// - Note: The generic type `K` must conform to the `Codable` protocol.
	func load<K: Codable>(_ key: KeychainKey) async throws -> K {
		try JSONDecoder.shared.decode(K.self, from: await load(key))
	}

	/// Encodes and saves data to the Keychain for a given key.
	///
	/// This function encodes the provided value into a `Data` object using `JSONEncoder` and then saves it to the Keychain using the specified key.
	///
	/// - Parameters:
	///   - value: The value to be encoded and saved. It must conform to the `Codable` protocol.
	///   - key: The key under which the data will be stored in the Keychain.
	/// - Throws: An error if the value could not be encoded or if the Keychain operation fails.
	///
	/// - Note: The generic type `K` must conform to the `Codable` protocol.
	func save<K: Codable>(_ value: K, for key: KeychainKey) async throws -> Void {
		let data = try JSONEncoder.shared.encode(value)
		try await save(data, key)
	}
}

extension KeychainService {
	static let live: KeychainService = {
		return KeychainService(
			save: { data, key in
				// Create a query dictionary with the key and data to store in the Keychain
				let query: [String: Any] = [
					kSecClass as String: kSecClassGenericPassword,
					kSecAttrAccount as String: key.rawValue,
					kSecValueData as String: data
				]

				// Delete any existing item with the same key
				SecItemDelete(query as CFDictionary)

				// Add the new item to the Keychain
				let status = SecItemAdd(query as CFDictionary, nil)

				// Check the status and throw an error if the operation failed
				if status != errSecSuccess {
					throw Error.operationFailed
				}
			},
			load: { key in
				let query: [String: Any] = [
					kSecClass as String: kSecClassGenericPassword,
					kSecAttrAccount as String: key.rawValue,
					kSecReturnData as String: kCFBooleanTrue!,
					kSecMatchLimit as String: kSecMatchLimitOne
				]

				var dataTypeReference: AnyObject?

				// Search for the item in the Keychain
				let status = SecItemCopyMatching(query as CFDictionary, &dataTypeReference)

				// Check the status and throw an error if the item was not found
				guard status == errSecSuccess else { throw Error.notFound }

				// Cast the result to Data and throw an error if the format is invalid
				guard let data = dataTypeReference as? Data else { throw Error.operationFailed }

				return data
			},
			delete: { key in
				let query: [String: Any] = [
					kSecClass as String: kSecClassGenericPassword,
					kSecAttrAccount as String: key.rawValue
				]

				// Delete the item from the Keychain
				let status = SecItemDelete(query as CFDictionary)

				// Check the status and throw an error if the operation failed
				if status != errSecSuccess {
					throw Error.operationFailed
				}
			}
		)
	}()

	private static let mock: KeychainService = {
		.init(
			save: {_, _ in throw Error.operationFailed },
			load: { _ in throw Error.notFound },
			delete: { _ in throw Error.operationFailed }
		)
	}()
}

// MARK: - Dependency Registration
extension KeychainService: DependencyKey {
	static let liveValue: KeychainService = .live
	static let testValue: KeychainService = .mock
	static let previewValue: KeychainService = .live
}

extension DependencyValues {
	var keychainService: KeychainService {
		get { self[KeychainService.self] }
		set { self[KeychainService.self] = newValue }
	}
}
