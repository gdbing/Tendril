import SwiftUI
import SwiftChatGPT

struct ContentView: View {
    @Binding var document: TextDocument
    let chatGPT: ChatGPT = ChatGPT(key: "")
    @State var gptifier: GPTifier?
//    @State var isGPTWriting: Bool = false
//    @State var gptIfy: ((ChatGPT) -> Void)? = nil
        
    @EnvironmentObject private var settings: Settings
    @State private var showingSettings: Bool = false

    var body: some View {
//        GeometryReader { geometry in
        DocumentView(text: $document.text, gpt: $gptifier)
                .onAppear {
                    self.chatGPT.key = settings.apiKey
                    self.chatGPT.model = settings.isGPT4 ? "gpt-4" : "gpt-3.5-turbo"
                    self.chatGPT.temperature = Float(settings.temperature)
                    self.chatGPT.systemMessage = settings.systemMessage
//                    self.documentView.updateInsets(geometry.size.width)
                }
//                .onChange(of: geometry.size, perform: { size in
//                    self.documentView.updateInsets(size.width)
//                })
//        }
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
//                    .environmentObject(settings)
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
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        if let gpt = self.gptifier {
                            gpt.GPTify(chatGPT: self.chatGPT)                            
                        }
                    }, label: {
                        Image(systemName: "bubble.left.fill")
                    })
                    .keyboardShortcut(.return, modifiers: [.command]) 
//                    .disabled(gptifier?.isWriting)
                }
            }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        let doc = TextDocument(text: "hello world")
//        NavigationStack {
//            ContentView(document: .constant(doc), isWriting: .constant(false))
//        }
//    }
//}
