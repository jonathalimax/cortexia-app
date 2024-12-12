import ComposableArchitecture
import SwiftUI

@ViewAction(for: ChatHistoryFeature.self)
struct ChatHistoryView: View {
	@Bindable var store: StoreOf<ChatHistoryFeature>

	var body: some View {
		Group {
			if store.messages.isEmpty {
				Text("There is not chat history!")
					.font(.headline)

			} else {
				List(selection: $store.selectedMessage) {
					ForEach(store.messages, id: \.date) { group in
						Section(group.date.formatted(date: .abbreviated, time: .omitted)) {
							ForEach(group.messages, id: \.self) { message in
								Text(message.content)
									.lineLimit(2)
									.padding(.vertical, 4)
									.listRowBackground(Color.clear)
									.swipeActions(edge: .trailing, allowsFullSwipe: true) {
										deleteButton(for: message)
									}
							}
						}
						.listRowBackground(Color.clear)
						.listRowSeparator(.hidden)
					}
				}
				.listStyle(.plain)
				.toolbar {
					ToolbarItem(placement: .topBarTrailing) {
						if !store.messages.isEmpty {
							Button(action: { send(.clearHistoryButtonTapped) }) {
								Image(systemName: "trash")
							}
						}
					}
				}
			}
		}
		.navigationTitle("Chat history")
		.onAppear { send(.onAppear) }
		.navigationDestination(
			item: $store.scope(state: \.destination?.newChat, action: \.destination.newChat),
			destination: ChatView.init
		)
		.confirmationDialog(
			item: $store.scope(state: \.destination?.clearHistory, action: \.destination.clearHistory),
			title: { _ in Text("Clear chat history?") },
			actions: { _ in deleteDialogButtons }
		)
	}

	@ViewBuilder
	private var deleteDialogButtons: some View {
		Button("Confirm", role: .destructive) { send(.clearHistoryConfirmationTapped) }

		Button("Cancel", role: .cancel) {}
	}

	private func deleteButton(for message: ChatMessage) -> some View {
		Button(role: .destructive, action: { send(.deleteButtonTapped(message.chatID), animation: .default) }) {
			Label("Delete", systemImage: "trash")
		}
	}
}

#Preview {
	ChatHistoryView(
		store: .init(
			initialState: ChatHistoryFeature.State(),
			reducer: { ChatHistoryFeature() }
		)
	)
}
