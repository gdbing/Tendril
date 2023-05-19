import SwiftUI
import UniformTypeIdentifiers

@main
struct Tendril: App {
    var body: some Scene {
        DocumentGroup(newDocument: TextDocument(text: "")) { file in
            ContentView(document: file.$document)
        }
    }
}
