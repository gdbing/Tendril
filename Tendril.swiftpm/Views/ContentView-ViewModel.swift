import SwiftUI

extension ContentView {
    class ViewModel: ObservableObject {
        private var project: Project? {
            willSet { project?.stopAccessingFolder() }
        }
        @Published var projectName: String?
        @Published var documents: [Document]
        @Published var archivedDocuments: [Document]
        @Published var tags: [Document]
        
        init() {
            self.documents = [Document]()
            self.archivedDocuments = [Document]()
            self.tags = [Document]()
        }
        
        func loadProject(url: URL) {
            let project = Project(url: url)
            
            guard project.startAccessingFolder() else {
                print("ERROR failed to access security scoped resource \(url)")
                return
            }
            
            self.project = project
            self.projectName = project.name
            
            self.documents = project.readDocuments()
            self.archivedDocuments = project.readArchivedDocuments()
        }
        
        func newDocument(name: String = "Untitled", suffix: String = "txt") -> Document? {
            if let project, let newDoc = project.newDocument(name: name, suffix: suffix) {
                self.documents.append(newDoc)
                return newDoc
            }
            return nil
        }
        
        func delete(document: Document) {
            do {
                try document.delete()
                self.documents.removeAll(where: { $0 == document })
            } catch {
                print("ERROR unable to delete document \(document.name)")
            }
        }
        
        func archive(document: Document) {
            let archivedDocument = document.renamed(name: "archive/\(document.name)")
            self.documents.removeAll(where: { $0 == document })
            self.archivedDocuments.append(archivedDocument)
        }
        
        func rename(document: Document, newName: String) -> Document? {
            // TODO: handle if newName contains "/"
            if newName.count > 0, newName != document.name, let project {
                let newDocument = project.rename(document: document, name: newName)
                if let ix = self.documents.firstIndex(of: document) {
                    self.documents.replaceSubrange(ix...ix, with: [newDocument])
                    return newDocument
                }
            }
            return nil
        }
    }
}
