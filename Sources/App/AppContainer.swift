import FairApp
import Busq
import SwiftUI
import UniformTypeIdentifiers

/// The shared app environment
@MainActor public final class Store: SceneManager {
    /// The signing identity for signing .ipa files
    @AppStorage("signingIdentity") public var signingIdentity = ""
    /// The developer team ID for signing .ipa files
    @AppStorage("teamID") public var teamID = ""
    /// The keychain that holds the signing certificate
    @AppStorage("keychainName") public var keychainName = ""

    @Published var selection: DeviceConnectionInfo?
    @Published var deviceMap: [DeviceConnectionInfo: Result<LockdownClient, Error>] = [:]
    /// Errors to be shown at the top level
    @Published var errors: [Error] = []
    var deviceEventSubscription: Disposable?

    /// Whether to display an initial error
    var presentedErrorExists: Binding<Bool> {
        Binding {
            self.errors.isEmpty == false
        } set: { newValue in
            if newValue == false && !self.errors.isEmpty {
                let _ = self.errors.removeFirst()
            }
        }
    }

    var presentedError: AppError? {
        errors.first.flatMap(AppError.init)
    }

    /// Returns the connection infos as will be displayed by the UI
    var connectionInfos: [DeviceConnectionInfo] {
        // TODO: sort by name, or something other than the udid
        deviceMap.keys.sorting(by: \.udid)
    }

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
                    try deviceInfo.createDevice().createLockdownClient()
                }
            }
            let dmap = deviceMap // else error: “Reference to captured var 'deviceMap' in concurrently-executing code”
            DispatchQueue.main.async {
                withAnimation {
                    self.deviceMap = dmap
                    // behaves really wierd
//                    DispatchQueue.main.async {
//                        self.ensureSelection() // select the first available device
//                    }
                }
            }
        } catch {
            dbg("error getting device list:", error)
            withAnimation {
                self.deviceMap = [:]
            }

        }
    }

    func reportError(_ error: Error) {
        dbg("error:", error)
        errors.append(error)
    }

    func importIPA(_ urls: [URL], upgrade: Bool = false) {
        dbg("importing:", urls, "into:", selection)
        guard let selection = selection,
              let client = deviceMap[selection]?.successValue else {
                  return dbg("no device selected")
              }

        dbg("importing into:", client)

        for url in urls {
            do {
                let iproxy = try client.createInstallationProxy(escrow: true)
                // "iTunesMetadata" -> PLIST_DATA
                // "ApplicationSINF" -> PLIST_DATA
                // "PackageType" -> "Developer"
                let opts = Plist(dictionary: [
                    // "CFBundleIdentifier": nil,
                    // "iTunesMetadata": nil,
                    // "ApplicationSINF": nil,
                    // "PackageType": Plist(string: "Developer"),
                    :])

                if upgrade {
                    let result = try iproxy.upgrade(pkgPath: url.path, options: opts, callback: nil)
                    result.dispose()
                } else {
                    let result = try iproxy.install(pkgPath: url.path, options: opts, callback: nil)
                    result.dispose()
                }
            } catch {
                dbg("error installing IPA:", error)
                self.reportError(error)
            }
        }
    }

    /// Ensure that at least one item is selected
    @discardableResult func ensureSelection() -> Bool {
        if self.deviceMap.isEmpty {
            return false
        }

        if let selection = self.selection, self.deviceMap.keys.contains(selection) {
            return true
        }

        self.selection = self.connectionInfos.first
        return self.selection != nil
    }
}

let ipaType = UTType("com.apple.itunes.ipa")!

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store
    @State var showFileImporter = false

    public var body: some View {
        navigationView
        // FIXME: not working
            .alert(isPresented: store.presentedErrorExists, error: store.presentedError) {
                Button("OK") {
                }
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [ipaType], allowsMultipleSelection: false) { result in
                switch result {
                case .failure(let error):
                    dbg("error importing file:", error)
                case .success(let urls):
                    store.importIPA(urls)
                }
            }
            .handlesExternalEvents(preferring: [], allowing: ["*"]) // re-use this window to open IPA files
            .onOpenURL { url in
                if store.ensureSelection() {
                    store.importIPA([url])
                }
            }
            .toolbar(id: "ImportToolbar") {
                ToolbarItem(id: "ImportIPA", placement: .navigation, showsByDefault: true) {
                    Text("Import")
                        .label(image: FairSymbol.arrow_down_app_fill)
                        .button {
                            if store.ensureSelection() {
                                showFileImporter = true
                            }
                        }
                        .hoverSymbol(activeVariant: .none)
                        .help(Text("Import an IPA file"))
                        .keyboardShortcut("O")
                        //.disabled(selection == nil) // instead we select the first available device if none is already selected
                }
            }
    }

    var navigationView: some View {
        NavigationView {
            List(selection: $store.selection) {
                Section {
                    ForEach(store.connectionInfos.enumerated().array(), id: \.element) { (index, info) in
                        if let client = store.deviceMap[info]?.successValue {
                            NavigationLink {
                                DeviceAppListSplitView()
                                    .environmentObject(client)
                            } label: {
                                clientLabel(client, info: info)
                            }
                            .keyboardShortcut(KeyEquivalent((index + 1).description.first ?? "?"))
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

            DeviceInfoView(selection: store.selection)
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
                        //.help("Battery level: \(batteryLevel)%")
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
                    keyRow("DevicePublicKey")
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

#if os(iOS)
typealias VSplit = VStack // VSplitView unavailable on iOS
#else
typealias VSplit = VSplitView
#endif

/// A vertical split view containing a list of apps for the device, below which is the information about the selected app
/// This uses the undocumented behavior of a NavigationLink such that it will use the next available split for displaying the destination of the link.
struct DeviceAppListSplitView : View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var client: LockdownClient
    @State var apps: [InstalledAppInfo] = []
    @State var iproxy: InstallationProxy?
    @State var sbclient: SpringboardServiceClient?
    @State var dropZoneTargeted = false

    var body: some View {
        // this split view allows us to override the 3-panel navigation behavior such that selecting an item from the list will make its navigation destination appear here (below the list) rather than in the panel on the right
        VSplit {
            appListView
                .frame(idealHeight: 100)

            selectAppView()
        }
        .task {
            do {
                self.iproxy = try client.createInstallationProxy(escrow: true)
                self.sbclient = try client.createSpringboardServiceClient(escrow: true)
            } catch {
                store.reportError(error)
            }
        }
    }

    func selectAppView() -> some View {
        Group {
            if store.teamID.isEmpty {
                Text("No App Selected")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                appDropView()
            }
        }
    }

    func appDropView() -> some View {
        VStack {
            // square.and.arrow.down.on.square.fill
            Image(FairSymbol.square_and_arrow_down_on_square)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .font(.largeTitle)
                .symbolVariant(dropZoneTargeted ? .fill : .none)
                .frame(maxHeight: 150)

            Text("Install app .ipa")
                .font(.title)
        }
        .help(Text("This will sign the dropped IPA with your Signing Identity and Team ID and transfer and install the app on your device."))
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [UTType.url, UTType.fileURL], isTargeted: $dropZoneTargeted) { (items) -> Bool in
            guard let item = items.first else {
                return false
            }
            guard let identifier = item.registeredTypeIdentifiers.first else {
                return false
            }
            item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                DispatchQueue.main.async {
                    if let urlData = urlData as? Data {
                        let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                        if urll.pathExtension == "ipa"{
                            store.importIPA([urll])
                        }
                    }
                }
            }
            return true
        }
    }

    @ViewBuilder var appListView: some View {
        ZStack {
            if let iproxy = self.iproxy, let sbclient = self.sbclient {
                AppsListView(apps: $apps)
                    .environmentObject(sbclient)
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

            HStack(spacing: 10) {
                #if os(macOS)
                ProgressView().controlSize(.small)
                #else
                ProgressView()
                #endif
                Text("Loading App Inventory…")
                    .font(.title)
            }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(apps.isEmpty ? 1.0 : 0.0)
        }
    }
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
    @EnvironmentObject var store: Store
    @EnvironmentObject var springboard: SpringboardServiceClient

    var body: some View {
        NavigationLink {
            AppInfoView(appInfo: appInfo, icon: $icon)
        } label: {
            AppItemLabel(appInfo: appInfo, icon: $icon)
        }
        .task {
            if let bundleID = appInfo.CFBundleIdentifier {
                do {
                    let pngData = try springboard.getIconPNGData(bundleIdentifier: bundleID)
                    if let img = UXImage(data: pngData) {
                        self.icon = Image(uxImage: img)
                            .resizable()
                    }
                } catch {
                    store.reportError(error)
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
                        .fill(Color.accentColor.opacity(0.2))
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
                icon(.NSSiriUsageDescription)
                icon(.NSSpeechRecognitionUsageDescription)
            }
            .foregroundStyle(Color.cyan)

            Group { // hardware
                icon(.NSMicrophoneUsageDescription)
                icon(.NSCameraUsageDescription)
                icon(.NSMotionUsageDescription)
                icon(.NFCReaderUsageDescription)
                icon(.NSBluetoothUsageDescription)
                icon(.NSBluetoothAlwaysUsageDescription)
                icon(.NSBluetoothPeripheralUsageDescription)
            }
            .foregroundStyle(Color.mint)

            Group { // databases
                icon(.NSRemindersUsageDescription)
                icon(.NSContactsUsageDescription)
                icon(.NSCalendarsUsageDescription)
                icon(.NSPhotoLibraryAddUsageDescription)
                icon(.NSPhotoLibraryUsageDescription)
            }
            .foregroundStyle(Color.green)

            Group { // services
                icon(.NSAppleMusicUsageDescription)
                icon(.NSHomeKitUsageDescription)
                //icon(.NSVideoSubscriberAccountUsageDescription)
                icon(.NSHealthShareUsageDescription)
                icon(.NSHealthUpdateUsageDescription)
            }
            .foregroundStyle(Color.mint)

            Group { // misc
                icon(.NSAppleEventsUsageDescription)
                icon(.NSFocusStatusUsageDescription)
                icon(.NSLocalNetworkUsageDescription)
                icon(.NSFaceIDUsageDescription)
            }
            .foregroundStyle(Color.gray)

            Group { // location
                icon(.NSLocationUsageDescription)
                icon(.NSLocationAlwaysUsageDescription)
                icon(.NSLocationTemporaryUsageDescriptionDictionary)
                icon(.NSLocationWhenInUseUsageDescription)
                icon(.NSLocationAlwaysAndWhenInUseUsageDescription)
            }
            .foregroundStyle(Color.blue)

            Group { // tracking
                icon(.NSUserTrackingUsageDescription)
            }
            .foregroundStyle(Color.pink)
        }
        .symbolRenderingMode(SwiftUI.SymbolRenderingMode.palette)
    }


    @ViewBuilder func icon(_ key: UsageDescriptionKeys) -> some View {
        if let value = appInfo[usage: key] {
            key.icon
                .help(Text(key.description) + Text(": ") + Text(value))
        }
    }
}

extension InstalledAppInfo {
    /// Returns the value of the given `UsageDescriptionKeys` is it exists
    subscript(usage key: UsageDescriptionKeys) -> String? {
        dict[key.rawValue]?.string
    }
}

enum UsageDescriptionKeys : String, CaseIterable {

    // MARK: tracking
    case NSUserTrackingUsageDescription

    // MARK: location

    case NSLocationUsageDescription
    case NSLocationAlwaysUsageDescription
    case NSLocationTemporaryUsageDescriptionDictionary
    case NSLocationWhenInUseUsageDescription
    case NSLocationAlwaysAndWhenInUseUsageDescription

    // MARK: voice

    case NSSiriUsageDescription
    case NSSpeechRecognitionUsageDescription

    // MARK: hardware

    case NSMicrophoneUsageDescription
    case NSCameraUsageDescription
    case NSMotionUsageDescription
    case NFCReaderUsageDescription
    case NSBluetoothUsageDescription
    case NSBluetoothAlwaysUsageDescription
    case NSBluetoothPeripheralUsageDescription

    // MARK: databases

    case NSRemindersUsageDescription
    case NSContactsUsageDescription
    case NSCalendarsUsageDescription
    case NSPhotoLibraryAddUsageDescription
    case NSPhotoLibraryUsageDescription

    // MARK: services

    case NSAppleMusicUsageDescription
    case NSHomeKitUsageDescription
    //case NSVideoSubscriberAccountUsageDescription
    case NSHealthShareUsageDescription
    case NSHealthUpdateUsageDescription

    // MARK: misc

    case NSAppleEventsUsageDescription
    case NSFocusStatusUsageDescription
    case NSLocalNetworkUsageDescription
    case NSFaceIDUsageDescription

}

extension UsageDescriptionKeys {
    var description: LocalizedStringKey {
        switch self {
        case .NSSiriUsageDescription: return "Siri"
        case .NSSpeechRecognitionUsageDescription: return "Speech Recognition"
        case .NSMicrophoneUsageDescription: return "Microphone"
        case .NSCameraUsageDescription: return "Camera"
        case .NSMotionUsageDescription: return "Motion"
        case .NFCReaderUsageDescription: return "NFC Reader"
        case .NSBluetoothUsageDescription: return "Bluetooth"
        case .NSBluetoothAlwaysUsageDescription: return "Bluetooth (Always)"
        case .NSBluetoothPeripheralUsageDescription: return "Bluetooth (peripheral)"
        case .NSRemindersUsageDescription: return "Reminders"
        case .NSContactsUsageDescription: return "Contacts"
        case .NSCalendarsUsageDescription: return "Calendars"
        case .NSPhotoLibraryAddUsageDescription: return "Photo Library Add"
        case .NSPhotoLibraryUsageDescription: return "Photo Library"
        case .NSAppleMusicUsageDescription: return "Apple Music"
        case .NSHomeKitUsageDescription: return "HomeKit"
        //case .NSVideoSubscriberAccountUsageDescription: return "Video Subscriber Account Usage"
        case .NSHealthShareUsageDescription: return "Health Sharing"
        case .NSHealthUpdateUsageDescription: return "Health Update"
        case .NSAppleEventsUsageDescription: return "Apple Events"
        case .NSFocusStatusUsageDescription: return "Focus Status"
        case .NSLocalNetworkUsageDescription: return "Local Network"
        case .NSFaceIDUsageDescription: return "Face ID"
        case .NSLocationUsageDescription: return "Location"
        case .NSLocationAlwaysUsageDescription: return "Location (Always)"
        case .NSLocationTemporaryUsageDescriptionDictionary: return "Location (Temporary)"
        case .NSLocationWhenInUseUsageDescription: return "Location (When in use)"
        case .NSLocationAlwaysAndWhenInUseUsageDescription: return "Location (Always)"
        case .NSUserTrackingUsageDescription: return "User Tracking"
        }
    }

    var icon: FairSymbol {
        switch self {
        case .NSSiriUsageDescription: return .ear
        case .NSSpeechRecognitionUsageDescription: return .waveform
        case .NSMicrophoneUsageDescription: return .mic_circle
        case .NSCameraUsageDescription: return .camera
        case .NSMotionUsageDescription: return .gyroscope
        case .NFCReaderUsageDescription: return .barcode_viewfinder
        case .NSBluetoothUsageDescription: return .cable_connector
        case .NSBluetoothAlwaysUsageDescription: return .cable_connector_horizontal
        case .NSBluetoothPeripheralUsageDescription: return .printer
        case .NSRemindersUsageDescription: return .text_badge_checkmark
        case .NSContactsUsageDescription: return .person_text_rectangle
        case .NSCalendarsUsageDescription: return .calendar
        case .NSPhotoLibraryAddUsageDescription: return .text_below_photo_fill
        case .NSPhotoLibraryUsageDescription: return .photo
        case .NSAppleMusicUsageDescription: return .music_note
        case .NSHomeKitUsageDescription: return .house
        //case .NSVideoSubscriberAccountUsageDescription: return .sparkles_tv
        case .NSHealthShareUsageDescription: return .stethoscope
        case .NSHealthUpdateUsageDescription: return .stethoscope_circle
        case .NSAppleEventsUsageDescription: return .scroll
        case .NSFocusStatusUsageDescription: return .eyeglasses
        case .NSLocalNetworkUsageDescription: return .network
        case .NSFaceIDUsageDescription: return .viewfinder
        case .NSLocationUsageDescription: return .location_magnifyingglass
        case .NSLocationAlwaysUsageDescription: return .location_fill
        case .NSLocationTemporaryUsageDescriptionDictionary: return .location
        case .NSLocationWhenInUseUsageDescription: return .location_north
        case .NSLocationAlwaysAndWhenInUseUsageDescription: return .location_fill_viewfinder
        case .NSUserTrackingUsageDescription: return .eyes

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
                            .frame(width: 60, height: 60)
                    }
                    .font(Font.largeTitle)
                    .textFieldStyle(.plain)
                    .textSelection(.enabled)
                    //.disabled(true)
                    //.frame(alignment: .center)
                }

                Divider()

                Section {
                    ForEach(UsageDescriptionKeys.allCases, id: \.self) { key in
                        usageRow(key: key)
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
        // .textFieldStyle(.squareBorder) // not on iOS
        .textSelection(.enabled)
    }

    func usageRow(key: UsageDescriptionKeys) -> some View {
        TextField(text: .constant(appInfo[usage: key] ?? ""), prompt: Text("Not used")) {
            (Text(key.description) + Text(":"))
                //.label(image: key.icon)
        }
        // .textFieldStyle(.squareBorder) // not on iOS
        .textSelection(.enabled)
    }

}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView().environmentObject(store)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window
            }
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public enum Tabs: Hashable {
        case general
    }

    public var body: some View {
        TabView {
            Group {
                Form {
                    HStack {
                        TextField(text: $store.teamID, prompt: Text("1A2B3C4D5F")) {
                            Text("Team ID:")
                        }

                        Group {
                            if store.teamID.isEmpty {
                                FairSymbol.questionmark_circle_fill
                            } else if store.teamID.count != 10 {
                                FairSymbol.exclamationmark_triangle_fill
                            } else {
                                FairSymbol.checkmark_square_fill.foregroundStyle(Color.green)
                            }
                        }
                            .symbolRenderingMode(.multicolor)
                            .help(Text("Team ID must be 10 characters long"))
                    }
                    HStack {
                        TextField(text: $store.signingIdentity, prompt: Text("iPhone Distribution: <Developer> (<Team ID>)")) {
                            Text("Signing Identity:")
                        }
                        FairSymbol.exclamationmark_triangle_fill
                            .opacity(0.0) // TODO
                    }
                    HStack {
                        TextField(text: $store.keychainName, prompt: Text("Optional")) {
                            Text("Keychain Name:")
                        }
                        FairSymbol.exclamationmark_triangle_fill
                            .opacity(0.0) // TODO
                    }
                }
            }
            .padding(20)
            .tabItem {
                Text("General")
                    .label(image: FairSymbol.platter_filled_top_and_arrow_up_iphone)
                    .symbolVariant(.fill)
            }
            .tag(Tabs.general)
        }
        .padding(20)
        .frame(width: 600)
    }
}


/// Extension to permit passing as an `@EnvironmentObject`
extension SpringboardServiceClient : ObservableObject {
}

/// Extension to permit passing as an `@EnvironmentObject`
extension InstallationProxy : ObservableObject {
}

/// Extension to permit passing as an `@EnvironmentObject`
extension LockdownClient : ObservableObject {
}
