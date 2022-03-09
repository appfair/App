import FairApp
import Busq

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("someToggle") public var someToggle = false
    @Published var deviceList: [DeviceConnectionInfo] = []
    var deviceEventSubscription: Disposable?

    func subscribeToDeviceEvents() {
        do {
            self.deviceEventSubscription = try DeviceManager.eventSubscribe { event in
                dbg("event:", event)
                self.refreshDeviceList()
            }
        } catch {
            dbg("error subscribing to event:", error)
        }
    }

    func refreshDeviceList() {
        do {
            let devices = try DeviceManager.getDeviceListExtended()
            DispatchQueue.main.async {
                withAnimation {
                    self.deviceList = devices
                }
            }
        } catch {
            dbg("error getting device list:", error)
            withAnimation {
                self.deviceList = []
            }

        }
    }
}

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(store.deviceList) { info in
                        let client = Result {
                            try Device(udid: info.udid, options: info.connectionType == .network ? .network : .usbmux).createLockdownClient()
                        }

                        if let client = client.successValue {
                            NavigationLink {
                                LockdownClientAppListView(client: client)
                            } label: {
                                clientLabel(client, info: info)
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
        .task {
            store.subscribeToDeviceEvents()
        }
    }

    func clientLabel(_ client: LockdownClient, info: DeviceConnectionInfo) -> some View {
        Label {
            VStack(alignment: .leading) {
                Text((try? client.deviceName) ?? "Unknown Name")
                HStack {
                    let deviceName = (try? client.deviceClass) ?? "Unknown Device"
                    let batteryLevel = (try? client.batteryLevel) ?? 0
                    let batteryIcon = batteryLevel > 90 ? FairSymbol.battery_100
                        : batteryLevel > 60 ? .battery_75
                        : batteryLevel > 40 ? .battery_50
                        : batteryLevel > 10 ? .battery_25
                        : .battery_0
                    Text(deviceName)
                        .label(image: batteryIcon)
                        .foregroundColor(Color.secondary)
                        .font(Font.caption)
                        .help("Battery level: \(batteryLevel)%")
                    Text((try? client.productVersion) ?? "Unknown Version")
                        .foregroundColor(Color.secondary)
                        .font(Font.caption)
                }

                // Text((try? client.uniqueDeviceID) ?? "Unknown")
            }
        } icon: {
            info.connectionType == .usbmuxd ? FairSymbol.cable_connector_horizontal : FairSymbol.wifi
        }
    }
}

extension DeviceConnectionInfo : Identifiable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(udid)
        hasher.combine(connectionType)
    }

    public static func == (lhs: DeviceConnectionInfo, rhs: DeviceConnectionInfo) -> Bool {
        lhs.udid == rhs.udid && lhs.connectionType == rhs.connectionType
    }

    public var id: Self {
        self
    }
}

struct LockdownClientAppListView : View {
    let client: LockdownClient
    @State var apps: [InstalledAppInfo] = []

    var body: some View {
        if let iproxy = try? client.createInstallationProxy(),
           let sbcient = try? client.createSpringboardServiceClient() {
            AppsListView(client: client, proxy: iproxy, springboard: sbcient, apps: $apps)
                .task {
                    do {
                        self.apps = try iproxy.getAppList(type: .any)
                    } catch {
                        dbg("error getting app list:", error)
                    }
                }
        }
    }
}

struct AppsListView : View {
    let client: LockdownClient
    let proxy: InstallationProxy
    let springboard: SpringboardServiceClient
    @Binding var apps: [InstalledAppInfo]

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
                        if let bundleID = app.CFBundleIdentifier {
//                            do {
                            if let pngData = try? springboard.getIconPNGData(bundleIdentifier: bundleID) {
                                if let img = UXImage(data: pngData) {
                                    Image(uxImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }
                            }
//                            } catch {
//                                dbg("error getting PNG data for app:", bundleID, error)
//                            }
                        }

//                        switch app.ApplicationType {
//                        case "User":
//                            FairSymbol.star_circle
//                        case "System":
//                            FairSymbol.rosette
//                        case "Internal":
//                            FairSymbol.flag_2_crossed
//                        default:
//                            FairSymbol.case
//                        }
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
                        row(title: "Signer", value: appInfo.SignerIdentity)
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
