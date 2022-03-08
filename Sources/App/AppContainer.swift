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
            if !apps.isEmpty {
                appsSection(type: .user)
                appsSection(type: .system)
                //appsSection(type: .internal)
            }
//            if !archives.isEmpty {
//                archivesSection
//            }
        }
    }

    @ViewBuilder func appsSection(type: ApplicationType) -> some View {
        let apps = apps.filter { app in
            app.ApplicationType == type.rawValue
        }
        Section {
            ForEach(apps.sorting(by: \.CFBundleDisplayName), id: \.CFBundleIdentifier) { app in
                NavigationLink {
                    AppInfoView(appInfo: app)
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            HStack {
                                Group {
                                    Text(app.CFBundleDisplayName ?? "")
                                        .lineLimit(1)
                                        .allowsTightening(true)

                                    if app.CFBundleName != app.CFBundleDisplayName {
                                        Text("(" + (app.CFBundleName ?? "") + ")")
                                            .lineLimit(1)
                                            .allowsTightening(true)
                                    }
                                }
                                .frame(minWidth: 20)
                                // .frame(minWidth: 45) // expands short text too much
                                .layoutPriority(1)

                                Spacer()

                                Text(app.CFBundleShortVersionString ?? "")
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                    .foregroundColor(Color.secondary)
                                    .font(Font.body.monospacedDigit())
                            }
                            HStack {
                                Text(app.CFBundleIdentifier ?? "")
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                    //.font(Font.body.monospaced())
                                    .truncationMode(.middle)
                                    .foregroundColor(Color.secondary)

                                Spacer()

                                HStack(spacing: 2) {
                                    Group {
                                        icon(app.NSAppleEventsUsageDescription, .scroll)
                                        icon(app.NSBluetoothUsageDescription, .cable_connector)
                                        icon(app.NSLocationAlwaysUsageDescription, .location)
                                        icon(app.NSVideoSubscriberAccountUsageDescription, .sparkles_tv)
                                        icon(app.NSFocusStatusUsageDescription, .eyeglasses)
                                        icon(app.NFCReaderUsageDescription, .barcode_viewfinder)
                                        icon(app.NSHomeKitUsageDescription, .house)
                                        icon(app.NSRemindersUsageDescription, .lightbulb)
                                    }

                                    Group {
                                        icon(app.NSLocationTemporaryUsageDescriptionDictionary, .location_magnifyingglass)
                                        icon(app.NSSiriUsageDescription, .ear)
                                        icon(app.NSHealthShareUsageDescription, .stethoscope)
                                        icon(app.NSHealthUpdateUsageDescription, .stethoscope_circle)
                                        icon(app.NSSpeechRecognitionUsageDescription, .waveform)
                                        icon(app.NSLocationUsageDescription, .location)
                                        icon(app.NSMotionUsageDescription, .gyroscope)
                                        icon(app.NSLocalNetworkUsageDescription, .network)
                                    }

                                    Group {
                                        icon(app.NSAppleMusicUsageDescription, .music_note)
                                        icon(app.NSLocationAlwaysAndWhenInUseUsageDescription, .location_fill_viewfinder)
                                        icon(app.NSUserTrackingUsageDescription, .magnifyingglass)
                                        icon(app.NSBluetoothAlwaysUsageDescription, .cable_connector_horizontal)
                                        icon(app.NSFaceIDUsageDescription, .viewfinder)
                                        icon(app.NSBluetoothPeripheralUsageDescription, .printer)
                                        icon(app.NSCalendarsUsageDescription, .calendar)
                                    }

                                    Group {
                                        icon(app.NSContactsUsageDescription, .person_text_rectangle)
                                        icon(app.NSMicrophoneUsageDescription, .mic_circle)
                                        icon(app.NSPhotoLibraryAddUsageDescription, .photo_on_rectangle)
                                        icon(app.NSPhotoLibraryUsageDescription, .photo)
                                        icon(app.NSCameraUsageDescription, .camera)
                                        icon(app.NSLocationWhenInUseUsageDescription, .location_circle)
                                    }
                                }
                                .symbolRenderingMode(.hierarchical)
                            }
                        }
                    } icon: {
                        switch app.ApplicationType {
                        case "User":
                            FairSymbol.star_circle
                        case "System":
                            FairSymbol.rosette
                        case "Internal":
                            FairSymbol.flag_2_crossed
                        default:
                            FairSymbol.case
                        }
                    }
                }
            }
        } header: {
            Text(type.rawValue)
        }
    }

    @ViewBuilder func icon(_ value: String?, _ symbol: FairSymbol) -> some View {
        if let value = value {
            symbol
                .help(value)
        }
    }

}

struct AppInfoView : View {
    let appInfo: InstalledAppInfo

    var body: some View {

        ScrollView {
            Form {
                Section {
                    Group {
                        row(title: "Name", value: appInfo.CFBundleDisplayName)
                        row(title: "Version", value: appInfo.CFBundleShortVersionString)
                        row(title: "Path", value: appInfo.Path)
                        row(title: "Bundle ID", value: appInfo.CFBundleIdentifier)
                        row(title: "Signer Identity", value: appInfo.SignerIdentity)
                    }
                } header: {
                    Text(appInfo.CFBundleDisplayName ?? "")
                        .font(Font.largeTitle)
                }

                Divider()

                Section {
                    Group {
                        Group {
                            if let usage = appInfo.NSSiriUsageDescription {
                                row(title: "Siri", value: usage)
                            }
                            if let usage = appInfo.NSCameraUsageDescription {
                                row(title: "Camera", value: usage)
                            }
                            if let usage = appInfo.NSMotionUsageDescription {
                                row(title: "Motion", value: usage)
                            }
                            if let usage = appInfo.NSContactsUsageDescription {
                                row(title: "Contacts", value: usage)
                            }
                            if let usage = appInfo.NSLocationUsageDescription {
                                row(title: "Location", value: usage)
                            }
                            if let usage = appInfo.NSBluetoothUsageDescription {
                                row(title: "Bluetooth", value: usage)
                            }
                        }

                        Group {
                            if let usage = appInfo.NSCalendarsUsageDescription {
                                row(title: "Calendar", value: usage)
                            }
                            if let usage = appInfo.NSRemindersUsageDescription {
                                row(title: "Reminders", value: usage)
                            }
                            if let usage = appInfo.NSMicrophoneUsageDescription {
                                row(title: "Microphone", value: usage)
                            }
                            if let usage = appInfo.NSFaceIDUsageDescription {
                                row(title: "FaceID", value: usage)
                            }
                            if let usage = appInfo.NSHomeKitUsageDescription {
                                row(title: "Homekit", value: usage)
                            }
                            if let usage = appInfo.NSSpeechRecognitionUsageDescription {
                                row(title: "Speech", value: usage)
                            }
                        }
                    }
                } header: {
                    Text("Permissions")
                        .font(Font.headline)
                }
            }
            .padding()
        }
    }

    func row(title: LocalizedStringKey, value: String?) -> some View {
        TextField(text: .constant(value ?? ""), prompt: Text("Unknown")) {
            Text(title) + Text(":")
        }
        .textSelection(.disabled)

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
