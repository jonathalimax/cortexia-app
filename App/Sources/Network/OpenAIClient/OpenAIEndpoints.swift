import Foundation

extension OpenAIClient {
	enum Endpoint: APIEndpoint {
		/// Available models for use with the OpenAI API
		case models
		/// Send a message to the API
		case chat
		/// Create an assistant that can call models and use tools to perform tasks
		case createAssistant
		/// Create thread that assistants can interact with
		case createThread
		/// Create messages within threads
		case createMessage(threadID: String)
		/// Retrieve a message
		case retrieveMessage(threadID: String, messageID: String)
		/// Create a run to perform certain tasks
		case createRun(threadID: String)
		/// Retrieves a run
		case retrieveRun(threadID: String, runID: String)
	}
}

// MARK: - Endpoint descriptor
extension OpenAIClient.Endpoint {
	var path: String {
		switch self {
		case .models: "models"
		case .chat: "chat/completions"
		case .createAssistant: "assistants"
		case .createThread: "threads"
		case .createMessage(let threadID): "threads/\(threadID)/messages"
		case .retrieveMessage(let threadID, let messageID): "/threads/\(threadID)/messages/\(messageID)"
		case .createRun(let threadID): "threads/\((threadID))/runs"
		case .retrieveRun(let threadID, let runID): "threads/\(threadID)/runs/\(runID)"
		}
	}

	var descriptor: EndpointDescriptor {
		switch self {
		case .models, .retrieveMessage, .retrieveRun:
			.init(version: .v1, method: .get)

		case .chat, .createAssistant, .createThread, .createMessage, .createRun:
			.init(version: .v1, method: .post)
		}
	}
}
