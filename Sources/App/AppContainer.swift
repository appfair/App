import FairApp
import Busq

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        NavigationView {
            List {
                ForEach(self.deviceList) { device in
                    NavigationLink {
                        DeviceView(device: Result {
                            try Device(udid: device.udid, options: device.connectionType == .network ? .network : .usbmux)
                        })
                    } label: {
                        Text(device.udid)
                            .label(image: device.connectionType == .usbmuxd ? FairSymbol.cable_connector_horizontal : FairSymbol.wifi)

                    }
                }
            }
            .listStyle(.automatic)

            Text("No Device Selected")
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

struct DeviceView : View {
    let device: Result<Device, Error>

    var body: some View {
        switch device {
        case .failure(let error):
            Text(error.localizedDescription)
                .font(Font.headline.monospaced())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .success(let dev):
            deviceView(dev)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func deviceView(_ dev: Device) -> some View {
        Form {
            Text("Handle:")
            Text(try! dev.getHandle(), format: .number)
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
