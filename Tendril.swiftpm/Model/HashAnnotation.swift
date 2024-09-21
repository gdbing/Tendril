import Foundation
import CryptoKit

struct HashAnnotation {
    let key: String
    let range: NSRange
    let hashString: String
    
    // Annotations: 0,6310 SHA-256 0650af9e723d7401b1a63e81582eb7bd
    init?(annotationString input: String) {
        guard let result = HashAnnotationParser.consume(input) else {
            return nil
        }
        self = result.annotation
    }
    
    init(content: String) {
        self.key = "Annotations"
        self.range = NSRange(location: 0, length: content.count)
        self.hashString = hash(content)
    }

    init(range: NSRange, hashString: String) {
        self.key = "Annotations"
        self.range = range
        self.hashString = hashString
    }
}

extension HashAnnotation: CustomStringConvertible {
    public var description: String {
        "\(key): \(range.lowerBound),\(range.length) SHA-256 \(hashString)"
    }
}

extension HashAnnotation {
    func verify(_ input: String) -> Bool {
        guard self.range.length <= input.count else {
            return false
        }
        
        let startIndex = input.index(input.startIndex, offsetBy: self.range.lowerBound)
        let endIndex = input.index(input.startIndex, offsetBy: self.range.upperBound)
        let subInput = input[startIndex..<endIndex]
        let inputHashString = hash(String(subInput))
        
        return self.hashString == inputHashString.prefix(self.hashString.count)
    }
}

fileprivate func hash(_ string: String) -> String {
    let data = Data(string.utf8)
    let hash = SHA256.hash(data: data)
    let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
    return String(hashString.prefix(32))
}
