struct MessageBody: Codable {
	/// The role of the message sender, which can be either a `user` or `assistant`.
	let role: Role
	/// The content of the message, which is a `String`.
	let content: String
}
