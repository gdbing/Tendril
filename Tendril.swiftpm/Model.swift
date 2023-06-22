import SwiftUI

struct Project {
    private let url: URL
    let name: String
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
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
//            .filter { $0.lastPathComponent != "tendril.proj" }
            .map( { Document(project: self, url: $0) } )
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
                return Document(project: self, url: newDocURL)
            } catch {
                print("ERROR creating new document \(name)")
            }
        }
        return nil
    }
}

extension Project: Hashable {}

extension Project {
    private var projFileURL: URL {
        get { self.url.appendingPathComponent("tendril.proj") }
    }
    
    private func readProjectFile() -> ProjectFile? {
        if let data = try? Data(contentsOf: self.projFileURL, options: .mappedIfSafe) {
            return try? JSONDecoder().decode(ProjectFile.self, from: data)
        }
        return nil
    }
        
    func readGreyRangesFor(document: Document) -> [NSRange] {
        if let project = readProjectFile() , let ranges = project.greyRanges[document.name] {
            return ranges
        } else {
            return []
        }
    }
    
    func writeGreyRanges(_ ranges: [NSRange], document: Document) {
        var project = self.readProjectFile() ?? ProjectFile(greyRanges: [:])
        project.greyRanges[document.name] = ranges
            if let jsonData: Data = try? JSONEncoder().encode(project) {
                self.projFileURL.writeFile(data: jsonData)
        }
    }
}

struct ProjectFile: Codable {
    var greyRanges: [String:[NSRange]]
}

struct Document {
    private var url: URL
    private let project: Project
    
    var name: String
    
    init(project: Project, url: URL) {
        self.project = project
        self.url = url
        self.name = url.lastPathComponent
    }
    
    func delete() {
        if self.url.deleteFile() {
            // TODO project remove all trace
        }
    }
    
    func readText() -> String {
        return self.url.readFile() ?? ""
    }
    
    func readGreyRanges() -> [NSRange] {
        return self.project.readGreyRangesFor(document: self)
    }
    
    func write(text: String) {
        self.url.writeFile(text: text)
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
