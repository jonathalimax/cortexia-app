import Foundation

@testable import Cortexia

class KeychainServiceStub {
	private var storage = [String: Any]()

	lazy var service: KeychainService = {
		return .init(
			save: { data, key in
				self.storage[key.rawValue] = data
			},
			load: { key in
				guard let data = self.storage[key.rawValue] as? Data else {
					throw KeychainService.Error.notFound
				}
				return data
			},
			delete: { key in
				self.storage.removeValue(forKey: key.rawValue)
			}
		)
	}()
}
