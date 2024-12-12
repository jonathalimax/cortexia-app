import Dependencies
import Foundation
import SwiftData

/// A service responsible for handling chat messages on database.
struct ChatService {
	/// Fetches all chat records from the database
	var fetchChats: () async throws -> [ChatMessage]

	/// Fetches messages for a specific chat, with optional pagination.
	/// - Parameters:
	///   - chatID: The identifier of the chat whose messages are to be fetched.
	///   - pagination: Optional pagination parameters to limit and offset the results.
	/// - Returns: An array of `MessageModel` objects.
	var fetchMessages: (_ chatID: String, _ pagination: Pagination?) async throws -> [ChatMessage]

	/// Saves a message to a specific chat.
	/// - Parameters:
	///   - chatID: The chatID of the message.
	///   - message: The message to be saved.
	/// - Returns: The saved `MessageModel` object.
	var saveMessage: @MainActor (_ chatID: String, _ message: Message) async throws -> Void

	/// Deletes a specific chat from the database.
	/// - Parameter chatID: The message chat id to be deleted
	var deleteChat: (_ chatID: String) async throws -> Void

	/// Removes all chat records from the database.
	var cleanHistory: () async throws -> Void

	/// A closure that checks whether a chat has been deleted.
	/// - Parameter chatID: The identifier of the chat to check.
	/// - Returns: A boolean indicating if the chat has been deleted.
	var isChatDeleted: (_ chatID: String) async throws -> Bool

	/// A closure that replaces the current message with a new message in a chat conversation.
	///
	/// - Parameters:
	///   - currentMessageID: The `Message` id that represents the current message which will be replaced.
	///   - newMessage: The `Message` instance that represents the new message to replace the current message with.
	var replaceMessage: (_ currentMessageID: String, _ newMessage: Message) async throws -> Void
}

// MARK: - Implementation
extension ChatService {
	static let live: Self = {
		@Dependency(\.uuid) var uuid
		@Dependency(\.date) var date
		@Dependency(\.logger) var logger
		@Dependency(\.databaseService) var databaseService

		return ChatService(
			fetchChats: {
				var descriptor = FetchDescriptor<ChatMessage>(
					sortBy: [SortDescriptor(\.sentAt, order: .reverse)]
				)

				descriptor.propertiesToFetch = [\.id, \.sentAt]

				let result = try await databaseService.fetch(descriptor)

				logger.info("💬 ChatService.fetchChats:: Stored chats fetched \(result)")

				return result
			},
			fetchMessages: { chatID, pagination in
				var descriptor = FetchDescriptor<ChatMessage>(
					predicate: #Predicate { $0.chatID == chatID },
					sortBy: [SortDescriptor(\.sentAt, order: .reverse)]
				)

				if let pagination {
					descriptor.fetchLimit = pagination.limit
					descriptor.fetchOffset = pagination.offset
				}

				let messages = try await databaseService.fetch(descriptor)

				logger.info("""
				💬 ChatService.fetchMessages:: Stored messages fetched for chatID: \(chatID),\ 
				within offset: \(pagination?.offset ?? 0) and limit: \(pagination?.limit ?? 0)
				Messages count: \(messages.count)\n
				"""
				)

				return messages.reversed()
			},
			saveMessage: { chatID, message in
				let date = date()
				let context = databaseService.modelContainer?.mainContext
				let message = ChatMessage(
					id: message.id,
					chatID: chatID,
					content: message.content,
					sentAt: date,
					sender: message.sender,
					tokens: message.tokens,
					costs: message.costs ?? .zero
				)

				context?.insert(message)

				try context?.save()

				logger.info(
					"""
					💬 ChatService.saveMessage:: Chat and messages stored successfully 
					with ID: \(message.id), chat id: \(chatID), date: \(date), sender: \(message.sender.rawValue)\n
					"""
				)
			},
			deleteChat: { chatID in
				var descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.chatID == chatID })
				let result = try await databaseService.fetch(descriptor)

				try databaseService.delete(result)

				logger.info(
					"""
					💬 ChatService.deleteChat:: Chat messages deleted successfully
					"""
				)
			},
			cleanHistory: {
				try await MainActor.run {
					let context = databaseService.modelContainer?.mainContext
					try context?.delete(model: ChatMessage.self)
				}

				logger.info("💬 ChatService.cleanHistory:: All chats were deleted\n")
			},
			isChatDeleted: { chatID in
				var descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.chatID == chatID })
				descriptor.fetchLimit = 1

				let chats = try await databaseService.fetch(descriptor)
				let isChatDeleted = chats.isEmpty

				logger.info("💬 ChatService.isChatDeleted:: Returns chat deletion status:\(isChatDeleted)\n")

				return isChatDeleted
			},
			replaceMessage: { currentMessageID, new in
				var descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.id == currentMessageID })
				descriptor.fetchLimit = 1

				if var message = try await databaseService.fetch(descriptor).first {
					message.id = new.id
					message.content = new.content
					message.tokens = new.tokens
					message.costs = new.costs ?? .zero

					try databaseService.save()
				}
				
			}
		)
	}()

	private static let mock: Self = {
		.init(
			fetchChats: { [] },
			fetchMessages: { _, _ in [] },
			saveMessage: { _, _ in },
			deleteChat: { _ in },
			cleanHistory: {},
			isChatDeleted: { _ in true },
			replaceMessage: { _, _ in }
		)
	}()
}

extension ChatService: DependencyKey {
	public static var liveValue: Self = .live
	public static var testValue: Self = .mock
}

extension DependencyValues {
	var chatService: ChatService {
		get { self[ChatService.self] }
		set { self[ChatService.self] = newValue }
	}
}
