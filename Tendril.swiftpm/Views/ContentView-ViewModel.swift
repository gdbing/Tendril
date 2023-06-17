import SwiftUI

extension ContentView {
    class ViewModel: ObservableObject {
//        @EnvironmentObject private var settings: Settings

        @Published var projectURL: URL? {
            willSet {
                projectURL?.stopAccessingSecurityScopedResource()
            }
            didSet {
                if let projectURL {
                    loadProject(url: projectURL)
                }
            }
        }
        @Published var documentURLs: [URL] = []
        @Published var selectedDocumentURL: URL? = nil
        @Published var selectedName: String = "" 
        
        var gpt: GPTifier = GPTifier()

        init() {
            
        }

        func loadProject(url: URL) {
            guard url.startAccessingSecurityScopedResource() else {
                print("ERROR failed to access security scoped resource \(url)")
                return
            }

            guard let files = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [
                    .contentModificationDateKey,
                    .creationDateKey,
                    .typeIdentifierKey
                ],
                options:.skipsHiddenFiles
            ) else { 
                return
            }
            self.documentURLs = files.filter( { !$0.hasDirectoryPath })
            self.selectedDocumentURL = nil
        }
        
        func newDocument(name: String = "Untitled", suffix: String = "txt") -> URL? {
            guard let projectURL else { return  nil }
            let untitledDotTxt = projectURL.appendingPathComponent("\(name).\(suffix)")
            if !self.documentURLs.contains(where: { $0 == untitledDotTxt}),
               !FileManager.default.fileExists(atPath: untitledDotTxt.absoluteString) {
                try? "".write(to: untitledDotTxt, atomically: false, encoding: .utf8)
                return untitledDotTxt
            } else {
                for ix in 1...255 {
                    let untitledDotTxtIx = projectURL.appendingPathComponent("\(name) \(ix).\(suffix)")
                    if !self.documentURLs.contains(where: { $0 == untitledDotTxtIx}),
                       !FileManager.default.fileExists(atPath: untitledDotTxtIx.absoluteString) {
                        try? "".write(to: untitledDotTxtIx, atomically: false, encoding: .utf8)
                        return untitledDotTxtIx
                    }
                }
            }
            return nil
        } 
        
        func delete(document: URL) {
            if document.deleteFile() {
                if document == selectedDocumentURL {
                    self.selectedDocumentURL = nil
                }
                documentURLs.removeAll(where: { $0 == document })
            }
        }
        
//        func rename(document: URL, newName: String) {
//            if newName != document.lastPathComponent,
//               let newURL = document.renameFile(name: newName),
//               let ix = self.documentURLs.firstIndex(of: document) {
//                self.documentURLs.replaceSubrange(ix...ix, with: [newURL])
//                self.selectedDocumentURL = newURL
//            }
//        }
    }
}
