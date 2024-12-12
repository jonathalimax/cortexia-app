import ComposableArchitecture
import SwiftUI

@ViewAction(for: PromptEditorFeature.self)
struct PromptEditorView: View {
	@Bindable var store: StoreOf<PromptEditorFeature>
	@FocusState private var focusedField: FocusedField?

	enum FocusedField {
		case editor
	}

	var body: some View {
		ZStack {
			Color.adaptiveBackground
				.background(.ultraThickMaterial)

			TextEditor(text: $store.text)
				.padding()
				.scrollContentBackground(.hidden)
				.focused($focusedField, equals: .editor)
				.onAppear { focusedField = .editor }
		}
		.clipShape(.rect(cornerRadius: 16))
		.padding()
		.navigationTitle("Editor")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				if !store.text.isEmpty {
					Button(action: { send(.saveButtonTapped) }) {
						Text("Save")
					}
				}
			}
		}
	}
}

#Preview {
	NavigationView {
		PromptEditorView(
			store: .init(
				initialState: PromptEditorFeature.State(),
				reducer: { PromptEditorFeature() }
			)
		)
	}
}
