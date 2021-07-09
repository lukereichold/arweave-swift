import SwiftUI
import Arweave

struct TransactionsView: View {
    
    @State private var showingFilePicker = false
    @State private var walletData: Data?
    @ObservedObject var wallets: WalletPersistence
    
    var body: some View {
        NavigationView {
            Text("Transactions!")
            .navigationTitle("Transactions")
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView(wallets: WalletPersistence())
    }
}
