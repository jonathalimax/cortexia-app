import Foundation

extension NumberFormatter {
	static let dollar = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencyCode = "USD"
		formatter.currencySymbol = "$"
		formatter.minimumFractionDigits = 0
		formatter.maximumFractionDigits = 4
		return formatter
	}()
}

extension Double {
	var toCurrency: String? {
		NumberFormatter.dollar.string(from: NSNumber(value: self))
	}
}
