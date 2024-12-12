import ComposableArchitecture
import SwiftUI

@ViewAction(for: SettingsAPIFeature.self)
struct SettingsAPIView: View {
	@Bindable var store: StoreOf<SettingsAPIFeature>
	@FocusState private var focusedField: Field?

	enum Field {
		case openAIKey, openRouterKey, ollamaKey, ollamaBaseURL
	}

	init(store: StoreOf<SettingsAPIFeature>) {
		self.store = store
	}

	var body: some View {
		Form {
			Picker("Selected API", selection: $store.selectedAPI) {
				ForEach(CompatibleOpenAIKey.allCases, id: \.self) { api in
					Text(api.name)
				}
			}

			ForEach(CompatibleOpenAIKey.allCases, id: \.self) { api in
				Section(api.name) {
					secretKeyField(api)
				}
			}
		}
		.navigationTitle("Compatible APIs")
		.onAppear {
			send(.onAppeared)

			focusedField = switch store.focusedField {
			case .secretKey: store.selectedAPI.field
			case .baseURL: .ollamaBaseURL
			default: nil
			}
		}
	}

	@ViewBuilder
	private func secretKeyField(_ api: CompatibleOpenAIKey) -> some View {
		let text = switch api {
		case .ollama: $store.ollamaKey
		case .openAI: $store.openAIKey
		case .openRouter: $store.openRouterKey
		}

		TextField("Secret Key", text: text)
			.focused($focusedField, equals: api.field)
			.autocorrectionDisabled()

		if api == .ollama {
			TextField("Base URL", text: $store.ollamaBaseURL)
				.focused($focusedField, equals: .ollamaBaseURL)
				.autocorrectionDisabled()
		}
	}
}

private extension CompatibleOpenAIKey {
	var field: SettingsAPIView.Field {
		switch self {
		case .ollama: .ollamaKey
		case .openAI: .openAIKey
		case .openRouter: .openRouterKey
		}
	}
}
