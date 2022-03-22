/**
 Copyright The Blunder Busq Contributors
 SPDX-License-Identifier: AGPL-3.0

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import FairApp
import Busq
import SwiftUI
import UniformTypeIdentifiers

/// The shared app environment
@MainActor public final class Store: SceneManager {
    /// The signing identity for signing .ipa files
    @AppStorage("signingIdentity") public var signingIdentity = ""
    /// The signing name for signing .ipa files
    @AppStorage("signingName") public var signingName = ""
    /// The developer's ID
    @AppStorage("signingNameID") public var signingNameID = ""
    /// The developer team ID for signing .ipa files
    @AppStorage("teamID") public var teamID = ""

    /// The keychain that holds the signing certificate
    @AppStorage("keychainName") public var keychainName = ""
    /// The preferred theme style for the app
    @AppStorage("themeStyle") public var themeStyle = ThemeStyle.system

    @Published var selection: DeviceConnectionInfo?
    @Published var deviceMap: [DeviceConnectionInfo: Result<LockdownClient, Error>] = [:]
    /// Errors to be shown at the top level
    @Published var errors: [Error] = []
    var deviceEventSubscription: Disposable?

    /// Returns the `LockdownClient` for the selected device
    var selectedLockdownClient: LockdownClient? {
        if let selection = self.selection {
            return deviceMap[selection]?.successValue
        } else {
            return nil
        }
    }

    var presentedError: AppError? {
        errors.first.flatMap(AppError.init)
    }

    /// Returns the connection infos as will be displayed by the UI
    var connectionInfos: [DeviceConnectionInfo] {
        deviceMap.keys
            .sorting(by: \.udid)
            .sorted(by: { i1, i2 in
                // always show connected devices first
                i1.connectionType.rawValue < i2.connectionType.rawValue
            })

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

    func installIPA(_ urls: [URL], escrow: Bool = false) {
        dbg("importing:", urls, "into:", selection)
        guard let client = selectedLockdownClient else {
            return dbg("no device selected")
        }

        dbg("importing:", urls.map(\.path), "into:", client)

        // TODO: cannot install using tasks because the tools are inaccessible from the sandboxed app
        for url in urls {
            do {
                // let signname = self.signingIdentity // TODO: need fingerprint
                let signname = self.signingName + " (" + self.signingNameID + ")"
                let signedIPA = try FileManager.default.prepareIPA(url, identity: signname, teamID: self.teamID, recompress: true)

                print("signedIPA:", signedIPA.path)
                let tmpFile = UUID().uuidString + ".ipa"

                let fileConduit = try client.createFileConduit(escrow: escrow)
                let handle = try fileConduit.fileOpen(filename: tmpFile, fileMode: .wrOnly)
                defer { try? fileConduit.fileClose(handle: handle) }
                try fileConduit.fileWrite(handle: handle, fileURL: signedIPA) { progress in
                    // TODO: progress handles
                }

                defer { try? fileConduit.removeFile(path: tmpFile) }

                let installProxy = try client.createInstallationProxy(escrow: escrow)

                var opts: [String : Busq.Plist] = [:]
                if true {
                    opts["PackageType"] = Plist(string: "Developer")
                }

                let optsDict = Plist(dictionary: opts)

                try installProxy.install(pkgPath: tmpFile, options: optsDict, callback: nil).dispose()

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
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [ipaType], allowsMultipleSelection: false) { result in
                switch result {
                case .failure(let error):
                    dbg("error importing file:", error)
                case .success(let urls):
                    store.installIPA(urls)
                }
            }
            .handlesExternalEvents(preferring: [], allowing: ["*"]) // re-use this window to open IPA files
            .onOpenURL { url in
                if store.ensureSelection() {
                    store.installIPA([url])
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
                                DeviceAppListSplitView(info: info)
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

    var body: some View {
        GeometryReader { proxy in
            List {
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
                        appDeviceInfoView(client, proxy)
                    }
                } else {
                    Spacer()
                }
            }
        }
    }

    /// A list of properties of a device
    private func appDeviceInfoView(_ client: LockdownClient, _ proxy: GeometryProxy) -> some View {
        func row(title: String, value: String?) -> some View {
            HStack {
                (Text(title) + Text(":"))
                    .truncationMode(.middle)
                    .frame(width: proxy.size.width / 2, alignment: .trailing)
                    .help(Text(title))

                Text(value ?? "")
                    .truncationMode(.tail)
                    .frame(maxWidth: proxy.size.width / 2, alignment: .leading)
                    .help(Text(value ?? ""))
            }
            .lineLimit(1)
            .allowsTightening(true)
            .textSelection(.enabled)
        }

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

        return Group {
            Section("Device Info") {
                Group {
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
            }

            Section("Extended Info") {
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
    }

}

#if os(iOS)
typealias VSplit = VStack // VSplitView unavailable on iOS
#else
typealias VSplit = VSplitView
#endif

/// Holder for various services
final class ServicesManager : ObservableObject {
    @Published var searchText = ""

    @Published var iproxy: InstallationProxy?
    @Published var sbclient: SpringboardServiceClient?

    /// The list of apps installed for a certain device
    @Published var apps: [InstalledAppInfo] = []

    /// Map of app bundle IDs to Icon images
    @Published var icons: [String: Image] = [:]

    var filteredApps: [InstalledAppInfo] {
        apps
            .filter({ info in
                searchText.isEmpty ||
                info.CFBundleName?.localizedCaseInsensitiveContains(searchText) == true
            })
    }
    /// Refresh the list of installed apps from the device
    func refreshAppList() throws {
        let appList = try iproxy?.getAppList(type: .any) ?? []
        //        DispatchQueue.main.async {
        withAnimation {
            self.apps = appList
        }
        //        }

    }
}

/// A vertical split view containing a list of apps for the device, below which is the information about the selected app
/// This uses the undocumented behavior of a NavigationLink such that it will use the next available split for displaying the destination of the link.
struct DeviceAppListSplitView : View {
    let info: DeviceConnectionInfo
    @EnvironmentObject var store: Store
    @StateObject var manager: ServicesManager = ServicesManager()
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
                let client = store.deviceMap[info]?.successValue
                let iproxy = try client?.createInstallationProxy(escrow: true)
                manager.iproxy = iproxy
                manager.sbclient = try client?.createSpringboardServiceClient(escrow: true)
                try manager.refreshAppList()
            } catch {
                store.reportError(error)
            }
        }
    }

    func selectAppView() -> some View {
        Group {
            // if the developer's teamid has not been selected, do not show the install screen
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
                        let dataURL = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                        if dataURL.pathExtension == "ipa"{
                            store.installIPA([dataURL])
                        }
                    }
                }
            }
            return true
        }
    }

    @ViewBuilder var appListView: some View {
        AppsListView()
            .environmentObject(manager)
        //            }
        //
        //            HStack(spacing: 10) {
        //                #if os(macOS)
        //                ProgressView().controlSize(.small)
        //                #else
        //                ProgressView()
        //                #endif
        //                Text("Loading App Inventory…")
        //                    .font(.title)
        //            }
        //                .foregroundColor(.secondary)
        //                .frame(maxWidth: .infinity, maxHeight: .infinity)
        //                .opacity(apps.isEmpty ? 1.0 : 0.0)
        //                .animation(.none)
        //        }
    }
}

struct AppsListView : View {
    @EnvironmentObject var manager: ServicesManager

    var body: some View {
        List {
            appsSection(type: .user) // always show this section because it contains the progress view
            if !manager.apps.isEmpty {
                appsSection(type: .system)
                appsSection(type: .internal)
            }
        }
        .searchable(text: $manager.searchText, placement: .automatic, prompt: Text("Search"))
    }

    @ViewBuilder func appsSection(type: ApplicationType) -> some View {
        let apps = manager.filteredApps.filter { app in
            app.ApplicationType == type.rawValue
        }

        Section {
            ForEach(apps.sorting(by: \.CFBundleDisplayName), id: \.CFBundleIdentifier) { appInfo in
                AppInfoLink(appInfo: appInfo)
            }
        } header: {
            HStack(spacing: 10) {
                if manager.apps.isEmpty {
#if os(macOS)
                    ProgressView().controlSize(.mini)
#endif
                }
                Text(type.rawValue) + Text(" ") + Text("Apps") + Text(" (") + Text(apps.count, format: .number) + Text(")")
            }
        }
    }
}

struct AppInfoLink : View {
    let appInfo: InstalledAppInfo
    @EnvironmentObject var store: Store
    @EnvironmentObject var manager: ServicesManager

    var body: some View {
        NavigationLink {
            AppInfoView(appInfo: appInfo)
        } label: {
            AppItemLabel(appInfo: appInfo)
        }
        .task {
            if let bundleID = appInfo.CFBundleIdentifier {
                do {
                    if let pngData = try manager.sbclient?.getIconPNGData(bundleIdentifier: bundleID) {
                        if let img = UXImage(data: pngData) {
                            withAnimation {
                                manager.icons[bundleID] = Image(uxImage: img)
                                    .resizable()
                            }
                        }
                    }
                } catch {
                    store.reportError(error)
                }
            }
        }

    }
}

struct AppItemLabel : View {
    @EnvironmentObject var manager: ServicesManager
    let appInfo: InstalledAppInfo

    var body: some View {
        HStack {
            Group {
                if let bundleID = appInfo.CFBundleIdentifier,
                   let icon = manager.icons[bundleID] {
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
    @EnvironmentObject var store: Store
    @EnvironmentObject var manager: ServicesManager
    @State var deleteAppConfirm = false

    var body: some View {
        ScrollView {
            appInfoForm
                .padding()
        }
        .toolbar(id: "AppInfoToolbar") {
            ToolbarItem(id: "DeleteApp", placement: .automatic, showsByDefault: true) {
                Text("Delete")
                    .label(image: FairSymbol.trash)
                    .button {
                        deleteAppConfirm = true // show the delete confirmation
                    }
                    .confirmationDialog(Text("Delete App?"), isPresented: $deleteAppConfirm, titleVisibility: .visible, actions: {
                        Text("Delete").button {
                            if let iproxy = manager.iproxy {
                                do {
                                    if let appID = appInfo.CFBundleIdentifier {
                                        try iproxy.uninstall(appID: appID, options: Plist(dictionary: [:]), callback: nil).dispose()
                                        try manager.refreshAppList()
                                    }
                                } catch {
                                    store.reportError(error)
                                }
                            }
                        }
                    }, message: {
                        Text("Really delete the app “\(appInfo.CFBundleName ?? "")”? This operation cannot be undone.")
                    })
                    .hoverSymbol(activeVariant: .fill)
                    .help(Text("Delete the app from your device"))
                    .disabled(manager.iproxy == nil || appInfo.CFBundleIdentifier == nil)
            }
        }
    }

    var appInfoForm: some View {
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
                    manager.icons[appInfo.CFBundleIdentifier ?? ""]?
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 55, height: 55)
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
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(store.themeStyle.colorScheme)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
            //            SearchBarCommands()
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window
            }
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView()
            .environmentObject(store)
            .preferredColorScheme(store.themeStyle.colorScheme)
    }
}

public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public enum Tabs: Hashable {
        case general
        case developer
    }

    public var body: some View {
        TabView {
            GeneralSettingsView()
                .padding(20)
                .tabItem {
                    Text("General")
                        .label(image: FairSymbol.switch_2)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)

            DeveloperSettingsView()
                .padding(20)
                .tabItem {
                    Text("Developer")
                        .label(image: FairSymbol.platter_filled_top_and_arrow_up_iphone)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.developer)
        }
        .padding(20)
        .frame(width: 600)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct DeveloperSettingsView: View {
    @EnvironmentObject var store: Store
    @State var identities: [SigningIdentity] = []

    var selectedSigningIdentity: Binding<SigningIdentity?> {
        Binding {
            SigningIdentity(certid: store.signingIdentity, certname: store.signingName, teamid: store.signingNameID)
        } set: { newValue in
            if let newValue = newValue {
                store.signingIdentity = newValue.certid
                store.signingName = newValue.certname
                store.signingNameID = newValue.teamid
            }
        }
    }

    var body: some View {
        return Group {
            Form {
                Picker(selection: selectedSigningIdentity) {
                    if identities.isEmpty {
                        Text("No signing identities found")
                            .foregroundColor(.secondary)
                            .disabled(true)
                    } else {
                        ForEach(identities, id: \.certid) { identity in
                            Text(identity.menuString)
                                .tag(Optional.some(identity))
                        }
                    }
                } label: {
                    Text("Signing Identity:")
                }
                .pickerStyle(.menu)
                .task {
                    dbg("showing identities")
                    refreshSigningIdentities()
                }

                Picker(selection: $store.teamID) {
                    if identities.isEmpty {
                        Text("No team identifiers found")
                            .foregroundColor(.secondary)
                            .disabled(true)
                    } else {
                        ForEach(identities.map(\.teamid), id: \.self) { teamid in
                            Text(teamid)
                                .tag(Optional.some(teamid))
                        }
                    }
                } label: {
                    Text("Team ID:")
                }
                .pickerStyle(.menu)

                Text("Refresh")
                    .label(image: FairSymbol.arrow_triangle_2_circlepath_circle)
                //.labelStyle(.iconOnly)
                    .button {
                        refreshSigningIdentities()
                    }
                //.buttonStyle(.plain)
                    .hoverSymbol(activeVariant: .fill)
                    .help(Text("Refresh signing identities"))
            }

        }
    }

    func refreshSigningIdentities() {
        dbg("refreshing signing identities")
        do {
            let output = try shell("/usr/bin/security", args: ["find-identity", "-v", "-p", "codesigning"])
            let ids = output.split(separator: "\r").compactMap(SigningIdentity.init(string:))
            dbg("parsed ids:", ids)
            self.identities = ids
        } catch {
            store.reportError(error)
        }
    }
}

/// The parsed output from `/usr/bin/security find-identity -v -p codesigning`
struct SigningIdentity : Hashable {
    let certid: String
    let certname: String
    let teamid: String
}

extension SigningIdentity {
    private static let idregex = Result {
        // `1) CERTID "Some Development: Person Name (TEAMID)"`
        try NSRegularExpression(pattern: #" *[0-9]*\) *(?<certid>[A-Z0-9]*) "(?<certname>.*) \((?<teamid>[A-Z0-9]*)\)""#, options: [])
    }

    /// Attempt the parse the signing identify in the form of: “1) CERTSIG "Some Development: Person Name (TEAMID)"”
    init?<S: StringProtocol>(string: S) {
        guard let idregex = Self.idregex.successValue else {
            dbg("bad regular expression:", Self.idregex.failureValue)
            return nil
        }

        let str = string.description
        dbg("parsing:", str)
        guard let certid = idregex.firstMatch(in: str, options: [], range: string.span)?.range(withName: "certid"), certid.location != NSNotFound else {
            dbg("no certid")
            return nil
        }
        guard let certname = idregex.firstMatch(in: str, options: [], range: string.span)?.range(withName: "certname"), certname.location != NSNotFound else {
            dbg("no certname")
            return nil
        }
        guard let teamid = idregex.firstMatch(in: str, options: [], range: string.span)?.range(withName: "teamid"), teamid.location != NSNotFound else {
            dbg("no teamid")
            return nil
        }

        self.certid = (str as NSString).substring(with: certid)
        self.certname = (str as NSString).substring(with: certname)
        self.teamid = (str as NSString).substring(with: teamid)
    }

    /// The string that will be displayed in a menu (the certificate name and team ID, but not the cert ID)
    var menuString: String {
        certname + " (" + teamid + ")"
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct GeneralSettingsView: View {
    @AppStorage("themeStyle") private var themeStyle = ThemeStyle.system
    @AppStorage("iconBadge") private var iconBadge = true

    var body: some View {
        Form {
            ThemeStylePicker(style: $themeStyle)

            Divider()

            Toggle(isOn: $iconBadge) {
                Text("Badge App Icon")
            }
            .help(Text("Show the number of apps pending install."))
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
            Text("Theme:")
        }
        .pickerStyle(.radioGroup)
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
        case .system: return Text("System")
        case .light: return Text("Light")
        case .dark: return Text("Dark")
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
