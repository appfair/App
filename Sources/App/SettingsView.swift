import FairApp

/// The settings view for app.
public struct SettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Form {
            Toggle(isOn: $store.showScore) {
                Text("Show Score", bundle: .module, comment: "score preferences in the settings view")
            }
            Button {
                store.highScore = 0
            } label: {
                Text("Reset High Score", bundle: .module, comment: "reset high score button title")
            }

        }
    }
}
