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

    var releasedVersion: AppVersion? {
        version.flatMap({ AppVersion(string: $0, prerelease: self.beta == true) })
    }

    /// All the entitlements, ordered by their index in the `AppEntitlement` cases.
    public func orderedPermissions(filterCategories: Set<AppEntitlement.Category> = []) -> Array<AppPermission> {
        (self.permissions ?? [])
            .filter {
                $0.type.categories.intersection(filterCategories).isEmpty
            }
    }

    /// A relative score summarizing how risky the app appears to be from a scale of 0–5
    var riskLevel: AppRisk {
        // let groups = Set(item.displayCategories.flatMap(\.groupings))
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
            return Text("Harmless", bundle: .module, comment: "risk assessment label for level 1 harmless apps")
        case .mostlyHarmless:
            return Text("Mostly Harmless", bundle: .module, comment: "risk assessment label for level 2 mostlyHarmless apps")
        case .risky:
            return Text("Risky", bundle: .module, comment: "risk assessment label for level 3 risky apps")
        case .hazardous:
            return Text("Hazardous", bundle: .module, comment: "risk assessment label for level 4 hazardous apps")
        case .dangerous:
            return Text("Dangerous", bundle: .module, comment: "risk assessment label for level 5 dangerous apps")
        case .perilous:
            return Text("Perilous", bundle: .module, comment: "risk assessment label for level 6 perilous apps")
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
            return Text("\(prefix) apps are sandboxed and have no ability to connect to the internet, read or write files outside of the sandbox, or connect to a camera, microphone, or other peripheral. They can be considered harmless in terms of the potential risks to your system and personal information.", bundle: .module, comment: "risk assessment summary text for level 1 harmless apps")
        case .mostlyHarmless:
            return Text("\(prefix) apps are granted a single category of permission, which means they can either connect to the internet, connect to a peripheral (such as the camera or microphone) or read files outside of their sandbox, but they cannot perform more than one of these categories of operations. These apps are not entirely without risk, but they can be generally considered safe.", bundle: .module, comment: "risk assessment summary text for level 2 mostlyHarmless apps")
        case .risky:
            return Text("\(prefix) apps are sandboxed and have a variety of permissions which, in combination, can put your system at risk. For example, they may be able to both read & write user-selected files, as well as connect to the internet, which makes them potential sources of data exfiltration or corruption. You should only install these apps from a reputable source.", bundle: .module, comment: "risk assessment summary text for level 3 risky apps")
        case .hazardous:
            return Text("\(prefix) apps are sandboxed and have a variety of permissions enabled. As such, they can perform many system operations that are unavailable to apps with reduced permission sets. You should only install these apps from a reputable source.", bundle: .module, comment: "risk assessment summary text for level 4 hazardous apps")
        case .dangerous:
            return Text("\(prefix) apps are still sandboxed, but they are granted a wide array of entitlements that makes them capable of damaging or hijacking your system. You should only install these apps from a trusted source.", bundle: .module, comment: "risk assessment summary text for level 5 dangerous apps")
        case .perilous:
            return Text("\(prefix) apps are granted all the categories of permission entitlement, and so can modify your system or damage your system in many ways. Despite being sandboxed, they should be considered to have the maximum possible permissions. You should only install these apps from a very trusted source.", bundle: .module, comment: "risk assessment summary text for level 6 perilous apps")
        }
    }
}

extension AppEntitlement : Identifiable {
    public var id: Self { self }

    /// Returns a text view with a description and summary of the given entitlement
    var localizedInfo: (title: Text, info: Text, symbol: FairSymbol) {
        switch self {
        case .app_sandbox:
            return (
                Text("Sandbox", bundle: .module, comment: "app entitlement title for app-sandbox"),
                Text("The Sandbox entitlement entitlement ensures that the app will run in a secure container.", bundle: .module, comment: "app entitlement info for app-sandbox"),
                .shield_fill)
        case .network_client:
            return (
                Text("Network Client", bundle: .module, comment: "app entitlement title for network.client"),
                Text("Communicate over the internet and any local networks.", bundle: .module, comment: "app entitlement info for network.client"),
                .globe)
        case .network_server:
            return (
                Text("Network Server", bundle: .module, comment: "app entitlement title for network.server"),
                Text("Handle network requests from the local network or the internet.", bundle: .module, comment: "app entitlement info for network.server"),
                .globe_badge_chevron_backward)
        case .device_camera:
            return (
                Text("Camera", bundle: .module, comment: "app entitlement title for device.camera"),
                Text("Use the device camera.", bundle: .module, comment: "app entitlement info for device.camera"),
                .camera)
        case .device_microphone:
            return (
                Text("Microphone", bundle: .module, comment: "app entitlement title for device.microphone"),
                Text("Use the device microphone.", bundle: .module, comment: "app entitlement info for device.microphone"),
                .mic)
        case .device_usb:
            return (
                Text("USB", bundle: .module, comment: "app entitlement title for device.usb"),
                Text("Access USB devices.", bundle: .module, comment: "app entitlement info for device.usb"),
                .cable_connector_horizontal)
        case .print:
            return (
                Text("Printing", bundle: .module, comment: "app entitlement title for print"),
                Text("Access printers.", bundle: .module, comment: "app entitlement info for print"),
                .printer)
        case .device_bluetooth:
            return (
                Text("Bluetooth", bundle: .module, comment: "app entitlement title for device.bluetooth"),
                Text("Access bluetooth.", bundle: .module, comment: "app entitlement info for device.bluetooth"),
                .b_circle_fill)
        case .device_audio_video_bridging:
            return (
                Text("Audio/Video Bridging", bundle: .module, comment: "app entitlement title for device.audio-video-bridging"),
                Text("Permit Audio/Bridging.", bundle: .module, comment: "app entitlement info for device.audio-video-bridging"),
                .point_3_connected_trianglepath_dotted)
        case .device_firewire:
            return (
                Text("Firewire", bundle: .module, comment: "app entitlement title for device.firewire"),
                Text("Access Firewire devices.", bundle: .module, comment: "app entitlement info for device.firewire"),
                .bolt_horizontal)
        case .device_serial:
            return (
                Text("Serial", bundle: .module, comment: "app entitlement title for device.serial"),
                Text("Access Serial devices.", bundle: .module, comment: "app entitlement info for device.serial"),
                .arrow_triangle_branch)
        case .device_audio_input:
            return (
                Text("Audio Input", bundle: .module, comment: "app entitlement title for device.audio-input"),
                Text("Access Audio Input devices.", bundle: .module, comment: "app entitlement info for device.audio-input"),
                .lines_measurement_horizontal)
        case .personal_information_addressbook:
            return (
                Text("Address Book", bundle: .module, comment: "app entitlement title for personal-information.addressbook"),
                Text("Access the user's personal address book.", bundle: .module, comment: "app entitlement info for personal-information.addressbook"),
                .text_book_closed)
        case .personal_information_location:
            return (
                Text("Location", bundle: .module, comment: "app entitlement title for personal-information.location"),
                Text("Access the user's personal location information.", bundle: .module, comment: "app entitlement info for personal-information.location"),
                .location)
        case .personal_information_calendars:
            return (
                Text("Calendars", bundle: .module, comment: "app entitlement title for personal-information.calendars"),
                Text("Access the user's personal calendar.", bundle: .module, comment: "app entitlement info for personal-information.calendars"),
                .calendar)
        case .files_user_selected_read_only:
            return (
                Text("Read User-Selected Files", bundle: .module, comment: "app entitlement title for files.user-selected.read-only"),
                Text("Read access to files explicitly selected by the user.", bundle: .module, comment: "app entitlement info for files.user-selected.read-only"),
                .doc)
        case .files_user_selected_read_write:
            return (
                Text("Read & Write User-Selected Files", bundle: .module, comment: "app entitlement title for files.user-selected.read-write"),
                Text("Read and write access to files explicitly selected by the user.", bundle: .module, comment: "app entitlement info for files.user-selected.read-write"),
                .doc_fill)
        case .files_user_selected_executable:
            return (
                Text("Executables (User-Selected)", bundle: .module, comment: "app entitlement title for files.user-selected.executable"),
                Text("Read access to executables explicitly selected by the user.", bundle: .module, comment: "app entitlement info for files.user-selected.executable"),
                .doc_text_below_ecg)
        case .files_downloads_read_only:
            return (
                Text("Read Download Folder", bundle: .module, comment: "app entitlement title for files.downloads.read-only"),
                Text("Read access to the user's Downloads folder", bundle: .module, comment: "app entitlement info for files.downloads.read-only"),
                .arrow_up_and_down_square)
        case .files_downloads_read_write:
            return (
                Text("Read & Write Downloads Folder", bundle: .module, comment: "app entitlement title for files.downloads.read-write"),
                Text("Read and write access to the user's Downloads folder", bundle: .module, comment: "app entitlement info for files.downloads.read-write"),
                .arrow_up_and_down_square_fill)
        case .assets_pictures_read_only:
            return (
                Text("Read Pictures", bundle: .module, comment: "app entitlement title for assets.pictures.read-only"),
                Text("Read access to the user's Pictures folder", bundle: .module, comment: "app entitlement info for assets.pictures.read-only"),
                .photo)
        case .assets_pictures_read_write:
            return (
                Text("Read & Write Pictures", bundle: .module, comment: "app entitlement title for assets.pictures.read-write"),
                Text("Read and write access to the user's Pictures folder", bundle: .module, comment: "app entitlement info for assets.pictures.read-write"),
                .photo_fill)
        case .assets_music_read_only:
            return (
                Text("Read Music", bundle: .module, comment: "app entitlement title for assets.music.read-only"),
                Text("Read access to the user's Music folder", bundle: .module, comment: "app entitlement info for assets.music.read-only"),
                .radio)
        case .assets_music_read_write:
            return (
                Text("Read & Write Music", bundle: .module, comment: "app entitlement title for assets.music.read-write"),
                Text("Read and write access to the user's Music folder", bundle: .module, comment: "app entitlement info for assets.music.read-write"),
                .radio_fill)
        case .assets_movies_read_only:
            return (
                Text("Read Movies", bundle: .module, comment: "app entitlement title for assets.movies.read-only"),
                Text("Read access to the user's Movies folder", bundle: .module, comment: "app entitlement info for assets.movies.read-only"),
                .film)
        case .assets_movies_read_write:
            return (
                Text("Read & Write Movies", bundle: .module, comment: "app entitlement title for assets.movies.read-write"),
                Text("Read and write access to the user's Movies folder", bundle: .module, comment: "app entitlement info for assets.movies.read-write"),
                .film_fill)
        case .files_all:
            return (
                Text("Read & Write All Files", bundle: .module, comment: "app entitlement title for files.all"),
                Text("Read and write all files on the system.", bundle: .module, comment: "app entitlement info for files.all"),
                .doc_on_doc_fill)
        case .cs_allow_jit:
            return (
                Text("Just-In-Time Compiler", bundle: .module, comment: "app entitlement title for cs.allow-jit"),
                Text("Enable performace booting.", bundle: .module, comment: "app entitlement info for cs.allow-jit"),
                .hare)
        case .cs_debugger:
            return (
                Text("Debugging", bundle: .module, comment: "app entitlement title for cs.debugger"),
                Text("Allows the app to act as a debugger and inspect the internal information of other apps in the system.", bundle: .module, comment: "app entitlement info for cs.debugger"),
                .stethoscope)
        case .cs_allow_unsigned_executable_memory:
            return (
                Text("Unsigned Executable Memory", bundle: .module, comment: "app entitlement title for cs.allow-unsigned-executable-memory"),
                Text("Permit and app to create writable and executable memory without the restrictions imposed by using the MAP_JIT flag.", bundle: .module, comment: "app entitlement info for cs.allow-unsigned-executable-memory"),
                .hammer)
        case .cs_allow_dyld_environment_variables:
            return (
                Text("Dynamic Linker Variables", bundle: .module, comment: "app entitlement title for cs.allow-dyld-environment-variables"),
                Text("Permit the app to be affected by dynamic linker environment variables, which can be used to inject code into the app's process.", bundle: .module, comment: "app entitlement info for cs.allow-dyld-environment-variables"),
                .screwdriver)
        case .cs_disable_library_validation:
            return (
                Text("Disable Library Validation", bundle: .module, comment: "app entitlement title for cs.disable-library-validation"),
                Text("Permit the app to load arbitrary plug-ins or frameworks without requiring code signing.", bundle: .module, comment: "app entitlement info for cs.disable-library-validation"),
                .wrench)
        case .cs_disable_executable_page_protection:
            return (
                Text("Disable Executable Page Protection", bundle: .module, comment: "app entitlement title for cs.disable-executable-page-protection"),
                Text("Permits the app the disable all code signing protections while launching an app and during its execution.", bundle: .module, comment: "app entitlement info for cs.disable-executable-page-protection"),
                .bandage)
        case .scripting_targets:
            return (
                Text("Scripting Target", bundle: .module, comment: "app entitlement title for scripting-targets"),
                Text("Ability to use specific scripting access groups within a specific scriptable app.", bundle: .module, comment: "app entitlement info for scripting-targets"),
                .scroll)
        case .application_groups:
            return (
                Text("Application Groups", bundle: .module, comment: "app entitlement title for application-groups"),
                Text("Share files and preferences between applications.", bundle: .module, comment: "app entitlement info for application-groups"),
                .square_grid_3x3_square)
        case .files_bookmarks_app_scope:
            return (
                Text("File Bookmarks App-Scope", bundle: .module, comment: "app entitlement title for files.bookmarks.app-scope"),
                Text("Enables use of app-scoped bookmarks and URLs.", bundle: .module, comment: "app entitlement info for files.bookmarks.app-scope"),
                .bookmark_fill)
        case .files_bookmarks_document_scope:
            return (
                Text("File Bookmarks Document-Scope", bundle: .module, comment: "app entitlement title for files.bookmarks.document-scope"),
                Text("Enables use of document-scoped bookmarks and URLs.", bundle: .module, comment: "app entitlement info for files.bookmarks.document-scope"),
                .bookmark)
        case .files_home_relative_path_read_only:
            return (
                Text("User Home Files Read-Only", bundle: .module, comment: "app entitlement title for temporary-exception.files.home-relative-path.read-only"),
                Text("Enables read-only access to the specified files or subdirectories in the user's home directory.", bundle: .module, comment: "app entitlement info for temporary-exception.files.home-relative-path.read-only"),
                .doc_badge_ellipsis)
        case .files_home_relative_path_read_write:
            return (
                Text("User Home Files Read-Write", bundle: .module, comment: "app entitlement title for temporary-exception.files.home-relative-path.read-write"),
                Text("Enables read/write access to the specified files or subdirectories in the user's home directory.", bundle: .module, comment: "app entitlement info for temporary-exception.files.home-relative-path.read-write"),
                .doc_fill_badge_ellipsis)
        case .files_absolute_path_read_only:
            return (
                Text("Global Files Read-Only", bundle: .module, comment: "app entitlement title for temporary-exception.files.absolute-path.read-only"),
                Text("Enables read-only access to the specified files or directories at specified absolute paths.", bundle: .module, comment: "app entitlement info for temporary-exception.files.absolute-path.read-only"),
                .doc_badge_gearshape)
        case .files_absolute_path_read_write:
            return (
                Text("Global Files Read-Write", bundle: .module, comment: "app entitlement title for temporary-exception.files.absolute-path.read-write"),
                Text("Enables read/write access to the specified files or directories at specified absolute paths.", bundle: .module, comment: "app entitlement info for temporary-exception.files.absolute-path.read-write"),
                .doc_badge_gearshape_fill)
        case .apple_events:
            return (
                Text("Apple Events", bundle: .module, comment: "app entitlement title for temporary-exception.apple-events"),
                Text("Enables sending of Apple events to one or more destination apps.", bundle: .module, comment: "app entitlement info for temporary-exception.apple-events"),
                .scroll_fill)
        case .audio_unit_host:
            return (
                Text("Audio Unit Host", bundle: .module, comment: "app entitlement title for temporary-exception.audio-unit-host"),
                Text("Enables hosting of audio components that are not designated as sandbox-safe.", bundle: .module, comment: "app entitlement info for temporary-exception.audio-unit-host"),
                .waveform)
        case .iokit_user_client_class:
            return (
                Text("IOKit User Client", bundle: .module, comment: "app entitlement title for temporary-exception.iokit-user-client-class"),
                Text("Ability to specify additional IOUserClient subclasses.", bundle: .module, comment: "app entitlement info for temporary-exception.iokit-user-client-class"),
                .waveform_badge_exclamationmark)
        case .mach_lookup_global_name:
            return (
                Text("Mach Global Name Lookup", bundle: .module, comment: "app entitlement title for temporary-exception.mach-lookup.global-name"),
                Text("Lookup global Mach services.", bundle: .module, comment: "app entitlement info for temporary-exception.mach-lookup.global-name"),
                .list_bullet_rectangle)
        case .mach_register_global_name:
            return (
                Text("Mach Global Name Register", bundle: .module, comment: "app entitlement title for temporary-exception.mach-register.global-name"),
                Text("Register global Mach services.", bundle: .module, comment: "app entitlement info for temporary-exception.mach-register.global-name"),
                .list_bullet_rectangle_fill)
        case .shared_preference_read_only:
            return (
                Text("Read Shared Preferences", bundle: .module, comment: "app entitlement title for temporary-exception.shared-preference.read-only"),
                Text("Read shared preferences.", bundle: .module, comment: "app entitlement info for temporary-exception.shared-preference.read-only"),
                .list_triangle)
        case .shared_preference_read_write:
            return (
                Text("Read & Write Shared Preferences", bundle: .module, comment: "app entitlement title for temporary-exception.shared-preference.read-write"),
                Text("Read and write shared preferences.", bundle: .module, comment: "app entitlement info for temporary-exception.shared-preference.read-write"),
                .list_star)
        }
    }
}



extension AppCatalogItem {
    private static var rndgen = SeededRandomNumberGenerator(uuids: UUID(uuidString: "E3C3FF63-EF95-4BF4-BE53-EC88EE097556")!)
    private static func rnd() -> UInt8 { UInt8.random(in: .min...(.max), using: &rndgen) }

    static let sample = AppCatalogItem(name: "App Fair", bundleIdentifier: .init("app.App-Fair"), subtitle: "The App Fair catalog browser app", developerName: "appfair@appfair.net", localizedDescription: "This app allows you to browse, download, and install apps from the App Fair. The App Fair catalog browser is the nexus for finding and installing App Fair apps", size: 1_234_567, version: "1.2.3", versionDate: Date(timeIntervalSinceNow: -60*60*24*2), downloadURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair-macOS.zip")!, iconURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair.png")!, screenshotURLs: nil, versionDescription: nil, tintColor: "#FF0000", beta: false, sourceIdentifier: nil, categories: [AppCategory.games.metadataIdentifier], downloadCount: 1_234, impressionCount: nil, viewCount: nil, starCount: 123, watcherCount: 43, issueCount: 12, sourceSize: 2_210_000, coreSize: 223_197, sha256: UUID(bytes: rnd).uuidString, permissions: AppEntitlement.allCases.map { AppPermission(type: $0, usageDescription: "This app needs this entitlement") }, metadataURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair-macOS.plist"), readmeURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/README.md"), releaseNotesURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/RELEASE_NOTES.md"), homepage: URL(string: "https://www.appfair.app"))
}
