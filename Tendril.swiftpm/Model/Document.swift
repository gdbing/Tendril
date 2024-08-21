import SwiftUI

struct Document {
    private var url: URL
    private let project: Project
    
    var name: String
    
    init(project: Project, url: URL) {
        self.project = project
        self.url = url
        self.name = url.lastPathComponent
    }
    
    func delete() throws {
        try FileManager.default.removeItem(at: self.url)
    }
    
    // Text
    
    func readText() -> String {
        return self.url.readFile() ?? ""
    }
    
    func write(text: String) {
        self.url.writeFile(text: text)
    }
    
    // Grey Ranges    
    
    func readGreyRanges() -> [NSRange] {
        return self.project.readGreyRangesFor(document: self)
    }
    
    func write(greyRanges: [NSRange]) {
        self.project.writeGreyRanges(greyRanges, document: self)
    }
        
    func renamed(name: String) -> Document {
        if let newURL = url.renameFile(name: name) {
            return Document(project: self.project, url: newURL)
        }
        return self
    }
}

extension Document: Equatable, Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.url == rhs.url
    }
}
