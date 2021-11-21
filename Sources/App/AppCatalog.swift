/**
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
import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
extension AppCatalogItem {

    /// All the entitlements, ordered by their index in the `AppEntitlement` cases.
    public func orderedPermissions(filterCategories: Set<AppEntitlement.Category> = []) -> Array<AppPermission> {
        (self.permissions ?? [])
            .filter {
                $0.type.categories.intersection(filterCategories).isEmpty
            }
    }

    /// A relative score summarizing how risky the app appears to be from a scale of 0–5
    var riskLevel: AppRisk {
        // let groups = Set(item.appCategories.flatMap(\.groupings))
        let categories = Set((self.permissions ?? []).flatMap(\.type.categories)).subtracting([.prerequisite, .harmless])
        // the risk level is simply the number of categories the permissions fall into. E.g.:
        // nothing -> harmless
        // network -> mostly harmless
        // read files -> mostly harmless
        // read & write files -> risky
        // network + read & write files -> hazardous
        let value = max(0, min(5, categories.count))
        return AppRisk(rawValue: value) ?? .allCases.last!
    }

    /// The topic identfier for the initial category
    var primaryCategoryIdentifier: AppCategory? {
        categories?.compactMap(AppCategory.init(metadataID:)).first
    }
}

enum AppRisk : Int, CaseIterable, Hashable, Identifiable, Comparable {
    case harmless
    case mostlyHarmless
    case risky
    case hazardous
    case dangerous
    case perilous

    var id: Self { self }

    static func < (lhs: AppRisk, rhs: AppRisk) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    func textLabel() -> Text {
        switch self {
        case .harmless:
            return Text("Harmless")
        case .mostlyHarmless:
            return Text("Mostly Harmless")
        case .risky:
            return Text("Risky")
        case .hazardous:
            return Text("Hazardous")
        case .dangerous:
            return Text("Dangerous")
        case .perilous:
            return Text("Perilous")
        }
    }

    /// The label summarizing how risky the app appears to be
    func riskLabel(help: Bool = true) -> some View {
        Group {
            textLabel()
                .label(image: Image(systemName: "\(self.rawValue)"))
                .foregroundColor(self.riskColor())
        }
        .symbolVariant(.square)
        .symbolVariant(.fill)
        .symbolRenderingMode(SymbolRenderingMode.hierarchical)
        //.help(Text("Based on the number of permission categories this app requests this app can be considered: ") + riskLevel.textLabel())
    }


    func riskColor() -> Color {
        switch self {
        case .harmless:
            return Color.green
        case .mostlyHarmless:
            return Color.mint
        case .risky:
            return Color.yellow
        case .hazardous:
            return Color.orange
        case .dangerous:
            return Color.red
        case .perilous:
            return Color.pink
        }
    }

    /// The summary text.
    /// - Parameter bold: whether to bold the risk name
    /// - Returns: the text to use to describe the risk level
    func riskSummaryText(bold: Bool = false) -> Text {
        var prefix = textLabel()
        if bold {
            // set bold=false for .help() text, or else the following will be logged: “[SwiftUI] Only unstyled text can be used with help(_:)”
            prefix = prefix.bold()
        }

        switch self {
        case .harmless:
            return prefix + Text(" apps are sandboxed and have no ability to connect to the internet, read or write files outside of the sandbox, or connect to a camera, microphone, or other device. They can be considered harmless in terms of the potential risks to your system and personal information.")
        case .mostlyHarmless:
            return prefix + Text(" apps are granted a single category of permission, which means they can either connect to the internet, connect to a device (such as the camera or microphone) or read files outside of their sandbox, but they cannot perform more than one of these categories of operations. These apps are not entirely without risk, but they can be generally considered safe.")
        case .risky:
            return prefix + Text(" apps are sandboxed and have a variety of permissions which, in combination, can put your system at risk. For example, they may be able to both read & write user-selected files, as well as connect to the internet, which makes them potential sources of data exfiltration or corruption. You should only install these apps from a reputable source.")
        case .hazardous:
            return prefix + Text(" apps are sandboxed and have a variety of permissions enabled. As such, they can perform many system operations that are unavailable to apps with reduced permission sets. You should only install these apps from a reputable source.")
        case .dangerous:
            return prefix + Text(" apps are still sandboxed, but they are granted a wide array of entitlements that makes them capable of damaging or hijacking your system. You should only install these apps from a trusted source.")
        case .perilous:
            return prefix + Text(" apps are granted all the categories of permission entitlement, and so can modify your system or damage your system in many ways. Despite being sandboxed, they should be considered to have the maximum possible permissions. You should only install these apps from a very trusted source.")
        }
    }
}

extension AppEntitlement : Identifiable {
    public var id: Self { self }

    /// Returns a text view with a description and summary of the given entitlement
    var localizedInfo: (title: Text, info: Text, symbol: String) {
        switch self {
        case .app_sandbox:
            return (
                Text("Sandbox"),
                Text("The Sandbox entitlement entitlement ensures that the app will run in a secure container."),
                "shield.fill")
        case .network_client:
            return (
                Text("Network Client"),
                Text("Communicate over the internet and any local networks."),
                "globe")
        case .network_server:
            return (
                Text("Network Server"),
                Text("Handle network requests from the local network or the internet."),
                "globe.badge.chevron.backward")
        case .device_camera:
            return (
                Text("Camera"),
                Text("Use the device camera."),
                "camera")
        case .device_microphone:
            return (
                Text("Microphone"),
                Text("Use the device microphone."),
                "mic")
        case .device_usb:
            return (
                Text("USB"),
                Text("Access USB devices."),
                "cable.connector.horizontal")
        case .print:
            return (
                Text("Printing"),
                Text("Access printers."),
                "printer")
        case .device_bluetooth:
            return (
                Text("Bluetooth"),
                Text("Access bluetooth."),
                "b.circle.fill")
        case .device_audio_video_bridging:
            return (
                Text("Audio/Video Bridging"),
                Text("Permit Audio/Bridging."),
                "point.3.connected.trianglepath.dotted")
        case .device_firewire:
            return (
                Text("Firewire"),
                Text("Access Firewire devices."),
                "bolt.horizontal")
        case .device_serial:
            return (
                Text("Serial"),
                Text("Access Serial devices."),
                "arrow.triangle.branch")
        case .device_audio_input:
            return (
                Text("Audio Input"),
                Text("Access Audio Input devices."),
                "lines.measurement.horizontal")
        case .personal_information_addressbook:
            return (
                Text("Address Book"),
                Text("Access the user's personal address book."),
                "text.book.closed")
        case .personal_information_location:
            return (
                Text("Location"),
                Text("Access the user's personal location information."),
                "location")
        case .personal_information_calendars:
            return (
                Text("Calendars"),
                Text("Access the user's personal calendar."),
                "calendar")
        case .files_user_selected_read_only:
            return (
                Text("Read User-Selected Files"),
                Text("Read access to files explicitly selected by the user."),
                "doc")
        case .files_user_selected_read_write:
            return (
                Text("Read & Write User-Selected Files"),
                Text("Read and write access to files explicitly selected by the user."),
                "doc.fill")
        case .files_user_selected_executable:
            return (
                Text("Executables (User-Selected)"),
                Text("Read access to executables explicitly selected by the user."),
                "doc.text.below.ecg")
        case .files_downloads_read_only:
            return (
                Text("Read Download Folder"),
                Text("Read access to the user's Downloads folder"),
                "arrow.up.and.down.square")
        case .files_downloads_read_write:
            return (
                Text("Read & Write Downloads Folder"),
                Text("Read and write access to the user's Downloads folder"),
                "arrow.up.and.down.square.fill")
        case .assets_pictures_read_only:
            return (
                Text("Read Pictures"),
                Text("Read access to the user's Pictures folder"),
                "photo")
        case .assets_pictures_read_write:
            return (
                Text("Read & Write Pictures"),
                Text("Read and write access to the user's Pictures folder"),
                "photo.fill")
        case .assets_music_read_only:
            return (
                Text("Read Music"),
                Text("Read access to the user's Music folder"),
                "radio")
        case .assets_music_read_write:
            return (
                Text("Read & Write Music"),
                Text("Read and write access to the user's Music folder"),
                "radio.fill")
        case .assets_movies_read_only:
            return (
                Text("Read Movies"),
                Text("Read access to the user's Movies folder"),
                "film")
        case .assets_movies_read_write:
            return (
                Text("Read & Write Movies"),
                Text("Read and write access to the user's Movies folder"),
                "film.fill")
        case .files_all:
            return (
                Text("Read & Write All Files"),
                Text("Read and write all files on the system."),
                "doc.on.doc.fill")
        case .cs_allow_jit:
            return (
                Text("Just-In-Time Compiler"),
                Text("Enable performace booting."),
                "hare")
        case .cs_debugger:
            return (
                Text("Debugging"),
                Text("Allows the app to act as a debugger and inspect the internal information of other apps in the system."),
                "stethoscope")
        case .cs_allow_unsigned_executable_memory:
            return (
                Text("Unsigned Executable Memory"),
                Text("Permit and app to create writable and executable memory without the restrictions imposed by using the MAP_JIT flag."),
                "hammer")
        case .cs_allow_dyld_environment_variables:
            return (
                Text("Dynamic Linker Variables"),
                Text("Permit the app to be affected by dynamic linker environment variables, which can be used to inject code into the app's process."),
                "screwdriver")
        case .cs_disable_library_validation:
            return (
                Text("Disable Library Validation"),
                Text("Permit the app to load arbitrary plug-ins or frameworks without requiring code signing."),
                "wrench")
        case .cs_disable_executable_page_protection:
            return (
                Text("Disable Executable Page Protection"),
                Text("Permits the app the disable all code signing protections while launching an app and during its execution."),
                "bandage")
        case .scripting_targets:
            return (
                Text("Scripting Target"),
                Text("Ability to use specific scripting access groups within a specific scriptable app."),
                "scroll")
        case .application_groups:
            return (
                Text("Application Groups"),
                Text("Share files and preferences between applications."),
                "square.grid.3x3.square")
        case .files_bookmarks_app_scope:
            return (
                Text("File Bookmarks App-Scope"),
                Text("Enables use of app-scoped bookmarks and URLs."),
                "bookmark.fill")
        case .files_bookmarks_document_scope:
            return (
                Text("File Bookmarks Document-Scope"),
                Text("Enables use of document-scoped bookmarks and URLs."),
                "bookmark")
        case .files_home_relative_path_read_only:
            return (
                Text("User Home Files Read-Only"),
                Text("Enables read-only access to the specified files or subdirectories in the user's home directory."),
                "doc.badge.ellipsis")
        case .files_home_relative_path_read_write:
            return (
                Text("User Home Files Read-Write"),
                Text("Enables read/write access to the specified files or subdirectories in the user's home directory."),
                "doc.fill.badge.ellipsis")
        case .files_absolute_path_read_only:
            return (
                Text("Global Files Read-Only"),
                Text("Enables read-only access to the specified files or directories at specified absolute paths."),
                "doc.badge.gearshape")
        case .files_absolute_path_read_write:
            return (
                Text("Global Files Read-Write"),
                Text("Enables read/write access to the specified files or directories at specified absolute paths."),
                "doc.badge.gearshape.fill")
        case .apple_events:
            return (
                Text("Apple Events"),
                Text("Enables sending of Apple events to one or more destination apps."),
                "scroll.fill")
        case .audio_unit_host:
            return (
                Text("Audio Unit Host"),
                Text("Enables hosting of audio components that are not designated as sandbox-safe."),
                "waveform")
        case .iokit_user_client_class:
            return (
                Text("IOKit User Client"),
                Text("Ability to specify additional IOUserClient subclasses."),
                "waveform.badge.exclamationmark")
        case .mach_lookup_global_name:
            return (
                Text("Mach Global Name Lookup"),
                Text("Lookup global Mach services."),
                "list.bullet.rectangle")
        case .mach_register_global_name:
            return (
                Text("Mach Global Name Register"),
                Text("Register global Mach services."),
                "list.bullet.rectangle.fill")
        case .shared_preference_read_only:
            return (
                Text("Read Shared Preferences"),
                Text("Read shared preferences."),
                "list.triangle")
        case .shared_preference_read_write:
            return (
                Text("Read & Write Shared Preferences"),
                Text("Read and write shared preferences."),
                "list.star")
        }
    }
}



extension AppCatalogItem {
    private static var rndgen = SeededRandomNumberGenerator(uuids: UUID(uuidString: "E3C3FF63-EF95-4BF4-BE53-EC88EE097556")!)
    private static func rnd() -> UInt8 { UInt8.random(in: .min...(.max), using: &rndgen) }

    static let sample = AppCatalogItem(name: "App Fair", bundleIdentifier: "app.App-Fair", subtitle: "The App Fair catalog browser app", developerName: "appfair@appfair.net", localizedDescription: "This app allows you to browse, download, and install apps from the App Fair. The App Fair catalog browser is the nexus for finding and installing App Fair apps", size: 1_234_567, version: "1.2.3", versionDate: Date(timeIntervalSinceNow: -60*60*24*2), downloadURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair-macOS.zip")!, iconURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair.png")!, screenshotURLs: nil, versionDescription: nil, tintColor: "#FF0000", beta: false, sourceIdentifier: nil, categories: [AppCategory.games.metadataIdentifier], downloadCount: 1_234, starCount: 123, watcherCount: 43, issueCount: 12, sourceSize: 2_210_000, coreSize: 223_197, sha256: UUID(bytes: rnd).uuidString, permissions: AppEntitlement.allCases.map { AppPermission(type: $0, usageDescription: "This app needs this entitlement") }, metadataURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair-macOS.plist"), readmeURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/README.md"))
}
