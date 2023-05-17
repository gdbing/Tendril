import SwiftUI
import SwiftChatGPT
import UniformTypeIdentifiers

struct ContentView: View {
    private let chatGPT = ChatGPT(key: "")
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("systemMessage") private var systemMessage: String = "You are a helpful assistant"
    @AppStorage("temperature") private var temperature: Double = 0.7
    @AppStorage("isGPT4") private var isGPT4: Bool = false

    @State private var text: String = ""
    @State private var document: TextDocument?
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    
    var body: some View {
        VStack {
            DocumentView(text: $text)
            HStack {
                Button("Open") {
                    document = TextDocument(text: self.text)
                    self.isImporting = true
                }
                .buttonStyle(.bordered)
                Button("Save") {
                    self.isExporting = true
                }
                .buttonStyle(.bordered)
                Button("append uneaten", action: {
                    let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
                    DispatchQueue.main.async {
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
                    }
                    
                })
                .buttonStyle(.bordered)
            }
            .onAppear {
                //            self.chatGPT.key = apiKey
                self.chatGPT.model = isGPT4 ? "gpt-4" : "gpt-3.5-turbo"
                self.chatGPT.temperature = Float(temperature)
                self.chatGPT.systemMessage = systemMessage
            }
            .onChange(of: apiKey, perform: { newValue in
                //            self.chatGPT.key = newValue
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
            .fileImporter(
                isPresented: $isImporting, 
                allowedContentTypes: [.plainText]) { result in
                do {
                    let selectedFile: URL = try result.get()
                    if selectedFile.startAccessingSecurityScopedResource() {
                        self.text = selectedFile.absoluteString
                        if let text = String(data: try Data(contentsOf: selectedFile), encoding: .utf8)  {
                            self.text = text
                        }
                        selectedFile.stopAccessingSecurityScopedResource()
                    } else {
                        print("permission to access file \(selectedFile) denied")
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
                .fileExporter(
                    isPresented: $isExporting,
                    document: document,
                    contentType: .plainText,
                    defaultFilename: "Tendril"
                ) { result in
                    if case .success = result {
                        self.document = nil
                    } else {
                        self.document = nil
                    }
                }
        }
    }
}
