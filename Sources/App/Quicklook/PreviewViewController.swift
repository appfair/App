import FairApp

#if canImport(Quartz)
import Quartz
#endif
#if canImport(QuickLook)
import QuickLook
#endif

class PreviewViewController: UXViewController, QLPreviewingController {
    override func loadView() {
        print("### LottieQuickLook: loading preview controller view")
        self.view = UXHostingView(rootView: Group {
            Color.red
        })
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        print("### LottieQuickLook: preparePreviewOfFile", url)
        handler(nil)
    }
}
