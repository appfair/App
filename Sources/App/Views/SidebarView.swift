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
import FairKit
import Foundation

struct AddSourceItem : Identifiable {
    var id: String { addSource }

    var addSource: String

    var addSourceItemValidationError: Error?
}

struct SidebarView: View {
    @EnvironmentObject var fairManager: FairManager
    @Binding var selection: AppInfo.ID?
    @Binding var scrollToSelection: Bool
    @Binding var sourceSelection: SourceSelection?
    @Binding var displayMode: TriptychOrient
    @Binding var searchText: String
    @Binding var addSourceItem: AddSourceItem?

    var body: some View {
        let _ = debuggingViewChanges()
        VStack(spacing: 0) {
            listBody
            Divider()
            bottomBar
        }
//        .onAppear {
//            // when we first appear select the initial element
//            if let source = fairManager.appSources.first, source != self.sourceSelection?.source {
//                self.sourceSelection = .init(source: source, section: .top)
//            }
//        }
    }

    var listBody: some View {
        List {
            ForEach(fairManager.appSources, id: \.self, content: appSidebarSection(for:))

            // categories section
            // TODO: merge homebrew and fairapps into single category
            if fairManager.homeBrewInv?.enableHomebrew == true {
                categoriesSection()
            }
        }
        //.symbolVariant(.none)
        .symbolRenderingMode(.hierarchical)
        //.symbolVariant(.circle) // note that these can be stacked
        //.symbolVariant(.fill)
        //.symbolRenderingMode(.multicolor)
        .listStyle(.automatic)
        //        .toolbar(id: "SidebarView") {
        //            tool(source: .fairapps, .top)
        //            tool(source: .fairapps, .recent)
        //            tool(source: .fairapps, .sponsorable)
        //            tool(source: .fairapps, .updated)
        //            tool(source: .fairapps, .installed)
        //        }
    }

    @State private var removeSourceShowing: Bool = false
    @State private var removeSource: AppSource? = nil

    @ViewBuilder var bottomBar: some View {
        HStack {
            // placeholder no-op button to keep the toolbar height consistent
            FairSymbol.link_circle
                .labelStyle(.iconOnly)
                .button {
                    dbg("help button")
                }
                .buttonStyle(.borderless)
                .hidden()

            Spacer()
            
            if fairManager.enableUserSources {
                Text("Add Catalog", bundle: .module, comment: "button at the bottom of sidebar for adding a new catalog")
                    .label(image: FairSymbol.plus)
                    .labelStyle(.iconOnly)
                    .button {
                        dbg("plus button")
                        //resetNewAppSource()
                        self.addSourceItem = AddSourceItem(addSource: "https://") // setting addSourceItem triggers the source URL sheet to display
                    }
                    .buttonStyle(.borderless)
                    .keyboardShortcut("N")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(4)
        .confirmationDialog(Text("Remove Source", bundle: .module, comment: "confirmation dialog title when removing a source from the user sources"), isPresented: $removeSourceShowing, actions: {
            Text("Remove", bundle: .module, comment: "delete button confirmation dialog delete button text").button {
                // there's a SwiftUI bug here: if you cancel the dialog and then try to re-delete the same catalog, the dialog won't appear; but if you try it delete another catalog and then go back to deleting this catalog, it will work!
                if let source = removeSource {
                    removeAppSource(source)
                }
                self.removeSource = nil
                self.removeSourceShowing = false
            }
        }, message: {
            Text("This will remove the source from your list of available app sources. Any apps that have been installed from this source will remain unaffected. This operation cannot be undone.", bundle: .module, comment: "confirmation dialog message text when removing an app source from the sidebar")
        })
    }

//    func resetNewAppSource() {
//        if UXPasteboard.general.hasURLs, let url = UXPasteboard.general.urls?.first {
//            if let validURL = isValidSourceURL(url.absoluteString) {
//                // FIXME: prefill only seems to work *after* the first time the prompt is shown
//                self.addSourceItem = AddSourceItem(addSource: validURL.absoluteString)
//                return
//            }
//        }
//
//        // otherwise, reset without triggering changes
//        if let src = self.addSourceItem, !src.addSource.isEmpty {
//            self.addSourceItem?.addSource = ""
//        }
//    }

    func removeAppSource(_ source: AppSource) {
        dbg("removing source:", source)
        fairManager.removeInventory(for: source, persist: true)
    }

    struct SectionHeader : View {
        let label: Label<Text, Image>
        @Binding var updating: Bool
        let canRemove: Bool
        @State var hovering = false
        let removeAction: () -> ()

        var body: some View {
            ZStack(alignment: .leading) {
                label.labelStyle(.titleOnly).frame(alignment: .leading)
                HStack {
                    Spacer(minLength: 0)
                    if canRemove && hovering {
                        Text("Remove Catalog", bundle: .module, comment: "sidebar button to remove a catalog")
                            .label(image: FairSymbol.minus_circle)
                            .labelStyle(.iconOnly)
                            .contentShape(Circle())
                            .button(action: removeAction)
                            .buttonStyle(.borderless)
                            .help(Text("Removes this catalog from the list of available catalogs. This operaiton cannot be undone.", bundle: .module, comment: "help text for sidebar button to remove catalog"))
                    }

                    if updating {
                        ProgressView()
                            .controlSize(.mini)
                            .padding(.trailing, 18)
                    }
                }
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                self.hovering = hovering
            }
        }
    }

    func appSidebarSection(source: AppSource, inventory inv: AppInventory) -> some View {
        Section {
            ForEach(enumerated: inv.supportedSidebars) { itemIndex, item in
                sidebarItem(SourceSelection(source: inv.source, section: item))
            }
        } header: {
            SectionHeader(label: inv.label(for: source), updating: .constant(inv.updateInProgress != 0), canRemove: fairManager.userSources.contains(inv.sourceURL.absoluteString), removeAction: {
                dbg("setting removeSource:", source)
                self.removeSource = source
                self.removeSourceShowing = true
            })
        }
        .symbolVariant(.fill)
    }

    @ViewBuilder func appSidebarSection(for source: AppSource) -> some View {
        if let inv = fairManager.inventory(for: source) {
            appSidebarSection(source: source, inventory: inv)
        }
    }

    func categoriesSection() -> some View {
        Section {
            ForEach(AppCategoryType.allCases) { cat in
                // TODO: merge apps from all catalogs, not just homebrew
                sidebarItem(SourceSelection(source: .homebrew, section: .category(cat)))
            }
            .symbolVariant(.fill)
        } header: {
            Label(title: { Text("Categories", bundle: .module, comment: "sidebar section header title for homebrew app categories") }, icon: { FairSymbol.list_dash.image })
                .labelStyle(.titleOnly)
        }
    }

    @ViewBuilder func sidebarItem(_ selection: SourceSelection, hideEmpty: Bool = true) -> some View {
        if let inv = fairManager.inventory(for: selection.source) {
            let badgeCountText = inv.badgeCount(for: selection.section)

            if hideEmpty == false || badgeCountText != nil {
                let info = fairManager.sourceInfo(for: selection)
                let label = info?.tintedLabel(monochrome: false)
                NavigationLink(tag: selection, selection: $sourceSelection, destination: {
                    navigationDestinationView(item: selection)
                        .navigationTitle(info?.fullTitle ?? Text(verbatim: ""))
                }, label: {
                    label.badge(inv.catalogUpdated == nil || inv.updateInProgress > 0 ? nil : badgeCountText)
                })
            }
        }
    }

    @ViewBuilder func navigationDestinationView(item: SourceSelection) -> some View {
        switch displayMode {
        case .list:
            AppsListView(source: item.source, sourceSelection: sourceSelection, selection: $selection, scrollToSelection: $scrollToSelection, searchTextSource: $searchText)
#if os(macOS)
        case .table:
            AppTableDetailSplitView(source: item.source, selection: $selection, searchText: $searchText, sourceSelection: $sourceSelection)
#endif
        }
    }

    func tool(source: AppSource, _ section: SidebarSection) -> some CustomizableToolbarContent {
        ToolbarItem(id: section.id, placement: .automatic, showsByDefault: false) {
            Button(action: {
                selectSection(section)
            }, label: {
                //                item.label(for: source, monochrome: false)
                //.symbolVariant(.fill)
                //                    .symbolRenderingMode(.multicolor)
            })
        }
    }

    func selectSection(_ item: SidebarSection) {
        dbg("selected:", item.id)
    }
}
