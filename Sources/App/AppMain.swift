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

// MARK: DO NOT MODIFY

// This file is validated by the fairground and any changes will cause integration to fail.

/// The `FairContainer` for the current app is the entry point 
/// to the app's initial launch, both in CLI and GUI forms.
///
/// - Note: This source in `AppMain.swift` must not be modified or else integration will fail;
///         App customization should be implemented with extensions in `Container.swift`
@main public enum AppContainer : FairApp.FairContainer {
    public static func main() async throws { try await launch(bundle: Bundle.module) }
}

// MARK: Localization

/// This file contains references to the localized translated Text embedded in the `FairApp` module.
///
/// The App Fair's translation strategy is to keep every translatable string in the `Sources/App/Resources/en.lproj/Localizable.strings` file.
/// This provides a single unit that a translator can work with, rather than having translations scattered throughout multiple app metadata configuration files.
/// At integration time, the `fairtool` will scan and assemble all the localized resources and use them in the various app storefront submission processes.

/// By convention, those strings that are used by the build system will be prefixed with a "_".
///
/// Note that even if you do not use these strings in your app, you must keep these strings defined in your project
/// because the string generation for the storefront relies on the presence of these constants.
public extension Locale {
    /// A translation of the app's keywords from the `Localized.strings` key: `_app-keywords`.
    ///
    /// This string is used both for runtime access to the localized app keywords, as well as part of the storefront metadata that is used to externally represent the app.
    ///
    /// Any changes to this string must be done in the corresponding `Sources/App/Resources/*.lproj/Localizable.strings` file.
    ///
    /// It corresponds to the fastlane key `keywords` https://docs.fastlane.tools/actions/deliver/#localized-metadata
    static let appKeywords = { NSLocalizedString("_app-keywords", bundle: .module, value: "app,fair,free", comment: "the comma-separated keywords (100 characters max), used both at runtime and on the storefront page") }

    /// A translation of the app's name from the `Localized.strings` key: `_app-name`
    ///
    /// Any changes to this string must be done in the corresponding `Sources/App/Resources/*.lproj/Localizable.strings` file.
    ///
    /// This string is used both for runtime access to the localized app name, as well as part of the storefront metadata that is used to externally represent the app.
    ///
    /// It corresponds to the fastlane key `name` https://docs.fastlane.tools/actions/deliver/#localized-metadata
    static let appName = { NSLocalizedString("_app-name", bundle: .module, value: "App Name", comment: "the app name (30 characters max) which should be simple, memorable, and distinctive; used both in the welcome card and on storefront pages") }

    /// A translation of the app's release notes from the `Localized.strings` key: `_app-release-notes`.
    ///
    /// Any changes to this string must be done in the corresponding `Sources/App/Resources/*.lproj/Localizable.strings` file.
    ///
    /// This string is used both for runtime access to the localized app release notes, as well as part of the storefront metadata that is used to externally represent the app.
    ///
    /// It corresponds to the fastlane key `releaseNotes` https://docs.fastlane.tools/actions/deliver/#localized-metadata
    static let appReleaseNotes = { NSLocalizedString("_app-release-notes", bundle: .module, value: """
        This release contains feature enhancements, bug fixes, performance improvements, and much more!
        """, comment: "The release notes for the latest version of the app; used both in the welcome card and on storefront pages") }

    /// A translation of the app's subtitle from the `Localized.strings` key: `_app-subtitle`.
    ///
    /// This string is used both for runtime access to the localized app subtitle, as well as part of the storefront metadata that is used to externally represent the app.
    ///
    /// It corresponds to the fastlane key `subtitle` https://docs.fastlane.tools/actions/deliver/#localized-metadata
    static let appSubtitle = { NSLocalizedString("_app-subtitle", bundle: .module, value: "A free and open App Fair app", comment: "the subtitle of the app (30 characters max) meant summarize your app in a concise phrase that explains the value of your app in greater detail that the name; used both in the welcome card and on storefront pages") }

    /// A translation of the app's summary from the `Localized.strings` key: `_app-summary`.
    ///
    /// This string is used both for runtime access to the localized app summary, as well as part of the storefront metadata that is used to externally represent the app.
    ///
    /// It corresponds to the fastlane key `description` https://docs.fastlane.tools/actions/deliver/#localized-metadata
    static let appSummary = { NSLocalizedString("_app-summary", bundle: .module, value: """
        This is an App Fair app. This text describes in plain language what the application does.

        This summary will be used both in the app's Welcome screen, as well as in the description of the app on the storefront.

        The description should be written with a general audience in mind, using plain language and common terms.
        It will be translated into multiple languages by App Fair translation volunteers.
        """, comment: "the long form summary of the app, used both at runtime and on the storefront page; used both in the welcome card and on storefront pages") }
}


#if canImport(SwiftUI)
extension Text {
    /// Clients should use the localized form of `Text.init` in order to take advantage of the provided `Localizable.strings` localizations.
    @available(*, deprecated, message: "Facilitate translation with: `Text(”My String”, bundle: .module, comment: “description of My String for translators”)`", renamed: "Text.init(_:bundle:comment:)")
    internal init(_ key: LocalizedStringKey) {
        self.init(key, bundle: .module, comment: "no comment")
    }
}
#endif

