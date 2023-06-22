import SwiftUI

extension ContentView {
    class ViewModel: ObservableObject {
//        @EnvironmentObject private var settings: Settings
        
        @Published var project: Project? {
            willSet { project?.stopAccessingFolder() }
        }
        @Published var documents: [Document]
        @Published var selectedDocument: Document?
        
        var gpt: GPTifier = GPTifier()
        
        init() {
            self.documents = [Document]()
        }
        
        func loadProject(url: URL) {
            let project = Project(url: url)
            
            guard project.startAccessingFolder() else {
                print("ERROR failed to access security scoped resource \(url)")
                return
            }
            
            self.project = project
            self.documents = self.project!.readDocuments()
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
        
        func rename(document: Document, newName: String) {
            if newName.count > 0, newName != document.name {
                let newDocument = document.renamed(name: newName)
                if let ix = self.documents.firstIndex(of: document) {
                    self.documents.replaceSubrange(ix...ix, with: [newDocument])
                }
                if selectedDocument == document {
                    selectedDocument = newDocument
                }
            }
        }
    }
}
