import SwiftUI
import Arweave

struct WalletsView: View {
    @State private var showingAlert = false
    @State private var showingFilePicker = false
    @ObservedObject var model: WalletPersistence
    
    var body: some View {
        NavigationView {
            listView
            .navigationTitle("Wallets")
            .toolbar {
                Button(action: {
                    showingFilePicker.toggle()
                }) {
                    Image(systemName: "doc.fill.badge.plus")
                        .font(.title2)
                }
                .accessibilityLabel("Import wallet")
                .foregroundStyle(.orange, .tint)
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker() { data in
                do {
                    let wallet = try Wallet(jwkFileData: data)
                    try model.add(wallet)
                } catch {
                    showingAlert = true
                }
            }
        }
        .alert("Unable to create wallet for the specified keyfile.",
               isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
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
