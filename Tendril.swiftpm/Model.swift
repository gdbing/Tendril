import SwiftUI

struct Project {
    private var url: URL
    var name: String
//    var tags: [Tag]
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
//        self.tags = [Tag]()
    }
    
    func startAccessingFolder() -> Bool {
        return self.url.startAccessingSecurityScopedResource()
    }
    
    func stopAccessingFolder() {
        self.url.stopAccessingSecurityScopedResource()
    }

    func readDocuments() -> [Document] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: self.url,
            includingPropertiesForKeys: [],
            options:.skipsHiddenFiles
        ) else {
            return [Document]()
        }
        
        return files
            .filter { !$0.hasDirectoryPath }
            .map( { Document(url: $0) } )
    }
    
    func newDocument(name: String, suffix: String) -> Document? {
        let findAvailableURLFor = { (_ name: String) -> URL? in
            let untitledDotTxt = self.url.appendingPathComponent("\(name).\(suffix)")
            if !FileManager.default.fileExists(atPath: untitledDotTxt.absoluteString) {
                return untitledDotTxt
            } else {
                for ix in 1...255 {
                    let untitledDotTxtIx = self.url.appendingPathComponent("\(name) \(ix).\(suffix)")
                    if !FileManager.default.fileExists(atPath: untitledDotTxtIx.absoluteString) {
                        return untitledDotTxtIx
                    }
                }
            }
            return nil
        }
        if let newDocURL = findAvailableURLFor(name) {
            do {
                try "".write(to: newDocURL, atomically: false, encoding: .utf8)
                return Document(url: newDocURL)
            } catch {
                print("ERROR creating new document \(name)")
            }
        }
        return nil
    }
}

struct Document {
    private var url: URL
    var name: String
//    var tags: [Tag]
    var grayRanges: [NSRange]
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
//        self.tags = [Tag]()
        self.grayRanges = [NSRange]()
    }
    
    func delete() {
        if self.url.deleteFile() {
            // project remove all trace
        }
    }
    
    func readText() -> String {
        return self.url.readFile() ?? ""
    }
    
    func readGrey() -> [NSRange]? {
        // TODO
        return nil
    }
    
    func write(text: String) {
        self.url.writeFile(text: text)
    }
    
    func write(grey: [NSRange]) {
        // TODO
    }
    
 func renamed(name: String) -> Document {
        if let newURL = try? url.renameFile(name: name) {
            return Document(url: newURL)
        }
        return self
    }
}

extension Document: Equatable, Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.url == rhs.url
    }
}

//struct Tag: Hashable {
//    let name: String
//}
