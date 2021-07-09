import SwiftUI
import Arweave

struct TransactionsView: View {
    
    @State private var transactions = [String]()
    @ObservedObject var model: WalletPersistence
    
    var body: some View {
        NavigationView {
            List {
                ForEach(transactions, id: \.self) { tx in
                    Text(tx.description)
                }
            }
            .onAppear {
                async {
                    await loadLastTransaction()
                }
            }
            .refreshable {
                await loadLastTransaction()
            }
            .navigationTitle("Last Transaction")
        }
    }
    
    private func loadLastTransaction() async {
        guard let wallet = model.wallets.first else { return }
        guard let lastTx = try? await wallet.lastTransactionId() else { return }
        transactions = [lastTx]
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView(model: WalletPersistence())
    }
}
