import SwiftData
@testable import Cortexia

class DatabaseServiceSpy: DatabaseService {
	var log = [Operation]()

	enum Operation: Equatable {
		case insert([any PersistentModel])

		static func ==(lhs: Operation, rhs: Operation) -> Bool {
			switch (lhs, rhs) {
			case (.insert(let lhs), .insert(let rhs)):
				lhs.map(\.hashValue) == rhs.map(\.hashValue)
			}
		}
	}

	override func insert<P>(_ values: [P]) async throws where P : PersistentModel {
		log.append(.insert(values))
	}
}
