/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 The full text of the GNU Affero General Public License can be
 found in the COPYING.txt file or at https://www.gnu.org/licenses/

 Linking this library statically or dynamically with other modules is
 making a combined work based on this library.  Thus, the terms and
 conditions of the GNU Affero General Public License cover the whole
 combination.

 As a special exception, the copyright holders of this library give you
 permission to link this library with independent modules to produce an
 executable, regardless of the license terms of these independent
 modules, and to copy and distribute the resulting executable under
 terms of your choice, provided that you also meet, for each linked
 independent module, the terms and conditions of the license of that
 module.  An independent module is a module which is not derived from
 or based on this library.  If you modify this library, you may extend
 this exception to your version of the library, but you are not
 obligated to do so.  If you do not wish to do so, delete this
 exception statement from your version.
 */
import FairApp
import SwiftUI

extension AppCatalogItem {
    var releasedVersion: AppVersion? {
        version.flatMap({ AppVersion(string: $0) })
    }

    /// A relative score summarizing how risky the app appears to be from a scale of 0–5
    var riskLevel: AppRisk {
        // let groups = Set(item.displayCategories.flatMap(\.groupings))
        let categories = Set((self.permissionsEntitlements ?? []).flatMap(\.identifier.categories)).subtracting([.prerequisite, .harmless])
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
    var primaryCategoryIdentifier: AppCategoryType? {
        categories?.first
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
            return Text("Harmless", comment: "risk assessment label for level 1 harmless apps")
        case .mostlyHarmless:
            return Text("Mostly Harmless", comment: "risk assessment label for level 2 mostlyHarmless apps")
        case .risky:
            return Text("Risky", comment: "risk assessment label for level 3 risky apps")
        case .hazardous:
            return Text("Hazardous", comment: "risk assessment label for level 4 hazardous apps")
        case .dangerous:
            return Text("Dangerous", comment: "risk assessment label for level 5 dangerous apps")
        case .perilous:
            return Text("Perilous", comment: "risk assessment label for level 6 perilous apps")
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
        //.help(Text("Based on the number of permission categories this app requests this app can be considered: \(riskLevel.textLabel())", comment: "tooltip text for describing install risk"))
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
            return Text("\(prefix) apps are sandboxed and have no ability to connect to the internet, read or write files outside of the sandbox, or connect to a camera, microphone, or other peripheral. They can be considered harmless in terms of the potential risks to your system and personal information.", comment: "risk assessment summary text for level 1 harmless apps")
        case .mostlyHarmless:
            return Text("\(prefix) apps are granted a single category of permission, which means they can either connect to the internet, connect to a peripheral (such as the camera or microphone) or read files outside of their sandbox, but they cannot perform more than one of these categories of operations. These apps are not entirely without risk, but they can be generally considered safe.", comment: "risk assessment summary text for level 2 mostlyHarmless apps")
        case .risky:
            return Text("\(prefix) apps are sandboxed and have a variety of permissions which, in combination, can put your system at risk. For example, they may be able to both read & write user-selected files, as well as connect to the internet, which makes them potential sources of data exfiltration or corruption. You should only install these apps from a reputable source.", comment: "risk assessment summary text for level 3 risky apps")
        case .hazardous:
            return Text("\(prefix) apps are sandboxed and have a variety of permissions enabled. As such, they can perform many system operations that are unavailable to apps with reduced permission sets. You should only install these apps from a reputable source.", comment: "risk assessment summary text for level 4 hazardous apps")
        case .dangerous:
            return Text("\(prefix) apps are still sandboxed, but they are granted a wide array of entitlements that makes them capable of damaging or hijacking your system. You should only install these apps from a trusted source.", comment: "risk assessment summary text for level 5 dangerous apps")
        case .perilous:
            return Text("\(prefix) apps are granted all the categories of permission entitlement, and so can modify your system or damage your system in many ways. Despite being sandboxed, they should be considered to have the maximum possible permissions. You should only install these apps from a very trusted source.", comment: "risk assessment summary text for level 6 perilous apps")
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
                Text("Sandbox", comment: "app entitlement title for app-sandbox"),
                Text("The Sandbox entitlement entitlement ensures that the app will run in a secure container.", comment: "app entitlement info for app-sandbox"),
                .shield_fill)
        case .network_client:
            return (
                Text("Network Client", comment: "app entitlement title for network.client"),
                Text("Communicate over the internet and any local networks.", comment: "app entitlement info for network.client"),
                .globe)
        case .network_server:
            return (
                Text("Network Server", comment: "app entitlement title for network.server"),
                Text("Handle network requests from the local network or the internet.", comment: "app entitlement info for network.server"),
                .globe_badge_chevron_backward)
        case .device_camera:
            return (
                Text("Camera", comment: "app entitlement title for device.camera"),
                Text("Use the device camera.", comment: "app entitlement info for device.camera"),
                .camera)
        case .device_microphone:
            return (
                Text("Microphone", comment: "app entitlement title for device.microphone"),
                Text("Use the device microphone.", comment: "app entitlement info for device.microphone"),
                .mic)
        case .device_usb:
            return (
                Text("USB", comment: "app entitlement title for device.usb"),
                Text("Access USB devices.", comment: "app entitlement info for device.usb"),
                .cable_connector_horizontal)
        case .print:
            return (
                Text("Printing", comment: "app entitlement title for print"),
                Text("Access printers.", comment: "app entitlement info for print"),
                .printer)
        case .device_bluetooth:
            return (
                Text("Bluetooth", comment: "app entitlement title for device.bluetooth"),
                Text("Access bluetooth.", comment: "app entitlement info for device.bluetooth"),
                .b_circle_fill)
        case .device_audio_video_bridging:
            return (
                Text("Audio/Video Bridging", comment: "app entitlement title for device.audio-video-bridging"),
                Text("Permit Audio/Bridging.", comment: "app entitlement info for device.audio-video-bridging"),
                .point_3_connected_trianglepath_dotted)
        case .device_firewire:
            return (
                Text("Firewire", comment: "app entitlement title for device.firewire"),
                Text("Access Firewire devices.", comment: "app entitlement info for device.firewire"),
                .bolt_horizontal)
        case .device_serial:
            return (
                Text("Serial", comment: "app entitlement title for device.serial"),
                Text("Access Serial devices.", comment: "app entitlement info for device.serial"),
                .arrow_triangle_branch)
        case .device_audio_input:
            return (
                Text("Audio Input", comment: "app entitlement title for device.audio-input"),
                Text("Access Audio Input devices.", comment: "app entitlement info for device.audio-input"),
                .lines_measurement_horizontal)
        case .personal_information_addressbook:
            return (
                Text("Address Book", comment: "app entitlement title for personal-information.addressbook"),
                Text("Access the user's personal address book.", comment: "app entitlement info for personal-information.addressbook"),
                .text_book_closed)
        case .personal_information_location:
            return (
                Text("Location", comment: "app entitlement title for personal-information.location"),
                Text("Access the user's personal location information.", comment: "app entitlement info for personal-information.location"),
                .location)
        case .personal_information_calendars:
            return (
                Text("Calendars", comment: "app entitlement title for personal-information.calendars"),
                Text("Access the user's personal calendar.", comment: "app entitlement info for personal-information.calendars"),
                .calendar)
        case .files_user_selected_read_only:
            return (
                Text("Read User-Selected Files", comment: "app entitlement title for files.user-selected.read-only"),
                Text("Read access to files explicitly selected by the user.", comment: "app entitlement info for files.user-selected.read-only"),
                .doc)
        case .files_user_selected_read_write:
            return (
                Text("Read & Write User-Selected Files", comment: "app entitlement title for files.user-selected.read-write"),
                Text("Read and write access to files explicitly selected by the user.", comment: "app entitlement info for files.user-selected.read-write"),
                .doc_fill)
        case .files_user_selected_executable:
            return (
                Text("Executables (User-Selected)", comment: "app entitlement title for files.user-selected.executable"),
                Text("Read access to executables explicitly selected by the user.", comment: "app entitlement info for files.user-selected.executable"),
                .doc_text_below_ecg)
        case .files_downloads_read_only:
            return (
                Text("Read Download Folder", comment: "app entitlement title for files.downloads.read-only"),
                Text("Read access to the user's Downloads folder", comment: "app entitlement info for files.downloads.read-only"),
                .arrow_up_and_down_square)
        case .files_downloads_read_write:
            return (
                Text("Read & Write Downloads Folder", comment: "app entitlement title for files.downloads.read-write"),
                Text("Read and write access to the user's Downloads folder", comment: "app entitlement info for files.downloads.read-write"),
                .arrow_up_and_down_square_fill)
        case .assets_pictures_read_only:
            return (
                Text("Read Pictures", comment: "app entitlement title for assets.pictures.read-only"),
                Text("Read access to the user's Pictures folder", comment: "app entitlement info for assets.pictures.read-only"),
                .photo)
        case .assets_pictures_read_write:
            return (
                Text("Read & Write Pictures", comment: "app entitlement title for assets.pictures.read-write"),
                Text("Read and write access to the user's Pictures folder", comment: "app entitlement info for assets.pictures.read-write"),
                .photo_fill)
        case .assets_music_read_only:
            return (
                Text("Read Music", comment: "app entitlement title for assets.music.read-only"),
                Text("Read access to the user's Music folder", comment: "app entitlement info for assets.music.read-only"),
                .radio)
        case .assets_music_read_write:
            return (
                Text("Read & Write Music", comment: "app entitlement title for assets.music.read-write"),
                Text("Read and write access to the user's Music folder", comment: "app entitlement info for assets.music.read-write"),
                .radio_fill)
        case .assets_movies_read_only:
            return (
                Text("Read Movies", comment: "app entitlement title for assets.movies.read-only"),
                Text("Read access to the user's Movies folder", comment: "app entitlement info for assets.movies.read-only"),
                .film)
        case .assets_movies_read_write:
            return (
                Text("Read & Write Movies", comment: "app entitlement title for assets.movies.read-write"),
                Text("Read and write access to the user's Movies folder", comment: "app entitlement info for assets.movies.read-write"),
                .film_fill)
        case .files_all:
            return (
                Text("Read & Write All Files", comment: "app entitlement title for files.all"),
                Text("Read and write all files on the system.", comment: "app entitlement info for files.all"),
                .doc_on_doc_fill)
        case .cs_allow_jit:
            return (
                Text("Just-In-Time Compiler", comment: "app entitlement title for cs.allow-jit"),
                Text("Enable performace booting.", comment: "app entitlement info for cs.allow-jit"),
                .hare)
        case .cs_debugger:
            return (
                Text("Debugging", comment: "app entitlement title for cs.debugger"),
                Text("Allows the app to act as a debugger and inspect the internal information of other apps in the system.", comment: "app entitlement info for cs.debugger"),
                .stethoscope)
        case .cs_allow_unsigned_executable_memory:
            return (
                Text("Unsigned Executable Memory", comment: "app entitlement title for cs.allow-unsigned-executable-memory"),
                Text("Permit and app to create writable and executable memory without the restrictions imposed by using the MAP_JIT flag.", comment: "app entitlement info for cs.allow-unsigned-executable-memory"),
                .hammer)
        case .cs_allow_dyld_environment_variables:
            return (
                Text("Dynamic Linker Variables", comment: "app entitlement title for cs.allow-dyld-environment-variables"),
                Text("Permit the app to be affected by dynamic linker environment variables, which can be used to inject code into the app's process.", comment: "app entitlement info for cs.allow-dyld-environment-variables"),
                .screwdriver)
        case .cs_disable_library_validation:
            return (
                Text("Disable Library Validation", comment: "app entitlement title for cs.disable-library-validation"),
                Text("Permit the app to load arbitrary plug-ins or frameworks without requiring code signing.", comment: "app entitlement info for cs.disable-library-validation"),
                .wrench)
        case .cs_disable_executable_page_protection:
            return (
                Text("Disable Executable Page Protection", comment: "app entitlement title for cs.disable-executable-page-protection"),
                Text("Permits the app the disable all code signing protections while launching an app and during its execution.", comment: "app entitlement info for cs.disable-executable-page-protection"),
                .bandage)
        case .scripting_targets:
            return (
                Text("Scripting Target", comment: "app entitlement title for scripting-targets"),
                Text("Ability to use specific scripting access groups within a specific scriptable app.", comment: "app entitlement info for scripting-targets"),
                .scroll)
        case .application_groups:
            return (
                Text("Application Groups", comment: "app entitlement title for application-groups"),
                Text("Share files and preferences between applications.", comment: "app entitlement info for application-groups"),
                .square_grid_3x3_square)
        case .files_bookmarks_app_scope:
            return (
                Text("File Bookmarks App-Scope", comment: "app entitlement title for files.bookmarks.app-scope"),
                Text("Enables use of app-scoped bookmarks and URLs.", comment: "app entitlement info for files.bookmarks.app-scope"),
                .bookmark_fill)
        case .files_bookmarks_document_scope:
            return (
                Text("File Bookmarks Document-Scope", comment: "app entitlement title for files.bookmarks.document-scope"),
                Text("Enables use of document-scoped bookmarks and URLs.", comment: "app entitlement info for files.bookmarks.document-scope"),
                .bookmark)
        case .files_home_relative_path_read_only:
            return (
                Text("User Home Files Read-Only", comment: "app entitlement title for temporary-exception.files.home-relative-path.read-only"),
                Text("Enables read-only access to the specified files or subdirectories in the user's home directory.", comment: "app entitlement info for temporary-exception.files.home-relative-path.read-only"),
                .doc_badge_ellipsis)
        case .files_home_relative_path_read_write:
            return (
                Text("User Home Files Read-Write", comment: "app entitlement title for temporary-exception.files.home-relative-path.read-write"),
                Text("Enables read/write access to the specified files or subdirectories in the user's home directory.", comment: "app entitlement info for temporary-exception.files.home-relative-path.read-write"),
                .doc_fill_badge_ellipsis)
        case .files_absolute_path_read_only:
            return (
                Text("Global Files Read-Only", comment: "app entitlement title for temporary-exception.files.absolute-path.read-only"),
                Text("Enables read-only access to the specified files or directories at specified absolute paths.", comment: "app entitlement info for temporary-exception.files.absolute-path.read-only"),
                .doc_badge_gearshape)
        case .files_absolute_path_read_write:
            return (
                Text("Global Files Read-Write", comment: "app entitlement title for temporary-exception.files.absolute-path.read-write"),
                Text("Enables read/write access to the specified files or directories at specified absolute paths.", comment: "app entitlement info for temporary-exception.files.absolute-path.read-write"),
                .doc_badge_gearshape_fill)
        case .apple_events:
            return (
                Text("Apple Events", comment: "app entitlement title for temporary-exception.apple-events"),
                Text("Enables sending of Apple events to one or more destination apps.", comment: "app entitlement info for temporary-exception.apple-events"),
                .scroll_fill)
        case .audio_unit_host:
            return (
                Text("Audio Unit Host", comment: "app entitlement title for temporary-exception.audio-unit-host"),
                Text("Enables hosting of audio components that are not designated as sandbox-safe.", comment: "app entitlement info for temporary-exception.audio-unit-host"),
                .waveform)
        case .iokit_user_client_class:
            return (
                Text("IOKit User Client", comment: "app entitlement title for temporary-exception.iokit-user-client-class"),
                Text("Ability to specify additional IOUserClient subclasses.", comment: "app entitlement info for temporary-exception.iokit-user-client-class"),
                .waveform_badge_exclamationmark)
        case .mach_lookup_global_name:
            return (
                Text("Mach Global Name Lookup", comment: "app entitlement title for temporary-exception.mach-lookup.global-name"),
                Text("Lookup global Mach services.", comment: "app entitlement info for temporary-exception.mach-lookup.global-name"),
                .list_bullet_rectangle)
        case .mach_register_global_name:
            return (
                Text("Mach Global Name Register", comment: "app entitlement title for temporary-exception.mach-register.global-name"),
                Text("Register global Mach services.", comment: "app entitlement info for temporary-exception.mach-register.global-name"),
                .list_bullet_rectangle_fill)
        case .shared_preference_read_only:
            return (
                Text("Read Shared Preferences", comment: "app entitlement title for temporary-exception.shared-preference.read-only"),
                Text("Read shared preferences.", comment: "app entitlement info for temporary-exception.shared-preference.read-only"),
                .list_triangle)
        case .shared_preference_read_write:
            return (
                Text("Read & Write Shared Preferences", comment: "app entitlement title for temporary-exception.shared-preference.read-write"),
                Text("Read and write shared preferences.", comment: "app entitlement info for temporary-exception.shared-preference.read-write"),
                .list_star)
        default:
            return (
                Text(self.rawValue),
                Text("Unknown entitlement: \(self.rawValue).", comment: "app entitlement info an unrecognized entitlement"),
                .questionmark_app)

        }
    }
}



extension AppCatalogItem {
    private static var rndgen = SeededRandomNumberGenerator(uuids: UUID(uuidString: "E3C3FF63-EF95-4BF4-BE53-EC88EE097556")!)
    private static func rnd() -> UInt8 { UInt8.random(in: .min...(.max), using: &rndgen) }

    static let sample = AppCatalogItem(name: "App Fair", bundleIdentifier: .init("app.App-Fair"), subtitle: "The App Fair catalog browser app", developerName: "appfair@appfair.net", localizedDescription: "This app allows you to browse, download, and install apps from the App Fair. The App Fair catalog browser is the nexus for finding and installing App Fair apps", size: 1_234_567, version: "1.2.3", versionDate: Date(timeIntervalSinceNow: -60*60*24*2), downloadURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair-macOS.zip")!, iconURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair.png")!, screenshotURLs: nil, versionDescription: nil, tintColor: "#FF0000", beta: false, categories: [.games], sha256: UUID(bytes: rnd).uuidString, permissions: AppEntitlement.allCases.map { AppEntitlementPermission(entitlement: $0, usageDescription: "This app needs this entitlement") }.map { .init($0) }, metadataURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair-macOS.plist"), readmeURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/README.md"), releaseNotesURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/RELEASE_NOTES.md"), homepage: URL(string: "https://www.appfair.app"), stats: AppStats(downloadCount: 1_234, starCount: 123, watcherCount: 43, issueCount: 12, coreSize: 223_197))
}
