import SwiftUI
import SwiftChatGPT

@main
struct Tendril: App {
    @State var document: TextDocument = TextDocument()
    var settings = Settings()
    var gptifier = GPTifier()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(document: $document, gptifier: gptifier)
                    .environmentObject(settings)
            }
        }
            //        DocumentGroup(newDocument: TextDocument()) { file in
            //            ContentView(document: file.$document)
            //                .environmentObject(settings)
            //        }
    }
}
