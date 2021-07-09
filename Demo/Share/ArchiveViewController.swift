import UIKit
import Social
import Arweave
import MobileCoreServices

class ArchiveViewController: SLComposeServiceViewController {

    let model = WalletPersistence()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = "Archive"
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {

        // Only allow one provider (PDF) for now:
        let attachments = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        let contentType = kUTTypePDF as String
        guard let provider = attachments.first else { return }

        if provider.hasItemConformingToTypeIdentifier(contentType) {
            provider.loadItem(forTypeIdentifier: contentType, options: nil) { [unowned self] (url, error) in
                guard let pdfUrl = url as? URL else { return }
                guard let pdfData = try? Data(contentsOf: pdfUrl) else { return }
                
                async {
                    await self.uploadDataToArweave(data: pdfData)
                }
            }
        }

        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func uploadDataToArweave(data: Data) async {
        guard let wallet = model.wallets.first else { return }

        let tx = Transaction(data: data)
        do {
            let signedTx = try await tx.sign(with: wallet)
            try await signedTx.commit()
        } catch {
            debugPrint(error)
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
