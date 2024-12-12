import ComposableArchitecture
import Foundation
import Testing

@testable import Cortexia

@MainActor
struct ChatFeatureTests {
	@Test
	func onAppear() async throws {
		let store = makeStore()

		await store.send(.view(.onAppear))
	}

	@Test
	func onAppearWithChatDeleted() async throws {
		let store = makeStore(chatID: UUID(1))

		store.dependencies.chatService.isChatDeleted = { _ in true }

		await store.send(.view(.onAppear))

		await store.receive(.internal(.chatDeleted), timeout: 1) {
			$0.viewState = .newChat
			$0.chatID = nil
			$0.messages = []
			$0.inputText = ""
			$0.pagination.offset = .zero
		}
	}
	
	@Test
	func onAppearWithoutSelectedChat() async throws {
		let store = makeStore()

		await store.send(.view(.onAppear))
	}

	@Test
	func onFirstAppear() async throws {
		let store = makeStore(chatID: UUID(0))

		store.dependencies.chatService.fetchMessages = { _, _ in MessageModel.mock }

		await store.send(.view(.onFirstAppear))

		await store.receive(.internal(.messagesFetched(MessageModel.mock)), timeout: 1) {
			$0.messages = .init(uncheckedUniqueElements: MessageModel.mock)
			$0.focusedMessage = MessageModel.mock[1]
			$0.pagination.offset = 2
		}
	}

	@Test
	func onFirstAppearWithoutChatId() async throws {
		let store = makeStore()

		store.dependencies.chatService.fetchMessages = { _, _ in MessageModel.mock }

		await store.send(.view(.onFirstAppear))
	}

	@Test
	func sendButtonTappedWithoutInputText() async throws {
		let store = makeStore()

		await store.send(.view(.sendButtonTapped))
	}

	@Test
	func sendButtonTappedMissingSecretKey() async throws {
		let store = makeStore()

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.missingSecretKey), timeout: 1) {
			$0.alert = .init(
				title: { TextState("Oops! Missing Your OpenAI Secret Key") },
				actions: {
					ButtonState(role: .cancel) {
						TextState("Cancel")
					}

					ButtonState(action: .confirmButtonTapped(.missingSecretKey)) {
						TextState("Confirm")
					}
				},
				message: { TextState("Please click \"Confirm\" and you’ll be redirected to add your key") }
			)
		}
	}

	@Test
	func sendButtonTappedEmptySecretKey() async throws {
		let store = makeStore()

		store.dependencies.keychainService.load = { _ in try! JSONEncoder.shared.encode("") }

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.missingSecretKey), timeout: 1) {
			$0.alert = .init(
				title: { TextState("Oops! Missing Your OpenAI Secret Key") },
				actions: {
					ButtonState(role: .cancel) {
						TextState("Cancel")
					}

					ButtonState(action: .confirmButtonTapped(.missingSecretKey)) {
						TextState("Confirm")
					}
				},
				message: { TextState("Please click \"Confirm\" and you’ll be redirected to add your key") }
			)
		}
	}

	@Test
	func sendButtonTappedMissingSecretKeyConfirmTapped() async throws {
		let store = makeStore()

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.missingSecretKey), timeout: 1) {
			$0.alert = .init(
				title: { TextState("Oops! Missing Your OpenAI Secret Key") },
				actions: {
					ButtonState(role: .cancel) {
						TextState("Cancel")
					}

					ButtonState(action: .confirmButtonTapped(.missingSecretKey)) {
						TextState("Confirm")
					}
				},
				message: { TextState("Please click \"Confirm\" and you’ll be redirected to add your key") }
			)
		}

		await store.send(.alert(.presented(.confirmButtonTapped(.missingSecretKey)))) {
			$0.alert = nil
			$0.destination = .settings(SettingsFeature.State(focusedField: .secretKey))
		}
	}

	@Test
	func sendButtonTappedMissingModelID() async throws {
		let store = makeStore()

		store.dependencies.keychainService.load = { _ in try! JSONEncoder.shared.encode("secretKey") }

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.missingModelID), timeout: 1) {
			$0.alert = .init(
				title: { TextState("Action Required: Select a Model") },
				actions: {
					ButtonState(role: .cancel) {
						TextState("Cancel")
					}

					ButtonState(action: .confirmButtonTapped(.missingModel)) {
						TextState("Confirm")
					}
				},
				message: { TextState("Please click \"Confirm\" and you’ll be redirected to select the model you want to use") }
			)
		}
	}

	@Test
	func sendButtonTappedMissingModelIDConfirmButtonTapped() async throws {
		let store = makeStore()

		store.dependencies.keychainService.load = { _ in try! JSONEncoder.shared.encode("secretKey") }

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.missingModelID), timeout: 1) {
			$0.alert = .init(
				title: { TextState("Action Required: Select a Model") },
				actions: {
					ButtonState(role: .cancel) {
						TextState("Cancel")
					}

					ButtonState(action: .confirmButtonTapped(.missingModel)) {
						TextState("Confirm")
					}
				},
				message: { TextState("Please click \"Confirm\" and you’ll be redirected to select the model you want to use") }
			)
		}

		await store.send(.alert(.presented(.confirmButtonTapped(.missingModel)))) {
			$0.alert = nil
			$0.destination = .settings(SettingsFeature.State())
		}
	}

	@Test
	func sendButtonTappedSaveSendMessageError() async throws {
		let store = makeStore()

		store.dependencies.uuid = .incrementing
		store.dependencies.defaultAppStorage.set("model", forKey: "selectedModelID")
		store.dependencies.keychainService.load = { _ in try! JSONEncoder.shared.encode("secretKey") }

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.receiveMessageFailed), timeout: 1) {
			$0.viewState = .ready
			$0.alert = .init(
				title: { TextState("Something Went Wrong") },
				message: { TextState("Please try again") }
			)
		}
	}

	@Test
	func sendButtonTappedChatCompletionRequestError() async throws {
		let store = makeStore()

		store.dependencies.uuid = .incrementing
		store.dependencies.chatService.saveMessage = { _, _, _ in MessageModel.mock[0] }
		store.dependencies.defaultAppStorage.set("model", forKey: "selectedModelID")
		store.dependencies.keychainService.load = { _ in try! JSONEncoder.shared.encode("secretKey") }

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.sentMessageSaved(UUID(0), MessageModel.mock[0])), timeout: 1) {
			$0.chatID = UUID(0)
			$0.messages = .init(uncheckedUniqueElements: [MessageModel.mock[0]])
			$0.inputText = ""
			$0.viewState = .loading
		}

		await store.receive(.internal(.receiveMessageFailed), timeout: 1) {
			$0.viewState = .ready
			$0.alert = .init(
				title: { TextState("Something Went Wrong") },
				message: { TextState("Please try again") }
			)
		}
	}

	@Test
	func sendButtonTappedChatCompletionMissingChoiceError() async throws {
		let store = makeStore()

		store.dependencies.uuid = .incrementing
		store.dependencies.openAIService.chatCompletions = { _, _ in ChatResponse.missingChoices }
		store.dependencies.chatService.saveMessage = { _, _, _ in MessageModel.mock[0] }
		store.dependencies.defaultAppStorage.set("model", forKey: "selectedModelID")
		store.dependencies.keychainService.load = { _ in try! JSONEncoder.shared.encode("secretKey") }

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.sentMessageSaved(UUID(0), MessageModel.mock[0])), timeout: 1) {
			$0.chatID = UUID(0)
			$0.messages = .init(uncheckedUniqueElements: [MessageModel.mock[0]])
			$0.inputText = ""
			$0.viewState = .loading
		}

		await store.receive(.internal(.receiveMessageFailed), timeout: 1) {
			$0.viewState = .ready
			$0.alert = .init(
				title: { TextState("Something Went Wrong") },
				message: { TextState("Please try again") }
			)
		}
	}

	@Test
	func sendButtonTappedHappyPath() async throws {
		let store = makeStore()

		store.dependencies.uuid = .incrementing
		store.dependencies.openAIService.chatCompletions = { _, _ in .mock }
		store.dependencies.chatService.saveMessage = { _, _, sender in MessageModel.mock[sender == .user ? 0 : 1] }
		store.dependencies.defaultAppStorage.set("model", forKey: "selectedModelID")
		store.dependencies.keychainService.load = { _ in try! JSONEncoder.shared.encode("secretKey") }

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.sentMessageSaved(UUID(0), MessageModel.mock[0])), timeout: 1) {
			$0.chatID = UUID(0)
			$0.messages = .init(uncheckedUniqueElements: [MessageModel.mock[0]])
			$0.inputText = ""
			$0.viewState = .loading
		}

		await store.receive(.internal(.aiMessageReceived(MessageModel.mock[1])), timeout: 1) {
			$0.viewState = .ready
			$0.messages.append(MessageModel.mock[1])
			$0.focusedMessage = MessageModel.mock[1]
		}
	}

	@Test
	func settingsButtonTapped() async throws {
		let store = makeStore()

		await store.send(.view(.settingsButtonTapped)) {
			$0.destination = .settings(SettingsFeature.State())
		}
	}

	@Test
	func chatHistoryButtonTapped() async throws {
		let store = makeStore()

		await store.send(.view(.chatHistoryButtonTapped)) {
			$0.destination = .chatHistory(ChatHistoryFeature.State())
		}
	}

	@Test
	func newChatButtonTapped() async throws {
		let store = makeStore()

		store.dependencies.uuid = .incrementing
		store.dependencies.openAIService.chatCompletions = { _, _ in .mock }
		store.dependencies.chatService.saveMessage = { _, _, sender in MessageModel.mock[sender == .user ? 0 : 1] }
		store.dependencies.defaultAppStorage.set("model", forKey: "selectedModelID")
		store.dependencies.keychainService.load = { _ in try! JSONEncoder.shared.encode("secretKey") }

		store.exhaustivity = .off
		await store.send(.binding(.set(\.inputText, "Test")))
		store.exhaustivity = .on

		await store.send(.view(.sendButtonTapped))

		await store.receive(.internal(.sentMessageSaved(UUID(0), MessageModel.mock[0])), timeout: 1) {
			$0.chatID = UUID(0)
			$0.messages = .init(uncheckedUniqueElements: [MessageModel.mock[0]])
			$0.inputText = ""
			$0.viewState = .loading
		}

		await store.receive(.internal(.aiMessageReceived(MessageModel.mock[1])), timeout: 1) {
			$0.viewState = .ready
			$0.messages.append(MessageModel.mock[1])
			$0.focusedMessage = MessageModel.mock[1]
		}

		await store.send(.view(.newChatButtonTapped)) {
			$0.viewState = .newChat
			$0.chatID = nil
			$0.messages = []
			$0.inputText = ""
			$0.pagination.offset = .zero
		}
	}

	@Test
	func scrolledToLastMessage() async throws {
		let store = makeStore()

		await store.send(.view(.scrolledToLastMessage)) {
			$0.finishedScrolling = true
		}
	}

	@Test
	func onMessageAppearWithoutFinishInitialScrolling() async throws {
		let store = makeStore()

		await store.send(.view(.onMessageAppear(id: UUID(0))))
	}

	@Test
	func onMessageAppearNotFirstOrNotExistent() async throws {
		let store = makeStore()

		store.dependencies.uuid = .incrementing

		store.exhaustivity = .off
		await store.send(.internal(.messagesFetched(MessageModel.mock)))
		await store.send(.view(.scrolledToLastMessage))
		store.exhaustivity = .on

		await store.send(.view(.onMessageAppear(id: UUID(1))))

		await store.send(.view(.onMessageAppear(id: UUID(3))))
	}

	@Test
	func onMessageAppearWithoutNextItems() async throws {
		let store = makeStore()

		store.dependencies.uuid = .incrementing

		store.exhaustivity = .off
		await store.send(.internal(.messagesFetched(MessageModel.mock)))
		await store.send(.view(.scrolledToLastMessage))
		await store.send(.view(.onMessageAppear(id: UUID(0))))
		await store.send(.internal(.messagesFetched([])))
		store.exhaustivity = .on

		await store.send(.view(.onMessageAppear(id: UUID(0))))
	}

	@Test
	func onMessageAppearWithinLoadingsState() async throws {
		let store = makeStore()

		store.dependencies.uuid = .incrementing

		store.exhaustivity = .off
		await store.send(.internal(.messagesFetched(MessageModel.mock)))
		await store.send(.view(.scrolledToLastMessage))

		await store.send(.internal(.sentMessageSaved(UUID(3), .init(id: UUID(3), content: "new", sentAt: Date(), sender: .assistant))))

		store.exhaustivity = .on

		await store.send(.view(.onMessageAppear(id: UUID(0))))
	}

	@Test
	func onMessageAppearFetchingMore() async throws {
		let store = makeStore(chatID: UUID(10))

		store.dependencies.uuid = .incrementing

		store.exhaustivity = .off
		await store.send(.internal(.messagesFetched(MessageModel.mock)))
		await store.send(.view(.scrolledToLastMessage))
		store.exhaustivity = .on

		let newMessages: [MessageModel] = [
			.init(id: UUID(5), content: "new response", sentAt: Date(), sender: .assistant),
			.init(id: UUID(4), content: "new question", sentAt: Date(), sender: .user),
		]

		store.dependencies.chatService.fetchMessages = { _, _ in newMessages }

		await store.send(.view(.onMessageAppear(id: UUID(0)))) {
			$0.viewState = .fetchingMore
		}

		await store.receive(.internal(.messagesFetched(newMessages)), timeout: 1) {
			$0.viewState = .ready
			$0.messages = .init(uncheckedUniqueElements: newMessages + MessageModel.mock)
			$0.pagination.offset = 4
			$0.focusedMessage = newMessages[1]
		}
	}
}

extension ChatFeatureTests {
	private func makeStore(chatID: UUID? = nil) -> TestStoreOf<ChatFeature> {
		.init(
			initialState: .init(chatID: chatID),
			reducer: { ChatFeature() }
		)
	}
}
