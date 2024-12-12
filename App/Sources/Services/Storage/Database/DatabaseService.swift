import Dependencies
import SwiftData

/// A service that provides access to the database, including model containers and batch operations.
class DatabaseService {
	/// An optional `ModelContainer` used for database operations.
	var modelContainer: ModelContainer? = nil
	/// A Boolean value indicating whether the database should be stored in memory only.
	var isStoredInMemoryOnly: Bool = false

	enum Error: Swift.Error {
		/// `ModelContainer` has not been registered.
		case containerNotRegistered
	}

	init(isStoredInMemoryOnly: Bool = false) {
		self.isStoredInMemoryOnly = isStoredInMemoryOnly
	}

	/// Registers a `ModelContainer` for the database with a specified configuration.
	///
	/// This method initializes a `ModelContainer` with the provided schema and configuration.
	/// It should be called before performing any database operations to ensure that the `ModelContainer`
	/// is available and properly configured.
	func registerContainer() {
		// Define the schema for the database.
		let schema = Schema([ChatMessage.self, GenerativeAIModel.self, Prompt.self])
		let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
		self.modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration])
	}

	/// Saves changes to the main context of the `ModelContainer`.
	/// - Throws: An error if the save operation fails.
	@MainActor
	func save() throws -> Void {
		try modelContainer?.mainContext.save()
	}

	/// Inserts an array of persistent models into the database.
	///
	/// This method creates a new model context for the `ModelContainer` and inserts each value into it.
	/// After insertion, the context is saved to persist the changes.
	///
	/// - Parameter values: The array of persistent models to insert.
	/// - Throws: An error if the `ModelContainer` is not registered or if the save operation fails.
	@MainActor
	func insert<P: PersistentModel>(_ values: [P]) async throws {
		guard let modelContainer else { throw Error.containerNotRegistered }

		// Create a new model context for the model container.
		let modelContext = ModelContext(modelContainer)

		// Insert each value into the model context.
		for value in values {
			modelContext.insert(value)
		}

		// Save the model context to persist the changes.
		try modelContext.save()
	}

	/// Fetches persistent models from the database using a fetch descriptor.
	///
	/// This method performs a fetch operation based on the provided `FetchDescriptor`,
	/// which defines the query parameters for fetching data.
	///
	/// - Parameter descriptor: A `FetchDescriptor` that defines the query parameters for fetching data.
	/// - Returns: An array of instances of the model type `P` that match the criteria defined in the `descriptor`.
	/// - Throws: An error if the `ModelContainer` is not registered or if the fetch operation fails.
	@MainActor
	func fetch<P: PersistentModel>(_ descriptor: FetchDescriptor<P>) async throws -> [P] {
		guard let mainContext = modelContainer?.mainContext else { throw Error.containerNotRegistered }
		return try mainContext.fetch(descriptor)
	}

	/// Deletes a persistent model from the database.
	/// - Parameter item: The persistent model to delete.
	/// - Throws: An error if the `ModelContainer` is not registered or if the delete operation fails.
	@MainActor
	func delete<P: PersistentModel>(_ item: [P]) throws {
		guard let mainContext = modelContainer?.mainContext else { throw Error.containerNotRegistered }

		for unit in item {
			mainContext.delete(unit)
		}

		try mainContext.save()
	}
}

// MARK: - Dependency Registration
extension DatabaseService: DependencyKey {
	public static var liveValue: DatabaseService = .init()
	public static var testValue: DatabaseService = .init(isStoredInMemoryOnly: true)
	public static var previewValue: DatabaseService = .init(isStoredInMemoryOnly: true)
}

extension DependencyValues {
	var databaseService: DatabaseService {
		get { self[DatabaseService.self] }
		set { self[DatabaseService.self] = newValue }
	}
}
