import FairApp
import Busq

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(self.deviceList) { device in
                        let client = Result {
                            try Device(udid: device.udid, options: device.connectionType == .network ? .network : .usbmux).createLockdownClient()
                        }

                        NavigationLink {
                            if let client = client.successValue,
                               let iproxy = try? client.createInstallationProxy(),
                               let appsList = try? iproxy.getAppList(type: .any) {
                                AppsListView(client: client, proxy: iproxy, apps: appsList)
                            }
                        } label: {
                            Label {
                                VStack(alignment: .leading) {
                                    Text((try? client.successValue?.deviceName) ?? "Unknown Name")
                                    Text((try? client.successValue?.productVersion) ?? "Unknown Version")
                                        .foregroundColor(Color.secondary)
                                        .font(Font.caption)
                                    // Text((try? client.successValue?.uniqueDeviceID) ?? "Unknown")
                                }
                            } icon: {
                                device.connectionType == .usbmuxd ? FairSymbol.cable_connector_horizontal : FairSymbol.wifi
                            }
                        }
                    }
                } header: {
                    Text("Devices")
                }
            }
            .listStyle(.automatic)

            List {
                Text("No Apps")
            }

            Text("No App Selected")
                .font(.title)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var deviceList: [DeviceInfo] {
        do {
            return try MobileDevice.getDeviceListExtended()
        } catch {
            dbg("error getting device list:", error)
            return []
        }
    }
}

extension DeviceInfo : Identifiable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(udid)
        hasher.combine(connectionType)
    }

    public static func == (lhs: DeviceInfo, rhs: DeviceInfo) -> Bool {
        lhs.udid == rhs.udid && lhs.connectionType == rhs.connectionType
    }

    public var id: Self {
        self
    }
}

struct AppsListView : View {
    let client: LockdownClient
    let proxy: InstallationProxy
    let apps: [InstalledAppInfo]

    var body: some View {
        List {
            ForEach(apps.sorting(by: \.CFBundleDisplayName), id: \.CFBundleIdentifier) { app in
                NavigationLink {
                    AppInfoView(appInfo: app)
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(app.CFBundleDisplayName ?? "")
                                    .lineLimit(1)
                                    .allowsTightening(true)

                                if app.CFBundleName != app.CFBundleDisplayName {
                                    Text("(" + (app.CFBundleName ?? "") + ")")
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                }

                                Text(app.CFBundleShortVersionString ?? "")
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                    .foregroundColor(Color.secondary)
                            }
                            HStack {
                                Text(app.CFBundleIdentifier ?? "")
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                    //.font(Font.body.monospaced())
                                    .foregroundColor(Color.secondary)

//                                Text(app.SignerIdentity ?? "")
//                                    .lineLimit(1)
//                                    .allowsTightening(true)
//                                    .font(Font.caption.monospaced())
//                                    .foregroundColor(Color.secondary)
                            }
                        }
                    } icon: {
                        switch app.ApplicationType {
                        case "System":
                            FairSymbol.app_badge
                        case "User":
                            FairSymbol.app_gift
                        case "Internal":
                            FairSymbol.app_badge_checkmark
                        default:
                            FairSymbol.case
                        }
                    }
                }
            }
        }
    }

}

struct AppInfoView : View {
    let appInfo: InstalledAppInfo

    var body: some View {
        Form {
            Text(appInfo.CFBundleDisplayName ?? "")
        }
    }
}

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("someToggle") public var someToggle = false
}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView().environmentObject(store)
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Toggle(isOn: $store.someToggle) {
            Text("Toggle")
        }
        .padding()
    }
}
