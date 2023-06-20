import SwiftUI

struct Project {
    private var url: URL
    var name: String
    var tags: [Tag]
    var documents: [Document]
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.tags = [Tag]()
        
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [
                .contentModificationDateKey,
                .creationDateKey,
                .typeIdentifierKey
            ],
            options:.skipsHiddenFiles
        ) else {
            self.documents = [Document]()
            return
        }
        
        self.documents = files.map( { Document(url: $0) } )
    }
    
    func newDocument(name: String, suffix: String) -> Document? {
//        let findAvailableURLFor = { (_ name: String) -> URL? in
//            let untitledDotTxt = projectURL.appendingPathComponent("\(name).\(suffix)")
//            if !self.documentURLs.contains(where: { $0 == untitledDotTxt}),
//               !FileManager.default.fileExists(atPath: untitledDotTxt.absoluteString) {
//                return untitledDotTxt
//            } else {
//                for ix in 1...255 {
//                    let untitledDotTxtIx = projectURL.appendingPathComponent("\(name) \(ix).\(suffix)")
//                    if !self.documentURLs.contains(where: { $0 == untitledDotTxtIx}),
//                       !FileManager.default.fileExists(atPath: untitledDotTxtIx.absoluteString) {
//                        return untitledDotTxtIx
//                    }
//                }
//            }
//            return nil
//        }
//        if let newDocURL = findAvailableURLFor(name) {
//            try? "".write(to: newDocURL, atomically: false, encoding: .utf8)
//            self.selectedDocumentURL = newDocURL
//            self.documentURLs.append(newDocURL)
//        }
        return nil
    }
}

struct Document {
    private var url: URL
    var name: String
//    var text: String
    var tags: [Tag]
    var grayRanges: [NSRange]
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
//        self.text = url.readFile() ?? ""
        self.tags = [Tag]()
        self.grayRanges = [NSRange]()
    }
    
    func delete() {
        if self.url.deleteFile() {
            // project remove all trace
        }
    }
    
    func read() -> String {
        return self.url.readFile() ?? ""
    }
    
    func write(text: String) {
        self.url.writeFile(text: text)
    }
}

extension Document: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.url == rhs.url
    }
}

extension Document: Hashable {
    
}

struct Tag: Hashable {
    let name: String
}
