enum TokenCost {
	struct ModelPricing {
		let inputPerMillion, outputPerMillion: Double
	}

	static var pricing: [String: ModelPricing] {
		[
			"gpt-3.5": ModelPricing(inputPerMillion: 2.0, outputPerMillion: 2.0),
			"gpt-4-8k": ModelPricing(inputPerMillion: 30.0, outputPerMillion: 60.0),
			"gpt-4-32k": ModelPricing(inputPerMillion: 60.0, outputPerMillion: 120.0),
			"gpt-4-1106-preview": ModelPricing(inputPerMillion: 10.0, outputPerMillion: 30.0),
			"chatgpt-4o-latest": ModelPricing(inputPerMillion: 5.0, outputPerMillion: 15.0),
			"dall-e-2": ModelPricing(inputPerMillion: 0.020, outputPerMillion: 0.020),
			"text-embedding-3-large": ModelPricing(inputPerMillion: 0.13, outputPerMillion: 0.13),
			"tts-1": ModelPricing(inputPerMillion: 5.0, outputPerMillion: 5.0),
			"tts-1-1106": ModelPricing(inputPerMillion: 6.0, outputPerMillion: 6.0),
			"gpt-4-0125-preview": ModelPricing(inputPerMillion: 10.0, outputPerMillion: 30.0),
			"gpt-3.5-turbo-0125": ModelPricing(inputPerMillion: 0.50, outputPerMillion: 1.50),
			"gpt-4-turbo-preview": ModelPricing(inputPerMillion: 10.0, outputPerMillion: 30.0),
			"gpt-3.5-turbo": ModelPricing(inputPerMillion: 3.0, outputPerMillion: 6.0),
			"whisper-1": ModelPricing(inputPerMillion: 0.0060, outputPerMillion: 0.006),
			"gpt-3.5-turbo-16k": ModelPricing(inputPerMillion: 3.0, outputPerMillion: 4.0),
			"text-embedding-3-small": ModelPricing(inputPerMillion: 0.02, outputPerMillion: 0.02),
			"gpt-4-turbo-2024-04-09": ModelPricing(inputPerMillion: 10.0, outputPerMillion: 30.0),
			"gpt-4-turbo": ModelPricing(inputPerMillion: 10.0, outputPerMillion: 30.0),
			"gpt-3.5-turbo-1106": ModelPricing(inputPerMillion: 1.0, outputPerMillion: 2.0),
			"tts-1-hd": ModelPricing(inputPerMillion: 7.0, outputPerMillion: 7.0),
			"tts-1-hd-1106": ModelPricing(inputPerMillion: 8.0, outputPerMillion: 8.0),
			"gpt-3.5-turbo-instruct-0914": ModelPricing(inputPerMillion: 1.5, outputPerMillion: 2.0),
			"gpt-4-0613": ModelPricing(inputPerMillion: 30.0, outputPerMillion: 60.0),
			"gpt-4": ModelPricing(inputPerMillion: 30.0, outputPerMillion: 60.0),
			"gpt-3.5-turbo-instruct": ModelPricing(inputPerMillion: 1.5, outputPerMillion: 2.0),
			"babbage-002": ModelPricing(inputPerMillion: 0.4, outputPerMillion: 0.4),
			"davinci-002": ModelPricing(inputPerMillion: 2.0, outputPerMillion: 2.0),
			"dall-e-3": ModelPricing(inputPerMillion: 0.040, outputPerMillion: 0.040),
			"gpt-4o-2024-05-13": ModelPricing(inputPerMillion: 5.0, outputPerMillion: 15.0),
			"gpt-4o-2024-08-06": ModelPricing(inputPerMillion: 2.5, outputPerMillion: 10.0),
			"gpt-4o": ModelPricing(inputPerMillion: 2.5, outputPerMillion: 10.0),
			"text-embedding-ada-002": ModelPricing(inputPerMillion: 1.0, outputPerMillion: 1.0),
			"gpt-4o-mini": ModelPricing(inputPerMillion: 0.15, outputPerMillion: 0.6),
			"gpt-4o-mini-2024-07-18": ModelPricing(inputPerMillion: 0.15, outputPerMillion: 0.6)
		]
	}
}
