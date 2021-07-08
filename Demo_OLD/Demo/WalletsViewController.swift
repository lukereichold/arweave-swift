import UIKit
import Arweave
import KeychainAccess

final class WalletsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }

    @objc private func addTapped() {
        let importMenu = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        present(importMenu, animated: true)
    }

    lazy var keychain: Keychain? = {
        guard let appIdPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as? String else { return nil }
        return Keychain(service: "com.reikam.arweave-wallets", accessGroup: "\(appIdPrefix)com.reikam.shared")
    }()

    var wallets: [String] {
        (keychain?.allKeys().sorted()) ?? []
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        wallets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WalletCell", for: indexPath)
        cell.textLabel?.text = "\(wallets[indexPath.row])"
        return cell
    }
}

extension WalletsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let keyFileUrl = urls.first else { return }
        guard let keyFileData = try? Data(contentsOf: keyFileUrl) else { return }

        guard let wallet = Wallet(jwkFileData: keyFileData) else { return }

        try! keychain?.set(keyFileData, key: wallet.address.address)
        tableView.reloadData()
    }
}
