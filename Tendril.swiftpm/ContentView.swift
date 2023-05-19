import SwiftUI
import SwiftChatGPT

struct ContentView: View {
    private let chatGPT = ChatGPT(key: "")
    
    @Binding var document: TextDocument
    
    @State private var settings: Settings = Settings()
    @State private var showingSettings: Bool = false
    
    var body: some View {
        VStack {
            DocumentView(text: $document.text)
            HStack {
                Button("settings", action: {
                    self.showingSettings = true
                })
                .buttonStyle(.bordered)
                Button("append uneaten", action: {
                    GPTify()                    
                })
                .buttonStyle(.bordered)
            }
            .onAppear {
                //            self.chatGPT.key = apiKey
                self.chatGPT.model = settings.isGPT4 ? "gpt-4" : "gpt-3.5-turbo"
                self.chatGPT.temperature = Float(settings.temperature)
                self.chatGPT.systemMessage = settings.systemMessage
            }
//            .onChange(of: apiKey, perform: { newValue in
//                //            self.chatGPT.key = newValue
//            })
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
//                NavigationView {
                    SettingsView(settings: $settings)
                        .padding()
//                }
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button(action: {
                                    showingSettings = false
                                }) {
                                    Text("Done").fontWeight(.semibold)
                                }
                            }
                        }
            }
        }
    }
    
    func GPTify() {
        let uneaten = self.document.text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
        DispatchQueue.main.async {
            do {
                Task {
                    switch await self.chatGPT.streamChatText(query: uneaten) {
                    case .failure(let error):
                        self.document.text.append("\nCommunication Error:\n\(error.description)")
                        return
                    case .success(let results):
                        for try await result in results {
                            if let result {
                                self.document.text.append(result)
                            }
                        }
                        self.document.text.append("\n")
                    }
                }
            }
        }
    }
}
