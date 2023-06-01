import SwiftUI
import SwiftChatGPT

@main
struct Tendril: App {
    @State var document: TextDocument = TextDocument()
    private let chatGPT = ChatGPT(key: "")
    @State private var text = ""

    var body: some Scene {
//        WindowGroup {
//            NavigationStack {
//                ContentView(chatGPT: chatGPT, document: $document)
//            }
//        }
        DocumentGroup(newDocument: TextDocument()) { file in
            ContentView(chatGPT: chatGPT, document: file.$document)
        }
    }
}
