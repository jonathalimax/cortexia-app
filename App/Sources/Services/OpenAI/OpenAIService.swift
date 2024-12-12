import Dependencies
import Foundation
import SwiftData

typealias MessageStream = AsyncThrowingStream<(MessageStreamResponse, OpenAIIdentifiers), Swift.Error>

/// A service for interacting with OpenAI's API to fetch chat completions and available models.
struct OpenAIService {
	/// Fetches the list of available models from the OpenAI API.
	///
	/// - Parameters:
	///   - forceRemote: When enabled fetches from API directly instead looking locally
	///
	/// - Returns: A `ModelResponse` containing the list of models.
	var fetchModels: (_ forceRemote: Bool) async throws -> ModelResponse

	/// Sends a message to the selected compatible Open API within a specific thread and receives a response.
	///
	/// - Parameters:
	///   - message: A `String` containing the message content to be sent to the OpenAI API.
	///   - model: The model used to generate the response.
	///   - identifiers: Tuple contain assistant and thread id, meaning the chat was already started.
	///
	/// - Returns: A `MessageStreamResponse` object containing the response from the OpenAI API. This includes details about the model's reply to the provided message.
	/// ```
	var chatStream: (_ message: String, _ modelID: String, _ identifiers: OpenAIIdentifiers?) async throws -> MessageStream

	/// Sends a message to the selected compatible Open API.
	///
	/// - Parameters:
	///   - message: A `String` containing the message content to be sent to the OpenAI API.
	///   - model: The model used to generate the response.
	///   - chatID: Chat ID
	///
	/// - Returns: A `MessageStreamResponse` object containing the response from the OpenAI API. This includes details about the model's reply to the provided message.
	/// ```
	var chat: (_ message: String, _ modelID: String, _ chatID: String) async throws -> MessageResponse
}

extension OpenAIService {
	static var live: Self {
		@Dependency(\.logger) var logger
		@Dependency(\.chatService) var chatService
		@Dependency(\.openAIClient) var openAIClient
		@Dependency(\.ollamaAIClient) var ollamaAIClient
		@Dependency(\.databaseService) var databaseService
		@Dependency(\.defaultAppStorage) var appStorage
		@Dependency(\.openRouterAIClient) var openRouterAIClient

		return OpenAIService(
			fetchModels: { forceRemote in
				logger.info("OpenAIService.fetchModels:: Fetching models with forceRemote enabled: \(forceRemote)")

				if !forceRemote {
					let descriptor = FetchDescriptor<GenerativeAIModel>(sortBy: [SortDescriptor(\.id)])

					// Return models if it's storage locally
					if let models = try? await databaseService.fetch(descriptor), !models.isEmpty {
						let data = models.map { ModelResponse.Model(id: $0.id, ownedBy: $0.owner) }
						logger.info("OpenAIService.fetchModels:: Returning database models")
						return .init(data: data)
					}
				}

				let response: ModelResponse = try await openAIClient.request(.models)

				// Map the fetched model data to GenerativeAIModel instances
				let generativeAIModels = response.data
					.map { GenerativeAIModel(id: $0.id, owner: $0.ownedBy) }

				// Insert the mapped models into the database in a batch operation
				try await databaseService.insert(generativeAIModels)

				logger.info("OpenAIService.fetchModels:: Models fetched from OpenAI API and stored in the database")

				return response
			},
			chatStream: { message, modelID, aiIdentifiers in
				logger.info("OpenAIService.streamMessage:: Sending message and listen to the response stream")

				let identifiers: OpenAIIdentifiers

				if let aiIdentifiers {
					// Use identifiers in case the chat already started
					identifiers = aiIdentifiers
				} else {
					// Create assistant and thread
					let assistantBody = try AssistantBody(model: modelID).encoded()
					let assistant: GenericResponse = try await openAIClient.request(.createAssistant, assistantBody)
					let thread: GenericResponse = try await openAIClient.request(.createThread)

					identifiers = .init(assistantID: assistant.id, threadID: thread.id)
				}

				return AsyncThrowingStream { continuation in
					Task {
						do {
							let messageBody = try MessageBody(role: .user, content: message).encoded()
							let message: MessageStreamResponse = try await openAIClient.request(.createMessage(threadID: identifiers.threadID), messageBody)

							// Yield the initial response from the server
							continuation.yield((message, identifiers))

							let runBody = try RunBody(assistantId: identifiers.assistantID ?? "", stream: true).encoded()
							let runStream = try await openAIClient.stream(.createRun(threadID: identifiers.threadID), runBody)

							// Flag to track when the run stream is completed
							var isCompleted = false

							for try await line in runStream.lines {
								// Parse each line into a usable data structure
								if let data = OpenAIService.parseLine(line) {
									// If the stream has completed and we have a valid value, decode the final response
									if isCompleted, let value = data.value.data(using: .utf8) {
										let response = try JSONDecoder.shared.decode(MessageStreamResponse.self, from: value)

										// Yield the final response and finish the stream
										continuation.yield((response, identifiers))
										continuation.finish()
										continue
									}

									// Handle different run events, such as completion or done signals
									switch RunEvent(rawValue: data.value) {
									case .completed:
										isCompleted = true
										continue

									case .done:
										// Finish the stream when the run is marked as done
										continuation.finish()

									case .none:
										// Continue for any unrecognized event
										continue
									}
								}
							}
						} catch {
							// Finish the stream if an error occurs
							continuation.finish(throwing: error)
						}
					}
				}
			},
			chat: { message, model, chatID in
				logger.info("OpenAIService.sendMessage:: Sending the following message \(message) within the following model \(model)")

				let selectedAPI = appStorage.string(forKey: .selectedAPI) ?? ""
				let temperature = appStorage.double(forKey: .selectedTemperature) ?? 1.0

				let messageHistory: [MessageBody] = if let messages = try? await chatService.fetchMessages(chatID, nil) {
					messages.filter { $0.sender != .system }
						.map { MessageBody(role: $0.sender, content: $0.content) }
				} else {
					[]
				}

				let body = try ChatBody(model: model, messages: messageHistory, temperature: temperature)
					.encoded()

				let compatibleOpenAI = CompatibleOpenAIKey(rawValue: selectedAPI)

				logger.info("OpenAIService.sendMessage using \(compatibleOpenAI?.name ?? "OpenAI") within body:: \(body?.prettyPrinted ?? "none")")

				return switch compatibleOpenAI {
				case .ollama: try await ollamaAIClient.request(.chat, body)
				case .openRouter: try await openRouterAIClient.request(.chat, body)
				case .none, .openAI: try await openAIClient.request(.chat, body)
				}
			}
		)
	}

	private static var mock: Self {
		.init(
			fetchModels: { _ in throw HTTPError.invalidResponse },
			chatStream: { _, _, _ in throw HTTPError.invalidResponse },
			chat: { _, _, _ in throw HTTPError.invalidResponse }
		)
	}

	enum RunEvent: String, Codable {
		case completed = "thread.message.completed"
		case done = "done"
	}

	/// Function to parse the input string
	private static func parseLine(_ string: String) -> (key: String, value: String)? {
		let dataPrefix = "data: "
		let eventPrefix = "event: "

		if string.hasPrefix(dataPrefix) {
			let value = String(string.dropFirst(dataPrefix.count)).trimmingCharacters(in: .whitespaces)
			return (key: "data", value: value)
		} else if string.hasPrefix(eventPrefix) {
			let value = String(string.dropFirst(eventPrefix.count)).trimmingCharacters(in: .whitespaces)
			return (key: "event", value: value)
		} else {
			return nil
		}
	}
}

extension OpenAIService {
	enum Error: Swift.Error {
		case missingModels
		case invalidMessage
	}
}

// MARK: - Dependency Registration
extension OpenAIService: DependencyKey {
	static var liveValue: OpenAIService = .live
	static var testValue: OpenAIService = .mock
	static var previewValue: OpenAIService = .live
}

extension DependencyValues {
	var openAIService: OpenAIService {
		get { self[OpenAIService.self] }
		set { self[OpenAIService.self] = newValue }
	}
}
