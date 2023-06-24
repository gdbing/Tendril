import SwiftUI

extension ContentView {
    class ViewModel: ObservableObject {
        @Published var project: Project? {
            willSet { project?.stopAccessingFolder() }
        }
        @Published var documents: [Document]
        @Published var selectedDocument: Document?
                
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
            do {
                try document.delete()
            } catch {
                print("ERROR unable to delete document \(document.name)")
            }
            // TODO we could check if the backing file still exists and only
            // remove the UI indications if it doesn't but ¯\_(ツ)_/¯
            if document == self.selectedDocument {
                self.selectedDocument = nil
            }
            self.documents.removeAll(where: { $0 == document })
        }
        
        func rename(document: Document, newName: String) {
            if newName.count > 0, newName != document.name, let project {
                let newDocument = project.rename(document: document, name: newName)
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
