import ComposableArchitecture
import SwiftUI

@ViewAction(for: SettingsFeature.self)
struct SettingsView: View {
	@Bindable var store: StoreOf<SettingsFeature>

	var body: some View {
		Form {
			Section("OpenAI") {
				HStack {
					Text("Compatible APIs")

					Spacer()

					Image(systemName: "chevron.right")
						.foregroundColor(.gray)
				}
				.contentShape(Rectangle())
				.onTapGesture { send(.apiKeysItemTapped) }

				HStack {
					Text("Prompts")

					Spacer()

					Image(systemName: "chevron.right")
						.foregroundColor(.gray)
				}
				.contentShape(Rectangle())
				.onTapGesture { send(.promptsItemTapped) }

				HStack(spacing: 16) {
					Text("Model")

					Spacer()

					Button(action: { send(.modelButtonTapped) }) {
						if let selectedModel = store.selectedModel {
							Text(selectedModel.name)
						} else if store.isLoadingModels {
							ProgressView()
						} else {
							Text("Select")
						}
					}
				}

				VStack(alignment: .leading) {
					Text("Temperature: ") +
					Text(String(format: "%.1f", store.selectedTemperature))
						.fontWeight(.semibold)

					Slider(value: $store.selectedTemperature, in: 0...2, step: 0.1)
				}
			}

			Section("App") {
				Toggle("Dark mode", isOn: $store.darkModeEnabled.sending(\.view.darkModeChanged))

				Toggle("Word wrap", isOn: $store.wordWrapEnabled.sending(\.view.wordWrapChanged))
			}
		}
		.navigationTitle("Settings")
		.onAppear { send(.viewDidAppear) }
		.navigationDestination(
			item: $store.scope(state: \.route?.apiKeys, action: \.route.apiKeys),
			destination: SettingsAPIView.init
		)
		.navigationDestination(
			item: $store.scope(state: \.route?.prompts, action: \.route.prompts),
			destination: PromptsView.init
		)

		.sheet(
			item: $store.scope(state: \.route?.models, action: \.route.models),
			content: { _ in modelsList }
		)
	}

	private var modelsList: some View {
		Group {
			if store.isSecretKeyInvalid {
				errorView("Your secret key is invalid, insert your secret key correctly")

			} else if store.openAIModels.isEmpty {
				errorView("There is no models available, insert your secret key")

			} else {
				ScrollViewReader { proxy in
					List(store.openAIModels, id: \.id, selection: $store.selectedModelID) {
						Text($0.name)
							.id($0.id)
					}
					.padding(.top, 22)
					.listStyle(.plain)
					.onAppear {
						Task {
							try? await Task.sleep(seconds: 0.4)

							withAnimation(.easeOut) {
								proxy.scrollTo(store.selectedModelID, anchor: .top)
							}
						}
					}
				}
				.presentationDetents([.medium, .large])
			}
		}
		.presentationDragIndicator(.visible)
	}

	private func errorView(_ message: String) -> some View {
		Text(message)
			.font(.headline)
			.padding(.horizontal, 32)
			.multilineTextAlignment(.center)
			.presentationDetents([.medium])
	}
}

// MARK: - Helpers
private extension ModelResponse.Model {
	var name: String { id }
}

// MARK: - Previews
#Preview {
	NavigationStack {
		SettingsView(
			store: .init(
				initialState: SettingsFeature.State(),
				reducer: { SettingsFeature() }
			)
		)
	}
}
