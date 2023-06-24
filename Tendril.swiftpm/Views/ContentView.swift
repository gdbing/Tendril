import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    @EnvironmentObject private var settings: Settings

    @State private var showingSettings: Bool = false
    @State private var showImporter = false
    
    var body: some View {
        NavigationSplitView {
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
        } detail: {
            ZStack {
                DocumentView(document: $viewModel.selectedDocument)
                if let selectedDocument = viewModel.selectedDocument {
                    Color.clear
                        .navigationTitle(Binding(get: { selectedDocument.name }, 
                                                 set: { viewModel.rename(document: selectedDocument, newName: $0) } ))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarRole(.editor)
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
            }
        }
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
