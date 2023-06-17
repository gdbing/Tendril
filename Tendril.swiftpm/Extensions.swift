import SwiftUI

extension String {
    func removeMatches(to regex: NSRegularExpression) -> String {
        let range = NSRange(location: 0, length: self.utf16.count)
        let modifiedString = NSMutableString(string: self)
        var offset = 0
        
        regex.enumerateMatches(in: self, options: [], range: range) { (match, _, _) in
            if let matchRange = match?.range {
                // Adjust the range to account for previous modifications
                let adjustedRange = NSRange(location: matchRange.location - offset, length: matchRange.length)
                modifiedString.deleteCharacters(in: adjustedRange)
                offset += matchRange.length
            }
        }
        return modifiedString as String
    }
}

extension URL {
    func deleteFile() -> Bool {
        do {
            try FileManager.default.removeItem(at: self)
        } catch {
            print("Error deleting the file: \(self.absoluteString) \(error)")
            return false
        }
        return true
    }
    
    func renameFile(name: String) -> URL? {
        let newURL = self
            .deletingLastPathComponent()
            .appendingPathComponent(name, isDirectory: self.hasDirectoryPath)
        do {
            try FileManager.default.moveItem(at: self, to: newURL)
            return newURL
        } catch {
            print("ERROR: failed to rename: \(self.absoluteString) to: \(newURL) \(error)")
        }
        return nil
    }
    
    /// Requirements:
    ///    - URL is a file URL
    ///    - file contents are plaintext UTF8
    ///    - startAccessingSecurityScopedResource() 
    func readFile() -> String? {
        if let data = try? Data(contentsOf: self, options: []),
           let text = String(data: data, encoding: .utf8) {
            return text
        }
        return nil
    }
    
    /// Requirements:
    ///    - URL is a file URL
    ///    - startAccessingSecurityScopedResource() 
    func writeFile(text: String) {
        do {
            try text.write(to: self, atomically: false, encoding: .utf8)
        } catch {
            print("Error writing to file: \(error)")
        }
    }
    
}
