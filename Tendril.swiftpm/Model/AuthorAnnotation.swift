import Foundation

struct AuthorAnnotation: Identifiable, Equatable {
    // @Anton Sotkov: 15 20,107 128,186 490,642
    var id: String {
        description
    }

    var key: String {
        return (isHuman ? "@" : "&") + name
    }
    let name: String
    let isHuman: Bool
    let ranges: [NSRange]

    init(name: String, isHuman: Bool, ranges: [NSRange]) {
        self.name = name
        self.isHuman = isHuman
        self.ranges = ranges
    }

    init?(key: String, ranges: [NSRange]) {
        if key.first == "@" {
            self.isHuman = true
        } else if key.first == "&" {
            self.isHuman = false
        } else {
            return nil
        }
        self.name = String(key.dropFirst())
        self.ranges = ranges
    }

    init?(annotationString input: String) {
        guard let result = AuthorAnnotationParser.consume(input) else {
            return nil
        }
        self = result.annotation
    }
}

extension AuthorAnnotation: CustomStringConvertible {
    public var description: String {
        var stringBuilder: String = ""
        stringBuilder += "\(key):"
        for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            stringBuilder += " \(range.lowerBound)"
            if range.length > 1 {
                stringBuilder += ",\(range.length)"
            }
        }
        return stringBuilder
    }
}

extension AuthorAnnotation {
    static func array(content: NSAttributedString) -> [AuthorAnnotation] {
        var nameRanges: [String: [NSRange]] = [:]
        content.enumerateAttribute(.author, in: NSRange(0..<content.length)) { value, range, _ in
            //Confirm the attribute value is actually a font
            if let name = value as? String, let charRange = content.string.charRange(byteRange: range) {
                if let existingRanges = nameRanges[name] {
                    nameRanges[name] = existingRanges + [charRange]
                } else {
                    nameRanges[name] = [charRange]
                }
            }
        }
        
        var annotations: [AuthorAnnotation] = []
        for (name, ranges) in nameRanges {
            if let annotation = AuthorAnnotation(key: name, ranges: ranges) {
                annotations.append(annotation)
            }
        }

        return annotations
    }
}
