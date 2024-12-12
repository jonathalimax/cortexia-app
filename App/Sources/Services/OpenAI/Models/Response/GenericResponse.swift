struct GenericResponse: Codable, Equatable {
	/// A unique identifier for the thread.
	let id: String

	/// The timestamp of when the resource was first created
	/// Represented in Unix epoch time format (seconds since January 1, 1970 at 00:00:00 UTC)
	let createdAt: Int
}
