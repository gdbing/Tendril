import SwiftUI
import SwiftChatGPT

struct ContentView: View {
    private let chatGPT = ChatGPT(key: "")
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("systemMessage") private var systemMessage: String = "You are a helpful assistant"
    @AppStorage("temperature") private var temperature: Double = 1.2
    @AppStorage("isGPT4") private var isGPT4: Bool = false

    @State private var text: String = ""
    
    var body: some View {
        VStack {
            DocumentView(text: $text)
            Button("append uneaten", action: {
                let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
                do {
                    Task {
                        switch await self.chatGPT.streamChatText(query: uneaten) {
                        case .failure(let error):
                            self.text.append("\nCommunication Error:\n\(error.description)")
                            return
                        case .success(let results):
                            for try await result in results {
                                if let result {
                                    self.text.append(result)
                                }
                            }
                            self.text.append("\n")
                        }
                    }
                }

            })
            .buttonStyle(.bordered)
        }
        .onAppear {
            self.chatGPT.key = apiKey
            self.chatGPT.model = isGPT4 ? "gpt-4" : "gpt-3.5-turbo"
            self.chatGPT.temperature = Float(temperature)
            self.chatGPT.systemMessage = systemMessage
        }
        .onChange(of: apiKey, perform: { newValue in
            self.chatGPT.key = newValue
        })
        .onChange(of: isGPT4, perform: { newValue in
            self.chatGPT.model = newValue ? "gpt-4" : "gpt-3.5-turbo"
        })
        .onChange(of: temperature, perform: { newValue in
            self.chatGPT.temperature = Float(temperature)
        })
        .onChange(of: systemMessage, perform: { newValue in
            self.chatGPT.systemMessage = systemMessage
        })
    }
}
