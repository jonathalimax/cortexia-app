struct ChatBody: Codable {
	let model: String
	let messages: [MessageBody]
	let temperature: Double
}
