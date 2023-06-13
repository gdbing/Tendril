import SwiftUI

struct ProjectView: View {
    @Binding var projectURL: URL?
    @Binding var documentURLs: [URL]
    @Binding var selectedDocumentURL: URL?
    
    var body: some View {
        VStack {
            List(documentURLs, id: \.self, selection: $selectedDocumentURL) { documentURL in
                Text(documentURL.lastPathComponent)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Delete", role: .destructive) {
                            if documentURL.deleteFile() {
                                documentURLs.removeAll(where: { $0 == documentURL })
                            }
                        }
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            if documentURL.deleteFile() {
                                documentURLs.removeAll(where: { $0 == documentURL })
                            }
                        }
                    }
            }
            Text(selectedDocumentURL?.lastPathComponent ?? "")
        }
        .navigationTitle(projectURL?.lastPathComponent ?? "")
//        .navigationDocument(projectURL)
    }
}

struct ProjectView_Previews: PreviewProvider {
    static var previews: some View {
        let folderPath = "file://folder/project"
        @State var selectedURL = URL(string: folderPath + "/special-file.txt")
        NavigationStack {
            ProjectView(projectURL: .constant(URL(string: folderPath)!), 
                        documentURLs: .constant([URL(string: folderPath + "/patrick.txt")!,
                                                 selectedURL!,
                                                 URL(string: folderPath + "/roberto.txt")!,
                                                 URL(string: folderPath + "/renata.txt")!]), 
                        selectedDocumentURL: $selectedURL)
        }
    }
}
