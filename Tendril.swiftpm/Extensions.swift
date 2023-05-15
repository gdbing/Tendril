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
