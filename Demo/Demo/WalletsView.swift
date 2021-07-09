import SwiftUI
import Arweave

struct WalletsView: View {
    
    @State private var showingFilePicker = false
    @State private var newWallet: Data?
    @ObservedObject var model: WalletPersistence

    func persistWallet() {
        guard let newData = newWallet else { return }
        guard let wallet = try? Wallet(jwkFileData: newData) else { return }
        try? model.add(wallet)
    }
    
    var body: some View {
        NavigationView {
            listView
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
        }
        .sheet(isPresented: $showingFilePicker, onDismiss: persistWallet) {
            DocumentPicker(fileContent: self.$newWallet)
        }
    }
    
    @ViewBuilder
    var listView: some View {
        if model.wallets.isEmpty {
            placeholder
        } else {
            walletList
        }
    }

    var placeholder: some View {
        Text("Import a wallet to get started.").italic()
    }

    var walletList: some View {
        List {
            ForEach(model.wallets, id: \.self) { wallet in
                Text(wallet.id)
            }
            .onDelete(perform: delete)
        }
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let wallet = model.wallets[index]
            try? model.remove(wallet)
        }
    }
}

struct WalletsView_Previews: PreviewProvider {
    static var previews: some View {
        WalletsView(model: WalletPersistence())
    }
}
