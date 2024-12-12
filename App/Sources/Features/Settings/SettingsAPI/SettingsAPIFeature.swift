import ComposableArchitecture

@Reducer
struct SettingsAPIFeature {
	@Dependency(\.mainQueue) private var mainQueue
	@Dependency(\.keychainService) private var keychainService

	@ObservableState
	struct State: Equatable {
		@Shared(.localStorage(.selectedAPI)) var selectedAPI: CompatibleOpenAIKey = .openAI
		@Shared(.localStorage(.ollamaBaseURL)) var ollamaBaseURL: String = ""

		var openAIKey: String = ""
		var openRouterKey: String = ""
		var ollamaKey: String = ""
		var focusedField: SelectedField?
	}

	enum Action: Equatable, ViewAction, BindableAction {
		enum ViewAction: Equatable {
			case onAppeared
		}

		enum InternalAction: Equatable {
			case secretKeysFetched(for: CompatibleOpenAIKey, value: String)
		}

		case view(ViewAction)
		case `internal`(InternalAction)
		case binding(BindingAction<State>)
	}

	enum Cancellables {
		case secretKeyStore
	}

	enum SelectedField {
		case secretKey, baseURL
	}

	var body: some ReducerOf<Self> {
		BindingReducer()

		Reduce { state, action in
			switch action {
			case .view(let action):
				switch action {
				case .onAppeared:
					return fetchSecretKeys()
				}

			case .internal(let action):
				switch action {
				case let .secretKeysFetched(apiKey, value):
					switch apiKey {
					case .openAI:
						state.openAIKey = value

					case .openRouter:
						state.openRouterKey = value

					case .ollama:
						state.ollamaKey = value
					}

					return .none
				}

			case .binding(let action):
				switch action {
				case \.openAIKey:
					return storeSecretKey(.openAI, value: state.openAIKey)

				case \.openRouterKey:
					return storeSecretKey(.openRouter, value: state.openRouterKey)

				case \.ollamaKey:
					return storeSecretKey(.ollama, value: state.ollamaKey)

				default:
					return .none
				}
			}
		}
	}

	private func storeSecretKey(_ secretKey: CompatibleOpenAIKey, value: String) -> EffectOf<Self> {
		return .run { _ in
			// Save the secret API key to the keychain
			try await keychainService.save(value, for: secretKey.keychainKey)
		}
		// Debounce the effect to prevent it from being called too frequently
		.debounce(id: Cancellables.secretKeyStore, for: .seconds(0.3), scheduler: mainQueue)
	}

	private func fetchSecretKeys() -> EffectOf<Self> {
		.run { send in
			for api in CompatibleOpenAIKey.allCases {
				// Loads the API secret keys from keychain
				if let secretKey: String = try? await keychainService.load(api.keychainKey) {
					await send(.internal(.secretKeysFetched(for: api, value: secretKey)))
				}
			}
		}
	}
}

// MARK: - Helpers
private extension CompatibleOpenAIKey {
	var keychainKey: KeychainKey {
		switch self {
		case .openAI: .openAISecretKey
		case .openRouter: .openRouterSecretKey
		case .ollama: .ollamaSecretKey
		}
	}
}
