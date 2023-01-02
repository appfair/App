import FairApp
import JXPod
import JXKit
import JXBridge

struct DataWrapperNavigator<Wrapper : DataWrapper> : View where Wrapper.Path : Hashable {
//    let wrapper: Wrapper
//    @Binding var folder: Wrapper.Path?
//    @State var selection: Wrapper.Path? = nil

    var body: some View {
//        OutlineGroup(wrapper.nodes(at: folder).map(nodeWrapper), id: \.self, children: \.children) { path in
//            Text("\(folder)")
//        }

        Text("DataWrapperNavigator")
    }

//    func nodeWrapper(for path: Wrapper.Path) -> NodeWrapper {
//        NodeWrapper(path: path, wrapper: wrapper)
//    }
//
//    class NodeWrapper : Hashable {
//        let path: Wrapper.Path
//        let wrapper: Wrapper
//
//        init(path: Wrapper.Path, wrapper: Wrapper) {
//            self.path = path
//            self.wrapper = wrapper
//        }
//
//        var children: [NodeWrapper]? {
//            do {
//                return try wrapper.nodes(at: path).map({ NodeWrapper(path: $0, wrapper: wrapper) })
//            } catch {
//                dbg("error getting node children for", path, error)
//                return nil
//            }
//        }
//    }
}

