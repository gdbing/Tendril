import SwiftUI
import SwiftChatGPT

struct ContentView: View {
    let chatGPT: ChatGPT
    @Binding var document: TextDocument
    
    @StateObject private var settings: Settings = Settings()
    @State private var showingSettings: Bool = false

    let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
    let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

    var body: some View {
        DocumentView(text: $document.text)
            .onAppear {
                self.chatGPT.key = settings.apiKey
                self.chatGPT.model = settings.isGPT4 ? "gpt-4" : "gpt-3.5-turbo"
                self.chatGPT.temperature = Float(settings.temperature)
                self.chatGPT.systemMessage = settings.systemMessage
            }
            .onChange(of: settings.apiKey, perform: { newValue in
                self.chatGPT.key = newValue
            })
            .onChange(of: settings.isGPT4, perform: { newValue in
                self.chatGPT.model = newValue ? "gpt-4" : "gpt-3.5-turbo"
            })
            .onChange(of: settings.temperature, perform: { newValue in
                self.chatGPT.temperature = Float(newValue)
            })
            .onChange(of: settings.systemMessage, perform: { newValue in
                self.chatGPT.systemMessage = newValue
            })
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settings)
                    .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.showingSettings = true
                    }, label: {
                        Image(systemName: "gear")
                    })
                    .keyboardShortcut(",", modifiers: [.command]) 
                }
//                ToolbarItem(placement: .primaryAction) {
//                    Button(action: {
//                        GPTify()
//                    }, label: {
//                        Image(systemName: "bubble.left")
//                    })
//                    .keyboardShortcut(.return, modifiers: [.command]) 
//                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let doc = TextDocument(text: "hello world")
        let cgpt = ChatGPT(key: "")
        NavigationStack {
            ContentView(chatGPT: cgpt, document: .constant(doc))
        }
    }
}
