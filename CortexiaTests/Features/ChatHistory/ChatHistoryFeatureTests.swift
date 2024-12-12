import ComposableArchitecture
import Testing

@testable import Cortexia

@MainActor
struct ChatHistoryFeatureTests {
	@Test
	func onFirstAppear() async throws {
		let store = makeStore()

		store.dependencies.chatService.fetchChats = { ChatModel.mock }

		await store.send(.view(.onFirstAppear))

		await store.receive(.internal(.chatsFetched(ChatModel.mock)), timeout: 1) {
			$0.chats = ChatModel.mock
		}
	}

	@Test
	func clearHistoryButtonTapped() async throws {
		let store = makeStore()

		await store.send(.view(.clearHistoryButtonTapped)) {
			$0.destination = .clearHistory
		}
	}

	@Test
	func deleteButtonTapped() async throws {
		var deleteChatCalled = false
		let store = makeStore()

		store.dependencies.chatService.fetchChats = { ChatModel.mock }
		store.dependencies.chatService.deleteChat = { _ in deleteChatCalled = true }

		await store.send(.view(.deleteButtonTapped(ChatModel.mock.first!)))

		await store.receive(.internal(.chatsFetched(ChatModel.mock)), timeout: 1) {
			$0.chats = ChatModel.mock
		}

		#expect(deleteChatCalled == true)
	}

	@Test
	func clearHistoryConfirmationTapped() async throws {
		var clearHistoryCalled = false
		let store = makeStore()

		store.dependencies.chatService.fetchChats = { ChatModel.mock }
		store.dependencies.chatService.cleanHistory = { clearHistoryCalled = true }

		await store.send(.view(.clearHistoryConfirmationTapped))

		await store.receive(.internal(.chatsFetched(ChatModel.mock)), timeout: 1) {
			$0.chats = ChatModel.mock
		}

		#expect(clearHistoryCalled == true)
	}

	@Test
	func selectChat() async throws {
		let selectedChat = ChatModel.mock.first!
		let store = makeStore(selectedChat: selectedChat)

		await store.send(.binding(.set(\.selectedChat, selectedChat))) {
			$0.destination = .newChat(
				.init(
					chatID: .init(1),
					viewState: .ready,
					isChatFocused: false,
					hasTopBarItems: false
				)
			)
		}
	}
}

extension ChatHistoryFeatureTests {
	private func makeStore(selectedChat: ChatModel? = nil) -> TestStoreOf<ChatHistoryFeature> {
		.init(
			initialState: .init(selectedChat: selectedChat),
			reducer: { ChatHistoryFeature() }
		)
	}
}
