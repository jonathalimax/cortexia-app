import ComposableArchitecture
import Foundation
import SwiftData

@Reducer
struct PromptsFeature {
	@Dependency(\.databaseService) private var databaseService

	@ObservableState
	struct State: Equatable {
		@Presents var destination: Destination.State?

		var prompts: [Prompt] = []
		var viewState: ViewState = .loading
	}

	enum Action: ViewAction, Equatable, BindableAction {
		enum ViewAction: Equatable {
			case onAppear
			case newPromptButtonTapped
			case promptItemTapped(Prompt, action: ContextAction)
		}

		enum InternalAction: Equatable {
			case promptsFetched([Prompt])
			case promptsFetchFailure
		}

		enum DelegateAction: Equatable {
			case promptSelected(Prompt)
		}

		case view(ViewAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
		case binding(BindingAction<State>)
		case destination(PresentationAction<Destination.Action>)
	}

	@Reducer(state: .equatable, action: .equatable)
	enum Destination {
		case editor(PromptEditorFeature)
	}

	enum ViewState {
		case loading, empty, error, ready
	}

	enum ContextAction {
		case use, edit, delete
	}

	var body: some ReducerOf<Self> {
		BindingReducer()

		Reduce { state, action in
			switch action {
			case .view(let action):
				switch action {
				case .onAppear:
					state.viewState = .loading
					return fetchPrompts()

				case .newPromptButtonTapped:
					state.destination = .editor(PromptEditorFeature.State())
					return .none

				case .promptItemTapped(let prompt, .use):
					return .send(.delegate(.promptSelected(prompt)))

				case .promptItemTapped(let prompt, .edit):
					state.destination = .editor(PromptEditorFeature.State(prompt: prompt))
					return .none

				case .promptItemTapped(let prompt, .delete):
					return .concatenate(
						deletePrompt(prompt),
						fetchPrompts()
					)
				}

			case .internal(let action):
				switch action {
				case .promptsFetched(let prompts):
					state.viewState = prompts.isEmpty ? .empty : .ready
					state.prompts = prompts
					return .none

				case .promptsFetchFailure:
					state.viewState = .error
					state.prompts = []
					return .none
				}

			case .destination(.dismiss):
				state.destination = nil
				return .none

			case .destination(.presented(.editor(.delegate(let action)))):
				switch action {
				case .backing:
					state.destination = nil
					return .none
				}

			case .destination, .delegate, .binding:
				return .none
			}
		}
		.ifLet(\.$destination, action: \.destination)
	}

	private func fetchPrompts() -> EffectOf<Self> {
		.run { send in
			let query = FetchDescriptor<Prompt>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
			let prompts = try await databaseService.fetch(query)
			await send(.internal(.promptsFetched(prompts)))
		} catch: { _, send in
			await send(.internal(.promptsFetchFailure))
		}
	}

	private func deletePrompt(_ prompt: Prompt) -> EffectOf<Self> {
		.run { _ in
			try await databaseService.delete([prompt])
		}
	}
}

