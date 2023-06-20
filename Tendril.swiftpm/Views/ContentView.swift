import SwiftUI
import SwiftChatGPT

struct ContentView: View {
    @StateObject var viewModel = ViewModel()

    @State private var showingSettings: Bool = false
    @State private var showImporter = false
    
    var body: some View {
        NavigationSplitView(sidebar: {
            ProjectView(viewModel: viewModel)
                .toolbar {
                    if viewModel.project != nil {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {
                                viewModel.newDocument()
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
                DocumentView(document: $viewModel.selectedDocument, gpt: viewModel.gpt)
                if let selectedDocument = viewModel.selectedDocument {
                    Color.clear
                        .navigationTitle(Binding(get: { selectedDocument.name }, 
                                                 set: { viewModel.rename(document: selectedDocument, newName: $0) } ))
                        .navigationBarTitleDisplayMode(.inline)
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
                        viewModel.gpt.GPTify()
                    }, label: {
                        Image(systemName: "bubble.left.fill")
                    })
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(viewModel.gpt.isWriting)
                }
//                ToolbarItem(placement: .automatic) {
//                    if let wordCount = viewModel.gpt.wordCount {
//                        Text("\(self.settings.model) | \(String(format: "%.1f°", self.settings.temperature)) | \(wordCount) \(wordCount == 1 ? "word " : "words")")
//                            .monospacedDigit()
//                    }
//                }
            }
        })
        .fileImporter(
            isPresented: $showImporter, 
            allowedContentTypes: [.folder]) { result in
                do {
                    let selectedFolder: URL = try result.get()
                    viewModel.loadProject(url: selectedFolder)
                } catch {
                    print(error.localizedDescription)
                }
            }
    }
}
