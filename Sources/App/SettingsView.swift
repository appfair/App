import FairApp

/// The settings view for app.
public struct SettingsView : View {
    @EnvironmentObject var store: Store
    @Environment(\.locale) var locale

    public var body: some View {
        Form {
            Toggle(isOn: $store.currencyScore) {
                Text("Currency Score", bundle: .module, comment: "preferences for displaying the score as currency in the settings view")
            }
            Button {
                store.highScore = 0
            } label: {
                HStack {
                    Text("Reset High Score", bundle: .module, comment: "reset high score button title")
                    Spacer()
                    Text(score: .init(store.highScore), locale: store.currencyScore ? locale : nil)
                        .font(.body.monospacedDigit())
                }
            }

        }
    }
}
