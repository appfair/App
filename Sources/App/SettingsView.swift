import FairApp

/// The settings view for app.
public struct SettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Form {
            Toggle(isOn: $store.someToggle) {
                Text("Toggle", bundle: .module, comment: "a preferences toggle in the settings view")
            }
        }
        .padding()
    }
}
