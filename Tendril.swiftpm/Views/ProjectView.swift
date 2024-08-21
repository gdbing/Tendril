import SwiftUI

extension ContentView { 
    struct ProjectView: View {
        @StateObject var viewModel: ViewModel
        
        @Binding var selectedDocument: Document?
        @State var selectedTag: Document?
        
        var filteredDocuments: [Document] {
            return viewModel.documents
                .sorted(by: {
                    $0.name.lowercased() < $1.name.lowercased()
            })

        }
        
        var body: some View {
            if viewModel.projectName != nil {
                List(selection: $selectedDocument) {
                    ForEach(filteredDocuments, id: \.self) { document in
                        Text(document.name)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Delete", role: .destructive) {
                                    viewModel.delete(document: document)
                                    if document == self.selectedDocument {
                                        self.selectedDocument = nil
                                    }
                                }
                                Button {
                                    viewModel.archive(document: document)
                                    if document == self.selectedDocument {
                                        self.selectedDocument = nil
                                    }
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                            }
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    viewModel.delete(document:document)
                                    if document == self.selectedDocument {
                                        self.selectedDocument = nil
                                    }
                                }
                                Button {
                                    viewModel.archive(document: document)
                                    if document == self.selectedDocument {
                                        self.selectedDocument = nil
                                    }
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                            }
                    }
                    Divider()
                    ForEach(viewModel.tags, id: \.self) { tag in
                        ZStack(alignment: .leading) {
                            Text(tag.name)
                                .font(Font.system(.body).smallCaps())
                                .foregroundColor(self.selectedTag == tag ? .white : .accentColor)
                                .padding(6)
                                .background(
                                    Rectangle()
                                    .fill(self.selectedTag == tag ? Color.accentColor : Color.clear)
                                    .cornerRadius(12))
                            Rectangle()
                                .fill(Color.accentColor)
                                .opacity(0.01)
                                .onTapGesture {
                                    if self.selectedTag == tag {
                                        self.selectedTag = nil
                                        if self.selectedDocument == tag {
                                            self.selectedDocument = nil
                                        }
                                    } else {
                                        self.selectedTag = tag
                                    }
                                }
                        }
                    }
                }.listStyle(.automatic)
                    .navigationTitle(viewModel.projectName ?? "")
                    .navigationBarTitleDisplayMode(.inline)
                
            } else {
                Color.clear
            }
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
