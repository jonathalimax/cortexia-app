struct ThreadBody: Codable {
	/// An array of `MessageBody` objects representing the messages in the thread.
	let messages: [MessageBody]
}
