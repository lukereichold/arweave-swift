import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {
    
    class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
          self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let fileUrl = urls[0]
            do {
                let fileContent = try Data(contentsOf: fileUrl)
                parent.onPick(fileContent)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private let onPick: (Data) -> ()
    
    init(onPick: @escaping (Data) -> Void) {
        self.onPick = onPick
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
