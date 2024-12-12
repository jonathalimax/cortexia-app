import Foundation

struct Chat: Hashable {
	let id: String
	let date: Date

	var displayDate: String {
		date.formatted(date: .abbreviated, time: .shortened)
	}
}
