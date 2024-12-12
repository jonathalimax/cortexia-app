import Foundation

@testable import Cortexia

extension MessageModel {
	static let mock: [MessageModel] = [
		.init(id: UUID(0), content: "Content", sentAt: Date(timeIntervalSince1970: 1), sender: .user),
		.init(id: UUID(1), content: "Response", sentAt: Date(timeIntervalSince1970: 2), sender: .assistant)
	]
}
