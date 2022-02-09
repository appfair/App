import FairApp

/// The `AppInventory` protocol handles installing and managing apps.
protocol AppInventory {
    // This is where we can define the protocol requriements once Isolated protocol conformances are supported (https://github.com/apple/swift-evolution/blob/main/proposals/0313-actor-isolation-control.md#isolated-protocol-conformances)

    // Static method 'installedPath(for:)' isolated to global actor 'MainActor' can not satisfy corresponding requirement from protocol 'InstallationManager'
    // func arrangedItems(sidebarSelection: SidebarSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo]

    // static func installedPath(for item: AppCatalogItem) -> URL?
}

