import Foundation
import Arweave
import KeychainAccess

var keychain: Keychain? = {
    guard let appIdPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as? String else { return nil }
    return Keychain(service: "com.reikam.arweave-wallets", accessGroup: "\(appIdPrefix)com.reikam.shared")
}()

private var allWallets: [Wallet] {
    let data = keychain?.allKeys().compactMap { try? keychain?.getData($0) } ?? []

    return data.compactMap {
        try? JSONDecoder().decode(Wallet.self, from: $0)
    }.sorted(by: <)
}

extension Wallet: Identifiable {
    public var id: String { String(describing: address) }
}

class WalletPersistence: ObservableObject {
    @Published private(set) var wallets: [Wallet]
    
    init() {
        wallets = allWallets
    }
    
    func add(_ wallet: Wallet) throws {
        let encoded = try JSONEncoder().encode(wallet)
        try keychain?.set(encoded, key: wallet.id)
        wallets = allWallets
    }
    
    func remove(_ wallet: Wallet) throws {
        try keychain?.remove(wallet.id)
        wallets = allWallets
    }
}
