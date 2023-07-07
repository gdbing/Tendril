import SwiftUI

extension ContentView { 
    struct ProjectView: View {
        @StateObject var viewModel: ViewModel
        
        var body: some View {
            List(selection: $viewModel.selectedDocument) {
//                Section {
                    ForEach(viewModel.documents, id: \.self) { document in
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
                    Section {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.callout)
                        }
                    } header: {
                        Text("Tags")
                    }
//                }
            }.listStyle(.automatic)
//                .navigationTitle(viewModel.projectName ?? "")
//                .navigationBarTitleDisplayMode(.inline)
            }
    }
}

// MARK: -
// MARK: Preview

//struct ProjectView_Previews: PreviewProvider {
//    let vm = ContentView.ViewModel()
//
//    static var previews: some View {
//        ContentView.ProjectView(viewModel: vm)
//    }
//}
