import ComposableArchitecture
import SwiftUI
import SwiftData

@ViewAction(for: AppFeature.self) @main
struct CortexiaApp: App {
	@Bindable var store: StoreOf<AppFeature>

	init() {
		self.store = .init(initialState: AppFeature.State(), reducer: { AppFeature() })
		send(.applicationStarted)
	}

	var body: some Scene {
		WindowGroup {
			ChatView(store: store.scope(state: \.chatState, action: \.chat))
				.preferredColorScheme(store.darkModeEnabled ? .dark : .light)
				.onOpenURL { send(.receivedDeepLink($0)) }
		}
	}
}
