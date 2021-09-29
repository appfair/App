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

extension AppCatalogItem {

    /// All the entitlements, ordered by their index in the `AppEntitlement` cases.
    public var orderedEntitlements: Array<AppEntitlement> {
        let activeEntitlements = self.entitlements
        return AppEntitlement.allCases.filter(activeEntitlements.contains)
    }
}

extension AppEntitlement : Identifiable {
    public var id: Self { self }

    /// Returns a text view with a description and summary of the given entitlement
    var localizedInfo: (title: Text, info: Text, symbol: String) {
        switch self {
        case .app_sandbox:
            return (
                Text("Sandbox", bundle: .module),
                Text("The Sandbox entitlement entitlement ensures that the app will run in a secure container.", bundle: .module),
                "shield.fill")
        case .network_client:
            return (
                Text("Network Client", bundle: .module),
                Text("Communicate over the internet and any local networks.", bundle: .module),
                "globe")
        case .network_server:
            return (
                Text("Network Server", bundle: .module),
                Text("Handle network requests from the local network or the internet.", bundle: .module),
                "globe.badge.chevron.backward")
        case .device_camera:
            return (
                Text("Camera", bundle: .module),
                Text("Use the device camera.", bundle: .module),
                "camera")
        case .device_microphone:
            return (
                Text("Microphone", bundle: .module),
                Text("Use the device microphone.", bundle: .module),
                "mic")
        case .device_usb:
            return (
                Text("USB", bundle: .module),
                Text("Access USB devices.", bundle: .module),
                "cable.connector.horizontal")
        case .print:
            return (
                Text("Printing", bundle: .module),
                Text("Access printers.", bundle: .module),
                "printer")
        case .device_bluetooth:
            return (
                Text("Bluetooth", bundle: .module),
                Text("Access bluetooth.", bundle: .module),
                "b.circle.fill")
        case .device_audio_video_bridging:
            return (
                Text("Audio/Video Bridging", bundle: .module),
                Text("Permit Audio/Bridging.", bundle: .module),
                "point.3.connected.trianglepath.dotted")
        case .device_firewire:
            return (
                Text("Firewire", bundle: .module),
                Text("Access Firewire devices.", bundle: .module),
                "bolt.horizontal")
        case .device_serial:
            return (
                Text("Serial", bundle: .module),
                Text("Access Serial devices.", bundle: .module),
                "arrow.triangle.branch")
        case .device_audio_input:
            return (
                Text("Audio Input", bundle: .module),
                Text("Access Audio Input devices.", bundle: .module),
                "lines.measurement.horizontal")
        case .personal_information_addressbook:
            return (
                Text("Address Book", bundle: .module),
                Text("Access the user's personal address book.", bundle: .module),
                "text.book.closed")
        case .personal_information_location:
            return (
                Text("Location", bundle: .module),
                Text("Access the user's personal location information.", bundle: .module),
                "location")
        case .personal_information_calendars:
            return (
                Text("Calendars", bundle: .module),
                Text("Access the user's personal calendar.", bundle: .module),
                "calendar")
        case .files_user_selected_read_only:
            return (
                Text("User-Selected Read-Only", bundle: .module),
                Text("Read access to files explicitly selected by the user.", bundle: .module),
                "doc")
        case .files_user_selected_read_write:
            return (
                Text("User-Selected Read-Write", bundle: .module),
                Text("Read and write access to files explicitly selected by the user.", bundle: .module),
                "doc.fill")
        case .files_user_selected_executable:
            return (
                Text("User-Selected Executable", bundle: .module),
                Text("Read access to executables explicitly selected by the user.", bundle: .module),
                "doc.text.below.ecg")
        case .files_downloads_read_only:
            return (
                Text("Downloads Read-Only", bundle: .module),
                Text("Read access to the user's Downloads folder", bundle: .module),
                "arrow.up.and.down.square")
        case .files_downloads_read_write:
            return (
                Text("Downloads Read-Write", bundle: .module),
                Text("Read and write access to the user's Downloads folder", bundle: .module),
                "arrow.up.and.down.square.fill")
        case .assets_pictures_read_only:
            return (
                Text("Pictures Read-Only", bundle: .module),
                Text("Read access to the user's Pictures folder", bundle: .module),
                "photo")
        case .assets_pictures_read_write:
            return (
                Text("Pictures Read-Write", bundle: .module),
                Text("Read and write access to the user's Pictures folder", bundle: .module),
                "photo.fill")
        case .assets_music_read_only:
            return (
                Text("Music Read-Only", bundle: .module),
                Text("Read access to the user's Music folder", bundle: .module),
                "radio")
        case .assets_music_read_write:
            return (
                Text("Music Read-Write", bundle: .module),
                Text("Read and write access to the user's Music folder", bundle: .module),
                "radio.fill")
        case .assets_movies_read_only:
            return (
                Text("Movies Read-Only", bundle: .module),
                Text("Read access to the user's Movies folder", bundle: .module),
                "film")
        case .assets_movies_read_write:
            return (
                Text("Movies Read-Write", bundle: .module),
                Text("Read and write access to the user's Movies folder", bundle: .module),
                "film.fill")
        case .files_all:
            return (
                Text("All Files", bundle: .module),
                Text("Read and write all files on the system.", bundle: .module),
                "doc.on.doc.fill")
        case .cs_allow_jit:
            return (
                Text("Just-In-Time Compiler", bundle: .module),
                Text("Enable performace booting.", bundle: .module),
                "hare")
        case .cs_debugger:
            return (
                Text("Debugging", bundle: .module),
                Text("Allows the app to act as a debugger and inspect the internal information of other apps in the system.", bundle: .module),
                "stethoscope")
        case .cs_allow_unsigned_executable_memory:
            return (
                Text("Unsigned Executable Memory", bundle: .module),
                Text("Permit and app to create writable and executable memory without the restrictions imposed by using the MAP_JIT flag.", bundle: .module),
                "hammer")
        case .cs_allow_dyld_environment_variables:
            return (
                Text("Dynamic Linker Variables", bundle: .module),
                Text("Permit the app to be affected by dynamic linker environment variables, which can be used to inject code into the app's process.", bundle: .module),
                "screwdriver")
        case .cs_disable_library_validation:
            return (
                Text("Disable Library Validation", bundle: .module),
                Text("Permit the app to load arbitrary plug-ins or frameworks without requiring code signing.", bundle: .module),
                "wrench")
        case .cs_disable_executable_page_protection:
            return (
                Text("Disable Executable Page Protection", bundle: .module),
                Text("Permits the app the disable all code signing protections while launching an app and during its execution.", bundle: .module),
                "bandage")
        case .scripting_targets:
            return (
                Text("Scripting Target", bundle: .module),
                Text("Ability to use specific scripting access groups within a specific scriptable app.", bundle: .module),
                "scroll")
        case .application_groups:
            return (
                Text("Application Groups", bundle: .module),
                Text("Share files and preferences between applications.", bundle: .module),
                "square.grid.3x3.square")
        case .files_bookmarks_app_scope:
            return (
                Text("File Bookmarks App-Scope", bundle: .module),
                Text("Enables use of app-scoped bookmarks and URLs.", bundle: .module),
                "bookmark.fill")
        case .files_bookmarks_document_scope:
            return (
                Text("File Bookmarks Document-Scope", bundle: .module),
                Text("Enables use of document-scoped bookmarks and URLs.", bundle: .module),
                "bookmark")
        case .files_home_relative_path_read_only:
            return (
                Text("User Home Files Read-Only", bundle: .module),
                Text("Enables read-only access to the specified files or subdirectories in the user's home directory.", bundle: .module),
                "doc.badge.ellipsis")
        case .files_home_relative_path_read_write:
            return (
                Text("User Home Files Read-Write", bundle: .module),
                Text("Enables read/write access to the specified files or subdirectories in the user's home directory.", bundle: .module),
                "doc.fill.badge.ellipsis")
        case .files_absolute_path_read_only:
            return (
                Text("Global Files Read-Only", bundle: .module),
                Text("Enables read-only access to the specified files or directories at specified absolute paths.", bundle: .module),
                "doc.badge.gearshape")
        case .files_absolute_path_read_write:
            return (
                Text("Global Files Read-Write", bundle: .module),
                Text("Enables read/write access to the specified files or directories at specified absolute paths.", bundle: .module),
                "doc.badge.gearshape.fill")
        case .apple_events:
            return (
                Text("Apple Events", bundle: .module),
                Text("Enables sending of Apple events to one or more destination apps.", bundle: .module),
                "scroll.fill")
        case .audio_unit_host:
            return (
                Text("Audio Unit Host", bundle: .module),
                Text("Enables hosting of audio components that are not designated as sandbox-safe.", bundle: .module),
                "waveform")
        case .iokit_user_client_class:
            return (
                Text("IOKit User Client", bundle: .module),
                Text("Ability to specify additional IOUserClient subclasses.", bundle: .module),
                "waveform.badge.exclamationmark")
        case .mach_lookup_global_name:
            return (
                Text("MACH Global Name Lookup", bundle: .module),
                Text("Lookup global Mach services.", bundle: .module),
                "list.bullet.rectangle")
        case .mach_register_global_name:
            return (
                Text("Mach Global Name Register", bundle: .module),
                Text("Register global Mach services.", bundle: .module),
                "list.bullet.rectangle.fill")
        case .shared_preference_read_only:
            return (
                Text("Shared Preferences Read-Only", bundle: .module),
                Text("Read shared preferences.", bundle: .module),
                "list.triangle")
        case .shared_preference_read_write:
            return (
                Text("Shared Preferences Read-Write", bundle: .module),
                Text("Read and write shared preferences.", bundle: .module),
                "list.star")
        }
    }
}
