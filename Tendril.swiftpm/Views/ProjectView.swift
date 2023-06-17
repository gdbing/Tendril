import SwiftUI

extension ContentView { 
    struct ProjectView: View {
        @StateObject var viewModel: ViewModel
        
        var body: some View {
            VStack {
                List(viewModel.documentURLs, id: \.self, selection: $viewModel.selectedDocumentURL) { documentURL in
                    Text(documentURL.lastPathComponent)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                viewModel.delete(document: documentURL)
                            }
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                viewModel.delete(document:documentURL)
                            }
                        }
                }
                .navigationTitle(viewModel.projectURL?.lastPathComponent ?? "")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
