import SwiftUI

extension ContentView { 
    struct ProjectView: View {
        @StateObject var viewModel: ViewModel
        
        var body: some View {
            VStack {
                List(viewModel.documents, id: \.self, selection: $viewModel.selectedDocument) { document in
                    Text(document.name)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                viewModel.delete(document: document)
                            }
                            Button {
                                viewModel.archive(document: document)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }

                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                viewModel.delete(document:document)
                            }
                            Button {
                                viewModel.archive(document: document)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }
                }
                .navigationTitle(viewModel.projectName ?? "")
                .navigationBarTitleDisplayMode(.inline)

//                List(viewModel.archivedDocuments, id: \.self, selection: $viewModel.selectedDocument) { document in
//                    Text(document.name)
//                }
            }
        }
    }
}
