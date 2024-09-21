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
        
    // both

    func readTextAndGrayRanges() -> (content: String, grays: [NSRange]) {
        let text = self.url.readFile() ?? ""
        if let result = DocumentParser.consume(text) {
            let byteRanges = result.authorAnnotations.first?.ranges.compactMap { result.content.byteRange(charRange:$0) }
            return (result.content, byteRanges ?? [])
        } else {
            return (text, self.readGreyRanges())
        }
    }

    func write(content: String, grayRanges: [NSRange]) {
        var result = content
        result += "\n"
        result += "\n---"
        let hashAnnotation = HashAnnotation(content: content)
        result += "\n\(hashAnnotation)"
        let charRanges = grayRanges.compactMap { content.charRange(byteRange: $0) }
        let authorAnnotation = AuthorAnnotation(name: "Tendril", isHuman: false, ranges: charRanges)
        result += "\n\(authorAnnotation)"
        result += "\n..."

        self.url.writeFile(text: result)
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
