import FairApp

/// The settings view for app.
public struct SettingsView : View {
    public enum Tabs: Hashable {
        case general
        case advanced
    }

    public var body: some View {
        TabView {
            GeneralSettingsView()
                .padding(20)
                .tabItem {
                    Text("General", bundle: .module, comment: "general preferences tab title")
                        .label(image: FairSymbol.switch_2)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            AdvancedSettingsView()
                .padding(20)
                .tabItem {
                    Text("Advanced", bundle: .module, comment: "advanced preferences tab title")
                        .label(image: FairSymbol.gearshape)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 600)
    }
}

struct GeneralSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
        Form {
            TextField(text: $store.homePage) {
                Text("Home Page", bundle: .module, comment: "label for general preference text field for the home page")
            }

            ThemeStylePicker(style: store.$themeStyle)
        }
    }
}

/// The preferred theme style for the app
public enum ThemeStyle: String, CaseIterable {
    case system
    case light
    case dark
}

extension ThemeStyle : Identifiable {
    public var id: Self { self }

    public var label: Text {
        switch self {
        case .system: return Text("System", bundle: .module, comment: "theme style preference radio label for using the system theme")
        case .light: return Text("Light", bundle: .module, comment: "theme style preference radio label for using the light theme")
        case .dark: return Text("Dark", bundle: .module, comment: "theme style preference radio label for using the dark theme")
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}


@available(macOS 12.0, iOS 15.0, *)
struct ThemeStylePicker: View {
    @Binding var style: ThemeStyle

    var body: some View {
        Picker(selection: $style) {
            ForEach(ThemeStyle.allCases) { themeStyle in
                themeStyle.label
            }
        } label: {
            Text("Theme:", bundle: .module, comment: "label for general preferences picker for choosing the theme style")
        }
        .radioPickerStyle()
    }
}

extension Picker {
    /// On macOS, sets the style as a radio picker style.
    /// On other platforms, has no effect.
    func radioPickerStyle() -> some View {
        #if os(macOS)
        self.pickerStyle(RadioGroupPickerStyle())
        #else
        self
        #endif
    }
}


struct AdvancedSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Form {
            TextField(text: $store.searchHost) {
                Text("Search Provider", bundle: .module, comment: "label for advanced preference text field for the search provider")
            }
        }
        .padding()
    }
}


