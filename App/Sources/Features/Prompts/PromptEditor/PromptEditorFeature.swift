import ComposableArchitecture

@Reducer
struct PromptEditorFeature {
	@Dependency(\.date) private var date
	@Dependency(\.uuid) private var uuid
	@Dependency(\.databaseService) private var databaseService

	@ObservableState
	struct State: Equatable {
		var text: String
		var prompt: Prompt?

		init(prompt: Prompt? = nil) {
			self.prompt = prompt
			self.text = prompt?.text ?? ""
		}
	}

	enum Action: ViewAction, BindableAction, Equatable {
		enum ViewAction: Equatable {
			case saveButtonTapped
		}

		enum DelegateAction: Equatable {
			case backing
		}

		case view(ViewAction)
		case delegate(DelegateAction)
		case binding(BindingAction<State>)
	}

	var body: some ReducerOf<Self> {
		BindingReducer()

		Reduce { state, action in
			switch action {
			case .view(let action):
				switch action {
				case .saveButtonTapped:
					guard let prompt = state.prompt else {
						return persistPrompt(state.text)
					}

					return updatePersistedPrompt(prompt, with: state.text)
				}

			case .binding, .delegate:
				return .none
			}
		}
	}

	private func persistPrompt(_ text: String) -> EffectOf<Self> {
		.run { send in
			let prompt = Prompt(id: uuid(), text: text, createdAt: date.now)
			try await databaseService.insert([prompt])
			await send(.delegate(.backing))
		}
	}

	private func updatePersistedPrompt(_ prompt: Prompt, with text: String) -> EffectOf<Self> {
		.run { send in
			prompt.text = text
			try await databaseService.save()
			await send(.delegate(.backing))
		}
	}
}
