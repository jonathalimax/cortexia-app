import Foundation
import ComposableArchitecture

extension PersistenceReaderKey {
	/// Creates a persistence key that can read and write to an integer user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<Int> {
		.appStorage(key.rawValue)
	}

	/// Creates a persistence key that can read and write to an optional integer user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<Int?> {
		.appStorage(key.rawValue)
	}

	/// Creates a persistence key that can read and write to an string user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<String> {
		.appStorage(key.rawValue)
	}

	/// Creates a persistence key that can read and write to an optional string user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<String?> {
		.appStorage(key.rawValue)
	}

	/// Creates a persistence key that can read and write to a boolean user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<Bool> {
		.appStorage(key.rawValue)
	}

	/// Creates a persistence key that can read and write to a optional boolean user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<Bool?> {
		.appStorage(key.rawValue)
	}

	/// Creates a persistence key that can read and write to a double user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<Double> {
		.appStorage(key.rawValue)
	}

	/// Creates a persistence key that can read and write to a optional double user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<Double?> {
		.appStorage(key.rawValue)
	}

	/// Creates a persistence key that can read and write to an optional integer user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<Data?> {
		.appStorage(key.rawValue)
	}

	/// Creates a persistence key that can read and write to an optional CompatibleOpenAIKey user default.
	///
	/// - Parameter key: The key to read and write the value to in the user defaults store.
	/// - Returns: A user defaults persistence key.
	public static func localStorage(_ key: LocalStorageKey) -> Self where Self == AppStorageKey<CompatibleOpenAIKey> {
		.appStorage(key.rawValue)
	}
}
