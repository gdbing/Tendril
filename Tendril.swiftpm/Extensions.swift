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
    
    func writeFile(data: Data) {
        do {
            try data.write(to: self, options: [])
        } catch {
            print("Error writing to file: \(error)")
        }
    }
}

extension UIColor {
    class var aiTextGray: UIColor { .secondaryLabel }
    class var commentGray: UIColor { .tertiaryLabel }
    class var userBubble: UIColor { .systemTeal.withAlphaComponent(0.25) }
    class var systemBubble: UIColor { .systemGreen.withAlphaComponent(0.25) }
    class var cacheBubble: UIColor { .systemPurple.withAlphaComponent(0.45) }
}

extension NSAttributedString.Key {
    public static let author: NSAttributedString.Key = NSAttributedString.Key(rawValue: "author")
}

extension NSAttributedString {
    convenience init(_ string: String, greyRanges: [NSRange]) {
        let mutableString = NSMutableAttributedString(string: string)
        let fullRange = NSRange(location: 0, length: (string as NSString).length)
        mutableString.addAttribute(.font, value: UIFont.systemFont(ofSize: 18), range: fullRange)
        mutableString.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
        for range in greyRanges {
            if range.location + range.length <= string.count {
                mutableString.addAttribute(.foregroundColor, value: UIColor.aiTextGray, range: range)
//                mutableString.addAttribute(.author, value: "gray", range: range)
            }
        } 
        self.init(attributedString: mutableString)
    }
    
    var greyRanges: [NSRange] {
        get {
            var ranges = [NSRange]()
//            self.enumerateAttribute(.author,
            self.enumerateAttribute(.foregroundColor,
                                    in: NSRange(location: 0, length: self.length), 
                                    options: [], 
                                    using: { value,range,_ in
//                if "gray" == value as? String {
                if UIColor.secondaryLabel == value as? NSObject {
                    ranges.append(range)
                }
            })
            return ranges
        }
    }
}
