import FairApp
import Busq
import SwiftUI

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("someToggle") public var someToggle = false
    @Published var deviceMap: [DeviceConnectionInfo: Result<LockdownClient, Error>] = [:]
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
            let deviceInfos = try DeviceManager.getDeviceListExtended()
            var deviceMap: [DeviceConnectionInfo: Result<LockdownClient, Error>] = [:]
            for deviceInfo in deviceInfos {
                deviceMap[deviceInfo] = Result {
                    try Device(udid: deviceInfo.udid, options: deviceInfo.connectionType == .network ? .network : .usbmux).createLockdownClient()
                }
            }
            let dmap = deviceMap // else error: “Reference to captured var 'deviceMap' in concurrently-executing code”
            DispatchQueue.main.async {
                withAnimation {
                    self.deviceMap = dmap
                }
            }
        } catch {
            dbg("error getting device list:", error)
            withAnimation {
                self.deviceMap = [:]
            }

        }
    }
}

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store
    @State var selection: DeviceConnectionInfo?

    public var body: some View {
        NavigationView {
            List(selection: $selection) {
                Section {
                    ForEach(store.deviceMap.keys.sorting(by: \.udid)) { info in
                        if let client = store.deviceMap[info]?.successValue {
                            NavigationLink {
                                DeviceAppListSplitView()
                                    .environmentObject(client)
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

            Text("No Device Selected")
                .font(.title)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            DeviceInfoView(selection: selection)
                .frame(idealWidth: 200)
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

/// The righmost panel containing a lsit of the properties for the selected device
struct DeviceInfoView: View {
    @EnvironmentObject var store: Store
    var selection: DeviceConnectionInfo?

    @ViewBuilder var body: some View {
        ScrollView {
            if let selection = selection {
                switch store.deviceMap[selection] {
                case .none:
                    Text("No Device Selected")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .some(.failure(let error)):
                    Text("Error: \(error.localizedDescription)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .some(.success(let client)):
                    appDeviceInfoView(client)
                }
            } else {
                Spacer()
            }
        }
    }

    /// A list of properties of a device
    func appDeviceInfoView(_ client: LockdownClient) -> some View {
        func keyRow(domain: String? = nil, _ key: String) -> some View {
            let value: Busq.Plist?
            let accessError: Error?

            do {
                value = try client.getValue(domain: domain, key: key)
                accessError = nil
            } catch {
                accessError = error
                value = nil
            }

            switch value?.nodeType {
            case nil:
                return row(title: key, value: accessError?.localizedDescription)
            case .boolean:
                return row(title: key, value: value?.bool?.description)
            case .uint:
                return row(title: key, value: value?.uint?.description)
            case .real:
                return row(title: key, value: value?.real?.description)
            case .string:
                return row(title: key, value: value?.string?.description)
            case .array:
                return row(title: key, value: "Array")
            case .dict:
                return row(title: key, value: "Dictionary")
            case .date:
                return row(title: key, value: value?.date?.description)
            case .data:
                return row(title: key, value: value?.data?.description)
            case .key:
                return row(title: key, value: value?.key?.description)
            case .uid:
                return row(title: key, value: value?.uid?.description)
            case .some(.none):
                return row(title: key, value: "None")
            }
        }


        return Form {
            Group {
                HStack {
                    Text("Device Info")
                        .font(.headline)
                }
                Group {
                    keyRow("DeviceName")
                    keyRow("DeviceClass")
                    keyRow("ProductName")
                    keyRow("ProductType")
                    keyRow("ProductVersion")
                }

                Group {
                    keyRow("ModelNumber")
                    keyRow("PasswordProtected")
                    keyRow(domain: "com.apple.mobile.battery", "BatteryCurrentCapacity")
                    keyRow(domain: "com.apple.mobile.battery", "BatteryIsCharging")
                    keyRow("CPUArchitecture")
                }

                Group {
                    keyRow("ActiveWirelessTechnology")
                    keyRow("AirplaneMode")
                    //keyRow("assistant")
                    keyRow("BasebandCertId")
                    keyRow("BasebandChipId")
                    keyRow("BasebandPostponementStatus")
                    keyRow("BasebandStatus")
                }

                Group {
                    keyRow("BluetoothAddress")
                    keyRow("BoardId")
                    keyRow("BootNonce")
                    keyRow("BuildVersion")
                    keyRow("CertificateProductionStatus")
                    keyRow("CertificateSecurityMode")
                    keyRow("ChipID")
                    keyRow("CompassCalibrationDictionary")
                }
            }

            Group {
                Text("Extended Info")
                    .font(.headline)

                Group {
                    keyRow("DeviceColor")
                    keyRow("DeviceEnclosureColor")
                    //keyRow("DeviceEnclosureRGBColor")
                    //keyRow("DeviceRGBColor")
                    keyRow("DeviceSupportsFaceTime")
                    keyRow("DeviceVariant")
                    keyRow("DeviceVariantGuess")
                }

                Group {
                    //keyRow("DiagData")
                    //keyRow("dictation")
                    //keyRow("DiskUsage")
                    keyRow("EffectiveProductionStatus")
                    keyRow("EffectiveProductionStatusAp")
                    keyRow("EffectiveProductionStatusSEP")
                    // keyRow("EffectiveSecurityMode")
                    keyRow("EffectiveSecurityModeAp")
                    keyRow("EffectiveSecurityModeSEP")
                }

                Group {
                    keyRow("FirmwarePreflightInfo")
                    keyRow("FirmwareVersion")
                    //keyRow("FrontFacingCameraHFRCapability")
                    keyRow("HardwarePlatform")
                    keyRow("HasSEP")
                    // keyRow("HWModelStr")
                    keyRow("Image4Supported")
                    // keyRow("InternalBuild")
                    // keyRow("InverseDeviceID")
                }

                Group {
                    // keyRow("ipad")
                    keyRow("MixAndMatchPrevention")
                    keyRow("MLBSerialNumber")
                    keyRow("MobileSubscriberCountryCode")
                    keyRow("MobileSubscriberNetworkCode")
                    keyRow("PartitionType")
                }
            }

            Group {
                Group {
                    // keyRow("ProximitySensorCalibrationDictionary")
                    //keyRow("RearFacingCameraHFRCapability")
                    keyRow("RegionCode")
                    keyRow("RegionInfo")
                    //keyRow("SDIOManufacturerTuple")
                    //keyRow("SDIOProductInfo")
                    keyRow("SerialNumber")
                    keyRow("SIMTrayStatus")
                    keyRow("SoftwareBehavior")
                }

                Group {
                    keyRow("SoftwareBundleVersion")
                    keyRow("SupportedDeviceFamilies")
                    //keyRow("SupportedKeyboards")
                    //keyRow("telephony")
                    keyRow("UniqueChipID")
                    keyRow("UniqueDeviceID")
                    //keyRow("UserAssignedDeviceName")
                    //keyRow("wifi")
                    keyRow("WifiVendor")
                }
            }
        }
        .controlSize(.small)
        .padding()

    }

    @ViewBuilder func row(title: String, value: String?) -> some View {
        TextField(text: .constant(value ?? ""), prompt: Text("Unknown")) {
            (Text(title) + Text(":"))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(Text(title))
                .layoutPriority(0)
        }
        .layoutPriority(1)
        .textFieldStyle(.plain)
        .textSelection(.enabled)
    }


}

/// A vertical split view containing a list of apps for the device, below which is the information about the selected app
/// This uses the undocumented behavior of a NavigationLink such that it will use the next available split for displaying the destination of the link.
struct DeviceAppListSplitView : View {
    @EnvironmentObject var client: LockdownClient
    @State var apps: [InstalledAppInfo] = []

    var body: some View {
        // this split view allows us to override the 3-panel navigation behavior such that selecting an item from the list will make its navigation destination appear here (below the list) rather than in the panel on the right
        VSplitView {
            appListView
            Text("No App Selected")
                .font(.title)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder var appListView: some View {
        if let iproxy = try? client.createInstallationProxy(),
           let sbcient = try? client.createSpringboardServiceClient() {
            AppsListView(apps: $apps)
                .environmentObject(sbcient)
                .environmentObject(iproxy)
                .task {
                    DispatchQueue.global().async {
                        do {
                            let appList = try iproxy.getAppList(type: .any)
                            DispatchQueue.main.async {
                                withAnimation {
                                    self.apps = appList
                                }
                            }
                        } catch {
                            dbg("error getting app list:", error)
                        }
                    }
                }
        }
    }
}

extension SpringboardServiceClient : ObservableObject {
}

extension InstallationProxy : ObservableObject {
}

extension LockdownClient : ObservableObject {
}

struct AppsListView : View {
    @EnvironmentObject var client: LockdownClient
    @EnvironmentObject var proxy: InstallationProxy
    @EnvironmentObject var springboard: SpringboardServiceClient
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
            ForEach(apps.sorting(by: \.CFBundleDisplayName), id: \.CFBundleIdentifier) { appInfo in
                AppInfoLink(appInfo: appInfo)
            }
        } header: {
            Text(type.rawValue) + Text(" ") + Text("Apps") + Text(" (") + Text(apps.count, format: .number) + Text(")")
        }
    }
}

struct AppInfoLink : View {
    let appInfo: InstalledAppInfo
    @State var icon: Image?
    @EnvironmentObject var springboard: SpringboardServiceClient

    var body: some View {
        NavigationLink {
            AppInfoView(appInfo: appInfo, icon: $icon)
        } label: {
            AppItemLabel(appInfo: appInfo, icon: $icon)
        }
        .task {
            if let bundleID = appInfo.CFBundleIdentifier {
                if let pngData = try? springboard.getIconPNGData(bundleIdentifier: bundleID) {
                    if let img = UXImage(data: pngData) {
                        self.icon = Image(uxImage: img)
                            .resizable()
                    }
                }
            }
        }

    }
}

struct AppItemLabel : View {
    let appInfo: InstalledAppInfo
    @Binding var icon: Image?

    var body: some View {
        HStack {
            Group {
                if let icon = icon {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.secondary)
                }
            }
            .frame(width: 35, height: 35)

            VStack(alignment: .leading) {
                HStack {
                    Group {
                        Text(appInfo.CFBundleDisplayName ?? "")
                            .lineLimit(1)
                            .allowsTightening(true)

                        if appInfo.CFBundleName != appInfo.CFBundleDisplayName {
                            Text("(" + (appInfo.CFBundleName ?? "") + ")")
                                .lineLimit(1)
                                .allowsTightening(true)
                        }
                    }
                    .frame(minWidth: 20)
                    // .frame(minWidth: 45) // expands short text too much
                    .layoutPriority(1)

                    Spacer()

                    Text(appInfo.CFBundleShortVersionString ?? "")
                        .lineLimit(1)
                        .allowsTightening(true)
                        .foregroundColor(Color.secondary)
                        .font(Font.body.monospacedDigit())
                }
                HStack {
                    Text(appInfo.CFBundleIdentifier ?? "")
                        .lineLimit(1)
                        .allowsTightening(true)
                        //.font(Font.body.monospaced())
                        .truncationMode(.middle)
                        .foregroundColor(Color.secondary)

                    Spacer()

                    appCapabilityIcons()
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
    }

    func appCapabilityIcons() -> some View {
        HStack(spacing: 2) {
            Group { // voice
                icon(appInfo.NSSiriUsageDescription, "Siri", .ear)
                icon(appInfo.NSSpeechRecognitionUsageDescription, "Speech Recognition", .waveform)
            }
            .foregroundStyle(Color.cyan)

            Group { // hardware
                icon(appInfo.NSMicrophoneUsageDescription, "Microphone", .mic_circle)
                icon(appInfo.NSCameraUsageDescription, "Camera", .camera)
                icon(appInfo.NSMotionUsageDescription, "Motion", .gyroscope)
                icon(appInfo.NFCReaderUsageDescription, "NFC Reader", .barcode_viewfinder)
                icon(appInfo.NSBluetoothUsageDescription, "Bluetooth", .cable_connector)
                icon(appInfo.NSBluetoothAlwaysUsageDescription, "Bluetooth (Always)", .cable_connector_horizontal)
                icon(appInfo.NSBluetoothPeripheralUsageDescription, "Bluetooth (peripheral)", .printer)
            }
            .foregroundStyle(Color.mint)

            Group { // databases
                icon(appInfo.NSRemindersUsageDescription, "Reminders", .text_badge_checkmark)
                icon(appInfo.NSContactsUsageDescription, "Contacts", .person_text_rectangle)
                icon(appInfo.NSCalendarsUsageDescription, "Calendars", .calendar)
                icon(appInfo.NSPhotoLibraryAddUsageDescription, "Photo Library Add", .text_below_photo_fill)
                icon(appInfo.NSPhotoLibraryUsageDescription, "Photo Library", .photo)
            }
            .foregroundStyle(Color.green)

            Group { // services
                icon(appInfo.NSAppleMusicUsageDescription, "Apple Music", .music_note)
                icon(appInfo.NSHomeKitUsageDescription, "HomeKit", .house)
                icon(appInfo.NSVideoSubscriberAccountUsageDescription, "Video Subscriber Account Usage", .sparkles_tv)
                icon(appInfo.NSHealthShareUsageDescription, "Health Sharing", .stethoscope)
                icon(appInfo.NSHealthUpdateUsageDescription, "Health Update", .stethoscope_circle)
            }
            .foregroundStyle(Color.mint)

            Group { // misc
                icon(appInfo.NSAppleEventsUsageDescription, "Apple Events", .scroll)
                icon(appInfo.NSFocusStatusUsageDescription, "Focus Status", .eyeglasses)
                icon(appInfo.NSLocalNetworkUsageDescription, "Local Network", .network)
                icon(appInfo.NSFaceIDUsageDescription, "Face ID", .viewfinder)
            }
            .foregroundStyle(Color.gray)

            Group { // location
                icon(appInfo.NSLocationUsageDescription, "Location", .location_magnifyingglass)
                icon(appInfo.NSLocationAlwaysUsageDescription, "Location (Always)", .location_fill)
                icon(appInfo.NSLocationTemporaryUsageDescriptionDictionary, "Location (Temporary)", .location)
                icon(appInfo.NSLocationWhenInUseUsageDescription, "Location (When in use)", .location_north)
                icon(appInfo.NSLocationAlwaysAndWhenInUseUsageDescription, "Location (Always and when in use)", .location_fill_viewfinder)
            }
            .foregroundStyle(Color.blue)

            Group { // tracking
                icon(appInfo.NSUserTrackingUsageDescription, "User Tracking", .eyes)
            }
            .foregroundStyle(Color.pink)
        }
        .symbolRenderingMode(SwiftUI.SymbolRenderingMode.palette)
    }


    @ViewBuilder func icon(_ value: String?, _ desc: String, _ symbol: FairSymbol) -> some View {
        if let value = value {
            symbol
                .help(Text(desc) + Text(": ") + Text(value))
        }
    }
}

struct AppInfoView : View {
    let appInfo: InstalledAppInfo
    @Binding var icon: Image?

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
                    TextField(text: .constant(appInfo.CFBundleDisplayName ?? ""), prompt: Text("Unknown")) {
                        icon.aspectRatio(contentMode: .fit)
                            .frame(height: 25)
                    }
                    .font(Font.largeTitle)
                    .textFieldStyle(.plain)
                    .textSelection(.enabled)
                    //.disabled(true)
                    //.frame(alignment: .center)
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
        .textFieldStyle(.squareBorder)
        .textSelection(.enabled)
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
