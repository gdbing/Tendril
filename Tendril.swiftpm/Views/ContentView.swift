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
        self.documentURLs = files.filter( { !$0.hasDirectoryPath })
        self.selectedDocumentURL = nil
    }
    
    func newDocument(name: String = "Untitled", suffix: String = "txt") -> URL? {
        guard let projectURL else { return  nil }
        let untitledDotTxt = projectURL.appendingPathComponent("\(name).\(suffix)")
        if !self.documentURLs.contains(where: { $0 == untitledDotTxt}),
           !FileManager.default.fileExists(atPath: untitledDotTxt.absoluteString) {
            try? "".write(to: untitledDotTxt, atomically: false, encoding: .utf8)
            return untitledDotTxt
        } else {
            for ix in 1...255 {
                let untitledDotTxtIx = projectURL.appendingPathComponent("\(name) \(ix).\(suffix)")
                if !self.documentURLs.contains(where: { $0 == untitledDotTxtIx}),
                   !FileManager.default.fileExists(atPath: untitledDotTxtIx.absoluteString) {
                    try? "".write(to: untitledDotTxtIx, atomically: false, encoding: .utf8)
                    return untitledDotTxtIx
                }
            }
        }
        return nil
    } 
    
    var body: some View {
        NavigationSplitView(sidebar: {
            ProjectView(projectURL: $projectURL, documentURLs: $documentURLs, selectedDocumentURL: $selectedDocumentURL)
                .toolbar {
                    if self.projectURL != nil {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {
                                let newDoc = self.newDocument()
                                self.selectedDocumentURL = newDoc
                                if let newDoc {
                                    self.documentURLs.append(newDoc)
                                }
                            }, label: {
                                Image(systemName: "square.and.pencil")
                            }).keyboardShortcut("n", modifiers: [.command])
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            self.showImporter = true
                        }, label: {
                            Image(systemName: "folder")
                        }).keyboardShortcut("o", modifiers: [.command]) 
                    }
                }
        }, detail: {
            ZStack {
                DocumentView(documentURL: $selectedDocumentURL, gpt: gpt)
                if let selectedDocumentURL {
                    Color.clear
                        .navigationTitle($selectedName)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationDocument(selectedDocumentURL)
                }
            }
            // TODO: this is triggering a rename attempt every time, because it changes 
            //       selectedName. the navigationTitle rename functionality is really
            //       meant to be used with a view dedicated to one model object. Should
            //       I refactor to hew closer to the NavigationLink pattern? And init a
            //       new DocumentView for each Document? probably! 
            .onChange(of: selectedDocumentURL) { newURL in
                self.selectedName = newURL?.lastPathComponent ?? ""
            }
            .onChange(of: selectedName) { newName in
                if let selectedDocumentURL,
                   newName != selectedDocumentURL.lastPathComponent,
                   let newURL = selectedDocumentURL.renameFile(name: newName),
                   let ix = self.documentURLs.firstIndex(of: selectedDocumentURL) {
                    self.documentURLs.replaceSubrange(ix...ix, with: [newURL])
                    self.selectedDocumentURL = newURL
                    print("rename")
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
//                ToolbarItem(placement: .automatic) {
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
            self.gpt.chatGPT.model = settings.isGPT4 ? "gpt-4" : "gpt-3.5-turbo-0613"
            self.gpt.chatGPT.temperature = Float(settings.temperature)
            self.gpt.chatGPT.systemMessage = settings.systemMessage
        }
        .onChange(of: settings.apiKey, perform: { newValue in
            self.gpt.chatGPT.key = newValue
        })
        .onChange(of: settings.isGPT4, perform: { newValue in
            self.gpt.chatGPT.model = newValue ? "gpt-4" : "gpt-3.5-turbo-0613"
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
