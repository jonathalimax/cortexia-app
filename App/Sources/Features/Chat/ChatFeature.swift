import ComposableArchitecture
import Foundation

@Reducer
struct ChatFeature {
	@Dependency(\.uuid) private var uuid
	@Dependency(\.date) private var date
	@Dependency(\.pasteboard) private var pasteboard
	@Dependency(\.chatService) private var chatService
	@Dependency(\.openAIService) private var openAIService
	@Dependency(\.keychainService) private var keychainService
	@Dependency(\.defaultAppStorage) private var appStorage
	@Shared(.localStorage(.selectedModelID)) private var modelID: String? = nil
	@Shared(.localStorage(.selectedAPI)) private var selectedAPI: CompatibleOpenAIKey = .openAI

	@ObservableState
	struct State: Equatable {
		@Shared(.localStorage(.wordWrapEnabled)) var wordWrapEnabled: Bool = false

		@Presents var destination: Destination.State?

		/// The unique identifier of the current chat.
		var chatID: String?
		/// The collection of messages associated with the current chat.
		var messages: IdentifiedArrayOf<Message> = []
		/// The text input by the user for sending a new message.
		var inputText: String = ""
		/// The current state of the screen.
		var viewState: ViewState
		/// A flag indicating whether the chat is currently focused.
		var isChatFocused: Bool
		/// The origin feature that started the chat.
		var origin: Origin
		/// The message id currently focused.
		var focusedMessageID: String?
		/// The message id currently being regenerated.
		var regeneratingMessageID: String?
		/// A flag indicating whether the user has finished scrolling through the chat messages.
		var finishedScrolling: Bool = false
		/// Object that represents the pagination
		var pagination: Pagination = .init(limit: .paginationLimit)
		/// The message being edited
		var editingMessageID: String?

		/// Total number of tokens from conversation
		var chatTokens: Int { messages.map(\.tokens).reduce(0, +) }

		/// Computes the total chat usage costs by summing up the costs of chat messages
		var chatUsageCosts: Double { messages.compactMap(\.costs).reduce(0, +) }

		/// Gets the next message from the editing one
		var nextEditingMessageID: String? {
			guard
				let editingMessageID,
				let editingIndex = messages.index(id: editingMessageID)
			else { return nil }

			let assistantIndex = messages.index(after: editingIndex)
			return messages[assistantIndex].id
		}

		init(
			chatID: String? = nil,
			viewState: ViewState = .newChat,
			isChatFocused: Bool = true,
			origin: Origin = .home
		) {
			self.chatID = chatID
			self.viewState = viewState
			self.isChatFocused = isChatFocused
			self.origin = origin
		}

		mutating func setDestination(_ destination: Destination.State) {
			self.destination = destination
		}
	}

	enum Action: Equatable, ViewAction, BindableAction {
		enum ViewAction: Equatable {
			case onAppear
			case sendButtonTapped
			case settingsButtonTapped
			case chatHistoryButtonTapped
			case newChatButtonTapped
			case firstMessageAppeared(id: String)
			case scrolledToLastMessage
			case contextItemTapped(ContextAction, message: Message)
			case cancelEditingButtonTapped
			case pencilButtonTapped
			case tokenButtonTapped
		}

		enum InternalAction: Equatable {
			case fetchChatMessages(_ chatID: String, _ pagination: Pagination)
			case messagesFetched(_ messages: [Message], _ isPaginating: Bool)
			case sendingMessage(Message, _ chatID: String)
			case chatDeleted
			case messageRegenerated(_ current: Message, _ new: Message)
			case messageEdited(_ current: Message, new: Message)
		}

		case view(ViewAction)
		case `internal`(InternalAction)
		case binding(BindingAction<State>)
		case destination(PresentationAction<Destination.Action>)
	}

	@Reducer(state: .equatable, action: .equatable)
	enum Destination {
		case chat(ChatFeature)
		case settings(SettingsFeature)
		case apiSettings(SettingsAPIFeature)
		case chatHistory(ChatHistoryFeature)
		case prompts(PromptsFeature)

		@ReducerCaseIgnored
		case usageCosts(Usage)

		@ObservableState struct Usage: Equatable {
			let tokens: Int
			let costs: Double
		}
	}

	enum Origin {
		case home, history
	}

	enum ViewState: Equatable {
		case newChat, loading, ready, fetchingMore, editing(_ messageID: String?)
	}

	enum Error: Swift.Error {
		case missingModelID
		case emptySecretKey
		case missingAIMessage
	}

	enum ContextAction: String, CaseIterable {
		case copy = "Copy"
		case edit = "Edit"
		case regenerate = "Regenerate"

		static func forRole(_ role: Role) -> [ContextAction] {
			switch role {
			case .assistant: [.copy, .regenerate]
			case .user:[.copy, .edit]
			case .system: [.copy]
			}
		}
	}

	var body: some ReducerOf<Self> {
		BindingReducer()

		Reduce { state, action in
			switch action {
			case .view(let action):
				return viewBody(action, &state)

			case .internal(let action):
				return internalBody(action, &state)

			case .destination(.presented(.settings(let action))):
				switch action {
				case .route(.presented(.prompts(.delegate(.promptSelected(let prompt))))):
					state.destination = nil
					state.inputText = prompt.text
					return .none

				default:
					return .none
				}

			case .destination(.presented(.prompts(.delegate(.promptSelected(let prompt))))):
				state.destination = nil
				state.inputText = prompt.text
				return .none

			case .binding, .destination:
				return .none

			}
		}
		.ifLet(\.$destination, action: \.destination)
	}

	private func viewBody(_ action: Action.ViewAction, _ state: inout State) -> EffectOf<Self> {
		switch action {
		case .onAppear:
			guard let chatID = state.chatID else { return .none }
			state.messages = []
			state.pagination.reset()

			return onAppearEffect(chatID, state.pagination)

		case .sendButtonTapped:
			guard !state.inputText.isEmpty else { return .none }
			return sendEffect(&state)

		case .settingsButtonTapped:
			state.destination = .settings(SettingsFeature.State())
			return .none

		case .chatHistoryButtonTapped:
			state.destination = .chatHistory(ChatHistoryFeature.State())
			return .none

		case .newChatButtonTapped:
			startsNewChat(&state)
			return .none

		case .firstMessageAppeared(let id):
			return firstMessageAppeared(id, &state)

		case .scrolledToLastMessage:
			state.finishedScrolling = true
			return .none

		case .contextItemTapped(.copy, let message):
			pasteboard.string = message.content
			return .none

		case .contextItemTapped(.edit, let message):
			state.editingMessageID = message.id
			state.inputText = message.content
			return .none

		case .contextItemTapped(.regenerate, let message):
			state.regeneratingMessageID = message.id
			return regenerateResponse(&state, message: message)

		case .cancelEditingButtonTapped:
			state.editingMessageID = nil
			state.inputText = ""
			return .none

		case .pencilButtonTapped:
			state.destination = .prompts(PromptsFeature.State())
			return .none

		case .tokenButtonTapped:
			let usage = Destination.Usage(tokens: state.chatTokens, costs: state.chatUsageCosts)
			state.destination = .usageCosts(usage)
			return .none
		}
	}

	private func internalBody(_ action: Action.InternalAction, _ state: inout State) -> EffectOf<Self> {
		switch action {
		case let .fetchChatMessages(chatID, pagination):
			return fetchMessages(for: chatID, pagination)

		case let .messagesFetched(messages, moreItemsFetched):
			// Appends based on the fetching type, wether is fetching for the first time or more items
			if moreItemsFetched {
				state.messages.insert(contentsOf: messages, at: state.messages.startIndex)
			} else {
				state.messages.append(contentsOf: messages)
				state.focusedMessageID = messages.last?.id
			}

			state.viewState = .ready
			state.pagination.offset += messages.count
			state.pagination.hasNext = messages.count != .zero
			return .none

		case let .sendingMessage(message, chatID):
			state.chatID = chatID
			state.messages.updateOrAppend(message)
			state.inputText = ""
			state.focusedMessageID = message.id

			if message.sender == .user {
				state.viewState = state.editingMessageID == nil ? .loading : .editing(state.nextEditingMessageID)
			} else {
				state.viewState = .ready
				state.pagination.hasNext = true
			}

			return .none

		case let .messageEdited(current, new):
			guard let currentMessageIndex = state.messages.index(id: current.id) else { return .none }
			var messages = state.messages

			messages.remove(at: currentMessageIndex)
			messages.insert(new, at: currentMessageIndex)

			state.inputText = ""
			state.messages = messages

			if case .assistant = new.sender {
				state.editingMessageID = nil
				state.viewState = .ready
			}

			return .none

		case let .messageRegenerated(current, new):
			guard let currentIndex = state.messages.index(id: current.id) else { return .none }
			var messages = state.messages
			messages.remove(current)
			messages.insert(new, at: currentIndex)
			state.messages = messages
			state.regeneratingMessageID = nil
			return .none

		case .chatDeleted:
			startsNewChat(&state)
			return .none
		}
	}

	private func regenerateResponse(_ state: inout State, message: Message) -> EffectOf<Self> {
		guard
			let chatID = state.chatID,
			let currentIndex = state.messages.index(id: message.id)
		else { return .none }

		let promptMessageIndex = state.messages.index(before: currentIndex)
		let prompt = state.messages[promptMessageIndex]

		return .run { send in
			guard let modelID else { throw Error.missingModelID }

			let response = try await openAIService.chat(prompt.content, modelID, chatID)
			let aiMessage = try response.aiMessage

			await send(.internal(.messageRegenerated(message, aiMessage)), animation: .default)

			// Update messages to the database
			try await chatService.replaceMessage(message.id, aiMessage)

		} catch: { [state] error, send in
			await displayError(error, state, chatID, send)
		}
	}

	private func sendEffect(_ state: inout State) -> EffectOf<Self> {
		let chatID = state.chatID ?? uuid().uuidString

		return .run { [state] send in
			var userMessage = Message(id: state.editingMessageID ?? uuid().uuidString, content: state.inputText, sender: .user, tokens: .zero)
			await send(.internal(.sendingMessage(userMessage, chatID)), animation: .default)
			// Stores the user message
			try await storeMessage(state, chatID, userMessage, send)

			// Load the OpenAI secret key from the keychain
			let openAISecretKey: String? = try? await keychainService.load(.openAISecretKey)

			// Check if the secret key is empty and throw an error if it is
			guard let openAISecretKey, !openAISecretKey.isEmpty else { throw Error.emptySecretKey }
			// Ensure that the model is selected, throwing an error if it's not
			guard let modelID else { throw Error.missingModelID }

			let response = try await openAIService.chat(state.inputText, modelID, chatID)

			// Update Costs
			userMessage.costs = response.cost
			await send(.internal(.sendingMessage(userMessage, chatID)), animation: .none)

			// Stores the user message
			try await chatService.replaceMessage(userMessage.id, userMessage)

			let aiMessage = try response.aiMessage
			try await storeMessage(state, chatID, aiMessage, send)

		} catch: { [state] error, send in
			await displayError(error, state, chatID, send)
		}
	}

	private func displayError(_ error: Swift.Error, _ state: State, _ chatID: String, _ send: Send<Action>) async {
		let message = switch error {
		case URLRequestBuilder.Error.missingBaseURL:
			"**Ollama API base URL not found**. Please [follow the link](\(DeepLink.baseURL.url.absoluteString)) to add and try again."

		case Error.emptySecretKey, AIClientError.missingSecretKey:
			"**Secret key not found** for \(selectedAPI.name) API. Please [follow the link](\(DeepLink.secretKey.url.absoluteString)) to add a brand new one."

		case AIClientError.invalidSecretKey:
			"**The secret key you entered is incorrect**. Please [follow the link](\(DeepLink.secretKey.url.absoluteString)) to change it key and try again."

		case Error.missingModelID:
			"**Model selection is essential for proceeding**. Please [follow the link](\(DeepLink.model.url.absoluteString)) to select a model that meets your needs."

		case Error.missingAIMessage:
			"I couldn't find any suitable options for your request. Please try rephrasing your query or providing more context."

		case ReachabilityService.Error.noConnection:
			"**No network connection detected.** Please ensure you have a stable internet connection and try again"

		default:
			"**Oops! Something went wrong.** Please try again later"
		}

		let errorMessage = Message(id: uuid().uuidString, content: message, sender: .system)
		try? await storeMessage(state, chatID, errorMessage, send)
	}

	private func storeMessage(_ state: State, _ chatID: String, _ message: Message, _ send: Send<Action>) async throws {
		if let editingMessageID = state.editingMessageID {
			if let editingIndex = state.messages.index(id: editingMessageID) {
				let nextIndexIncrement = message.sender == .assistant ? 1 : 0
				let currentMessage = state.messages[editingIndex + nextIndexIncrement]

				await send(.internal(.messageEdited(currentMessage, new: message)))
				try await chatService.replaceMessage(currentMessage.id, message)
			}

		} else {
			await send(.internal(.sendingMessage(message, chatID)), animation: .default)
			// Saves messages to the database
			try await chatService.saveMessage(chatID, message)
		}
	}

	private func onAppearEffect(_ chatID: String, _ pagination: Pagination) -> EffectOf<Self> {
		.run { send in
			if try await chatService.isChatDeleted(chatID) {
				// In case chat was deleted
				await send(.internal(.chatDeleted))
			} else {
				// Let's fetch the chat most updated snapshot
				await send(.internal(.fetchChatMessages(chatID, pagination)))
			}
		}
	}

	private func fetchMessages(for chatID: String?, _ pagination: Pagination, moreItemsFetched: Bool = false) -> EffectOf<Self> {
		guard let chatID else { return .none }

		return .run { send in
			let messages = try await chatService.fetchMessages(chatID, pagination)
				.map { Message(id: $0.id, content: $0.content, sender: $0.sender, tokens: $0.tokens, costs: $0.costs) }

			await send(.internal(.messagesFetched(messages, moreItemsFetched)))
		}
	}

	private func startsNewChat(_ state: inout State) {
		state.viewState = .newChat
		state.chatID = nil
		state.messages = []
		state.inputText = ""
		state.pagination.reset()
	}

	private func firstMessageAppeared(_ id: String, _ state: inout State) -> EffectOf<Self> {
		// Does nothing in case there isn't next items
		guard state.pagination.hasNext else { return .none }

		// Does nothing in case it's already loading
		guard ![.loading, .fetchingMore].contains(state.viewState) else { return .none }

		state.viewState = .fetchingMore
		return fetchMessages(for: state.chatID, state.pagination, moreItemsFetched: true)
	}
}

// MARK: - Helpers
private extension MessageResponse {
	/// Calculated cost based on model, input, or output tokens
	var cost: Double {
		guard let modelPricing = TokenCost.pricing[model] else { return .zero }
		let role = choices.first?.message.role
		let inputTokens = role == .user ? usage.promptTokens : .zero
		let outputTokens = role == .assistant ? usage.completionTokens : .zero

		let inputCost = (Double(inputTokens) / 1_000_000) * modelPricing.inputPerMillion
		let outputCost = (Double(outputTokens) / 1_000_000) * modelPricing.outputPerMillion

		return inputCost + outputCost
	}

	var aiMessage: Message {
		get throws {
			guard let message = choices.first?.message else {
				throw ChatFeature.Error.missingAIMessage
			}

			let tokens = switch message.role {
			case .user: usage.promptTokens
			case .assistant: usage.completionTokens
			case .system: Int.zero
			}

			return .init(id: id, content: message.content, sender: message.role, tokens: tokens, costs: cost)
		}
	}
}

// MARK: - Constants
private extension Int {
	static let paginationLimit: Self = 15
}
