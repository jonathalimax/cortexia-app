import ComposableArchitecture
import Dependencies
import Foundation
import SwiftData

@Reducer
struct AppFeature {
	@Dependency(\.openAIService) private var openAIService
	@Dependency(\.databaseService) private var databaseService

	@ObservableState
	struct State: Equatable {
		@Shared(.localStorage(.selectedAPI)) var selectedAPI: CompatibleOpenAIKey = .openAI
		@Shared(.localStorage(.darkModeEnabled)) var darkModeEnabled: Bool = true

		var chatState: ChatFeature.State = .init()
	}

	enum Action: Equatable, ViewAction {
		enum ViewAction: Equatable {
			case applicationStarted
			case receivedDeepLink(URL)
		}

		case view(ViewAction)
		case chat(ChatFeature.Action)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.chatState, action: \.chat) { ChatFeature() }

		Reduce { state, action in
			switch action {
			case .view(.applicationStarted):
				return .concatenate(
					registerDataContainer(),
					fetchGenerativeAIModels()
				)

			case .view(.receivedDeepLink(let url)):
				return handleReceivedDeeplink(url, &state)

			case .chat:
				return .none
			}
		}
	}

	/// Register swift data container
	private func registerDataContainer() -> EffectOf<Self> {
		.run { _ in databaseService.registerContainer() }
	}

	/// Fetches the generative AI models from the OpenAI service and inserts them into the database.
	private func fetchGenerativeAIModels() -> EffectOf<Self> {
		.run(priority: .background) { _ in
			// Fetch models asynchronously from the OpenAI service
			_ = try? await openAIService.fetchModels(true)
		}
	}

	private func handleReceivedDeeplink(_ url: URL, _ state: inout State) -> EffectOf<Self> {
		guard
			let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
			urlComponents.scheme == DeepLink.schemaURL
		else { return .none }

		switch DeepLink(rawValue: urlComponents.host ?? "") {
		case .model: state.chatState.setDestination(.settings(.init(initialRoute: .models)))
		case .baseURL: state.chatState.setDestination(.apiSettings(.init(focusedField: .baseURL)))
		case .secretKey: state.chatState.setDestination(.apiSettings(.init(focusedField: .secretKey)))
		default: break
		}

		return .none
	}
}
