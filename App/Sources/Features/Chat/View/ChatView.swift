import Combine
import ComposableArchitecture
import MarkdownUI
import SwiftUI

@ViewAction(for: ChatFeature.self)
struct ChatView: View {
	@Bindable var store: StoreOf<ChatFeature>
	@FocusState private var focusedField: Field?
	@State private var isCancelButtonEnabled: Bool = false

	init(store: StoreOf<ChatFeature>) {
		self.store = store
	}

	var body: some View {
		NavigationStack {
			ZStack {
				Color.adaptiveBackground
					.ignoresSafeArea()

				ZStack(alignment: .bottom) {
					chat

					chatTextView
						.frame(height: .chatTextHeight)
				}
				.ignoresSafeArea(.container, edges: .bottom)
			}
			.navigationTitle("AI Chat")
			.toolbar { toolbarView }
			.onFirstAppear {
				if store.isChatFocused {
					focusedField = .chatText
				}
			}
			.onAppear { send(.onAppear) }
			.navigationDestination(
				item: $store.scope(state: \.destination?.chatHistory, action: \.destination.chatHistory),
				destination: ChatHistoryView.init
			)
			.navigationDestination(
				item: $store.scope(state: \.destination?.settings, action: \.destination.settings),
				destination: SettingsView.init
			)
			.navigationDestination(
				item: $store.scope(state: \.destination?.apiSettings, action: \.destination.apiSettings),
				destination: SettingsAPIView.init
			)
			.sheet(
				item: $store.scope(state: \.destination?.prompts, action: \.destination.prompts),
				content: { childStore in
					NavigationStack {
						PromptsView(store: childStore)
					}
					.presentationDetents([.fraction(0.3), .medium])
					.presentationDragIndicator(.visible)
				}
			)
			.sheet(
				item: $store.scope(state: \.destination?.usageCosts, action: \.destination.usageCosts),
				content: {
					UsageCostsView(token: $0.tokens, money: $0.costs)
						.presentationDetents([.medium])
						.presentationDragIndicator(.visible)
				}
			)
		}
	}

	private var chat: some View {
		ScrollViewReader { proxy in
			List {
				Group {
					if store.viewState == .newChat {
						emptyStateView

					} else {
						if store.viewState == .fetchingMore {
							progress
						}

						chatMessagesView

						if store.viewState == .loading {
							progress
						}
					}

					Spacer()
						.frame(height: .chatTextHeight)
				}
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
			}
			.listStyle(.plain)
			.scrollDismissesKeyboard(.immediately)
			.onChange(of: store.editingMessageID) { _, newValue in
				withAnimation {
					focusedField = .chatText
					scrollToFocusedMessage(newValue, proxy, delay: 1)
				}

				Task {
					try await Task.sleep(seconds: newValue != nil ? 1 : .zero)
					isCancelButtonEnabled = newValue != nil
				}
			}
			.onChange(of: store.focusedMessageID) { _, newValue in
				scrollToFocusedMessage(newValue, proxy, delay: 0.5)
			}
		}
	}

	private var progress: some View {
		HStack {
			Spacer()

			ProgressView()

			Spacer()
		}
		.id(UUID())
	}

	private var emptyStateView: some View {
		Text("Need help? I'm here!")
			.applyMessageBubble(
				textColor: .adaptiveBlack,
				backgroundColor: .adaptiveWhite.opacity(0.6)
			)
			.font(.headline)
			.padding(.top, 32)
			.frame(maxWidth: .infinity, alignment: .center)
	}

	private var chatMessagesView: some View {
		ForEach(store.messages, id: \.id) { message in
			Group {
				switch message.sender {
				case .user:
					VStack(alignment: .trailing, spacing: 6) {
						ChatMessageView(message: message.content, type: .sent)
							.frame(maxWidth: .infinity, alignment: .trailing)
							.id(message.id)

						if store.editingMessageID == message.id, isCancelButtonEnabled {
							Button(action: { send(.cancelEditingButtonTapped) }) {
								Text("Cancel")
									.foregroundStyle(Color.red.opacity(0.8))
									.font(.footnote)
									.fontWeight(.medium)
							}
							.padding(.trailing, 8)
							.animation(.default, value: isCancelButtonEnabled)
						}

					}
					.padding(.leading)

				case .assistant where store.viewState == .editing(message.id),
					.assistant where store.regeneratingMessageID == message.id:
					progress

				case .assistant, .system:
					Markdown(message.content)
						.markdownBlockStyle(\.codeBlock) { configuration in
							if store.wordWrapEnabled {
								codeBlockView(configuration)
							} else {
								ScrollView(.horizontal) {
									codeBlockView(configuration)
								}
							}
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.id(message.id)
				}
			}
			.onAppear {
				if store.finishedScrolling, message == store.messages.first {
					send(.firstMessageAppeared(id: message.id))
				}
			}
			.contextMenu { contextMenuItems(message) }
		}
	}

	private func contextMenuItems(_ message: Message) -> some View {
		ForEach(ChatFeature.ContextAction.forRole(message.sender), id: \.self) { item in
			Button(
				action: { send(.contextItemTapped(item, message: message)) },
				label: { Text(item.rawValue) }
			)
		}
	}

	private func codeBlockView(_ configuration: CodeBlockConfiguration) -> some View {
		configuration.label
			.relativeLineSpacing(.em(0.25))
			.markdownTextStyle {
				FontFamilyVariant(.monospaced)

				FontSize(.em(0.85))
			}
			.padding()
			.background(Color.codeBlocks)
			.clipShape(RoundedRectangle(cornerRadius: 8))
			.markdownMargin(top: .zero, bottom: .em(0.8))
	}

	private var chatTextView: some View {
		ZStack {
			Color.clear
				.background(.ultraThinMaterial)
				.clipShape(.rect(topLeadingRadius: 8, topTrailingRadius: 8))
				.ignoresSafeArea()

			ChatTextView(
				text: $store.inputText,
				onSendTapped: { send(.sendButtonTapped) },
				onPencilTapped: { send(.pencilButtonTapped) }
			)
			.padding([.horizontal, .top])
			.padding(.bottom, 40)
			.focused($focusedField, equals: .chatText)
			.onSubmit { send(.sendButtonTapped) }
		}
	}

	private var toolbarView: some ToolbarContent {
		ToolbarItemGroup(placement: .topBarTrailing) {
			HStack {
				switch store.origin {
				case .home:
					Button("", systemImage: "gear", action: { send(.settingsButtonTapped) })
					Button("", systemImage: "arrow.counterclockwise", action: { send(.chatHistoryButtonTapped) })

					if store.chatID != nil {
						Button("", systemImage: "square.and.pencil", action: { send(.newChatButtonTapped, animation: .default) })
							.animation(.default, value: store.chatID)
					}

				case .history:
					Button("", systemImage: "dollarsign.arrow.circlepath", action: { send(.tokenButtonTapped) })
				}
			}
			.foregroundStyle(.adaptiveWhite)
		}
	}

	private func scrollToFocusedMessage(_ messageID: String?, _ proxy: ScrollViewProxy, delay seconds: Double) {
		Task {
			guard let messageID else { return }

			try await Task.sleep(seconds: seconds)

			withAnimation(.smooth) {
				proxy.scrollTo(messageID, anchor: .top)
			}

			send(.scrolledToLastMessage)
		}
	}
}

extension ChatView {
	enum Field {
		case chatText
	}
}

// MARK: - Constants
private extension CGFloat {
	static let chatTextHeight: Self = 90
}

// MARK: - Previews
#Preview {
	ChatView(
		store: .init(
			initialState: ChatFeature.State(),
			reducer: { ChatFeature() }
		)
	)
}
