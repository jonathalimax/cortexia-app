import Foundation

extension Data {
	var prettyPrinted: String {
		guard
			let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
			let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
			let prettyString = String(data: prettyData, encoding: .utf8)
		else { return "\(self)" }

		return prettyString
	}
}
