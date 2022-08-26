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

#if os(macOS)
/// A container for a Table
@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
protocol ItemTableView : TableRowContent {
}


@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ItemTableView {

    func dateColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, Date?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: optionalDateComparator) { item in
            Text(verbatim: item[keyPath: path]?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
            //Text(verbatim: item[keyPath: path].localizedDate(dateStyle: .short, timeStyle: .short))
        }
    }

    func numColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableRowValue, T>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: NumericComparator()) { item in
            Text(verbatim: item[keyPath: path].localizedNumber())
        }
    }

    func boolColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, Bool>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Toggle<EmptyView>, Text> {
        TableColumn(key, value: path, comparator: BoolComparator()) { item in
            Toggle(isOn: .constant(item[keyPath: path])) { EmptyView () }
        }
    }

    /// Non-optional string column
    func strColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, String>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: .localizedStandard) { item in
            Text(verbatim: item[keyPath: path])
        }
    }

    func ostrColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, String?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: optionalStringComparator) { item in
            Text(verbatim: item[keyPath: path] ?? "")
        }
    }

    func oversionColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, AppVersion?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, VersionLabel, Text> {
        // TODO: we might want to disallow sorting on versions since it doesn't make sense to compare the versions of two different apps, and we want to discourage version inflation as a mechanism for rank boosting
        TableColumn(key, value: path, comparator: optionalComparator(AppVersion.min)) { item in
            VersionLabel(version: item[keyPath: path])
        }
    }

    func onumColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableRowValue, T?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, AlignedText, Text> {
        TableColumn(key, value: path, comparator: optionalComparator(0)) { item in
            AlignedText(text: Text(verbatim: item[keyPath: path]?.localizedNumber() ?? ""), alignment: .trailing)
        }
    }
}

struct AlignedText : Equatable, View {
    let text: Text
    let alignment: TextAlignment

    var body: some View {
        text.multilineTextAlignment(alignment)
    }
}

/// The label that renders a version of an app
struct VersionLabel : Equatable, View {
    let version: AppVersion?

    var body: some View {
        Text(verbatim: version?.versionStringExtended ?? "-")
            .multilineTextAlignment(.trailing)
    }
}


#if !os(Linux) // unavailable on Linux

extension SortComparator {
    fileprivate func reorder(_ result: ComparisonResult) -> ComparisonResult {
        switch (order, result) {
        case (_, .orderedSame): return .orderedSame
        case (.forward, .orderedAscending): return .orderedAscending
        case (.reverse, .orderedAscending): return .orderedDescending
        case (.forward, .orderedDescending): return .orderedDescending
        case (.reverse, .orderedDescending): return .orderedAscending
        }
    }
}

/// A ``SortComparator`` with booleans values.
public struct BoolComparator : SortComparator {
    public var order: SortOrder = SortOrder.forward

    public init(order: SortOrder = SortOrder.forward) {
        self.order = order
    }

    public func compare(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
        switch (lhs, rhs) {
        case (true, true): return reorder(.orderedSame)
        case (false, false): return reorder(.orderedSame)
        case (true, false): return reorder(.orderedAscending)
        case (false, true): return reorder(.orderedAscending)
        }
    }
}


/// A ``SortComparator`` with optional values.
public struct OptionalSortCompatator<T: Comparable & Hashable> : SortComparator {
    public var order: SortOrder = SortOrder.forward

    public let lhsDefault: T
    public let rhsDefault: T

    public init(order: SortOrder = SortOrder.forward, lhsDefault: T, rhsDefault: T) {
        self.order = order
        self.lhsDefault = lhsDefault
        self.rhsDefault = rhsDefault
    }

    public func compare(_ lhs: T?, _ rhs: T?) -> ComparisonResult {
        lhs ?? lhsDefault < rhs ?? rhsDefault ? reorder(.orderedAscending)
        : lhs ?? lhsDefault > rhs ?? rhsDefault ? reorder(.orderedDescending)
        : .orderedSame
    }
}

let optionalDateComparator = OptionalSortCompatator(lhsDefault: Date.distantPast, rhsDefault: Date.distantFuture)

let optionalStringComparator = OptionalSortCompatator(lhsDefault: "", rhsDefault: "")

func optionalComparator<T: Hashable & Comparable>(_ value: T) -> OptionalSortCompatator<T> {
    OptionalSortCompatator(lhsDefault: value, rhsDefault: value)
}

#endif // !os(Linux)

struct URLComparator : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: URL?, _ rhs: URL?) -> ComparisonResult {
        reorder((lhs?.absoluteString ?? "").compare(rhs?.absoluteString ?? ""))
    }
}

struct NumericComparator<N: Numeric & Comparable> : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: N, _ rhs: N) -> ComparisonResult {
        lhs < rhs ? reorder(.orderedAscending) : lhs > rhs ? reorder(.orderedDescending) : .orderedSame
    }
}
#endif

