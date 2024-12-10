import Foundation

extension String {
    func range(from utf16Range: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: utf16Range.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: utf16Range.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        
        return from ..< to
    }

    func utf16Range(from range: Range<String.Index>) -> NSRange? {
        guard 
            let from = range.lowerBound.samePosition(in: utf16),
            let to = range.upperBound.samePosition(in: utf16)
        else { return nil }

        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }

    func utf16Range(charRange: NSRange) -> NSRange? {
        guard charRange.upperBound <= count else { return nil }
        
        let lowerBound = index(startIndex, offsetBy: charRange.lowerBound)
        let upperBound = index(startIndex, offsetBy: charRange.upperBound)
        let indexRange: Range<String.Index> = lowerBound ..< upperBound
        return utf16Range(from: indexRange)
    }

    func charRange(utf16Range: NSRange) -> NSRange? {
        guard let indexRange = Range(utf16Range, in: self) else { return nil }

        let location = self.distance(from: self.startIndex, to: indexRange.lowerBound)
        let length = self.distance(from: indexRange.lowerBound, to: indexRange.upperBound)

        return NSRange(location: location, length: length)
    }

    public func charIndex(utf16Index: Int) -> String.Index? {
        guard let idx = utf16.index(utf16.startIndex, offsetBy: utf16Index, limitedBy: utf16.endIndex)
        else { return nil }

        return String.Index(idx, within: self)
    }

    public func utf16Index(charIndex: String.Index) -> Int? {
        guard let from = charIndex.samePosition(in: utf16)
        else { return nil }

        return utf16.distance(from: utf16.startIndex, to: from)
    }
}

extension String {
//    @inline(__always)
//    var _indexOfLastCharacter: Index {
//      guard !isEmpty else { return endIndex }
//      return index(before: endIndex)
//    }
//
//    @inline(__always)
//    func _index(at offset: Int) -> Index {
//      self.index(self.startIndex, offsetBy: offset)
//    }
//
//    @inline(__always)
//    func _utf8Index(at offset: Int) -> Index {
//      self.utf8.index(startIndex, offsetBy: offset)
//    }
//
//    @inline(__always)
//    func _utf8ClampedIndex(at offset: Int) -> Index {
//      self.utf8.index(startIndex, offsetBy: offset, limitedBy: endIndex) ?? endIndex
//    }
//
//    @inline(__always)
//    func _utf8Offset(of index: Index) -> Int {
//      self.utf8.distance(from: startIndex, to: index)
//    }
//
//    public func index(offsetBy distance: Int) -> String.Index {
//        return self.index(self.startIndex, offsetBy: distance)
//    }

    var utf16Length: Int {
        (self as NSString).length
    }
}

extension String {
    public func splitIntoLines() -> [String] {
        var lines: [String] = []
        let wholeString = self.startIndex..<self.endIndex
        self.enumerateSubstrings(in: wholeString, options: .byLines) {
            (substring, range, enclosingRange, stopPointer) in
            if let _ = substring {
                let line = self[enclosingRange]
                lines.append(String(line))
            }
        }
        return lines
    }
}

