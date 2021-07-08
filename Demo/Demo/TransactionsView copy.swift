import SwiftUI
import Arweave

struct TransactionsView: View {
    
    @State private var showingFilePicker = false
    @State private var walletData: Data?
    
//    @StateObject var wallets = WalletPersistence()
    @ObservedObject var wallets: WalletPersistence
    
    func persistWallet() {
        guard let newData = walletData else { return }
        guard let wallet = Wallet(jwkFileData: newData) else { return }
        wallets.add(wallet)
    }
    
    var body: some View {
        NavigationView {
            Text("Wallets")
                .navigationTitle("Wallets")
                .toolbar {
                    Button(action: {
                        print("Button was tapped")
                        showingFilePicker.toggle()
                    }) {
                        Image(systemName: "doc.fill.badge.plus")
                            .font(.title2)
                    }
                    .accessibilityLabel("Import wallet")
                    .foregroundStyle(.orange, .tint)
                }
            
            // Create `InnerView` that can mutate the List
            
        }
        .sheet(isPresented: $showingFilePicker, onDismiss: persistWallet) {
            DocumentPicker(fileContent: self.$walletData)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WalletsView()
    }
}
