import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    @EnvironmentObject private var settings: Settings

    @State private var showingSettings: Bool = false
    @State private var showingImporter = false
    @State private var showingTags = false
    
    var body: some View {
        NavigationSplitView {
            ProjectView(viewModel: viewModel)
                .toolbar {
                    if viewModel.projectName != nil {
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
                            self.showingImporter = true
                        }, label: {
                            Image(systemName: "folder")
                        }).keyboardShortcut("o", modifiers: [.command]) 
                    }
                }
        } detail: {
            ZStack {
                DocumentView(document: $viewModel.selectedDocument)
                
                if self.showingTags {
                    VStack {
                        TagView()
                        Button(action: {
                            self.showingTags.toggle()
                        }) {
                            Text("Close")
                        }
                    }
                    .background(Color(UIColor.systemBackground))
                    .transition(.move(edge: self.showingTags ? .bottom : .top))
                    .animation(Animation.easeInOut(duration: 0.3))
                    //https://stackoverflow.com/questions/63223542/swiftui-animation-slide-in-and-out#63223600
                }
                
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
                if viewModel.selectedDocument != nil {
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            self.showingTags = true
                        }, label: {
                            Image(systemName: "tag")
                        })
                        .keyboardShortcut("t", modifiers: [.command])
                    }
                }
           }
        }
        .fileImporter(
            isPresented: $showingImporter, 
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

struct TagView: View {
    
    var body: some View {
        Text("Tags")
    }
}
