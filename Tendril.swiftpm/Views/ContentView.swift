import SwiftUI
import SwiftChatGPT

struct ContentView: View {
    @ObservedObject var gpt: GPTifier
        
    @EnvironmentObject private var settings: Settings
    @State private var showingSettings: Bool = false

    @Binding var projectURL: URL?
    @State var documentURLs: [URL] = []
    @State var selectedDocumentURL: URL? = nil
    @State var selectedName: String = ""
    
    @State var showImporter = false

    init(project: Binding<URL?>, gpt: GPTifier) {
        self.gpt = gpt
        _projectURL = project
        if let projectURL {
            self.loadProject(url: projectURL)
        }
    }
    
    func loadProject(url: URL) {        
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [
                .contentModificationDateKey,
                .creationDateKey,
                .typeIdentifierKey
            ],
            options:.skipsHiddenFiles
        ) else { 
            return 
        }
        self.documentURLs = files
        self.selectedDocumentURL = nil
    }
        
    var body: some View {
        NavigationSplitView(sidebar: {
            ProjectView(projectURL: $projectURL, documentURLs: $documentURLs, selectedDocumentURL: $selectedDocumentURL)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Open...") {
                            self.showImporter = true
                        }
                    }
                }
        }, detail: {
            ZStack {
                DocumentView(documentURL: $selectedDocumentURL, gpt: gpt)
                if let selectedDocumentURL {
                    Color.clear
                        .navigationTitle($selectedName)
                        .navigationBarTitle(selectedDocumentURL.lastPathComponent, displayMode: .inline)
                        .navigationDocument(selectedDocumentURL)
                }
            }
            .onChange(of: selectedName) { newName in
                if let selectedDocumentURL,
                   let newURL = selectedDocumentURL.renameFile(name: newName),
                   let ix = self.documentURLs.firstIndex(of: selectedDocumentURL) {
                    self.documentURLs.replaceSubrange(ix...ix, with: [newURL])
                    self.selectedDocumentURL = newURL
                }
            }     
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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
                        self.gpt.GPTify()
                    }, label: {
                        Image(systemName: "bubble.left.fill")
                    })
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(self.gpt.isWriting)
                }
//                ToolbarItem(placement: .status) {
//                    let words = text.components(separatedBy: .whitespacesAndNewlines)
//                    let filteredWords = words.filter { !$0.isEmpty }
//                    let wordCount = filteredWords.count
//                    Text("\(self.settings.isGPT4 ? "gpt-4" : "gpt-3.5") | \(String(format: "%.1f°", self.settings.temperature)) | \(wordCount) \(wordCount == 1 ? "word " : "words")")
//                        .monospacedDigit()
//                }
            }
        })

        .onAppear {
            self.gpt.chatGPT.key = settings.apiKey
            self.gpt.chatGPT.model = settings.isGPT4 ? "gpt-4" : "gpt-3.5-turbo"
            self.gpt.chatGPT.temperature = Float(settings.temperature)
            self.gpt.chatGPT.systemMessage = settings.systemMessage
        }
        .onChange(of: settings.apiKey, perform: { newValue in
            self.gpt.chatGPT.key = newValue
        })
        .onChange(of: settings.isGPT4, perform: { newValue in
            self.gpt.chatGPT.model = newValue ? "gpt-4" : "gpt-3.5-turbo"
        })
        .onChange(of: settings.temperature, perform: { newValue in
            self.gpt.chatGPT.temperature = Float(newValue)
        })
        .onChange(of: settings.systemMessage, perform: { newValue in
            self.gpt.chatGPT.systemMessage = newValue
        })
        
        .fileImporter(
            isPresented: $showImporter, 
            allowedContentTypes: [.folder]) { result in
                do {
                    let selectedFolder: URL = try result.get()
                    if selectedFolder.startAccessingSecurityScopedResource() {
                        self.projectURL = selectedFolder
                        self.loadProject(url: selectedFolder)                        
                    } 
                } catch {
                    print(error.localizedDescription)
                }
            }
    }
}
