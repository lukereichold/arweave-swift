import Foundation
import WebKit

final class DataViewController: UIViewController {
    
    var txId: String?
    @IBOutlet weak var webView: WKWebView!

    var data: Data? {
        didSet {
            refreshData()
        }
    }

    private func refreshData() {
        title = txId
        loadViewIfNeeded()
        let file = txId ?? "file"
        let filename = getDocumentsDirectory().appendingPathComponent("\(file).pdf")
        try? data?.write(to: filename)
        let request = URLRequest(url: filename)
        webView.load(request)
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

}
