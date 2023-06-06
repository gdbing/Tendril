import SwiftUI

@main
struct Tendril: App {
    @State var document: TextDocument = TextDocument()
    @State var isGPTWriting: Bool = false
    
    var body: some Scene {
//        WindowGroup {
//            NavigationStack {
//                ContentView(document: $document, isWriting: $isGPTWriting)
//            }
//        }
        DocumentGroup(newDocument: TextDocument()) { file in
            ContentView(document: file.$document, isWriting: $isGPTWriting)
        }
    }
}
