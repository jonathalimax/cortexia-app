import Foundation

extension UserDefaults {
	func string(forKey key: LocalStorageKey) -> String? {
		string(forKey: key.rawValue)
	}

	func double(forKey key: LocalStorageKey) -> Double? {
		double(forKey: key.rawValue)
	}
}
