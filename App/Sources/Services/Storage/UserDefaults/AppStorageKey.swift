import Dependencies

public enum LocalStorageKey: String {
	/// Whether dark mode is enabled
	case darkModeEnabled
	/// Generative AI selected model id
	case selectedModelID
	/// Whether AI response should wrap texts
	case wordWrapEnabled
	/// Selected compatible openAI API
	case selectedAPI
	/// Ollama API URL
	case ollamaBaseURL
	/// Is used to control the randomness of the output
	case selectedTemperature
}


// MARK: Computed variables
import Foundation

extension UserDefaults {
	var isOpenAIAPISelected: Bool {
		let selectedAPI = self.string(forKey: .selectedAPI) ?? ""
		return CompatibleOpenAIKey(rawValue: selectedAPI) == .openAI
	}
}
