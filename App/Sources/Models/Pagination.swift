/// A struct that represents pagination parameters for data retrieval, including the limit on the number of items and the current offset.
struct Pagination: Equatable {
	/// The maximum number of items to fetch per page.
	let limit: Int
	/// The current offset or starting point for the data retrieval.
	var offset: Int = .zero
	/// A flag indicating whether there are more items to fetch beyond the current page.
	var hasNext: Bool = true

	/// Resets the pagination parameters to their initial state.
	mutating func reset() {
		offset = .zero
	}
}
