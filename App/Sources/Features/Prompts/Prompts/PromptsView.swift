import ComposableArchitecture
import SwiftUI

@ViewAction(for: PromptsFeature.self)
struct PromptsView: View {
	@Bindable var store: StoreOf<PromptsFeature>

	var body: some View {
		VStack {
			switch store.viewState {
			case .loading:
				ProgressView()

			case .empty:
				Text("Create a prompt to get personalized, creative, and relevant suggestions tailored to your needs.")
					.padding()

				Spacer()

			case .error:
				Text("Oops! We couldn't load your prompts.")
					.padding()

				Spacer()

			case .ready:
				Form {
					ForEach(store.prompts) { prompt in
						Section {
							Menu {
								Button("Use", action: { send(.promptItemTapped(prompt, action: .use)) })
								Button("Edit", action: { send(.promptItemTapped(prompt, action: .edit)) })
								Button("Delete", action: { send(.promptItemTapped(prompt, action: .delete)) })
							} label: {
								Text(prompt.text)
									.foregroundStyle(Color.adaptiveWhite)
									.multilineTextAlignment(.leading)
									.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
							}
						}
					}
				}
				.listSectionSpacing(.compact)
			}
		}
		.onAppear { send(.onAppear) }
		.navigationTitle("Prompts")
		.toolbar {
			ToolbarItemGroup(placement: .topBarTrailing) {
				Button("", systemImage: "square.and.pencil") { send(.newPromptButtonTapped) }
			}
		}
		.navigationDestination(
			item: $store.scope(state: \.destination?.editor, action: \.destination.editor),
			destination: PromptEditorView.init
		)
	}
}

#Preview {
	NavigationStack {
		PromptsView(
			store: .init(
				initialState: PromptsFeature.State(),
				reducer: { PromptsFeature() }
			)
		)
	}
}
