import FairApp

/// The settings view for app.
public struct SettingsView : View {
    @EnvironmentObject var store: Store
    @AppStorage("searchCount") var searchCount: Int = 250

    public var body: some View {
        Form {
            Toggle(isOn: $store.autoplayStation) {
                Text("Auto-play stations when selected", bundle: .module, comment: "preferences toggle for auto-playing stations")
            }
            .help(Text("Whether to automatically start playing selected stations.", bundle: .module, comment: "help text for preferences toggle for auto-playing stations"))
        }
        .padding()
    }
}

