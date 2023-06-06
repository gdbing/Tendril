import SwiftUI

@main
struct Tendril: App {
    @State var document: TextDocument = TextDocument()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(document: $document)
                    .environmentObject(Settings())
            }
        }
//        DocumentGroup(newDocument: TextDocument()) { file in
//            ContentView(document: file.$document)
//                .environmentObject(Settings())
//        }
    }
}
