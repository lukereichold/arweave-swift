import UIKit
import Social
import KeychainAccess
import Arweave
import MobileCoreServices

class ArchiveViewController: SLComposeServiceViewController {

    lazy var keychain: Keychain? = {
        guard let appIdPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as? String else { return nil }
        return Keychain(service: "com.reikam.arweave-wallets", accessGroup: "\(appIdPrefix)com.reikam.shared")
    }()

    var wallets: [String] {
        (keychain?.allKeys().sorted()) ?? []
    }

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
                
                detach {
                    await self.uploadDataToArweave(data: pdfData)
                }
            }
        }

        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func uploadDataToArweave(data: Data) async {
        guard let firstWalletKey = wallets.first else { return }
        guard let walletData = try! keychain?.getData(firstWalletKey) else { return }
        guard let wallet = Wallet(jwkFileData: walletData) else { return }

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
