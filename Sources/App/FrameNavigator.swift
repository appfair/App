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
import TabularData
import SwiftUI

#warning("TODO: remove and replace with FrameNavigator")

/// An `EnvironmentObject` that is used to coordinate the various
/// components of a `FrameNavigator`.
@available(macOS 12.0, iOS 15.0, *)
public protocol FrameCoordinator : ObservableObject {
    //var frameColumns: [TabularData.ColumnID] { get }
}

//@available(macOS 12.0, iOS 15.0, *)
//private extension TabularData.ColumnID {
//    func createFrameColumn() -> FrameColumn<Never, Never, Never, Never> {
//        //let xxx = SwiftUI.TableColumn(wip("")) { EmptyView() }
//        //return xxx
//        fatalError(wip("FIXME"))
//    }
//}

/// The method by with the frame will be displayed:
///
/// * list (iOS & macOS): the traditional 3-column-list will be used to browse a simplified form of the data
/// * table (macOS-only): a traditional master-detail view will be used to display a table at the top and the content below
public struct FrameDisplayMode: OptionSet, Hashable {
    public let rawValue: Int

    public static let list = Self(rawValue: 1 << 0)
    public static let table = Self(rawValue: 1 << 1)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

///// A `FrameNavigator` is a three-part user interface for browsing
///// a `TabularData.DataFrame`. On iOS and macOS, it is displayed
///// as a traditional three-column app with a sidebar, selectable list view,
///// and a focused detail view. In addition, on macOS, the sidebar can
///// be swapped for a `SwiftUI.TableView` to display additional
///// details about the list and permit advances sorting, selection, and filtering.
//@available(macOS 12.0, iOS 15.0, *)
//public struct FrameNavigator</*Coordinator: ObservableObject, */SidebarView: View, ListView: View, TableView: View, ContentView: View>: View {
//    /*@Environment(\.frameDisplayMode)*/ let displayMode: Set<FrameDisplayMode> = [.table, .list]
//
//    //@EnvironmentObject var coordinator: Coordinator
//    let sidebarView: () -> SidebarView
//    let listView: () -> ListView
//    let tableView: () -> TableView
//    let contentView: () -> ContentView
//
//    internal init(@ViewBuilder sidebarView: @escaping () -> SidebarView, @ViewBuilder listView: @escaping () -> ListView, @ViewBuilder tableView: @escaping () -> TableView, @ViewBuilder contentView: @escaping () -> ContentView) {
//        self.sidebarView = sidebarView
//        self.listView = listView
//        self.tableView = tableView
//        self.contentView = contentView
//    }
//
//    public var body: some View {
//        NavigationView {
//            sidebarView()
//            if displayMode.contains(.list) {
//                listView()
//            }
//            #if os(iOS)
//            contentView()
//            #endif
//            #if os(macOS)
//            HSplitView {
//                if displayMode.contains(.table) {
//                    tableView()
//                }
//                contentView()
//            }
//            #endif
//        }
//    }
//}

@available(macOS 12.0, *)
@available(iOS 15.0, *)
struct FrameColumn<Value, RowValue : Identifiable, Sort : SortComparator, Content : View, Label : View> {
    let column: TabularData.ColumnID<Value>
}


#if os(macOS)
@available(macOS 12.0, *)
@available(iOS, unavailable)
extension FrameColumn {
    func createTableColumn() -> TableColumn<RowValue, Sort, Content, Label> {
//        extension TableColumn where Sort == KeyPathComparator<RowValue>, Label == Text

        fatalError(wip("TODO"))
    }
}

@available(macOS 12.0, *)
extension TableColumnContent {

    // -> TupleTableColumnContent<Self.TableRowValue, C, (Self, Content)>

    /// Appends a column to the end of this column
    func withColumn<C, Content: TableColumnContent>(@TableColumnBuilder<TableRowValue, C> content: () -> Content) -> some TableColumnContent where Content.TableRowValue == TableRowValue, C == Content.TableColumnSortComparator {
//        ForEach([1, 2], id: \.self) { i in
//            self
            TableColumnBuilder<TableRowValue, Content.TableColumnSortComparator>.buildBlock(self, content())
//        }
    }

}


@available(macOS 12.0, *)
extension XOr.Or : TableColumnContent where P : TableColumnContent, Q : TableColumnContent {
    public var tableColumnBody: P {
        p!
    }

    public typealias TableColumnBody = P

//    public typealias TableColumnBody = <#type#>


}

#endif


//@available(macOS 12.0, iOS 15.0, *)
//struct FrameNavigator_Previews: PreviewProvider {
//    static var previews: some View {
//        let people = [
//            Person(givenName: "Juan", familyName: "Chavez"),
//            Person(givenName: "Mei", familyName: "Chen"),
//            Person(givenName: "Tom", familyName: "Clark"),
//            Person(givenName: "Gita", familyName: "Kumar"),
//        ]
//
//        //@State private var selectedPeople = Set<Person.ID>()
//        let selectedPeople = Binding.constant(Set<Person.ID>())
//        //@State private var sortOrder = [KeyPathComparator(\Person.givenName)]
//        let sortOrder = Binding.constant([KeyPathComparator(\Person.givenName)])
//
//        let fn = FrameNavigator {
//            List(people) { person in
//                Text("Person: \(person.fullName)")
//            }
//        } listView: {
//            List(people) { person in
//                Text("Person: \(person.fullName)")
//            }
//        } tableView: {
//            #if os(macOS)
//            Table(people, selection: selectedPeople, sortOrder: sortOrder) {
////                TableColumn("Given Name", value: \.givenName)
////                TableColumn("Family Name", value: \.familyName)
//
//                TableColumn("Given Name", value: \.givenName)
////                    .withColumn {
//                        TableColumn("Family Name", value: \.familyName)
////                    }
//
//            }
//            #endif
//        } contentView: {
//            Text("\(selectedPeople.wrappedValue.count) people selected")
//        }
//
//        return fn
//    }
//
//    struct Person: Identifiable {
//        let id = UUID()
//        let givenName: String
//        let familyName: String
//
//        /// Returns the localized full name of the person
//        var fullName: String {
//            PersonNameComponentsFormatter.localizedString(from: PersonNameComponents(givenName: givenName, familyName: familyName), style: PersonNameComponentsFormatter.Style.medium, options: PersonNameComponentsFormatter.Options())
//        }
//    }
//}
