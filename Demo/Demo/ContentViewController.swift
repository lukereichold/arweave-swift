import UIKit
import Arweave
import KeychainAccess

final class ContentViewController: UITableViewController {

    lazy var keychain: Keychain? = {
        guard let appIdPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as? String else { return nil }
        return Keychain(service: "com.reikam.arweave-wallets", accessGroup: "\(appIdPrefix)com.reikam.shared")
    }()

    var wallets: [String] {
        (keychain?.allKeys().sorted()) ?? []
    }

    var lastTx: TransactionId?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Transactions"
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (lastTx == nil) ? 0 : 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TxCell", for: indexPath)
        cell.textLabel?.text = "\(lastTx!)"
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Transaction.data(for: lastTx!) { [weak self] result in
            guard let dataString = try? result.get() else { return }
            let data = Data(base64URLEncoded: dataString)
            let dataVC = self?.storyboard?.instantiateViewController(withIdentifier: "DataViewController") as! DataViewController
            dataVC.txId = self?.lastTx!
            dataVC.data = data
            self?.navigationController?.pushViewController(dataVC, animated: true)
        }
    }

    @objc private func refresh() {
        guard let firstWalletKey = wallets.first else { return }
        guard let walletData = try! keychain?.getData(firstWalletKey) else { return }
        guard let wallet = Wallet(jwkFileData: walletData) else { return }

        wallet.lastTransactionId { [weak self] result in
            self?.lastTx = try? result.get()
            self?.tableView.reloadData()
            self?.refreshControl?.endRefreshing()
        }
    }

}
