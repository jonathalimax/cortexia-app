public enum CompatibleOpenAIKey: String, Codable, CaseIterable {
	case openAI
	case openRouter
	case ollama

	var name: String {
		switch self {
		case .openAI: "OpenAI"
		case .ollama: "Ollama"
		case .openRouter: "OpenRouter"
		}
	}
}
