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
        // TODO: Deal with icloud offloaded files
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: self.url,
            includingPropertiesForKeys: [],
            options:.skipsHiddenFiles
        ) else {
            return [Document]()
        }
        
        return files
            .filter { !$0.hasDirectoryPath }
            .filter { $0.lastPathComponent != "tendril.proj" }
            .filter { !$0.lastPathComponent.hasPrefix("#") }
            .map( { Document(project: self, url: $0) } )
    }
    
    func readArchivedDocuments() -> [Document] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: self.url.appendingPathComponent("archive"),
            includingPropertiesForKeys: [],
            options:.skipsHiddenFiles
        ) else {
            return [Document]()
        }
        return files
            .filter { !$0.hasDirectoryPath }
            .map( { Document(project: self, url: $0) } )
    }
    
    func newDocument(name: String, suffix: String) -> Document? {
        let findAvailableURLFor = { (_ name: String) -> URL? in
            let untitledDotTxt = self.url.appendingPathComponent("\(name).\(suffix)")
            if !FileManager.default.fileExists(atPath: untitledDotTxt.path) {
                return untitledDotTxt
            } else {
                for ix in 1...255 {
                    let untitledDotTxtIx = self.url.appendingPathComponent("\(name) \(ix).\(suffix)")
                    if !FileManager.default.fileExists(atPath: untitledDotTxtIx.path) {
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
    
    func rename(document: Document, name: String) -> Document {
        let newDoc = document.renamed(name: name)
        let projFile = self.readProjectFile().renamedDocument(from: document.name, to: name)
        self.writeProjectFile(file: projFile)
        return newDoc
    } 
}

extension Project: Hashable {}

extension Project {
    private var projFileURL: URL {
        get { self.url.appendingPathComponent("tendril.proj") }
    }
    
    private func readProjectFile() -> ProjectFile {
        if let data = try? Data(contentsOf: self.projFileURL, options: .mappedIfSafe), 
            let project = try? JSONDecoder().decode(ProjectFile.self, from: data) {
            return project
        }
        return ProjectFile(greyRanges: [:])
    }
    
    func writeProjectFile(file: ProjectFile) {
        if let jsonData: Data = try? JSONEncoder().encode(file) {
            self.projFileURL.writeFile(data: jsonData)
        }
    }
}

// Grey Ranges
extension Project {
    func readGreyRangesFor(document: Document) -> [NSRange] {
        let project = readProjectFile()
        if let ranges = project.greyRanges[document.name] {
            return ranges
        } else {
            return []
        }
    }
    
    func writeGreyRanges(_ ranges: [NSRange], document: Document) {
        var project = self.readProjectFile()
        guard project.greyRanges[document.name] != ranges else { return }
        
        project.greyRanges[document.name] = ranges
        self.writeProjectFile(file: project)
    }
}

struct ProjectFile: Codable {
    var greyRanges: [String:[NSRange]] = [:]
    var tags: [String:[String]] = [:]
    
    // TODO the name of this method doesn't really make sense
    func renamedDocument(from: String, to: String) -> ProjectFile {
        var ranges = self.greyRanges
        if let value = ranges[from] {
            ranges.removeValue(forKey: from)
            ranges[to] = value
        }
        var tags = self.tags
        if let value = tags[from] {
            tags.removeValue(forKey: from)
            tags[to] = value
        }
        return ProjectFile(greyRanges: ranges, tags: tags)
    }
}
