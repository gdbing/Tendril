import SwiftUI

extension ContentView {
    class ViewModel: ObservableObject {
//        @EnvironmentObject private var settings: Settings

        @Published var project: Project?
        @Published var documents: [Document]
        @Published var selectedDocument: Document?
        
//        @Published var projectURL: URL? {
//            willSet {
//                projectURL?.stopAccessingSecurityScopedResource()
//            }
//            didSet {
//                if let projectURL {
//                    loadProject(url: projectURL)
//                }
//            }
//        }
//        @Published var documentURLs: [URL] = []
//        @Published var selectedDocumentURL: URL? = nil
//        @Published var selectedName: String = "" 
        
        var gpt: GPTifier = GPTifier()

        init() {
            self.documents = [Document]()
        }

        func loadProject(url: URL) {
            guard url.startAccessingSecurityScopedResource() else {
                print("ERROR failed to access security scoped resource \(url)")
                return
            }
            self.project = Project(url: url)
            self.documents = self.project?.documents ?? [Document]()
            self.selectedDocument = nil
        }
        
        func newDocument(name: String = "Untitled", suffix: String = "txt") {
            if let project, let newDoc = project.newDocument(name: name, suffix: suffix) {
                self.selectedDocument = newDoc
                self.documents.append(newDoc)
            }
        }
        
        func delete(document: Document) {
            document.delete()
            if document == self.selectedDocument {
                self.selectedDocument = nil
            }
            self.documents.removeAll(where: { $0 == document })
        }
        
//        func rename(document: Document, newName: String) {
//            if newName != document.lastPathComponent,
//               let newURL = document.renameFile(name: newName),
//               let ix = self.documentURLs.firstIndex(of: document) {
//                self.documentURLs.replaceSubrange(ix...ix, with: [newURL])
//                self.selectedDocumentURL = newURL
//            }
//        }
    }
}
