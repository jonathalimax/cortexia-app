import ComposableArchitecture
import Foundation

@Reducer
struct ChatHistoryFeature {
	@Dependency(\.calendar) private var calendar
	@Dependency(\.chatService) private var chatService

	@ObservableState
	struct State: Equatable {
		@Presents var destination: Destination.State?

		var messages: [DateMessageGroup] = []
		var selectedMessage: ChatMessage?
	}

	enum Action: Equatable, ViewAction, BindableAction {
		enum ViewAction: Equatable {
			case onAppear
			case deleteButtonTapped(_ chatID: String)
			case clearHistoryButtonTapped
			case clearHistoryConfirmationTapped
		}

		enum InternalAction: Equatable {
			case messagesFetched([DateMessageGroup])
			case messagesCleaned
		}

		case view(ViewAction)
		case `internal`(InternalAction)
		case binding(BindingAction<State>)
		case destination(PresentationAction<Destination.Action>)
	}

	@Reducer(state: .equatable, action: .equatable)
	enum Destination {
		case newChat(ChatFeature)
		@ReducerCaseIgnored
		case clearHistory
	}

	struct DateMessageGroup: Equatable {
		let date: Date
		var messages: [ChatMessage]
	}

	var body: some ReducerOf<Self> {
		BindingReducer()

		Reduce { state, action in
			switch action {
			case .view(let viewAction):
				switch viewAction {
				case .onAppear:
					return fetchChats()

				case .clearHistoryButtonTapped:
					state.destination = .clearHistory

				case .deleteButtonTapped(let chatID):
					return .concatenate(
						deleteChat(chatID),
						fetchChats()
					)
				case .clearHistoryConfirmationTapped:
					return .concatenate(
						deleteHistory(),
						fetchChats()
					)
				}

				return .none

			case .internal(let internalAction):
				switch internalAction {
				case .messagesFetched(let messages):
					state.messages = messages

				case .messagesCleaned:
					state.messages = []
				}

				return .none

			case .binding(let bindingAction):
				switch bindingAction {
				case \.selectedMessage:
					guard let selectedMessage = state.selectedMessage else { return .none }
					let chatState = ChatFeature.State(
						chatID: selectedMessage.chatID,
						viewState: .ready,
						isChatFocused: false,
						origin: .history
					)
					state.destination = .newChat(chatState)

				default: break
				}

				return .none

			case .destination:
				return .none
			}
		}
		.ifLet(\.$destination, action: \.destination)
	}

	private func fetchChats() -> EffectOf<Self> {
		.run { send in
			// Fetch user messages from chat service
			let response = try await chatService.fetchChats()

			// Dictionary to store the earliest message for each thread
			var firstMessagesByChat = [String: ChatMessage]()
			// Array to store groups of messages sorted by date
			var groupedMessages = [DateMessageGroup]()

			// Find the earliest message for each thread
			for message in response where message.sender == .user {
				if let existingMessage = firstMessagesByChat[message.chatID] {
					if message.sentAt < existingMessage.sentAt {
						firstMessagesByChat[message.chatID] = message
					}
				} else {
					firstMessagesByChat[message.chatID] = message
				}
			}

			// Create a dictionary to group messages by date
			var dateToMessages = [Date: [ChatMessage]]()

			// Populate the dictionary with messages
			for message in firstMessagesByChat.values {
				let messageDate = calendar.startOfDay(for: message.sentAt)
				if dateToMessages[messageDate] != nil {
					dateToMessages[messageDate]?.append(message)
				} else {
					dateToMessages[messageDate] = [message]
				}
			}

			// Convert dictionary to array of `DateMessageGroup` and sort it
			groupedMessages = dateToMessages.map { date, messages in
				DateMessageGroup(date: date, messages: messages.sorted(by: { $0.sentAt > $1.sentAt }))
			}
			groupedMessages.sort(by: { $0.date > $1.date })

			// Send the result
			await send(.internal(.messagesFetched(groupedMessages)))
		}
	}

	private func deleteChat(_ chatID: String) -> EffectOf<Self> {
		.run { _ in
			try await chatService.deleteChat(chatID)
		}
	}

	private func deleteHistory() -> EffectOf<Self> {
		.run { send in
			try await chatService.cleanHistory()
			await send(.internal(.messagesCleaned))
		}
	}
}
