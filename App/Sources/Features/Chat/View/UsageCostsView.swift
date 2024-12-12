import SwiftUI

struct UsageCostsView: View {
	@State private var currentToken: Int = .zero
	@State private var currentMoney: Double = .zero

	let token: Int
	let money: Double

	var body: some View {
		VStack(spacing: 16) {
			Text("Used tokens")
				.font(.title2)

			Text("\(currentToken)")
				.font(.largeTitle)
				.animation(.spring.delay(0.2), value: currentToken)
				.contentTransition(.numericText())

			Spacer()
				.frame(height: 8)

			Text("Cost")
				.font(.title2)

			Text(currentMoney.toCurrency ?? "$ 0")
				.font(.largeTitle)
				.animation(.spring(duration: 1).delay(0.8), value: currentMoney)
				.contentTransition(.numericText())
		}
		.task {
			startAnimating()
		}
	}

	private func startAnimating() {
		currentToken = token
		currentMoney = money
	}
}

#Preview {
	UsageCostsView(token: 100, money: 10)
}
