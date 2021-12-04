//
//  PreviewViewController.swift
//  Lottie Motion Quicklook
//
//  Created by Marc Prud'hommeaux on 12/4/21.
//

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

    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        print("### LottieQuickLook: preparePreviewOfFile", url)

        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        
        handler(nil)
    }
}
