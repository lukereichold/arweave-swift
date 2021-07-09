import SwiftUI

struct MainView: View {
    
    let wallets = WalletPersistence()
    
    var body: some View {
        TabView {
            WalletsView(model: wallets)
                .tabItem {
                    Label("Wallets", systemImage: "wallet.pass")
                }
            TransactionsView(model: wallets)
                .tabItem {
                    Label("Transactions", systemImage: "arrowshape.zigzag.right.fill")
                }
        }
        .accentColor(.indigo)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
