import FairApp

#if canImport(Quartz)
import Quartz
#endif
#if canImport(QuickLook)
import QuickLook
#endif

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        print("### LottieQuickLook: providePreview request", request)

        //You can create a QLPreviewReply in several ways, depending on the format of the data you want to return.
        //To return Data of a supported content type:
        
        let contentType = UTType.plainText // replace with your data type
        
        let reply = QLPreviewReply.init(dataOfContentType: contentType, contentSize: CGSize.init(width: 800, height: 800)) { (replyToUpdate : QLPreviewReply) in

            let data = Data("Hello world".utf8)
            
            //setting the stringEncoding for text and html data is optional and defaults to String.Encoding.utf8
            replyToUpdate.stringEncoding = .utf8
            
            //initialize your data here
            
            return data
        }
                
        return reply
    }
}
