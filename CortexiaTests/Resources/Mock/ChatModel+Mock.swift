import Foundation
@testable import Cortexia

extension ChatModel {
	static let mock: [ChatModel] = [
		.init(id: UUID(1), startAt: Date(timeIntervalSince1970: 1)),
		.init(id: UUID(2), startAt: Date(timeIntervalSince1970: 2)),
	]
}
