import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import Cortexia

@MainActor
struct SettingsFeatureTests {
	@Test func viewDidAppearFetchModels() async throws {
		let store = makeStore()

		store.dependencies.keychainService = KeychainServiceStub().service
		try await store.dependencies.keychainService.save("secretKey", for: .openAISecretKey)

		store.dependencies.openAIService.fetchModels = { _ in ModelResponse.mock }

		await store.send(.view(.viewDidAppear))

		await store.receive(.internal(.secretKeyLoaded("secretKey")), timeout: 1) {
			$0.secretAPIKey = "secretKey"
		}

		let expectedModels: [ModelResponse.Model] = [
			.init(id: "model1", ownedBy: "openAI"),
			.init(id: "model2", ownedBy: "openAI"),
		]

		await store.receive(.internal(.openAIModelsFetched(expectedModels)), timeout: 1) {
			$0.openAIModels = .init(uniqueElements: expectedModels)
		}
	}

	@Test func viewDidAppearFetchModelsMissingSecretKey() async throws {
		let store = makeStore()

		store.dependencies.openAIService.fetchModels = { _ in throw AIClientError.invalidSecretKey }

		await store.send(.view(.viewDidAppear))

		await store.receive(.internal(.secretKeyInvalid)) {
			$0.isSecretKeyInvalid = true
		}
	}

	@Test func modelButtonTapped() async throws {
		let store = makeStore()

		store.dependencies.keychainService = KeychainServiceStub().service
		try await store.dependencies.keychainService.save("secretKey", for: .openAISecretKey)

		store.dependencies.openAIService.fetchModels = { _ in ModelResponse.mock }

		await store.send(.view(.viewDidAppear))
		await store.skipReceivedActions()

		await store.send(.view(.modelButtonTapped)) {
			$0.isLoadingModels = true
		}

		let expectedModels: [ModelResponse.Model] = [
			.init(id: "model1", ownedBy: "openAI"),
			.init(id: "model2", ownedBy: "openAI"),
		]

		await store.receive(.internal(.openAIModelsFetched(expectedModels)), timeout: 1)

		await store.receive(.internal(.hasRefetchedModels), timeout: 1) {
			$0.route = .models
			$0.isLoadingModels = false
		}
	}

	@Test(arguments: [true, false])
	func darModeChanged(enabled: Bool) async throws {
		let store = makeStore()

		await store.send(.view(.darkModeChanged(enabled))) {
			$0.darkModeEnabled = enabled
		}
	}

	@Test(arguments: [true, false])
	func wordWrapChanged(enabled: Bool) async throws {
		let store = makeStore()

		await store.send(.view(.wordWrapChanged(enabled))) {
			$0.wordWrapEnabled = enabled
		}
	}

	@Test func secretAPIKeyChanged() async throws {
		let store = makeStore()
		let mainScheduler = DispatchQueue.test
		let keychainServiceStub = KeychainServiceStub()

		store.dependencies.keychainService = keychainServiceStub.service
		try await store.dependencies.keychainService.delete(.openAISecretKey)

		store.dependencies.mainQueue = mainScheduler.eraseToAnyScheduler()

		await store.send(.binding(.set(\.secretAPIKey, "k"))) {
			$0.isSecretKeyInvalid = false
			$0.secretAPIKey = "k"
		}

		await mainScheduler.advance(by: 0.1)

		var openAISecretKey: String? = try? await keychainServiceStub.service.load(.openAISecretKey)
		#expect(openAISecretKey == nil)

		await store.send(.binding(.set(\.secretAPIKey, "ke"))) {
			$0.isSecretKeyInvalid = false
			$0.secretAPIKey = "ke"
		}

		await mainScheduler.advance(by: 0.1)

		openAISecretKey = try? await keychainServiceStub.service.load(.openAISecretKey)
		#expect(openAISecretKey == nil)

		await store.send(.binding(.set(\.secretAPIKey, "key"))) {
			$0.isSecretKeyInvalid = false
			$0.secretAPIKey = "key"
		}

		await mainScheduler.advance(by: 0.3)

		openAISecretKey = try? await keychainServiceStub.service.load(.openAISecretKey)
		#expect(openAISecretKey == "key")
	}

	@Test func selectModelChanged() async throws {
		let store = makeStore()

		await store.send(.binding(.set(\.selectedModelID, "model"))) {
			$0.selectedModelID = "model"
			$0.route = nil
		}
	}
}

extension SettingsFeatureTests {
	private func makeStore() -> TestStoreOf<SettingsFeature> {
		.init(
			initialState: SettingsFeature.State(),
			reducer: { SettingsFeature() },
			withDependencies: {
				$0.mainQueue = .immediate
			}
		)
	}
}
