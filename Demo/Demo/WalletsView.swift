import SwiftUI

struct WalletsView: View {
    var body: some View {
        NavigationView {
            Text("Wallets")
                .navigationTitle("Welcome")
                .toolbar {
                    Button("Help") {
                        print("Help tapped!")
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WalletsView()
    }
}
