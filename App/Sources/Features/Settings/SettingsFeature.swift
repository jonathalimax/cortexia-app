import SwiftData
import ComposableArchitecture
import SwiftUI

@Reducer
struct SettingsFeature {
	@Dependency(\.mainQueue) private var mainQueue
	@Dependency(\.openAIService) private var openAIService
	@Dependency(\.databaseService) private var databaseService
	@Dependency(\.keychainService) private var keychainService

	@ObservableState
	struct State: Equatable {
		@Shared(.localStorage(.wordWrapEnabled)) var wordWrapEnabled: Bool = false
		@Shared(.localStorage(.darkModeEnabled)) var darkModeEnabled: Bool = true
		@Shared(.localStorage(.selectedModelID)) var selectedModelID: String? = nil
		@Shared(.localStorage(.selectedTemperature)) var selectedTemperature: Double = 1.0

		@Presents var route: Route.State?

		var secretAPIKey: String = ""
		var openAIModels: IdentifiedArrayOf<ModelResponse.Model> = []
		var isLoadingModels: Bool = false
		var isSecretKeyInvalid: Bool = false
		var initialRoute: Route.State?

		var selectedModel: ModelResponse.Model? {
			guard let selectedModelID else { return nil }
			return openAIModels[id: selectedModelID]
		}
	}

	@CasePathable
	enum Action: ViewAction, BindableAction, Equatable {
		@CasePathable
		enum ViewAction: Equatable {
			case viewDidAppear
			case modelButtonTapped
			case apiKeysItemTapped
			case promptsItemTapped
			case darkModeChanged(_ isEnabled: Bool)
			case wordWrapChanged(_ isEnabled: Bool)
		}

		enum InternalAction: Equatable {
			case secretKeyLoaded(String)
			case openAIModelsFetched([ModelResponse.Model])
			case hasRefetchedModels
			case secretKeyInvalid
		}

		case view(ViewAction)
		case `internal`(InternalAction)
		case route(PresentationAction<Route.Action>)
		case binding(BindingAction<State>)
	}

	@Reducer(state: .equatable, action: .equatable)
	enum Route {
		@ReducerCaseIgnored
		case models
		case apiKeys(SettingsAPIFeature)
		case prompts(PromptsFeature)
	}

	var body: some ReducerOf<Self> {
		BindingReducer()

		Reduce { state, action in
			switch action {
			case .view(let viewAction):
				switch viewAction {
				case .viewDidAppear:
					return .concatenate(
						fetchOpenAISecretKey(),
						fetchOpenAIModels()
					)

				case .modelButtonTapped:
					var effects = [EffectOf<Self>]()
					state.isLoadingModels = true

					if !state.secretAPIKey.isEmpty {
						// Fetches AI models in case the key is not empty
						effects.append(fetchOpenAIModels())
					}

					effects.append(
						.run { await $0(.internal(.hasRefetchedModels)) }
					)

					return .concatenate(effects)

				case .apiKeysItemTapped:
					state.route = .apiKeys(.init())
					return .none

				case .promptsItemTapped:
					state.route = .prompts(.init())
					return .none

				case .darkModeChanged(let enabled):
					state.darkModeEnabled = enabled
					return .none

				case .wordWrapChanged(let enabled):
					state.wordWrapEnabled = enabled
					return .none
				}

			case .internal(let internalAction):
				switch internalAction {
				case .secretKeyLoaded(let secretAPIKey):
					state.secretAPIKey = secretAPIKey
					return .none

				case .openAIModelsFetched(let models):
					state.openAIModels = .init(uniqueElements: models)
					if let initialRoute = state.initialRoute, initialRoute == .models {
						state.route = initialRoute
					}
					return .none

				case .hasRefetchedModels:
					state.isLoadingModels = false
					state.route = .models
					return .none

				case .secretKeyInvalid:
					state.isSecretKeyInvalid = true
					return .none
				}

			case .binding(let bindingAction):
				switch bindingAction {
				case \.selectedModelID:
					state.route = nil
					return .none

				default:
					return .none
				}

			case .route(.dismiss):
				state.route = nil
				return .none

			case .route:
				return .none
			}
		}
		.ifLet(\.$route, action: \.route)
	}

	private func fetchOpenAISecretKey() -> EffectOf<Self> {
		.run { send in
			// Loads the secret API key from keychain
			guard let openAISecretKey: String = try? await keychainService.load(.openAISecretKey), !openAISecretKey.isEmpty else { return }
			await send(.internal(.secretKeyLoaded(openAISecretKey)))
		}
	}

	private func fetchOpenAIModels() -> EffectOf<Self> {
		.run { send in
			// Should find locally before requesting from the API
			let forceRemote = false
			let modelResponse = try await openAIService.fetchModels(forceRemote)
			await send(.internal(.openAIModelsFetched(modelResponse.data)))
		} catch: { error, send in
			if case AIClientError.invalidSecretKey = error {
				await send(.internal(.secretKeyInvalid))
			}
		}
	}
}
